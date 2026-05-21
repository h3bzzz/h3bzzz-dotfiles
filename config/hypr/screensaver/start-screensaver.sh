#!/usr/bin/env bash
set -euo pipefail

SCREENSAVER="$HOME/.config/hypr/screensaver/screensaver.sh"
GHOSTTY_SCREENSAVER_CONF="$HOME/.config/hypr/screensaver/ghostty-screensaver.conf"
TEXT="wake up h3bzzz, the Matrix has you..."

# Kill any existing screensaver instances
pkill -f "ghostty --class tte-screensaver" 2>/dev/null || true
sleep 0.5

# Launch a ghostty screensaver on each monitor using workspace-targeted exec
# NOTE: hyprctl dispatch exec is broken in hyprland 0.55.2 Lua mode, use eval instead
for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
	ws=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$m\") | .activeWorkspace.id")
	hyprctl eval "hl.exec_cmd('[workspace $ws] ghostty \
		--class=tte-screensaver \
		--config-file=$GHOSTTY_SCREENSAVER_CONF \
		-e \"$SCREENSAVER\" \"$TEXT\"')"
done
