#!/bin/bash

if [[ $(cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | grep -c "1") -gt 0 ]]; then
	echo " hey fat fingers, your CAPS LOCK is ON!"
else
	echo ""
fi
