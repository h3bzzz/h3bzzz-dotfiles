#!/usr/bin/env bash
set -euo pipefail

# Rose Pine colors (used by wofi css)
BG="#191724"
FG="#e0def4"
ACCENT="#d7827e"
HIGHLIGHT="#31748f"

options=$(
cat <<EOF
⏻  Shutdown
  Reboot
⏾  Suspend
󰌾  Lock
󰍃  Logout
EOF
)

chosen=$(echo "$options" | wofi \
    --dmenu \
    --prompt "Power" \
    --width 260 \
    --lines 5 \
    --style "$HOME/.config/wofi/power-menu.css" \
    --conf "$HOME/.config/wofi/power-menu.config"
)

# Exit cleanly if user cancels
[[ -z "$chosen" ]] && exit 0

case "$chosen" in
    *Shutdown)
        if hyprshutdown --help >/dev/null 2>&1; then
            hyprshutdown -t 'Shutting down...See ya!' --post-cmd 'shutdown -P 0'
        else
            systemctl poweroff
        fi
        ;;
    *Reboot)
        if hyprshutdown --help >/dev/null 2>&1; then
            hyprshutdown -t 'Restarting...Give me a sec' --post-cmd 'reboot'
        else
            systemctl reboot
        fi
        ;;
    *Suspend)
        systemctl suspend
        ;;
    *Lock)
        hyprlock
        ;;
    *Logout)
        hyprctl dispatch exit
        ;;
esac
