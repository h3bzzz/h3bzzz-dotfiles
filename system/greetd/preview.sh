#!/usr/bin/env bash
# Preview the login screen in a window on the current desktop, without root
# and without touching /etc: renders the background from the current
# wallpaper into a temp dir, then runs the greeter's own Hyprland config
# nested with `regreet --demo`. Close the window (or Ctrl+C) to finish.
#
#   ./preview.sh            keep it open until closed
#   ./preview.sh --shot F   save a screenshot of the preview to F and exit
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHOT=""
if [[ "${1:-}" = --shot ]]; then SHOT="${2:?path}"; fi

[[ -n "${WAYLAND_DISPLAY:-}" ]] || { echo "run this from inside the Wayland desktop" >&2; exit 1; }

work="$(mktemp -d)"
hypr=""
cleanup() {
    [[ -n "$hypr" ]] && kill "$hypr" 2>/dev/null || true
    pkill -f "regreet --demo -c '$work/" 2>/dev/null || true
    rm -rf -- "$work"
}
trap cleanup EXIT

cp -- "$HERE/regreet.css" "$work/regreet.css"
GREETER_SYNC_BG_DIR="$work" GREETER_SYNC_CSS="$work/regreet.css" "$HERE/sync-greeter-wallpaper"
sed "s|^path = .*|path = \"$work/current-wallpaper\"|" "$HERE/regreet.toml" > "$work/regreet.toml"

export GREETER_REGREET_CMD="regreet --demo -c '$work/regreet.toml' -s '$work/regreet.css' -l '$work/regreet.log'"
# A nested Hyprland must not inherit the parent's instance signature.
env -u HYPRLAND_INSTANCE_SIGNATURE Hyprland --config "$HERE/hyprland.lua" >"$work/hyprland.out" 2>&1 &
hypr=$!

if [[ -z "$SHOT" ]]; then
    wait "$hypr"
    exit 0
fi


# wlr-screencopy (grim/hyprshot) hangs on this box, so the screenshot path
# skips the nested compositor: run the demo as an X11 window on the desktop
# and let ImageMagick pull the pixels straight from Xwayland.
kill "$hypr" 2>/dev/null || true; hypr=""
[[ -n "${DISPLAY:-}" ]] || { echo "no DISPLAY (Xwayland) for the screenshot path" >&2; exit 1; }
GDK_BACKEND=x11 GTK_USE_PORTAL=0 GDK_DEBUG=no-portals \
    regreet --demo -c "$work/regreet.toml" -s "$work/regreet.css" -l "$work/regreet.log" >"$work/regreet.out" 2>&1 &
rg=$!
sleep 4
wid="$(xprop -root _NET_CLIENT_LIST 2>/dev/null | grep -oE '0x[0-9a-f]+' | head -1)"
import -display "$DISPLAY" -window "${wid:-root}" "$SHOT"
kill "$rg" 2>/dev/null || true
echo "screenshot: $SHOT"
echo "--- regreet log (warnings/errors)"; grep -E 'WARN|ERROR' "$work/regreet.log" 2>/dev/null | grep -vE 'Run as demo|locale' | tail -n 10 || true
echo "--- gtk css warnings"; grep -iE 'css|theme parser' "$work/regreet.out" | grep -v 'Empty declaration' | head -10 || true
