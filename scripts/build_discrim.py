#!/usr/bin/env python3
"""build_discrim.py — throwaway Push 3 discriminator device.

Builds m4l/NAMDiscrim.maxpat: three VISIBLE parameters on one baked Push bank, to
answer empirically how Push 3 derives an enum parameter's displayed value name:

  slot 0  Disc Text  — live.text  @parameter_type 2 @parameter_enum ["Off","On"]
  slot 1  Disc Menu  — live.menu  items ["Off","On"]   (control: known to surface)
  slot 2  Disc Bool  — live.toggle (boolean @parameter_type 1)

Drag the device onto a track, look at the Push device page, read the VALUE under
each of the three encoders:
  - Menu shows Off/On, Text shows val1/val2  -> live.text never surfaces its enum
  - both Text and Menu show val1/val2         -> file/load problem, not parameters
  - both show Off/On                          -> live.text does surface its enum

Audio passes through (plugin~ -> plugout~) so the track isn't silenced.

Build:  python3 scripts/build_discrim.py && \
        python3 scripts/build_amxd.py m4l/NAMDiscrim.maxpat m4l/NAMDiscrim.amxd
"""
import json
import os


def box(**kw):
    return {"box": kw}


def line(src, so, dst, di=0):
    return {"patchline": {"source": [src, so], "destination": [dst, di]}}


def live_text_toggle(bid, longname, shortname, px, py):
    return box(
        id=bid, maxclass="live.text",
        numinlets=1, numoutlets=2, outlettype=["int", "int"],
        patching_rect=[px, py + 200, 80, 22],
        presentation=1, presentation_rect=[px, py, 80, 22],
        parameter_enable=1, mode=1, text="Off", texton="On",
        saved_attribute_attributes={"valueof": {
            "parameter_longname": longname,
            "parameter_shortname": shortname,
            "parameter_type": 2,
            "parameter_enum": ["Off", "On"],
            "parameter_initial_enable": 1,
            "parameter_initial": [0],
        }},
        varname=bid,
    )


def live_menu(bid, longname, shortname, px, py):
    return box(
        id=bid, maxclass="live.menu",
        numinlets=1, numoutlets=2, outlettype=["int", "bang"],
        patching_rect=[px, py + 200, 80, 22],
        presentation=1, presentation_rect=[px, py, 80, 22],
        parameter_enable=1,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": longname,
            "parameter_shortname": shortname,
            "parameter_type": 2,
            "parameter_enum": ["Off", "On"],
            "parameter_initial_enable": 1,
            "parameter_initial": [0],
        }},
        varname=bid,
    )


def live_toggle(bid, longname, shortname, px, py):
    return box(
        id=bid, maxclass="live.toggle",
        numinlets=1, numoutlets=1, outlettype=["int"],
        patching_rect=[px, py + 200, 24, 24],
        presentation=1, presentation_rect=[px, py, 24, 24],
        parameter_enable=1,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": longname,
            "parameter_shortname": shortname,
            "parameter_type": 1,
            "parameter_initial_enable": 1,
            "parameter_initial": [0],
        }},
        varname=bid,
    )


def comment(bid, text, px, py, pw=80):
    return box(
        id=bid, maxclass="comment", numinlets=1, numoutlets=0,
        patching_rect=[px, py + 200, pw, 18],
        presentation=1, presentation_rect=[px, py, pw, 18],
        text=text, fontsize=9, varname=bid,
    )


PARAMS = [
    ("disc_text", "Disc Text", "Text"),
    ("disc_menu", "Disc Menu", "Menu"),
    ("disc_bool", "Disc Bool", "Bool"),
]


def build():
    boxes = []
    lines = []

    # Audio passthrough so the host track isn't silenced.
    boxes.append(box(id="plugin", maxclass="newobj", numinlets=2, numoutlets=2,
                     outlettype=["signal", "signal"], patching_rect=[20, 320, 60, 22],
                     text="plugin~", varname="plugin"))
    boxes.append(box(id="plugout", maxclass="newobj", numinlets=2, numoutlets=0,
                     outlettype=[], patching_rect=[20, 380, 60, 22],
                     text="plugout~", varname="plugout"))
    lines.append(line("plugin", 0, "plugout", 0))
    lines.append(line("plugin", 1, "plugout", 1))

    boxes.append(box(id="thisdev", maxclass="newobj", numinlets=1, numoutlets=4,
                     outlettype=["", "", "", ""], patching_rect=[120, 320, 110, 22],
                     text="live.thisdevice", varname="thisdev"))

    # Three visible controls + labels.
    boxes.append(comment("lbl_text", "live.text enum", 20, 20))
    boxes.append(live_text_toggle("disc_text", "Disc Text", "Text", 20, 40))
    boxes.append(comment("lbl_menu", "live.menu enum", 120, 20))
    boxes.append(live_menu("disc_menu", "Disc Menu", "Menu", 120, 40))
    boxes.append(comment("lbl_bool", "live.toggle bool", 220, 20))
    boxes.append(live_toggle("disc_bool", "Disc Bool", "Bool", 220, 40))

    # Baked Push bank (bank_count=1 the instant Live loads it).
    registry = {vn: [ln, sn, 0] for vn, ln, sn in PARAMS}
    registry["parameterbanks"] = {
        "0": {
            "index": 0,
            "name": "Discrim",
            "parameters": ["Disc Text", "Disc Menu", "Disc Bool",
                           "-", "-", "-", "-", "-"],
            "buttons": ["-"] * 8,
        }
    }
    registry["inherited_shortname"] = 1

    patcher = {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 0, "revision": 10,
                       "architecture": "x64", "modernui": 1},
        "classnamespace": "box",
        "rect": [100, 100, 360, 240],
        "openinpresentation": 1,
        "default_fontsize": 12.0,
        "default_fontname": "Ableton Sans Medium",
        "gridsize": [8.0, 8.0],
        "boxes": boxes,
        "lines": lines,
        "parameters": registry,
    }
    return {"patcher": patcher}


if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "..", "m4l", "NAMDiscrim.maxpat")
    out = os.path.abspath(out)
    with open(out, "w") as f:
        json.dump(build(), f, indent=1)
    print("Wrote", out)
