#!/usr/bin/env bash
set -euo pipefail

STATE_LINK="$HOME/.config/hypr/current-wallpaper"
DEFAULT_WALL="$HOME/Pictures/wallpapers/a_skeleton_standing_on_a_pile_of_skulls.png"

# Wait up to 5 seconds for monitor detection (prevents setting wallpaper before monitors are ready)
for i in $(seq 1 10); do
    count=$(hyprctl monitors -j | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)
    if [[ "$count" -gt 0 ]]; then
        break
    fi
    sleep 0.5
done

# Determine which wallpaper to use
wallpaper="$DEFAULT_WALL"
if [[ -L "$STATE_LINK" ]]; then
    stored="$(readlink -f "$STATE_LINK")"
    if [[ -n "$stored" && -f "$stored" ]]; then
        wallpaper="$stored"
    fi
fi

exec "$HOME/.config/hypr/scripts/set-wallpaper.sh" "$wallpaper"
