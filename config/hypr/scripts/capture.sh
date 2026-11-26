#!/usr/bin/env bash
# Screen capture beyond plain screenshots.
#
#   capture.sh ocr      select a region, copy the text in it (tesseract)
#   capture.sh qr       select a region, copy the QR / barcode payload (zbar)
#   capture.sh record   toggle a screen recording: first call asks for a
#                       region (Escape = whole focused monitor), second stops
#   capture.sh status   prints "recording" while one is running (for a bar)
#
# Everything degrades to a notification when a tool is missing rather than
# failing silently behind a keybind.

set -uo pipefail

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/rice-recording.pid"
OUTDIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/recordings"

say() { notify-send -a capture "$@"; }
need() {
    command -v "$1" >/dev/null 2>&1 && return 0
    say "Capture" "$1 is not installed (sudo pacman -S $2)"
    exit 1
}

recording() { [[ -f $PIDFILE ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }

case "${1:-}" in
    ocr)
        need tesseract "tesseract tesseract-data-eng"
        region=$(slurp) || exit 0
        text=$(grim -g "$region" - | tesseract stdin stdout -l "${OCR_LANG:-eng}" 2>/dev/null)
        text=${text%$'\n'}
        if [[ -n ${text//[[:space:]]/} ]]; then
            printf '%s' "$text" | wl-copy
            say "Text copied" "${text:0:200}"
        else
            say "OCR" "No text found in that region"
        fi
        ;;
    qr)
        need zbarimg zbar
        region=$(slurp) || exit 0
        data=$(grim -g "$region" - | zbarimg --quiet --raw - 2>/dev/null)
        if [[ -n $data ]]; then
            # --sensitive keeps a scanned secret (wifi password, OTP seed)
            # out of cliphist.
            printf '%s' "$data" | wl-copy --sensitive
            say "Code copied" "${data:0:200}"
        else
            say "QR" "No code found in that region"
        fi
        ;;
    record)
        if recording; then
            kill -INT "$(cat "$PIDFILE")"
            say "Recording saved" "$(cat "$PIDFILE.name" 2>/dev/null)"
            rm -f "$PIDFILE" "$PIDFILE.name"
            exit 0
        fi
        mkdir -p "$OUTDIR"
        file="$OUTDIR/$(date +%Y-%m-%d_%H-%M-%S).mp4"
        region=$(slurp 2>/dev/null) || region=""
        if command -v wf-recorder >/dev/null 2>&1; then
            if [[ -n $region ]]; then
                wf-recorder -g "$region" -f "$file" >/dev/null 2>&1 &
            else
                out=$(hyprctl monitors -j | python3 -c 'import json,sys; print(next(m["name"] for m in json.load(sys.stdin) if m["focused"]))')
                wf-recorder -o "$out" -f "$file" >/dev/null 2>&1 &
            fi
        elif command -v gpu-screen-recorder >/dev/null 2>&1; then
            if [[ -n $region ]]; then
                read -r pos size <<<"$region"
                gpu-screen-recorder -w region -region "${size}+${pos/,/+}" -f 60 -o "$file" >/dev/null 2>&1 &
            else
                gpu-screen-recorder -w screen -f 60 -o "$file" >/dev/null 2>&1 &
            fi
        else
            say "Capture" "No recorder installed (sudo pacman -S wf-recorder)"
            exit 1
        fi
        echo $! >"$PIDFILE"
        echo "$file" >"$PIDFILE.name"
        say "Recording started" "Press the record key again to stop"
        ;;
    status)
        recording && echo recording
        ;;
    *)
        echo "usage: capture.sh ocr|qr|record|status" >&2
        exit 2
        ;;
esac
