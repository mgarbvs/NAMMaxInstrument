// namgate_gain~.cpp — Max external applying a sample-rate envelope (sidechain
// from namgate_trigger~) to the post-model signal. The split-gate topology
// mirrors NAM plugin's chain order: Trigger reads dry pre-model audio and
// emits an envelope; Gain multiplies that envelope into the post-model audio.
//
// No NAM core dependency here — the math is just out[i] = in[i] * env[i].
// (NAM core's dsp::noise_gate::Gain reads the same envelope internally via a
// pointer to Trigger's gain-reduction array. Our Max-side split moves that
// coupling out of band into a signal connection — cleaner for the patcher,
// and avoids any shared-state lifetime concerns between the two externals.)
//
// Inlets:
//   0 — (signal) audio in (post-model)
//   1 — (signal) envelope (linear gain factor 0..1) from namgate_trigger~
// Outlets:
//   0 — (signal) gated audio

extern "C" {
#include "ext.h"
#include "ext_obex.h"
#include "z_dsp.h"
}

typedef struct _namgate_gain {
    t_pxobject ob;
} t_namgate_gain;

static t_class *s_class = nullptr;

static void *gg_new(t_symbol *, long, t_atom *);
static void  gg_free(t_namgate_gain *);
static void  gg_assist(t_namgate_gain *, void *, long, long, char *);
static void  gg_dsp64(t_namgate_gain *, t_object *, short *, double, long, long);
static void  gg_perform64(t_namgate_gain *, t_object *, double **, long,
                          double **, long, long, long, void *);

extern "C" void ext_main(void *)
{
    t_class *c = class_new("namgate_gain~",
                           (method)gg_new, (method)gg_free,
                           (long)sizeof(t_namgate_gain), 0L, A_GIMME, 0);

    class_addmethod(c, (method)gg_dsp64,  "dsp64",  A_CANT, 0);
    class_addmethod(c, (method)gg_assist, "assist", A_CANT, 0);

    class_dspinit(c);
    class_register(CLASS_BOX, c);
    s_class = c;
}

static void *gg_new(t_symbol *, long, t_atom *)
{
    t_namgate_gain *x = (t_namgate_gain *)object_alloc(s_class);
    if (!x) return nullptr;

    dsp_setup((t_pxobject *)x, 2);
    outlet_new(x, "signal");
    return x;
}

static void gg_free(t_namgate_gain *x)
{
    dsp_free((t_pxobject *)x);
}

static void gg_assist(t_namgate_gain *, void *, long m, long a, char *s)
{
    if (m == ASSIST_INLET) {
        switch (a) {
            case 0: snprintf(s, 256, "(signal) audio in (post-model)"); break;
            case 1: snprintf(s, 256, "(signal) envelope (0..1) from namgate_trigger~"); break;
        }
    } else {
        snprintf(s, 256, "(signal) audio out (gated)");
    }
}

static void gg_dsp64(t_namgate_gain *x, t_object *dsp64, short *, double, long, long)
{
    object_method(dsp64, gensym("dsp_add64"), x, (method)gg_perform64, 0, nullptr);
}

static void gg_perform64(t_namgate_gain *, t_object *, double **ins, long,
                         double **outs, long, long sampleframes, long, void *)
{
    double *in  = ins[0];
    double *env = ins[1];
    double *out = outs[0];
    for (long i = 0; i < sampleframes; ++i) {
        out[i] = in[i] * env[i];
    }
}
