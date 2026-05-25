// namgate_trigger~.cpp — Max external wrapping dsp::noise_gate::Trigger.
// Analyzes pre-model dry audio, emits a sample-rate envelope (linear gain
// factor 0..1) on the right outlet. Downstream namgate_gain~ multiplies that
// envelope into the post-model signal. Split topology mirrors NAM plugin's
// chain order (gate analysis on dry, gate application on wet).
//
// M6: Full implementation integrating NAM core's Trigger when available.
//
// Conditional compilation:
//   If NAM core's noise-gate header is present (NAM_CORE_AVAILABLE=1 set by
//   CMake), the real DSP path is compiled. Otherwise the external emits a
//   constant 1.0 envelope so the rest of the chain stays audible while
//   thirdparty deps are absent.
//
// Inlets:
//   0 — (signal) dry audio in / messages: threshold, ratio, attack, release, holdtime
// Outlets:
//   0 — (signal) dry audio passthrough
//   1 — (signal) envelope (linear gain factor 0..1)

extern "C" {
#include "ext.h"
#include "ext_obex.h"
#include "z_dsp.h"
}

#include <atomic>

// The noise gate lives in NAM core's bundled AudioDSPTools subproject at
// Dependencies/AudioDSPTools/dsp/NoiseGate.h — not under NAM/. CMake puts
// AudioDSPTools/ on the include path so <dsp/NoiseGate.h> resolves.

#ifndef NAM_CORE_AVAILABLE
#  if __has_include(<dsp/NoiseGate.h>)
#    define NAM_CORE_AVAILABLE 1
#  else
#    define NAM_CORE_AVAILABLE 0
#  endif
#endif
// Even if CMake set NAM_CORE_AVAILABLE=1, fall back to passthrough if the
// AudioDSPTools header isn't actually reachable from this translation unit.
#if NAM_CORE_AVAILABLE && !__has_include(<dsp/NoiseGate.h>)
#  undef NAM_CORE_AVAILABLE
#  define NAM_CORE_AVAILABLE 0
#endif

#if NAM_CORE_AVAILABLE
#  include <dsp/NoiseGate.h>
#  include <cmath>     // pow
#endif

typedef struct _namgate_trigger {
    t_pxobject ob;

    // Parameters (defaults match NAM plugin)
    std::atomic<double> threshold;   // dB
    std::atomic<double> ratio;       // unitless
    std::atomic<double> attack;      // seconds (open time)
    std::atomic<double> release;     // seconds (close time)
    std::atomic<double> holdtime;    // seconds

    std::atomic<bool>   params_dirty;
    void               *param_clock;

#if NAM_CORE_AVAILABLE
    dsp::noise_gate::Trigger *trigger;
    double      current_sample_rate;

    // AudioDSPTools uses DSP_SAMPLE (double by default). Trigger::Process
    // expects DSP_SAMPLE** — pointer-to-channel-pointer. We feed mono.
    DSP_SAMPLE *scratch_in;
    DSP_SAMPLE *scratch_in_ptrs[1];
    long        scratch_size;
#endif
} t_namgate_trigger;

static t_class *s_class = nullptr;

static void *ng_new(t_symbol *, long, t_atom *);
static void  ng_free(t_namgate_trigger *);
static void  ng_assist(t_namgate_trigger *, void *, long, long, char *);
static void  ng_dsp64(t_namgate_trigger *, t_object *, short *, double, long, long);
static void  ng_perform64(t_namgate_trigger *, t_object *, double **, long,
                          double **, long, long, long, void *);
static void  ng_threshold(t_namgate_trigger *, double);
static void  ng_ratio(t_namgate_trigger *, double);
static void  ng_attack(t_namgate_trigger *, double);
static void  ng_release(t_namgate_trigger *, double);
static void  ng_holdtime(t_namgate_trigger *, double);
static void  ng_clock_tick(t_namgate_trigger *);

#if NAM_CORE_AVAILABLE
static void  ng_apply_params(t_namgate_trigger *);
#endif

extern "C" void ext_main(void *)
{
    t_class *c = class_new("namgate_trigger~",
                           (method)ng_new, (method)ng_free,
                           (long)sizeof(t_namgate_trigger), 0L, A_GIMME, 0);

    class_addmethod(c, (method)ng_dsp64,      "dsp64",     A_CANT,  0);
    class_addmethod(c, (method)ng_assist,     "assist",    A_CANT,  0);
    class_addmethod(c, (method)ng_threshold,  "threshold", A_FLOAT, 0);
    class_addmethod(c, (method)ng_ratio,      "ratio",     A_FLOAT, 0);
    class_addmethod(c, (method)ng_attack,     "attack",    A_FLOAT, 0);
    class_addmethod(c, (method)ng_release,    "release",   A_FLOAT, 0);
    class_addmethod(c, (method)ng_holdtime,   "holdtime",  A_FLOAT, 0);

    class_dspinit(c);
    class_register(CLASS_BOX, c);
    s_class = c;
}

static void *ng_new(t_symbol *, long, t_atom *)
{
    t_namgate_trigger *x = (t_namgate_trigger *)object_alloc(s_class);
    if (!x) return nullptr;

    dsp_setup((t_pxobject *)x, 1);
    outlet_new(x, "signal");   // outlet 1 — envelope (right)
    outlet_new(x, "signal");   // outlet 0 — dry passthrough (left)

    x->threshold.store(-80.0);
    x->ratio.store(8.0);
    x->attack.store(0.005);
    x->release.store(0.05);
    x->holdtime.store(0.01);
    x->params_dirty.store(true);

    x->param_clock = clock_new(x, (method)ng_clock_tick);

#if NAM_CORE_AVAILABLE
    x->trigger             = new dsp::noise_gate::Trigger();
    x->current_sample_rate = 0.0;
    x->scratch_in          = nullptr;
    x->scratch_in_ptrs[0]  = nullptr;
    x->scratch_size        = 0;
#endif
    return x;
}

static void ng_free(t_namgate_trigger *x)
{
    dsp_free((t_pxobject *)x);

    if (x->param_clock) {
        clock_unset(x->param_clock);
        freeobject((t_object *)x->param_clock);
        x->param_clock = nullptr;
    }

#if NAM_CORE_AVAILABLE
    delete x->trigger;
    x->trigger = nullptr;
    delete[] x->scratch_in;
    x->scratch_in         = nullptr;
    x->scratch_in_ptrs[0] = nullptr;
    x->scratch_size       = 0;
#endif
}

static void ng_assist(t_namgate_trigger *, void *, long m, long a, char *s)
{
    if (m == ASSIST_INLET) {
        snprintf(s, 256, "(signal) dry audio in / threshold, ratio, attack, release, holdtime");
    } else {
        switch (a) {
            case 0: snprintf(s, 256, "(signal) dry audio passthrough"); break;
            case 1: snprintf(s, 256, "(signal) envelope (0..1)"); break;
        }
    }
}

static void ng_dsp64(t_namgate_trigger *x, t_object *dsp64, short *,
                     double samplerate, long maxvectorsize, long)
{
#if NAM_CORE_AVAILABLE
    if (maxvectorsize > x->scratch_size) {
        delete[] x->scratch_in;
        x->scratch_in         = new DSP_SAMPLE[maxvectorsize];
        x->scratch_in_ptrs[0] = x->scratch_in;
        x->scratch_size       = maxvectorsize;
    }

    if (x->trigger && samplerate != x->current_sample_rate) {
        x->trigger->SetSampleRate(samplerate);
        x->current_sample_rate = samplerate;
        ng_apply_params(x);
    }
#endif
    object_method(dsp64, gensym("dsp_add64"), x, (method)ng_perform64, 0, nullptr);
}

// Audio thread. No allocation, no outlet calls.
static void ng_perform64(t_namgate_trigger *x, t_object *, double **ins, long,
                         double **outs, long numouts, long sampleframes, long, void *)
{
    double *in  = ins[0];
    double *out = outs[0];
    double *env = numouts > 1 ? outs[1] : nullptr;

#if NAM_CORE_AVAILABLE
    if (x->trigger && x->scratch_in) {
        // Copy mono input into scratch (DSP_SAMPLE = double in this build);
        // Trigger::Process returns the input passthrough on its return value,
        // and stores the per-sample gain reduction in dB internally.
        for (long i = 0; i < sampleframes; ++i) {
            x->scratch_in[i] = static_cast<DSP_SAMPLE>(in[i]);
            out[i] = in[i];
        }
        (void)x->trigger->Process(x->scratch_in_ptrs, 1, (size_t)sampleframes);

        if (env) {
            // GainReductionDB[channel][sample] — values are ≤ 0 dB (0 = no
            // reduction, more negative = more attenuation). Convert to a
            // linear gain factor that the downstream namgate_gain~ multiplier
            // can apply directly: factor = 10^(db/20).
            auto reduction = x->trigger->GetGainReductionDB();
            if (!reduction.empty() && (long)reduction[0].size() >= sampleframes) {
                const auto &chan0 = reduction[0];
                for (long i = 0; i < sampleframes; ++i) {
                    env[i] = std::pow(10.0, chan0[i] / 20.0);
                }
            } else {
                for (long i = 0; i < sampleframes; ++i) env[i] = 1.0;
            }
        }
        return;
    }
#endif
    // Passthrough fallback — constant unity envelope so downstream gain
    // multiplies by 1.0 and the chain stays audible.
    for (long i = 0; i < sampleframes; ++i) {
        out[i] = in[i];
        if (env) env[i] = 1.0;
    }
}

// ── Parameter setters ────────────────────────────────────────────────────────
// Setters defer to clock_tick so the NAM trigger is only mutated on the
// scheduler thread (serialized with the audio thread by Max).

static void ng_set(t_namgate_trigger *x)
{
    x->params_dirty.store(true);
    if (x->param_clock) clock_delay(x->param_clock, 0);
}

static void ng_threshold(t_namgate_trigger *x, double v) { x->threshold.store(v); ng_set(x); }
static void ng_ratio(t_namgate_trigger *x, double v)     { x->ratio.store(v);     ng_set(x); }
static void ng_attack(t_namgate_trigger *x, double v)    { x->attack.store(v);    ng_set(x); }
static void ng_release(t_namgate_trigger *x, double v)   { x->release.store(v);   ng_set(x); }
static void ng_holdtime(t_namgate_trigger *x, double v)  { x->holdtime.store(v);  ng_set(x); }

#if NAM_CORE_AVAILABLE
static void ng_apply_params(t_namgate_trigger *x)
{
    if (!x->trigger) return;
    // TriggerParams(time, threshold, ratio, openTime, holdTime, closeTime).
    // `time` is the RMS-averaging window used by the level detector — not
    // user-exposed in Max; 5 ms is a sensible default. The other five map
    // directly to our user-facing parameters.
    const double kLevelDetectorTime = 0.005;
    dsp::noise_gate::TriggerParams params(
        kLevelDetectorTime,
        x->threshold.load(),
        x->ratio.load(),
        x->attack.load(),
        x->holdtime.load(),
        x->release.load()
    );
    x->trigger->SetParams(params);
}
#endif

static void ng_clock_tick(t_namgate_trigger *x)
{
    if (!x->params_dirty.exchange(false)) return;
#if NAM_CORE_AVAILABLE
    ng_apply_params(x);
#endif
}
