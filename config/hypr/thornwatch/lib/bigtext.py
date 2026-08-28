#!/usr/bin/env python3
"""Dependency-free 5x5 block-font renderer for thornwatch panels.

figlet is not installed and this needs to stay a zero-dependency config
directory, so the font lives here. Every glyph is five rows of five cells;
'#' is a lit cell, '.' is blank. Unknown characters render as blank.

    bigtext.py [-f FILL] [-p PAD] [-c COLS] TEXT [TEXT ...]

Each TEXT argument becomes one line of output. -c centres the result inside
that many columns; without it lines are left-aligned and untrimmed.
"""

import argparse
import sys

GLYPHS = {
    "A": ".###." "#...#" "#####" "#...#" "#...#",
    "B": "####." "#...#" "####." "#...#" "####.",
    "C": ".####" "#...." "#...." "#...." ".####",
    "D": "####." "#...#" "#...#" "#...#" "####.",
    "E": "#####" "#...." "####." "#...." "#####",
    "F": "#####" "#...." "####." "#...." "#....",
    "G": ".####" "#...." "#..##" "#...#" ".####",
    "H": "#...#" "#...#" "#####" "#...#" "#...#",
    "I": "#####" "..#.." "..#.." "..#.." "#####",
    "J": "####." "...#." "...#." "#..#." ".##..",
    "K": "#...#" "#..#." "###.." "#..#." "#...#",
    "L": "#...." "#...." "#...." "#...." "#####",
    "M": "#...#" "##.##" "#.#.#" "#...#" "#...#",
    "N": "#...#" "##..#" "#.#.#" "#..##" "#...#",
    "O": ".###." "#...#" "#...#" "#...#" ".###.",
    "P": "####." "#...#" "####." "#...." "#....",
    "Q": ".###." "#...#" "#.#.#" "#..#." ".##.#",
    "R": "####." "#...#" "####." "#..#." "#...#",
    "S": ".####" "#...." ".###." "....#" "####.",
    "T": "#####" "..#.." "..#.." "..#.." "..#..",
    "U": "#...#" "#...#" "#...#" "#...#" ".###.",
    "V": "#...#" "#...#" "#...#" ".#.#." "..#..",
    "W": "#...#" "#...#" "#.#.#" "##.##" "#...#",
    "X": "#...#" ".#.#." "..#.." ".#.#." "#...#",
    "Y": "#...#" ".#.#." "..#.." "..#.." "..#..",
    "Z": "#####" "...#." "..#.." ".#..." "#####",
    "0": ".###." "#..##" "#.#.#" "##..#" ".###.",
    "1": "..#.." ".##.." "..#.." "..#.." ".###.",
    "2": ".###." "#...#" "..##." ".#..." "#####",
    "3": "####." "....#" ".###." "....#" "####.",
    "4": "#..#." "#..#." "#####" "...#." "...#.",
    "5": "#####" "#...." "####." "....#" "####.",
    "6": ".###." "#...." "####." "#...#" ".###.",
    "7": "#####" "....#" "...#." "..#.." "..#..",
    "8": ".###." "#...#" ".###." "#...#" ".###.",
    "9": ".###." "#...#" ".####" "....#" ".###.",
    " ": "....." "....." "....." "....." ".....",
    ":": "....." "..#.." "....." "..#.." ".....",
    ".": "....." "....." "....." "....." "..#..",
    ",": "....." "....." "....." "..#.." ".#...",
    "-": "....." "....." ".###." "....." ".....",
    "_": "....." "....." "....." "....." "#####",
    "+": "....." "..#.." ".###." "..#.." ".....",
    "=": "....." ".###." "....." ".###." ".....",
    "/": "....#" "...#." "..#.." ".#..." "#....",
    "\\": "#...." ".#..." "..#.." "...#." "....#",
    "|": "..#.." "..#.." "..#.." "..#.." "..#..",
    "!": "..#.." "..#.." "..#.." "....." "..#..",
    "?": ".###." "#...#" "..##." "....." "..#..",
    "@": ".###." "#...#" "#.###" "#...." ".###.",
    "#": ".#.#." "#####" ".#.#." "#####" ".#.#.",
    "%": "##..#" "##.#." "..#.." ".#.##" "#..##",
    "*": "....." "#.#.#" ".###." "#.#.#" ".....",
    ">": "#...." ".#..." "..#.." ".#..." "#....",
    "<": "....#" "...#." "..#.." "...#." "....#",
    "[": ".###." ".#..." ".#..." ".#..." ".###.",
    "]": ".###." "...#." "...#." "...#." ".###.",
    "(": "..##." ".#..." ".#..." ".#..." "..##.",
    ")": ".##.." "...#." "...#." "...#." ".##..",
    "'": "..#.." "..#.." "....." "....." ".....",
    '"': ".#.#." ".#.#." "....." "....." ".....",
}

ROWS = 5
COLS = 5
BLANK = "." * (ROWS * COLS)


def render(text, fill="█", pad=1):
    """Return `text` as a list of ROWS strings drawn in the block font."""
    gap = " " * pad
    lines = []
    for row in range(ROWS):
        cells = []
        for ch in text.upper():
            glyph = GLYPHS.get(ch, BLANK)
            slice_ = glyph[row * COLS:(row + 1) * COLS]
            cells.append("".join(fill if c == "#" else " " for c in slice_))
        lines.append(gap.join(cells).rstrip())
    return lines


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("-f", "--fill", default="█", help="glyph for a lit cell")
    ap.add_argument("-p", "--pad", type=int, default=1,
                    help="blank columns between glyphs")
    ap.add_argument("-c", "--cols", type=int, default=0,
                    help="centre output inside this many columns")
    ap.add_argument("text", nargs="+")
    args = ap.parse_args()

    out = []
    for i, chunk in enumerate(args.text):
        if i:
            out.append("")
        out.extend(render(chunk, args.fill, args.pad))

    if args.cols > 0:
        width = max((len(line) for line in out), default=0)
        # Centre the block as a unit, not line by line -- per-line centring
        # makes the wordmark wobble between frames.
        left = max(0, (args.cols - width) // 2)
        out = [(" " * left) + line if line else line for line in out]

    sys.stdout.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
