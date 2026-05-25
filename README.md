# NAM Max for Live

A [Neural Amp Modeler](https://github.com/sdatkinson/NeuralAmpModelerPlugin) instrument for Ableton Live, built as a Max for Live device. Loads `.nam` amp models and cabinet IR files directly in Live — no VST or AU required.

**Platform:** macOS (Apple Silicon + Intel universal). Windows builds are not yet available.

## Signal chain

```
Input gain → Noise gate → NAM model → FMV tone stack → IR convolution → Output gain
```

Three collapsible sections: **NAM Amp Head** | **Gate + Tone Stack** | **IR Cabinet**

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

See **[docs/guide.html](docs/guide.html)** for a full walkthrough of every control.

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
