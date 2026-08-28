#!/usr/bin/env bash
# Rose Pine OSD daemon — feeds wob from the per-instance fifo.
# volume.sh / brightness.sh write slider values here.

set -euo pipefail

fifo="/tmp/${HYPRLAND_INSTANCE_SIGNATURE:-hypr}.wob"
conf="$HOME/.config/wob/wob.ini"

# Recreate fifo cleanly on each session start
rm -f "$fifo"
mkfifo "$fifo"

# tail keeps the fifo open so wob never gets EOF and exits
tail -f "$fifo" | wob -c "$conf"
