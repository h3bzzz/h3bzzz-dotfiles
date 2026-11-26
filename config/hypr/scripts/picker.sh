#!/usr/bin/env bash
# Emoji picker and calculator through rofi plugins (rofi-emoji, rofi-calc).
#
#   picker.sh emoji   pick an emoji; it is copied to the clipboard
#   picker.sh calc    live calculator; Enter copies the result

set -uo pipefail

theme="$HOME/.config/rofi/launchers/type-3/style-3.rasi"
plugin_dir=$(pkg-config --variable=pluginsdir rofi 2>/dev/null || echo /usr/lib/rofi)

need() {
    [[ -e $plugin_dir/$1.so ]] && return 0
    notify-send -a picker "${2^}" "rofi-$2 is not installed (sudo pacman -S rofi-$2)"
    exit 1
}

case "${1:-}" in
    emoji)
        need emoji emoji
        rofi -modi emoji -show emoji -emoji-mode copy -theme "$theme"
        ;;
    calc)
        need calc calc
        rofi -modi calc -show calc -no-show-match -no-sort -theme "$theme" \
            -calc-command "printf '%s' '{result}' | wl-copy"
        ;;
    *)
        echo "usage: picker.sh emoji|calc" >&2
        exit 2
        ;;
esac
