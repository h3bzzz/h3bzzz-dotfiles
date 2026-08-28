#!/usr/bin/env bash
# ~/.config/hypr/scripts/lock-session.sh
#
# The one place hyprlock is spawned. hypridle's general.lock_cmd points here,
# and everything else (the keybind, thornwatch's ctl.sh) reaches it through
# `loginctl lock-session`, which logind turns back into that lock_cmd.
#
# Why this exists rather than a semicolon-joined lock_cmd: the display-off step
# has to be measured from the moment of locking, and hypridle cannot express
# that. Its listeners are anchored to the idle clock, and that clock is not
# where the lock happens:
#
#   t=600   thornwatch maps its window. Mapping a window is an input event as
#           far as ext-idle-notify is concerned, so hypridle's clock RESETS.
#   t=900   thornwatch hits its own TW_LOCK_AFTER budget and locks. hypridle's
#           clock reads 300 here, not 900.
#   t=1530  only now does a 930s listener fire.
#
# So the "display off 30 seconds after lock" listener was really turning the
# screen off ten and a half minutes after lock -- the panel stayed lit on a
# locked, unattended machine for the entire window that mattered. The watchdog
# below is armed by the lock itself, so it measures from the right moment no
# matter which path got us here.

set -uo pipefail

RUNTIME=${XDG_RUNTIME_DIR:-/tmp}/thornwatch
TOKENFILE=$RUNTIME/lock_token
mkdir -p "$RUNTIME"

# Seconds between the lock screen appearing and the panel going dark. Short,
# but long enough to type a password without the screen dropping out mid-entry.
DPMS_DELAY=${LOCK_DPMS_DELAY:-30}

# Internal: the detached arm. Not reachable from the command line by accident,
# since it needs the token as its second argument.
if [[ ${1:-} == --dpms-watchdog ]]; then
    token=${2:?}
    sleep "$DPMS_DELAY"
    # Two conditions, both required. `pidof` alone is not enough: an unlock
    # followed by a fresh lock inside the delay window would leave this stale
    # watchdog firing into someone's password entry. The token is rewritten on
    # every lock, so only the newest watchdog still matches.
    [[ -r $TOKENFILE && $(<"$TOKENFILE") == "$token" ]] || exit 0
    pidof hyprlock >/dev/null 2>&1 || exit 0
    hyprctl dispatch dpms off >/dev/null 2>&1
    exit 0
fi

# Unlock path, called from hypridle's general.unlock_cmd. Invalidating the
# token is what retires any watchdog still counting down.
if [[ ${1:-} == unlocked ]]; then
    : > "$TOKENFILE"
    hyprctl dispatch dpms on >/dev/null 2>&1
    exit 0
fi

# ---------------------------------------------------------------- lock path --

# Tear the screensaver down before hyprlock draws, otherwise the lock screen
# stacks on top of a still-running fullscreen terminal.
~/.config/hypr/thornwatch/ctl.sh stop >/dev/null 2>&1

# Already locked: re-arm nothing, just leave. Spawning a second hyprlock is how
# you end up with a session you cannot get back into.
if pidof hyprlock >/dev/null 2>&1; then
    exit 0
fi

TOKEN="$(date +%s)-$RANDOM"
printf '%s' "$TOKEN" > "$TOKENFILE"

# setsid -f matters: hypridle reaps the `sh -c` it spawned for lock_cmd, and a
# plain background child would be torn down with it.
setsid -f "$0" --dpms-watchdog "$TOKEN" >/dev/null 2>&1

# Foreground on purpose, and deliberately NOT `exec`: hypridle and logind track
# the lock as held for as long as this process lives, and staying in the script
# means the teardown below runs the instant hyprlock returns -- which is the
# moment the password was accepted. That keeps the unlock cleanup self-
# contained rather than depending on logind's LockedHint reaching hypridle.
hyprlock
rc=$?

# Fallback. A hyprlock that dies immediately with a non-zero status did not
# lock anything -- a bad config, a missing font, a broken image path -- and
# without this the machine would simply sit unlocked and unattended, which is
# the one outcome this whole file exists to prevent. The retry uses a minimal
# config written from here, so it cannot fail the same way the user config did.
if (( rc != 0 )) && (( $(date +%s) - ${TOKEN%%-*} < 3 )); then
    FALLBACK=$RUNTIME/fallback.conf
    cat > "$FALLBACK" <<'CONF'
background { color = rgba(25, 23, 36, 1.0) }
input-field {
    size = 400, 56
    outer_color = rgba(196, 167, 231, 0.35)
    inner_color = rgba(31, 29, 46, 1.0)
    font_color  = rgba(224, 222, 244, 1.0)
    fail_color  = rgba(235, 111, 146, 1.0)
    rounding    = 14
    placeholder_text = enter password
    position = 0, -60
    halign = center
    valign = center
}
label {
    text = $TIME
    color = rgba(224, 222, 244, 1.0)
    font_size = 72
    position = 0, 60
    halign = center
    valign = center
}
CONF
    printf 'lock-session: hyprlock exited %d immediately, falling back\n' "$rc" >&2
    hyprlock -c "$FALLBACK"
    rc=$?
fi

# Retire the watchdog and make sure the panel is on. Both matter even when the
# unlock was clean: a watchdog may still be mid-sleep, and if it already fired
# the display is off and needs waking regardless of what unlocked us.
: > "$TOKENFILE"
hyprctl dispatch dpms on >/dev/null 2>&1

exit $rc
