#!/usr/bin/env python3
"""Splice the generated palette into hyprlock.conf.

hyprlock 0.9.6 cannot `source` another file -- hyprlang leaves that directive
to Hyprland -- so the palette has to land inside hyprlock.conf itself. The
block between the two markers is replaced wholesale with the body of the
matugen-generated colors.conf.

Written to a temporary file in the same directory and moved into place, so an
interrupted run can never leave a half-written lock screen config behind. Any
problem is reported and the existing hyprlock.conf is left untouched: a lock
screen that will not parse is the one failure mode worth being paranoid about.
"""
import pathlib
import sys
import tempfile

BEGIN = "# >>> matugen palette >>>"
END = "# <<< matugen palette <<<"


def main():
    home = pathlib.Path.home()
    generated = home / ".config/hypr/colors.conf"
    target = home / ".config/hypr/hyprlock.conf"

    if not generated.is_file():
        sys.exit("splice-hyprlock-palette: {} is missing".format(generated))
    if not target.is_file():
        sys.exit("splice-hyprlock-palette: {} is missing".format(target))

    payload = [
        line for line in generated.read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if not payload:
        sys.exit("splice-hyprlock-palette: generated palette is empty")

    lines = target.read_text().splitlines()
    try:
        start = lines.index(BEGIN)
        end = lines.index(END)
    except ValueError:
        sys.exit("splice-hyprlock-palette: markers not found in {}".format(target))
    if end < start:
        sys.exit("splice-hyprlock-palette: markers are out of order")

    merged = lines[:start + 1] + payload + lines[end:]

    fd, tmp = tempfile.mkstemp(dir=str(target.parent), prefix=".hyprlock.conf.")
    tmp = pathlib.Path(tmp)
    try:
        with open(fd, "w") as fh:
            fh.write("\n".join(merged) + "\n")
        tmp.replace(target)
    except BaseException:
        tmp.unlink(missing_ok=True)
        raise

    print("splice-hyprlock-palette: {} palette lines written".format(len(payload)))


if __name__ == "__main__":
    main()
