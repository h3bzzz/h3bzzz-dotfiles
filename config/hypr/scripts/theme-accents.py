#!/usr/bin/env python3
"""Derive the six Rose Pine accent slots from the wallpaper's own colours.

The old version rotated each Rose Pine hue a fixed *fraction* of the way toward
the wallpaper's source colour. That lerps between two hues, and the midpoint of
(pink -> blue) is magenta -- a hue present in neither the wallpaper nor the
theme. Measured over the wallpaper library, the accents it produced sat a mean
0.19 turn away from any colour actually in the image, which is why the bar
never looked like it belonged to the picture.

This version instead reads the image's real hue vocabulary and *assigns* the
free accent slots to hues that are genuinely in the frame, so the bar is built
out of the wallpaper's own colours rather than out of interpolation artefacts.

What is kept from Rose Pine is the part that carries meaning rather than
identity:

  * lightness  -- verbatim. `pine` is a dark selection ground and `foam` is an
                  airy highlight; that spread is the theme's legibility
                  contract and no wallpaper gets a vote on it.
  * semantics  -- `love` is the error colour and `gold` the warning one. They
                  are only re-hued when the wallpaper actually offers a colour
                  inside the red/amber bands; otherwise they harmonise by a
                  bounded 15 degrees, the same cap Material's Blend.harmonize
                  uses. A magenta "error" badge is a worse bar than an
                  untinted one.

Usage: theme-accents.py SOURCE_HEX [IMAGE_PATH] [BASE_HEX]

With no IMAGE_PATH (or if the image cannot be read) it degrades to bounded
harmonisation of the stock palette, which is still a valid, if quieter, theme.
BASE_HEX is the bar background; accents are lifted until they clear a contrast
floor against it.
"""

import colorsys
import json
import math
import re
import subprocess
import sys

# Rose Pine anchors: (hex, semantic hue window or None).
# The window is written on the unwrapped wheel, so love's runs past 1.0.
ANCHORS = {
    "love": ("#eb6f92", (0.88, 1.03)),
    "gold": ("#f6c177", (0.06, 0.17)),
    "rose": ("#ebbcba", None),
    "pine": ("#31748f", None),
    "foam": ("#9ccfd8", None),
    "iris": ("#c4a7e7", None),
}

# Material's Blend.harmonize caps its rotation at 15 degrees. Same cap here,
# for the fallback path only.
HARMONISE_CAP = 15.0 / 360.0

# How far a slot's saturation may follow the wallpaper's. Bounded so a washed
# out photo cannot grey the whole UI out, and a neon one cannot make every
# widget scream.
SAT_PULL = 0.55
SAT_FLOOR = 0.28
SAT_CEIL = 0.92

# Two hues closer than this are the same colour as far as the eye is concerned.
HUE_MERGE = 0.045

# Minimum WCAG contrast an accent must have against the bar background.
# 3.0 is the large-text / UI-component floor; accents are icons and borders.
CONTRAST_FLOOR = 3.0


# ---------------------------------------------------------------- colour math

def hex_to_hls(hex_str):
    h = hex_str.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return colorsys.rgb_to_hls(r, g, b)


def hue_gap(a, b):
    """Shortest distance between two hues, 0..0.5."""
    d = abs(a - b) % 1.0
    return min(d, 1.0 - d)


def relative_luminance(r, g, b):
    def chan(c):
        c /= 255.0
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)


def contrast_ratio(rgb1, rgb2):
    l1, l2 = relative_luminance(*rgb1), relative_luminance(*rgb2)
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)


def to_forms(h, l, s):
    """Every spelling of one colour the templates ask for.

    matugen's own colours arrive as objects with .hex/.rgb/.red/... ; imported
    JSON is inert, so each accent has to carry those forms itself.
    """
    r, g, b = colorsys.hls_to_rgb(h % 1.0, min(max(l, 0.0), 1.0), min(max(s, 0.0), 1.0))
    r, g, b = round(r * 255), round(g * 255), round(b * 255)
    stripped = "{:02x}{:02x}{:02x}".format(r, g, b)
    return {
        "hex": "#" + stripped,
        "hexs": stripped,
        "rgb": "rgb({}, {}, {})".format(r, g, b),
        "r": r, "g": g, "b": b,
    }


def in_window(hue, window):
    lo, hi = window
    probe = hue + 1.0 if hue < lo - 0.5 else hue
    return lo <= probe <= hi


def clamp_window(hue, window):
    lo, hi = window
    probe = hue + 1.0 if hue < lo - 0.5 else hue
    return min(max(probe, lo), hi)


# ------------------------------------------------------------ image palette

def image_hue_families(path):
    """The image's hue vocabulary, strongest first.

    Each entry is (hue, weight, saturation). Weight is pixel area times
    saturation: a small vivid neon sign and a large muted sky both get to
    matter, but neither one alone decides the palette. Neutral, near-black and
    blown-out pixels carry no hue and are dropped.
    """
    try:
        out = subprocess.run(
            ["convert", path + "[0]", "-resize", "220x220^", "-colors", "40",
             "-format", "%c", "histogram:info:"],
            capture_output=True, text=True, timeout=40).stdout
    except Exception:
        return []

    entries = []
    for line in out.splitlines():
        m = re.search(r"^\s*(\d+):.*?(#[0-9A-Fa-f]{6})", line)
        if not m:
            continue
        count, hx = int(m.group(1)), m.group(2)
        h, l, s = hex_to_hls(hx)
        if s < 0.13 or l < 0.07 or l > 0.94:
            continue
        entries.append((h, count * s, s))
    if not entries:
        return []

    # Merge neighbouring hues into families, accumulating their weight, so a
    # gradient counts once as a strong colour rather than ten weak ones.
    entries.sort(key=lambda e: -e[1])
    families = []
    for h, w, s in entries:
        for i, (fh, fw, fs, n) in enumerate(families):
            if hue_gap(h, fh) < HUE_MERGE:
                # Circular mean, weight-blended.
                tot = fw + w
                x = fw * math.cos(2 * math.pi * fh) + w * math.cos(2 * math.pi * h)
                y = fw * math.sin(2 * math.pi * fh) + w * math.sin(2 * math.pi * h)
                families[i] = ((math.atan2(y, x) / (2 * math.pi)) % 1.0,
                               tot, (fs * fw + s * w) / tot, n + 1)
                break
        else:
            families.append((h, w, s, 1))

    families.sort(key=lambda f: -f[1])
    total = sum(f[1] for f in families) or 1.0
    # Drop specks: a family worth under 3% of the image's colour mass is noise,
    # not a colour the wallpaper reads as having.
    return [(h, w / total, s) for h, w, s, _ in families if w / total >= 0.03]


# ---------------------------------------------------------------- assignment

def pick_free_hues(families, src_h):
    """Hues for the four unconstrained slots: iris, foam, pine, rose.

    The dominant family owns the structural accents. That is the whole lesson
    of the previous two attempts: a wallpaper that is 80% blue and 20% neon
    must not end up with an olive selection ground, and both `--prefer
    saturation` and a naive "spend each family once" rule do exactly that by
    handing a structural slot to a minority speck.

    So iris, foam and pine stay in the dominant family -- fanned into an
    analogous chord so they read as three colours rather than one -- and a
    genuine secondary hue is spent on `rose` alone, where a single contrasting
    accent is a feature rather than an inconsistency. A secondary only
    displaces a structural slot when it is strong enough to be a co-dominant
    colour rather than an accent.
    """
    if families:
        base, base_w = families[0][0], families[0][1]
        rest = families[1:]
    else:
        base, base_w, rest = src_h, 1.0, []

    def nth(i, floor):
        """The i-th secondary family, if it carries enough of the image."""
        return rest[i][0] if len(rest) > i and rest[i][1] >= floor else None

    # Co-dominant (>= 0.30) hues may take a structural slot; anything weaker
    # cannot. `rose` accepts a merely-substantial (>= 0.15) secondary.
    return {
        "iris": base,
        "foam": nth(0, 0.30) if nth(0, 0.30) is not None else base + 0.055,
        "pine": nth(1, 0.30) if nth(1, 0.30) is not None else base - 0.055,
        "rose": nth(0, 0.15) if nth(0, 0.15) is not None else base + 0.11,
    }


def derive(source_hex, image_path, base_hex):
    src_h, _, src_s = hex_to_hls(source_hex)
    families = image_hue_families(image_path) if image_path else []
    free = pick_free_hues(families, src_h)
    base_rgb = None
    if base_hex:
        b = base_hex.lstrip("#")
        base_rgb = tuple(int(b[i:i + 2], 16) for i in (0, 2, 4))

    out = {}
    for name, (anchor, window) in ANCHORS.items():
        a_h, a_l, a_s = hex_to_hls(anchor)

        if window is None:
            hue = free[name]
            # Saturation follows whichever family we landed on, if any.
            match = min(families, key=lambda f: hue_gap(f[0], hue)) if families else None
            target_s = match[2] if match else src_s
        else:
            # Semantic slot. Re-hue only if the wallpaper genuinely has a
            # colour in this band; otherwise harmonise within the 15 degree cap.
            candidates = [f for f in families if in_window(f[0], window)]
            if candidates:
                hue = max(candidates, key=lambda f: f[1])[0]
                target_s = max(candidates, key=lambda f: f[1])[2]
            else:
                delta = (src_h - a_h + 0.5) % 1.0 - 0.5
                hue = a_h + max(-HARMONISE_CAP, min(HARMONISE_CAP, delta))
                hue = clamp_window(hue, window)
                target_s = src_s

        sat = a_s + (target_s - a_s) * SAT_PULL
        sat = min(max(sat, SAT_FLOOR), SAT_CEIL)
        light = a_l

        # Contrast floor. Rose Pine's lightnesses were chosen against Rose
        # Pine's own base; a wallpaper-derived base can sit anywhere, so walk
        # the accent away from it until it is legible again.
        if base_rgb:
            for _ in range(24):
                r, g, b = colorsys.hls_to_rgb(hue % 1.0, light, sat)
                if contrast_ratio((r * 255, g * 255, b * 255), base_rgb) >= CONTRAST_FLOOR:
                    break
                light = light + 0.02 if relative_luminance(*base_rgb) < 0.18 else light - 0.02
                light = min(max(light, 0.05), 0.95)

        out[name] = to_forms(hue, light, sat)

    return out


def main():
    source = sys.argv[1] if len(sys.argv) > 1 else "#c4a7e7"
    image = sys.argv[2] if len(sys.argv) > 2 else None
    base = sys.argv[3] if len(sys.argv) > 3 else None
    json.dump({"accent": derive(source, image, base)}, sys.stdout)


if __name__ == "__main__":
    main()
