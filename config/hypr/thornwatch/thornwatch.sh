#!/usr/bin/env bash
# ~/.config/hypr/thornwatch/thornwatch.sh
#
# The renderer. Runs inside the fullscreen terminal that ctl.sh spawns, and
# does exactly three things forever: build a frame from a panel script, push
# it through a random terminaltexteffects effect, and watch for any sign that
# the human came back.
#
# It never locks the screen itself. Exiting is the whole contract -- hypridle
# sees the same input event and runs `ctl.sh wake`, which is what brings up
# hyprlock. That keeps the lock decision in one place.

set -uo pipefail

TW_DIR=${TW_DIR:-$HOME/.config/hypr/thornwatch}
CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/thornwatch

# shellcheck source=/dev/null
[[ -r $TW_DIR/thornwatch.conf ]] && . "$TW_DIR/thornwatch.conf"
# shellcheck source=/dev/null
. "$TW_DIR/lib/palette.sh"

TTE=${TW_TTE:-$(command -v tte)}
[[ -x $TTE ]] || { echo "thornwatch: tte not found on PATH" >&2; sleep 5; exit 1; }

mkdir -p "$CACHE_DIR"

FRAME=$(mktemp -t thornwatch.frame.XXXXXX)
TTE_PID=""

cleanup() {
    [[ -n $TTE_PID ]] && kill "$TTE_PID" 2>/dev/null
    rm -f "$FRAME"
    printf '\033[?25h\033[0m\033[2J\033[H'   # cursor back, colours off, clear
    stty sane 2>/dev/null
}
trap cleanup EXIT
trap 'exit 0' TERM INT HUP

printf '\033[?25l\033[2J\033[H'              # hide cursor, clear

# ---------------------------------------------------------------- effects --
# tte prints its effect list in the subcommand block of --help. Parse it once
# and cache, so a screensaver start does not pay for a --help every time.
effects_cache=$CACHE_DIR/effects
if [[ ! -s $effects_cache ]]; then
    "$TTE" --help 2>/dev/null \
        | sed -n 's/^    \([a-z][a-z0-9]*\)  \+[A-Z].*/\1/p' \
        | sort -u > "$effects_cache"
fi

mapfile -t ALL_EFFECTS < "$effects_cache"
if (( ${#ALL_EFFECTS[@]} == 0 )); then
    ALL_EFFECTS=(beams binarypath burn crumble decrypt errorcorrect expand
                 laseretch matrix middleout orbittingvolley overflow pour
                 print rain randomsequence rings scattered slice slide smoke
                 spotlights spray swarm sweep synthgrid unstable vhstape
                 waves wipe)
fi

EFFECTS=()
for e in "${ALL_EFFECTS[@]}"; do
    [[ " ${TW_EFFECT_DENY:-} " == *" $e "* ]] && continue
    EFFECTS+=("$e")
done
(( ${#EFFECTS[@]} == 0 )) && EFFECTS=(wipe)

# Not every effect exposes the final-gradient flags. Probing costs one
# `tte <effect> -h` the first time an effect comes up, then it is cached.
supports_gradient() {
    local effect=$1 marker="$CACHE_DIR/grad.$effect"
    if [[ ! -f $marker ]]; then
        if "$TTE" "$effect" -h 2>/dev/null | grep -q -- '--final-gradient-stops'; then
            echo yes > "$marker"
        else
            echo no  > "$marker"
        fi
    fi
    [[ $(<"$marker") == yes ]]
}

# ----------------------------------------------------------------- panels --
# Weighted draw bag: each panel is inserted TW_WEIGHT_<name> times, then one
# element is drawn at random. Cheap, and the weights stay readable in the
# config file.
BAG=()
for panel in ${TW_PANELS:-sigil clock vitals}; do
    [[ -x $TW_DIR/panels/$panel.sh ]] || continue
    weight_var="TW_WEIGHT_$panel"
    weight=${!weight_var:-1}
    for (( i = 0; i < weight; i++ )); do BAG+=("$panel"); done
done
(( ${#BAG[@]} == 0 )) && { echo "thornwatch: no runnable panels" >&2; sleep 5; exit 1; }

# Avoid drawing the same panel twice in a row when there is a choice.
LAST_PANEL=""
draw_panel() {
    local pick
    for _ in 1 2 3; do
        pick=${BAG[$((RANDOM % ${#BAG[@]}))]}
        [[ $pick != "$LAST_PANEL" ]] && break
    done
    LAST_PANEL=$pick
    printf '%s' "$pick"
}

# ------------------------------------------------------------ input watch --
# NOTE: reading /dev/tty is NOT a usable wake signal here. The terminal writes
# its own reports into that same buffer -- a focus-in report the moment the
# stay_focused window rule pulls focus, plus the replies tte solicits when it
# queries background colour and cursor position. Treating any byte as "the
# human came back" killed the saver about one second after every start.
#
# So the wake signal is compositor state, not terminal bytes:
#
#   * hypridle owns real input. Any key, pointer move or touchpad tap resumes
#     idle, hypridle runs `ctl.sh wake`, and that SIGTERMs this script. That is
#     the primary path and it needs nothing from us.
#   * the pointer poll below is the backup for the case where hypridle is not
#     running, so a manually toggled saver still dismisses.
#   * hyprlock appearing means the hard-lock listener fired underneath us.
#
# Anything already sitting in the tty buffer at startup is drained and thrown
# away, so a stray report cannot be mistaken for input later.
drain_tty() {
    local _junk
    while read -rsn1 -t 0.01 _junk < /dev/tty 2>/dev/null; do :; done
}
drain_tty

POINTER_BASE=$(hyprctl cursorpos 2>/dev/null)

woke_up() {
    # The pointer, including touchpad taps and two-finger scroll. hyprctl can
    # fail transiently; an empty read is not a wake.
    local now
    now=$(hyprctl cursorpos 2>/dev/null)
    if [[ -n $now && -n $POINTER_BASE && $now != "$POINTER_BASE" ]]; then
        return 0
    fi

    # hyprlock came up underneath us -- the hard-lock listener fired, or the
    # session was locked from elsewhere. Nothing left to draw over.
    pidof hyprlock >/dev/null 2>&1 && return 0

    return 1
}

# Wall-clock budget for the saver itself. hypridle cannot own this deadline:
# mapping the saver's window resets the idle counter, so hypridle's hard-lock
# listener would restart counting from the moment the saver appeared. Tracking
# it here keeps "screensaver at 10 minutes, locked at 15" true regardless.
#
# Checked from inside the polling loops as well as the top of the outer loop --
# a single frame is an animation plus a hold, up to twenty seconds, and the
# lock should not wait that long past its deadline.
LOCK_AFTER=${TW_LOCK_AFTER:-300}
STARTED=$SECONDS

expired() { (( LOCK_AFTER > 0 && SECONDS - STARTED >= LOCK_AFTER )); }

# setsid because ctl.sh is about to SIGTERM this script on its way through
# cmd_stop, and the lock must outlive that.
escalate_to_lock() {
    setsid -f "$TW_DIR/ctl.sh" lock >/dev/null 2>&1 || true
    exit 0
}

# Wait up to $1 seconds, returning 1 immediately if the human came back.
wait_or_wake() {
    local deadline=$(( SECONDS + ${1%.*} ))
    while (( SECONDS < deadline )); do
        expired && escalate_to_lock
        woke_up && return 1
        sleep "$TW_POLL"
    done
    return 0
}

# --------------------------------------------------------------- the loop --
COLS=$(tput cols 2>/dev/null || echo 120)
ROWS=$(tput lines 2>/dev/null || echo 30)

hold_min=${TW_HOLD_MIN:-4}
hold_max=${TW_HOLD_MAX:-8}
hold_span=$(( hold_max - hold_min + 1 ))
(( hold_span < 1 )) && hold_span=1

while :; do
    expired && escalate_to_lock
    woke_up && break

    panel=$(draw_panel)

    # Terminal size can change under us if the monitor layout does.
    COLS=$(tput cols 2>/dev/null || echo "$COLS")
    ROWS=$(tput lines 2>/dev/null || echo "$ROWS")

    TW_DIR="$TW_DIR" TW_COLS="$COLS" TW_ROWS="$ROWS" TW_FILL="${TW_FILL:-█}" \
        timeout 10 "$TW_DIR/panels/$panel.sh" > "$FRAME" 2>/dev/null

    [[ -s $FRAME ]] || { printf 'thornwatch: %s produced nothing\n' "$panel" > "$FRAME"; }

    effect=${EFFECTS[$((RANDOM % ${#EFFECTS[@]}))]}

    # tte's parser is strictly ordered: global options, then the effect name,
    # then that effect's own options. Mixing them is an unrecognised-argument
    # error, not a reorder.
    args=(
        --input-file "$FRAME"
        --canvas-width 0 --canvas-height 0
        --anchor-canvas c --anchor-text c
        --terminal-background-color "${TW_BG:-191724}"
        --frame-rate 60
        --no-eol --no-restore-cursor
        "$effect"
    )
    if supports_gradient "$effect"; then
        # shellcheck disable=SC2206  -- word splitting is the point here
        stops=( $(tw_gradient) )
        args+=(
            --final-gradient-stops "${stops[@]}"
            --final-gradient-steps 12
            --final-gradient-direction "$(tw_gradient_dir)"
        )
    fi

    printf '\033[2J\033[H'

    # tte runs in the background so the watcher stays responsive during the
    # animation itself -- otherwise a mouse nudge would wait out the effect.
    "$TTE" "${args[@]}" &
    TTE_PID=$!

    woken=0
    while kill -0 "$TTE_PID" 2>/dev/null; do
        if expired; then kill "$TTE_PID" 2>/dev/null; escalate_to_lock; fi
        if woke_up; then woken=1; break; fi
        sleep "$TW_POLL"
    done

    if (( woken )); then
        kill "$TTE_PID" 2>/dev/null
        wait "$TTE_PID" 2>/dev/null
        TTE_PID=""
        break
    fi

    wait "$TTE_PID" 2>/dev/null
    TTE_PID=""

    wait_or_wake $(( hold_min + RANDOM % hold_span )) || break
done

# Reaching here means the pointer poll saw real motion (a TERM from `ctl.sh
# stop` would have gone through the trap instead, never returning to this
# line). hypridle may still be inside its post-start grace, so ask for the lock
# explicitly with --force. setsid detaches it: ctl.sh is about to SIGTERM this
# script's process group on its way through cmd_stop.
if ! pidof hyprlock >/dev/null 2>&1; then
    setsid -f "$TW_DIR/ctl.sh" wake --force >/dev/null 2>&1 || true
fi

exit 0
