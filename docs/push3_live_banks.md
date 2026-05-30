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

## Two-phase initialization pattern

**Problem:** Push calls `create_device_bank` before or shortly after `loadbang`. At `loadbang`, Live hasn't yet registered device parameters, so `live.banks new` can create structure but the name may not be persisted via the parameter hub. At 0ms after `live.thisdevice`, `new` is still silently ignored. At 10ms, params are registered and `new`/`edit` work fully.

**Solution:**

```
loadbang  → live.banks new (empty bank structure, bank_count > 0)
             → Push picks MaxDeviceParameterBank ✓

live.thisdevice → delay 10ms → init()
             → live.banks edit (real params + real name, one call per bank)
             → fires bank_parameters_changed → Push updates display ✓
```

**`new` at loadbang** — minimal placeholder only:
- `b.message("new", 0, "NAM", "NAM Cat", "NAM Model 0")` — bank count goes to 1
- Keep the `new` call as short as possible. Do NOT include all desired slots here — only what's needed to ensure count > 0. Adding extra registered-param names (e.g. "NAM Dry/Wet") to the `new` call at loadbang can shift the timing of the 30ms `on_banks_changed` race and break first-load.

**`edit` at 10ms** (params registered) — put ALL real slot assignments here. For 6+ slots, split across two calls to stay under the ~13-atom-per-call limit:
```javascript
// First call: real bank name + slots 0–4 (≤13 atoms total — safe)
b.message("edit", 0, "NAM", 0, "NAM Cat", 1, "NAM Model " + catIdx, 2, "NAM Dry/Wet", 3, "IR Cat", 4, "IR File " + irIdx);
// Second call: "-" preserves bank name + remaining slots (also safe)
b.message("edit", 0, "-",   5, "IR Dry/Wet", 6, "Noise Gate Threshold", 7, "Noise Gate On");
```
- First call sets bank name; second uses `"-"` to avoid the "real name in two calls" problem
- Each call fires one `bank_parameters_changed` — two rapid events is fine
- Do NOT exceed ~13 atoms in a single `edit` call — larger calls fire `on_banks_changed` instead

**Subsequent slot updates** (e.g. on category switch):
```javascript
b.message("edit", bankId, "-", slotIdx, paramName);
```
- Uses `-` to preserve existing bank name
- Only updates the one changed slot

---

## Key gotchas

- **`new` inserts, never replaces.** Calling `new 0 "NAM" ...` when bank 0 already exists pushes the existing bank to index 1. Don't call `new` for the same bank twice.
- **Only `new 0` works at loadbang.** `new 1 "IR" ...` silently fails (`cannot edit missing bank 1` appears later). `new 0` can be called multiple times at loadbang — each call inserts at index 0 and shifts existing banks up. Use this to pre-create all banks: `new 0 "IR" ...` then `new 0 "NAM" ...` gives bank 0=NAM, bank 1=IR, count=2.
- **Never call `new` after live.thisdevice.** `new` fires `on_banks_changed`, which causes Push to re-call `create_device_bank`. During the transient reset inside `new`, `get_bank_count()` may briefly return 0, causing Push to fall back to `DeviceParameterBank` (all-columns). After loadbang, use only `edit` — it fires `bank_parameters_changed` instead, which only updates the parameter list without re-evaluating bank type.
- **Never create a second bank with `new` after live.thisdevice, even in a delayed tick.** The `on_banks_changed` race exists whenever `new` is called after loadbang, regardless of how long after. The only safe pattern is a single bank (bank 0) with all desired slots, populated entirely via `edit` at 10ms.
- **`edit` with a real name vs `-`:** When `_populateBanks()` runs at 10ms, the bank name from the loadbang `new` call may be empty (parameter hub not yet connected). Use `edit bank_id "RealName" ...` to set it properly. Use `-` in subsequent per-slot updates to preserve the already-set name.
- **Using a real name in two separate `edit` calls breaks banks.** Combine into one call — but see the atom-count limit below.
- **`edit` atom-count limit: max ~13 atoms per call.** A single `edit` call with more than ~13 atoms (i.e., more than 5 index-based slot pairs) appears to fire `on_banks_changed` instead of `bank_parameters_changed`, causing the same all-columns regression as a `new` call. The safe pattern for 6+ slots is to split across two calls: the first sets slots 0–4 with the real bank name, the second sets the remaining slots using `"-"` to preserve the name:
  ```javascript
  b.message("edit", 0, "NAM", 0, "NAM Cat", 1, "NAM Model 0", 2, "NAM Dry/Wet", 3, "IR Cat", 4, "IR File 0");
  b.message("edit", 0, "-",   5, "IR Dry/Wet", 6, "Noise Gate Threshold", 7, "Noise Gate On");
  ```
  Each call fires `bank_parameters_changed` once. Using `"-"` in the second call avoids the "real name in two calls" issue.
- **Keep `new` at loadbang minimal.** Only include 1–2 placeholder slot names. Do not include all desired slots — put those in the `edit` at 10ms. Extra params in the loadbang `new` call (especially registered params like `live.dial`/`live.toggle` long names) can disrupt the 30ms `on_banks_changed` timing and cause all-columns on first load.
- **`parameter_enable=0` on navigation/display params** prevents them from creating an unwanted main bank page on Push.
