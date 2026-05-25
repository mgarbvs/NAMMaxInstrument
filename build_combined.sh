#!/usr/bin/env bash
# build_combined.sh — emit m4l/COMBINED.maxpat, validate, assemble m4l/COMBINED.amxd.
set -euo pipefail
cd "$(dirname "$0")"

python3 scripts/build_combined_maxpat.py m4l/COMBINED.maxpat
python3 scripts/validate_maxpat.py m4l/COMBINED.maxpat
python3 scripts/build_amxd.py m4l/COMBINED.maxpat m4l/COMBINED.amxd
