#!/usr/bin/env bash
# panels/lore.sh -- draw one card from data/lore.txt. Idle time is the only
# time this machine is not busy, so it may as well be revision.
set -uo pipefail
. "$TW_DIR/lib/layout.sh"

DECK=${TW_LORE_DECK:-$TW_DIR/data/lore.txt}
[[ -r $DECK ]] || { echo "no lore deck at $DECK"; exit 0; }

# Split on %% separator lines, dropping comments and empty records. \036 is a
# stand-in for the newline so each card survives as one mapfile element.
mapfile -t cards < <(awk '
    /^[[:space:]]*#/ { next }
    /^%%[[:space:]]*$/ { if (n) print rec; rec=""; n=0; next }
    { rec = rec $0 "\036"; if ($0 ~ /[^[:space:]]/) n=1 }
    END { if (n) print rec }
' "$DECK")

(( ${#cards[@]} == 0 )) && { echo "empty deck"; exit 0; }

mapfile -t lines < <(printf '%s' "${cards[$((RANDOM % ${#cards[@]}))]}" | tr '\036' '\n')

title=${lines[0]}
body=("${lines[@]:1}")

while (( ${#body[@]} )) && [[ -z ${body[0]//[[:space:]]/} ]];  do body=("${body[@]:1}"); done
while (( ${#body[@]} )) && [[ -z ${body[-1]//[[:space:]]/} ]]; do unset 'body[-1]'; done

# The rule spans the card, so it has to be measured before tw_block sees it.
width=${#title}
for line in "${body[@]}"; do
    (( ${#line} > width )) && width=${#line}
done

{
    echo "$title"
    printf '%s\n\n' "$(printf '─%.0s' $(seq 1 "$width"))"
    printf '%s\n' "${body[@]}"
} | tw_block
