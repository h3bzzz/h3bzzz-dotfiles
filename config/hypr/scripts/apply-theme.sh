#!/usr/bin/env bash
#
# Regenerate the whole desktop palette from a wallpaper and reload every
# surface that renders it.
#
#   apply-theme.sh [/path/to/image]
#
# With no argument it re-themes from whatever ~/.config/hypr/current-wallpaper
# points at, so it doubles as "rebuild the theme" after editing a template.
#
# Deliberately NOT `set -e`: a single unhappy consumer (waybar not running,
# quickshell not started) must never abort the reload of the others.

set -uo pipefail

MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
STATE_LINK="$HOME/.config/hypr/current-wallpaper"
SCHEME="${MATUGEN_SCHEME:-scheme-vibrant}"
MODE="${MATUGEN_MODE:-dark}"

wallpaper="${1:-$(readlink -f "$STATE_LINK" 2>/dev/null)}"

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    printf 'apply-theme: no wallpaper to theme from (%s)\n' "${wallpaper:-unset}" >&2
    exit 1
fi

if ! command -v matugen >/dev/null 2>&1; then
    printf 'apply-theme: matugen is not installed; leaving the palette alone\n' >&2
    exit 1
fi

# ---- 1. generate -------------------------------------------------------
# Two passes, because the accents are not matugen's to make. Pass one only
# extracts the wallpaper's source colour; theme-accents.py assigns the six
# Rose Pine accents to hues the image actually contains, and pass two
# renders the templates with those accents imported alongside the Material
# surfaces. See theme-accents.py for why matugen's own `blend` is not used.
#
# `--source-color-index 0` takes matugen's most *dominant* candidate. The
# obvious-looking alternative, `--prefer saturation`, takes the most vivid one
# instead, and on a photograph that is usually a minority detail -- a neon
# sign, a lamp, a sunset edge. Measured over this wallpaper library it put the
# palette on the wrong side of the colour wheel for 15 of 35 images (a blue
# Tokyo Night wallpaper themed the desktop orange). Index 0 was wrong for none
# of them. The old comment here worried that the dominant colour would be
# near-black on a dark rice; matugen already drops neutrals before it offers
# candidates, so that never actually happens.
MATUGEN_ARGS=(-t "$SCHEME" -m "$MODE" --source-color-index 0)

# One dry run yields both the seed colour and the bar background the accents
# have to stay legible against.
read -r source_color base_color < <(
    matugen image "$wallpaper" "${MATUGEN_ARGS[@]}" --json hex --dry-run 2>/dev/null \
    | python -c 'import json,sys
c = json.load(sys.stdin)["colors"]
sur = c["surface"]
print(c["source_color"]["default"]["color"],
      sur["dark"]["color"] if "dark" in sur else sur["default"]["color"])' \
    2>/dev/null
)

if [[ -z "$source_color" ]]; then
    printf 'apply-theme: could not read a source colour from %s; palette left in place\n' \
        "$wallpaper" >&2
    exit 1
fi

accents="$(python "$HOME/.config/hypr/scripts/theme-accents.py" \
    "$source_color" "$wallpaper" "$base_color")" || {
    printf 'apply-theme: accent derivation failed; palette left in place\n' >&2
    exit 1
}

if ! matugen image "$wallpaper" \
        -c "$MATUGEN_CONFIG" \
        "${MATUGEN_ARGS[@]}" \
        --import-json-string "$accents" \
        --quiet; then
    printf 'apply-theme: matugen failed; existing palette left in place\n' >&2
    exit 1
fi

# ---- 2. splice ---------------------------------------------------------
# hyprlock cannot `source` a palette file, so its copy is patched in place.
# Non-fatal on purpose: a failed splice leaves the previous, valid lock screen
# config alone, and that is strictly better than aborting the rest of the
# reload over it.
python "$HOME/.config/hypr/scripts/splice-hyprlock-palette.py" >/dev/null || \
    printf 'apply-theme: hyprlock palette not spliced; lock screen keeps its old colours\n' >&2

# ---- 3. reload ---------------------------------------------------------

# Hyprland re-reads lua/colors.lua as part of a normal config reload.
hyprctl reload >/dev/null 2>&1

# Waybar has no live CSS reload; SIGUSR2 makes it re-read config *and* style.
if pgrep -x waybar >/dev/null 2>&1; then
    pkill -USR2 -x waybar
fi

# swaync reloads CSS without dropping the notification history.
if command -v swaync-client >/dev/null 2>&1; then
    swaync-client --reload-css >/dev/null 2>&1
fi

# Quickshell needs no signal: it watches its config directory and reloads
# itself when matugen rewrites Colors.qml. (There is no `qs reload` subcommand
# in 0.3.1 -- only log/list/kill/ipc -- so nothing to call here.)

# Ghostty watches its config file; SIGUSR2 asks every window to re-read it.
if pgrep -x ghostty >/dev/null 2>&1; then
    pkill -USR2 -x ghostty
fi

# tmux keeps its options in the running server, so a reload is needed for
# existing sessions to pick up the new palette. No server = nothing to do.
if command -v tmux >/dev/null 2>&1 && tmux has-session 2>/dev/null; then
    tmux source-file "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1
fi

# btop reads its theme only at startup — nothing to signal.

exit 0
