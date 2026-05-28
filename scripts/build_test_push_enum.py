#!/usr/bin/env python3
"""Build test_push_enum.amxd — Push 3 enum display test (parameter_visibility theories).

Tests whether Live 12.4 parameter_visibility modes allow runtime enum updates on Push 3:
  F. parameter_enable=1, parameter_visibility="Visible"
  G. parameter_enable=1, parameter_visibility="Visible (Not Stored)"
  H. parameter_enable=0, parameter_visibility="Visible"  (Push-only, no automation)

Each live.menu starts with ["Pre-0".."Pre-4"].
Click F/G/H to send _parameter_range -> ["Alpha".."Epsilon"].
Check if Push 3 shows the new names.
"""
import json, os, struct

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR    = os.path.join(SCRIPT_DIR, "..", "test_devices")

INITIAL = ["Pre-0", "Pre-1", "Pre-2", "Pre-3", "Pre-4"]


def _b(id, cls, x, y, w, h, nin=1, nout=0, ot=None, **kw):
    return {"box": {
        "id": id, "maxclass": cls,
        "numinlets": nin, "numoutlets": nout,
        "outlettype": ot or [],
        "patching_rect": [x, y, w, h],
        **kw,
    }}


def comment(id, text, x, y, w=580):
    return _b(id, "comment", x, y, w, 20, nin=1, text=text)


def button(id, x, y):
    return _b(id, "button", x, y, 30, 30, nin=1, nout=1, ot=["bang"])


def msgbox(id, text, x, y, w=160):
    return _b(id, "message", x, y, w, 22, nin=2, nout=1, ot=[""], text=text)


def newobj(id, text, x, y, w=200):
    return _b(id, "newobj", x, y, w, 22, nin=1, nout=1, ot=[""], text=text)


def live_menu(id, longname, shortname, visibility, parameter_enable, x, y):
    vo = {
        "parameter_longname": longname,
        "parameter_shortname": shortname,
        "parameter_type": 2,
        "parameter_enum": INITIAL,
        "parameter_initial_enable": 1,
        "parameter_initial": [0],
        "parameter_visibility": visibility,
    }
    return {"box": {
        "id": id, "maxclass": "live.menu", "varname": id,
        "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "bang"],
        "patching_rect": [x, y, 90, 22],
        "parameter_enable": parameter_enable,
        "hidden": 0,
        "saved_attribute_attributes": {"valueof": vo},
    }}


def line(s, so, d, di):
    return {"patchline": {"source": [s, so], "destination": [d, di]}}


boxes = [
    comment("hdr", "Push 3 parameter_visibility test (Live 12.4). Check Max console.", 5, 3),
    comment("hdr2", "Push should show F_Vis / G_VNS / H_PE0. Click buttons to update Pre->Alpha.", 5, 22),

    # Three live.menus — one per theory
    live_menu("testmenu_f", "F_Vis",  "F_Vis",  "Visible",            1, 5,   45),
    live_menu("testmenu_g", "G_VNS",  "G_VNS",  "Visible (Not Stored)", 1, 105, 45),
    live_menu("testmenu_h", "H_PE0",  "H_PE0",  "Visible",            0, 205, 45),

    # Buttons in a row
    button("btn_f",   5,   75),
    button("btn_g",   60,  75),
    button("btn_h",   115, 75),
    button("btn_all", 185, 75),
    comment("lbl_f",   "F",   15,  82, 20),
    comment("lbl_g",   "G",   70,  82, 20),
    comment("lbl_h",   "H",   125, 82, 20),
    comment("lbl_all", "All", 195, 82, 28),

    # Message boxes (below visible area — still wired)
    msgbox("msg_f",   "test_f",   5,   120),
    msgbox("msg_g",   "test_g",   5,   145),
    msgbox("msg_h",   "test_h",   5,   170),
    msgbox("msg_all", "test_all", 5,   195),

    # JS
    newobj("js1", "js testpushenum.js", 5, 225, 180),
]

lines = [
    line("btn_f",   0, "msg_f",   0), line("msg_f",   0, "js1", 0),
    line("btn_g",   0, "msg_g",   0), line("msg_g",   0, "js1", 0),
    line("btn_h",   0, "msg_h",   0), line("msg_h",   0, "js1", 0),
    line("btn_all", 0, "msg_all", 0), line("msg_all", 0, "js1", 0),
]

patcher = {
    "patcher": {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 0, "revision": 10, "architecture": "x64", "modernui": 1},
        "classnamespace": "box",
        "rect": [100.0, 100.0, 620.0, 260.0],
        "bglocked": 0,
        "openinpresentation": 0,
        "boxes": boxes,
        "lines": lines,
    }
}

os.makedirs(OUT_DIR, exist_ok=True)
maxpat_path = os.path.join(OUT_DIR, "test_push_enum.maxpat")
amxd_path   = os.path.join(OUT_DIR, "test_push_enum.amxd")

with open(maxpat_path, "w") as f:
    json.dump(patcher, f, indent=2)

json_bytes = open(maxpat_path, "rb").read()
header = (
    b"ampf" + struct.pack("<I", 4) +
    b"aaaameta" + struct.pack("<I", 4) +
    struct.pack("<I", 1) +
    b"ptch" + struct.pack("<I", len(json_bytes))
)
with open(amxd_path, "wb") as f:
    f.write(header + json_bytes)

print(f"Wrote {maxpat_path}")
print(f"Built {amxd_path}")
