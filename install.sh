#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
PICS_DIR="$HOME/Pictures"

echo "==> h3bzzz's Hyprland Dotfiles Installer"
echo "    Installing to: $CONFIG_DIR"
echo ""

link_or_copy() {
	local src="$1"
	local dst="$2"

	if [[ -e "$dst" || -L "$dst" ]]; then
		if [[ "$(readlink -f "$src")" == "$(readlink -f "$dst")" ]]; then
			return 0
		fi
		echo "    Backing up $dst -> ${dst}.bak"
		mv "$dst" "${dst}.bak"
	fi

	mkdir -p "$(dirname "$dst")"
	ln -sfn "$src" "$dst"
}

install_pkg() {
	if command -v pacman &>/dev/null; then
		sudo pacman -S --needed --noconfirm "$@"
	elif command -v apt &>/dev/null; then
		sudo apt install -y "$@"
	elif command -v dnf &>/dev/null; then
		sudo dnf install -y "$@"
	elif command -v zypper &>/dev/null; then
		sudo zypper install -y "$@"
	else
		echo "    !! Could not detect package manager. Please install: $*"
	fi
}

INSTALL_DEPS=false
for arg in "$@"; do
	case "$arg" in
		--deps | --install-deps) INSTALL_DEPS=true ;;
		--help | -h)
			echo "Usage: $0 [--deps] [--help]"
			echo "  --deps   Also install required packages"
			exit 0
			;;
	esac
done

if $INSTALL_DEPS; then
	echo "==> Installing dependencies..."
	install_pkg hyprland hyprpaper hyprlock hypridle hyprlauncher
	install_pkg waybar wofi rofi-wayland
	install_pkg kitty ghostty
	install_pkg cava
	install_pkg swaync
	install_pkg cliphist wl-clipboard
	install_pkg jq python
	install_pkg playerctl pavucontrol wireplumber
	install_pkg blueman networkmanager
	install_pkg papirus-icon-theme
	install_pkg ttf-jetbrains-mono-nerd

	if command -v yay &>/dev/null; then
		yay -S --needed --noconfirm hyprshutdown 2>/dev/null || true
	elif command -v paru &>/dev/null; then
		paru -S --needed --noconfirm hyprshutdown 2>/dev/null || true
	fi

	if ! command -v tte &>/dev/null && [[ ! -f "$HOME/.local/bin/tte" ]]; then
		echo "    tte not found. Install from: https://github.com/nicoverbruggen/tte"
	fi

	echo ""
fi

echo "==> Deploying configurations..."

link_or_copy "$DOTFILES_DIR/config/hypr" "$CONFIG_DIR/hypr"
link_or_copy "$DOTFILES_DIR/config/waybar" "$CONFIG_DIR/waybar"
link_or_copy "$DOTFILES_DIR/config/wofi" "$CONFIG_DIR/wofi"
link_or_copy "$DOTFILES_DIR/config/rofi" "$CONFIG_DIR/rofi"
link_or_copy "$DOTFILES_DIR/config/cava" "$CONFIG_DIR/cava"
link_or_copy "$DOTFILES_DIR/config/nvim" "$CONFIG_DIR/nvim"
link_or_copy "$DOTFILES_DIR/config/kitty" "$CONFIG_DIR/kitty"

# Zsh (sourced from $HOME, not .config)
link_or_copy "$DOTFILES_DIR/config/zsh/.zshrc" "$HOME/.zshrc"
link_or_copy "$DOTFILES_DIR/config/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

mkdir -p "$PICS_DIR/wallpapers"
echo "    Copying wallpapers -> $PICS_DIR/wallpapers/"
cp -n "$DOTFILES_DIR"/wallpapers/* "$PICS_DIR/wallpapers/" 2>/dev/null || true

DEFAULT_WALL="$PICS_DIR/wallpapers/a_skeleton_standing_on_a_pile_of_skulls.png"
if [[ -f "$DEFAULT_WALL" ]]; then
	ln -sfn "$DEFAULT_WALL" "$CONFIG_DIR/hypr/current-wallpaper"
	echo "    Set default wallpaper symlink"
fi

# Auto-detect monitors and configure settings.lua
SETTINGS_LUA="$CONFIG_DIR/hypr/lua/settings.lua"
if command -v hyprctl &>/dev/null && MONITORS_JSON=$(hyprctl -j monitors 2>/dev/null) && [[ "$(echo "$MONITORS_JSON" | jq length 2>/dev/null)" -gt 0 ]]; then
	echo "==> Detecting monitors and updating settings.lua..."

	NEW_MONITOR_ENTRIES=$(echo "$MONITORS_JSON" | jq -r '.[] |
		"hl.monitor({\n\toutput = \"\(.name)\",\n\tmode = \"\(.width)x\(.height)@\(.refreshRate | round)\",\n\tposition = \"\(.x)x\(.y)\",\n\tscale = \(.scale),\n}"')

	sed -i '/^hl\.monitor({/,/^})/d' "$SETTINGS_LUA"

	{
		echo "$NEW_MONITOR_ENTRIES"
		echo ""
		cat "$SETTINGS_LUA"
	} > "${SETTINGS_LUA}.tmp" && mv "${SETTINGS_LUA}.tmp" "$SETTINGS_LUA"

	echo "    settings.lua updated with detected monitors."
else
	echo "==> hyprctl not available (Hyprland not running); keeping default placeholders."
	echo "    After starting Hyprland, edit $SETTINGS_LUA with: hyprctl monitors"
fi

echo ""
echo "==> Done! Restart Hyprland (or hyprctl reload) to apply."
echo "    Run nvim to trigger LazyVim plugin install."
