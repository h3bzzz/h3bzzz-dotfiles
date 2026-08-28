#!/usr/bin/env bash
# ~/.config/hypr/thornwatch/ctl.sh
#
# The control surface. hypridle, the keybind and you all talk to this, never
# to thornwatch.sh directly.
#
#   start   bring the saver up (no-op if it is already up, or if locked)
#   stop    take it down and leave the session unlocked
#   wake    take it down and go to hyprlock -- this is the idle-resume path
#   lock    take it down and lock, without waiting for input
#   toggle  manual on/off, used by the keybind
#   status  print what is running
#   test    render one panel to stdout, for editing panels
#
set -uo pipefail

TW_DIR=${TW_DIR:-$HOME/.config/hypr/thornwatch}
# shellcheck source=/dev/null
[[ -r $TW_DIR/thornwatch.conf ]] && . "$TW_DIR/thornwatch.conf"

TW_CLASS=${TW_CLASS:-dev.h3bzzz.thornwatch}
RUNTIME=${XDG_RUNTIME_DIR:-/tmp}/thornwatch
PIDFILE=$RUNTIME/pid
STARTFILE=$RUNTIME/started_at
mkdir -p "$RUNTIME"

# Mapping a new window is itself an input event as far as Hyprland's idle
# notifier is concerned -- verified by isolating the three things cmd_start
# does: `brightnessctl -r` and `hyprctl dispatch focuswindow` produce nothing,
# spawning the ghostty surface produces a resume within a second.
#
# So hypridle sees the saver appear, calls this script's `wake`, and the saver
# tears itself down about a second after it was asked to start. This is the
# window in which a resume is assumed to be that echo rather than a human.
TW_WAKE_GRACE=${TW_WAKE_GRACE:-6}

log() { printf 'thornwatch: %s\n' "$*" >&2; }

running() {
    [[ -s $PIDFILE ]] || return 1
    local pid
    pid=$(<"$PIDFILE")
    [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null
}

locked() { pidof hyprlock >/dev/null 2>&1; }

# --------------------------------------------------------------------------
spawn_terminal() {
    local cmd=("$TW_DIR/thornwatch.sh")

    case ${TW_TERM:-ghostty} in
        ghostty)
            # gtk-single-instance=false matters: routed through an existing
            # instance the new surface inherits that instance's app-id and the
            # window rule never matches.
            ghostty \
                --class="$TW_CLASS" \
                --title=thornwatch \
                --gtk-single-instance=false \
                --initial-window=true \
                --quit-after-last-window-closed=true \
                --font-family="${TW_FONT_FAMILY:-monospace}" \
                --font-size="${TW_FONT_SIZE:-15}" \
                --background="#${TW_BG:-191724}" \
                --background-opacity=1 \
                --window-padding-x=0 \
                --window-padding-y=0 \
                --window-decoration=none \
                --cursor-style-blink=false \
                --mouse-hide-while-typing=true \
                --confirm-close-surface=false \
                --app-notifications=false \
                -e "${cmd[@]}" >/dev/null 2>&1 &
            ;;
        foot)
            foot \
                --app-id="$TW_CLASS" \
                --title=thornwatch \
                --font="${TW_FONT_FAMILY:-monospace}:size=${TW_FONT_SIZE:-15}" \
                --override="colors.background=${TW_BG:-191724}" \
                --override="colors.alpha=1.0" \
                --override="pad=0x0" \
                -- "${cmd[@]}" >/dev/null 2>&1 &
            ;;
        *)
            log "unknown TW_TERM '${TW_TERM}'"; return 1 ;;
    esac

    echo $! > "$PIDFILE"
}

# The rules.lua entry does the real work; this is the fallback for the case
# where the config has not been reloaded yet, and it also pulls focus so
# keystrokes land in the saver instead of whatever was underneath.
enforce_window() {
    local match="class:^(${TW_CLASS//./\\.})$" i
    for (( i = 0; i < 40; i++ )); do
        if hyprctl clients -j 2>/dev/null | grep -q "\"class\": \"$TW_CLASS\""; then
            # fullscreenstate sets an absolute state; `dispatch fullscreen`
            # is a toggle and would UNDO the rules.lua fullscreen when the
            # rule did fire. `pin` is floating-only, so it is left to the rule.
            hyprctl --batch "\
                dispatch focuswindow $match ; \
                dispatch fullscreenstate 2 2 ; \
                setprop $match noanim 1 ; \
                setprop $match norounding 1 ; \
                setprop $match noborder 1 ; \
                setprop $match nodim 1 ; \
                setprop $match opaque 1" >/dev/null 2>&1
            return 0
        fi
        sleep 0.1
    done
    return 1
}

# --------------------------------------------------------------------------
cmd_start() {
    if running; then log "already running"; return 0; fi
    if locked;  then log "session is locked, not starting"; return 0; fi

    # The dim listener fires at 5 minutes and the saver at 10, so without this
    # the effects would play at 20% brightness.
    if [[ ${TW_UNDIM:-1} == 1 ]]; then
        brightnessctl -r >/dev/null 2>&1 || true
    fi

    date +%s > "$STARTFILE"
    spawn_terminal || return 1
    enforce_window
}

# True while a resume is still plausibly the echo of our own window mapping.
in_wake_grace() {
    [[ -s $STARTFILE ]] || return 1
    local started now
    started=$(<"$STARTFILE")
    now=$(date +%s)
    (( now - started < TW_WAKE_GRACE ))
}

cmd_stop() {
    : > "$STARTFILE"
    # Kill the renderer first so it can restore the cursor and clear, then
    # take the window with it.
    pkill -TERM -f "$TW_DIR/thornwatch.sh" 2>/dev/null

    if running; then
        local pid
        pid=$(<"$PIDFILE")
        kill -TERM "$pid" 2>/dev/null
    fi
    : > "$PIDFILE"

    hyprctl dispatch closewindow "class:^(${TW_CLASS//./\\.})$" >/dev/null 2>&1
}

# One way in to the lock screen, for every caller.
#
# `loginctl lock-session` is used rather than running hyprlock here so logind
# records the session as locked and hypridle's own general.lock_cmd is the only
# place that actually spawns hyprlock. setsid is the fallback path and matters:
# hypridle reaps the `sh -c` it spawned for on-timeout, and a plain child would
# be torn down with it, leaving the session on a dead lock screen.
raise_lock() {
    pidof hyprlock >/dev/null 2>&1 && return 0
    loginctl lock-session 2>/dev/null && return 0
    setsid -f hyprlock >/dev/null 2>&1
}

# No grace here on purpose: the hard-lock listener is time-driven, not
# input-driven, so there is nothing to mistake for an echo.
cmd_lock() {
    : > "$STARTFILE"
    cmd_stop
    raise_lock
}

cmd_wake() {
    # Idle-resume path. Down, then straight to the lock screen -- the point of
    # the screensaver is that coming back means authenticating.
    #
    # `wake --force` is the renderer's own call, made when its pointer poll saw
    # real motion. It skips the grace check, which closes the hole the grace
    # would otherwise leave: a human touching the trackpad in the first few
    # seconds still lands on the lock screen.
    if [[ ${1:-} != --force ]] && in_wake_grace; then
        log "resume within ${TW_WAKE_GRACE}s of start, treating as our own window map"
        return 0
    fi
    : > "$STARTFILE"
    cmd_stop
    raise_lock
}

cmd_toggle() {
    if running; then cmd_stop; else cmd_start; fi
}

# Exit-code-only variant of status, for callers that want to branch on it --
# hypridle's dim listener uses it so a re-armed dim cannot darken a saver that
# is already up. (The saver's own window map resets the idle counter, so the
# five-minute dim listener does come around again while it is running.)
cmd_active() { running; }

cmd_status() {
    running && echo "saver: running (pid $(<"$PIDFILE"))" || echo "saver: stopped"
    locked  && echo "hyprlock: up" || echo "hyprlock: down"
    pgrep -x hypridle >/dev/null && echo "hypridle: up" || echo "hypridle: down"
}

cmd_test() {
    local panel=${1:-}
    if [[ -z $panel ]]; then
        echo "usage: ctl.sh test <panel>"
        echo "panels: $(cd "$TW_DIR/panels" && ls *.sh | sed 's/\.sh$//' | tr '\n' ' ')"
        return 1
    fi
    TW_DIR="$TW_DIR" \
    TW_COLS=$(tput cols 2>/dev/null || echo 120) \
    TW_ROWS=$(tput lines 2>/dev/null || echo 30) \
    TW_FILL="${TW_FILL:-█}" \
        "$TW_DIR/panels/$panel.sh"
}

case ${1:-toggle} in
    start)  cmd_start ;;
    stop)   cmd_stop ;;
    wake)   shift; cmd_wake "$@" ;;
    lock)   cmd_lock ;;
    toggle) cmd_toggle ;;
    active) cmd_active ;;
    status) cmd_status ;;
    test)   shift; cmd_test "$@" ;;
    *)      sed -n '4,20p' "$0"; exit 1 ;;
esac
