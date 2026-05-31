# live.banks — Push 3 API Reference

Sourced from: Max 9 `live.banks.maxref.xml`, `live.banks.maxhelp`, and Push3.app Python bytecode.

---

## Messages

### `new bank_id bank_name [param1 param2 ...]`

Creates a bank. **Inserts** at `bank_id`; existing banks at that index and above are shifted up. Never replaces.

- `bank_name`: required. Sets the name Push displays for this bank page.
- Params: up to 8 symbols (parameter long names), positional (slot 0–7). Use `-` for an empty slot.
- If param names don't resolve at call time (e.g. at `loadbang` before Live initializes), the bank **structure** is created (bank count increases) but the **name may not persist** through the parameter hub. Use `edit` after `live.thisdevice` to set the real name.
- Creating bank N when banks 0..N-1 don't exist creates **dummy banks** for the gaps. Dummy banks have no name and grey text in the editor. Editing a dummy bank promotes it to a real bank.

**Index-based variant (not used in our code):** same as above but params are `param_index param_name` pairs.

### `edit bank_id bank_name param_index param_name [param_index param_name ...]`

Updates an existing bank. Fires `bank_parameters_changed`, which Push handles immediately to update its display — no navigate-away required.

- `bank_name`: pass `-` to **keep the existing name**; pass a string to change it.
- Params: `param_index param_name` pairs. Only specified slots are changed; others are untouched.
- Use `-` as `param_name` to clear a slot.
- Multiple separate `edit` calls fire `bank_parameters_changed` once each. Prefer a **single combined call** (all slots in one message) to avoid rapid double-firing.

**Positional variant:** `edit bank_id bank_name param0 param1 param2 ...` (symbols, up to 8, positional). Detected by whether the first arg after bank_name is a symbol vs integer.

### `delete bank_id`

Removes the bank. Higher-indexed banks shift down.

### `getcount` → `count N`

Reports number of banks.

### `getname bank_id` → `name bank_id bank_name`

Reports the name of a bank.

### `getparameters bank_id` → `parameters bank_id param0 param1 ...`

Reports the parameter long names assigned to a bank's encoder slots.

---

## How Push 3 selects bank type (`create_device_bank`)

Source: `Push3.app/python/Push2/device_parameter_bank.pyc` (Python 3.11 bytecode, decompiled).

```python
def create_device_bank(device, bank_definitions, ...):
    if liveobj_valid(device) and isinstance(device, MaxDevice) and device.get_bank_count() > 0:
        return MaxDeviceParameterBank(device, size=8)   # custom banks
    elif bank_definitions.get(device.class_name):
        return DescribedDeviceParameterBank(...)         # built-in device (Operator, etc.)
    else:
        return DeviceParameterBank(device, size=8)       # all-columns fallback
```

**`get_bank_count() > 0` is the gate.** Push calls this once and caches the result. If it returns 0 at call time, Push uses `DeviceParameterBank` (all-columns view) until the user navigates away and back.

### `MaxDeviceParameterBank.bank_index_to_name(index)`

```python
def bank_index_to_name(self, index):
    if self.bank_count == 0:
        return MAIN_KEY   # "Main"
    mx_index = index - int(self._has_main_bank)
    provided_name = self.device.get_bank_name(mx_index)
    if len(provided_name) > 0:
        return provided_name
    return super().bank_index_to_name(index)   # fallback: "Bank %d" % (index + 1)
```

`device.get_bank_name(mx_index)` is a C++ Live API call that returns what `live.banks` stored. If it returns `""` (empty), Push falls back to `"Bank 1"`, `"Bank 2"`, etc.

### `MaxDeviceParameterBank.bank_count`

```python
@property
def bank_count(self):
    return self.device.get_bank_count() + int(self._has_main_bank)
```

### `MaxDeviceParameterBank._has_main_bank`

```python
@property
def _has_main_bank(self):
    return bool(self.device.get_bank_encoder_parameters(MX_MAIN_BANK_INDEX))
```

Returns `True` if any `parameter_enable=1` params are **not** assigned to any custom bank. Those orphaned params form the "main bank" (an extra Push page). **Orphaned params do NOT prevent custom banks from showing** — they just add an extra page. To avoid a main bank, all `parameter_enable=1` params must be assigned to a custom bank slot.

### `BANK_FORMAT = "Bank %d"` (from `banking_util.pyc`)

Default bank name when `get_bank_name()` returns `""`. 1-indexed: bank index 0 → `"Bank 1"`.

---

## Solution: bake the bank into the device at build time (current approach)

**The `get_bank_count() > 0` gate is evaluated once at device-component creation and cached** (see mechanism above). The only way to win it reliably is for the bank to already exist *before any JS runs*. Per the Cycling '74 `live.banks` reference: **"Banks are saved with the device, but can be modified in real-time."** So we bake the bank into the saved `.amxd` and never create it at runtime.

Banks persist in the patcher under **`patcher.parameters.parameterbanks`**. `build_nam_maxpat.py` emits this block (`_build_parameters_block()`), so the device reports `bank_count = 1` the instant Live loads it → Push picks `MaxDeviceParameterBank` on first paint. No race, no navigate-away-and-back.

### Format

`patcher.parameters` is a registry of every parameter object **plus** the bank layout:

```jsonc
"parameters": {
  // one entry per parameter object, keyed by varname: [longname, shortname, modulation_mode]
  "Model0":          ["NAM Model 0", "Model0", 0],
  "ir_blend_dial":   ["IR Dry/Wet",  "IR",     0],
  // ... (49 entries for the NAM device) ...
  "parameterbanks": {
    "0": {
      "index": 0,
      "name": "NAM",
      "parameters": ["NAM Cat", "NAM Model 0", "NAM Dry/Wet", "IR Cat",
                     "IR File 0", "IR Dry/Wet", "Noise Gate Threshold", "Noise Gate On"],
      "buttons": ["-", "-", "-", "-", "-", "-", "-", "-"]
    }
  },
  "inherited_shortname": 1
}
```

- Bank slots reference parameters by **longname**; each must exist in the registry (the builder asserts this).
- `buttons` is the Push 3 button row (8 slots, `-` = unused).
- The registry is **generated from the boxes** at build time, so it can't drift from the actual parameters. Verified byte-identical to what Max itself writes when you define a bank via the editor's Parameter Banks window (double-click `live.banks`) and save.

### Runtime: `edit` only, never `new`

At runtime the JS only ever sends **`edit`** to mutate the baked bank in place — to point the model/IR slot at the current category's shadow menu:

```javascript
// nam_loader.js — on init (init_banks, +10ms) and on every category switch
b.message("edit", bankId, "-", slotIdx, paramName);   // e.g. slot 1 → "NAM Model 3"
```

**Never send `new`.** Bank 0 already exists from the bake; `new 0` *inserts* and pushes the baked bank to index 1, producing a spurious second page (see gotchas). `edit` mutates in place, keeps `bank_count` ≥ 1 throughout, and fires `bank_parameters_changed` (which updates slots without re-evaluating bank type).

> ### ⚠️ Empty `parameterbanks` crashes Live — populated is required
> An **empty** `parameterbanks` dict alongside `parameter_enable=1` objects triggers a NULL-deref in `param_banks_fromdictionary` (crashes Live on load and Max on save — see `KNOWLEDGE_BASE_MAX_INSTRUMENTS.md` §2). The rule is therefore: a device either has **no** top-level `parameters` key at all (no custom Push bank), **or** a `parameters` block whose `parameterbanks` is **non-empty** (custom bank, our case). Never ship an empty one. `build_amxd.py` warns if it sees an all-empty `parameterbanks`; `validate_maxpat.py` fails on it.

---

## Superseded: runtime two-phase `new`/`edit` (historical — do not use)

> Before we discovered banks are saved with the device, the bank was built at runtime: a placeholder `new 0` at `loadbang` to force `bank_count > 0`, then `edit` at +10ms to fill slots. This **lost the race on a cold device add** (Push enumerated before the JS ran → all-columns on first load) and was riddled with timing traps (`new` firing `on_banks_changed`, the ~13-atom `edit` limit, the 30ms race). The build-time bake above replaces it entirely. The traps are retained below only because they explain why **`new` must never be sent at runtime** even now.

- **`new` inserts, never replaces.** `new 0 "NAM" ...` when bank 0 exists pushes the existing bank to index 1. With a baked bank, any `new` produces a duplicate page.
- **`new` after `live.thisdevice` can flash all-columns.** `new` fires `on_banks_changed` → Push re-calls `create_device_bank`; during the transient reset `get_bank_count()` may briefly read 0 → `DeviceParameterBank` fallback. `edit` fires `bank_parameters_changed` instead (no bank-type re-eval), so `edit` is always safe.
- **~13-atom `edit` limit.** A single `edit` with more than ~13 atoms (>5 index/name pairs) could fire `on_banks_changed` instead of `bank_parameters_changed`. Our per-slot `edit` calls are tiny, so this no longer bites — but keep slot edits small.
- **`parameter_enable=0` on navigation/display params** keeps them out of the auto "main bank" so they don't add an extra Push page.
