#!/usr/bin/env bash

set -euo pipefail

step="${2:-5}"

get_brightness() {
    brightnessctl -m | awk -F, '{gsub("%", "", $4); print $4}'
}

send_wob() {
    local value="$1"
    local fifo="/tmp/${HYPRLAND_INSTANCE_SIGNATURE:-}.wob"

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" && -p "$fifo" ]]; then
        printf '%s\n' "$value" > "$fifo"
    fi
}

case "${1:-}" in
    up)
        brightnessctl set "${step}%+" >/dev/null
        send_wob "$(get_brightness)"
        ;;
    down)
        brightnessctl set "${step}%-" >/dev/null
        send_wob "$(get_brightness)"
        ;;
    get)
        get_brightness
        ;;
    *)
        printf 'Usage: %s {up|down|get} [step]\n' "$0" >&2
        exit 1
        ;;
esac
