#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
PICS_DIR="$HOME/Pictures"

echo "==> h3bzzz's Hyprland Dotfiles Installer"
echo "    Installing to: $CONFIG_DIR"
echo ""

# ── Helper: symlink or copy a file/directory ──────────────────────
link_or_copy() {
	local src="$1"
	local dst="$2"

	if [[ -e "$dst" || -L "$dst" ]]; then
		if [[ "$(readlink -f "$src")" == "$(readlink -f "$dst")" ]]; then
			return 0  # already correct
		fi
		echo "    Backing up $dst -> ${dst}.bak"
		mv "$dst" "${dst}.bak"
	fi

	mkdir -p "$(dirname "$dst")"
	ln -sfn "$src" "$dst"
}

# ── Detect distro / package manager ───────────────────────────────
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

# ── Parse flags ───────────────────────────────────────────────────
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

# ── Install dependencies ─────────────────────────────────────────
if $INSTALL_DEPS; then
	echo "==> Installing dependencies..."

	# Core
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

	# Optional: AUR helpers or external tools
	if command -v yay &>/dev/null; then
		yay -S --needed --noconfirm hyprshutdown 2>/dev/null || true
	elif command -v paru &>/dev/null; then
		paru -S --needed --noconfirm hyprshutdown 2>/dev/null || true
	fi

	# tte (terminal text effects) for screensaver
	if ! command -v tte &>/dev/null && [[ ! -f "$HOME/.local/bin/tte" ]]; then
		echo "    tte not found. Install manually from: https://github.com/nicoverbruggen/tte"
	fi

	echo ""
fi

# ── Deploy configurations ─────────────────────────────────────────
echo "==> Deploying configurations..."

# Hyprland
link_or_copy "$DOTFILES_DIR/config/hypr" "$CONFIG_DIR/hypr"

# Waybar
link_or_copy "$DOTFILES_DIR/config/waybar" "$CONFIG_DIR/waybar"

# Wofi
link_or_copy "$DOTFILES_DIR/config/wofi" "$CONFIG_DIR/wofi"

# Rofi
link_or_copy "$DOTFILES_DIR/config/rofi" "$CONFIG_DIR/rofi"

# Cava
link_or_copy "$DOTFILES_DIR/config/cava" "$CONFIG_DIR/cava"

# Wallpapers
mkdir -p "$PICS_DIR/wallpapers"
echo "    Copying wallpapers -> $PICS_DIR/wallpapers/"
cp -n "$DOTFILES_DIR"/wallpapers/* "$PICS_DIR/wallpapers/" 2>/dev/null || true

# Create current-wallpaper symlink to default wallpaper
DEFAULT_WALL="$PICS_DIR/wallpapers/a_skeleton_standing_on_a_pile_of_skulls.png"
if [[ -f "$DEFAULT_WALL" ]]; then
	ln -sfn "$DEFAULT_WALL" "$CONFIG_DIR/hypr/current-wallpaper"
	echo "    Set default wallpaper symlink"
fi

echo ""
echo "==> Done! Restart Hyprland or run 'hyprctl reload' to apply."
echo "    If things don't look right, verify the symlinks in $CONFIG_DIR"
echo "    and ensure all dependencies are installed."
