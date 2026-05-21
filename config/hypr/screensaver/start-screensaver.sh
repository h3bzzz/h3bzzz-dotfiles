#!/usr/bin/env bash
set -euo pipefail

SCREENSAVER="$HOME/.config/hypr/screensaver/screensaver.sh"
TEXT="wake up h3bzzz, the Matrix has you..."

# Kill any existing screensaver instances
pkill -f "kitty --class tte-screensaver" 2>/dev/null || true
sleep 0.5

# Launch a kitty screensaver on each monitor using workspace-targeted exec
# NOTE: hyprctl dispatch exec is broken in hyprland 0.55.2 Lua mode, use eval instead
for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
	ws=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$m\") | .activeWorkspace.id")
	hyprctl eval "hl.exec_cmd('[workspace $ws] kitty --class tte-screensaver \
		--start-as=fullscreen \
		--override background_opacity=1 \
		--override confirm_os_window_close=0 \
		--override font_size=36 \
		--override window_padding_width=0 \
		-e \"$SCREENSAVER\" \"$TEXT\"')"
done
