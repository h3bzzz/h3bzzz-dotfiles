#!/usr/bin/env bash
#
# h3bzzz's Hyprland rice -- installer.
#
# Zero-to-desktop on Arch Linux. From a minimal TTY install (base + user +
# sudo + network) this script takes you to a fully working Hyprland desktop:
# compositor, audio, bluetooth, networking, power, login manager, fonts,
# apps, shell, dev languages and the rice itself.
#
#   ./install.sh                          deploy configs only (asks copy/link)
#   ./install.sh --deps                   full wizard: packages + deploy
#   ./install.sh --deps-only               packages + services, no deploy
#   ./install.sh --copy / --link           deploy mode (otherwise asked)
#
# Unattended (sensible defaults + auto-detected CPU/GPU):
#
#   ./install.sh --deps --yes
#   ./install.sh --deps --yes --cpu=amd --gpu=amd --form=laptop \
#       --greeter=regreet --langs=all --extras=printing,firewall
#
# Options:
#   --deps            install system packages first, then deploy
#   --deps-only       install packages + enable services, skip deploy
#   --copy / --link   deploy mode (copy = standalone, link = tracked)
#   --yes             never prompt; use defaults / flag values / auto-detect
#   --cpu=amd|intel|auto
#   --gpu=amd|intel|nvidia|hybrid|vm|auto
#                     hybrid = intel iGPU + nvidia dGPU
#   --form=laptop|desktop|auto
#   --greeter=regreet|tuigreet|none
#                     regreet = graphical (themed, matches wallpaper)
#                     tuigreet = TUI (minimal, keyboard-only)
#   --bt=yes|no|auto  bluetooth stack (auto = yes on laptop)
#   --aur=yay|paru|auto|none
#   --langs=all|none|go,zig,node,python,rust,lua,c
#   --extras=none|printing,firewall,docker,ssh
#   --no-reboot       don't offer a reboot at the end
#   -h | --help       this text
#
# Two deploy modes, and the choice only matters afterwards:
#
#   copy  Files are copied into ~/.config. The rice is yours -- edit anything,
#         delete this clone, the desktop keeps working. Nothing you change ever
#         touches the repo. Re-running --copy overwrites the copies (the old
#         ones are backed up first), so pull-then-reinstall would discard local
#         edits: that is the trade for being unchained.
#
#   link  ~/.config/hypr and friends become symlinks into this repo, so editing
#         ~/.config/hypr/... *is* editing the clone and `git status` here shows
#         every change. Right if you intend to track or contribute the rice.
#
# Target: Arch Linux + Hyprland. Other distros get a best-effort warning and
# are otherwise on their own for the AUR-only pieces (matugen-bin).
#
# Sudo: you type your password ONCE at the start. A background keep-alive
# refreshes the timestamp so the rest of the run never re-prompts.

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPERS="$HOME/Pictures/wallpapers"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"
[ -n "${HOME:-}" ] && TARGET_HOME="$HOME" # we run as the user, not root

BOLD=$'\e[1m'
DIM=$'\e[2m'
GRN=$'\e[32m'
YLW=$'\e[33m'
RED=$'\e[31m'
OFF=$'\e[0m'
say() { printf '%s==>%s %s\n' "$BOLD" "$OFF" "$*"; }
ok() { printf '    %s+%s %s\n' "$GRN" "$OFF" "$*"; }
warn() { printf '    %s!%s %s\n' "$YLW" "$OFF" "$*"; }
err() { printf '    %sx%s %s\n' "$RED" "$OFF" "$*" >&2; }
die() {
    err "$*"
    exit 1
}

# ── CLI ──────────────────────────────────────────────────────────────────

DO_DEPS=false
DO_DEPLOY=true
MODE=""
ASSUME_YES=false
NO_REBOOT=false
WANT_CPU=""
WANT_GPU=""
WANT_FORM=""
WANT_GREETER=""
WANT_BT=""
WANT_AUR=""
WANT_LANGS=""
WANT_EXTRAS=""

usage() { sed -n '3,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

for arg in "$@"; do
    case "$arg" in
    --deps) DO_DEPS=true ;;
    --deps-only)
        DO_DEPS=true
        DO_DEPLOY=false
        ;;
    --copy) MODE=copy ;;
    --link) MODE=link ;;
    --yes) ASSUME_YES=true ;;
    --no-reboot) NO_REBOOT=true ;;
    --cpu=*) WANT_CPU="${arg#--cpu=}" ;;
    --gpu=*) WANT_GPU="${arg#--gpu=}" ;;
    --form=*) WANT_FORM="${arg#--form=}" ;;
    --greeter=*) WANT_GREETER="${arg#--greeter=}" ;;
    --bt=*) WANT_BT="${arg#--bt=}" ;;
    --aur=*) WANT_AUR="${arg#--aur=}" ;;
    --langs=*) WANT_LANGS="${arg#--langs=}" ;;
    --extras=*) WANT_EXTRAS="${arg#--extras=}" ;;
    -h | --help)
        usage
        exit 0
        ;;
    *) die "unknown option: $arg (see --help)" ;;
    esac
done

case "${WANT_CPU:-}" in "" | amd | intel | auto) ;; *) die "--cpu must be amd|intel|auto" ;; esac
case "${WANT_GPU:-}" in "" | amd | intel | nvidia | hybrid | vm | auto) ;; *) die "--gpu must be amd|intel|nvidia|hybrid|vm|auto" ;; esac
case "${WANT_FORM:-}" in "" | laptop | desktop | auto) ;; *) die "--form must be laptop|desktop|auto" ;; esac
case "${WANT_GREETER:-}" in "" | regreet | tuigreet | none) ;; *) die "--greeter must be regreet|tuigreet|none" ;; esac
case "${WANT_BT:-}" in "" | yes | no | auto) ;; *) die "--bt must be yes|no|auto" ;; esac
case "${WANT_AUR:-}" in "" | yay | paru | auto | none) ;; *) die "--aur must be yay|paru|auto|none" ;; esac

INTERACTIVE=false
[ -t 0 ] && [ "$ASSUME_YES" = false ] && INTERACTIVE=true

# ── prompt helpers ───────────────────────────────────────────────────────

ask_choice() { # ask_choice "Question" "default" "opt1" "opt2" ...
    local question="$1" def="$2"
    shift 2
    local opts=("$@") reply i
    if [ "$ASSUME_YES" = true ] || [ ! -t 0 ]; then
        printf '%s' "$def"
        return 0
    fi
    printf '\n%s%s%s\n\n' "$BOLD" "$question" "$OFF" >&2
    i=1
    for o in "${opts[@]}"; do
        printf '  %s%d%s  %s\n' "$BOLD" "$i" "$OFF" "$o" >&2
        i=$((i + 1))
    done
    printf '\n' >&2
    read -r -p "  Choice [${def}]: " reply >&2
    reply="${reply:-$def}"
    # accept either the number or the text itself
    if [[ "$reply" =~ ^[0-9]+$ ]] && [ "$reply" -ge 1 ] && [ "$reply" -le "${#opts[@]}" ]; then
        printf '%s' "${opts[$((reply - 1))]}"
    else
        printf '%s' "$reply"
    fi
}

ask_yesno() { # ask_yesno "Question" y|n  -> prints yes/no
    local question="$1" def="${2:-y}" reply
    if [ "$ASSUME_YES" = true ] || [ ! -t 0 ]; then
        [ "$def" = "y" ] && {
            printf 'yes'
            return 0
        }
        printf 'no'
        return 0
    fi
    local hint="[Y/n]"
    [ "$def" = "n" ] && hint="[y/N]"
    read -r -p "$(printf '%s%s%s %s ' "$BOLD" "$question" "$OFF" "$hint")" reply
    reply="${reply:-$def}"
    case "$reply" in y | Y | yes | YES) printf 'yes' ;; *) printf 'no' ;; esac
}

# ── auto-detect (used as wizard defaults and --yes values) ──────────────

detect_cpu() {
    if grep -qi 'AuthenticAMD' /proc/cpuinfo 2>/dev/null; then
        printf 'amd'
    elif grep -qi 'GenuineIntel' /proc/cpuinfo 2>/dev/null; then
        printf 'intel'
    else printf 'amd'; fi
}

detect_gpu() {
    local pci=""
    pci="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' || true)"
    local has_i=0 has_n=0 has_a=0
    grep -qi 'nvidia' <<<"$pci" && has_n=1
    grep -qi 'amd\|ati\|radeon' <<<"$pci" && has_a=1
    grep -qi 'intel' <<<"$pci" && has_i=1
    if [ "$has_i" = 1 ] && [ "$has_n" = 1 ]; then
        printf 'hybrid'
    elif [ "$has_n" = 1 ]; then
        printf 'nvidia'
    elif [ "$has_a" = 1 ]; then
        printf 'amd'
    elif [ "$has_i" = 1 ]; then
        printf 'intel'
    elif systemd-detect-virt -q 2>/dev/null; then
        printf 'vm'
    else printf 'amd'; fi
}

detect_form() {
    if [ -d /sys/class/power_supply ]; then
        if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
            printf 'laptop'
            return
        fi
    fi
    if command -v hostnamectl >/dev/null 2>&1; then
        local chassis
        chassis="$(hostnamectl status 2>/dev/null | grep -i chassis | awk '{print $2}' || true)"
        case "$chassis" in laptop | notebook | convertible | handset | tablet)
            printf 'laptop'
            return
            ;;
        esac
    fi
    printf 'desktop'
}

# ── wizard ───────────────────────────────────────────────────────────────
# Fills CPU/GPU/FORM/GREETER/WANT_BT/AUR/LANGS/EXTRAS. Flag values win;
# otherwise ask (interactive) or auto-detect (non-interactive).

CPU=""
GPU=""
FORM=""
GREETER=""
WANT_BT_FINAL=""
AUR_PREF=""
LANGS=""
EXTRAS=""

run_wizard() {
    local d_cpu d_gpu d_form
    d_cpu="$(detect_cpu)"
    d_gpu="$(detect_gpu)"
    d_form="$(detect_form)"

    if [ -n "$WANT_CPU" ] && [ "$WANT_CPU" != auto ]; then CPU="$WANT_CPU"; else
        [ "$INTERACTIVE" = true ] &&
            CPU="$(ask_choice "CPU vendor? (microcode + power tuning)" "$d_cpu" amd intel)" ||
            CPU="$d_cpu"
    fi
    if [ -n "$WANT_GPU" ] && [ "$WANT_GPU" != auto ]; then GPU="$WANT_GPU"; else
        [ "$INTERACTIVE" = true ] &&
            GPU="$(ask_choice "GPU? (drivers; hybrid = intel iGPU + nvidia dGPU)" "$d_gpu" amd intel nvidia hybrid vm)" ||
            GPU="$d_gpu"
    fi
    if [ -n "$WANT_FORM" ] && [ "$WANT_FORM" != auto ]; then FORM="$WANT_FORM"; else
        [ "$INTERACTIVE" = true ] &&
            FORM="$(ask_choice "Machine type? (laptop enables battery/backlight extras)" "$d_form" laptop desktop)" ||
            FORM="$d_form"
    fi

    # Bluetooth: auto = yes on laptops (Waybar BT tile + blueman need a stack),
    # no on desktops unless asked. The old installer shipped only `blueman`
    # with no bluez underneath, so clicking the tile did nothing.
    local d_bt="no"
    [ "$FORM" = laptop ] && d_bt="yes"
    if [ -n "$WANT_BT" ] && [ "$WANT_BT" != auto ]; then
        WANT_BT_FINAL="$WANT_BT"
    elif [ "$INTERACTIVE" = true ]; then
        local ans
        ans="$(ask_choice "Install bluetooth stack (bluez + blueman)?" "$d_bt" yes no)"
        WANT_BT_FINAL="$ans"
    else
        WANT_BT_FINAL="$d_bt"
    fi

    if [ -n "$WANT_GREETER" ]; then
        GREETER="$WANT_GREETER"
    elif [ "$INTERACTIVE" = true ]; then
        GREETER="$(ask_choice "Login manager? (regreet = themed GUI, tuigreet = minimal TUI)" "regreet" regreet tuigreet none)"
    else GREETER="regreet"; fi

    if [ -n "$WANT_AUR" ]; then
        AUR_PREF="$WANT_AUR"
    elif [ "$INTERACTIVE" = true ]; then
        AUR_PREF="$(ask_choice "AUR helper?" "auto" auto yay paru none)"
    else AUR_PREF="auto"; fi

    # Languages. Drives the dev-toolchain group below; matches what
    # config/nvim + config/zsh/.zshrc actually consume:
    #   go (gopls/gofumpt/delve), zig (zls via mason + zvm),
    #   node+typescript (ts_ls/prettier/eslint + pwa-node DAP),
    #   python (pyright/black/flake8 + pipx + uv),
    #   rust (rust-analyzer via rustaceanvim + clippy),
    #   lua (lua_ls/stylua on LuaJIT), c (clangd on clang).
    if [ -n "$WANT_LANGS" ]; then
        LANGS="$WANT_LANGS"
    elif [ "$INTERACTIVE" = true ]; then
        printf '\n%sLanguages / toolchains?%s (comma-separated, or all/none)\n' "$BOLD" "$OFF"
        printf '  go zig node python rust lua c\n\n'
        local reply
        read -r -p "  Choice [all]: " reply
        LANGS="${reply:-all}"
    else LANGS="all"; fi
    [ "$LANGS" = all ] && LANGS="go,zig,node,python,rust,lua,c"

    if [ -n "$WANT_EXTRAS" ]; then
        EXTRAS="$WANT_EXTRAS"
    elif [ "$INTERACTIVE" = true ]; then
        printf '\n%sOptional extras?%s (comma-separated, or none)\n' "$BOLD" "$OFF"
        printf '  printing  firewall  docker  ssh\n\n'
        local reply2
        read -r -p "  Choice [none]: " reply2
        EXTRAS="${reply2:-none}"
    else EXTRAS="none"; fi
}

langs_wanted() { # langs_wanted go -> 0/1
    [[ ",$LANGS," == *",$1,"* ]]
}
extras_wanted() {
    [[ ",$EXTRAS," == *",$1,"* ]]
}

# Nobody should get symlinked into a stranger's repo without saying so, and
# nobody should be prompted in a script. Ask when there is a terminal to ask
# on; otherwise keep the historical default.
choose_mode() {
    [ -n "$MODE" ] && return 0
    if [ "$INTERACTIVE" = false ]; then
        MODE=copy
        return 0
    fi

    printf '\n%sHow should the configs be installed?%s\n\n' "$BOLD" "$OFF"
    printf '  %s1%s  copy  -- files are copied into %s. Edit them freely;\n' "$BOLD" "$OFF" "$CONFIG"
    printf '           nothing links back to this clone, which you can delete.\n'
    printf '  %s2%s  link  -- symlink this repo into %s, so your edits\n' "$BOLD" "$OFF" "$CONFIG"
    printf '           land in `git status` here. For tracking/contributing.\n\n'
    local reply
    read -r -p "  Choice [1]: " reply
    case "${reply:-1}" in
    2 | l | link) MODE=link ;;
    *) MODE=copy ;;
    esac
    printf '\n'
}

# ── sudo: one prompt, then keep-alive ────────────────────────────────────

sudo_bootstrap() {
    command -v sudo >/dev/null 2>&1 || die "sudo is required (install it and add your user to wheel first)"
    say "Authenticating sudo (one prompt; kept alive for the whole run)"
    sudo -v || die "sudo authentication failed"
    # Refresh the timestamp every minute until this script exits.
    (while true; do
        sleep 50
        sudo -n true 2>/dev/null || exit
    done) &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

# ── packages ─────────────────────────────────────────────────────────────
# Every binary the rice shells out to is covered here. The previous list was
# missing the layers underneath several Waybar tiles and binds, which is why
# e.g. bluetooth/pavucontrol/wireplumber tiles and hyprshot/satty binds
# silently did nothing on a fresh install.

# Base build + rescue tools. base-devel covers gcc/make (nvim clangd fallback,
# treesitter parsers, AUR builds). reflector keeps mirrors fast.
# Core utilities (always installed -- tiny, no reason to gate behind a choice):
# rsync (_backups, OMZ rsync plugin), less (pager for man/bat/delta),
# tree (directory overviews), htop (alongside btop), usbutils/pciutils
# (lsusb/lspci -- lspci also powers the GPU auto-detect in the wizard).
PKGS_BASE=(
    base-devel git curl wget unzip zip rsync
    ripgrep fd fzf jq tree eza bat btop htop fastfetch
    man-db man-pages less usbutils pciutils
    reflector bash-completion
    polkit sudo openssh
)

# Microcode + CPU power. cpupower was explicitly requested: the service lets
# you set the governor (powersave/performance) and persists across reboots.
PKGS_CPU_COMMON=(cpupower lm_sensors)
PKGS_CPU_AMD=(amd-ucode)
PKGS_CPU_INTEL=(intel-ucode thermald)

# GPU. mesa/vulkan/icd loader are shared; the rest follows the wizard pick.
# nvidia on Hyprland additionally wants drm modeset=1 (we warn, never edit
# the bootloader for you).
PKGS_GPU_COMMON=(mesa vulkan-icd-loader libva libvdpau wayland-protocols wayland-utils)
PKGS_GPU_AMD=(xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa-vdpau)
PKGS_GPU_INTEL=(intel-media-driver libva-intel-driver vulkan-intel)
PKGS_GPU_NVIDIA=(nvidia nvidia-utils egl-wayland)
PKGS_GPU_VM=(xf86-video-vmware spice-vdagent)

# Compositor + portals + policy. Both portals are needed: -hyprland alone
# leaves file-pickers and screen-share without a backend. hyprpolkitagent is
# the auth dialog for privileged GUI actions (mounts, nm-editor changes).
PKGS_HYPRLAND=(
    hyprland hyprpaper hyprlock hypridle hyprshot hyprpicker hyprpolkitagent hyprcursor
    xdg-desktop-portal-hyprland xdg-desktop-portal xdg-desktop-portal-gtk
    qt5-wayland qt6-wayland
    waybar quickshell rofi-wayland wofi swaync
    ghostty
)

# Screenshots / clipboard / OSD / notifications. Each maps to a bind or an
# autostart entry: slurp+grim feed satty (SUPER+SHIFT+Print), swayimg is the
# gallery (SUPER+SHIFT+I), wl-clip-persist keeps clipboard after app close,
# cliphist+wl-clipboard power the history picker, wob draws the
# volume/brightness slider, libnotify provides notify-send.
PKGS_CAPTURE=(
    grim slurp satty swayimg hyprpicker
    cliphist wl-clipboard wl-clip-persist
    wob libnotify
)

# Audio. wireplumber ALONE is not a stack -- pipewire + compat layers are
# what actually move samples. pavucontrol is the Waybar click target,
# playerctl drives media keys + the mpris tile, alsa-utils gives amixer/aplay
# for debugging, helvum is the optional patchbay GUI.
PKGS_AUDIO=(
    pipewire pipewire-pulse pipewire-alsa pipewire-jack
    wireplumber alsa-utils pavucontrol playerctl helvum
)

# Network + bluetooth. network-manager-applet OWNS nm-connection-editor (the
# Waybar network click target -- `networkmanager` alone does not ship it).
# bluez+bluez-utils are the daemon/CLI under blueman-manager (the BT click
# target). Without them the tile renders but does nothing.
PKGS_NET=(networkmanager network-manager-applet wireless_tools wpa_supplicant)
PKGS_BT=(bluez bluez-utils blueman)

# Power. upower feeds Waybar's battery tile AND swaync idle hints;
# brightnessctl backs the backlight tile + binds; power-profiles-daemon is
# the modern governor switcher (powerprofilesctl); acpi/lm_sensors feed the
# thornwatch vitals panel and btop temperature.
PKGS_POWER=(upower brightnessctl power-profiles-daemon acpi cpupower lm_sensors)

# Login manager. greetd is the daemon in both modes; the frontend differs.
# cage is regreet's kiosk compositor. greetd-regreet is the package name
# (not `regreet`). The rice themes regreet to the wallpaper via
# /usr/local/bin/sync-greeter-wallpaper (deployed below).
PKGS_GREETD=(greetd cage greetd-regreet greetd-tuigreet)

# Fonts / icons / cursors / GTK look. Waybar/wofi/rofi glyphs come from the
# Nerd font + Font Awesome; emoji need noto-emoji; liberation covers office
# docs; papirus is the icon theme; nwg-look lets you preview GTK themes.
PKGS_FONTS=(
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    ttf-liberation otf-font-awesome
    papirus-icon-theme hyprcursor nwg-look gtk3 gtk4
)

# File manager + thumbnails. thunar alone cannot trash/mount/preview:
# gvfs (+mtp for phones) handles trash+mounts, tumbler+ffmpegthumbnailer draw
# previews, thunar-volman automounts, archive-plugin+file-roller handle zips.
PKGS_FILES=(
    thunar gvfs gvfs-mtp tumbler thunar-volman thunar-archive-plugin
    file-roller ffmpegthumbnailer
)

# Shell + CLI. Mirrors config/zsh/.zshrc plugins and every TUI in the rice:
# atuin (Ctrl-R), lazygit (lg), zoxide + z.lua (z), gh (gh plugin), nmap
# (nmap plugin), cava/btop/fastfetch (bar + greeter), yazi (+7zip/ffmpeg/
# poppler/chafa for previews), stylua/shfmt/shellcheck (same linters mason
# installs, so :checkhealth is green even before mason runs).
# NOTE: core utils (eza/bat/fd/ripgrep/fzf/jq/btop/fastfetch/rsync/man-db,
# tree/htop/less) live in PKGS_BASE above -- listed once, installed always.
# python-pipx is here (not in the python lang group) because `tte`
# (terminaltexteffects, thornwatch screensaver) is a RICE dependency, not a
# python-dev nicety -- it must install even with --langs excluding python.
PKGS_CLI=(
    zsh neovim tmux ghostty cava
    git-delta yazi glow go-yq direnv hyperfine
    atuin lazygit zoxide github-cli
    imagemagick python python-pipx socat tree-sitter-cli
    ffmpeg 7zip poppler chafa
    luajit lua luarocks
    stylua shfmt shellcheck
    nmap
)

# Languages, driven by config/nvim (mason-lspconfig-treesitter.lua servers +
# ensure_installed) and .zshrc PATH blocks. System packages provide the
# COMPILERS/RUNTIMES; mason then installs the LSPs/linters on first nvim run.
#   go     -> gopls/gofumpt/delve (go.nvim + dap-go expect `go` + `dlv`)
#   zig    -> zls via mason; zvm manages the compiler (author pins a dev build)
#   node   -> ts_ls/prettier/eslint_d + pwa-node DAP needs a real `node`
#   python -> pyright/black/flake8/debugpy + uv for project venvs
#            (pipx/tte live in PKGS_CLI -- rice dependency, always installed)
#   rust   -> rust-analyzer via rustaceanvim (rustup owns the toolchain) + clippy
#   lua    -> lua_ls/stylua on LuaJIT (hyprland.lua + yazi plugins)
#   c      -> clangd (config passes --clang-tidy, needs system clangd)
PKGS_LANG_GO=(go delve)
PKGS_LANG_ZIG=(zig)
PKGS_LANG_NODE=(nodejs npm pnpm bun typescript)
PKGS_LANG_PYTHON=(python python-pip uv ruff)
PKGS_LANG_RUST=(rustup clang llvm cmake ninja gdb)
PKGS_LANG_LUA=(lua luajit luarocks stylua)
PKGS_LANG_C=(clang cmake ninja gdb llvm)

PKGS_EXTRA_PRINTING=(cups cups-pdf system-config-printer)
PKGS_EXTRA_FIREWALL=(ufw)
PKGS_EXTRA_DOCKER=(docker docker-compose)
PKGS_EXTRA_SSH=(openssh)

# AUR. quickshell/hyprshutdown/wl-clip-persist have all moved to extra, so
# only the true AUR-only pieces remain: matugen (wallpaper->palette, REQUIRED
# -- waybar will not start without colors.css) and oh-my-posh-bin (prompt;
# has a manual binary fallback so it is best-effort, not fatal).
PKGS_AUR=(matugen-bin oh-my-posh-bin)

aur_helper() {
    case "$AUR_PREF" in
    yay | paru) command -v "${1:-$AUR_PREF}" >/dev/null 2>&1 && {
        echo "${1:-$AUR_PREF}"
        return
    } ;;
    esac
    for h in yay paru; do command -v "$h" >/dev/null 2>&1 && {
        echo "$h"
        return
    }; done
}

pacman_install() { # pacman_install "label" pkg...
    local label="$1"
    shift
    [ "$#" -eq 0 ] && return 0
    say "Installing $label (${#} packages)"
    # shellcheck disable=SC2068
    sudo pacman -S --needed --noconfirm $@ || warn "some $label packages failed -- re-run to retry"
}

ensure_aur_helper() {
    [ "$AUR_PREF" = none ] && return 1
    local want="" have=""
    have="$(aur_helper || true)"
    [ -n "$have" ] && {
        printf '%s' "$have"
        return 0
    }
    [ "$AUR_PREF" = auto ] && want="yay" || want="$AUR_PREF"
    [ "$want" = none ] && return 1
    if [ "$INTERACTIVE" = true ]; then
        local ans
        ans="$(ask_yesno "No AUR helper found. Build '$want' from the AUR?" y)"
        [ "$ans" = yes ] || return 1
    else
        say "No AUR helper found -- building $want (required for matugen)"
    fi
    local tmp
    tmp="$(mktemp -d)"
    git clone --depth=1 "https://aur.archlinux.org/${want}.git" "$tmp/$want" &&
        (cd "$tmp/$want" && makepkg -si --noconfirm) &&
        ok "$want built" || {
        warn "$want build failed"
        rm -rf "$tmp"
        return 1
    }
    rm -rf "$tmp"
    command -v "$want" >/dev/null 2>&1 && {
        printf '%s' "$want"
        return 0
    }
    return 1
}

install_deps() {
    command -v pacman >/dev/null 2>&1 ||
        {
            warn "Not an Arch system -- this rice targets Arch + Hyprland."
            return 1
        }

    # 0. refresh mirrors + db (reflector first so the rest is fast)
    say "Refreshing package databases"
    sudo pacman -Sy --noconfirm >/dev/null 2>&1 || warn "pacman -Sy failed; continuing with cached db"

    # 1. base
    pacman_install "base tools" "${PKGS_BASE[@]}"

    # 2. firmware / CPU / GPU
    local cpu_pkgs=("${PKGS_CPU_COMMON[@]}")
    [ "$CPU" = amd ] && cpu_pkgs+=("${PKGS_CPU_AMD[@]}")
    [ "$CPU" = intel ] && cpu_pkgs+=("${PKGS_CPU_INTEL[@]}")
    pacman_install "CPU microcode + power" "${cpu_pkgs[@]}"

    local gpu_pkgs=("${PKGS_GPU_COMMON[@]}")
    case "$GPU" in
    amd) gpu_pkgs+=("${PKGS_GPU_AMD[@]}") ;;
    intel) gpu_pkgs+=("${PKGS_GPU_INTEL[@]}") ;;
    nvidia) gpu_pkgs+=("${PKGS_GPU_NVIDIA[@]}") ;;
    hybrid) gpu_pkgs+=("${PKGS_GPU_INTEL[@]}" "${PKGS_GPU_NVIDIA[@]}") ;;
    vm) gpu_pkgs+=("${PKGS_GPU_VM[@]}") ;;
    esac
    pacman_install "GPU drivers ($GPU)" "${gpu_pkgs[@]}"
    if [[ "$GPU" == nvidia || "$GPU" == hybrid ]]; then
        warn "NVIDIA + Hyprland needs drm modeset: add nvidia_drm.modeset=1 to your"
        warn "bootloader kernel cmdline, then: sudo mkinitcpio -P (mkinitcpio) or"
        warn "rebuild your uki (systemd-boot/limine) before rebooting."
    fi
    if [ "$CPU" = amd ] || [ "$CPU" = intel ]; then
        warn "Microcode was installed -- ensure your bootloader loads it"
        warn "(GRUB: grub-mkconfig -o /boot/grub/grub.cfg; systemd-boot/limine: uki rebuild)."
    fi

    # 3. compositor + capture + audio + net/bt + power
    pacman_install "Hyprland desktop" "${PKGS_HYPRLAND[@]}"
    pacman_install "screenshots / clipboard / OSD" "${PKGS_CAPTURE[@]}"
    pacman_install "audio (pipewire)" "${PKGS_AUDIO[@]}"
    pacman_install "networking" "${PKGS_NET[@]}"
    if [ "$WANT_BT_FINAL" = yes ]; then
        pacman_install "bluetooth (bluez)" "${PKGS_BT[@]}"
    else
        say "Skipping bluetooth stack (per choice)"
    fi
    pacman_install "power + sensors" "${PKGS_POWER[@]}"

    # 4. login manager (ESSENTIAL -- without it you boot to a bare TTY)
    if [ "$GREETER" != none ]; then
        pacman_install "login manager (greetd)" "${PKGS_GREETD[@]}"
    else
        say "Skipping login manager (you will boot to a TTY; run Hyprland manually)"
    fi

    # 5. fonts / files / shell CLI
    pacman_install "fonts + icons" "${PKGS_FONTS[@]}"
    pacman_install "file manager" "${PKGS_FILES[@]}"
    pacman_install "shell + CLI tools" "${PKGS_CLI[@]}"

    # 6. languages (one group per opt-in, so --langs=go,python stays lean)
    langs_wanted go && pacman_install "Go toolchain" "${PKGS_LANG_GO[@]}"
    langs_wanted zig && pacman_install "Zig toolchain" "${PKGS_LANG_ZIG[@]}"
    langs_wanted node && pacman_install "Node/TypeScript toolchain" "${PKGS_LANG_NODE[@]}"
    langs_wanted python && pacman_install "Python + uv" "${PKGS_LANG_PYTHON[@]}"
    if langs_wanted rust; then pacman_install "Rust toolchain (rustup + clang)" "${PKGS_LANG_RUST[@]}"; fi
    langs_wanted lua && pacman_install "Lua toolchain" "${PKGS_LANG_LUA[@]}"
    if langs_wanted c; then
        # clang/cmake may already be in via rust; pacman --needed makes this free.
        pacman_install "C/C++ toolchain" "${PKGS_LANG_C[@]}"
    fi

    # 7. extras
    extras_wanted printing && pacman_install "printing" "${PKGS_EXTRA_PRINTING[@]}"
    extras_wanted firewall && pacman_install "firewall" "${PKGS_EXTRA_FIREWALL[@]}"
    extras_wanted docker && pacman_install "docker" "${PKGS_EXTRA_DOCKER[@]}"
    extras_wanted ssh && pacman_install "ssh" "${PKGS_EXTRA_SSH[@]}"

    # 8. AUR (matugen is REQUIRED -- waybar @imports its output)
    local helper=""
    helper="$(ensure_aur_helper || true)"
    if [ -n "$helper" ]; then
        say "Installing AUR packages ($helper): ${PKGS_AUR[*]}"
        "$helper" -S --needed --noconfirm "${PKGS_AUR[@]}" ||
            warn "some AUR packages failed -- matugen is REQUIRED, retry manually"
    else
        warn "No AUR helper -- matugen-bin is REQUIRED and AUR-only:"
        warn "  git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
        warn "  yay -S ${PKGS_AUR[*]}"
    fi
    # oh-my-posh fallback: upstream binary when the AUR package is unavailable.
    if ! command -v oh-my-posh >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        if curl -fsSL "https://cdn.ohmyposh.dev/releases/latest/posh-linux-amd64" \
            -o "$HOME/.local/bin/oh-my-posh" 2>/dev/null; then
            chmod +x "$HOME/.local/bin/oh-my-posh"
            ok "oh-my-posh (upstream binary)"
        else
            warn "oh-my-posh install failed; zsh falls back to powerlevel10k"
        fi
    fi

    install_shell_stack
    install_lang_post
    enable_services
}

install_shell_stack() {
    # terminaltexteffects powers the thornwatch screensaver panels
    # (config/hypr/thornwatch/thornwatch.sh resolves it via `command -v tte`
    # with fallbacks to ~/.local/bin/tte). python-pipx ships in PKGS_CLI so
    # this works on every --deps run, whatever --langs selected.
    if ! command -v tte >/dev/null 2>&1; then
        if command -v pipx >/dev/null 2>&1; then
            pipx install terminaltexteffects >/dev/null 2>&1 && ok "tte (pipx)" ||
                warn "tte install failed; screensaver text effects will be skipped"
            pipx ensurepath >/dev/null 2>&1 || true
        else
            warn "pipx missing -- tte not installed (deploy-only run? re-run with --deps)"
        fi
    fi
    # uv keeps a python toolchain independent of system upgrades (nvim dap-python
    # just calls `python3`, but project venvs via `uv` survive pacman -Syu).
    if command -v uv >/dev/null 2>&1; then
        ok "uv $(uv --version 2>/dev/null)"
    else
        warn "uv not found (expected from python group)"
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
        git clone --depth=1 "$1" "$2" >/dev/null 2>&1 && ok "$(basename "$2")" ||
            warn "clone failed: $1"
    }
    clone_if_absent https://github.com/romkatv/powerlevel10k.git "$CUSTOM/themes/powerlevel10k"
    clone_if_absent https://github.com/zsh-users/zsh-autosuggestions.git "$CUSTOM/plugins/zsh-autosuggestions"
    clone_if_absent https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM/plugins/zsh-syntax-highlighting"
    clone_if_absent https://github.com/zsh-users/zsh-completions.git "$CUSTOM/plugins/zsh-completions"
    # Plugins the .zshrc references beyond the stock OMZ set:
    clone_if_absent https://github.com/skywind3000/z.lua.git "$CUSTOM/plugins/zlua"
    # z.lua ships `z.lua.plugin.zsh`, but oh-my-zsh only sources
    # $ZSH_CUSTOM/plugins/zlua/zlua.plugin.zsh. Without this shim the plugin
    # is skipped silently and every shell start prints
    # "[oh-my-zsh] plugin 'zlua' not found".
    if [ ! -f "$CUSTOM/plugins/zlua/zlua.plugin.zsh" ]; then
        cat > "$CUSTOM/plugins/zlua/zlua.plugin.zsh" <<'EOF'
# zlua - oh-my-zsh loader shim (generated by install.sh, see the zlua clone above).
source "${0:A:h}/z.lua.plugin.zsh"
EOF
        ok "zlua loader shim"
    fi
    clone_if_absent https://github.com/Aloxaf/fzf-tab.git "$CUSTOM/plugins/fzf-tab"
    clone_if_absent https://github.com/wfxr/forgit.git "$CUSTOM/plugins/forgit"
    clone_if_absent https://github.com/MichaelAquilina/zsh-you-should-use.git "$CUSTOM/plugins/zsh-you-should-use"
    clone_if_absent https://github.com/zsh-users/zsh-history-substring-search.git "$CUSTOM/plugins/history-substring-search"
}

install_lang_post() {
    # rustup toolchains are per-user, not pacman packages.
    if langs_wanted rust && command -v rustup >/dev/null 2>&1; then
        if ! rustup toolchain list 2>/dev/null | grep -q stable; then
            say "Installing Rust stable toolchain"
            rustup default stable >/dev/null 2>&1 &&
                ok "rust stable" || warn "rustup toolchain install failed"
        fi
        rustup component add clippy rust-analyzer >/dev/null 2>&1 || true
    fi
    # Go env sanity (go.nvim + mason gopls expect GOPATH/bin on PATH --
    # .zshrc already exports it; just make sure the dir exists).
    if langs_wanted go && command -v go >/dev/null 2>&1; then
        mkdir -p "$HOME/go/bin"
        ok "go $(go version 2>/dev/null | awk '{print $3}')"
    fi
    # zvm (zig version manager) -- the .zshrc wires ~/.zvm/bin. The pacman
    # `zig` package already gives you a compiler; zvm is for pinning dev
    # builds like the author's /opt/zig_17_dev. Best-effort, never fatal.
    if langs_wanted zig && [ ! -d "$HOME/.zvm" ]; then
        if [ "$INTERACTIVE" = true ]; then
            local ans
            ans="$(ask_yesno "Install zvm (zig version manager)?" n)"
            [ "$ans" = yes ] && install_zvm || true
        else
            say "Skipping zvm bootstrap in unattended mode (pacman zig is installed)"
            say "To pin dev builds later: curl https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash"
        fi
    fi
    # node sanity: pacman nodejs already satisfies the pwa-node DAP adapter.
    if langs_wanted node && command -v node >/dev/null 2>&1; then
        ok "node $(node --version 2>/dev/null)"
    fi
    if langs_wanted python && command -v python3 >/dev/null 2>&1; then
        ok "python $(python3 --version 2>&1)"
    fi
}

install_zvm() {
    say "Installing zvm"
    if curl -fsSL https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash >/dev/null 2>&1; then
        ok "zvm"
    else
        warn "zvm install failed; pacman zig still works"
    fi
}

enable_services() {
    say "Enabling services"
    # System services. enable --now when already booted with systemd; plain
    # enable when chrooted / no systemd (install media) so nothing errors out.
    local sys_svcs=(NetworkManager)
    [ "$WANT_BT_FINAL" = yes ] && sys_svcs+=(bluetooth)
    sys_svcs+=(upower power-profiles-daemon)
    [ "$CPU" = intel ] && sys_svcs+=(thermald)
    [ "$GREETER" != none ] && sys_svcs+=(greetd)
    extras_wanted printing && sys_svcs+=(cups)
    extras_wanted firewall && sys_svcs+=(ufw)
    extras_wanted docker && sys_svcs+=(docker)
    extras_wanted ssh && sys_svcs+=(sshd)
    # Housekeeping timers are free wins on every machine.
    sys_svcs+=(reflector.timer fstrim.timer)

    local s
    for s in "${sys_svcs[@]}"; do
        if sudo systemctl enable "$s" >/dev/null 2>&1; then
            ok "$s (enabled)"
            # Best-effort start; fails harmlessly under chroot.
            sudo systemctl start "$s" >/dev/null 2>&1 || true
        else
            warn "$s could not be enabled (package may be missing)"
        fi
    done

    # Unblock bluetooth radios that ship soft-blocked (common on laptops).
    if [ "$WANT_BT_FINAL" = yes ] && command -v rfkill >/dev/null 2>&1; then
        sudo rfkill unblock bluetooth >/dev/null 2>&1 || true
    fi

    # Audio is per-user under systemd --user. Enabling here writes the
    # symlinks for the invoking user; starting is left to the first login so
    # a chrooted run does not fail.
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user enable pipewire pipewire-pulse wireplumber >/dev/null 2>&1 &&
            ok "pipewire user services (enabled)" ||
            warn "pipewire user services could not be enabled (no user bus yet -- they start on first login)"
    fi

    # Groups that matter on bare metal: video/render for DRM, input for
    # brightness keys without sudo, wheel is already the sudo group.
    for g in video render input; do
        getent group "$g" >/dev/null 2>&1 || continue
        id -nG "$USER" 2>/dev/null | grep -qw "$g" || sudo usermod -aG "$g" "$USER" >/dev/null 2>&1 || true
    done
    ok "user groups checked (video/render/input)"
}

# ── system files (greeter, sync hook, wob) ───────────────────────────────

deploy_system_files() {
    [ "$GREETER" = none ] && return 0
    say "Configuring login manager (greetd + $GREETER)"

    # --- /etc/greetd/config.toml ---
    sudo mkdir -p /etc/greetd
    if [ -f /etc/greetd/config.toml ] && [ ! -f /etc/greetd/config.toml.pre-rice ]; then
        sudo cp -f /etc/greetd/config.toml /etc/greetd/config.toml.pre-rice
    fi
    if [ "$GREETER" = regreet ]; then
        sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "dbus-run-session cage -s -mlast -d -- regreet"
user = "greeter"
EOF
    else
        sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-user-session --cmd Hyprland"
user = "greeter"

[initial_session]
command = "Hyprland"
user = "$TARGET_USER"
EOF
    fi
    ok "greetd config ($GREETER)"

    if [ "$GREETER" = regreet ]; then
        # --- regreet.toml: straight to the password prompt, wallpaper bg ---
        if [ -f /etc/greetd/regreet.toml ] && [ ! -f /etc/greetd/regreet.toml.pre-rice ]; then
            sudo cp -f /etc/greetd/regreet.toml /etc/greetd/regreet.toml.pre-rice
        fi
        sudo tee /etc/greetd/regreet.toml >/dev/null <<'EOF'
# ReGreet login screen -- matches the wallpaper via
# /usr/local/bin/sync-greeter-wallpaper (run on every theme change).
skip_selection = true

[background]
# Stable path: the sync script copies the current wallpaper here so the
# `greeter` user (no home access) can read it.
path = "/usr/share/backgrounds/greetd/current-wallpaper"
fit = "Cover"

[appearance]
greeting_msg = "welcome back."

[widget.clock]
format = "%H:%M\n%A %d %B"
resolution = "500ms"
label_width = 340

[GTK]
application_prefer_dark_theme = true
cursor_theme_name = "Adwaita"
cursor_blink = false
font_name = "JetBrainsMono Nerd Font 14"
icon_theme_name = "Adwaita"
theme_name = "Adwaita"

[commands]
reboot = ["systemctl", "reboot"]
poweroff = ["systemctl", "poweroff"]
EOF
        ok "regreet.toml"

        # --- regreet.css with matugen splice markers ---
        if [ ! -f /etc/greetd/regreet.css ]; then
            sudo tee /etc/greetd/regreet.css >/dev/null <<'EOF'
/* ReGreet stylesheet. The block between the markers is regenerated from the
   desktop wallpaper by /usr/local/bin/sync-greeter-wallpaper -- do not edit
   between the markers by hand. */

/* >>> matugen palette >>> */
/* <<< matugen palette <<< */
EOF
            ok "regreet.css (with palette markers)"
        else
            # Ensure the markers exist exactly once for the splice script.
            if ! sudo grep -q '>>> matugen palette >>>' /etc/greetd/regreet.css; then
                sudo tee -a /etc/greetd/regreet.css >/dev/null <<'EOF'

/* >>> matugen palette >>> */
/* <<< matugen palette <<< */
EOF
            fi
            ok "regreet.css (markers ensured)"
        fi

        deploy_greeter_sync
    fi
}

# Password-less wallpaper sync for the login screen. apply-theme.sh calls
# `sudo -n /usr/local/bin/sync-greeter-wallpaper`, so this sudoers rule is
# what lets the greeter follow the desktop without a password prompt.
deploy_greeter_sync() {
    say "Installing greeter wallpaper sync hook"
    local wall_link="$TARGET_HOME/.config/hypr/current-wallpaper"
    local palette_src="$TARGET_HOME/.config/hypr/colors.conf"
    sudo tee /usr/local/bin/sync-greeter-wallpaper >/dev/null <<EOF
#!/usr/bin/env bash
# Keep the greetd/regreet login screen following the desktop rice.
# Managed by h3bzzz-dotfiles install.sh -- safe to re-run the installer to regenerate.
set -uo pipefail

WALL_LINK="$wall_link"
PALETTE_SRC="$palette_src"
BG_DIR="/usr/share/backgrounds/greetd"
BG_FILE="\$BG_DIR/current-wallpaper"
CSS_TARGET="/etc/greetd/regreet.css"
BEGIN="/* >>> matugen palette >>> */"
END="/* <<< matugen palette <<< */"

wallpaper="\$(readlink -f "\$WALL_LINK" 2>/dev/null)"
if [[ -n "\$wallpaper" && -f "\$wallpaper" ]]; then
    mkdir -p "\$BG_DIR" 2>/dev/null
    if cp -f "\$wallpaper" "\$BG_FILE" 2>/dev/null && chmod 644 "\$BG_FILE" 2>/dev/null; then
        printf 'sync-greeter-wallpaper: copied %s\\n' "\$wallpaper"
    else
        printf 'sync-greeter-wallpaper: could not copy wallpaper\\n' >&2
    fi
else
    printf 'sync-greeter-wallpaper: no current wallpaper; background left alone\\n' >&2
fi

make_palette_block() {
    awk '
        /^[$][A-Za-z0-9_]+[[:space:]]*=[[:space:]]*rgba?\\(/ {
            name = \$1; sub(/^[$]/, "", name)
            sub(/^[^=]*=[[:space:]]*/, "")
            printf "  --%s: %s;\\n", name, \$0
        }
    ' "\$PALETTE_SRC"
}

if [[ ! -f "\$PALETTE_SRC" || ! -f "\$CSS_TARGET" ]]; then
    printf 'sync-greeter-wallpaper: palette or stylesheet missing; palette not spliced\\n' >&2
    exit 0
fi

block="\$(make_palette_block)"
if [[ -z "\$block" ]]; then
    printf 'sync-greeter-wallpaper: no palette colours found; stylesheet left alone\\n' >&2
    exit 0
fi

payload=":root {"\$'\\n'"\$block}"\$'\\n'}
tmp="\$(mktemp "\${CSS_TARGET%.css}.XXXXXX")" || exit 1
{
    sed -n '1,\\|'"\$BEGIN"'|p' "\$CSS_TARGET" | sed "\\|\$BEGIN|d"
    printf '%s\\n' "\$payload"
    sed -n '\\|'"\$END"'|,\$p' "\$CSS_TARGET" | sed "\\|\$END|d"
} > "\$tmp" || { rm -f "\$tmp"; exit 1; }

if mv -f "\$tmp" "\$CSS_TARGET"; then
    n="\$(printf '%s\\n' "\$block" | grep -c -- '--' || true)"
    printf 'sync-greeter-wallpaper: spliced %s palette entries into %s\\n' "\$n" "\$CSS_TARGET"
else
    rm -f "\$tmp"
    printf 'sync-greeter-wallpaper: could not update %s\\n' "\$CSS_TARGET" >&2
    exit 1
fi
exit 0
EOF
    sudo chmod 755 /usr/local/bin/sync-greeter-wallpaper
    sudo tee "/etc/sudoers.d/10-greeter-wallpaper" >/dev/null <<EOF
# Let $TARGET_USER refresh the login-screen wallpaper/palette without a password.
# Managed by h3bzzz-dotfiles install.sh.
$TARGET_USER ALL=(root) NOPASSWD: /usr/local/bin/sync-greeter-wallpaper
EOF
    sudo chmod 440 "/etc/sudoers.d/10-greeter-wallpaper"
    sudo visudo -c -q 2>/dev/null && ok "greeter sync hook (password-less)" ||
        {
            warn "sudoers check failed -- removing rule"
            sudo rm -f "/etc/sudoers.d/10-greeter-wallpaper"
        }
    sudo mkdir -p /usr/share/backgrounds/greetd
}

deploy_wob_config() {
    # wob has no default config; without wob.ini the volume/brightness OSD
    # silently never appears. Colours are Rose Pine defaults -- apply-theme
    # does not manage this file, edit freely.
    local wob_ini="$CONFIG/wob/wob.ini"
    if [ ! -f "$wob_ini" ]; then
        mkdir -p "$(dirname "$wob_ini")"
        cat >"$wob_ini" <<'EOF'
# wob OSD -- spawned per-session by ~/.config/hypr/scripts/osd-wob.sh.
# volume.sh / brightness.sh write slider values into the per-instance fifo.
anchor = "bottom"
margin = 32
width = 320
height = 28
border_size = 2
border_offset = 4
bar_padding = 4
border_color = "26233aFF"
background_color = "191724EE"
bar_color = "31748fee"
overflow_background_color = "1f1d2eEE"
overflow_bar_color = "c4a7e7ee"
overflow_mode = "wrap"
EOF
        ok "wob.ini (OSD bar)"
    fi
}

# ── deploy ───────────────────────────────────────────────────────────────

STAMP="$(date +%Y%m%d-%H%M%S)"

# Move whatever is at $1 out of the way, once, into .bak-<timestamp>.
backup() {
    local dst="$1"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv "$dst" "${dst}.bak-${STAMP}"
        warn "$(basename "$dst") existed -> $(basename "$dst").bak-${STAMP}"
    fi
}

# Link $1 -> $2. An existing correct link is left alone, so re-running is a
# no-op.
link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        ok "$(basename "$dst") (already linked)"
        return 0
    fi
    backup "$dst"
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    ok "$(basename "$dst")"
}

# Copy $1 -> $2, dereferencing so the result contains no path back into the
# repo. Unlike link() this cannot be idempotent: the destination is the user's
# to edit, so an existing one is always backed up rather than silently kept.
copy() {
    local src="$1" dst="$2"
    backup "$dst"
    mkdir -p "$(dirname "$dst")"
    cp -RL --preserve=mode "$src" "$dst"
    ok "$(basename "$dst")"
}

place() { if [ "$MODE" = link ]; then link "$@"; else copy "$@"; fi; }

deploy() {
    if [ "$MODE" = link ]; then
        say "Linking configs into $CONFIG"
    else
        say "Copying configs into $CONFIG"
    fi
    local d
    for d in "$DOTFILES"/config/*/; do
        d="${d%/}"
        [ "$(basename "$d")" = "zsh" ] && continue # zsh lives in $HOME
        place "$d" "$CONFIG/$(basename "$d")"
    done

    say "Installing shell config into \$HOME"
    place "$DOTFILES/config/zsh/.zshrc" "$HOME/.zshrc"
    place "$DOTFILES/config/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

    # Wallpaper-tracking shell colours (fzf, eza, bat, LS_COLORS). Lives under
    # $CONFIG rather than $HOME because .zshrc sources it by that path.
    mkdir -p "$CONFIG/zsh"
    place "$DOTFILES/config/zsh/shell-theme.zsh" "$CONFIG/zsh/shell-theme.zsh"

    # Secrets stub. .zshrc sources this when present and .gitignore excludes
    # it, so machine-local keys never reach the repo.
    mkdir -p "$CONFIG/zsh"
    if [ ! -f "$CONFIG/zsh/secrets.zsh" ]; then
        cat >"$CONFIG/zsh/secrets.zsh" <<'STUB'
# Machine-local secrets. Gitignored -- never committed.
# export SOME_API_KEY="..."
STUB
        chmod 600 "$CONFIG/zsh/secrets.zsh"
        ok "secrets.zsh stub (gitignored)"
    fi

    # fastfetch's Lua sandbox exposes no `os`, `io` or `package`, so a theme
    # cannot work out where it lives -- every dofile() and the palette load in
    # lib/rp.lua spell the path out in full. Rewrite them for this $HOME. Only
    # touches the copies under $CONFIG, never the repo.
    if [ -d "$CONFIG/fastfetch" ]; then
        ff_real="$(readlink -f "$CONFIG/fastfetch")"
        if grep -rqs "/home/h3bzzz/.config/fastfetch" "$ff_real" 2>/dev/null &&
            [ "$HOME" != "/home/h3bzzz" ]; then
            grep -rls "/home/h3bzzz/.config/fastfetch" "$ff_real" 2>/dev/null |
                while IFS= read -r f; do
                    sed -i "s|/home/h3bzzz/.config/fastfetch|$HOME/.config/fastfetch|g" "$f"
                done
            ok "fastfetch paths rewritten for $HOME"
        fi
    fi

    deploy_wob_config

    say "Installing wallpapers"
    mkdir -p "$HOME/Pictures"
    if [ "$MODE" = link ]; then
        link "$DOTFILES/wallpapers" "$WALLPAPERS"
    else
        # ~84 MB of images. Merge rather than replace: a standalone user's own
        # wallpapers live here too and must survive a re-run.
        mkdir -p "$WALLPAPERS"
        cp -RLn "$DOTFILES/wallpapers/." "$WALLPAPERS/" 2>/dev/null
        ok "wallpapers -> $WALLPAPERS (existing files kept)"
    fi

    # Point the live-state link at something real so hyprpaper and hyprlock
    # have a background on the first boot.
    if [ ! -e "$CONFIG/hypr/current-wallpaper" ]; then
        local first
        first="$(find -L "$WALLPAPERS" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) \
            2>/dev/null | LC_ALL=C sort | head -1)"
        [ -n "$first" ] && ln -sfn "$first" "$CONFIG/hypr/current-wallpaper" &&
            ok "default wallpaper: $(basename "$first")"
    fi

    # Credential guard, for the tracked install only -- a copy install never
    # commits back, so the repo's hooks are none of its business.
    if [ "$MODE" = link ] && git -C "$DOTFILES" rev-parse --git-dir >/dev/null 2>&1; then
        chmod +x "$DOTFILES/.githooks/"* 2>/dev/null
        git -C "$DOTFILES" config core.hooksPath .githooks 2>/dev/null &&
            ok "pre-commit secret guard enabled"
    fi
}

# ── theme ────────────────────────────────────────────────────────────────

# The palette files are generated, not tracked, so a fresh clone has none.
# waybar's style.css @imports colors.css and will not start without it.
# Ghostty's `theme = matugen` needs ghostty/themes/matugen, and the zsh
# prompt needs ~/.config/oh-my-posh/config.json -- all three come out of
# apply-theme.sh. A missing one means a broken bar, a ghostty error toast,
# or a shell that silently falls back to p10k, so verify each output here.
# apply-theme.sh only ever addresses ~/.config, so the installed copy is the
# one to run in either mode.
generate_theme() {
    say "Generating the palette from the current wallpaper"
    if ! command -v matugen >/dev/null 2>&1; then
        err "matugen missing -- the palette cannot be generated."
        err "Install it (yay -S matugen-bin), then run:"
        err "  ~/.config/hypr/scripts/apply-theme.sh"
        return 1
    fi
    mkdir -p "$CONFIG/oh-my-posh"
    if bash "$CONFIG/hypr/scripts/apply-theme.sh" >/dev/null 2>&1; then
        ok "waybar, rofi, ghostty, quickshell, swaync, btop, fastfetch and hyprland palettes written"
        local theme_missing=0
        for f in "$CONFIG/waybar/colors.css" \
            "$CONFIG/ghostty/themes/matugen" \
            "$CONFIG/oh-my-posh/config.json"; do
            if [ -s "$f" ]; then ok "$(basename "$f")"; else
                warn "MISSING generated file: $f"
                theme_missing=1
            fi
        done
        [ "$theme_missing" -eq 0 ] || warn "re-run ~/.config/hypr/scripts/apply-theme.sh by hand"
        # Push the fresh wallpaper + palette to the login screen, if configured.
        if command -v sync-greeter-wallpaper >/dev/null 2>&1; then
            env -u TERMINFO sudo -n /usr/local/bin/sync-greeter-wallpaper >/dev/null 2>&1 &&
                ok "login screen synced" || true
        fi
    else
        warn "apply-theme.sh failed; run it by hand once a wallpaper is set"
        return 1
    fi
}

# ── shell landing ──────────────────────────────────────────────────────────
# Goal: first ghostty window opens zsh with the oh-my-posh prompt and zero
# errors. Ghostty already forces `command = /usr/bin/zsh`, so the login shell
# is belt-and-braces -- but every ghostty tab still sources ~/.zshrc, and a
# single missing OMZ plugin prints "[oh-my-zsh] plugin not found" on EVERY
# new tab. Audit the exact plugin list .zshrc declares, then smoke-test a
# real interactive zsh before declaring victory.

REQUIRED_OMZ_CUSTOM=(powerlevel10k zsh-autosuggestions zsh-syntax-highlighting
    zsh-completions zlua fzf-tab forgit zsh-you-should-use history-substring-search)

ensure_login_shell() {
    local zsh_bin
    zsh_bin="$(command -v zsh || true)"
    [ -n "$zsh_bin" ] || {
        warn "zsh not installed -- login shell unchanged"
        return 1
    }
    if [ "${SHELL:-}" = "$zsh_bin" ]; then
        ok "login shell already zsh"
        return 0
    fi
    if chsh -s "$zsh_bin" >/dev/null 2>&1; then
        ok "login shell -> $zsh_bin (takes effect on next login)"
    else
        warn "chsh failed; run by hand: chsh -s $zsh_bin"
    fi
    # Ghostty does not depend on $SHELL (command = /usr/bin/zsh), but TTY
    # logins and `tuigreet --cmd` fall back to it, so a stale /bin/bash here
    # is how you land in bash on the first boot.
    if [ -x /usr/bin/zsh ] && ! grep -q '^/usr/bin/zsh' /etc/shells 2>/dev/null; then
        warn "/usr/bin/zsh not in /etc/shells (unexpected on Arch)"
    fi
}

verify_shell() {
    say "Verifying ghostty + zsh + oh-my-posh landing"
    local fail=0
    command -v ghostty >/dev/null 2>&1 && ok "ghostty" || {
        warn "MISSING: ghostty"
        fail=1
    }
    command -v zsh >/dev/null 2>&1 && ok "zsh $(zsh --version 2>/dev/null)" || {
        warn "MISSING: zsh"
        fail=1
    }
    command -v oh-my-posh >/dev/null 2>&1 && ok "oh-my-posh $(oh-my-posh --version 2>/dev/null)" ||
        {
            warn "MISSING: oh-my-posh (prompt falls back to p10k)"
            fail=1
        }
    [ -s "$CONFIG/oh-my-posh/config.json" ] && ok "oh-my-posh config" ||
        {
            warn "MISSING: $CONFIG/oh-my-posh/config.json (prompt falls back to p10k)"
            fail=1
        }
    [ -s "$CONFIG/ghostty/themes/matugen" ] && ok "ghostty theme (matugen)" ||
        {
            warn "MISSING: $CONFIG/ghostty/themes/matugen (ghostty error toast)"
            fail=1
        }
    [ -d "${ZSH:-$HOME/.oh-my-zsh}" ] && ok "oh-my-zsh" || {
        warn "MISSING: ~/.oh-my-zsh"
        fail=1
    }
    local ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}" CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}" p where stock
    for p in "${REQUIRED_OMZ_CUSTOM[@]}"; do
        if [ "$p" = powerlevel10k ]; then
            where="$CUSTOM/themes/$p"
        else where="$CUSTOM/plugins/$p"; fi
        stock="$ZSH_DIR/plugins/$p" # ships with OMZ (e.g. history-substring-search)
        if [ -d "$where" ] || [ -d "$stock" ]; then ok "$p"; else
            warn "MISSING OMZ custom: $p ($where)"
            fail=1
        fi
    done
    # Real smoke test: an interactive login-ish zsh sourcing the deployed
    # .zshrc must exit 0 with no "plugin not found" / "command not found:
    # oh-my-posh" diagnostics. _FF_GREETED=1 keeps fastfetch out of the probe.
    if command -v zsh >/dev/null 2>&1 && [ -f "$HOME/.zshrc" ]; then
        local out
        out="$(env _FF_GREETED=1 TERM=xterm-256color zsh -i -c 'echo ZSH_SMOKE_OK' 2>&1 || true)"
        if grep -q ZSH_SMOKE_OK <<<"$out"; then
            ok "zsh interactive smoke test"
        else
            warn "zsh smoke test did not print ZSH_SMOKE_OK"
            fail=1
        fi
        if grep -Ei 'plugin.*not found|oh-my-posh.*not found|error loading|unknown file attribute' <<<"$out" >/dev/null; then
            warn "zsh smoke test printed errors:"
            printf '%s\n' "$out" | head -n 20 >&2
            fail=1
        fi
        # Prompt engine check: with binary + config present the deployed
        # .zshrc must select omp, not the p10k fallback.
        if command -v oh-my-posh >/dev/null 2>&1 && [ -s "$CONFIG/oh-my-posh/config.json" ]; then
            if env _FF_GREETED=1 TERM=xterm-256color zsh -i -c 'print -r -- $_PROMPT_ENGINE' 2>/dev/null | grep -qx omp; then
                ok "prompt engine: oh-my-posh"
            else
                warn "prompt engine is NOT omp (check oh-my-posh + config.json)"
                fail=1
            fi
            oh-my-posh print primary --config "$CONFIG/oh-my-posh/config.json" \
                --shell zsh >/dev/null 2>&1 && ok "oh-my-posh renders" ||
                {
                    warn "oh-my-posh failed to render config.json"
                    fail=1
                }
        fi
    fi
    [ "$fail" -eq 0 ] || warn "shell landing has gaps -- fix lines above before rebooting"
    return "$fail"
}

# ── monitors ─────────────────────────────────────────────────────────────

configure_monitors() {
    local settings="$CONFIG/hypr/lua/settings.lua"
    local json
    if ! command -v hyprctl >/dev/null 2>&1 || ! json="$(hyprctl -j monitors 2>/dev/null)" ||
        [ "$(printf '%s' "$json" | jq 'length' 2>/dev/null || echo 0)" -lt 1 ]; then
        warn "Hyprland is not running -- leaving the monitor block as it is."
        warn "Once it is up:  hyprctl monitors   then edit $settings"
        return 0
    fi
    say "Detected monitors"
    printf '%s' "$json" | jq -r '.[] | "    \(.name)  \(.width)x\(.height)@\(.refreshRate|round)  scale \(.scale)"'
    warn "settings.lua is NOT rewritten automatically -- copy the values above"
    warn "into the hl.monitor{} block of $settings if they differ."
}

# ── verify ───────────────────────────────────────────────────────────────
# The old failure mode was silent: a missing daemon just meant a dead tile.
# Report every load-bearing binary so a fresh install visibly passes/fails.

verify() {
    say "Verifying install"
    local missing=0
    check() {
        if command -v "$1" >/dev/null 2>&1; then ok "$1"; else
            warn "MISSING: $1 ($2)"
            missing=$((missing + 1))
        fi
    }
    check Hyprland "compositor"
    check waybar "status bar"
    check quickshell "launcher / wallpaper wheel"
    check matugen "wallpaper->palette (REQUIRED)"
    check ghostty "terminal"
    check swaync "notifications"
    check hyprpaper "wallpaper daemon"
    check hyprlock "lock screen"
    check hypridle "idle daemon"
    check hyprshot "screenshots (SUPER+Print)"
    check satty "screenshot annotate"
    check swayimg "image gallery"
    check hyprpicker "colour picker"
    check grim "screenshot backend"
    check slurp "region select"
    check wl-copy "clipboard"
    check cliphist "clipboard history"
    check wl-clip-persist "clipboard persistence"
    check wob "volume/brightness OSD"
    check notify-send "notifications (libnotify)"
    check pavucontrol "audio mixer (Waybar click)"
    check wpctl "volume binds (pipewire)"
    check playerctl "media keys"
    check blueman-manager "bluetooth GUI (Waybar click, needs bluez)"
    check bluetoothctl "bluetooth CLI (bluez-utils)"
    check nm-connection-editor "network GUI (Waybar click)"
    check brightnessctl "backlight binds"
    check upower "battery tile"
    check powerprofilesctl "power profiles"
    check cpupower "CPU governor"
    check rofi "launcher"
    check nvim "editor"
    check tmux "multiplexer"
    check yazi "file manager (TUI)"
    check thunar "file manager (GUI)"
    check atuin "shell history"
    check lazygit "git TUI"
    check fzf "fuzzy finder"
    check rg "ripgrep (zsh z-function + yazi search)"
    check fd "fd (zsh z-function + yazi search)"
    check eza "ls replacement (zsh eza plugin)"
    check bat "pager (zsh shell-theme)"
    check jq "JSON (theme scripts + jsontools plugin)"
    check tree "directory overview"
    check htop "process monitor (alongside btop)"
    check less "pager (man/delta)"
    check lspci "PCI inventory (pciutils; GPU detect)"
    check lsusb "USB inventory (usbutils)"
    check rsync "file sync (OMZ rsync plugin)"
    check tte "screensaver effects (pipx)"
    check oh-my-posh "prompt"
    check fastfetch "greeter"
    check zsh "shell"
    check yay "AUR helper"
    [ "$GREETER" = regreet ] && check regreet "login screen"
    [ "$GREETER" = tuigreet ] && check tuigreet "login screen"
    langs_wanted go && check go "Go compiler"
    langs_wanted zig && check zig "Zig compiler"
    langs_wanted node && check node "Node runtime (TS DAP)"
    langs_wanted python && check uv "Python package manager"
    langs_wanted rust && check rustup "Rust toolchain manager"
    langs_wanted lua && check luajit "LuaJIT (Hyprland config)"
    langs_wanted c && check clangd "C/C++ LSP backend"
    if [ "$missing" -gt 0 ]; then
        warn "$missing tool(s) missing -- see lines above; re-run ./install.sh --deps"
    else
        ok "all checks passed"
    fi
}

# ── run ──────────────────────────────────────────────────────────────────

printf '%s\n' "${BOLD}h3bzzz's Hyprland rice -- zero to desktop${OFF}"
printf '%s\n' "${DIM}repo: $DOTFILES${OFF}"

if $DO_DEPS; then
    run_wizard
    printf '\n%sPlan:%s cpu=%s gpu=%s form=%s bt=%s greeter=%s langs=%s extras=%s aur=%s\n\n' \
        "$BOLD" "$OFF" "$CPU" "$GPU" "$FORM" "$WANT_BT_FINAL" "$GREETER" "$LANGS" "$EXTRAS" "$AUR_PREF"
    if [ "$INTERACTIVE" = true ]; then
        local go
        read -r -p "  Proceed? [Y/n]: " go
        case "${go:-Y}" in n | N | no) die "aborted" ;; esac
    fi
    sudo_bootstrap
    install_deps
    deploy_system_files
fi

if $DO_DEPLOY; then
    # sudo is not needed for deploy, but the greeter sync + theme steps are;
    # ensure we have a timestamp if --deps was skipped (deploy-only run).
    if ! $DO_DEPS; then
        sudo -n true 2>/dev/null || sudo -v || true
    fi
    choose_mode
    deploy
    generate_theme
    ensure_login_shell || true
    verify_shell || true
    configure_monitors
fi

if $DO_DEPS; then
    verify
fi

cat <<EOF

${BOLD}Done.${OFF}

  Desktop     reboot, pick Hyprland at the login screen (or run Hyprland from TTY)
  Terminal    first ghostty window lands in zsh + oh-my-posh (verified above)
  Reload      hyprctl reload
  Wallpapers  SUPER+W  (wheel picker; applying one re-themes the whole desktop + login screen)
  Shell       login shell already set to zsh by the installer (check: echo $SHELL)
  Neovim      run nvim once to let LazyVim + mason install LSPs/parsers
  Power       powerprofilesctl get   /   sudo cpupower frequency-info
  Bluetooth   bluetoothctl power on  (then use the Waybar tile / blueman-manager)
EOF

if [ "$DO_DEPLOY" = true ] && [ "$MODE" = link ]; then
    cat <<EOF

  Your configs are symlinks into this repo, so anything you change shows up in
  \`git -C $DOTFILES status\`. Commit it when you want to keep it.
EOF
elif [ "$DO_DEPLOY" = true ]; then
    cat <<EOF

  Your configs are your own copies under $CONFIG -- no symlinks, no ties to
  this clone, which you can now delete. Change anything you like.
  Re-running ./install.sh --copy overwrites them (backing the old ones up
  as .bak-<timestamp>), so keep your own git repo if you want history.
EOF
fi

if $DO_DEPS && [ "$NO_REBOOT" = false ] && [ "$GREETER" != none ]; then
    cat <<EOF

  A reboot is recommended (microcode, drivers, greetd, new groups).
EOF
    if [ "$INTERACTIVE" = true ]; then
        read -r -p "  Reboot now? [y/N]: " rb
        case "${rb:-N}" in y | Y | yes) sudo reboot ;; esac
    else
        printf '  Run: sudo reboot\n'
    fi
fi
