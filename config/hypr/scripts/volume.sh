#!/usr/bin/env bash

set -euo pipefail

step="${2:-5}"

get_volume() {
	wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100 + 0.5)}'
}

is_muted() {
	wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "\[MUTED\]"
}

send_wob() {
	local value="$1"
	local fifo="/tmp/${HYPRLAND_INSTANCE_SIGNATURE:-}.wob"

	if (( value > 100 )); then
		value=100
	fi

	if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" && -p "$fifo" ]]; then
		printf '%s\n' "$value" > "$fifo"
	fi
}


case "${1:-}" in
	up)
		wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ "${step}%+"
		;;
	down)
		wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%-"
		;;
	mute)
		wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
		;;
	get)
		get_volume
		exit 0
		;;
	*)
		printf 'Usage: %s {up|down|mute|get} [step]\n' "$0" >&2
		exit 1
		;;
esac

if is_muted; then
	send_wob 0
else
	send_wob "$(get_volume)"
fi
