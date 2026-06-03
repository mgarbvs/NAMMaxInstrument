> **⚠️ SUPERSEDED (see `docs/push3_live_banks.md`).** The runtime-`new` plan below was
> built and shipped the all-columns-on-first-load bug. The corrected approach **bakes the
> bank into `patcher.parameters.parameterbanks` at build time** (`build_nam_maxpat.py`) so
> the device loads with `bank_count = 1`; the JS only ever sends `edit`, never `new`. The
> claim below that "no pre-populated parameterbanks JSON was found / bank count is 0 on
> fresh load" was **wrong** — banks *are* saved with the device. Kept for history only.

Format verified from the live.banks help patcher. Here's exactly what's confirmed:

**`new` message:** `new <bank_id> <name> param1 param2 param3 ...` (up to 8 positional param shortnames, `-` for empty slot)
- Example: `new 0 slartybank bar foo enum`

**`edit` message (slot/name pairs):** `edit <bank_id> <name_or_dash> <slot_idx> <param_name> [<slot_idx> <param_name> ...]`
- Example: `edit 1 newestbank 0 foo 2 bar 4 enum`
- Use `-` as name to keep existing
- Only specifies slots you're changing (sparse)

**Critical note:** *"after adding a new parameter object to a device, you need to save the device before the parameter is available for mapping with live.banks."* — so all per-category parameters must be in the saved amxd before banks can reference them. ✓ (our build script bakes them in)

~~**No pre-populated `parameterbanks` JSON found** in any device — banks are created at runtime via `new`, then saved to the Live Set. On fresh amxd load, bank count is 0, so we use `new`; thereafter `edit` for swaps.~~ — **FALSE.** Banks *are* saved with the device in `patcher.parameters.parameterbanks` (verified against `ConvolutionReverb_reference.maxpat` and confirmed by the Cycling '74 `live.banks` reference). We now bake the bank at build time; runtime `new` is never used.

**Full plan:**

| What               | How                                                                                                                                                                                                    |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Build script       | One shadow `live.menu` per NAM category (shortname `Model0`…`Model13`) + one per IR category (`IRFile0`…`IRFile4`), each with its category's files baked as `parameter_enum`. Add `live.banks` object. |
| Loadbang           | Delay → `getcount` → if 0: `new 0 NAM NamCat Model0 - - - - - -` + `new 1 IR IRCat IRFile0 - - - - - -`                                                                                                |
| Category change    | `edit 0 - 1 Model{catIdx}` → Push immediately shows the new parameter with its baked enum                                                                                                              |
| Clamping observers | One per per-category param, each clamping to its own file count                                                                                                                                        |

Want me to implement this now?
