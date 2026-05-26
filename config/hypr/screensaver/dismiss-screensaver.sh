#!/usr/bin/env bash

pkill -f "com\\.tte\\.screensaver"
sleep 0.3
loginctl lock-session
