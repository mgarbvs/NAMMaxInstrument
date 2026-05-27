#!/usr/bin/env bash
# build_nam.sh — emit m4l/NAM.maxpat, validate, assemble m4l/NAM.amxd.
set -euo pipefail
cd "$(dirname "$0")"

python3 scripts/build_nam_maxpat.py m4l/NAM.maxpat
python3 scripts/validate_maxpat.py m4l/NAM.maxpat
python3 scripts/build_amxd.py m4l/NAM.maxpat m4l/NAM.amxd
