#!/usr/bin/env bash
# panels/recon.sh -- the bug bounty board. One row per target directory under
# ~/bugs, sorted by how recently it was touched, so the screensaver doubles as
# a reminder of what is actually in flight.
#
# Walking those trees costs real time (some targets hold six figures of scan
# output), so the table is cached. The saver redraws every few seconds and the
# board does not change that fast.
set -uo pipefail
. "$TW_DIR/lib/layout.sh"

BUGS=${TW_BUGS_DIR:-$HOME/bugs}
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/thornwatch/recon
TTL=${TW_RECON_TTL:-900}

[[ -d $BUGS ]] || { echo "no target directory at $BUGS"; exit 0; }

build() {
    local now dir name newest files size age when mark
    now=$(date +%s)
    local -a rows=()

    for dir in "$BUGS"/*/; do
        [[ -d $dir ]] || continue
        name=$(basename "$dir")

        newest=$(find "$dir" -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -1)
        newest=${newest%%.*}
        [[ -z $newest ]] && newest=0

        files=$(find "$dir" -type f 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)

        if (( newest > 0 )); then
            age=$(( (now - newest) / 86400 ))
            case $age in
                0) when="today" ;;
                1) when="yesterday" ;;
                *) when="$age days ago" ;;
            esac
        else
            when="empty"
        fi

        rows+=("$newest|$name|$files|${size:-0}|$when|$age")
    done

    (( ${#rows[@]} == 0 )) && { echo "  no targets"; return; }

    printf '%s\n' "${rows[@]}" | sort -t'|' -k1,1rn | head -14 | \
    while IFS='|' read -r _ name files size when age; do
        # Freshness marker: anything touched inside a week is still warm.
        if   [[ $when == empty ]]; then mark="·"
        elif (( age < 7 ));       then mark="▶"
        else                           mark="▹"
        fi
        printf '  %s  %-16s %6s files  %7s   %s\n' "$mark" "$name" "$files" "$size" "$when"
    done

    printf '\n  %d targets tracked in %s\n' \
        "$(find "$BUGS" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)" \
        "${BUGS/#"$HOME"/\~}"
}

mkdir -p "$(dirname "$CACHE")"
if [[ ! -s $CACHE ]] || (( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) > TTL )); then
    build > "$CACHE.tmp" 2>/dev/null && mv "$CACHE.tmp" "$CACHE"
fi

{
    echo "${TW_C}RECON BOARD"
    echo
    cat "$CACHE"
} | tw_block
