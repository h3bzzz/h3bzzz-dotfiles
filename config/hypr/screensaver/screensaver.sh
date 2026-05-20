#!/usr/bin/env bash

TTE="$HOME/.local/bin/tte"
TEXT="${1:-wake up h3bzzz, the Matrix has you...}"

trap 'exit 0' INT TERM

printf '\033]11;rgb:00/00/00\007'
printf '\033[?25l'

while true; do
	echo "$TEXT" | "$TTE" \
		--canvas-width 0 --canvas-height 0 \
		--anchor-canvas c --anchor-text c \
		--frame-rate 120 \
		--reuse-canvas --no-eol --no-restore-cursor \
		--random-effect \
		--exclude-effects colorshift randomsequence bouncyballs bubbles highlight expand middleout print
done
