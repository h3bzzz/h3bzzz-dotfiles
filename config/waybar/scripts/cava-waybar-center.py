#!/usr/bin/env python3

import json
import os
import signal
import subprocess
import sys
from typing import cast, TextIO

SIDE = sys.argv[1] if len(sys.argv) > 1 else "right"
CONFIG = os.path.expanduser("~/.config/cava/waybar-center.conf")
HALF = 10
LEVELS = "▁▂▃▄▅▆▇█"
# ── Palette ─────────────────────────────────────────────────────────────
# ~/.config/matugen/colors.json is regenerated from the wallpaper by
# apply-theme.sh, which then SIGUSR2s waybar -- and that restarts this
# script, so reading the file once at start-up is enough.
#
# The Rose Pine defaults stay as a fallback: this module has to keep drawing
# if the file is missing, unreadable, or caught mid-write by the reload.
PALETTE = {
    "base": "#191724", "surface": "#1f1d2e", "overlay": "#26233a",
    "muted": "#6e6a86", "subtle": "#908caa", "text": "#e0def4",
    "love": "#eb6f92", "gold": "#f6c177", "rose": "#ebbcba",
    "pine": "#31748f", "foam": "#9ccfd8", "iris": "#c4a7e7",
}

try:
    with open(os.path.expanduser("~/.config/matugen/colors.json")) as _fh:
        PALETTE.update({
            k: v for k, v in json.load(_fh).items()
            if k in PALETTE and isinstance(v, str)
        })
except (OSError, ValueError):
    pass

COLORS = [
    (80,   PALETTE["muted"]),
    (180,  PALETTE["subtle"]),
    (320,  PALETTE["pine"]),
    (520,  PALETTE["foam"]),
    (760,  PALETTE["iris"]),
    (1001, PALETTE["gold"]),
]

proc = None

# idle/active with hysteresis to avoid flicker on quiet passages
ACTIVE_HIGH = 120  # rise above this -> active
ACTIVE_LOW = 40    # fall below this -> idle; between = hold previous state
_is_active = False


def color_for(value: int) -> str:
    for threshold, color in COLORS:
        if value < threshold:
            return color
    return PALETTE["love"]


def glyph_for(value: int) -> str:
    index = round((max(0, min(value, 1000)) / 1000) * (len(LEVELS) - 1))
    return LEVELS[index]


def emit(values):
    # full-spectrum split: left = bass (bands 0-9, bass at outer edge),
    # right = treble (bands 10-19, treble at outer edge). Uses all bars
    # instead of mirroring the same low-freq half on both sides.
    if SIDE == "left":
        half = values[:HALF]
    else:
        half = values[HALF:HALF * 2]

    global _is_active
    peak = max(values) if values else 0
    if peak >= ACTIVE_HIGH:
        _is_active = True
    elif peak <= ACTIVE_LOW:
        _is_active = False
    css_class = "active" if _is_active else "idle"
    text = "".join(
        f"<span foreground='{color_for(v)}'>{glyph_for(v)}</span>" for v in half
    )
    print(
        json.dumps(
            {
                "text": text,
                "tooltip": f"Cava - {SIDE} channel",
                "class": css_class,
            }
        ),
        flush=True,
    )


def shutdown(*_args):
    global proc
    if proc and proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=1)
        except subprocess.TimeoutExpired:
            proc.kill()
    sys.exit(0)


signal.signal(signal.SIGINT, shutdown)
signal.signal(signal.SIGTERM, shutdown)

proc = subprocess.Popen(
    ["cava", "-p", CONFIG],
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True,
    bufsize=1,
)

if proc.stdout is None:
    shutdown()

stdout = cast(TextIO, proc.stdout)

try:
    while True:
        line = stdout.readline()
        if line == "":
            break

        values = []
        for raw in line.strip().split(";"):
            if raw:
                try:
                    values.append(int(raw))
                except ValueError:
                    pass

        if not values:
            values = [0] * 20

        emit(values)
finally:
    shutdown()
