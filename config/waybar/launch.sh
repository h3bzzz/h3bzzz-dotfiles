#!/bin/bash

killall waybar 2>/dev/null
pkill -f cava-waybar 2>/dev/null
sleep 0.5

waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css &

echo "Waybar started (PID: $!)"
