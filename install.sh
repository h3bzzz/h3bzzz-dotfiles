#!/usr/bin/env bash
#
# h3bzzz's Hyprland rice -- installer.
#
#   ./install.sh              deploy configs only
#   ./install.sh --deps       install packages first, then deploy
#   ./install.sh --deps-only  packages, no deploy
#
# The deploy step SYMLINKS this repo into ~/.config rather than copying it.
# That is deliberate: once linked, editing ~/.config/hypr/... *is* editing
# this repo, so `git status` here shows every change you make to the rice and
# nothing has to be synced back by hand.
#
# Target: Arch Linux + Hyprland. Other distros get a best-effort package pass
# and are otherwise on their own for the AUR-only pieces (matugen, quickshell).

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPERS="$HOME/Pictures/wallpapers"

BOLD=$'\e[1m'; DIM=$'\e[2m'; GRN=$'\e[32m'; YLW=$'\e[33m'; RED=$'\e[31m'; OFF=$'\e[0m'
say()  { printf '%s==>%s %s\n' "$BOLD" "$OFF" "$*"; }
ok()   { printf '    %s+%s %s\n' "$GRN" "$OFF" "$*"; }
warn() { printf '    %s!%s %s\n' "$YLW" "$OFF" "$*"; }
err()  { printf '    %sx%s %s\n' "$RED" "$OFF" "$*" >&2; }

DO_DEPS=false; DO_DEPLOY=true
for arg in "$@"; do
    case "$arg" in
        --deps)      DO_DEPS=true ;;
        --deps-only) DO_DEPS=true; DO_DEPLOY=false ;;
        -h|--help)   sed -n '3,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)           err "unknown option: $arg"; exit 1 ;;
    esac
done

# ── packages ─────────────────────────────────────────────────────────────

# Repo packages. imagemagick is not optional: theme-accents.py reads the
# wallpaper's histogram through `convert` to choose the accent hues.
PKGS_ARCH=(
    hyprland hyprpaper hyprlock hypridle xdg-desktop-portal-hyprland
    waybar rofi-wayland wofi swaync
    ghostty cava btop neovim tmux
    imagemagick jq python socat
    cliphist wl-clipboard grim slurp brightnessctl
    playerctl pavucontrol wireplumber
    blueman networkmanager thunar
    papirus-icon-theme ttf-jetbrains-mono-nerd noto-fonts-emoji
    zsh git curl
)
# AUR only. matugen drives the whole wallpaper->palette pipeline and
# quickshell renders the launcher and wallpaper wheel, so neither is optional.
PKGS_AUR=(matugen-bin quickshell)

aur_helper() {
    for h in yay paru; do command -v "$h" >/dev/null 2>&1 && { echo "$h"; return; }; done
}

install_deps() {
    if command -v pacman >/dev/null 2>&1; then
        say "Installing repo packages (pacman)"
        sudo pacman -S --needed --noconfirm "${PKGS_ARCH[@]}" || warn "some packages failed"

        local helper; helper="$(aur_helper)"
        if [ -n "$helper" ]; then
            say "Installing AUR packages ($helper)"
            "$helper" -S --needed --noconfirm "${PKGS_AUR[@]}" || warn "some AUR packages failed"
        else
            warn "No AUR helper (yay/paru) found."
            warn "matugen and quickshell are AUR-only and REQUIRED:"
            warn "  git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
            warn "  yay -S ${PKGS_AUR[*]}"
        fi
    else
        warn "Not an Arch system -- this rice targets Arch + Hyprland."
        warn "Install the equivalents of: ${PKGS_ARCH[*]}"
        warn "plus matugen and quickshell, then re-run without --deps."
    fi

    # terminaltexteffects powers the thornwatch screensaver panels.
    if ! command -v tte >/dev/null 2>&1; then
        if command -v pipx >/dev/null 2>&1; then
            pipx install terminaltexteffects >/dev/null 2>&1 && ok "tte (pipx)" \
                || warn "tte install failed; screensaver text effects will be skipped"
        else
            warn "tte not found. Install with: pipx install terminaltexteffects"
        fi
    fi

    # Oh My Zsh + Powerlevel10k + plugins, all sourced by config/zsh/.zshrc.
    local ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
    if [ ! -d "$ZSH_DIR" ]; then
        say "Installing Oh My Zsh"
        RUNZSH=no CHSH=no sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            >/dev/null 2>&1 && ok "oh-my-zsh" || warn "oh-my-zsh install failed"
    fi
    local CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
    clone_if_absent() {
        [ -d "$2" ] && return 0
        git clone --depth=1 "$1" "$2" >/dev/null 2>&1 && ok "$(basename "$2")" \
            || warn "clone failed: $1"
    }
    clone_if_absent https://github.com/romkatv/powerlevel10k.git             "$CUSTOM/themes/powerlevel10k"
    clone_if_absent https://github.com/zsh-users/zsh-autosuggestions.git     "$CUSTOM/plugins/zsh-autosuggestions"
    clone_if_absent https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM/plugins/zsh-syntax-highlighting"
    clone_if_absent https://github.com/zsh-users/zsh-completions.git         "$CUSTOM/plugins/zsh-completions"
}

# ── deploy ───────────────────────────────────────────────────────────────

# Link $1 -> $2, moving anything already there to .bak-<timestamp> first.
# An existing correct link is left alone, so re-running is a no-op.
STAMP="$(date +%Y%m%d-%H%M%S)"
link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        ok "$(basename "$dst") (already linked)"
        return 0
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv "$dst" "${dst}.bak-${STAMP}"
        warn "$(basename "$dst") existed -> $(basename "$dst").bak-${STAMP}"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    ok "$(basename "$dst")"
}

deploy() {
    say "Linking configs into $CONFIG"
    local d
    for d in "$DOTFILES"/config/*/; do
        d="${d%/}"
        [ "$(basename "$d")" = "zsh" ] && continue   # zsh lives in $HOME
        link "$d" "$CONFIG/$(basename "$d")"
    done

    say "Linking shell config into \$HOME"
    link "$DOTFILES/config/zsh/.zshrc"    "$HOME/.zshrc"
    link "$DOTFILES/config/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

    # Secrets stub. .zshrc sources this when present and .gitignore excludes
    # it, so machine-local keys never reach the repo.
    mkdir -p "$CONFIG/zsh"
    if [ ! -f "$CONFIG/zsh/secrets.zsh" ]; then
        cat > "$CONFIG/zsh/secrets.zsh" <<'STUB'
# Machine-local secrets. Gitignored -- never committed.
# export SOME_API_KEY="..."
STUB
        chmod 600 "$CONFIG/zsh/secrets.zsh"
        ok "secrets.zsh stub (gitignored)"
    fi

    say "Linking wallpapers"
    mkdir -p "$HOME/Pictures"
    link "$DOTFILES/wallpapers" "$WALLPAPERS"

    # Point the live-state link at something real so hyprpaper and hyprlock
    # have a background on the first boot.
    if [ ! -e "$CONFIG/hypr/current-wallpaper" ]; then
        local first
        first="$(find -L "$WALLPAPERS" -maxdepth 1 -type f \
                 \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) \
                 2>/dev/null | LC_ALL=C sort | head -1)"
        [ -n "$first" ] && ln -sfn "$first" "$CONFIG/hypr/current-wallpaper" \
            && ok "default wallpaper: $(basename "$first")"
    fi

    # Credential guard for anyone committing back to this repo.
    if git -C "$DOTFILES" rev-parse --git-dir >/dev/null 2>&1; then
        chmod +x "$DOTFILES/.githooks/"* 2>/dev/null
        git -C "$DOTFILES" config core.hooksPath .githooks 2>/dev/null \
            && ok "pre-commit secret guard enabled"
    fi
}

# ── theme ────────────────────────────────────────────────────────────────

# The palette files are generated, not tracked, so a fresh clone has none.
# waybar's style.css @imports colors.css and will not start without it.
generate_theme() {
    say "Generating the palette from the current wallpaper"
    if ! command -v matugen >/dev/null 2>&1; then
        err "matugen missing -- the palette cannot be generated."
        err "Install it (yay -S matugen-bin), then run:"
        err "  ~/.config/hypr/scripts/apply-theme.sh"
        return 1
    fi
    if bash "$DOTFILES/config/hypr/scripts/apply-theme.sh" >/dev/null 2>&1; then
        ok "waybar, rofi, ghostty, quickshell, swaync, btop and hyprland palettes written"
    else
        warn "apply-theme.sh failed; run it by hand once a wallpaper is set"
    fi
}

# ── monitors ─────────────────────────────────────────────────────────────

configure_monitors() {
    local settings="$DOTFILES/config/hypr/lua/settings.lua"
    local json
    if ! command -v hyprctl >/dev/null 2>&1 || ! json="$(hyprctl -j monitors 2>/dev/null)" \
       || [ "$(printf '%s' "$json" | jq 'length' 2>/dev/null || echo 0)" -lt 1 ]; then
        warn "Hyprland is not running -- leaving the monitor block as it is."
        warn "Once it is up:  hyprctl monitors   then edit lua/settings.lua"
        return 0
    fi
    say "Detected monitors"
    printf '%s' "$json" | jq -r '.[] | "    \(.name)  \(.width)x\(.height)@\(.refreshRate|round)  scale \(.scale)"'
    warn "settings.lua is tracked and is NOT rewritten automatically -- doing so"
    warn "would create a diff on every machine you install to. Copy the values"
    warn "above into its hl.monitor{} block if they differ."
}

# ── run ──────────────────────────────────────────────────────────────────

printf '%s\n' "${BOLD}h3bzzz's Hyprland rice${OFF}"
printf '%s\n\n' "${DIM}repo: $DOTFILES${OFF}"

$DO_DEPS && install_deps
if $DO_DEPLOY; then
    deploy
    generate_theme
    configure_monitors
fi

cat <<EOF

${BOLD}Done.${OFF}

  Reload      hyprctl reload
  Wallpapers  SUPER+W  (wheel picker; applying one re-themes the whole desktop)
  Shell       chsh -s \$(which zsh)   then log out and back in
  Neovim      run nvim once to let LazyVim install its plugins

  Your configs are symlinks into this repo, so anything you change shows up in
  \`git -C $DOTFILES status\`. Commit it when you want to keep it.
EOF
