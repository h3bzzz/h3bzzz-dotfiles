#!/usr/bin/env bash
# Replace the AUR matugen-bin with matugen from the official repos.
set -euo pipefail
if pacman -Q matugen-bin >/dev/null 2>&1; then
    # pacman asks to remove matugen-bin because the two conflict; answer yes.
    sudo pacman -S matugen
else
    sudo pacman -S --needed matugen
fi
