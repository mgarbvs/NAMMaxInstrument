// irconv~.cpp — Max external for partitioned FFT convolution using HISSTools.
//
// Replacement for the buffir~ stopgap used during M4. multiconvolve~ is not
// available in the M4L runtime; this external wraps HISSTools::MonoConvolve
// (the same engine underlying Ableton's bundled multiconvolve~.mxo) to provide
// real partitioned convolution with accurate latency reporting.
//
// Conditional compilation:
//   If the HISSTools_Library headers are present (HISSTOOLS_AVAILABLE=1 set by
//   CMake), the real convolution path is compiled. Otherwise this file compiles
//   to a silent passthrough so ./build.sh keeps working while HISSTools is not
//   yet vendored. The guard mirrors the NAM_CORE_AVAILABLE pattern in nam~.cpp.
//
// Thread-safety design (mirrors the staged-swap pattern in nam~.cpp):
//   - mStagedConv holds a freshly configured HISSTools::MonoConvolve* from the
//     "set" message handler (runs on the main/scheduler thread).
//   - At the TOP of perform64, if mStagedConv is non-null we atomically swap
//     it into mLiveConv, delete the old convolver, and schedule a deferred
//     notification (clock_delay) to fire latency/load-complete outlets on the
//     main thread.
//   - No locks in the audio path — only atomic load/exchange.
//   - NEVER allocate in the audio callback. Scratch buffers allocated in dsp64
//     based on maxvectorsize; a second temp buffer is required by
//     MonoConvolve::process().
//
// Partition strategy:
//   We construct MonoConvolve with kLatencyShort mode, which uses partition
//   sizes {256, 1024, 4096, 16384}. This means the first partition is 256
//   samples — that is the reported PDC latency. kLatencyShort is the right
//   trade-off for a cabinet-IR use case: the 256-sample first partition keeps
//   latency to ~5 ms at 48 kHz, while the larger partitions keep CPU cost
//   proportional for long IRs (> 4096 taps). kLatencyZero (time-domain first
//   pass) is more CPU-intensive and unnecessary here. kLatencyMedium (1024
//   first partition) adds ~21 ms latency — too much for a guitar amp chain.
//
// Outlets (declared innermost/rightmost first per Max convention):
//   3 — error symbol (rightmost)
//   2 — load_complete bang
//   1 — latency/meta messages ("latency <samples>")
//   0 — signal out (leftmost, declared last via outlet_new(x, "signal"))
//
// NOTE on HISSTools include path:
//   The canonical path inside the vendored submodule is:
//     HISSTools_Library/HIRT_Multichannel_Convolution/MonoConvolve.h
//   CMakeLists.txt adds the HISSTools_Library root as an include path, so:
//     #include "HIRT_Multichannel_Convolution/MonoConvolve.h"
//   Adjust if the submodule is cloned under a different directory name.

extern "C" {
#include "ext.h"
#include "ext_obex.h"
#include "ext_buffer.h"
#include "z_dsp.h"
}

#include <atomic>
#include <cstring>

// ── HISSTools conditional include ────────────────────────────────────────────
// CMakeLists.txt sets HISSTOOLS_AVAILABLE=1 and adds the include path when
// external_src/thirdparty/HISSTools_Library/HIRT_Multichannel_Convolution/
// MonoConvolve.h is present. The __has_include guard lets this file compile
// to a passthrough when the submodule hasn't been fetched yet.

#ifndef HISSTOOLS_AVAILABLE
#  if __has_include("HIRT_Multichannel_Convolution/MonoConvolve.h")
#    define HISSTOOLS_AVAILABLE 1
#  else
#    define HISSTOOLS_AVAILABLE 0
#  endif
#endif

#if HISSTOOLS_AVAILABLE
#  include "HIRT_Multichannel_Convolution/MonoConvolve.h"
#  include <vector>
#endif

// ── Constants ─────────────────────────────────────────────────────────────────

// Max IR length supported: 4 seconds at 96 kHz = 384 000 samples.
// MonoConvolve is constructed with this as maxLength; actual loaded length
// may be shorter. Keep generous to avoid re-allocation on IR change.
static constexpr uintptr_t kMaxIRLength = 384000;

// Reported PDC latency when using kLatencyShort (first partition = 256 samples).
static constexpr long kReportedLatency = 256;

// ── Object struct ─────────────────────────────────────────────────────────────

typedef struct _irconv {
    t_pxobject  ob;

    // Outlets (created innermost/rightmost first)
    void       *error_out;        // outlet 3 — error symbol
    void       *load_complete_out;// outlet 2 — bang on successful IR load
    void       *meta_out;         // outlet 1 — latency messages

    // Parameters
    std::atomic<long> bypass;

    // Clock for deferred main-thread outlet calls
    void       *mLoadClock;

    // Notification flags written by main thread "set" handler, read by clock cb
    std::atomic<bool> mPendingLoadNotify;
    std::atomic<bool> mPendingErrorNotify;
    char              mErrorMsg[512];

#if HISSTOOLS_AVAILABLE
    // Convolver state — atomic staged-swap (same pattern as nam~.cpp mStagedModel)
    std::atomic<HISSTools::MonoConvolve *> mLiveConv;    // audio thread owns it
    std::atomic<HISSTools::MonoConvolve *> mStagedConv;  // ready to swap in

    // Scratch buffers sized to maxvectorsize (allocated in dsp64, NOT perform64)
    float     *mScratchIn;   // double → float conversion
    float     *mScratchTemp; // required by MonoConvolve::process()
    float     *mScratchOut;  // float → double conversion
    long       mScratchSize;
#endif
} t_irconv;

static t_class *s_irconv_class = nullptr;

// ── Forward declarations ──────────────────────────────────────────────────────

static void *irconv_new(t_symbol *s, long argc, t_atom *argv);
static void  irconv_free(t_irconv *x);
static void  irconv_assist(t_irconv *x, void *b, long m, long a, char *s);
static void  irconv_dsp64(t_irconv *x, t_object *dsp64, short *count,
                          double samplerate, long maxvectorsize, long flags);
static void  irconv_perform64(t_irconv *x, t_object *dsp64,
                              double **ins, long numins,
                              double **outs, long numouts,
                              long sampleframes, long flags, void *userparam);
static void  irconv_set(t_irconv *x, t_symbol *s);
static void  irconv_bypass(t_irconv *x, long v);
static void  irconv_report(t_irconv *x);
static void  irconv_clock_tick(t_irconv *x);

// ── ext_main ──────────────────────────────────────────────────────────────────

extern "C" void ext_main(void *)
{
    t_class *c = class_new("irconv~",
                           (method)irconv_new, (method)irconv_free,
                           (long)sizeof(t_irconv), 0L, A_GIMME, 0);

    class_addmethod(c, (method)irconv_dsp64,   "dsp64",   A_CANT,  0);
    class_addmethod(c, (method)irconv_assist,  "assist",  A_CANT,  0);
    class_addmethod(c, (method)irconv_set,     "set",     A_SYM,   0);
    class_addmethod(c, (method)irconv_bypass,  "bypass",  A_LONG,  0);
    class_addmethod(c, (method)irconv_report,  "report",  0);

    class_dspinit(c);
    class_register(CLASS_BOX, c);
    s_irconv_class = c;
}

// ── irconv_new ────────────────────────────────────────────────────────────────

static void *irconv_new(t_symbol *, long, t_atom *)
{
    t_irconv *x = (t_irconv *)object_alloc(s_irconv_class);
    if (!x) return nullptr;

    dsp_setup((t_pxobject *)x, 1);  // 1 signal inlet

    // Outlets declared rightmost first (highest index = rightmost in UI).
    x->error_out         = outlet_new(x, (char *)"symbol"); // outlet 3
    x->load_complete_out = bangout(x);                       // outlet 2
    x->meta_out          = outlet_new(x, nullptr);           // outlet 1
    outlet_new(x, "signal");                                  // outlet 0

    x->bypass.store(0);
    x->mPendingLoadNotify.store(false);
    x->mPendingErrorNotify.store(false);
    x->mErrorMsg[0] = '\0';

    x->mLoadClock = clock_new(x, (method)irconv_clock_tick);

#if HISSTOOLS_AVAILABLE
    x->mLiveConv.store(nullptr);
    x->mStagedConv.store(nullptr);
    x->mScratchIn   = nullptr;
    x->mScratchTemp = nullptr;
    x->mScratchOut  = nullptr;
    x->mScratchSize = 0;
#endif

    return x;
}

// ── irconv_free ───────────────────────────────────────────────────────────────

static void irconv_free(t_irconv *x)
{
    dsp_free((t_pxobject *)x);

    if (x->mLoadClock) {
        clock_unset(x->mLoadClock);
        freeobject((t_object *)x->mLoadClock);
        x->mLoadClock = nullptr;
    }

#if HISSTOOLS_AVAILABLE
    delete x->mLiveConv.exchange(nullptr);
    delete x->mStagedConv.exchange(nullptr);

    delete[] x->mScratchIn;
    delete[] x->mScratchTemp;
    delete[] x->mScratchOut;
    x->mScratchIn   = nullptr;
    x->mScratchTemp = nullptr;
    x->mScratchOut  = nullptr;
    x->mScratchSize = 0;
#endif
}

// ── irconv_assist ─────────────────────────────────────────────────────────────

static void irconv_assist(t_irconv *, void *, long m, long a, char *s)
{
    if (m == ASSIST_INLET) {
        snprintf(s, 256,
            "(signal) audio in / messages: set <buffer_name>, bypass 0|1, report");
    } else {
        switch (a) {
            case 0: snprintf(s, 256, "(signal) convolved audio out"); break;
            case 1: snprintf(s, 256, "latency messages: latency <samples>"); break;
            case 2: snprintf(s, 256, "bang on IR load-complete"); break;
            case 3: snprintf(s, 256, "error symbol"); break;
        }
    }
}

// ── irconv_dsp64 ──────────────────────────────────────────────────────────────

static void irconv_dsp64(t_irconv *x, t_object *dsp64, short *,
                         double, long maxvectorsize, long)
{
#if HISSTOOLS_AVAILABLE
    // Allocate scratch buffers sized for maxvectorsize.
    // This is the dsp64 callback (main thread, before audio starts) — safe to
    // allocate here. Never allocate in perform64.
    if (maxvectorsize > x->mScratchSize) {
        delete[] x->mScratchIn;
        delete[] x->mScratchTemp;
        delete[] x->mScratchOut;
        x->mScratchIn   = new float[maxvectorsize];
        x->mScratchTemp = new float[maxvectorsize];
        x->mScratchOut  = new float[maxvectorsize];
        x->mScratchSize = maxvectorsize;
    }
#endif
    object_method(dsp64, gensym("dsp_add64"), x,
                  (method)irconv_perform64, 0, nullptr);
}

// ── irconv_perform64 ──────────────────────────────────────────────────────────
//
// Audio thread. No allocation, no locks, no outlet calls.
// Outlet notifications deferred via clock_delay (main thread).

static void irconv_perform64(t_irconv *x, t_object *,
                             double **ins, long,
                             double **outs, long,
                             long sampleframes, long, void *)
{
    double *in  = ins[0];
    double *out = outs[0];

#if HISSTOOLS_AVAILABLE
    // ── Staged-swap: bring in a freshly configured convolver ──────────────
    HISSTools::MonoConvolve *staged = x->mStagedConv.exchange(nullptr);
    if (staged) {
        HISSTools::MonoConvolve *old = x->mLiveConv.exchange(staged);
        delete old;
        x->mPendingLoadNotify.store(true);
        clock_delay(x->mLoadClock, 0);
    }

    // ── Process ───────────────────────────────────────────────────────────
    HISSTools::MonoConvolve *conv = x->mLiveConv.load();

    if (!x->bypass.load() && conv) {
        // Convert double input → float scratch
        float *si  = x->mScratchIn;
        float *st  = x->mScratchTemp;
        float *so  = x->mScratchOut;
        for (long i = 0; i < sampleframes; ++i)
            si[i] = static_cast<float>(in[i]);

        // MonoConvolve::process(in, temp, out, numSamples)
        // temp is an internal working buffer; out receives the result.
        conv->process(si, st, so, static_cast<uintptr_t>(sampleframes));

        // Convert float result → double output
        for (long i = 0; i < sampleframes; ++i)
            out[i] = static_cast<double>(so[i]);
    } else {
        // Bypass or no IR loaded: passthrough
        for (long i = 0; i < sampleframes; ++i)
            out[i] = in[i];
    }

#else
    // Passthrough fallback — HISSTools not compiled in
    for (long i = 0; i < sampleframes; ++i)
        out[i] = in[i];
#endif
}

// ── irconv_clock_tick ─────────────────────────────────────────────────────────
// Called on the main/scheduler thread — safe to call outlets.

static void irconv_clock_tick(t_irconv *x)
{
    if (x->mPendingErrorNotify.exchange(false)) {
        outlet_anything(x->error_out,
                        gensym(x->mErrorMsg[0] ? x->mErrorMsg : "irconv~: error"),
                        0, nullptr);
    }
    if (x->mPendingLoadNotify.exchange(false)) {
        // Report latency first (before bang) so the patch can route it before
        // acting on the load-complete signal. kLatencyShort first partition = 256.
        t_atom latency_val;
        atom_setlong(&latency_val, kReportedLatency);
        outlet_anything(x->meta_out, gensym("latency"), 1, &latency_val);

        outlet_bang(x->load_complete_out);
    }
}

// ── irconv_set ────────────────────────────────────────────────────────────────
//
// Message: set <buffer_name>
//
// Reads the named buffer~, copies its first channel into a float vector,
// constructs a new HISSTools::MonoConvolve configured with that IR, and
// stages it for the audio thread to swap in on its next block.
//
// Runs on the main/scheduler thread — safe to call buffer_locksamples and
// to allocate memory.

static void irconv_set(t_irconv *x, t_symbol *s)
{
    if (!s || !s->s_name || s->s_name[0] == '\0') {
        object_error((t_object *)x, "irconv~: set requires a buffer name argument");
        return;
    }

#if HISSTOOLS_AVAILABLE
    // Access the buffer~ via buffer_ref API.
    // buffer_ref_new acquires a reference; we release it immediately after
    // copying samples (we don't need a persistent ref — we own our own copy).
    t_buffer_ref *ref = buffer_ref_new((t_object *)x, s);
    if (!ref) {
        snprintf(x->mErrorMsg, sizeof(x->mErrorMsg),
                 "irconv~: could not create buffer ref for '%s'", s->s_name);
        object_error((t_object *)x, "%s", x->mErrorMsg);
        x->mPendingErrorNotify.store(true);
        clock_delay(x->mLoadClock, 0);
        return;
    }

    t_buffer_obj *buf = buffer_ref_getobject(ref);
    if (!buf) {
        snprintf(x->mErrorMsg, sizeof(x->mErrorMsg),
                 "irconv~: buffer '%s' not found", s->s_name);
        object_error((t_object *)x, "%s", x->mErrorMsg);
        x->mPendingErrorNotify.store(true);
        clock_delay(x->mLoadClock, 0);
        object_free(ref);
        return;
    }

    // Lock the buffer and copy samples.
    float *samples = buffer_locksamples(buf);
    if (!samples) {
        snprintf(x->mErrorMsg, sizeof(x->mErrorMsg),
                 "irconv~: could not lock samples for buffer '%s'", s->s_name);
        object_error((t_object *)x, "%s", x->mErrorMsg);
        x->mPendingErrorNotify.store(true);
        clock_delay(x->mLoadClock, 0);
        object_free(ref);
        return;
    }

    long frameCount  = buffer_getframecount(buf);
    long chanCount   = buffer_getchannelcount(buf);

    if (frameCount <= 0 || chanCount <= 0) {
        buffer_unlocksamples(buf);
        object_free(ref);
        snprintf(x->mErrorMsg, sizeof(x->mErrorMsg),
                 "irconv~: buffer '%s' is empty or has no channels", s->s_name);
        object_error((t_object *)x, "%s", x->mErrorMsg);
        x->mPendingErrorNotify.store(true);
        clock_delay(x->mLoadClock, 0);
        return;
    }

    // Copy channel 0 only (irconv~ is mono-in / mono-out by design).
    // Buffer~ interleaves channels: sample[frame * chanCount + chan].
    std::vector<float> irData(static_cast<size_t>(frameCount));
    for (long i = 0; i < frameCount; ++i)
        irData[i] = samples[i * chanCount + 0];

    buffer_unlocksamples(buf);
    object_free(ref);

    // Clamp to our supported maximum (shouldn't normally be hit).
    uintptr_t irLen = static_cast<uintptr_t>(frameCount);
    if (irLen > kMaxIRLength) {
        object_warn((t_object *)x,
                    "irconv~: IR length %lu exceeds max %lu; truncating",
                    (unsigned long)irLen, (unsigned long)kMaxIRLength);
        irLen = kMaxIRLength;
    }

    // Build a new convolver with kLatencyShort (first partition = 256 samples).
    // This is constructed on the main thread; the audio thread swaps it in atomically.
    HISSTools::MonoConvolve *newConv = nullptr;
    try {
        newConv = new HISSTools::MonoConvolve(kMaxIRLength, kLatencyShort);
        ConvolveError err = newConv->set(irData.data(), irLen, false);
        if (err != CONVOLVE_ERR_NONE) {
            delete newConv;
            snprintf(x->mErrorMsg, sizeof(x->mErrorMsg),
                     "irconv~: HISSTools set() error %d for buffer '%s'",
                     (int)err, s->s_name);
            object_error((t_object *)x, "%s", x->mErrorMsg);
            x->mPendingErrorNotify.store(true);
            clock_delay(x->mLoadClock, 0);
            return;
        }
    } catch (const std::exception &e) {
        delete newConv;
        snprintf(x->mErrorMsg, sizeof(x->mErrorMsg),
                 "irconv~: exception constructing convolver for '%s': %s",
                 s->s_name, e.what());
        object_error((t_object *)x, "%s", x->mErrorMsg);
        x->mPendingErrorNotify.store(true);
        clock_delay(x->mLoadClock, 0);
        return;
    }

    // Stage the new convolver. If the audio thread hasn't consumed the previous
    // staged one yet (rapid successive calls), delete it here.
    HISSTools::MonoConvolve *old_staged = x->mStagedConv.exchange(newConv);
    delete old_staged;

    object_post((t_object *)x,
                "irconv~: staged new convolver for buffer '%s' (%ld frames)",
                s->s_name, (long)irLen);

#else
    object_post((t_object *)x,
                "irconv~: set '%s' (HISSTools not available — passthrough mode)",
                s->s_name);
#endif
}

// ── irconv_bypass ─────────────────────────────────────────────────────────────

static void irconv_bypass(t_irconv *x, long v)
{
    x->bypass.store(v ? 1 : 0);
}

// ── irconv_report ─────────────────────────────────────────────────────────────
//
// Send the current latency out the meta outlet on demand.
// Safe to call on the main thread at any time.

static void irconv_report(t_irconv *x)
{
#if HISSTOOLS_AVAILABLE
    if (x->mLiveConv.load()) {
        t_atom latency_val;
        atom_setlong(&latency_val, kReportedLatency);
        outlet_anything(x->meta_out, gensym("latency"), 1, &latency_val);
    } else {
        object_post((t_object *)x, "irconv~: no IR loaded");
    }
#else
    object_post((t_object *)x,
                "irconv~: report (HISSTools not available — passthrough mode, latency=0)");
    t_atom latency_val;
    atom_setlong(&latency_val, 0);
    outlet_anything(x->meta_out, gensym("latency"), 1, &latency_val);
#endif
}
