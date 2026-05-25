// nam_collapse.js — Max-JS file. Manages TONE/IR section collapse-expand.
//
// Tone and IR toggles are INDEPENDENT. When Tone is off but IR is on,
// the IR section slides left by 320 px to fill the gap.
//
// Four legal states:
//   Tone on,  IR on  → show TONE, show IR at original x, width 960
//   Tone on,  IR off → show TONE, hide IR,                width 640
//   Tone off, IR on  → hide TONE, show IR shifted -320px, width 640
//   Tone off, IR off → hide TONE, hide IR,                width 320
//
// Inlets:
//   0 — tone_expand_toggle output (int 0/1)
//   1 — ir_expand_toggle output   (int 0/1)
//
// Outlets:
//   0 — "script show/hide/sendbox <varname> ..." → thispatcher
//   1 — "setwidth <px>"                          → live.thisdevice

inlets = 2;
outlets = 2;
autowatch = 1;

var OUT_PATCHER = 0;
var OUT_WIDTH   = 1;

var TONE_VARS = [
    "eq_curve_jsui",
    "nam_blend_dial", "gate_thresh_dial",
    "bass_dial", "mid_dial", "treble_dial",
    "ir_blend_dial",
    "gate_on_toggle", "tone_on_toggle"
];

// Keep in sync with build_combined_maxpat.py presentation_rect values.
var IR_LAYOUT = {
    "ir_live_drop":       [642,   0, 320, 100],
    "ir_waveform":        [642,   0, 320, 100],
    "dur_display":        [644,   2,  62,  14],
    "ir_cat_menu":        [664, 100, 276,  22],
    "ir_file_menu":       [664, 122, 276,  22],
    "btn_ir_cat_prev":    [642, 100,  22,  22],
    "btn_ir_cat_next":    [940, 100,  22,  22],
    "btn_ir_prev":        [642, 122,  22,  22],
    "btn_ir_next":        [940, 122,  22,  22],
    "btn_ir_root":        [642, 144, 100,  22],
    "trim_pfx_toggle_ir": [746, 148,  14,  14],
    "lbl_trim_ir":        [763, 148,  28,  14],
    "ir_on_toggle":       [794, 144, 168,  22]
};

var IR_VARS = [
    "ir_live_drop", "ir_waveform", "dur_display",
    "ir_cat_menu", "ir_file_menu",
    "btn_ir_cat_prev", "btn_ir_cat_next",
    "btn_ir_prev", "btn_ir_next",
    "btn_ir_root", "trim_pfx_toggle_ir", "lbl_trim_ir",
    "ir_on_toggle"
];

var WIDTH_NAM         = 320;
var WIDTH_NAM_TONE    = 640;
var WIDTH_NAM_IR      = 642;  // NAM + 2px gap + IR (no Tone)
var WIDTH_NAM_TONE_IR = 962;

var tone_on = 1;
var ir_on   = 1;

function _repositionIR(shift_left) {
    var i, name, r, x;
    for (i = 0; i < IR_VARS.length; i++) {
        name = IR_VARS[i];
        r = IR_LAYOUT[name];
        x = shift_left ? r[0] - 320 : r[0];
        outlet(OUT_PATCHER, "script", "sendbox", name, "presentation_rect", x, r[1], r[2], r[3]);
    }
}

function _apply() {
    var i, w;
    // Show/hide first, then reposition.
    for (i = 0; i < TONE_VARS.length; i++) {
        outlet(OUT_PATCHER, "script", tone_on ? "show" : "hide", TONE_VARS[i]);
    }
    for (i = 0; i < IR_VARS.length; i++) {
        outlet(OUT_PATCHER, "script", ir_on ? "show" : "hide", IR_VARS[i]);
    }
    // Reposition IR: shift left when Tone is hidden but IR is shown.
    _repositionIR(!tone_on && ir_on);
    // Width: 968 both on, 640 tone only, 648 IR only (NAM+gap+IR), 320 none.
    if (tone_on && ir_on)        w = WIDTH_NAM_TONE_IR;
    else if (tone_on && !ir_on)  w = WIDTH_NAM_TONE;
    else if (!tone_on && ir_on)  w = WIDTH_NAM_IR;
    else                         w = WIDTH_NAM;
    outlet(OUT_WIDTH, "setwidth", w);
}

function msg_int(v) {
    var val = v ? 1 : 0;
    if (inlet === 0) {
        tone_on = val;
    } else {
        ir_on = val;
    }
    _apply();
}
