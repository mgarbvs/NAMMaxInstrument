# NAM Max for Live

A [Neural Amp Modeler](https://github.com/sdatkinson/NeuralAmpModelerPlugin) instrument for Ableton Live, built as a Max for Live device. Loads `.nam` amp models and cabinet IR files directly in Live — no VST or AU required.

<img width="974" height="187" alt="image" src="https://github.com/user-attachments/assets/ca278628-fd3f-4ce7-a1bb-3809ddfa821c" />


**Platform:** macOS (Apple Silicon + Intel universal). Windows builds are not yet available.

## Signal chain

```
Input gain → Noise gate → NAM model → 3-band EQ → IR convolution → Output gain
```

Three collapsible sections: **NAM Amp Head** | **Gate + Tone Stack** | **IR Cabinet**

NAM Amp Head:

<img width="331" height="189" alt="image" src="https://github.com/user-attachments/assets/7822611c-e28c-46b6-88d9-88f888ac1d36" />

Gate / Tone Stack:

<img width="648" height="186" alt="image" src="https://github.com/user-attachments/assets/34ffb82d-ce83-4273-a7a8-866149194488" />

IR:

<img width="648" height="184" alt="image" src="https://github.com/user-attachments/assets/586db3c6-d867-48de-823d-b8d38c4004e7" />


All together:

<img width="976" height="189" alt="image" src="https://github.com/user-attachments/assets/6c328f80-52a8-4d5b-9dd4-cc336c7ceaa9" />


## Requirements

- Ableton Live 11 or later with Max for Live
- macOS 11 or later
- NAM model files (`.nam`) — download free models from [Tone3000](https://tone3000.org)
- Cabinet IR files (`.wav`) — optional; the IR section can be bypassed

## Installation

All files in `m4l/` must stay together in the same directory — Max for Live loads the `.mxo` externals from the same folder as the `.amxd`.

Copy the contents of `m4l/` to your Ableton User Library:

```
~/Music/Ableton/User Library/Presets/Audio Effects/Max Audio Effect/
```

Then drag **NAM.amxd** onto an audio track in Live.

## First use

1. **Set NAM Root** — click the button in the NAM section and choose the folder containing your `.nam` files (subfolders are scanned automatically).
2. **Set IR Root** — click the button in the IR section and choose the folder containing your `.wav` IR files.
3. Use the category and file menus to browse and load models.

The device saves your root folders and last selection across sessions.

## Controls at a glance

**NAM Amp Head** (always visible)
| Control | What it does |
|---|---|
| Set NAM Root | Choose your `.nam` library folder; subfolders become categories |
| Category / File menus | Browse and load models; `<` `>` arrows step through them |
| Drag & drop | Drop a `.nam` file onto the grill to load it directly |
| Input (fader) | Gain before NAM — more = more saturation |
| NAM Out (fader) | Output level after NAM, before tone and IR |
| Bypass | Hard-bypasses the whole device with PDC-matched latency compensation |
| Tone / IR toggles | Collapse or expand the Tone Stack and IR Cabinet panels |

**Gate + Tone Stack** (collapsible)
| Control | What it does |
|---|---|
| NAM dial | Dry/wet blend between the raw input and NAM output (default 100% wet) |
| Gate dial | Noise gate threshold, −70 to 0 dB; raise until hiss disappears between notes |
| Gate off / on | Hard-bypass the gate |
| Bass · Mid · Treble | 3-band biquad EQ (same as NAM plugin): low shelf 150 Hz ±20 dB · peaking 425 Hz ±15 dB · high shelf 1800 Hz ±10 dB; knob 5 = flat |
| EQ curve display | Live frequency response of the current Bass/Mid/Treble setting |
| Tone off / on | Hard-bypass the tone stack |

**IR Cabinet** (collapsible)
| Control | What it does |
|---|---|
| Set IR Root | Choose your `.wav` IR library folder |
| Category / File menus | Browse and load IRs; `<` `>` arrows step through them |
| Drag & drop | Drop a `.wav` onto the waveform display to load it directly |
| Duration display | Shows IR length in seconds |
| IR dial | Dry/wet blend between pre-IR signal and convolved output |
| IR off / on | Hard-bypass IR convolution |

See **[docs/guide.html](docs/guide.html)** for the full guide, including tone stack tips and workflow advice.

## Building from source

See **[BUILDING.md](BUILDING.md)**.

## Third-party licenses

| Library | License |
|---|---|
| [NeuralAmpModelerCore](https://github.com/sdatkinson/NeuralAmpModelerCore) | MIT |
| [HISSTools_Library](https://github.com/AlexHarker/HISSTools_Library) | BSD-3-Clause |
| [Eigen](https://eigen.tuxfamily.org) | MPL-2.0 (header-only) |
| [nlohmann/json](https://github.com/nlohmann/json) | MIT |
| [Cycling '74 Max SDK](https://github.com/Cycling74/max-sdk) | MIT |

## License

MIT — see [LICENSE](LICENSE).
