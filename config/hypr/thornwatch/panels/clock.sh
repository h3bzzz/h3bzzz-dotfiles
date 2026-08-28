#!/usr/bin/env bash
# panels/clock.sh -- block-font wall clock with the date underneath.
set -uo pipefail
. "$TW_DIR/lib/layout.sh"

BIG="$TW_DIR/lib/bigtext.py"
date_line=$(date '+%A %d %B %Y' | tr '[:lower:]' '[:upper:]')

# Battery rides along on the date line -- glancing at the clock is exactly
# when you want to know whether the laptop is about to die.
bat=/sys/class/power_supply/BAT0
if [[ -r $bat/capacity ]]; then
    case $(<"$bat/status") in
        Charging) mark="+" ;;
        Full)     mark="=" ;;
        *)        mark="-" ;;
    esac
    date_line="$date_line   ·   BAT $mark$(<"$bat/capacity")%"
fi

{
    "$BIG" -f "$TW_FILL" -p 2 "$(date '+%H:%M')" | sed "s/^/$TW_G/"
    echo
    echo "${TW_C}${date_line}"
} | tw_block
