#!/usr/bin/env python3
"""render_presentation.py — SVG layout visualizer for NAM.maxpat presentation boxes.

Reads every box with presentation:1, draws its presentation_rect as an SVG rect,
annotates each with a label, draws the 166-px guideline, draws §5 wireframe
region outlines, and detects overlaps among live.* boxes.

Usage:
    python3 scripts/render_presentation.py m4l/NAM.maxpat -o m4l/NAM.presentation.svg

Exit codes:
    0 — no overlaps detected
    1 — one or more live.* overlaps detected
"""

import argparse
import json
import sys
import os


# ── §5 wireframe regions ─────────────────────────────────────────────────────

WIREFRAME_REGIONS = [
    {"label": "Amp Head",   "x": 0,   "y": 0,  "w": 310, "h": 166},
    {"label": "Tone Stack", "x": 320, "y": 0,  "w": 180, "h": 166},
    {"label": "IR",         "x": 510, "y": 0,  "w": 320, "h": 166},
]

LIMIT_Y = 166

# ── fill colours by maxclass ─────────────────────────────────────────────────

CLASS_FILL = {
    "live.dial":    "#cfe2ff",
    "live.gain~":   "#e0d5ff",
    "live.text":    "#fff3cd",
    "live.menu":    "#d4edda",
    "umenu":        "#d4edda",
    "live.meter~":  "#fff0e0",
    "panel":        None,       # use bgcolor or fallback
    "comment":      "none",
    "waveform~":    "#ffc0cb",
    "spectrumdraw~":"#ffc0cb",
    "jsui":         "#ffc0cb",
    "message":      "#f8f9fa",
}

DEFAULT_FILL   = "#ffffff"
PANEL_FALLBACK = "#eeeeee"

# ── helpers ───────────────────────────────────────────────────────────────────

def load_maxpat(path):
    with open(path, "rb") as f:
        return json.loads(f.read())


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


def box_label(inner):
    attrs = param_attrs(inner)
    longname = attrs.get("parameter_longname")
    if longname:
        return longname
    text = (inner.get("text") or "").strip()
    if text:
        return text[:40]
    varname = inner.get("varname") or inner.get("id") or ""
    if varname:
        return varname[:40]
    return inner.get("maxclass", "?")[:40]


def is_live_star(inner):
    cls = inner.get("maxclass", "")
    return cls.startswith("live.") and cls not in ("live.thisdevice",)


def is_panel(inner):
    return inner.get("maxclass") == "panel"


def rect_to_xywh(pr):
    """Return (x, y, w, h) from a presentation_rect list [x, y, w, h]."""
    return float(pr[0]), float(pr[1]), float(pr[2]), float(pr[3])


def rects_overlap(ax, ay, aw, ah, bx, by, bw, bh):
    """Return the overlap area (≥ 0). 0 means no overlap."""
    ox = max(0.0, min(ax + aw, bx + bw) - max(ax, bx))
    oy = max(0.0, min(ay + ah, by + bh) - max(ay, by))
    return ox * oy


def find_presentation_overlaps(doc):
    """Return a list of overlap dicts for live.* boxes that intersect each other.

    Each dict has:
      {
        'a': inner_box_dict,
        'b': inner_box_dict,
        'overlap_area': float,
        'a_rect': (x, y, w, h),
        'b_rect': (x, y, w, h),
      }

    Panel boxes are excluded from overlap detection (panels intentionally sit
    under controls). Non-live.* boxes (comment, message, etc.) are also excluded.
    """
    patcher = doc.get("patcher", {})
    live_boxes = []
    for inner in walk_boxes(patcher):
        if not is_live_star(inner):
            continue
        if inner.get("presentation") != 1:
            continue
        pr = inner.get("presentation_rect")
        if not (isinstance(pr, list) and len(pr) == 4):
            continue
        live_boxes.append(inner)

    overlaps = []
    for i in range(len(live_boxes)):
        for j in range(i + 1, len(live_boxes)):
            a = live_boxes[i]
            b = live_boxes[j]
            ax, ay, aw, ah = rect_to_xywh(a["presentation_rect"])
            bx, by, bw, bh = rect_to_xywh(b["presentation_rect"])
            area = rects_overlap(ax, ay, aw, ah, bx, by, bw, bh)
            if area > 0:
                overlaps.append({
                    "a": a,
                    "b": b,
                    "overlap_area": area,
                    "a_rect": (ax, ay, aw, ah),
                    "b_rect": (bx, by, bw, bh),
                })
    return overlaps


# ── SVG generation ────────────────────────────────────────────────────────────

def escape_xml(s):
    return (s.replace("&", "&amp;")
              .replace("<", "&lt;")
              .replace(">", "&gt;")
              .replace('"', "&quot;"))


def rgb_from_bgcolor(bg):
    """Convert Max RGBA float list [r,g,b,a] to SVG hex."""
    if not bg or len(bg) < 3:
        return PANEL_FALLBACK
    r = int(bg[0] * 255)
    g = int(bg[1] * 255)
    b = int(bg[2] * 255)
    return f"#{r:02x}{g:02x}{b:02x}"


def truncate_label(label, max_chars=25):
    if len(label) > max_chars:
        return label[:max_chars - 1] + "…"
    return label


def render_svg(doc, output_path):
    """Generate and write an SVG visualisation; return (overlaps list)."""

    patcher = doc.get("patcher", {})
    all_pres = []
    for inner in walk_boxes(patcher):
        if inner.get("presentation") != 1:
            continue
        pr = inner.get("presentation_rect")
        if not (isinstance(pr, list) and len(pr) == 4):
            continue
        all_pres.append(inner)

    # Determine SVG canvas size from bounding box of all presentation rects
    # plus some margin; at minimum 850 × 200.
    xs = [pr[0] for b in all_pres for pr in [b["presentation_rect"]]]
    ys = [pr[1] for b in all_pres for pr in [b["presentation_rect"]]]
    x2s = [pr[0] + pr[2] for b in all_pres for pr in [b["presentation_rect"]]]
    y2s = [pr[1] + pr[3] for b in all_pres for pr in [b["presentation_rect"]]]

    if xs:
        min_x, max_x = min(xs), max(x2s)
        min_y, max_y = min(ys), max(y2s)
    else:
        min_x, max_x, min_y, max_y = 0, 850, 0, 200

    MARGIN = 30
    SVG_W = max(max_x + MARGIN, 880)
    SVG_H = max(max_y + MARGIN + 40, 220)  # extra for guideline label

    # Collect overlapping box IDs for red-border marking
    overlaps = find_presentation_overlaps(doc)
    overlap_ids = set()
    for ov in overlaps:
        for k in ("a", "b"):
            bid = ov[k].get("id") or ov[k].get("varname")
            if bid:
                overlap_ids.add(bid)

    lines_svg = []
    lines_svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" '
                     f'width="{SVG_W}" height="{SVG_H}" '
                     f'style="font-family: monospace; background: #fafafa;">')

    # Defs: striped pattern for waveform~/jsui
    lines_svg.append("""  <defs>
    <pattern id="stripes" patternUnits="userSpaceOnUse" width="8" height="8" patternTransform="rotate(45)">
      <line x1="0" y1="0" x2="0" y2="8" stroke="#ffc0cb" stroke-width="4"/>
    </pattern>
  </defs>""")

    # ── draw §5 wireframe region outlines ──────────────────────────────────
    for region in WIREFRAME_REGIONS:
        rx, ry, rw, rh = region["x"], region["y"], region["w"], region["h"]
        lines_svg.append(
            f'  <rect x="{rx}" y="{ry}" width="{rw}" height="{rh}" '
            f'fill="none" stroke="#aaaacc" stroke-width="1" stroke-dasharray="4 3"/>'
        )
        lines_svg.append(
            f'  <text x="{rx + 4}" y="{ry + 12}" font-size="10" fill="#6666aa">'
            f'{escape_xml(region["label"])}</text>'
        )

    # ── draw 166-px guideline ──────────────────────────────────────────────
    lines_svg.append(
        f'  <line x1="0" y1="{LIMIT_Y}" x2="{SVG_W}" y2="{LIMIT_Y}" '
        f'stroke="#cc3333" stroke-width="1" stroke-dasharray="6 4"/>'
    )
    lines_svg.append(
        f'  <text x="4" y="{LIMIT_Y - 3}" font-size="9" fill="#cc3333">'
        f'166 px detail-view limit</text>'
    )

    # ── draw each presentation box ─────────────────────────────────────────
    for inner in all_pres:
        pr = inner["presentation_rect"]
        bx, by, bw, bh = rect_to_xywh(pr)
        cls = inner.get("maxclass", "")
        bid = inner.get("id") or inner.get("varname") or ""

        # Determine fill
        if cls == "panel":
            bg = inner.get("bgcolor")
            fill = rgb_from_bgcolor(bg) if bg else PANEL_FALLBACK
        elif cls in ("waveform~", "spectrumdraw~", "jsui"):
            fill = "url(#stripes)"
        elif cls == "comment":
            fill = "none"
        else:
            fill = CLASS_FILL.get(cls, DEFAULT_FILL)

        # Stroke: red if overlapping, dark-grey otherwise, none for comment
        if cls == "comment":
            stroke = "none"
            stroke_w = 0
        elif bid in overlap_ids:
            stroke = "#cc0000"
            stroke_w = 2
        else:
            stroke = "#555555"
            stroke_w = 1

        lines_svg.append(
            f'  <rect x="{bx}" y="{by}" width="{bw}" height="{bh}" '
            f'fill="{fill}" stroke="{stroke}" stroke-width="{stroke_w}"/>'
        )

        # For live.dial, draw a small circle to suggest a knob
        if cls == "live.dial" and bw >= 20 and bh >= 20:
            cr = min(bw, bh) / 2 - 4
            cx = bx + bw / 2
            cy = by + bh / 2
            lines_svg.append(
                f'  <circle cx="{cx:.1f}" cy="{cy:.1f}" r="{cr:.1f}" '
                f'fill="none" stroke="#335588" stroke-width="1.5"/>'
            )

        # Label inside the box
        label = truncate_label(box_label(inner))
        font_size = 9 if bh < 16 else 10
        text_x = bx + 3
        text_y = by + bh / 2 + font_size * 0.35
        if cls == "comment":
            text_y = by + font_size + 2
        lines_svg.append(
            f'  <text x="{text_x:.1f}" y="{text_y:.1f}" font-size="{font_size}" fill="#222222" '
            f'clip-path="inset(0 0 0 0)">{escape_xml(label)}</text>'
        )

    lines_svg.append("</svg>")

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines_svg))

    return overlaps


def print_layout_summary(doc):
    """Print counts, bounding box, and parameter count to stdout."""
    patcher = doc.get("patcher", {})
    class_counts = {}
    live_param_count = 0
    xs, ys, x2s, y2s = [], [], [], []

    for inner in walk_boxes(patcher):
        if inner.get("presentation") != 1:
            continue
        pr = inner.get("presentation_rect")
        if not (isinstance(pr, list) and len(pr) == 4):
            continue

        cls = inner.get("maxclass", "unknown")
        class_counts[cls] = class_counts.get(cls, 0) + 1

        if is_live_star(inner) and inner.get("parameter_enable") == 1:
            live_param_count += 1

        xs.append(pr[0]); ys.append(pr[1])
        x2s.append(pr[0] + pr[2]); y2s.append(pr[1] + pr[3])

    print("=== Layout Summary ===")
    for cls, cnt in sorted(class_counts.items()):
        print(f"  {cls:25s} × {cnt}")
    print(f"  Total live.* parameters:  {live_param_count}")
    if xs:
        print(f"  Bounding box of all rects: x={min(xs):.0f}..{max(x2s):.0f}, "
              f"y={min(ys):.0f}..{max(y2s):.0f}")
    print()


# ── main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Render NAM.maxpat presentation boxes to an SVG layout visualizer."
    )
    parser.add_argument("maxpat", help="Path to NAM.maxpat")
    parser.add_argument("-o", "--output", default=None,
                        help="Output SVG path (default: m4l/NAM.presentation.svg next to maxpat)")
    args = parser.parse_args()

    maxpat_path = args.maxpat
    if args.output:
        svg_path = args.output
    else:
        svg_path = os.path.join(os.path.dirname(os.path.abspath(maxpat_path)),
                                "NAM.presentation.svg")

    doc = load_maxpat(maxpat_path)
    print_layout_summary(doc)

    overlaps = render_svg(doc, svg_path)

    if overlaps:
        print("=== Overlap Report ===")
        for ov in overlaps:
            a_label = box_label(ov["a"])
            b_label = box_label(ov["b"])
            a_id = ov["a"].get("id") or ov["a"].get("varname", "?")
            b_id = ov["b"].get("id") or ov["b"].get("varname", "?")
            ax, ay, aw, ah = ov["a_rect"]
            bx, by, bw, bh = ov["b_rect"]
            print(f"  OVERLAP: [{a_id}] '{a_label}' {[int(v) for v in [ax, ay, aw, ah]]}")
            print(f"       vs. [{b_id}] '{b_label}' {[int(v) for v in [bx, by, bw, bh]]}")
            print(f"       overlap area: {ov['overlap_area']:.0f} px²")
        print(f"\n{len(overlaps)} overlap(s) detected. SVG written: {svg_path}")
        print("(Overlapping boxes are marked with red borders in the SVG.)")
        sys.exit(1)
    else:
        print("=== Overlap Report ===")
        print("  No live.* overlaps detected.")
        print(f"\nSVG written: {svg_path}")
        sys.exit(0)


if __name__ == "__main__":
    main()
