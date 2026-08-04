#!/usr/bin/env bash
# Waybar notification module backed by dunst (the daemon actually running).
# Left-click: toggle Do-Not-Disturb. Right-click: pop last notification from history.
# Emits Waybar JSON: text (glyph), class (styled in style.css), tooltip.

waiting=$(dunstctl count waiting 2>/dev/null || echo 0)
displayed=$(dunstctl count displayed 2>/dev/null || echo 0)
count=$(( ${waiting:-0} + ${displayed:-0} ))
paused=$(dunstctl is-paused 2>/dev/null)

if [ "$paused" = "true" ]; then
    if [ "${count:-0}" -gt 0 ]; then
        printf '{"text":"󰂛","class":"dnd-notification","tooltip":"Do Not Disturb — %s waiting"}\n' "$count"
    else
        printf '{"text":"󰂛","class":"dnd-none","tooltip":"Do Not Disturb"}\n'
    fi
else
    if [ "${count:-0}" -gt 0 ]; then
        printf '{"text":"󰂚","class":"notification","tooltip":"%s notification(s) waiting"}\n' "$count"
    else
        printf '{"text":"󰂚","class":"none","tooltip":"No new notifications"}\n'
    fi
fi
