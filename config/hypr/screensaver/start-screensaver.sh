#!/usr/bin/env bash
LOG="/tmp/screensaver.log"

echo "=== $(date) starting ===" >> "$LOG"

SCREENSAVER="$HOME/.config/hypr/screensaver/screensaver.sh"
GHOSTTY_SCREENSAVER_CONF="$HOME/.config/hypr/screensaver/ghostty-screensaver.conf"
TEXT="wake up h3bzzz, the Matrix has you..."

echo "killing old screensavers..." >> "$LOG"
pkill -f "com\\.tte\\.screensaver" 2>/dev/null || true
sleep 0.5

echo "getting monitors..." >> "$LOG"
mapfile -t monitors < <(hyprctl monitors -j 2>/dev/null | jq -r '.[] | .name' 2>/dev/null)
echo "monitors: ${monitors[*]}" >> "$LOG"

if [ ${#monitors[@]} -eq 0 ]; then
    echo "no monitors found, falling back to DP-3, HDMI-A-1" >> "$LOG"
    monitors=("DP-3" "HDMI-A-1")
fi

for m in "${monitors[@]}"; do
    safe="${m//[^a-zA-Z0-9]/-}"
    class="com.tte.screensaver.${safe}"
    echo "launching on $m with class $class" >> "$LOG"
    nohup ghostty \
        --class="${class}" \
        --config-file="${GHOSTTY_SCREENSAVER_CONF}" \
        -e "${SCREENSAVER}" "${TEXT}" \
        >/dev/null 2>&1 &
    echo "launched pid $!" >> "$LOG"
done

echo "=== done ===" >> "$LOG"
