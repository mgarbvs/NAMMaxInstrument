#!/usr/bin/env python3
"""validate_maxpat.py — preflight checks against a .maxpat before .amxd build.

Each check maps to a documented trap in KNOWLEDGE_BASE_MAX_INSTRUMENTS.md.
Exit 0 if clean, 1 if any violation. One error line per violation.
"""

import json
import os
import sys

# Import overlap detector from render_presentation (same scripts/ directory).
# Added in the M7 fix pass.  When validate_maxpat.py is called directly via
# "python3 scripts/validate_maxpat.py ..." sys.path may not include scripts/,
# so we insert it explicitly.
_SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, _SCRIPTS_DIR)

from render_presentation import find_presentation_overlaps  # noqa: E402

PRESENTATION_Y_LIMIT = 166


def walk_boxes(patcher):
    for b in patcher.get("boxes", []):
        inner = b.get("box", {})
        yield inner
        sub = inner.get("patcher")
        if isinstance(sub, dict):
            yield from walk_boxes(sub)


def param_attrs(inner):
    saa = inner.get("saved_attribute_attributes") or {}
    return saa.get("valueof") or {}


def validate(maxpat_path):
    with open(maxpat_path, "rb") as f:
        doc = json.loads(f.read())

    errors = []
    patcher = doc.get("patcher") or {}

    if "parameters" in patcher:
        banks = (patcher["parameters"] or {}).get("parameterbanks", {})
        if not banks:
            errors.append(
                "parameterbanks missing or empty (Live/Max param_banks crash trap)"
            )
        else:
            all_dash = all(
                all(slot == "-" for slot in bank.get("parameters", []))
                for bank in banks.values()
            )
            if all_dash:
                errors.append(
                    "parameterbanks present but all slots are '-' (param_banks crash trap)"
                )

    longnames = {}
    has_thisdevice = False

    for inner in walk_boxes(patcher):
        text = inner.get("text", "")
        if text == "live.thisdevice" or inner.get("maxclass") == "live.thisdevice":
            has_thisdevice = True

        attrs = param_attrs(inner)
        if inner.get("parameter_enable") == 1 or attrs.get("parameter_initial_enable") == 1:
            longname = attrs.get("parameter_longname")
            box_id = inner.get("id", "<unknown>")
            if not longname:
                errors.append(
                    f"box id={box_id} ({inner.get('maxclass', '?')}) has parameter_enable but no parameter_longname"
                )
            else:
                if longname in longnames:
                    errors.append(
                        f"duplicate parameter_longname '{longname}' on box {box_id} (also on {longnames[longname]})"
                    )
                else:
                    longnames[longname] = box_id

        pr = inner.get("presentation_rect")
        if isinstance(pr, list) and len(pr) == 4 and inner.get("presentation") == 1:
            y, h = pr[1], pr[3]
            if (y + h) > PRESENTATION_Y_LIMIT:
                errors.append(
                    f"box id={inner.get('id', '?')} presentation_rect y+h={y + h} exceeds {PRESENTATION_Y_LIMIT}px band"
                )

    if not has_thisdevice:
        errors.append("no live.thisdevice present in patcher")

    # ── Check 5: No overlapping live.* presentation boxes ─────────────────────
    # Panels are excluded (intentionally behind live.* controls).
    overlaps = find_presentation_overlaps(doc)
    for ov in overlaps:
        a = ov["a"]
        b = ov["b"]
        from render_presentation import box_label as _box_label  # noqa: F401
        a_label = _box_label(a)
        b_label = _box_label(b)
        a_id = a.get("id") or a.get("varname", "?")
        b_id = b.get("id") or b.get("varname", "?")
        ax, ay, aw, ah = ov["a_rect"]
        bx, by, bw, bh = ov["b_rect"]
        errors.append(
            f"live.* overlap: [{a_id}] '{a_label}' [{int(ax)},{int(ay)},{int(aw)},{int(ah)}]"
            f" overlaps [{b_id}] '{b_label}' [{int(bx)},{int(by)},{int(bw)},{int(bh)}]"
            f" (area={ov['overlap_area']:.0f}px²)"
        )

    return errors


def main():
    if len(sys.argv) != 2:
        sys.stderr.write("Usage: validate_maxpat.py <path-to-.maxpat>\n")
        sys.exit(2)

    errors = validate(sys.argv[1])
    if errors:
        for e in errors:
            sys.stderr.write(f"ERROR: {e}\n")
        sys.exit(1)
    print(f"OK: {sys.argv[1]}")
    sys.exit(0)


if __name__ == "__main__":
    main()
