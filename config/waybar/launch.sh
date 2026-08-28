#!/bin/bash

# Kill existing waybar and cava instances
killall waybar 2>/dev/null
pkill -f cava-waybar-center 2>/dev/null
# also reap orphaned raw cava children (cmdline uses cava/waybar-center.conf,
# which the pattern above does NOT match -> they leak on every relaunch)
pkill -f "cava -p .*waybar-center" 2>/dev/null
sleep 1

# Start main waybar
waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css &

echo "Waybar started (PID: $!)"
