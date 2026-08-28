#!/usr/bin/env bash

set -euo pipefail

dir="$HOME/.config/rofi/launchers/type-3"

rofi \
    -show drun \
    -theme "$dir/style-3.rasi"
