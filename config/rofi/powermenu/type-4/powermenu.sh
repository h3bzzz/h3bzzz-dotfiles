#!/usr/bin/env bash

set -euo pipefail

dir="$HOME/.config/rofi/powermenu/type-4"
theme="$dir/style-5.rasi"
confirm_theme="$dir/shared/confirm.rasi"

lock='󰌾  Lock'
suspend='󰒲  Suspend'
logout='󰍃  Logout'
reboot='󰜉  Reboot'
shutdown='󰐥  Shutdown'
yes='Yes'
no='No'

rofi_cmd() {
    rofi -dmenu -i -p "Rose Pine Session" -mesg "Lock, sleep, or power down" -theme "$theme"
}

confirm_cmd() {
    rofi -dmenu -i -p "Confirm" -mesg "Are you sure?" -theme "$confirm_theme"
}

confirm_exit() {
    printf '%s\n%s\n' "$yes" "$no" | confirm_cmd
}

run_rofi() {
    printf '%s\n%s\n%s\n%s\n%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown" | rofi_cmd
}

run_cmd() {
    selected="$(confirm_exit)"
    [[ "$selected" == "$yes" ]] || exit 0

    case "$1" in
        --shutdown)
            if command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown --help >/dev/null 2>&1; then
                hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'
            else
                systemctl poweroff
            fi
            ;;
        --reboot)
            if command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown --help >/dev/null 2>&1; then
                hyprshutdown -t 'Restarting...' --post-cmd 'reboot'
            else
                systemctl reboot
            fi
            ;;
        --suspend)
            systemctl suspend
            ;;
        --logout)
            hyprctl dispatch exit
            ;;
    esac
}

chosen="$(run_rofi)"

case "$chosen" in
    "$lock")
        hyprlock
        ;;
    "$suspend")
        run_cmd --suspend
        ;;
    "$logout")
        run_cmd --logout
        ;;
    "$reboot")
        run_cmd --reboot
        ;;
    "$shutdown")
        run_cmd --shutdown
        ;;
esac
