#!/usr/bin/env bash

set -euo pipefail

if hyprctl devices -j | python3 -c "
import sys, json
devices = json.load(sys.stdin)
for kb in devices.get('keyboards', []):
    if kb.get('caps_lock', False):
        sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
	echo "caps lock"
fi
