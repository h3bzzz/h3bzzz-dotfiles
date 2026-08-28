#!/usr/bin/env bash

set -euo pipefail

STATE_LINK="$HOME/.config/hypr/current-wallpaper"

if [[ $# -lt 1 ]]; then
    printf 'Usage: %s /absolute/path/to/wallpaper\n' "$0" >&2
    exit 1
fi

wallpaper="$1"

if [[ "$wallpaper" != /* ]]; then
    wallpaper="$(python -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$wallpaper")"
fi

if [[ ! -f "$wallpaper" ]]; then
    printf 'Wallpaper not found: %s\n' "$wallpaper" >&2
    exit 1
fi

ln -sfn "$wallpaper" "$STATE_LINK"

pkill -9 hyprpaper 2>/dev/null || true
sleep 0.5
hyprpaper -c ~/.config/hypr/hyprpaper.conf >/dev/null 2>&1 &
sleep 1

# Re-derive the whole desktop palette from this wallpaper and reload every
# surface that renders it. Deliberately not fatal: a wallpaper that matugen
# cannot read must still get set, just without a new palette.
"$HOME/.config/hypr/scripts/apply-theme.sh" "$wallpaper" || \
    printf 'set-wallpaper: theme not regenerated; wallpaper still changed\n' >&2

# Sync the greetd/regreet login-screen background to this pick.
if command -v sync-greeter-wallpaper >/dev/null 2>&1; then
    env -u TERMINFO sudo -n /usr/local/bin/sync-greeter-wallpaper >/dev/null 2>&1 || true
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Wallpaper changed" "$(basename "$wallpaper")"
fi
