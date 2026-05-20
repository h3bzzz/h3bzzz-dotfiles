#!/usr/bin/env bash

set -euo pipefail

picker_theme="$HOME/.config/rofi/wallpaper.rasi"
state_link="$HOME/.config/hypr/current-wallpaper"

mapfile -t wallpapers < <(
	python - <<'PY'
from pathlib import Path

home = Path.home()
roots = [home / "Pictures" / "wallpapers"]
exts = {".jpg", ".jpeg", ".png", ".webp"}

items = []
for root in roots:
	if not root.exists():
		continue
	for path in root.rglob("*"):
		if path.is_file() and path.suffix.lower() in exts:
			items.append(str(path))


for item in sorted(set(items), key=lambda p: (Path(p).name.lower(), p.lower())):
	print(item)
PY
)

if [[ ${#wallpapers[@]} -eq 0 ]]; then
	printf 'No wallpapers found under ~/Pictures/wallpapers\n' >&2
	exit 1
fi

current=""
if [[ -L "$state_link" || -e "$state_link" ]]; then
	current="$(readlink -f "$state_link")"
fi

chosen=$(
	for wallpaper in "${wallpapers[@]}"; do
		name="$(basename "$wallpaper")"
		if [[ "$wallpaper" == "$current" ]]; then
			display="Now $name"
		else
			display="     $name"
		fi
		printf '%s\0icon\x1f%s\x1fmeta\x1f%s\n' "$display" "$wallpaper" "$wallpaper"
	done | rofi -dmenu -i -show-icons -p "Wallpaper" -mesg "Pick from ~/Pictures/wallpapers" -theme "$picker_theme"
)

[[ -n "$chosen" ]] || exit 0

selected_name="${chosen#Now }"
selected_name="${selected_name#     }"

for wallpaper in "${wallpapers[@]}"; do
	if [[ "$(basename "$wallpaper")" == "$selected_name" ]]; then
		exec "$HOME/.config/hypr/scripts/set-wallpaper.sh" "$wallpaper"
	fi
done

printf 'Wallpaper selection not found: %s\n' "$selected_name" >&2
exit 1
