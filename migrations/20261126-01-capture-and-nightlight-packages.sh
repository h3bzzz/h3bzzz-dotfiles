#!/usr/bin/env bash
# Install the packages behind night light, screen recording, QR scan, emoji and calculator.
set -euo pipefail
sudo pacman -S --needed hyprsunset hyprshutdown wf-recorder tesseract tesseract-data-eng zbar rofi-emoji rofi-calc
