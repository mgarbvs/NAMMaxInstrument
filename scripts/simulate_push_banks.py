#!/usr/bin/env python3
"""simulate_push_banks.py — Show what Push 3 would display for NAM.amxd.

Reads the .maxpat, extracts all parameter_enable=1 params, then applies the
_initBanks() configuration to show what Push would compute.

Logic matches MaxDeviceParameterBank (Push3/device_parameter_bank.pyc):
  bank_count = get_bank_count() + int(_has_main_bank)
  _has_main_bank = bool(get_bank_encoder_parameters(-1))

LIMITATION: This script verifies static structure only — whether the right
params are enabled and their longnames match INIT_BANKS. It cannot verify
that the JavaScript code in _initBanks() correctly sends those messages at
runtime. In particular, Function.prototype.apply on native Max object methods
(JsObject.message) silently drops variadic args — this script would still
show green even if the JS uses apply incorrectly. Always use explicit args
in b.message() calls, not apply/spread.

Usage:
  python3 scripts/simulate_push_banks.py             # uses m4l/NAM.maxpat
  python3 scripts/simulate_push_banks.py m4l/NAMTest.maxpat
"""

import json
import sys
import os

MAXPAT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "m4l", "NAM.maxpat"
)

# ── _initBanks() configuration ─────────────────────────────────────────────
# Mirror exactly what nam_loader.js _initBanks() sends to live.banks.
# Format: (bank_id, bank_name, param_longname, param_longname, ...)
# Edit this section to test different bank layouts.
INIT_BANKS = [
    (0, "NAM",  "NAM Cat", "NAM Model 0"),
    (1, "IR",   "IR Cat",  "IR File 0"),
    # Proposed additional banks to eliminate main bank:
    # (2, "Tone", "Bass", "Mid", "Treble", "Noise Gate Threshold", "NAM Dry/Wet", "Tone Stack On", "Tone Section", "IR Section"),
    # (3, "FX",   "IR Dry/Wet", "Input", "NAM Out", "Noise Gate On", "IR On", "Bypass"),
]

# ── Parse .maxpat ───────────────────────────────────────────────────────────

with open(MAXPAT) as f:
    pat = json.load(f)

enabled_params = {}  # longname → {shortname, class, enum_len}
for box in pat["patcher"]["boxes"]:
    b = box["box"]
    if b.get("parameter_enable") != 1:
        continue
    saa = b.get("saved_attribute_attributes", {})
    vof = saa.get("valueof", {})
    longname = vof.get("parameter_longname", "")
    if not longname:
        continue
    enum = vof.get("parameter_enum", [])
    enabled_params[longname] = {
        "shortname": vof.get("parameter_shortname", ""),
        "class":     b.get("maxclass", ""),
        "enum_len":  len(enum),
        "enum_preview": enum[:3],
    }

# ── Apply live.banks new calls ──────────────────────────────────────────────

custom_banks = {}   # bank_id → {"name": str, "slots": [(longname, found)]}
in_custom = set()

for entry in INIT_BANKS:
    bank_id   = entry[0]
    bank_name = entry[1]
    params    = list(entry[2:])
    slots = []
    for p in params:
        found = p in enabled_params
        slots.append((p, found))
        if found:
            in_custom.add(p)
    custom_banks[bank_id] = {"name": bank_name, "slots": slots}

# ── Compute Push view ───────────────────────────────────────────────────────

orphaned    = {k: v for k, v in enabled_params.items() if k not in in_custom}
has_main    = len(orphaned) > 0
get_bank_count = len(custom_banks)
bank_count  = get_bank_count + int(has_main)

# ── Report ──────────────────────────────────────────────────────────────────

print(f"Source: {os.path.basename(MAXPAT)}")
print(f"parameter_enable=1 params: {len(enabled_params)}")
print(f"Custom banks (live.banks new): {get_bank_count}")
print(f"_has_main_bank: {has_main}  ({len(orphaned)} orphaned params)")
print(f"Push bank_count: {bank_count}  ← this many pages on Push")
print()

# Custom banks
for bank_id in sorted(custom_banks.keys()):
    info = custom_banks[bank_id]
    print(f"  Push page {bank_id + int(has_main) + 1 - 1}  Bank {bank_id} '{info['name']}':")
    for longname, found in info["slots"]:
        marker = "✓" if found else "✗ NOT FOUND"
        ep = enabled_params.get(longname, {})
        enum_note = ""
        if found and ep.get("enum_len"):
            enum_note = f"  [{ep['enum_len']} items: {ep['enum_preview']}…]"
        print(f"    {marker}  \"{longname}\" / \"{ep.get('shortname', '?')}\"{enum_note}")

# Main bank
if has_main:
    print(f"\n  Push page {bank_count} (MAIN BANK — 'Bank {bank_count}' or 'Main'):")
    print(f"  {len(orphaned)} orphaned params (first 12):")
    for i, (name, info) in enumerate(sorted(orphaned.items())):
        if i >= 12:
            print(f"    … and {len(orphaned) - 12} more")
            break
        print(f"    [{info['class']}] \"{name}\" / \"{info['shortname']}\"")

print()
if not has_main:
    print("✅  No main bank — Push shows exactly the custom banks above.")
elif get_bank_count == 0:
    print("⚠️  No custom banks — Push uses DeviceParameterBank (all-columns view).")
else:
    print(f"⚠️  Main bank present — Push shows {bank_count} pages, last is '{f'Bank {bank_count}'}' with orphaned params.")

print()
print("── Params NOT in any custom bank ──")
for cls in ["live.gain~", "live.dial", "live.text", "live.toggle", "live.menu", "live.drop"]:
    group = [(n, v) for n, v in orphaned.items() if v["class"] == cls]
    if group:
        label = cls.ljust(12)
        names = [f'"{n}"' for n, _ in group[:6]]
        more = f" +{len(group)-6} more" if len(group) > 6 else ""
        print(f"  {label}  {', '.join(names)}{more}")
