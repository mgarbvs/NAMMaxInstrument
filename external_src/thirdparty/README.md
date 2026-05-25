# external_src/thirdparty — submodule setup

The native externals (`nam~`, `namtone~`, `namgate_trigger~`, `namgate_gain~`) link against three external libraries plus the Cycling '74 Max SDK. None of these are vendored — clone or fetch them into the paths below before building.

## Required

### max-sdk

```
git clone https://github.com/Cycling74/max-sdk.git ../max-sdk
```

CMake expects it at `external_src/max-sdk/`. The CMakeLists hard-fails early with a pointer back here if missing.

### NeuralAmpModelerCore

```
git clone https://github.com/sdatkinson/NeuralAmpModelerCore.git NeuralAmpModelerCore
cd NeuralAmpModelerCore
git checkout <pinned-tag>
git rev-parse HEAD > PINNED_COMMIT.txt
```

Pin to a tagged release commit, not `main` — the NAM core ABI is not stable (PLAN.md §9). Record the chosen hash in `external_src/thirdparty/NeuralAmpModelerCore/PINNED_COMMIT.txt`.

### Eigen

Header-only. Either:
- `git clone https://gitlab.com/libeigen/eigen.git eigen` (or use a release tarball)
- or let CMake fetch it (M5 work — for now CMake just expects `eigen/Eigen/` to be present)

### nlohmann/json

Single-header. Download:
```
mkdir -p nlohmann_json
curl -L -o nlohmann_json/json.hpp \
    https://github.com/nlohmann/json/releases/latest/download/json.hpp
```

## Build

```
cd external_src
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j
```

macOS universal binaries are produced automatically (CMakeLists sets `CMAKE_OSX_ARCHITECTURES="x86_64;arm64"` when not overridden). Output lands in `m4l/externals/`.

## Eigen alignment escape hatch

NAM core's README documents an Eigen alignment crash that can occur inside Max's allocator. CMake exposes the escape hatch as an option (PLAN.md §3):

```
cmake .. -DNAM_DISABLE_EIGEN_VECTORIZE=ON
```

This sets `EIGEN_MAX_ALIGN_BYTES=0` and `EIGEN_DONT_VECTORIZE`. Try without first; only enable if Max crashes on model load.

### HISSTools_Library

HISSTools is Alex Harker's BSD-3-clause DSP library. It provides the partitioned
FFT convolution engine (`HISSTools::MonoConvolve`) that underlies Ableton's
bundled `multiconvolve~.mxo`. We build the same engine from source for `irconv~`
so it is redistributable under the same permissive license.

```
git clone https://github.com/AlexHarker/HISSTools_Library.git HISSTools_Library
cd HISSTools_Library
git checkout <pinned-commit>
git rev-parse HEAD > PINNED_COMMIT.txt
```

Pin to a stable commit, not `main`. Record the hash in
`external_src/thirdparty/HISSTools_Library/PINNED_COMMIT.txt`.

**License:** BSD-3-clause — fine to redistribute the built binary. See
`HISSTools_Library/LICENSE`.

**Note:** On macOS the HISSTools FFT engine may use the Accelerate framework
(`vDSP`). CMakeLists.txt links `-framework Accelerate` for the `irconv~` target
when HISSTools is present.

## Notarization (release builds)

After building on macOS, sign with a Developer ID and notarize via `notarytool`. Pattern is in `../../scripts/codesign_notarize.sh` (M9 deliverable — not yet written).
