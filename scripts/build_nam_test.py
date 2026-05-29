#!/usr/bin/env python3
"""build_nam_test.py — Minimal NAM test device: category + model picker, no audio.

Tests whether live.banks per-category swapping updates Push 3 mid-session.
Root is hardcoded to ~/Documents/NAM/Models.

Usage:
  python3 scripts/build_nam_test.py          # writes m4l/NAMTest.maxpat
  python3 scripts/build_amxd.py m4l/NAMTest.maxpat m4l/NAMTest.amxd
"""
import json
import os
import re
import sys

NAM_ROOT = os.path.expanduser("~/Documents/NAM/Models")


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


def _build_enums():
    cats = _scan_subdirs(NAM_ROOT) or ["(no categories)"]
    result = {"nam_cat_idx": cats}
    for i, cat in enumerate(cats):
        files = _scan_files(os.path.join(NAM_ROOT, cat), [".nam"]) if cat else []
        result[f"Model{i}"] = _make_display_names(files, r"\.nam$") if files else ["(empty)"]
    return result


_ENUMS = _build_enums()


# ── Patch helpers ─────────────────────────────────────────────────────────────

def bx(**kw):
    return {"box": kw}


def line(src, src_out, dst, dst_in=0):
    return {"patchline": {"source": [src, src_out], "destination": [dst, dst_in]}}


def obj(bid, text, x, y, ni=1, no=1, ot=None, w=200):
    return bx(id=bid, maxclass="newobj", numinlets=ni, numoutlets=no,
              outlettype=ot or [""], patching_rect=[x, y, w, 22],
              text=text, varname=bid)


def push_menu(bid, longname, shortname, py_patch, enabled=True):
    enum = _ENUMS.get(bid) or ["(empty)"]
    return bx(
        id=bid, maxclass="live.menu",
        numinlets=1, numoutlets=2, outlettype=["int", "bang"],
        patching_rect=[800, py_patch, 60, 22],
        parameter_enable=1 if enabled else 0, hidden=1,
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


# Presentation-layer objects sit at (px+600, py+300) in patching view.
_PX = 600
_PY = 300


def pres_umenu(bid, px, py, pw, ph):
    return bx(
        id=bid, maxclass="umenu",
        numinlets=1, numoutlets=3, outlettype=["int", "", ""],
        patching_rect=[px + _PX, py + _PY, pw, ph],
        presentation=1, presentation_rect=[px, py, pw, ph],
        varname=bid,
    )


def pres_msg(bid, text, px, py, pw, ph, fontsize=10):
    return bx(
        id=bid, maxclass="message",
        numinlets=2, numoutlets=1, outlettype=[""],
        patching_rect=[px + _PX, py + _PY, pw, ph],
        presentation=1, presentation_rect=[px, py, pw, ph],
        text=text, fontsize=fontsize, varname=bid,
    )


def build():
    boxes = []
    lines = []

    # ── Startup sequence ─────────────────────────────────────────────────────
    # live.thisdevice bang → delay 10ms → "init" → jsloader
    # loadbang creates empty bank structure (bank_count > 0 → Push picks
    # MaxDeviceParameterBank). After 10ms params are registered; init() uses
    # edit to fill real params (fires bank_parameters_changed → Push updates).
    boxes.append(bx(
        id="thisdev", maxclass="newobj", numinlets=1, numoutlets=3,
        outlettype=["bang", "int", "int"],
        patching_rect=[10, 10, 110, 22], text="live.thisdevice", varname="thisdev",
    ))
    boxes.append(obj("delay_init", "delay 10", 10, 36, ni=2, no=1, ot=[""], w=80))
    boxes.append(bx(id="msg_init", maxclass="message", numinlets=2, numoutlets=1,
                    outlettype=[""], patching_rect=[10, 62, 60, 22], text="init",
                    varname="msg_init"))
    lines.append(line("thisdev", 0, "delay_init", 0))
    lines.append(line("delay_init", 0, "msg_init", 0))

    # ── JS loader ────────────────────────────────────────────────────────────
    boxes.append(obj("jsloader", "js nam_test_loader.js", 100, 10,
                     ni=1, no=3, ot=["", "", ""], w=190))
    lines.append(line("msg_init", 0, "jsloader", 0))

    # ── Category umenu [0, 0, 320, 22] ───────────────────────────────────────
    boxes.append(pres_umenu("cat_menu", px=0, py=0, pw=320, ph=22))
    boxes.append(obj("pre_sel_cat", "prepend select_category",
                     10, 88, ni=1, no=1, ot=[""], w=200))
    lines.append(line("jsloader", 0, "cat_menu", 0))
    lines.append(line("cat_menu", 0, "pre_sel_cat", 0))
    lines.append(line("pre_sel_cat", 0, "jsloader", 0))

    # ── Model umenu [0, 24, 320, 22] ─────────────────────────────────────────
    boxes.append(pres_umenu("model_menu", px=0, py=24, pw=320, ph=22))
    boxes.append(obj("pre_sel_model", "prepend select_model",
                     10, 114, ni=1, no=1, ot=[""], w=200))
    lines.append(line("jsloader", 1, "model_menu", 0))
    lines.append(line("model_menu", 0, "pre_sel_model", 0))
    lines.append(line("pre_sel_model", 0, "jsloader", 0))

    # ── Status message [0, 48, 320, 14] ──────────────────────────────────────
    boxes.append(pres_msg("status_msg", "(loading...)",
                          px=0, py=48, pw=320, ph=14, fontsize=9))
    lines.append(line("jsloader", 2, "status_msg", 0))

    # ── live.banks ───────────────────────────────────────────────────────────
    # JS calls patcher.getnamed("live_banks") to send new/edit messages.
    boxes.append(obj("live_banks", "live.banks",
                     800, 10, ni=1, no=1, ot=[""], w=100))

    # ── Push 3: category shadow menu ─────────────────────────────────────────
    boxes.append(push_menu("nam_cat_idx", "NAM Cat", "NamCat", py_patch=60))
    boxes.append(obj("pre_push_cat", "prepend select_cat_by_push",
                     800, 86, ni=1, no=1, ot=[""], w=230))
    lines.append(line("nam_cat_idx", 0, "pre_push_cat", 0))
    lines.append(line("pre_push_cat", 0, "jsloader", 0))

    # ── Push 3: per-category model shadow menus ───────────────────────────────
    # Only Model0 starts parameter_enable=1. When the category changes, the JS
    # enables the new category's menu, edits the bank slot, then disables the old
    # one. This prevents orphaned parameter_enable=1 menus from creating a main bank.
    cat_list = _ENUMS.get("nam_cat_idx", [])
    for i, _cat in enumerate(cat_list):
        mbid = f"Model{i}"
        mpre = f"pre_push_{mbid}"
        py_m = 110 + i * 26
        boxes.append(push_menu(mbid, f"NAM Model {i}", f"Model{i}", py_patch=py_m))
        boxes.append(obj(mpre, "prepend select_model_by_push",
                         800, py_m + 26, ni=1, no=1, ot=[""], w=250))
        lines.append(line(mbid, 0, mpre, 0))
        lines.append(line(mpre, 0, "jsloader", 0))

    # ── Diag button: prints current Live parameter count to Max console ──────
    boxes.append(bx(
        id="btn_diag", maxclass="message",
        numinlets=2, numoutlets=1, outlettype=[""],
        patching_rect=[0 + _PX, 72 + _PY, 200, 22],
        presentation=1, presentation_rect=[0, 72, 200, 22],
        text="diag_params", varname="btn_diag",
    ))
    lines.append(line("btn_diag", 0, "jsloader", 0))

    patcher = {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 0, "revision": 10,
                       "architecture": "x64", "modernui": 1},
        "classnamespace": "box",
        "rect": [100.0, 100.0, 1000.0, 800.0],
        "openinpresentation": 1,
        "default_fontsize": 12.0,
        "default_fontname": "Ableton Sans Medium",
        "gridsize": [8.0, 8.0],
        "boxes": boxes,
        "lines": lines,
        "dependency_cache": [],
        "autosave": 0,
    }
    return {"patcher": patcher}


if __name__ == "__main__":
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "m4l", "NAMTest.maxpat")
    doc = build()
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        json.dump(doc, f, indent="\t")
    print(f"Wrote {out}")
    # Print enum summary
    cats = _ENUMS.get("nam_cat_idx", [])
    print(f"  {len(cats)} categories, Model0..Model{len(cats)-1} baked")
    for i, c in enumerate(cats):
        print(f"  Model{i} ({c}): {len(_ENUMS.get(f'Model{i}', []))} files")
