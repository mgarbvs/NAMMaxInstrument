#!/usr/bin/env python3
"""build_nam_maxpat.py — emit m4l/NAM.maxpat.

Full NAM + TONE + IR instrument in a single 962 × 166 px device.
Three sections: NAM Amp Head (320) | Gate + Tone Stack (320) | 2px gap | IR Cabinet (320).

Signal chain:
  plugin~ L+R → +~ → *~0.5
    → in_gain ─┬─► bypass_dry_delay (whole-device bypass dry tap)
               ├─► namgate_trigger~ (gate envelope sidechain)
               └─► nam~
                     └─► namgate_gain~ → gate_sel (gate on/off hard bypass)
                           gate_sel ──► nam_blend_sum~ inlet 1 (wet)
                in_gain ──────────────► nam_blend_sum~ inlet 0 (dry)
                nam_blend_dial ────────► nam_blend_sum~ inlet 2 (position)
                nam_blend_sum~ ─┬──► namtone~ → tone_sel inlet 2 (tone wet)
                                  └──► tone_sel inlet 1 (tone bypass dry)
                tone_sel ─┬──► irconv~ (wet path)
                          └──► ir_blend_dry_delay (dry tap, latency-matched)
                irconv~ ─────────────► ir_blend_sum~ inlet 1 (wet)
                ir_blend_dry_delay ──► ir_blend_sum~ inlet 0 (dry)
                ir_blend_dry_delay ──► ir_sel inlet 1 (IR-off bypass)
                ir_blend_dial ────────► ir_blend_sum~ inlet 2 (position)
                ir_blend_sum~ ─────► ir_sel inlet 2 (IR-on blended)
                ir_sel → out_gain → bypass_sel → plugout~ L+R

PDC: irconv~ outlet 1 "latency N" → lat_trig (t i i i):
  outlet 0 → ir_blend_dry_delay right inlet
  outlet 1 → msg_latency → defer → live.thisdevice
  outlet 2 → bypass_dry_delay right inlet

State: nam_state.js (Node-for-Max) + nam_loader.js (Max-JS, 7 outlets).
"""
import json
import os
import re
import sys

# ── Library roots (baked into Push 3 parameter_enum at build time) ───────────
# Edit these paths if the library moves, then rebuild + reload device.
NAM_ROOT = os.path.expanduser("~/Documents/NAM/Models")
IR_ROOT  = os.path.expanduser("~/Documents/NAM/IRs")


def _scan_subdirs(root):
    try:
        return sorted(n for n in os.listdir(root)
                      if not n.startswith(".") and os.path.isdir(os.path.join(root, n)))
    except OSError:
        return []


def _scan_files(root, exts):
    try:
        return sorted(n for n in os.listdir(root)
                      if not n.startswith(".") and any(n.lower().endswith(e) for e in exts))
    except OSError:
        return []


def _common_prefix(strs):
    if not strs:
        return ""
    p = strs[0]
    for s in strs[1:]:
        j = 0
        while j < len(p) and j < len(s) and p[j] == s[j]:
            j += 1
        p = p[:j]
        if not p:
            return ""
    return p


def _trim_to_word_bound(s):
    i = len(s)
    while i > 0 and s[i - 1] != " ":
        i -= 1
    return s[:i]


def _make_display_names(filenames, strip_ext_re):
    noext = [re.sub(strip_ext_re, "", n, flags=re.IGNORECASE) for n in filenames]
    prefix = _trim_to_word_bound(_common_prefix(noext)) if len(filenames) > 1 else ""
    result = []
    for n in noext:
        d = re.sub(r"^[\s\-_]+", "", n[len(prefix):]) if prefix else n
        result.append(d or n)
    return result


def _build_push_enums():
    """Scan library at build time and return enum arrays for shadow menus.

    Keys: nam_cat_idx, ir_cat_idx, nam_model_idx (cat0, compat), ir_file_idx (cat0, compat),
    Model0..ModelN (per-category NAM), IRFile0..IRFileM (per-category IR).
    """
    nam_cats = _scan_subdirs(NAM_ROOT) or [""]
    ir_cats  = _scan_subdirs(IR_ROOT)  or [""]

    result = {
        "nam_cat_idx": nam_cats,
        "ir_cat_idx":  ir_cats,
    }

    for i, cat in enumerate(nam_cats):
        if cat:
            files = _scan_files(os.path.join(NAM_ROOT, cat), [".nam"])
            result[f"Model{i}"] = _make_display_names(files, r"\.[nN][aA][mM]$") if files else [""]
        else:
            result[f"Model{i}"] = [""]

    for i, cat in enumerate(ir_cats):
        if cat:
            files = _scan_files(os.path.join(IR_ROOT, cat), [".wav", ".aif", ".aiff"])
            result[f"IRFile{i}"] = _make_display_names(files, r"\.(wav|aif|aiff)$") if files else [""]
        else:
            result[f"IRFile{i}"] = [""]

    # Backward-compat keys used by tests and the original single-menu boxes.
    result["nam_model_idx"] = result.get("Model0", [""])
    result["ir_file_idx"]   = result.get("IRFile0", [""])

    return result


_PUSH_ENUMS = _build_push_enums()

# ── Presentation offset for the combined device ──────────────────────────────
# Non-presentation patching objects use absolute (x, y); presentation objects
# use (px+1100, py+400) to keep patching view distinct from other scripts.
_PX_OFF = 1100
_PY_OFF = 400


def box(**kw):
    return {"box": kw}


def line(src_id, src_outlet, dst_id, dst_inlet=0):
    return {"patchline": {"source": [src_id, src_outlet], "destination": [dst_id, dst_inlet]}}


def newobj(bid, text, x, y, numinlets=1, numoutlets=1, outlettype=None, w=200):
    ot = outlettype if outlettype is not None else [""]
    return box(
        id=bid, maxclass="newobj",
        numinlets=numinlets, numoutlets=numoutlets, outlettype=ot,
        patching_rect=[x, y, w, 22],
        text=text, varname=bid,
    )


def msgbox(bid, content, x, y, w=200):
    return box(
        id=bid, maxclass="message",
        numinlets=2, numoutlets=1, outlettype=[""],
        patching_rect=[x, y, w, 22],
        text=content, varname=bid,
    )


def pattr_obj(bid, name, x, y):
    return box(
        id=bid, maxclass="newobj",
        numinlets=2, numoutlets=2, outlettype=["", ""],
        patching_rect=[x, y, 200, 22],
        text=f"pattr {name} @autorestore 1 @type symbol",
        varname=bid,
    )


def comment_box(bid, text, px, py, pw, ph, fontsize=10):
    return box(
        id=bid, maxclass="comment",
        numinlets=1, numoutlets=0,
        patching_rect=[px + _PX_OFF, py + _PY_OFF, pw, ph],
        presentation=1, presentation_rect=[px, py, pw, ph],
        text=text, fontsize=fontsize, varname=bid,
    )


def live_gain(bid, longname, shortname, px, py, pw=55, ph=90):
    return box(
        id=bid, maxclass="live.gain~",
        numinlets=2, numoutlets=5,
        outlettype=["signal", "signal", "float", "float", "list"],
        patching_rect=[px + _PX_OFF, py + _PY_OFF, pw, ph],
        presentation=1, presentation_rect=[px, py, pw, ph],
        parameter_enable=1,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": longname,
            "parameter_shortname": shortname,
            "parameter_type": 0,
            "parameter_unitstyle": 4,
            "parameter_mmin": -36.0,
            "parameter_mmax": 36.0,
            "parameter_initial_enable": 1,
            "parameter_initial": [0.0],
        }},
        varname=bid,
    )


def live_dial(bid, longname, shortname, px, py, pw, ph,
              lo, hi, default, unitstyle=0, modmode=2, steps=0):
    valueof = {
        "parameter_longname": longname,
        "parameter_shortname": shortname,
        "parameter_type": 0,
        "parameter_mmin": float(lo),
        "parameter_mmax": float(hi),
        "parameter_initial_enable": 1,
        "parameter_initial": [float(default)],
        "parameter_unitstyle": unitstyle,
        "parameter_modmode": modmode,
    }
    if steps:
        valueof["parameter_steps"] = steps
    return box(
        id=bid, maxclass="live.dial",
        numinlets=1, numoutlets=2, outlettype=["", "float"],
        patching_rect=[px + _PX_OFF, py + _PY_OFF, pw, ph],
        presentation=1, presentation_rect=[px, py, pw, ph],
        parameter_enable=1,
        saved_attribute_attributes={"valueof": valueof},
        varname=bid,
    )


def live_text_toggle(bid, longname, shortname, default, px, py, pw=80, ph=22,
                     text="off", texton="on", enum=None):
    enum_vals = list(enum) if enum is not None else [text, texton]
    return box(
        id=bid, maxclass="live.text",
        numinlets=1, numoutlets=2, outlettype=["int", "int"],
        patching_rect=[px + _PX_OFF, py + _PY_OFF, pw, ph],
        presentation=1, presentation_rect=[px, py, pw, ph],
        parameter_enable=1, mode=1,
        text=text, texton=texton,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": longname,
            "parameter_shortname": shortname,
            "parameter_type": 2,
            "parameter_enum": enum_vals,
            "parameter_initial_enable": 1,
            "parameter_initial": [default],
        }},
        varname=bid,
    )


def live_text_button(bid, label, longname, shortname, px, py, pw=100, ph=22):
    return box(
        id=bid, maxclass="live.text",
        numinlets=1, numoutlets=2, outlettype=["int", "int"],
        patching_rect=[px + _PX_OFF, py + _PY_OFF, pw, ph],
        presentation=1, presentation_rect=[px, py, pw, ph],
        parameter_enable=1, mode=0,
        text=label, texton=label,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": longname,
            "parameter_shortname": shortname,
            "parameter_type": 2,
            "parameter_enum": ["val1", "val2"],
            "parameter_initial_enable": 1,
            "parameter_initial": [0],
        }},
        varname=bid,
    )


def live_nav_button(bid, label, longname, shortname, px, py):
    b = live_text_button(bid, label, longname, shortname, px, py, pw=22, ph=22)
    b["box"]["saved_attribute_attributes"]["valueof"]["parameter_invisible"] = 1
    return b


def live_push_menu(bid, longname, shortname, py_patch=320):
    """Hidden live.menu for Push 3 encoder control.

    parameter_enable 1 so it appears on Push; hidden 1 so it stays out of
    the Max patch view. Enum is baked from the library scan at build time so
    Push shows real names after a device reload + power cycle.
    """
    enum = _PUSH_ENUMS.get(bid) or [str(i) for i in range(1, 101)]
    return box(
        id=bid, maxclass="live.menu",
        numinlets=1, numoutlets=2, outlettype=["int", "bang"],
        patching_rect=[940, py_patch, 60, 22],
        parameter_enable=1,
        hidden=1,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": longname,
            "parameter_shortname": shortname,
            "parameter_type": 2,
            "parameter_enum": enum,
            "parameter_initial_enable": 1,
            "parameter_initial": [0],
        }},
        varname=bid,
    )


def display_toggle(bid, longname, shortname, default, text, texton,
                   px, py, pw=80, ph=22):
    """Visible live.text toggle that mirrors a hidden live.menu shadow.

    It must stay a real parameter (parameter_enable 1) — a parameter_enable 0
    live.text does NOT hold or draw toggle state when clicked. parameter_invisible
    1 ("Stored Only") keeps it out of Push and the automation lane, exactly like
    the prev/next nav buttons; the automatable/Push-facing parameter is the shadow
    live.menu (live_onoff_menu), which carries the banked longname and surfaces
    Off/On to Push. The two are wired bidirectionally so they stay in sync."""
    return box(
        id=bid, maxclass="live.text",
        numinlets=1, numoutlets=2, outlettype=["int", "int"],
        patching_rect=[px + _PX_OFF, py + _PY_OFF, pw, ph],
        presentation=1, presentation_rect=[px, py, pw, ph],
        parameter_enable=1, mode=1,
        text=text, texton=texton,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": longname,
            "parameter_shortname": shortname,
            "parameter_type": 2,
            "parameter_enum": [text, texton],
            "parameter_invisible": 1,
            "parameter_initial_enable": 1,
            "parameter_initial": [default],
        }},
        varname=bid,
    )


def live_onoff_menu(bid, longname, shortname, default, py_patch=320):
    """Hidden live.menu (Off/On) carrying a boolean-style parameter for Push.

    live.menu is the only control class that surfaces its enum names to Push 3,
    so each on/off toggle's Live parameter lives here (same longname as the old
    live.text, so Push banks and nam_loader.js still resolve). hidden 1 keeps it
    out of the Max patch view; the visible display_toggle mirrors it on desktop."""
    return box(
        id=bid, maxclass="live.menu",
        numinlets=1, numoutlets=2, outlettype=["int", "bang"],
        patching_rect=[940, py_patch, 60, 22],
        parameter_enable=1,
        hidden=1,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": longname,
            "parameter_shortname": shortname,
            "parameter_type": 2,
            "parameter_enum": ["Off", "On"],
            "parameter_initial_enable": 1,
            "parameter_initial": [default],
        }},
        varname=bid,
    )


def live_toggle(bid, longname, shortname, default, px, py):
    """14×14 live.toggle checkbox."""
    return box(
        id=bid, maxclass="live.toggle",
        numinlets=1, numoutlets=1, outlettype=["int"],
        patching_rect=[px + _PX_OFF, py + _PY_OFF, 14, 14],
        presentation=1, presentation_rect=[px, py, 14, 14],
        parameter_enable=1,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": longname,
            "parameter_shortname": shortname,
            "parameter_type": 1,
            "parameter_initial_enable": 1,
            "parameter_initial": [default],
        }},
        varname=bid,
    )


# Push 3 parameter bank baked into the saved device. Each slot names a parameter
# by its longname; baking this means the device reports bank_count>0 the instant
# Live loads it — before nam_loader.js runs — so Push shows this one curated bank
# instead of one encoder column per (hidden) shadow parameter. Without it, the
# bank is only created at runtime via live.banks `new`, which loses the race
# against Push's first device enumeration (the all-columns-on-first-load bug).
_PUSH_BANK_PARAMS = [
    "NAM Cat", "NAM Model 0", "NAM Dry/Wet", "IR Cat",
    "IR File 0", "IR Dry/Wet", "Noise Gate Threshold", "Noise Gate On",
]

# Push bank 1: the tone stack + levels. These params are static (no per-category
# swapping), so unlike bank 0 the runtime JS never edits this bank. Curating them
# here gives Push a named "Tone" page instead of leaving them in the auto main bank.
_PUSH_TONE_BANK_PARAMS = [
    "Input", "NAM Out", "Bass", "Mid",
    "Treble", "Tone Stack On", "IR On", "Bypass",
]


def _build_parameters_block(boxes):
    """Generate patcher.parameters: a {varname: [longname, shortname, 0]} registry
    of every parameter object, plus the baked Push bank. Derived from the boxes so
    it can never drift from the actual parameters in the patch."""
    registry = {}
    for b in boxes:
        inner = b["box"]
        vn = inner.get("varname")
        saa = inner.get("saved_attribute_attributes")
        if not vn or not saa:
            continue
        vo = saa.get("valueof") or {}
        longname = vo.get("parameter_longname")
        if longname is None:
            continue
        registry[vn] = [longname, vo.get("parameter_shortname", longname), 0]

    longnames = {entry[0] for entry in registry.values()}
    for slot in _PUSH_BANK_PARAMS + _PUSH_TONE_BANK_PARAMS:
        if slot != "-" and slot not in longnames:
            raise ValueError(
                "Push bank slot %r has no matching parameter longname in the patch" % slot
            )

    registry["parameterbanks"] = {
        "0": {
            "index": 0,
            "name": "NAM",
            "parameters": list(_PUSH_BANK_PARAMS),
            "buttons": ["-"] * 8,
        },
        "1": {
            "index": 1,
            "name": "Tone",
            "parameters": list(_PUSH_TONE_BANK_PARAMS),
            "buttons": ["-"] * 8,
        },
    }
    registry["inherited_shortname"] = 1
    return registry


def build():
    boxes = []
    lines = []

    # ── Audio I/O + thisdevice ────────────────────────────────────────────────
    # NOTE: amp_fpic and ir_waveform are appended AFTER their live.drops so
    # they sit behind them. In Max presentation z-order: earlier = frontmost.
    boxes.append(box(
        id="thisdev", maxclass="newobj", numinlets=1, numoutlets=3,
        outlettype=["bang", "int", "int"],
        patching_rect=[30, 30, 110, 22], text="live.thisdevice", varname="thisdev",
    ))
    boxes.append(box(
        id="plugin", maxclass="newobj", numinlets=2, numoutlets=2,
        outlettype=["signal", "signal"],
        patching_rect=[30, 60, 80, 22], text="plugin~",
    ))
    boxes.append(box(
        id="plugout", maxclass="newobj", numinlets=2, numoutlets=0,
        patching_rect=[30, 700, 80, 22], text="plugout~",
    ))
    boxes.append(newobj("sum_lr", "+~", 30, 90, numinlets=2, numoutlets=1, outlettype=["signal"], w=40))
    boxes.append(newobj("half", "*~ 0.5", 30, 116, numinlets=2, numoutlets=1, outlettype=["signal"], w=60))
    lines.append(line("plugin", 0, "sum_lr", 0))
    lines.append(line("plugin", 1, "sum_lr", 1))
    lines.append(line("sum_lr", 0, "half", 0))

    # ── in_gain [2, 5, 55, 90] ────────────────────────────────────────────────
    boxes.append(live_gain("in_gain", "Input", "In", px=2, py=5))
    lines.append(line("half", 0, "in_gain", 0))
    lines.append(line("half", 0, "in_gain", 1))

    # ── out_gain [263, 5, 55, 90] — NAM section output, before TONE/IR stages ──
    boxes.append(live_gain("out_gain", "NAM Out", "Out", px=263, py=5))

    # ── State management ──────────────────────────────────────────────────────
    boxes.append(newobj("nodestate", "node.script nam_state.js @autostart 1",
                        300, 30, numinlets=1, numoutlets=2, outlettype=["", ""], w=280))
    boxes.append(newobj("jsloader", "js nam_loader.js",
                        300, 60, numinlets=1, numoutlets=8,
                        outlettype=["", "", "", "", "", "", "", ""], w=160))
    boxes.append(newobj("pre_rehydrate", "prepend rehydrate",
                        300, 6, numinlets=1, numoutlets=1, outlettype=[""], w=160))
    lines.append(line("nodestate", 0, "pre_rehydrate", 0))
    lines.append(line("pre_rehydrate", 0, "jsloader", 0))

    boxes.append(newobj("delay_startup", "delay 1000", 480, 6,
                        numinlets=2, numoutlets=1, outlettype=["bang"], w=80))
    boxes.append(msgbox("msg_getall", "get_all", 570, 6, w=100))
    lines.append(line("thisdev", 0, "delay_startup", 0))
    lines.append(line("delay_startup", 0, "msg_getall", 0))
    lines.append(line("msg_getall", 0, "nodestate", 0))

    # 10ms: init_banks — fills bank 0 (NAM) via edit. edit fires bank_parameters_changed
    # (safe). Bank 1 (IR) is created separately at 30ms to avoid racing with this edit.
    boxes.append(newobj("delay_init_banks", "delay 10", 700, 6,
                        numinlets=2, numoutlets=1, outlettype=["bang"], w=80))
    boxes.append(msgbox("msg_init_banks", "init_banks", 800, 6, w=120))
    lines.append(line("thisdev", 0, "delay_init_banks", 0))
    lines.append(line("delay_init_banks", 0, "msg_init_banks", 0))
    lines.append(line("msg_init_banks", 0, "jsloader", 0))


    boxes.append(newobj("pre_sr_changed", "prepend sr_changed",
                        600, 6, numinlets=1, numoutlets=1, outlettype=[""], w=140))
    lines.append(line("thisdev", 1, "pre_sr_changed", 0))
    lines.append(line("pre_sr_changed", 0, "jsloader", 0))

    # ── nam~ external ─────────────────────────────────────────────────────────
    boxes.append(newobj("nam_ext", "nam~", 30, 160,
                        numinlets=1, numoutlets=4,
                        outlettype=["signal", "", "bang", "symbol"], w=60))
    lines.append(line("in_gain", 0, "nam_ext", 0))
    lines.append(line("jsloader", 4, "nam_ext", 0))  # load messages

    boxes.append(newobj("print_nam_meta", "print nam_meta", 200, 160,
                        numinlets=1, numoutlets=0, outlettype=[], w=140))
    lines.append(line("nam_ext", 1, "print_nam_meta", 0))

    # ── Status message [10, 88, 300, 18] ─────────────────────────────────────
    boxes.append(box(
        id="status_msg", maxclass="message",
        numinlets=2, numoutlets=1, outlettype=[""],
        patching_rect=[10 + _PX_OFF, 88 + _PY_OFF, 300, 18],
        presentation=1, presentation_rect=[62, 8, 196, 18],
        text="(no model loaded)", varname="status_msg",
    ))
    boxes.append(msgbox("msg_nam_loaded", "set Loaded", 30, 186, w=130))
    lines.append(line("nam_ext", 2, "msg_nam_loaded", 0))
    lines.append(line("msg_nam_loaded", 0, "status_msg", 0))
    boxes.append(newobj("pre_nam_error", "prepend set", 170, 186,
                        numinlets=1, numoutlets=1, outlettype=[""], w=100))
    lines.append(line("nam_ext", 3, "pre_nam_error", 0))
    lines.append(line("pre_nam_error", 0, "status_msg", 0))
    lines.append(line("jsloader", 6, "status_msg", 0))

    # ── Whole-device bypass ───────────────────────────────────────────────────
    boxes.append(newobj("bypass_dry_delay", "delay~ 96000 0",
                        1000, 116, numinlets=2, numoutlets=1, outlettype=["signal"], w=140))
    lines.append(line("half", 0, "bypass_dry_delay", 0))

    boxes.append(newobj("bypass_sel", "selector~ 2",
                        1000, 160, numinlets=3, numoutlets=1, outlettype=["signal"], w=100))
    lines.append(line("bypass_dry_delay", 0, "bypass_sel", 2))  # dry → inlet 2
    lines.append(line("bypass_sel", 0, "plugout", 0))
    lines.append(line("bypass_sel", 0, "plugout", 1))

    # bypass_toggle [160, 144, 58, 22] — visible button; param lives on bypass_menu
    boxes.append(display_toggle(
        "bypass_toggle", "Bypass UI", "BypUI", default=0,
        text="Bypass", texton="Bypass",
        px=160, py=144, pw=58, ph=22,
    ))
    boxes.append(live_onoff_menu(
        "bypass_menu", "Bypass", "Byp", default=0, py_patch=620))
    boxes.append(newobj("bypass_setmsg", "prepend set",
                        1180, 648, numinlets=1, numoutlets=1, outlettype=[""], w=80))
    lines.append(line("bypass_toggle", 0, "bypass_menu", 0))    # click → param
    lines.append(line("bypass_menu", 0, "bypass_setmsg", 0))    # param → mirror
    lines.append(line("bypass_setmsg", 0, "bypass_toggle", 0))  # set: no re-output
    lines.append(line("thisdev", 0, "bypass_menu", 0))          # load-time init
    # tone_expand_toggle [222, 144, 46, 22]
    boxes.append(live_text_toggle(
        "tone_expand_toggle", "Tone Section", "Tone", default=1,
        px=222, py=144, pw=46, ph=22,
        text="Tone", texton="Tone",
        enum=["collapsed", "expanded"],
    ))
    # ir_expand_toggle [272, 144, 48, 22]
    boxes.append(live_text_toggle(
        "ir_expand_toggle", "IR Section", "IR", default=1,
        px=272, py=144, pw=48, ph=22,
        text="IR", texton="IR",
        enum=["collapsed", "expanded"],
    ))

    # collapse_tp + collapse_js (non-presentation, patching view only)
    boxes.append(newobj("collapse_tp", "thispatcher",
                        1100, 6, numinlets=1, numoutlets=2,
                        outlettype=["", ""], w=80))
    boxes.append(newobj("collapse_js", "js nam_collapse.js",
                        1100, 35, numinlets=2, numoutlets=2,
                        outlettype=["", ""], w=160))
    lines.append(line("tone_expand_toggle", 0, "collapse_js", 0))
    lines.append(line("ir_expand_toggle", 0, "collapse_js", 1))
    lines.append(line("collapse_js", 0, "collapse_tp", 0))
    lines.append(line("collapse_js", 1, "thisdev", 0))

    boxes.append(newobj("bypass_plus1", "+ 1",
                        1010, 200, numinlets=2, numoutlets=1, outlettype=["int"], w=40))
    lines.append(line("bypass_menu", 0, "bypass_plus1", 0))
    lines.append(line("bypass_plus1", 0, "bypass_sel", 0))

    # ── NAM root picker ───────────────────────────────────────────────────────
    # btn_nam_root [0, 144, 100, 22]
    boxes.append(live_text_button("btn_nam_root", "Set NAM Root",
                                  "Set NAM Root", "NAMRoot",
                                  px=0, py=144, pw=100, ph=22))
    boxes.append(newobj("opendlg_nam", "opendialog folder",
                        500, 186, numinlets=1, numoutlets=1, outlettype=["symbol"], w=110))
    boxes.append(pattr_obj("pattr_nam_root", "nam_root", 500, 212))
    boxes.append(pattr_obj("pattr_nam_relpath", "nam_relpath", 500, 238))
    boxes.append(newobj("pre_nam_root", "prepend set_nam_root",
                        500, 264, numinlets=1, numoutlets=1, outlettype=[""], w=160))
    lines.append(line("btn_nam_root", 0, "opendlg_nam", 0))
    lines.append(line("opendlg_nam", 0, "pattr_nam_root", 0))
    lines.append(line("opendlg_nam", 0, "pre_nam_root", 0))
    lines.append(line("pre_nam_root", 0, "jsloader", 0))
    lines.append(line("pre_nam_root", 0, "nodestate", 0))

    # NAM trim prefix toggle [104, 148, 14, 14]
    boxes.append(live_toggle("trim_pfx_toggle_nam", "NAM Trim Prefix", "TrimNAM",
                             default=1, px=104, py=148))
    boxes.append(comment_box("lbl_trim_nam", "Trim", px=121, py=148, pw=36, ph=14, fontsize=9))
    boxes.append(newobj("pre_trim_nam", "prepend set_trim_prefix_nam",
                        500, 290, numinlets=1, numoutlets=1, outlettype=[""], w=200))
    lines.append(line("trim_pfx_toggle_nam", 0, "pre_trim_nam", 0))
    lines.append(line("pre_trim_nam", 0, "jsloader", 0))

    # ── NAM category umenu [22, 100, 276, 22] with nav buttons ───────────────
    boxes.append(box(
        id="nam_cat_menu", maxclass="umenu",
        numinlets=1, numoutlets=3, outlettype=["int", "", ""],
        patching_rect=[300, 320, 276, 22],
        presentation=1, presentation_rect=[22, 100, 276, 22],
        varname="nam_cat_menu",
    ))
    boxes.append(box(
        id="nam_model_menu", maxclass="umenu",
        numinlets=1, numoutlets=3, outlettype=["int", "", ""],
        patching_rect=[300, 346, 276, 22],
        presentation=1, presentation_rect=[22, 122, 276, 22],
        varname="nam_model_menu",
    ))
    lines.append(line("jsloader", 0, "nam_cat_menu", 0))
    lines.append(line("jsloader", 1, "nam_model_menu", 0))

    boxes.append(newobj("pre_sel_nam_cat", "prepend select_nam_category",
                        300, 372, numinlets=1, numoutlets=1, outlettype=[""], w=210))
    boxes.append(newobj("pre_sel_nam_model", "prepend select_nam_model",
                        300, 398, numinlets=1, numoutlets=1, outlettype=[""], w=200))
    lines.append(line("nam_cat_menu", 0, "pre_sel_nam_cat", 0))
    lines.append(line("pre_sel_nam_cat", 0, "jsloader", 0))
    lines.append(line("nam_model_menu", 0, "pre_sel_nam_model", 0))
    lines.append(line("pre_sel_nam_model", 0, "jsloader", 0))

    # Nav buttons for NAM
    for bid, label, longname, shortname, handler, px, py in [
        ("btn_cat_prev",   "<", "Cat Prev",   "CatPrev",  "prev_cat",   0,   100),
        ("btn_cat_next",   ">", "Cat Next",   "CatNext",  "next_cat",   298, 100),
        ("btn_model_prev", "<", "Model Prev", "ModPrev",  "prev_model", 0,   122),
        ("btn_model_next", ">", "Model Next", "ModNext",  "next_model", 298, 122),
    ]:
        boxes.append(live_nav_button(bid, label, longname, shortname, px=px, py=py))
        boxes.append(newobj(f"pre_{bid}", f"prepend {handler}",
                            500 + px, 424, numinlets=1, numoutlets=1, outlettype=[""], w=150))
        lines.append(line(bid, 0, f"pre_{bid}", 0))
        lines.append(line(f"pre_{bid}", 0, "jsloader", 0))

    # ── Push 3 shadow menus for NAM ───────────────────────────────────────────
    # Category menu: same wiring as before (receive/prepend-set for index sync).
    # Model menu (nam_model_idx): kept for test backward-compat; not in any bank.
    # Per-category menus (Model0…ModelN): JS sends to these via patcher.getnamed;
    #   live.banks swaps which one occupies bank slot 1 when the category changes.
    for bid, longname, shortname, handler, rcv_name, py_p in [
        ("nam_cat_idx", "NAM Cat", "NamCat", "select_nam_cat_by_push", "nam_numbox_set_cat", 320),
    ]:
        pre_id    = f"pre_push_{bid}"
        rcv_id    = f"rcv_set_{bid}"
        pre_set_id = f"pre_set_{bid}"
        boxes.append(live_push_menu(bid, longname, shortname, py_patch=py_p))
        boxes.append(newobj(pre_id, f"prepend {handler}",
                            940, py_p + 28, numinlets=1, numoutlets=1, outlettype=[""], w=250))
        boxes.append(newobj(rcv_id, f"receive {rcv_name}",
                            1210, py_p, numinlets=1, numoutlets=1, outlettype=[""], w=210))
        boxes.append(newobj(pre_set_id, "prepend set",
                            1210, py_p + 28, numinlets=1, numoutlets=1, outlettype=[""], w=80))
        lines.append(line(bid, 0, pre_id, 0))
        lines.append(line(pre_id, 0, "jsloader", 0))
        lines.append(line(rcv_id, 0, pre_set_id, 0))
        lines.append(line(pre_set_id, 0, bid, 0))

    # Per-category NAM model menus — one hidden live.menu per category folder.
    # JS uses patcher.getnamed("Model{i}") to set the index; no receive wiring needed.
    nam_cat_list = _PUSH_ENUMS.get("nam_cat_idx", [])
    for i, _cat in enumerate(nam_cat_list):
        mbid   = f"Model{i}"
        mpre   = f"pre_push_{mbid}"
        py_m   = 380 + i * 24
        boxes.append(live_push_menu(mbid, f"NAM Model {i}", f"Model{i}", py_patch=py_m))
        boxes.append(newobj(mpre, "prepend select_nam_model_by_push",
                            940, py_m + 24, numinlets=1, numoutlets=1, outlettype=[""], w=270))
        lines.append(line(mbid, 0, mpre, 0))
        lines.append(line(mpre, 0, "jsloader", 0))

    # Per-category IR file menus — one hidden live.menu per IR category folder.
    ir_cat_list = _PUSH_ENUMS.get("ir_cat_idx", [])
    ir_base_y = 380 + len(nam_cat_list) * 24 + 40
    for i, _cat in enumerate(ir_cat_list):
        fbid  = f"IRFile{i}"
        fpre  = f"pre_push_{fbid}"
        py_f  = ir_base_y + i * 24
        boxes.append(live_push_menu(fbid, f"IR File {i}", f"IRFile{i}", py_patch=py_f))
        boxes.append(newobj(fpre, "prepend select_ir_file_by_push",
                            940, py_f + 24, numinlets=1, numoutlets=1, outlettype=[""], w=260))
        lines.append(line(fbid, 0, fpre, 0))
        lines.append(line(fpre, 0, "jsloader", 0))

    # live.banks — JS sends new/edit messages via patcher.getnamed("live_banks")
    # to swap which per-category model/file param occupies each bank slot.
    boxes.append(newobj("live_banks", "live.banks",
                        1450, 320, numinlets=1, numoutlets=1, outlettype=[""], w=100))
    boxes.append(newobj("print_banks", "print banks",
                        1450, 346, numinlets=1, numoutlets=0, outlettype=[], w=100))
    lines.append(line("live_banks", 0, "print_banks", 0))

    # NAM live.drop [57, 0, 206, 100]
    boxes.append(box(
        id="nam_live_drop", maxclass="live.drop",
        numinlets=1, numoutlets=2, outlettype=["", ""],
        patching_rect=[57 + _PX_OFF, _PY_OFF, 206, 100],
        presentation=1, presentation_rect=[57, 0, 206, 100],
        parameter_enable=1,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": "NAM Drop",
            "parameter_shortname": "Drop",
            "parameter_type": 4,
        }},
        varname="nam_live_drop",
    ))
    boxes.append(newobj("pre_drop_nam", "prepend load_dropped_nam",
                        500, 450, numinlets=1, numoutlets=1, outlettype=[""], w=200))
    lines.append(line("nam_live_drop", 0, "pre_drop_nam", 0))
    lines.append(line("pre_drop_nam", 0, "jsloader", 0))

    # ── Amp grill fpic — after live.drop so it's behind it (earlier = frontmost)
    boxes.append(box(
        id="amp_fpic", maxclass="fpic",
        numinlets=1, numoutlets=0,
        patching_rect=[57 + _PX_OFF, _PY_OFF, 206, 100],
        presentation=1, presentation_rect=[57, 0, 206, 100],
        pic="amp_grill.png", varname="amp_fpic",
    ))

    # ── Gate (namgate_trigger~ + namgate_gain~ + gate_sel) ────────────────────
    boxes.append(newobj("ng_trigger", "namgate_trigger~",
                        130, 220, numinlets=1, numoutlets=2,
                        outlettype=["signal", "signal"], w=130))
    lines.append(line("in_gain", 0, "ng_trigger", 0))

    boxes.append(newobj("ng_gain", "namgate_gain~",
                        30, 250, numinlets=2, numoutlets=1,
                        outlettype=["signal"], w=110))
    lines.append(line("nam_ext", 0, "ng_gain", 0))
    lines.append(line("ng_trigger", 1, "ng_gain", 1))

    boxes.append(newobj("gate_sel", "selector~ 2",
                        30, 280, numinlets=3, numoutlets=1,
                        outlettype=["signal"], w=100))
    lines.append(line("nam_ext", 0, "gate_sel", 1))   # gate-OFF dry tap
    lines.append(line("ng_gain", 0, "gate_sel", 2))   # gate-ON wet

    # gate_thresh_dial [374, 92, 50, 52] — TONE section
    boxes.append(live_dial(
        "gate_thresh_dial", "Noise Gate Threshold", "Gate",
        px=374, py=92, pw=50, ph=52,
        lo=-70.0, hi=0.0, default=-70.0,
        unitstyle=4, modmode=1,
    ))
    boxes.append(newobj("pre_gate_thresh", "prepend threshold",
                        200, 280, numinlets=1, numoutlets=1, outlettype=[""], w=150))
    lines.append(line("gate_thresh_dial", 0, "pre_gate_thresh", 0))
    lines.append(line("pre_gate_thresh", 0, "ng_trigger", 0))

    # gate_on_toggle [320, 144, 160, 22] — TONE section bottom row
    boxes.append(display_toggle(
        "gate_on_toggle", "Gate On UI", "GateUI", default=0,
        text="Gate off", texton="Gate on",
        px=320, py=144, pw=160, ph=22,
    ))
    boxes.append(live_onoff_menu(
        "gate_on_menu", "Noise Gate On", "GateOn", default=0, py_patch=650))
    boxes.append(newobj("gate_on_setmsg", "prepend set",
                        1180, 678, numinlets=1, numoutlets=1, outlettype=[""], w=80))
    lines.append(line("gate_on_toggle", 0, "gate_on_menu", 0))    # click → param
    lines.append(line("gate_on_menu", 0, "gate_on_setmsg", 0))    # param → mirror
    lines.append(line("gate_on_setmsg", 0, "gate_on_toggle", 0))  # set: no re-output
    lines.append(line("thisdev", 0, "gate_on_menu", 0))           # load-time init
    boxes.append(newobj("gate_on_plus1", "+ 1",
                        30, 306, numinlets=2, numoutlets=1, outlettype=["int"], w=40))
    lines.append(line("gate_on_menu", 0, "gate_on_plus1", 0))
    lines.append(line("gate_on_plus1", 0, "gate_sel", 0))

    # ── NAM Dry/Wet blend (*~ crossfade) ─────────────────────────────────────
    # nam_blend_dial [320, 92, 50, 52] — TONE section
    boxes.append(live_dial(
        "nam_blend_dial", "NAM Dry/Wet", "NAM",
        px=320, py=92, pw=50, ph=52,
        lo=0.0, hi=100.0, default=100.0,
        unitstyle=5, modmode=0,
    ))

    # Crossfade: dial 0-100% ÷ 100 → blend (0-1).
    # Output (nam_blend_sum) = in_gain * (1-blend) + gate_sel * blend
    boxes.append(newobj("nam_blend_div", "/ 100.",
                        30, 328, numinlets=2, numoutlets=1, outlettype=["float"], w=60))
    boxes.append(newobj("nam_blend_inv", "expr 1. - $f1",
                        100, 328, numinlets=1, numoutlets=1, outlettype=["float"], w=120))
    boxes.append(newobj("nam_dry_mul", "*~",
                        30, 354, numinlets=2, numoutlets=1, outlettype=["signal"], w=40))
    boxes.append(newobj("nam_wet_mul", "*~",
                        80, 354, numinlets=2, numoutlets=1, outlettype=["signal"], w=40))
    boxes.append(newobj("nam_blend_sum", "+~",
                        50, 380, numinlets=2, numoutlets=1, outlettype=["signal"], w=40))
    lines.append(line("in_gain", 0, "nam_dry_mul", 0))           # dry signal
    lines.append(line("gate_sel", 0, "nam_wet_mul", 0))          # wet signal
    lines.append(line("nam_blend_dial", 0, "nam_blend_div", 0))  # 0-100 → /100
    lines.append(line("nam_blend_div", 0, "nam_blend_inv", 0))   # blend → 1-blend
    lines.append(line("nam_blend_div", 0, "nam_wet_mul", 1))     # blend coefficient
    lines.append(line("nam_blend_inv", 0, "nam_dry_mul", 1))     # 1-blend coefficient
    lines.append(line("nam_dry_mul", 0, "nam_blend_sum", 0))
    lines.append(line("nam_wet_mul", 0, "nam_blend_sum", 1))

    # ── EQ curve jsui [320, 0, 320, 90] — TONE section ───────────────────────
    boxes.append(box(
        id="eq_curve_jsui", maxclass="jsui",
        numinlets=1, numoutlets=1, outlettype=[""],
        patching_rect=[320 + _PX_OFF, _PY_OFF, 320, 90],
        presentation=1, presentation_rect=[320, 0, 320, 90],
        filename="eq_curve.jsui", varname="eq_curve_jsui",
    ))

    # ── Tone stack (namtone~) ─────────────────────────────────────────────────
    # out_gain sits here in the signal chain: after NAM blend, before TONE/IR
    lines.append(line("nam_blend_sum", 0, "out_gain", 0))
    lines.append(line("nam_blend_sum", 0, "out_gain", 1))

    boxes.append(newobj("tone_ext", "namtone~",
                        30, 360, numinlets=1, numoutlets=2,
                        outlettype=["signal", ""], w=80))
    lines.append(line("out_gain", 0, "tone_ext", 0))
    lines.append(line("tone_ext", 1, "eq_curve_jsui", 0))

    boxes.append(newobj("tone_sel", "selector~ 2",
                        30, 390, numinlets=3, numoutlets=1,
                        outlettype=["signal"], w=100))
    lines.append(line("out_gain", 0, "tone_sel", 1))  # tone-OFF dry tap
    lines.append(line("tone_ext", 0, "tone_sel", 2))  # tone-ON wet

    # EQ dials — TONE section
    # 6 dials × 50px + 5 × 4px gaps = 320px (section-local x: 0, 54, 108, 162, 216, 270)
    # Absolute x: 320, 374, 428, 482, 536, 590
    boxes.append(live_dial("bass_dial", "Bass", "Bass",
                           px=428, py=92, pw=50, ph=52,
                           lo=0.0, hi=10.0, default=5.0, unitstyle=1, modmode=2, steps=1001))
    boxes.append(live_dial("mid_dial", "Mid", "Mid",
                           px=482, py=92, pw=50, ph=52,
                           lo=0.0, hi=10.0, default=5.0, unitstyle=1, modmode=2, steps=1001))
    boxes.append(live_dial("treble_dial", "Treble", "Trbl",
                           px=536, py=92, pw=50, ph=52,
                           lo=0.0, hi=10.0, default=5.0, unitstyle=1, modmode=2, steps=1001))

    for dial_id, msg in [("bass_dial", "bass"), ("mid_dial", "mid"), ("treble_dial", "treble")]:
        boxes.append(newobj(f"pre_{msg}", f"prepend {msg}",
                            200 + {"bass": 0, "mid": 30, "treble": 60}[msg], 360,
                            numinlets=1, numoutlets=1, outlettype=[""], w=110))
        lines.append(line(dial_id, 0, f"pre_{msg}", 0))
        lines.append(line(f"pre_{msg}", 0, "tone_ext", 0))

    # tone_on_toggle [480, 144, 160, 22] — TONE section bottom row
    boxes.append(display_toggle(
        "tone_on_toggle", "Tone Stack On UI", "EQUI", default=1,
        text="Tone off", texton="Tone on",
        px=480, py=144, pw=160, ph=22,
    ))
    boxes.append(live_onoff_menu(
        "tone_on_menu", "Tone Stack On", "EQOn", default=1, py_patch=680))
    boxes.append(newobj("tone_on_setmsg", "prepend set",
                        1180, 708, numinlets=1, numoutlets=1, outlettype=[""], w=80))
    lines.append(line("tone_on_toggle", 0, "tone_on_menu", 0))    # click → param
    lines.append(line("tone_on_menu", 0, "tone_on_setmsg", 0))    # param → mirror
    lines.append(line("tone_on_setmsg", 0, "tone_on_toggle", 0))  # set: no re-output
    lines.append(line("thisdev", 0, "tone_on_menu", 0))           # load-time init
    boxes.append(newobj("tonestack_on_plus1", "+ 1",
                        30, 416, numinlets=2, numoutlets=1, outlettype=["int"], w=40))
    lines.append(line("tone_on_menu", 0, "tonestack_on_plus1", 0))
    lines.append(line("tonestack_on_plus1", 0, "tone_sel", 0))

    # ── IR convolution chain ──────────────────────────────────────────────────
    boxes.append(newobj("ir_buf", "buffer~ ir_buf",
                        600, 80, numinlets=2, numoutlets=2,
                        outlettype=["float", "bang"], w=120))
    lines.append(line("jsloader", 5, "ir_buf", 0))  # read <path> messages

    # irdisplay~ pipeline: ir_buf bang → process → irdisplay~ → set ir_display → waveform~
    boxes.append(newobj("ir_display_buf", "buffer~ ir_display 1",
                        600, 110, numinlets=2, numoutlets=1, outlettype=["float"], w=140))
    boxes.append(newobj("irdisplay_obj", "irdisplay~",
                        600, 140, numinlets=1, numoutlets=1, outlettype=["bang"], w=80))
    boxes.append(msgbox("msg_irdisplay_process", "process ir_display ir_buf",
                        750, 110, w=200))
    boxes.append(msgbox("msg_set_waveform_display", "set ir_display",
                        600, 170, w=140))
    lines.append(line("ir_buf", 1, "msg_irdisplay_process", 0))
    lines.append(line("msg_irdisplay_process", 0, "irdisplay_obj", 0))
    lines.append(line("irdisplay_obj", 0, "msg_set_waveform_display", 0))
    lines.append(line("msg_set_waveform_display", 0, "ir_waveform", 0))

    # irconv~ initial arm + re-arm on every read-complete
    boxes.append(newobj("lb_irconv", "loadbang",
                        760, 80, numinlets=0, numoutlets=1, outlettype=["bang"], w=70))
    boxes.append(msgbox("msg_set_ir", "set ir_buf", 760, 104, w=130))
    lines.append(line("lb_irconv", 0, "msg_set_ir", 0))
    lines.append(line("ir_buf", 1, "msg_set_ir", 0))
    lines.append(line("msg_set_ir", 0, "mconv", 0))

    boxes.append(newobj("mconv", "irconv~",
                        600, 200, numinlets=1, numoutlets=4,
                        outlettype=["signal", "", "bang", "symbol"], w=80))
    lines.append(line("tone_sel", 0, "mconv", 0))

    # IR Dry/Wet blend (*~ crossfade)
    boxes.append(live_dial(
        "ir_blend_dial", "IR Dry/Wet", "IR",
        px=590, py=92, pw=50, ph=52,
        lo=0.0, hi=100.0, default=100.0,
        unitstyle=5, modmode=0,
    ))

    boxes.append(newobj("ir_blend_dry_delay", "delay~ 96000 0",
                        820, 200, numinlets=2, numoutlets=1,
                        outlettype=["signal"], w=140))
    lines.append(line("tone_sel", 0, "ir_blend_dry_delay", 0))

    # Crossfade: dial 0-100% ÷ 100 → blend (0-1).
    # Output (ir_blend_sum) = ir_blend_dry_delay * (1-blend) + mconv * blend
    boxes.append(newobj("ir_blend_div", "/ 100.",
                        700, 238, numinlets=2, numoutlets=1, outlettype=["float"], w=60))
    boxes.append(newobj("ir_blend_inv", "expr 1. - $f1",
                        770, 238, numinlets=1, numoutlets=1, outlettype=["float"], w=120))
    boxes.append(newobj("ir_dry_mul", "*~",
                        700, 264, numinlets=2, numoutlets=1, outlettype=["signal"], w=40))
    boxes.append(newobj("ir_wet_mul", "*~",
                        750, 264, numinlets=2, numoutlets=1, outlettype=["signal"], w=40))
    boxes.append(newobj("ir_blend_sum", "+~",
                        720, 290, numinlets=2, numoutlets=1, outlettype=["signal"], w=40))
    lines.append(line("ir_blend_dry_delay", 0, "ir_dry_mul", 0))  # dry signal
    # -18 dB normalization: NAM plugin bakes pow(10,-18*0.05)*48000/sr into IR weights;
    # irconv~ uses raw buffer values. jsloader outlet 7 sends 0.12589 when IR is loaded,
    # 0.0 when not — so normalization only applies when a file is actually loaded.
    boxes.append(newobj("ir_norm", "*~",
                        700, 270, numinlets=2, numoutlets=1, outlettype=["signal"], w=40))
    lines.append(line("mconv", 0, "ir_norm", 0))
    lines.append(line("jsloader", 7, "ir_norm", 1))               # norm factor: 0.12589 or 0.0
    lines.append(line("ir_norm", 0, "ir_wet_mul", 0))             # wet signal (normalized)
    lines.append(line("ir_blend_dial", 0, "ir_blend_div", 0))     # 0-100 → /100
    lines.append(line("ir_blend_div", 0, "ir_blend_inv", 0))      # blend → 1-blend
    lines.append(line("ir_blend_div", 0, "ir_wet_mul", 1))        # blend coefficient
    lines.append(line("ir_blend_inv", 0, "ir_dry_mul", 1))        # 1-blend coefficient
    lines.append(line("ir_dry_mul", 0, "ir_blend_sum", 0))
    lines.append(line("ir_wet_mul", 0, "ir_blend_sum", 1))

    # ir_sel — hard IR bypass (selector~ 2)
    boxes.append(newobj("ir_sel", "selector~ 2",
                        600, 270, numinlets=3, numoutlets=1,
                        outlettype=["signal"], w=100))
    lines.append(line("ir_blend_dry_delay", 0, "ir_sel", 1))  # IR-off dry tap
    lines.append(line("ir_blend_sum", 0, "ir_sel", 2))      # IR-on blended

    # ir_on_toggle [794, 144, 168, 22] — IR section bottom row
    boxes.append(display_toggle(
        "ir_on_toggle", "IR On UI", "IRUI", default=1,
        text="IR off", texton="IR on",
        px=794, py=144, pw=168, ph=22,
    ))
    boxes.append(live_onoff_menu(
        "ir_on_menu", "IR On", "IROn", default=1, py_patch=710))
    boxes.append(newobj("ir_on_setmsg", "prepend set",
                        1180, 738, numinlets=1, numoutlets=1, outlettype=[""], w=80))
    lines.append(line("ir_on_toggle", 0, "ir_on_menu", 0))    # click → param
    lines.append(line("ir_on_menu", 0, "ir_on_setmsg", 0))    # param → mirror
    lines.append(line("ir_on_setmsg", 0, "ir_on_toggle", 0))  # set: no re-output
    lines.append(line("thisdev", 0, "ir_on_menu", 0))         # load-time init
    boxes.append(newobj("ir_on_plus1", "+ 1",
                        510, 250, numinlets=2, numoutlets=1, outlettype=["int"], w=40))
    lines.append(line("ir_on_menu", 0, "ir_on_plus1", 0))
    lines.append(line("ir_on_plus1", 0, "ir_sel", 0))

    # ir_sel → bypass_sel (out_gain is now in the NAM section, not at chain end)
    lines.append(line("ir_sel", 0, "bypass_sel", 1))

    # ── PDC (latency reporting) ───────────────────────────────────────────────
    boxes.append(newobj("route_latency", "route latency",
                        900, 200, numinlets=1, numoutlets=2, outlettype=["", ""], w=100))
    boxes.append(newobj("unpack_lat", "unpack i",
                        900, 226, numinlets=1, numoutlets=1, outlettype=["int"], w=70))
    boxes.append(newobj("lat_trig", "t i i i",
                        600, 300, numinlets=1, numoutlets=3, outlettype=["int", "int", "int"], w=70))
    boxes.append(msgbox("msg_latency", "latency $1", 700, 300, w=140))
    boxes.append(newobj("lat_defer", "defer",
                        700, 326, numinlets=1, numoutlets=1, outlettype=[""], w=60))

    lines.append(line("mconv", 1, "route_latency", 0))
    lines.append(line("route_latency", 0, "unpack_lat", 0))
    lines.append(line("unpack_lat", 0, "lat_trig", 0))
    lines.append(line("lat_trig", 0, "ir_blend_dry_delay", 1))  # set dry tap delay
    lines.append(line("lat_trig", 1, "msg_latency", 0))
    lines.append(line("msg_latency", 0, "lat_defer", 0))
    lines.append(line("lat_defer", 0, "thisdev", 0))
    lines.append(line("lat_trig", 2, "bypass_dry_delay", 1))    # set bypass delay

    # ── IR duration display ───────────────────────────────────────────────────
    # jsloader outlet 5 sends "read <path>" → strip "read" → "open <path>" → sfinfo~
    boxes.append(newobj("route_read_sfinfo", "route read",
                        960, 80, numinlets=1, numoutlets=2, outlettype=["", ""], w=80))
    boxes.append(newobj("pre_open_sfinfo", "prepend open",
                        960, 110, numinlets=1, numoutlets=1, outlettype=[""], w=100))
    boxes.append(newobj("sfinfo_dur", "sfinfo~",
                        960, 140, numinlets=1, numoutlets=6,
                        outlettype=["int", "int", "int", "float", "", "symbol"], w=60))
    boxes.append(newobj("div_ms", "/ 1000.",
                        960, 170, numinlets=2, numoutlets=1, outlettype=["float"], w=60))
    boxes.append(newobj("sprintf_dur", "sprintf %.2f sec",
                        960, 200, numinlets=1, numoutlets=1, outlettype=["symbol"], w=140))
    boxes.append(newobj("pre_set_dur", "prepend set",
                        960, 226, numinlets=1, numoutlets=1, outlettype=[""], w=100))
    boxes.append(box(
        id="dur_display", maxclass="message",
        numinlets=2, numoutlets=1, outlettype=[""],
        patching_rect=[644 + _PX_OFF, 2 + _PY_OFF, 62, 14],
        presentation=1, presentation_rect=[644, 2, 62, 14],
        text="", fontsize=9, varname="dur_display",
    ))
    lines.append(line("jsloader", 5, "route_read_sfinfo", 0))
    lines.append(line("route_read_sfinfo", 0, "pre_open_sfinfo", 0))
    lines.append(line("pre_open_sfinfo", 0, "sfinfo_dur", 0))
    lines.append(line("sfinfo_dur", 3, "div_ms", 0))
    lines.append(line("div_ms", 0, "sprintf_dur", 0))
    lines.append(line("sprintf_dur", 0, "pre_set_dur", 0))
    lines.append(line("pre_set_dur", 0, "dur_display", 0))

    # ── IR root picker ────────────────────────────────────────────────────────
    # btn_ir_root [642, 144, 100, 22]
    boxes.append(live_text_button("btn_ir_root", "Set IR Root",
                                  "Set IR Root", "IRRoot",
                                  px=642, py=144, pw=100, ph=22))
    boxes.append(newobj("opendlg_ir", "opendialog folder",
                        175, 506, numinlets=1, numoutlets=1, outlettype=["symbol"], w=110))
    boxes.append(pattr_obj("pattr_ir_root", "ir_root", 175, 532))
    boxes.append(pattr_obj("pattr_ir_relpath", "ir_relpath", 175, 558))
    boxes.append(newobj("pre_ir_root", "prepend set_ir_root",
                        420, 532, numinlets=1, numoutlets=1, outlettype=[""], w=160))
    lines.append(line("btn_ir_root", 0, "opendlg_ir", 0))
    lines.append(line("opendlg_ir", 0, "pattr_ir_root", 0))
    lines.append(line("opendlg_ir", 0, "pre_ir_root", 0))
    lines.append(line("pre_ir_root", 0, "jsloader", 0))
    lines.append(line("pre_ir_root", 0, "nodestate", 0))

    # IR trim prefix toggle [746, 148, 14, 14]
    boxes.append(live_toggle("trim_pfx_toggle_ir", "IR Trim Prefix", "TrimIR",
                             default=1, px=746, py=148))
    boxes.append(comment_box("lbl_trim_ir", "Trim", px=763, py=148, pw=28, ph=14, fontsize=9))
    boxes.append(newobj("pre_trim_ir", "prepend set_trim_prefix_ir",
                        175, 584, numinlets=1, numoutlets=1, outlettype=[""], w=200))
    lines.append(line("trim_pfx_toggle_ir", 0, "pre_trim_ir", 0))
    lines.append(line("pre_trim_ir", 0, "jsloader", 0))

    # ── IR category and file umenus with nav buttons ──────────────────────────
    boxes.append(box(
        id="ir_cat_menu", maxclass="umenu",
        numinlets=1, numoutlets=3, outlettype=["int", "", ""],
        patching_rect=[662, 500, 276, 22],
        presentation=1, presentation_rect=[664, 100, 276, 22],
        varname="ir_cat_menu",
    ))
    boxes.append(box(
        id="ir_file_menu", maxclass="umenu",
        numinlets=1, numoutlets=3, outlettype=["int", "", ""],
        patching_rect=[662, 526, 276, 22],
        presentation=1, presentation_rect=[664, 122, 276, 22],
        varname="ir_file_menu",
    ))
    lines.append(line("jsloader", 2, "ir_cat_menu", 0))
    lines.append(line("jsloader", 3, "ir_file_menu", 0))

    boxes.append(newobj("pre_sel_ir_cat", "prepend select_ir_category",
                        600, 552, numinlets=1, numoutlets=1, outlettype=[""], w=200))
    boxes.append(newobj("pre_sel_ir", "prepend select_ir",
                        600, 578, numinlets=1, numoutlets=1, outlettype=[""], w=150))
    lines.append(line("ir_cat_menu", 0, "pre_sel_ir_cat", 0))
    lines.append(line("pre_sel_ir_cat", 0, "jsloader", 0))
    lines.append(line("ir_file_menu", 0, "pre_sel_ir", 0))
    lines.append(line("pre_sel_ir", 0, "jsloader", 0))

    # IR nav buttons (22×22, section-local x: 0, 318; absolute: 642, 940)
    for bid, label, longname, shortname, handler, px, py in [
        ("btn_ir_cat_prev", "<", "IR Cat Prev", "IRCatPrv", "prev_ir_cat", 642, 100),
        ("btn_ir_cat_next", ">", "IR Cat Next", "IRCatNxt", "next_ir_cat", 940, 100),
        ("btn_ir_prev",     "<", "IR Prev",     "IRPrev",   "prev_ir",     642, 122),
        ("btn_ir_next",     ">", "IR Next",     "IRNext",   "next_ir",     940, 122),
    ]:
        boxes.append(live_nav_button(bid, label, longname, shortname, px=px, py=py))
        boxes.append(newobj(f"pre_{bid}", f"prepend {handler}",
                            600, 604 + ["btn_ir_cat_prev","btn_ir_cat_next","btn_ir_prev","btn_ir_next"].index(bid) * 26,
                            numinlets=1, numoutlets=1, outlettype=[""], w=160))
        lines.append(line(bid, 0, f"pre_{bid}", 0))
        lines.append(line(f"pre_{bid}", 0, "jsloader", 0))

    # ── Push 3 shadow menus for IR category and file ─────────────────────────────
    # ir_cat_idx: same wiring as before (receive/prepend-set for index sync).
    # ir_file_idx: kept for test backward-compat; not assigned to any bank.
    # Per-category IRFile menus are added in the NAM section above.
    for bid, longname, shortname, handler, rcv_name, py_p in [
        ("ir_cat_idx", "IR Cat", "IRCat", "select_ir_cat_by_push", "ir_numbox_set_cat", 552),
    ]:
        pre_id     = f"pre_push_{bid}"
        rcv_id     = f"rcv_set_{bid}"
        pre_set_id = f"pre_set_{bid}"
        boxes.append(live_push_menu(bid, longname, shortname, py_patch=py_p))
        boxes.append(newobj(pre_id, f"prepend {handler}",
                            940, py_p + 28, numinlets=1, numoutlets=1, outlettype=[""], w=240))
        boxes.append(newobj(rcv_id, f"receive {rcv_name}",
                            1210, py_p, numinlets=1, numoutlets=1, outlettype=[""], w=210))
        boxes.append(newobj(pre_set_id, "prepend set",
                            1210, py_p + 28, numinlets=1, numoutlets=1, outlettype=[""], w=80))
        lines.append(line(bid, 0, pre_id, 0))
        lines.append(line(pre_id, 0, "jsloader", 0))
        lines.append(line(rcv_id, 0, pre_set_id, 0))
        lines.append(line(pre_set_id, 0, bid, 0))

    # IR live.drop [642, 0, 320, 100]
    boxes.append(box(
        id="ir_live_drop", maxclass="live.drop",
        numinlets=1, numoutlets=2, outlettype=["", ""],
        patching_rect=[640 + _PX_OFF, _PY_OFF, 320, 100],
        presentation=1, presentation_rect=[642, 0, 320, 100],
        parameter_enable=1,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": "IR File Drop",
            "parameter_shortname": "IRDrop",
            "parameter_type": 4,
            "parameter_initial_enable": 1,
            "parameter_initial": [""],
        }},
        varname="ir_live_drop",
    ))
    boxes.append(newobj("pre_drop_ir", "prepend load_dropped_ir",
                        620, 710, numinlets=1, numoutlets=1, outlettype=[""], w=200))
    lines.append(line("ir_live_drop", 0, "pre_drop_ir", 0))
    lines.append(line("pre_drop_ir", 0, "jsloader", 0))

    # ── IR waveform — after ir_live_drop so it's behind it (earlier = frontmost)
    boxes.append(box(
        id="ir_waveform", maxclass="waveform~",
        numinlets=5, numoutlets=6,
        outlettype=["float", "float", "float", "float", "float", "list"],
        patching_rect=[640 + _PX_OFF, _PY_OFF, 320, 100],
        presentation=1, presentation_rect=[642, 0, 320, 100],
        buffername="ir_display",
        allowdrag=0, ignoreclick=1, labels=0, ruler=0, vticks=0,
        varname="ir_waveform",
    ))

    # ── Patcher shell ─────────────────────────────────────────────────────────
    patcher = {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 0, "revision": 10,
                       "architecture": "x64", "modernui": 1},
        "classnamespace": "box",
        "rect": [100.0, 100.0, 1400.0, 800.0],
        "openinpresentation": 1,
        "default_fontsize": 12.0,
        "default_fontname": "Ableton Sans Medium",
        "gridsize": [8.0, 8.0],
        "boxes": boxes,
        "lines": lines,
        "parameters": _build_parameters_block(boxes),
        "dependency_cache": [],
        "autosave": 0,
    }
    return {"patcher": patcher}


if __name__ == "__main__":
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "m4l", "NAM.maxpat")
    doc = build()
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        json.dump(doc, f, indent="\t")
    print(f"Wrote {out}")
