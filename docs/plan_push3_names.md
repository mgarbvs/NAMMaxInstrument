# Plan: Bake real file names into Push 3 enum display

> **Status (not implemented as written).** The runtime "Save Push Names" button +
> `push_name_patch.js` + `patch_push_enum` handler described below were **never wired**
> (`push_name_patch.js` is an orphan module; no `node.script` loads it). What actually
> ships: **`build_nam_maxpat.py` bakes `parameter_enum` from the library at *build* time**
> (`_build_push_enums()` scans `NAM_ROOT`/`IR_ROOT`). To refresh Push names after adding
> models/IRs: edit those roots if needed, then `python3 scripts/build_nam_maxpat.py &&
> python3 scripts/build_amxd.py m4l/NAM.maxpat m4l/NAM.amxd` and reload the device. The
> root-cause analysis below (Push caches `parameter_enum` at load; no runtime update path)
> is still accurate and is *why* the build-time bake + reload is the workflow.

## Goal

When NAM.amxd loads, Push 3 should show the actual NAM model and IR file names
instead of "1", "2", "3", ... The approach is to update the amxd on disk with the
current file lists baked into each shadow live.menu's `parameter_enum`, then prompt
the user to reload the device.

## What has already been tried and ruled out

All of the following were tested exhaustively during this session and confirmed to
have no effect on Push 3's displayed names:

- `_parameter_range` message (same-count and count-change)
- `LiveAPI.set("items", ...)` — attribute doesn't exist on DeviceParameter
- `setattr("parameter_shortname", ...)` and `setattr("parameter_enable", ...)`
- All `parameter_visibility` modes: "Automated and Stored", "Visible", "Visible (Not
  Stored)", "Stored Only", "Hidden"

**Root cause**: Push 3 reads `parameter_enum` from the amxd binary at device-load
time and caches it. No runtime update path exists.

## Two candidate approaches

### A. Save-and-reload (recommended)

1. A "Save Push Names" button triggers JS → node script
2. Node script scans the current library roots, builds enum arrays, and rewrites
   `NAM.amxd` on disk with real names baked in (atomic write)
3. UI shows "Push names saved — reload device to apply"
4. On next load Push 3 reads the real names

**Trade-off**: requires one manual reload per library change. Names stay correct
until the folder structure changes (files added/removed/renamed).

### B. Auto-reload via LiveAPI device reinsertion

The running device could delete and re-insert itself using the LOM
(`live_set tracks N devices M` → delete → load amxd path). This removes the
manual step but **loses all in-session state**: parameter automation, undo history,
any clip automation pointing at this device's parameters. Not recommended for a
production instrument.

## Recommended implementation (Approach A)

### Files to change

| File | Change |
|------|--------|
| `m4l/nam_state.js` | Add `patch_push_enum` handler; scans roots and rewrites amxd |
| `m4l/nam_loader.js` | Add `save_push_names` message handler; calls messnamed to trigger node script; shows status |
| `scripts/build_nam_maxpat.py` | Add receive/prepend wiring for `patch_push_enum` round-trip |
| `m4l/NAM.maxpat` / `m4l/NAM.amxd` | Rebuilt from script |

### amxd binary format (from `scripts/build_amxd.py`)

```
4 bytes  "ampf"
4 bytes  LE uint32(4)       -- section length
8 bytes  "aaaameta"
4 bytes  LE uint32(4)       -- meta section length
4 bytes  LE uint32(1)       -- meta value
4 bytes  "ptch"
4 bytes  LE uint32(N)       -- JSON byte length
N bytes  <JSON>             -- verbatim .maxpat content
```

Header is always **32 bytes** (the field list above sums to 32; the final
JSON-length `uint32` sits at offset 28). Strip the 32-byte header, `JSON.parse`,
mutate, `JSON.stringify`, rewrite the length field at offset 28, prepend the
header, write atomically (`NAM.amxd.tmp` → rename). This matches
`push_name_patch.js` (`AMXD_HEADER_SIZE = 32`) and `build_amxd.py`.

### JSON path to mutate (four targets)

```
patcher.boxes[i].box.saved_attribute_attributes.valueof.parameter_enum
```

Target `box.varname` values: `nam_cat_idx`, `nam_model_idx`, `ir_cat_idx`,
`ir_file_idx`.

### Enum array strategy

Bake exactly N real names (no padding to 100). This means:

- Push 3 sees N items on next load → clean short list with real names
- Max-side live.menu also initializes with N items from amxd
- `_syncPushNames` still sends `_parameter_range` on category change (updates
  Max-side count/names; no effect on Push until next reload, which is fine)
- The LiveAPI observers added in the previous commit handle any out-of-range
  values that arise from switching categories between reloads

### What names to bake

At save time, scan the **category-zero files** for each list type:

- `nam_cat_idx` → category names from the NAM root (one per subdirectory)
- `nam_model_idx` → model files in the **first NAM category** (category 0)
- `ir_cat_idx` → category names from the IR root
- `ir_file_idx` → IR files in the **first IR category** (category 0)

This matches what the device shows on first load. Baking category 0 is the
right default because the device always starts there.

### IPC path (match existing pattern)

Existing pattern in `nam_loader.js`: `messnamed("nam_state_set_nam_root", p)`
→ patch receive "nam_state_set_nam_root" → prepend "set_nam_root" → node.script
inlet.

Add similarly:

- Trigger: `messnamed("nam_state_patch_push_enum", "")` from a new
  `save_push_names()` JS function
- Patch wiring: receive "nam_state_patch_push_enum" → prepend "patch_push_enum"
  → node.script inlet
- Response: node.script calls `maxApi.outlet(...)` → existing route back to
  loader JS via a new message selector, OR just post a status string to the
  existing status display

The response message should be one of:
- `"Push names saved — reload device to apply"` (success)
- `"Push name save failed: <reason>"` (error)

Node script already knows `__dirname` = `m4l/`, so amxd path is simply
`path.join(__dirname, "NAM.amxd")`.

### Node script file scanning

`nam_state.js` already stores `state.nam_root` and `state.ir_root`. The
`patch_push_enum` handler can scan those paths directly using Node's `fs`
module — no need to pass lists over IPC.

Directory scan for categories: `fs.readdirSync(root)` filtered to directories
(not hidden). Sort alphabetically to match `nam_loader.js` `listSubdirs` order.

File scan for models/IRs: `fs.readdirSync(cat0_path)` filtered to `.nam` or
`.wav`/`.aiff` extensions. Sort alphabetically.

If a root is empty string, skip that array (leave existing enum unchanged in
the amxd, or write `[""]` as a single-item placeholder so live.menu doesn't
break).

### Display-name trimming

`nam_loader.js` trims the common prefix from model/IR file display names.
The node script should apply the same trimming so baked names match what the
loader shows in the computer UI. The algorithm:

```
common_prefix = longest common prefix of all names
trim to last word boundary (last space before prefix end)
for each name: strip prefix + leading whitespace/hyphens/underscores
strip file extension (.nam, .wav, .aiff) before trimming
```

This is worth getting right so that Push names and the computer dropdown match.

### UI button

Add a button labeled "Push Names" (or similar) to the existing device UI panel
in `build_nam_maxpat.py`. It sends `save_push_names` to the jsloader inlet.

The button should live near the IR/NAM root displays. Exact coordinates to be
determined by the implementer — just keep it in the visible device footprint.

### Atomic write in node script

```javascript
const tmp = amxdPath + ".tmp";
fs.writeFileSync(tmp, newBuffer);
fs.renameSync(tmp, amxdPath);
```

This matches the existing `save()` pattern in `nam_state.js`. On macOS,
`rename` is atomic at the filesystem level. Live holds the amxd open but only
reads it at load time, so the rename is safe; Live won't pick up the change
until the user reloads the device.

## Testing

### Automatable by the implementer

1. **Roundtrip unit test** (`tests/test_push_name_patch.js` or `.py`):
   - Load a known `NAM.amxd`
   - Call the patch logic with synthetic name arrays
   - Read the written amxd back, parse JSON, assert `parameter_enum` values match
   - Assert amxd binary header is byte-for-byte identical to original
   
2. **Directory scan test**: given a fixture folder tree, assert the correct
   sorted/trimmed name list is produced.

3. **Build smoke test**: `python3 scripts/build_nam_maxpat.py` should succeed and
   include the new button + receive/prepend wiring in the generated maxpat.

### Requires user (Push 3 hardware)

- Load NAM.amxd, set NAM root and IR root, click "Push Names" button
- Verify Max console shows success status
- Reload device on the track
- Verify Push 3 shows actual model/IR names on the encoders (not "1", "2", ...)
- Verify encoder scrolling is still bounded (observer clamping still active)
- Switch IR category → verify names update on computer UI; encoder still clamped
  (Push still shows old names until next save+reload — this is expected and OK)

## Out of scope for this plan

- Updating Push names automatically on every category change (would require
  auto-reload which loses device state)
- Showing more than `num_slots=100` items (not needed; baking handles the count)
- Windows path handling differences (defer until Windows testing)
