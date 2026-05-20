#!/usr/bin/env bash
set -euo pipefail

STATE_LINK="$HOME/.config/hypr/current-wallpaper"
CONF="$HOME/.config/hypr/hyprpaper.conf"

if [[ $# -lt 1 ]]; then
	printf 'Usage: %s /absolute/path/to/wallpaper\n' "$0" >&2
	exit 1
fi

wallpaper="$1"

if [[ "$wallpaper" != /* ]]; then
	wallpaper="$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$wallpaper")"
fi

if [[ ! -f "$wallpaper" ]]; then
	printf 'Wallpaper not found: %s\n' "$wallpaper" >&2
	exit 1
fi

# Ensure hyprpaper is running; start it if not
if ! pgrep -x hyprpaper >/dev/null 2>&1; then
	hyprpaper >/dev/null 2>&1 &
	sleep 1
fi

# Get monitor names for IPC commands (use raw name, not desc: prefix)
mapfile -t monitors < <(hyprctl monitors -j | python3 -c "
import sys, json
for m in json.load(sys.stdin):
    print(m['name'])
")

# Set wallpaper on all monitors via IPC (single command handles preload + set)
for mon in "${monitors[@]}"; do
	hyprctl hyprpaper wallpaper "$mon,$wallpaper,cover" 2>/dev/null || true
done

# Update state symlink
ln -sfn "$wallpaper" "$STATE_LINK"

# Get monitor identifiers with desc: prefix for boot-stable config
mapfile -t monitors_cfg < <(hyprctl monitors -j | python3 -c "
import sys, json
for m in json.load(sys.stdin):
    desc = m.get('description', '')
    if desc:
        print(f'desc:{desc}')
    else:
        print(m['name'])
")

# Rewrite hyprpaper.conf for persistence across hyprland restarts
{
	echo "preload = $wallpaper"
	for mon in "${monitors_cfg[@]}"; do
		echo "wallpaper = $mon,$wallpaper"
	done
	echo "splash = false"
	echo "ipc = true"
} > "$CONF"

if command -v notify-send >/dev/null 2>&1; then
	notify-send "Wallpaper changed" "$(basename "$wallpaper")"
fi
