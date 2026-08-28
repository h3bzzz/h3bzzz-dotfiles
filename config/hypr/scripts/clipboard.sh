#!/usr/bin/env bash
# Clipboard history picker — cliphist through rofi (Rose Pine launcher theme).

set -euo pipefail

theme="$HOME/.config/rofi/launchers/type-3/style-3.rasi"

cliphist list \
    | rofi -dmenu -i -p "Clipboard" -theme "$theme" \
    | cliphist decode \
    | wl-copy
