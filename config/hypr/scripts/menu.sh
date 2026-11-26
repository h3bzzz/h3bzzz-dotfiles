#!/usr/bin/env bash
# Control menu (SUPER + X): every toggle and tool in one searchable list, with
# the current state shown inline. Each entry is also reachable by its own
# keybind -- this is the "I forgot the key" path.

set -uo pipefail

theme="$HOME/.config/rofi/launchers/type-3/style-3.rasi"
S="$HOME/.config/hypr/scripts"
st() { "$S/toggle.sh" status "$1"; }
game=$(hyprctl eval 'return Rice and Rice.game_mode and "on" or "off"' 2>/dev/null | head -1)
[[ $game == on || $game == off ]] || game=off
candy=$(hyprctl eval 'return Rice and Rice.eye_candy and "on" or "off"' 2>/dev/null | head -1)
[[ $candy == on || $candy == off ]] || candy=off
rec=$("$S/capture.sh" status)

entries=(
    "󰌌  Keybinds"
    "󰖔  Night light            [$(st nightlight)]"
    "󰅶  Caffeine (no idle)     [$(st idle)]"
    "󰊴  Game mode              [$game]"
    "󰄛  Eye candy              [$candy]"
    "󰂛  Do not disturb         [$(st dnd)]"
    "󱐋  Power profile          [$(st power)]"
    "󰕧  Record screen          [${rec:-idle}]"
    "󰊄  Copy text from screen (OCR)"
    "󰐲  Scan QR code"
    "󰈊  Pick colour"
    "󰞅  Emoji"
    "󰃬  Calculator"
    "󰅌  Clipboard history"
    "󰸉  Wallpaper"
    "󰌾  Lock"
)

pick=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "Control" -theme "$theme") || exit 0

case "$pick" in
    *Keybinds*)        exec "$S/keybinds.sh" ;;
    *"Night light"*)   exec "$S/toggle.sh" nightlight ;;
    *Caffeine*)        exec "$S/toggle.sh" idle ;;
    *"Game mode"*)     hyprctl eval 'Rice.toggle_game_mode()' >/dev/null ;;
    *"Eye candy"*)     hyprctl eval 'Rice.toggle_eye_candy()' >/dev/null ;;
    *"Do not disturb"*) exec "$S/toggle.sh" dnd ;;
    *"Power profile"*) exec "$S/toggle.sh" power ;;
    *Record*)          sleep 0.3; exec "$S/capture.sh" record ;;
    *OCR*)             sleep 0.3; exec "$S/capture.sh" ocr ;;
    *QR*)              sleep 0.3; exec "$S/capture.sh" qr ;;
    *colour*)          sleep 0.3; hyprpicker -a ;;
    *Emoji*)           exec "$S/picker.sh" emoji ;;
    *Calculator*)      exec "$S/picker.sh" calc ;;
    *Clipboard*)       exec "$S/clipboard.sh" ;;
    *Wallpaper*)       qs ipc call wallpaper toggle ;;
    *Lock*)            pidof hyprlock >/dev/null || hyprlock ;;
esac
