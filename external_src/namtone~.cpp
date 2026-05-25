// namtone~.cpp — Max external wrapping dsp::tone_stack::BasicNamToneStack.
//
// M6: Full implementation integrating NAM core's tone stack when available.
//
// Conditional compilation:
//   If NAM core's tone-stack header is present (NAM_CORE_AVAILABLE=1 set by
//   CMake), the real DSP path is compiled. Otherwise the external is a
//   passthrough, so build.sh still works while thirdparty deps are absent.
//
// Sample-rate handling:
//   BasicNamToneStack needs sample rate; we call Reset() in dsp64 each time the
//   audio chain reconfigures. NEVER allocate or call Reset in perform64.
//
// Outlets:
//   0 — (signal) audio out
//   1 — params list (bass, mid, treble) emitted on each parameter change;
//       eq_curve.jsui reads this to redraw the response. Computing exact
//       coefficients here would require reaching into NAM core internals;
//       the jsui approximates the Fender Bassman transfer function locally.

extern "C" {
#include "ext.h"
#include "ext_obex.h"
#include "z_dsp.h"
}

#include <atomic>
#include <cstring>

// ── NAM core conditional include ─────────────────────────────────────────────

// The Bassman tone stack (dsp::tone_stack::BasicNamToneStack) lives in the
// NeuralAmpModelerPlugin source tree, not NAM core. CMake vendors the plugin
// under thirdparty/NeuralAmpModelerPlugin/ and compiles ToneStack.cpp +
// RecursiveLinearFilter.cpp + AudioDSPTools/dsp.cpp into this external when
// NAM_TONESTACK_AVAILABLE is defined. Falls back to passthrough otherwise.

#ifndef NAM_TONESTACK_AVAILABLE
#  if __has_include(<NeuralAmpModeler/ToneStack.h>)
#    define NAM_TONESTACK_AVAILABLE 1
#  else
#    define NAM_TONESTACK_AVAILABLE 0
#  endif
#endif
#if NAM_TONESTACK_AVAILABLE && !__has_include(<NeuralAmpModeler/ToneStack.h>)
#  undef NAM_TONESTACK_AVAILABLE
#  define NAM_TONESTACK_AVAILABLE 0
#endif

#if NAM_TONESTACK_AVAILABLE
#  include <NeuralAmpModeler/ToneStack.h>
#endif

// Keep NAM_CORE_AVAILABLE around for the rest of this file so existing
// `#if NAM_CORE_AVAILABLE` blocks below still gate the real DSP path.
#ifndef NAM_CORE_AVAILABLE
#  define NAM_CORE_AVAILABLE NAM_TONESTACK_AVAILABLE
#endif
#if !NAM_TONESTACK_AVAILABLE
#  undef NAM_CORE_AVAILABLE
#  define NAM_CORE_AVAILABLE 0
#endif

// ── Object struct ────────────────────────────────────────────────────────────

typedef struct _namtone {
    t_pxobject  ob;
    void       *meta_out;

    std::atomic<double> bass;
    std::atomic<double> mid;
    std::atomic<double> treble;
    std::atomic<bool>   params_dirty;     // set by setters, drained by clock_tick

    void       *param_clock;               // deferred meta-outlet emission

#if NAM_CORE_AVAILABLE
    dsp::tone_stack::BasicNamToneStack *stack;
    double      current_sample_rate;
    long        current_block_size;

    // DSP_SAMPLE scratch (mono). The tone stack's Process returns pointers
    // into its own internal output buffer, so we only need a writable input
    // array. DSP_SAMPLE is double (AudioDSPTools default).
    DSP_SAMPLE *scratch_in;
    DSP_SAMPLE *scratch_in_ptrs[1];
    long        scratch_size;
#endif
} t_namtone;

static t_class *s_namtone_class = nullptr;

// ── Forward declarations ─────────────────────────────────────────────────────

static void *namtone_new(t_symbol *, long, t_atom *);
static void  namtone_free(t_namtone *);
static void  namtone_assist(t_namtone *, void *, long, long, char *);
static void  namtone_dsp64(t_namtone *, t_object *, short *, double, long, long);
static void  namtone_perform64(t_namtone *, t_object *, double **, long,
                               double **, long, long, long, void *);
static void  namtone_bass(t_namtone *, double);
static void  namtone_mid(t_namtone *, double);
static void  namtone_treble(t_namtone *, double);
static void  namtone_clock_tick(t_namtone *);

#if NAM_CORE_AVAILABLE
static void  namtone_apply_params(t_namtone *);
#endif

// ── ext_main ─────────────────────────────────────────────────────────────────

extern "C" void ext_main(void *)
{
    t_class *c = class_new("namtone~",
                           (method)namtone_new, (method)namtone_free,
                           (long)sizeof(t_namtone), 0L, A_GIMME, 0);

    class_addmethod(c, (method)namtone_dsp64,   "dsp64",  A_CANT,  0);
    class_addmethod(c, (method)namtone_assist,  "assist", A_CANT,  0);
    class_addmethod(c, (method)namtone_bass,    "bass",   A_FLOAT, 0);
    class_addmethod(c, (method)namtone_mid,     "mid",    A_FLOAT, 0);
    class_addmethod(c, (method)namtone_treble,  "treble", A_FLOAT, 0);

    class_dspinit(c);
    class_register(CLASS_BOX, c);
    s_namtone_class = c;
}

// ── namtone_new ──────────────────────────────────────────────────────────────

static void *namtone_new(t_symbol *, long, t_atom *)
{
    t_namtone *x = (t_namtone *)object_alloc(s_namtone_class);
    if (!x) return nullptr;

    dsp_setup((t_pxobject *)x, 1);

    // Outlets: innermost-first → meta_out (right) then signal (left).
    x->meta_out = outlet_new(x, nullptr);
    outlet_new(x, "signal");

    x->bass.store(5.0);
    x->mid.store(5.0);
    x->treble.store(5.0);
    x->params_dirty.store(true);

    x->param_clock = clock_new(x, (method)namtone_clock_tick);

#if NAM_CORE_AVAILABLE
    x->stack               = new dsp::tone_stack::BasicNamToneStack();
    x->current_sample_rate = 0.0;
    x->current_block_size  = 0;
    x->scratch_in          = nullptr;
    x->scratch_in_ptrs[0]  = nullptr;
    x->scratch_size        = 0;
#endif
    return x;
}

// ── namtone_free ─────────────────────────────────────────────────────────────

static void namtone_free(t_namtone *x)
{
    dsp_free((t_pxobject *)x);

    if (x->param_clock) {
        clock_unset(x->param_clock);
        freeobject((t_object *)x->param_clock);
        x->param_clock = nullptr;
    }

#if NAM_CORE_AVAILABLE
    delete x->stack;
    x->stack = nullptr;
    delete[] x->scratch_in;
    x->scratch_in         = nullptr;
    x->scratch_in_ptrs[0] = nullptr;
    x->scratch_size       = 0;
#endif
}

// ── namtone_assist ───────────────────────────────────────────────────────────

static void namtone_assist(t_namtone *, void *, long m, long a, char *s)
{
    if (m == ASSIST_INLET) {
        snprintf(s, 256, "(signal) audio in / messages: bass/mid/treble 0..10");
    } else {
        switch (a) {
            case 0: snprintf(s, 256, "(signal) audio out"); break;
            case 1: snprintf(s, 256, "params list (bass, mid, treble) on change"); break;
        }
    }
}

// ── namtone_dsp64 ────────────────────────────────────────────────────────────

static void namtone_dsp64(t_namtone *x, t_object *dsp64, short *,
                          double samplerate, long maxvectorsize, long)
{
#if NAM_CORE_AVAILABLE
    if (maxvectorsize > x->scratch_size) {
        delete[] x->scratch_in;
        x->scratch_in         = new DSP_SAMPLE[maxvectorsize];
        x->scratch_in_ptrs[0] = x->scratch_in;
        x->scratch_size       = maxvectorsize;
    }

    if (x->stack &&
        (samplerate  != x->current_sample_rate ||
         maxvectorsize != x->current_block_size)) {
        x->stack->Reset(samplerate, (int)maxvectorsize);
        x->current_sample_rate = samplerate;
        x->current_block_size  = maxvectorsize;
        // Re-apply parameters after reset (BasicNamToneStack's Reset reconfigures
        // its biquad coefficients but doesn't push our stored knob positions —
        // do that ourselves).
        namtone_apply_params(x);
    }
#endif
    object_method(dsp64, gensym("dsp_add64"), x, (method)namtone_perform64, 0, nullptr);
}

// ── namtone_perform64 ────────────────────────────────────────────────────────
// Audio thread. No allocation, no outlet calls.

static void namtone_perform64(t_namtone *x, t_object *, double **ins, long,
                              double **outs, long, long sampleframes, long, void *)
{
    double *in  = ins[0];
    double *out = outs[0];

#if NAM_CORE_AVAILABLE
    if (x->stack && x->scratch_in) {
        for (long i = 0; i < sampleframes; ++i) {
            x->scratch_in[i] = static_cast<DSP_SAMPLE>(in[i]);
        }
        // BasicNamToneStack::Process(inputs, numChannels, numFrames) returns
        // a pointer-to-channel-pointers into its own output buffer.
        DSP_SAMPLE **proc_out =
            x->stack->Process(x->scratch_in_ptrs, 1, (int)sampleframes);

        if (proc_out && proc_out[0]) {
            for (long i = 0; i < sampleframes; ++i) {
                out[i] = static_cast<double>(proc_out[0][i]);
            }
        } else {
            for (long i = 0; i < sampleframes; ++i) out[i] = in[i];
        }
        return;
    }
#endif
    // Passthrough fallback
    for (long i = 0; i < sampleframes; ++i) out[i] = in[i];
}

// ── Parameter setters ────────────────────────────────────────────────────────
//
// Setters are called on the main thread (from live.dial). They store into
// atomics and schedule a clock_delay to (a) push the values into the NAM
// stack and (b) emit the params list on the meta outlet. We do NOT touch the
// NAM stack from the message thread directly — the audio thread could be in
// Process when the setter fires. clock_delay defers to the scheduler thread,
// which is serialized with the audio thread by Max.

static void namtone_bass(t_namtone *x, double v)
{
    x->bass.store(v);
    x->params_dirty.store(true);
    if (x->param_clock) clock_delay(x->param_clock, 0);
}

static void namtone_mid(t_namtone *x, double v)
{
    x->mid.store(v);
    x->params_dirty.store(true);
    if (x->param_clock) clock_delay(x->param_clock, 0);
}

static void namtone_treble(t_namtone *x, double v)
{
    x->treble.store(v);
    x->params_dirty.store(true);
    if (x->param_clock) clock_delay(x->param_clock, 0);
}

#if NAM_CORE_AVAILABLE
static void namtone_apply_params(t_namtone *x)
{
    if (!x->stack) return;
    // BasicNamToneStack::SetParam expects lowercase names. Knob values are in
    // 0..10 with 5 = noon (documented on the BasicNamToneStack class).
    x->stack->SetParam("bass",   x->bass.load());
    x->stack->SetParam("middle", x->mid.load());
    x->stack->SetParam("treble", x->treble.load());
}
#endif

// ── Clock tick ───────────────────────────────────────────────────────────────
// Main/scheduler thread: safe to call outlets and to mutate NAM state.

static void namtone_clock_tick(t_namtone *x)
{
    if (!x->params_dirty.exchange(false)) return;

#if NAM_CORE_AVAILABLE
    namtone_apply_params(x);
#endif

    // Emit (bass, mid, treble) on the meta outlet so eq_curve.jsui can redraw.
    t_atom params[3];
    atom_setfloat(&params[0], x->bass.load());
    atom_setfloat(&params[1], x->mid.load());
    atom_setfloat(&params[2], x->treble.load());
    outlet_list(x->meta_out, nullptr, 3, params);
}
