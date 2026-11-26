#!/usr/bin/env bash
# Searchable keybind cheat sheet. Reads the binds Hyprland actually has loaded
# (hyprctl binds -j) and shows every one that carries a description, so the
# sheet can never drift from binds.lua / extras.lua.

set -euo pipefail

theme="$HOME/.config/rofi/launchers/type-3/style-3.rasi"

hyprctl binds -j | python3 -c '
import json, sys

MODS = [(64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT")]
rows = []
for b in json.load(sys.stdin):
    desc = b.get("description") or ""
    if not b.get("has_description") or not desc:
        continue
    keys = [name for bit, name in MODS if b.get("modmask", 0) & bit]
    key = b.get("key") or ("code:%s" % b.get("keycode"))
    keys.append(key.upper() if len(key) == 1 else key)
    sub = b.get("submap") or ""
    combo = " + ".join(keys) + ("  [%s]" % sub if sub else "")
    rows.append((combo, desc))

width = max(len(c) for c, _ in rows)
for combo, desc in rows:
    print("%s   %s" % (combo.ljust(width), desc))
' | rofi -dmenu -i -p "Keybinds" -theme "$theme" \
        -theme-str 'window { width: 900px; } listview { lines: 16; columns: 1; }' \
    >/dev/null || true
