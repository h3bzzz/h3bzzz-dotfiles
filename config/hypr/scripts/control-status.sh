#!/usr/bin/env bash
# One JSON object describing everything the quickshell control centre shows.
# Polled every couple of seconds while the panel is open, so it stays cheap:
# no long-running children, CPU usage from a /proc/stat delta kept in
# $XDG_RUNTIME_DIR between calls.

set -uo pipefail

S="$HOME/.config/hypr/scripts"
RUN="${XDG_RUNTIME_DIR:-/tmp}"

# --- cpu ---------------------------------------------------------------
read -r _ u n s i w q sq st _ </proc/stat
total=$((u + n + s + i + w + q + sq + st))
idle=$((i + w))
cpu=0
if [[ -r $RUN/rice-cpu ]]; then
    read -r ptotal pidle <"$RUN/rice-cpu"
    dt=$((total - ptotal))
    ((dt > 0)) && cpu=$((100 * (dt - (idle - pidle)) / dt))
fi
printf '%s %s\n' "$total" "$idle" >"$RUN/rice-cpu"

# --- memory / disk / battery -------------------------------------------
mem=$(awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {printf "%d", (t-a)*100/t}' /proc/meminfo)
disk=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9')
bat=-1
charging=false
for b in /sys/class/power_supply/BAT*; do
    [[ -r $b/capacity ]] || continue
    bat=$(<"$b/capacity")
    [[ $(<"$b/status") == Charging ]] && charging=true
    break
done

# --- volume / brightness -----------------------------------------------
vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
vol=$(awk '{printf "%d", $2*100}' <<<"$vol_raw")
muted=false
[[ $vol_raw == *MUTED* ]] && muted=true
bri=-1
if command -v brightnessctl >/dev/null 2>&1 && [[ -n $(brightnessctl -l -c backlight 2>/dev/null) ]]; then
    bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -dc '0-9')
fi

# --- radios -------------------------------------------------------------
wifi=na
ssid=""
if command -v nmcli >/dev/null 2>&1; then
    [[ $(nmcli -t radio wifi 2>/dev/null) == enabled ]] && wifi=on || wifi=off
    ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes" {print $2; exit}')
fi
bt=na
if command -v bluetoothctl >/dev/null 2>&1 && systemctl is-active --quiet bluetooth 2>/dev/null; then
    bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && bt=on || bt=off
fi

# --- compositor-side toggles ----------------------------------------------
lua=$(hyprctl eval 'return (Rice and Rice.game_mode and "on" or "off") .. " " .. (Rice and Rice.eye_candy and "on" or "off")' 2>/dev/null | head -1)
read -r game candy <<<"$lua"
[[ $game == on ]] || game=off
[[ $candy == on ]] || candy=off

# --- media ---------------------------------------------------------------
title=$(playerctl metadata title 2>/dev/null | head -1)
artist=$(playerctl metadata artist 2>/dev/null | head -1)
playing=false
[[ $(playerctl status 2>/dev/null) == Playing ]] && playing=true

python3 - "$cpu" "$mem" "${disk:-0}" "$bat" "$charging" "${vol:-0}" "$muted" "$bri" \
    "$wifi" "$ssid" "$bt" "$("$S/toggle.sh" status nightlight)" "$("$S/toggle.sh" status idle)" \
    "$("$S/toggle.sh" status dnd)" "$("$S/toggle.sh" status power)" "$game" "$candy" \
    "$title" "$artist" "$playing" <<'PY'
import json, sys
a = sys.argv[1:]
num = lambda v: int(v) if v.lstrip("-").isdigit() else 0
print(json.dumps({
    "cpu": num(a[0]), "mem": num(a[1]), "disk": num(a[2]),
    "battery": num(a[3]), "charging": a[4] == "true",
    "volume": num(a[5]), "muted": a[6] == "true", "brightness": num(a[7]),
    "wifi": a[8], "ssid": a[9], "bluetooth": a[10],
    "nightlight": a[11], "caffeine": a[12], "dnd": a[13], "power": a[14],
    "game": a[15], "candy": a[16],
    "title": a[17], "artist": a[18], "playing": a[19] == "true",
}))
PY
