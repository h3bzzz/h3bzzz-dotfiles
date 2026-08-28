#!/usr/bin/env bash
# panels/forge.sh -- git working trees that are not clean. Anything with
# uncommitted work or unpushed commits shows up here; clean repos are noise
# and get counted, not listed.
set -uo pipefail
. "$TW_DIR/lib/layout.sh"

read -r -a ROOTS <<< "${TW_CODE_ROOTS:-$HOME/Code $HOME/.config}"

dirty=() clean=0

while IFS= read -r gitdir; do
    repo=${gitdir%/.git}
    branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD 2>/dev/null \
             || git -C "$repo" rev-parse --short HEAD 2>/dev/null) || continue

    changed=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l)
    ahead=$(git -C "$repo" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
    last=$(git -C "$repo" log -1 --format='%cr' 2>/dev/null)

    if (( changed == 0 && ahead == 0 )); then
        clean=$(( clean + 1 ))
        continue
    fi

    flags=""
    (( changed > 0 )) && flags+="${changed}~"
    (( ahead   > 0 )) && flags+="${ahead}↑"

    name=$(basename "$repo")
    (( ${#name}   > 22 )) && name="${name:0:21}…"
    (( ${#branch} > 16 )) && branch="${branch:0:15}…"

    dirty+=("$(printf '  ●  %-22s %-16s %-8s %s' \
        "$name" "$branch" "$flags" "${last:-—}")")
done < <(find "${ROOTS[@]}" -maxdepth 4 -type d -name .git 2>/dev/null)

{
    echo "${TW_C}FORGE"
    echo
    if (( ${#dirty[@]} == 0 )); then
        printf '  everything committed and pushed. %d clean repos.\n' "$clean"
    else
        printf '%s\n' "${dirty[@]}" | head -14
        printf '\n  %d dirty · %d clean\n' "${#dirty[@]}" "$clean"
    fi
} | tw_block
