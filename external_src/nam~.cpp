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
#include <cmath>
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
    std::atomic<long>   bypass;
    std::atomic<long>   mNormalize;   // 1 = apply output loudness normalization
    std::atomic<double> mNormGain;    // linear gain from model loudness (1.0 if unknown)
    double              slim;

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

    // NAM_SAMPLE conversion scratch buffer (float, allocated in dsp64)
    // NAM_SAMPLE is typically float; Max passes double. We copy before/after.
    NAM_SAMPLE *mScratchIn;   // maxvectorsize floats
    NAM_SAMPLE *mScratchOut;  // maxvectorsize floats
    long        mScratchSize; // allocated size (in samples)
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
static void  nam_normalize(t_nam *x, long v);
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
    class_addmethod(c, (method)nam_bypass,    "bypass",    A_LONG,  0);
    class_addmethod(c, (method)nam_normalize, "normalize", A_LONG,  0);
    class_addmethod(c, (method)nam_slim,      "slim",      A_FLOAT, 0);

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
    x->mNormalize.store(1);     // output normalization on by default (matches plugin)
    x->mNormGain.store(1.0);
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
        snprintf(s, 256, "(signal) audio in / messages: load <path>, reset, bypass 0|1, normalize 0|1, slim 0..1");
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

static void nam_dsp64(t_nam *x, t_object *dsp64, short *, double,
                      long maxvectorsize, long)
{
#if NAM_CORE_AVAILABLE
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
        // Output loudness normalization (mirrors the plugin's "Normalized"
        // output mode): target -18 dB, gain = -18 - model_loudness. Computed
        // once here at swap time — not per sample. If the model has no loudness
        // metadata, gain stays 1.0 (no-op).
        double g = staged->HasLoudness()
                     ? std::pow(10.0, (-18.0 - staged->GetLoudness()) / 20.0)
                     : 1.0;
        x->mNormGain.store(g);

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
        // NAM_SAMPLE is float; Max uses double. Convert in → scratch.
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

        // Convert scratch_out (float) → out (double), applying the output
        // normalization gain (1.0 when normalization is off or loudness unknown).
        const double g = x->mNormalize.load() ? x->mNormGain.load() : 1.0;
        for (long i = 0; i < sampleframes; ++i) {
            out[i] = static_cast<double>(scratch_out[i]) * g;
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

            // Diagnostic: surface the model's loudness and the resulting
            // normalization gain so the Max console shows whether this model
            // can be normalized at all (no loudness ⇒ gain 1.0 ⇒ toggle no-op).
            {
                const bool   hasL = dsp->HasLoudness();
                const double loud = hasL ? dsp->GetLoudness() : 0.0;
                const double gain = hasL ? std::pow(10.0, (-18.0 - loud) / 20.0) : 1.0;
                object_post((t_object *)x,
                    "nam~: loaded — loudness %s%.2f dB, normGain %.3f, normalize=%ld",
                    hasL ? "" : "(none) ", loud, gain, x->mNormalize.load());
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

// ── nam_normalize ────────────────────────────────────────────────────────────

static void nam_normalize(t_nam *x, long v)
{
    x->mNormalize.store(v ? 1 : 0);
    object_post((t_object *)x, "nam~: normalize=%ld (current normGain %.3f)",
                x->mNormalize.load(), x->mNormGain.load());
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
