#!/usr/bin/env bash

pkill -f "kitty --class tte-screensaver"

SCREENSAVER="$HOME/.config/hypr/screensaver/screensaver.sh"
TEXT="wake up h3bzzz, the Matrix has you..."

for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
	hyprctl dispatch focusmonitor "$m"
	kitty --class tte-screensaver \
		--start-as=fullscreen \
		--override background_opacity=1 \
		--override confirm_os_window_close=0 \
		--override font_size=36 \
		--override window_padding_width=0 \
		-e "$SCREENSAVER" "$TEXT"
done
