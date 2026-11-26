#!/usr/bin/env bash
# Install (or roll back) the greetd login screen from this directory.
#
#   sudo ./install.sh              deploy Hyprland+ReGreet greeter, keep backups
#   sudo ./install.sh --rollback   restore the previous cage greeter and
#                                  restart greetd (safe to run from tty3)
#   sudo ./install.sh --user NAME  whose wallpaper/palette the greeter follows
#                                  (default: the user who ran sudo)
#
# Nothing here restarts greetd on a normal install: the running greetd owns
# the current session's VT, and the new greeter simply appears at the next
# logout/reboot. Every file that is replaced is kept as <file>.bak-<stamp>.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET_USER="${SUDO_USER:-}"
MODE=install

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rollback) MODE=rollback ;;
        --user) TARGET_USER="${2:-}"; shift ;;
        -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

if [[ "$(id -u)" -ne 0 ]]; then
    printf 'run as root:  sudo %s %s\n' "$0" "$*" >&2
    exit 1
fi
[[ -n "$TARGET_USER" && "$TARGET_USER" != root ]] || TARGET_USER=h3bzzz
getent passwd "$TARGET_USER" >/dev/null || { printf 'no such user: %s\n' "$TARGET_USER" >&2; exit 1; }

say() { printf '==> %s\n' "$*"; }
ok()  { printf '    + %s\n' "$*"; }

backup() {
    local f="$1"
    if [[ -e "$f" && ! -L "$f" ]]; then
        cp -a -- "$f" "$f.bak-$STAMP"
        ok "backed up $(basename "$f") -> $(basename "$f").bak-$STAMP"
    fi
}

# Put a file in place atomically, after a backup of what was there.
put() { # put <mode> <src> <dst>
    local mode="$1" src="$2" dst="$3"
    backup "$dst"
    install -D -m "$mode" -o root -g root -- "$src" "$dst.new-$STAMP"
    mv -f -- "$dst.new-$STAMP" "$dst"
    ok "$dst"
}

rollback() {
    say "Restoring the cage greeter"
    backup /etc/greetd/config.toml
    cat > /etc/greetd/config.toml <<'CFG'
[terminal]
vt = 1

[default_session]
command = "dbus-run-session cage -s -mlast -d -- regreet"
user = "greeter"
CFG
    ok "/etc/greetd/config.toml -> cage + regreet"
    say "Restarting greetd"
    systemctl restart greetd
    ok "done -- the stock cage login screen is back"
}

if [[ "$MODE" = rollback ]]; then
    rollback
    exit 0
fi

say "Checking prerequisites"
for bin in Hyprland regreet cage dbus-run-session magick visudo; do
    command -v "$bin" >/dev/null || { printf 'missing: %s\n' "$bin" >&2; exit 1; }
done
luac -p "$HERE/hyprland.lua" 2>/dev/null && ok "hyprland.lua parses" || {
    command -v luac >/dev/null && { printf 'hyprland.lua has a syntax error\n' >&2; exit 1; }
}
id -nG greeter | tr ' ' '\n' | grep -qx video || usermod -aG video greeter

say "Installing greetd + Hyprland greeter config"
put 755 "$HERE/greeter-session" /etc/greetd/greeter-session
put 644 "$HERE/hyprland.lua"    /etc/greetd/hyprland.lua
put 644 "$HERE/regreet.toml"    /etc/greetd/regreet.toml
put 644 "$HERE/regreet.css"     /etc/greetd/regreet.css
put 644 "$HERE/config.toml"     /etc/greetd/config.toml
# Arch ships greetd.conf next to config.toml; greetd reads config.toml, but
# keep the two identical so nobody is misled by a stale copy.
if [[ -f /etc/greetd/greetd.conf ]]; then
    put 644 "$HERE/config.toml" /etc/greetd/greetd.conf
fi

say "Installing the wallpaper/palette sync hook"
put 755 "$HERE/sync-greeter-wallpaper" /usr/local/bin/sync-greeter-wallpaper
sed "s/^h3bzzz /$TARGET_USER /" "$HERE/sudoers" > "/etc/sudoers.d/.10-greeter-wallpaper.$STAMP"
chmod 440 "/etc/sudoers.d/.10-greeter-wallpaper.$STAMP"
if visudo -cf "/etc/sudoers.d/.10-greeter-wallpaper.$STAMP" >/dev/null; then
    mv -f -- "/etc/sudoers.d/.10-greeter-wallpaper.$STAMP" /etc/sudoers.d/10-greeter-wallpaper
    ok "/etc/sudoers.d/10-greeter-wallpaper ($TARGET_USER, NOPASSWD)"
else
    rm -f -- "/etc/sudoers.d/.10-greeter-wallpaper.$STAMP"
    printf 'sudoers rule failed validation; not installed\n' >&2
fi

say "Rendering the login background from $TARGET_USER's wallpaper"
mkdir -p /usr/share/backgrounds/greetd
SUDO_USER="$TARGET_USER" /usr/local/bin/sync-greeter-wallpaper || true

say "Checking the greeter user can reach everything"
for f in /etc/greetd/hyprland.lua /etc/greetd/regreet.toml /etc/greetd/regreet.css \
         /usr/share/backgrounds/greetd/current-wallpaper; do
    if runuser -u greeter -- test -r "$f"; then ok "readable: $f"
    else printf '    ! greeter cannot read %s (login still works, just plainer)\n' "$f" >&2; fi
done
if runuser -u greeter -- test -x /etc/greetd/greeter-session; then
    ok "executable: /etc/greetd/greeter-session"
else
    printf '    ! greeter cannot run /etc/greetd/greeter-session -- rolling back\n' >&2
    cp -f /etc/greetd/config.toml.bak-"$STAMP" /etc/greetd/config.toml 2>/dev/null || true
    exit 1
fi
bash -n /etc/greetd/greeter-session || { cp -f /etc/greetd/config.toml.bak-"$STAMP" /etc/greetd/config.toml; echo 'greeter-session broken; old config restored' >&2; exit 1; }

say "Done"
cat <<MSG
    The new login screen appears at the next logout or reboot; the running
    session is untouched. To go back to the old cage greeter at any time
    (for example from tty3 with Ctrl+Alt+F3):
        sudo $HERE/install.sh --rollback
    Backups of every replaced file: /etc/greetd/*.bak-$STAMP
MSG
