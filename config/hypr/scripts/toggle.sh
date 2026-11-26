#!/usr/bin/env bash
# Session toggles that live outside the compositor. Each one reports its new
# state with a notification so a keybind never leaves you guessing.
#
#   toggle.sh nightlight   blue-light filter on/off (hyprsunset)
#   toggle.sh idle         caffeine: stop/start hypridle (no dim, saver, lock)
#   toggle.sh power        cycle power-saver -> balanced -> performance
#   toggle.sh dnd          swaync do-not-disturb
#   toggle.sh wifi         Wi-Fi radio (NetworkManager)
#   toggle.sh bluetooth    Bluetooth adapter power
#   toggle.sh status NAME  print on/off (or the profile name) for a bar/menu

set -uo pipefail

say() { notify-send -a toggle -t 2500 "$@"; }
NIGHT_TEMP="${NIGHT_TEMP:-4000}"
NIGHT_FLAG="${XDG_RUNTIME_DIR:-/tmp}/rice-nightlight-on"

# Ask hyprsunset what it is doing right now, so the 20:00 profile in
# hyprsunset.conf and this toggle agree. The flag file is only the fallback
# for a hyprsunset that does not answer the query.
night_on() {
    local cur
    cur=$(hyprctl hyprsunset temperature 2>/dev/null)
    if [[ $cur =~ ^[0-9]+$ ]]; then
        ((cur < 6000))
    else
        [[ -f $NIGHT_FLAG ]]
    fi
}

state() {
    case "$1" in
        nightlight) night_on && echo on || echo off ;;
        idle)       pgrep -x hypridle >/dev/null && echo off || echo on ;;
        power)      powerprofilesctl get 2>/dev/null || echo unknown ;;
        dnd)        [[ $(swaync-client -D 2>/dev/null) == true ]] && echo on || echo off ;;
    esac
}

case "${1:-}" in
    nightlight)
        if ! command -v hyprsunset >/dev/null 2>&1; then
            say "Night light" "hyprsunset is not installed (sudo pacman -S hyprsunset)"
            exit 1
        fi
        pgrep -x hyprsunset >/dev/null || { hyprsunset >/dev/null 2>&1 & sleep 0.4; }
        if night_on; then
            hyprctl hyprsunset identity >/dev/null
            rm -f "$NIGHT_FLAG"
            say "Night light" "Off"
        else
            hyprctl hyprsunset temperature "$NIGHT_TEMP" >/dev/null
            : >"$NIGHT_FLAG"
            say "Night light" "On (${NIGHT_TEMP}K)"
        fi
        ;;
    idle)
        if pgrep -x hypridle >/dev/null; then
            pkill -x hypridle
            say "Caffeine" "On -- the screen will not dim, save or lock"
        else
            hypridle >/dev/null 2>&1 &
            disown
            say "Caffeine" "Off -- idle timers are back"
        fi
        ;;
    power)
        case "$(powerprofilesctl get 2>/dev/null)" in
            power-saver) next=balanced ;;
            balanced)    next=performance ;;
            *)           next=power-saver ;;
        esac
        # Not every machine offers `performance`; fall through to the next one.
        powerprofilesctl set "$next" 2>/dev/null || { next=power-saver; powerprofilesctl set "$next"; }
        say "Power profile" "$next"
        ;;
    dnd)
        swaync-client -d -sw >/dev/null
        say "Do not disturb" "$(state dnd)"
        ;;
    wifi)
        if [[ $(nmcli -t radio wifi 2>/dev/null) == enabled ]]; then
            nmcli radio wifi off && say "Wi-Fi" "Off"
        else
            nmcli radio wifi on && say "Wi-Fi" "On"
        fi
        ;;
    bluetooth)
        if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
            bluetoothctl power off >/dev/null && say "Bluetooth" "Off"
        else
            bluetoothctl power on >/dev/null && say "Bluetooth" "On"
        fi
        ;;
    status)
        state "${2:-}"
        ;;
    *)
        echo "usage: toggle.sh nightlight|idle|power|dnd|wifi|bluetooth|status NAME" >&2
        exit 2
        ;;
esac
