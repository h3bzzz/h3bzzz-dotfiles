#!/usr/bin/env bash
# panels/vitals.sh -- machine state at a glance, drawn as a bar chart so it
# reads from across the room instead of needing to be parsed.
set -uo pipefail
. "$TW_DIR/lib/layout.sh"

rep() {  # rep <glyph> <count> -- printf '%.0s' emits once on an empty
         # argument list, so an explicit zero check is required.
    local n=$2
    (( n > 0 )) || return 0
    printf "$1%.0s" $(seq 1 "$n")
}

bar() {  # bar <percent> <width>
    local pct=$1 width=$2 filled
    (( pct < 0 ))   && pct=0
    (( pct > 100 )) && pct=100
    filled=$(( pct * width / 100 ))
    printf '%s%s' "$(rep '█' "$filled")" "$(rep '░' $(( width - filled )))"
}

row() {  # row <label> <percent> <detail>
    printf '  %-9s %s %3d%%   %s\n' "$1" "$(bar "$2" 34)" "$2" "${3:-}"
}

# --- gather -------------------------------------------------------------
read -r _ cpu_pct < <(awk '/^cpu /{
    idle=$5+$6; total=0; for(i=2;i<=NF;i++) total+=$i;
    printf "x %d\n", (total-idle)*100/total }' /proc/stat)

read -r mem_pct mem_detail < <(free -m | awk '/^Mem:/{
    printf "%d %.1fG / %.1fG\n", $3*100/$2, $3/1024, $2/1024 }')

read -r swap_pct swap_detail < <(free -m | awk '/^Swap:/{
    if ($2 == 0) { print "0 none"; exit }
    printf "%d %.1fG / %.1fG\n", $3*100/$2, $3/1024, $2/1024 }')

read -r disk_pct disk_detail < <(df -h / | awk 'NR==2{
    gsub("%","",$5); printf "%d %s / %s\n", $5, $3, $2 }')

load=$(cut -d' ' -f1-3 /proc/loadavg)
cores=$(nproc)

temp_c=0
for z in /sys/class/thermal/thermal_zone*; do
    [[ -r $z/type && -r $z/temp ]] || continue
    case $(<"$z/type") in
        *pkg*|*x86_pkg*|acpitz|*cpu*) temp_c=$(( $(<"$z/temp") / 1000 )); break ;;
    esac
done

bat=/sys/class/power_supply/BAT0
if [[ -r $bat/capacity ]]; then
    bat_pct=$(<"$bat/capacity")
    bat_state=$(<"$bat/status")
fi

# Bridges and container interfaces are noise here -- only the link that
# actually carries traffic is interesting.
net=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null \
      | awk -F: '$2!="loopback" && $2!="bridge" && $3 !~ /^(docker|br-|veth)/ {
            printf "%s ", $1 }')
ip4=$(ip -4 -o addr show scope global 2>/dev/null \
      | awk '$2 !~ /^(docker|br-|veth|virbr)/ { split($4,a,"/"); printf "%s ", a[1] }')

# --- draw ---------------------------------------------------------------
{
    echo "${TW_C}SYSTEM VITALS"
    echo
    row "cpu"  "$cpu_pct"  "load $load over $cores cores"
    row "mem"  "$mem_pct"  "$mem_detail"
    [[ $swap_detail == none ]] || row "swap" "$swap_pct" "$swap_detail"
    row "disk" "$disk_pct" "$disk_detail  on /"
    [[ -n ${bat_pct:-} ]] && row "battery" "$bat_pct" "$bat_state"
    echo
    printf '  %-9s %s\n' "thermal" "${temp_c}°C"
    printf '  %-9s %s\n' "network" "${net:-offline} ${ip4:-}"
    printf '  %-9s %s\n' "procs"   "$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)"
} | tw_block
