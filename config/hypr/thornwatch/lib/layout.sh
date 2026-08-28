# ~/.config/hypr/thornwatch/lib/layout.sh
# Block-local centring for panels. Sourced, never executed.
#
# tte anchors the whole text block in the canvas for us, so a panel must not
# centre itself against the terminal width -- doing both shifts everything
# right by half the slack. What a panel actually wants is to centre its
# heading over its own content, which is what this does.
#
# Two markers, both stripped before output:
#
#   $TW_C   centre this line on its own, over the width of the whole block
#   $TW_G   centre this line as part of a group -- a run of consecutive $TW_G
#           lines shifts by one shared offset, so multi-line block type stays
#           rigid instead of each row wobbling to its own centre
#
# Everything unmarked is left-aligned and sets the block width.
#
#     { echo "${TW_C}SYSTEM VITALS"; echo; rows; } | tw_block

TW_C=$'\001'
TW_G=$'\002'

tw_block() {
    local -a lines=()
    local line body width=0 trimmed

    while IFS= read -r line || [[ -n $line ]]; do
        lines+=("$line")
        body=$line
        [[ ${body:0:1} == "$TW_C" || ${body:0:1} == "$TW_G" ]] && body=${body:1}
        trimmed=${body%"${body##*[![:space:]]}"}   # drop trailing blanks
        (( ${#trimmed} > width )) && width=${#trimmed}
    done

    local i=0 n=${#lines[@]}
    while (( i < n )); do
        line=${lines[i]}

        case ${line:0:1} in
        "$TW_C")
            body=${line:1}
            emit_centred "$body" "$width"
            (( i++ ))
            ;;
        "$TW_G")
            # Measure the whole run first, then shift every line in it by the
            # same amount.
            local j=$i group_width=0
            while (( j < n )) && [[ ${lines[j]:0:1} == "$TW_G" ]]; do
                body=${lines[j]:1}
                trimmed=${body%"${body##*[![:space:]]}"}
                (( ${#trimmed} > group_width )) && group_width=${#trimmed}
                (( j++ ))
            done
            local pad=$(( (width - group_width) / 2 ))
            (( pad < 0 )) && pad=0
            while (( i < j )); do
                body=${lines[i]:1}
                if [[ -z ${body//[[:space:]]/} ]]; then
                    echo
                else
                    printf '%*s%s\n' "$pad" '' "$body"
                fi
                (( i++ ))
            done
            ;;
        *)
            printf '%s\n' "$line"
            (( i++ ))
            ;;
        esac
    done
}

emit_centred() {  # emit_centred <text> <block-width>
    local text=$1 width=$2 pad
    if [[ -z ${text//[[:space:]]/} ]]; then echo; return; fi
    pad=$(( (width - ${#text}) / 2 ))
    (( pad < 0 )) && pad=0
    printf '%*s%s\n' "$pad" '' "$text"
}
