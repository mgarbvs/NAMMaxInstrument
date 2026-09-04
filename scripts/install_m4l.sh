#!/usr/bin/env bash
# Installs m4l/'s contents as one unit into Ableton's User Library.
#
# NAM.amxd's .mxo externals, nam_loader.js, and eq_curve.jsui only resolve
# when they sit next to the .amxd in a folder Max always searches. Running
# NAM.amxd straight from this repo (or from an Instrument Rack preset that
# copies just the .amxd elsewhere) leaves those siblings behind — see
# README.md "Installation". This script does the copy correctly every time.
set -euo pipefail

DEST="${1:-$HOME/Music/Ableton/User Library/Presets/Audio Effects/Max Audio Effect}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../m4l" && pwd)"

mkdir -p "$DEST"
rsync -a --exclude 'Ableton Folder Info' --exclude '.DS_Store' "$SRC/" "$DEST/"
echo "Installed $SRC -> $DEST"
