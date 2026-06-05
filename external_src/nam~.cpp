// nam~.cpp — Max external wrapping nam::DSP from NeuralAmpModelerCore.
//
// M5: Full implementation integrating NeuralAmpModelerCore when available.
//
// Conditional compilation:
//   If NAM/dsp.h is present (NAM_CORE_AVAILABLE=1 set by CMake), the real
//   inference path is compiled. Otherwise, the file compiles to a passthrough
//   fallback so build.sh still works while thirdparty deps are absent.
//
// Thread-safety design (mirrors the NAM plugin's staged-swap pattern):
//   - mStagedModel holds a freshly-loaded DSP* from the worker thread.
//   - At the TOP of perform64, if mStagedModel is non-null we atomically swap
//     it into mModel, delete the previous live model, and set a flag that
//     triggers a deferred notification (clock_delay) on the main thread.
//   - No locks in the audio path — only atomic load/exchange.
//   - NEVER allocate in the audio callback. Scratch buffer allocated in dsp64
//     based on maxvectorsize.
//   - Reset()/prewarm() (which push audio through the model) run only off the
//     audio thread: on the load worker before staging, or in dsp64 while audio
//     is stopped. A2 "container" models read uninitialized submodel state if
//     process() is called before a Reset+prewarm.
//
// Outlet order (set up innermost-first, which is outermost in the box UI):
//   0 — (signal) audio out
//   1 — metadata dict (sample_rate, normalized, ...)  [not yet populated]
//   2 — bang on load-complete
//   3 — error symbol

extern "C" {
#include "ext.h"
#include "ext_obex.h"
#include "z_dsp.h"
}

#include <atomic>
#include <cstring>

// ── NAM core conditional include ─────────────────────────────────────────────
// The CMakeLists.txt sets NAM_CORE_AVAILABLE=1 and adds the include path when
// external_src/thirdparty/NeuralAmpModelerCore/NAM/dsp.h is present.
// The __has_include guard lets this file compile to a passthrough if the
// submodule hasn't been fetched yet.

#ifndef NAM_CORE_AVAILABLE
#  if __has_include(<NAM/dsp.h>)
#    define NAM_CORE_AVAILABLE 1
#  else
#    define NAM_CORE_AVAILABLE 0
#  endif
#endif

#if NAM_CORE_AVAILABLE
#  include <NAM/dsp.h>
#  include <NAM/get_dsp.h>
#  include <filesystem>
#  include <thread>
#  include <string>
#endif

// ── Object struct ────────────────────────────────────────────────────────────

typedef struct _nam {
    t_pxobject  ob;

    // Outlets (created innermost-first so outermost = index 0)
    void       *error_out;          // outlet 3 — error symbol
    void       *load_complete_out;  // outlet 2 — bang on load-complete
    void       *meta_out;           // outlet 1 — metadata dict

    // Parameters
    std::atomic<long> bypass;
    double            slim;

#if NAM_CORE_AVAILABLE
    // Model state — atomic staged-swap pattern
    std::atomic<nam::DSP *> mModel;        // live model (audio thread owns it)
    std::atomic<nam::DSP *> mStagedModel;  // freshly loaded, waiting to swap in

    // Worker thread — one load at a time
    std::thread             mWorkerThread;
    std::atomic<bool>       mWorkerRunning;

    // Clock for deferred main-thread notification after model swap
    void                   *mLoadClock;
    std::atomic<bool>       mPendingLoadNotify;    // true → next clock fires bang
    std::atomic<bool>       mPendingErrorNotify;   // true → next clock fires error
    char                    mErrorMsg[512];         // written by worker, read by clock cb

    // NAM_SAMPLE conversion scratch buffer (allocated in dsp64).
    // On the pinned core (v0.5.2) NAM_SAMPLE resolves to double unless
    // NAM_SAMPLE_FLOAT is defined; Max also passes double, so the copy is a
    // straight assignment. We keep the conversion in case the core is ever
    // built with NAM_SAMPLE_FLOAT.
    NAM_SAMPLE *mScratchIn;   // maxvectorsize samples
    NAM_SAMPLE *mScratchOut;  // maxvectorsize samples
    long        mScratchSize; // allocated size (in samples)

    // Last sample rate / max block size seen in dsp64. The load worker reads
    // these to Reset + prewarm a freshly loaded model before staging it, so the
    // expensive prewarm (which pushes audio through the model) never runs on the
    // audio thread. A2 "container" models REQUIRE this — their process() forwards
    // straight to the active submodel with no self-initialization.
    std::atomic<double> mSampleRate;  // 0 until dsp64 has run at least once
    std::atomic<long>   mMaxBlock;    // 0 until dsp64 has run at least once
#endif
} t_nam;

static t_class *s_nam_class = nullptr;

// ── Forward declarations ─────────────────────────────────────────────────────

static void *nam_new(t_symbol *s, long argc, t_atom *argv);
static void  nam_free(t_nam *x);
static void  nam_assist(t_nam *x, void *b, long m, long a, char *s);
static void  nam_dsp64(t_nam *x, t_object *dsp64, short *count, double samplerate,
                       long maxvectorsize, long flags);
static void  nam_perform64(t_nam *x, t_object *dsp64, double **ins, long numins,
                           double **outs, long numouts, long sampleframes,
                           long flags, void *userparam);
static void  nam_load(t_nam *x, t_symbol *s);
static void  nam_reset(t_nam *x);
static void  nam_bypass(t_nam *x, long v);
static void  nam_slim(t_nam *x, double v);

#if NAM_CORE_AVAILABLE
static void  nam_clock_tick(t_nam *x);
#endif

// ── ext_main ─────────────────────────────────────────────────────────────────

extern "C" void ext_main(void *)
{
    t_class *c = class_new("nam~",
                           (method)nam_new, (method)nam_free,
                           (long)sizeof(t_nam), 0L, A_GIMME, 0);

    class_addmethod(c, (method)nam_dsp64,   "dsp64",   A_CANT,  0);
    class_addmethod(c, (method)nam_assist,  "assist",  A_CANT,  0);
    class_addmethod(c, (method)nam_load,    "load",    A_SYM,   0);
    class_addmethod(c, (method)nam_reset,   "reset",   0);
    class_addmethod(c, (method)nam_bypass,  "bypass",  A_LONG,  0);
    class_addmethod(c, (method)nam_slim,    "slim",    A_FLOAT, 0);

    class_dspinit(c);
    class_register(CLASS_BOX, c);
    s_nam_class = c;
}

// ── nam_new ──────────────────────────────────────────────────────────────────

static void *nam_new(t_symbol *, long, t_atom *)
{
    t_nam *x = (t_nam *)object_alloc(s_nam_class);
    if (!x) return nullptr;

    dsp_setup((t_pxobject *)x, 1);  // 1 signal inlet

    // Outlets created innermost-first; the rightmost outlet (highest index
    // in the UI) must be created first.
    x->error_out         = outlet_new(x, (char *)"symbol"); // outlet 3
    x->load_complete_out = bangout(x);                       // outlet 2
    x->meta_out          = outlet_new(x, nullptr);           // outlet 1
    outlet_new(x, "signal");                                  // outlet 0

    x->bypass.store(0);
    x->slim = 0.0;

#if NAM_CORE_AVAILABLE
    x->mModel.store(nullptr);
    x->mStagedModel.store(nullptr);
    x->mWorkerRunning.store(false);
    x->mPendingLoadNotify.store(false);
    x->mPendingErrorNotify.store(false);
    x->mErrorMsg[0] = '\0';
    x->mScratchIn   = nullptr;
    x->mScratchOut  = nullptr;
    x->mScratchSize = 0;
    x->mSampleRate.store(0.0);
    x->mMaxBlock.store(0);

    // Clock for deferred outlet calls from the main thread
    x->mLoadClock = clock_new(x, (method)nam_clock_tick);
#endif

    return x;
}

// ── nam_free ─────────────────────────────────────────────────────────────────

static void nam_free(t_nam *x)
{
    dsp_free((t_pxobject *)x);

#if NAM_CORE_AVAILABLE
    // Stop any in-progress worker thread before freeing model memory.
    if (x->mWorkerThread.joinable()) {
        x->mWorkerThread.join();
    }

    // Free the clock
    if (x->mLoadClock) {
        clock_unset(x->mLoadClock);
        freeobject((t_object *)x->mLoadClock);
        x->mLoadClock = nullptr;
    }

    // Delete both models (the staged one was never swapped in)
    delete x->mModel.exchange(nullptr);
    delete x->mStagedModel.exchange(nullptr);

    // Free scratch buffers
    delete[] x->mScratchIn;
    delete[] x->mScratchOut;
    x->mScratchIn   = nullptr;
    x->mScratchOut  = nullptr;
    x->mScratchSize = 0;
#endif
}

// ── nam_assist ───────────────────────────────────────────────────────────────

static void nam_assist(t_nam *, void *, long m, long a, char *s)
{
    if (m == ASSIST_INLET) {
        snprintf(s, 256, "(signal) audio in / messages: load <path>, reset, bypass 0|1, slim 0..1");
    } else {
        switch (a) {
            case 0: snprintf(s, 256, "(signal) audio out"); break;
            case 1: snprintf(s, 256, "metadata dict (sample_rate, normalized, ...)"); break;
            case 2: snprintf(s, 256, "bang on load-complete"); break;
            case 3: snprintf(s, 256, "error symbol"); break;
        }
    }
}

// ── nam_dsp64 ────────────────────────────────────────────────────────────────

static void nam_dsp64(t_nam *x, t_object *dsp64, short *, double samplerate,
                      long maxvectorsize, long)
{
#if NAM_CORE_AVAILABLE
    // dsp64 runs on the main thread with this object's audio stopped, so it is
    // safe here (and ONLY here, or on the load worker) to Reset/prewarm a model.
    //
    // Make sure no load is in flight, then publish the current SR/block so the
    // next load worker can prewarm against them.
    if (x->mWorkerThread.joinable()) {
        x->mWorkerThread.join();
    }
    x->mSampleRate.store(samplerate);
    x->mMaxBlock.store(maxvectorsize);

    // Allocate scratch buffers sized for the block size.
    // We allocate here (dsp64 callback, main thread before audio starts) — NOT
    // in perform64. This avoids any allocation in the audio callback.
    if (maxvectorsize > x->mScratchSize) {
        delete[] x->mScratchIn;
        delete[] x->mScratchOut;
        x->mScratchIn   = new NAM_SAMPLE[maxvectorsize];
        x->mScratchOut  = new NAM_SAMPLE[maxvectorsize];
        x->mScratchSize = maxvectorsize;
    }

    // Drain a model that was staged while audio was stopped (e.g. loaded from
    // saved device state before DSP started, so the worker could not prewarm it
    // at a known SR). Swapping it in here — rather than leaving it for perform64
    // — lets us prewarm it below on this non-audio thread.
    if (nam::DSP *staged = x->mStagedModel.exchange(nullptr)) {
        delete x->mModel.exchange(staged);
        x->mPendingLoadNotify.store(true);
        clock_delay(x->mLoadClock, 0);
    }

    // Reset + prewarm the live model for the current SR/block. Covers a sample
    // rate change and the cold-load drain above. Safe: audio is stopped during
    // dsp64, so perform64 is not reading the model concurrently.
    if (nam::DSP *live = x->mModel.load()) {
        live->Reset(samplerate, static_cast<int>(maxvectorsize));
        live->prewarm();
    }
#endif
    object_method(dsp64, gensym("dsp_add64"), x, (method)nam_perform64, 0, nullptr);
}

// ── nam_perform64 ────────────────────────────────────────────────────────────
//
// Audio thread. No allocation, no locks, no outlet calls here.
// Outlet notification is deferred via clock_delay (main thread).

static void nam_perform64(t_nam *x, t_object *, double **ins, long,
                          double **outs, long, long sampleframes, long, void *)
{
    double *in  = ins[0];
    double *out = outs[0];

#if NAM_CORE_AVAILABLE
    // ── Staged-swap: bring in a freshly loaded model ──────────────────
    // If a new model is waiting, exchange it atomically into mModel and
    // delete the old one. Set a flag; the clock (main thread) will fire
    // the load-complete bang.
    nam::DSP *staged = x->mStagedModel.exchange(nullptr);
    if (staged) {
        nam::DSP *old = x->mModel.exchange(staged);
        delete old;
        x->mPendingLoadNotify.store(true);
        // Schedule the deferred notification on the main/scheduler thread.
        // clock_delay with 0 ms fires as soon as the main thread is idle.
        clock_delay(x->mLoadClock, 0);
    }

    // ── Process ──────────────────────────────────────────────────────
    nam::DSP *model = x->mModel.load();

    if (!x->bypass.load() && model) {
        // NAM_SAMPLE is double on the pinned core; Max uses double. Convert
        // in → scratch (a no-op copy unless built with NAM_SAMPLE_FLOAT).
        NAM_SAMPLE *scratch_in  = x->mScratchIn;
        NAM_SAMPLE *scratch_out = x->mScratchOut;
        for (long i = 0; i < sampleframes; ++i) {
            scratch_in[i] = static_cast<NAM_SAMPLE>(in[i]);
        }

        // NAM core process(): mono in/out via NAM_SAMPLE** (array of channel pointers).
        // NAM's DSP::process signature (confirmed from NAM core source):
        //   void process(NAM_SAMPLE** inputs, NAM_SAMPLE** outputs, const int numFrames)
        // We pass single-channel arrays.
        model->process(&scratch_in, &scratch_out, static_cast<int>(sampleframes));

        // NAM core's v2 DSP base class advances internal state inside process()
        // itself — there is no separate finalize_(num_frames) call any more
        // (it existed in older NAM core releases; pinned commit on this build
        // is post-removal).

        // Convert scratch_out (float) → out (double)
        for (long i = 0; i < sampleframes; ++i) {
            out[i] = static_cast<double>(scratch_out[i]);
        }
    } else {
        // Bypass or no model: passthrough
        for (long i = 0; i < sampleframes; ++i) out[i] = in[i];
    }

#else
    // Passthrough fallback — NAM core not available
    if (x->bypass.load()) {
        for (long i = 0; i < sampleframes; ++i) out[i] = in[i];
    } else {
        for (long i = 0; i < sampleframes; ++i) out[i] = in[i];
    }
#endif
}

// ── nam_clock_tick ───────────────────────────────────────────────────────────
// Called on the main/scheduler thread (safe to call outlets).

#if NAM_CORE_AVAILABLE
static void nam_clock_tick(t_nam *x)
{
    if (x->mPendingErrorNotify.exchange(false)) {
        outlet_anything(x->error_out, gensym(x->mErrorMsg[0] ? x->mErrorMsg : "load failed"), 0, nullptr);
    }
    if (x->mPendingLoadNotify.exchange(false)) {
        outlet_bang(x->load_complete_out);
    }
}
#endif

// ── nam_load ─────────────────────────────────────────────────────────────────
//
// Spawns a worker thread to call nam::get_dsp(path). Does NOT block the
// message (main) thread. The worker stores the result in mStagedModel; the
// audio thread swaps it in on the next block.

static void nam_load(t_nam *x, t_symbol *s)
{
    if (!s || !s->s_name || s->s_name[0] == '\0') {
        object_error((t_object *)x, "nam~: load requires a path argument");
        return;
    }

#if NAM_CORE_AVAILABLE
    // If a previous worker is still running, join it before starting a new one.
    // (Rapid successive loads: the last one wins; earlier staged models are
    // overwritten in mStagedModel — the audio thread will only ever see the
    // latest one because exchange() replaces whatever is there.)
    if (x->mWorkerThread.joinable()) {
        x->mWorkerThread.join();
    }

    std::string path(s->s_name);

    x->mWorkerRunning.store(true);
    x->mWorkerThread = std::thread([x, path]() {
        try {
            // nam::get_dsp constructs the appropriate DSP subclass (WaveNet,
            // LSTM, etc.) from the .nam JSON file. NAM core has multiple
            // get_dsp overloads — cast through std::filesystem::path to pin
            // the path-taking one and avoid ambiguity with the json-taking
            // overload (std::string converts to both).
            auto dsp = nam::get_dsp(std::filesystem::path(path));

            // Reset + prewarm before staging, off the audio thread, using the
            // SR/block last seen in dsp64. A2 container models REQUIRE this or
            // their process() reads uninitialized submodel state. If dsp64 has
            // not run yet (SR == 0, cold device load), skip — dsp64 will drain
            // and prewarm the staged model when audio starts.
            double sr  = x->mSampleRate.load();
            long   blk = x->mMaxBlock.load();
            if (sr > 0.0 && blk > 0) {
                dsp->Reset(sr, static_cast<int>(blk));
                dsp->prewarm();
            }

            // Store into the staged slot. The audio thread will pick this up
            // on its next block and swap it into mModel.
            // If a previous staged model was never consumed (very fast reload),
            // delete it now.
            nam::DSP *old_staged = x->mStagedModel.exchange(dsp.release());
            delete old_staged;

        } catch (const std::exception &e) {
            snprintf(x->mErrorMsg, sizeof(x->mErrorMsg),
                     "nam~: load failed for '%s': %s", path.c_str(), e.what());
            object_error((t_object *)x, "%s", x->mErrorMsg);
            x->mPendingErrorNotify.store(true);
            clock_delay(x->mLoadClock, 0);
        } catch (...) {
            snprintf(x->mErrorMsg, sizeof(x->mErrorMsg),
                     "nam~: load failed for '%s': unknown exception", path.c_str());
            object_error((t_object *)x, "%s", x->mErrorMsg);
            x->mPendingErrorNotify.store(true);
            clock_delay(x->mLoadClock, 0);
        }
        x->mWorkerRunning.store(false);
    });
    // Thread is detached from the calling code; nam_free will join it.
    // (We keep the thread joinable in mWorkerThread for cleanup.)

    object_post((t_object *)x, "nam~: loading '%s' on worker thread ...", s->s_name);

#else
    // Passthrough fallback — report what would happen
    object_post((t_object *)x, "nam~: load '%s' (NAM core not available — passthrough mode)",
                s->s_name);
#endif
}

// ── nam_reset ────────────────────────────────────────────────────────────────

static void nam_reset(t_nam *x)
{
#if NAM_CORE_AVAILABLE
    nam::DSP *model = x->mModel.load();
    if (model) {
        // NAM core v2 exposes Reset(sampleRate, blockSize); ResetAndPrewarm
        // is the call most tools use after a model load. We don't have the
        // sample rate / block size handy here on the message thread, so the
        // safer behavior on a user-issued "reset" is to log it and let the
        // next dsp64 callback re-Reset the model with the right SR/block.
        object_post((t_object *)x, "nam~: reset acknowledged (model state will refresh on next DSP start)");
    } else {
        object_post((t_object *)x, "nam~: reset (no model loaded)");
    }
#else
    object_post((t_object *)x, "nam~: reset (NAM core not available)");
#endif
}

// ── nam_bypass ───────────────────────────────────────────────────────────────

static void nam_bypass(t_nam *x, long v)
{
    x->bypass.store(v ? 1 : 0);
}

// ── nam_slim ─────────────────────────────────────────────────────────────────

static void nam_slim(t_nam *x, double v)
{
    if (v < 0.0) v = 0.0;
    if (v > 1.0) v = 1.0;
    x->slim = v;
    // TODO (M6): forward slim preference to model when NAM core exposes
    // a per-block "slim" coefficient API (currently internal to some models).
    // For now, storing the value so it's available when needed.
}
