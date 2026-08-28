#!/usr/bin/env bash
# Region screenshot -> satty annotation editor -> clipboard + saved file.

set -euo pipefail

dir="$HOME/Pictures/screenshots"
mkdir -p "$dir"

out="$dir/satty-$(date +%Y%m%d-%H%M%S).png"

geom="$(slurp)" || exit 0   # user cancelled selection

grim -g "$geom" - \
    | satty --filename - \
            --output-filename "$out" \
            --copy-command wl-copy \
            --early-exit
