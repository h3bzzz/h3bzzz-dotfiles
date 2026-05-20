#!/usr/bin/env bash
set -euo pipefail

STATE_LINK="$HOME/.config/hypr/current-wallpaper"
DEFAULT_WALL="$HOME/Pictures/wallpapers/a_skeleton_standing_on_a_pile_of_skulls.png"

if [[ -L "$STATE_LINK" ]]; then
    wallpaper="$(readlink -f "$STATE_LINK")"
    if [[ -n "$wallpaper" && -f "$wallpaper" ]]; then
        exec "$HOME/.config/hypr/scripts/set-wallpaper.sh" "$wallpaper"
    fi
fi

exec "$HOME/.config/hypr/scripts/set-wallpaper.sh" "$DEFAULT_WALL"
