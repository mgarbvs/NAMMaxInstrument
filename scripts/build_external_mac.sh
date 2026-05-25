#!/usr/bin/env bash
# build_external_mac.sh — configure and build the Max externals on macOS.
# Produces .mxo bundles in m4l/ (co-located with NAM.amxd so Max's default
# patcher-directory search resolves them). Defaults to arm64-only for fast
# iteration; pass ARCHS=x86_64\;arm64 to produce a universal binary.
#
# Ad-hoc codesigning is applied after build so Live (a signed app subject to
# Gatekeeper / runtime hardening) will load the externals without a "cannot be
# loaded due to system security policy" rejection. Real release builds need
# Developer ID + notarization (PLAN §9 M9, scripts/codesign_notarize.sh).

set -euo pipefail
cd "$(dirname "$0")/.."

SRC="external_src"
BUILD="$SRC/build"
ARCHS="${ARCHS:-arm64}"

if [[ ! -d "$SRC/max-sdk/source" ]]; then
    echo "ERROR: max-sdk submodule missing at $SRC/max-sdk/." >&2
    echo "       See $SRC/thirdparty/README.md for setup." >&2
    exit 1
fi

mkdir -p "$BUILD"
cmake -S "$SRC" -B "$BUILD" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS"
cmake --build "$BUILD" -j "$(sysctl -n hw.ncpu)"

# Ad-hoc sign + clear quarantine so Live loads them.
for mxo in m4l/*.mxo; do
    [[ -e "$mxo" ]] || continue
    xattr -dr com.apple.quarantine "$mxo" 2>/dev/null || true
    codesign --force --deep --sign - "$mxo"
done

echo
echo "Built externals to m4l/:"
ls -1 m4l/*.mxo 2>/dev/null | xargs -n1 basename
