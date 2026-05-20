#!/usr/bin/env python3

import json
import os
import signal
import subprocess
import sys
from typing import cast, TextIO

CONFIG = os.path.expanduser("~/.config/cava/waybar.conf")
LEVELS = "▁▂▃▄▅▆▇█"
COLORS = [
    (80, "#6e6a86"),
    (180, "#908caa"),
    (320, "#31748f"),
    (520, "#9ccfd8"),
    (760, "#c4a7e7"),
    (1001, "#f6c177"),
]

proc = None


def color_for(value: int) -> str:
    for threshold, color in COLORS:
        if value < threshold:
            return color
    return "#eb6f92"


def glyph_for(value: int) -> str:
    index = round((max(0, min(value, 1000)) / 1000) * (len(LEVELS) - 1))
    return LEVELS[index]


def emit(values):
    peak = max(values) if values else 0
    css_class = "active" if peak > 60 else "idle"
    text = "".join(
        f"<span foreground='{color_for(value)}'>{glyph_for(value)}</span>"
        for value in values
    )
    print(
        json.dumps(
            {
                "text": text,
                "tooltip": "Cava visualizer - default output monitor",
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
            values = [0] * 12

        emit(values)
finally:
    shutdown()
