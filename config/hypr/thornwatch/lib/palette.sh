# ~/.config/hypr/thornwatch/lib/palette.sh
# The wallpaper palette, and the gradient sets thornwatch hands to tte.
# Sourced, never executed.

# Rose Pine, as the fallback. ~/.config/matugen/colors.sh is regenerated from
# the current wallpaper by apply-theme.sh and overrides these below; if it is
# missing or half-written, thornwatch still has a full palette to draw with.
RP_BASE=191724
RP_SURFACE=1f1d2e
RP_OVERLAY=26233a
RP_MUTED=6e6a86
RP_SUBTLE=908caa
RP_TEXT=e0def4
RP_LOVE=eb6f92
RP_GOLD=f6c177
RP_ROSE=ebbcba
RP_PINE=31748f
RP_FOAM=9ccfd8
RP_IRIS=c4a7e7
RP_HL_LOW=21202e
RP_HL_MED=403d52
RP_HL_HIGH=524f67

# tte wants bare hex, so the *_BARE spellings are the ones taken here.
# Sourced in a subshell-safe way: every name is assigned only if the generated
# file actually defined it.
if [[ -r "$HOME/.config/matugen/colors.sh" ]]; then
    # shellcheck source=/dev/null
    . "$HOME/.config/matugen/colors.sh"
    RP_BASE="${BASE_BARE:-$RP_BASE}"
    RP_SURFACE="${SURFACE_BARE:-$RP_SURFACE}"
    RP_OVERLAY="${OVERLAY_BARE:-$RP_OVERLAY}"
    RP_MUTED="${MUTED_BARE:-$RP_MUTED}"
    RP_SUBTLE="${SUBTLE_BARE:-$RP_SUBTLE}"
    RP_TEXT="${TEXT_BARE:-$RP_TEXT}"
    RP_LOVE="${LOVE_BARE:-$RP_LOVE}"
    RP_GOLD="${GOLD_BARE:-$RP_GOLD}"
    RP_ROSE="${ROSE_BARE:-$RP_ROSE}"
    RP_PINE="${PINE_BARE:-$RP_PINE}"
    RP_FOAM="${FOAM_BARE:-$RP_FOAM}"
    RP_IRIS="${IRIS_BARE:-$RP_IRIS}"
    RP_HL_LOW="${HL_LOW_BARE:-$RP_HL_LOW}"
    RP_HL_MED="${HL_MED_BARE:-$RP_HL_MED}"
    RP_HL_HIGH="${HL_HIGH_BARE:-$RP_HL_HIGH}"
fi

# Gradient sets, one per line, each a space-separated stop list.
# tte interpolates between the stops; two or three reads best at a distance.
TW_GRADIENTS=(
    "$RP_IRIS $RP_FOAM"
    "$RP_LOVE $RP_GOLD"
    "$RP_PINE $RP_FOAM $RP_IRIS"
    "$RP_ROSE $RP_LOVE"
    "$RP_GOLD $RP_ROSE $RP_IRIS"
    "$RP_FOAM $RP_TEXT"
    "$RP_IRIS $RP_LOVE $RP_GOLD"
    "$RP_PINE $RP_IRIS"
    "$RP_MUTED $RP_FOAM"
    "$RP_LOVE $RP_IRIS $RP_FOAM"
)

TW_GRADIENT_DIRECTIONS=(vertical horizontal diagonal radial)

# Pick a random element from the arguments.
tw_pick() {
    local n=$#
    (( n == 0 )) && return 1
    local i=$(( RANDOM % n ))
    shift "$i"
    printf '%s' "$1"
}

tw_gradient()      { tw_pick "${TW_GRADIENTS[@]}"; }
tw_gradient_dir()  { tw_pick "${TW_GRADIENT_DIRECTIONS[@]}"; }
