#!/usr/bin/env bash
# panels/sigil.sh -- the wordmark. Host name in block type over a status rule.
set -uo pipefail
. "$TW_DIR/lib/layout.sh"

BIG="$TW_DIR/lib/bigtext.py"
host=$(hostnamectl hostname 2>/dev/null || cat /etc/hostname)
kernel=$(uname -r)
up=$(uptime -p 2>/dev/null | sed 's/^up //')
hypr=$(hyprctl version 2>/dev/null | sed -n '1s/.*Hyprland \([0-9.]*\).*/\1/p')

taglines=(
    "the way is made by walking"
    "read the source, then read it again"
    "every input is hostile until proven otherwise"
    "trust boundaries are where the bugs live"
    "compile it. run it. break it. keep it."
    "no such thing as a small privilege"
    "the machine is honest, the docs are not"
    "you do not find bugs, you notice them"
)

{
    # Marked as a group so the five rows of block type shift together.
    "$BIG" -f "$TW_FILL" "$host" | sed "s/^/$TW_G/"
    echo
    echo "${TW_C}$USER@$host   ·   hyprland $hypr   ·   $kernel   ·   up $up"
    echo "${TW_C}${taglines[$((RANDOM % ${#taglines[@]}))]}"
} | tw_block
