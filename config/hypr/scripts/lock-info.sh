#!/usr/bin/env bash
# ~/.config/hypr/scripts/lock-info.sh
#
# Every dynamic string on the hyprlock screen comes from here, so the lock
# config stays declarative and there is one place to fix a broken reading.
#
# Contract: print exactly one line, never block, never exit non-zero. hyprlock
# re-runs these on a timer while the screen is locked -- a hang would freeze
# that label, and stderr would land in the compositor log every tick.

set -uo pipefail
export LC_ALL=C

# Pango markup colours (Rose Pine Moon).
#
# Single '#', not '##'. The doubled form is hyprlang's escape for a literal
# hash inside a *config* value; this output is substituted into the label after
# the config has already been parsed, so it goes straight to Pango. Doubling it
# here would make pango_parse_markup reject the colour and blank the label.
MUTED='#6e6a86'; SUBTLE='#908caa'; TEXT='#e0def4'
LOVE='#eb6f92';  GOLD='#f6c177'; FOAM='#9ccfd8'; PINE='#31748f'; IRIS='#c4a7e7'

span() { printf '<span foreground="%s">%s</span>' "$1" "$2"; }

# --------------------------------------------------------------- greeting --
greet() {
    local h name
    h=$(date +%-H)
    name=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)
    [[ -z $name ]] && name=$USER
    if   (( h < 5  )); then printf 'still up, %s'      "$name"
    elif (( h < 12 )); then printf 'good morning, %s'  "$name"
    elif (( h < 18 )); then printf 'good afternoon, %s' "$name"
    elif (( h < 22 )); then printf 'good evening, %s'  "$name"
    else                    printf 'good night, %s'    "$name"
    fi
}

# ---------------------------------------------------------------- battery --
# Ramps the colour with the charge and swaps in a charging glyph, so the state
# reads at a glance from across the room.
battery() {
    local dir=/sys/class/power_supply/BAT0 cap status icon colour
    [[ -r $dir/capacity ]] || return 0
    cap=$(<"$dir/capacity")
    status=$(<"$dir/status" 2>/dev/null)

    if [[ $status == Charging || $status == "Not charging" ]]; then
        icon=""; colour=$FOAM
    elif   (( cap >= 90 )); then icon=""; colour=$FOAM
    elif (( cap >= 70 )); then icon=""; colour=$FOAM
    elif (( cap >= 45 )); then icon=""; colour=$GOLD
    elif (( cap >= 20 )); then icon=""; colour=$GOLD
    else                        icon=""; colour=$LOVE
    fi
    span "$colour" "$icon  ${cap}%"
}

# ---------------------------------------------------------------- network --
# iwgetid is not installed on this box (wireless_tools is not a dependency of
# anything modern), so `iw dev` is the primary read and nmcli the fallback.
network() {
    local ssid
    ssid=$(iw dev 2>/dev/null | awk '/^\tssid /{ $1=""; sub(/^ /,""); print; exit }')
    [[ -z $ssid ]] && ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null \
                             | awk -F: '$1=="yes"{ print $2; exit }')
    if [[ -n $ssid ]]; then
        span "$FOAM" "󰖩  $ssid"
    elif ip route get 1.1.1.1 >/dev/null 2>&1; then
        span "$FOAM" "󰈀  wired"
    else
        span "$MUTED" "󰖪  offline"
    fi
}

# ----------------------------------------------------------------- uptime --
uptime_short() {
    local secs d h m
    secs=$(cut -d. -f1 /proc/uptime 2>/dev/null)
    [[ -n $secs ]] || return 0
    d=$(( secs / 86400 )); h=$(( secs % 86400 / 3600 )); m=$(( secs % 3600 / 60 ))
    if   (( d > 0 )); then span "$SUBTLE" "󰅐  ${d}d ${h}h"
    elif (( h > 0 )); then span "$SUBTLE" "󰅐  ${h}h ${m}m"
    else                   span "$SUBTLE" "󰅐  ${m}m"
    fi
}

# ------------------------------------------------------------- caps lock --
caps() {
    grep -qs 1 /sys/class/leds/input*::capslock/brightness \
        && span "$LOVE" "  caps lock is on"
}

# ---------------------------------------------------------------- now playing --
# Truncated hard: a long track title would otherwise push the bottom row wider
# than the card and look broken.
player() {
    command -v playerctl >/dev/null 2>&1 || return 0
    [[ $(playerctl status 2>/dev/null) == Playing ]] || return 0
    local line
    line=$(playerctl metadata --format '{{artist}} — {{title}}' 2>/dev/null)
    [[ -z $line ]] && return 0
    (( ${#line} > 46 )) && line="${line:0:45}…"
    span "$IRIS" "󰝚  $line"
}

# ---------------------------------------------------------------- session --
host()   { span "$MUTED" "󰇅  $(hostnamectl hostname 2>/dev/null || cat /etc/hostname)"; }
kernel() { span "$MUTED" "󰣇  $(uname -r)"; }

# Bottom status row, assembled here rather than as three labels so the spacing
# between the segments cannot drift as the strings change length.
statusbar() {
    local sep parts=()
    sep=$(span "$MUTED" "   ·   ")
    for f in battery network uptime_short; do
        local out; out=$("$f")
        [[ -n $out ]] && parts+=("$out")
    done
    local IFS=; printf '%s' "${parts[0]:-}"
    for (( i = 1; i < ${#parts[@]}; i++ )); do printf '%s%s' "$sep" "${parts[i]}"; done
}

case ${1:-statusbar} in
    greet)     greet ;;
    battery)   battery ;;
    network)   network ;;
    uptime)    uptime_short ;;
    caps)      caps ;;
    player)    player ;;
    host)      host ;;
    kernel)    kernel ;;
    statusbar) statusbar ;;
    *)         printf '' ;;
esac
printf '\n'
