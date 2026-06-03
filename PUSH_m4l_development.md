# Push 3 + Max for Live (M4L) Development Notes

Cross-project reference for building Max for Live devices that expose parameters to
the Ableton Push 3 hardware controller. Written to be read by an agent with **no
prior context** about any specific device. All claims below were verified empirically
on real Push 3 hardware unless noted.

---

## 1. How Push 3 displays an enum parameter's value name

Push reads a parameter's `value_items` / `short_value_items` from Live (these are
populated by Live's C++ core; the decompiled Push Python only *consumes* them). The
Max control class you use determines whether your enum names ever reach Push:

| Max object | parameter setup | What Push shows |
|---|---|---|
| `live.text` (mode 1 toggle) | `parameter_type 2` + `parameter_enum` | **`val1` / `val2`** — enum names are NOT surfaced |
| `live.menu` | `parameter_type 2` + `parameter_enum` | **The real item names** (e.g. `Off` / `On`) ✅ |
| `live.toggle` | boolean (`parameter_type 1`) | a raw `0` / `1` dial, not clean text |

**Conclusion: the only control class that surfaces clean text values under a Push
encoder is `live.menu`.** `val1/val2` is Live's generic fallback name for a 2-value
enum parameter whose names it never received — it is not a Push concept and appears
nowhere in the Push source.

This was proven with a 3-control "discriminator" device (one `live.text`, one
`live.menu`, one `live.toggle`, all enum `["Off","On"]`, all on one baked bank).

---

## 2. The `parameter_enable=0` gotcha (live.text won't fake a toggle)

A `live.text` in toggle mode (`mode 1`) with `parameter_enable=0` does **NOT** hold or
draw its on/off state. Clicking it does nothing visually. It only works as a visual
toggle when it is a **real parameter** (`parameter_enable=1`).

Consequence: you cannot make the visible toggle a "display-only, non-parameter"
control. It must stay a real parameter.

---

## 3. Pattern: show `Off/On` on Push for a toggle WITHOUT changing desktop appearance

Goal: a device has an on/off button drawn as a `live.text` toggle (e.g. "Gate off" /
"Gate on"). You want Push to show `Off/On` for it, but the device's desktop/Live
appearance must stay byte-identical.

Because only `live.menu` surfaces enums (§1) and `live.text` must stay a parameter to
function (§2), use a **hidden-menu-shadow** with two parameters:

- **Visible `live.text`** — keep `parameter_enable=1`, `mode 1`, original `text`/`texton`.
  Give it a **distinct longname** (e.g. `"Bypass UI"`) and set `parameter_invisible=1`
  ("Stored Only") so it is hidden from Push and from the automation lane, while still
  drawing/clicking normally on the desktop. (This is the same trick the prev/next
  nav buttons in the NAM device use.)
- **Hidden `live.menu`** — `hidden=1`, `parameter_enum ["Off","On"]`, `parameter_type 2`.
  Give it the **banked longname** (e.g. `"Bypass"`) — i.e. whatever the Push bank
  definitions and any loader JS already reference. This becomes the Push-facing AND
  automatable parameter. Because it keeps the original banked longname, **no bank
  definition or loader-JS edits are needed.**

### Wiring (bidirectional sync, no feedback loop)

```
visible toggle  --[outlet 0, plain int]-->  hidden menu        (click drives param + audio + Push)
hidden menu     --[outlet 0]--> prepend set --> visible toggle  (remote/automation/load updates display; "set" suppresses output -> no loop)
hidden menu     --[outlet 0]--> (+ 1) --> selector~ / audio     (drives the audio path)
live.thisdevice --[outlet 0]--> hidden menu                     (load-time init: bang outputs restored value -> sets toggle + audio)
```

Why each piece:
- `prepend set` → `live.text`: the `set 0/1` message sets the toggle's displayed state
  **without** sending output, which breaks the otherwise-infinite mirror loop. (For
  `live.menu` the equivalent is also `set`; for `live.text` confirm `set N` toggles
  display per its docs.)
- `live.thisdevice` outlet 0 is the canonical M4L load trigger — it fires **after**
  parameters are restored from the saved set, so banging the menu there outputs the
  restored value, which both initializes the audio selector and sets the visible
  toggle's display. Don't rely on the visible control auto-outputting on load if the
  parameter has moved off it.

### Important Push enumeration fact

With **baked `parameterbanks`** present in the device (i.e. `patcher.parameters.
parameterbanks` has `bank_count > 0` at load), **Push shows ONLY the baked banks**.
Non-banked enabled parameters do NOT form an auto "Main" page. (Confirmed: enabled,
non-banked, non-invisible "expand" toggles never appear on Push.) So in a baked-bank
device, `parameter_invisible=1` on the visible shadow toggle is belt-and-suspenders —
it would be hidden anyway. It still matters in devices without baked banks.

---

## 4. General M4L / Push facts worth remembering

- **`parameter_type`**: `0` = Float, `1` = Int/boolean, `2` = Enum. Changing a released
  parameter's `parameter_type` in place corrupts saved presets/automation — instead
  give the new control a new longname and migrate.
- **Push banks reference parameters by longname**, not by Max varname. Two parameters
  may not share a longname (collision).
- **Baked vs runtime banks**: baking `parameterbanks` into the saved device means the
  device reports `bank_count > 0` the instant Live loads it — before any runtime JS
  (`live.banks new/edit`) runs. This wins the race against Push's first device
  enumeration and avoids the "one encoder column per parameter on first load" bug that
  occurs when banks are only created later at runtime.
- **`parameter_invisible` / Parameter Visibility**: `1` = "Stored Only" — saved with
  the set, still drawn/clickable in the device UI, but kept out of the automation lane
  and out of Push. Used for UI-only mirror controls and nav buttons.

---

## 5. Debugging gotcha that cost real time

**The Max *editor* instance and the device instance running in Ableton/Push are
SEPARATE processes.** Editing the patch, or sending messages via the Max MCP tools,
affects only the editor instance. The Live device does not reflect a change until you
(a) rebuild the `.amxd` and (b) reload the device in Live. When a fix "doesn't take
effect," first confirm *which instance* you're testing. Likewise, an `.amxd` is a
32-byte header + verbatim `.maxpat` JSON, so the device is only as current as the last
`.amxd` build.

---

## 6. Verifying changes (build/test loop for the NAM device, as an example)

```
python3 scripts/build_nam_maxpat.py                       # regenerate .maxpat
python3 scripts/validate_maxpat.py m4l/NAM.maxpat          # structural checks
python3 scripts/build_amxd.py m4l/NAM.maxpat m4l/NAM.amxd  # wrap into .amxd
# JS/py test suites: tests/test_banks.js, tests/test_nam_loader.js,
#                    tests/test_validate_maxpat.py, tests/test_push_name_patch.js
```
`validate_maxpat.py` catches longname collisions and `parameter_enable=1` without a
longname. None of this confirms Push *display* — that requires reloading the `.amxd`
in Live and looking at the hardware (see §5).
