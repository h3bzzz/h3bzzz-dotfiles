# =============================================================================
#  ~/.zshrc  —  oh-my-zsh + powerlevel10k, wallpaper-themed via matugen
#
#  Load order in this file is deliberate. Three constraints, in priority order:
#
#    1. The fastfetch greeter must run BEFORE the p10k instant-prompt block.
#       Instant prompt forbids console output *after* it initialises; output
#       before it is fine. The greeter is the point of this rice, so it wins
#       the top slot and instant prompt takes second.
#    2. zstyles that configure an OMZ plugin must be set BEFORE
#       `source $ZSH/oh-my-zsh.sh`, which is where plugins are sourced.
#    3. zsh-autosuggestions / zsh-syntax-highlighting / history-substring-search
#       must be the last three plugins, in that order.
#
#  Machine-local secrets live in ~/.config/zsh/secrets.zsh (gitignored).
# =============================================================================

# ---- greeter -----------------------------------------------------------------
# Random fastfetch theme on every new terminal — ghostty windows, tabs and
# splits all spawn a fresh interactive shell, so each one draws its own theme.
# See ~/.config/fastfetch/README.md; `ff doctor` explains what it detected.
# This runs before the PATH exports further down, so resolve ff explicitly.
if [[ -o interactive && -t 1 && -z $TMUX && -z $_FF_GREETED ]]; then
	typeset -g _FF_GREETED=1
	if [[ -x $HOME/.local/bin/ff ]]; then
		$HOME/.local/bin/ff
	else
		command -v ff >/dev/null && ff || fastfetch
	fi
fi

# ---- powerlevel10k instant prompt --------------------------------------------
# Paints a cached copy of the prompt immediately, then finishes loading the
# real shell behind it. Everything slow below (nvm, sdkman, plugin sourcing)
# stops being felt. Set to `quiet` in ~/.p10k.zsh because a few of the tools
# sourced further down (sdkman, nvm) occasionally print, and the warning about
# it is noise rather than a problem worth acting on.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# ---- z.lua tuning (must be set BEFORE the zlua plugin loads) ----
export ZLUA_EXEC=$(command -v luajit)
export _ZL_ECHO=1                                   # print landing dir so a miss is visible
export _ZL_MATCH_MODE=1                             # enhanced matching
export _ZL_ADD_ONCE=1                               # only touch DB when $PWD actually changed
export _ZL_FZF_FLAG=""                              # drop plugin's default "-e" exact-mode
export _ZL_FZF_HEIGHT="40%"
export _ZL_ROOT_MARKERS=".git,.hg,.svn,.root,package.json,Cargo.toml,build.zig,go.mod,pyproject.toml"
export _ZL_EXCLUDE_DIRS="/tmp,$HOME/.cache"

ZSH_THEME="powerlevel10k/powerlevel10k"

# ---- plugin configuration (must precede oh-my-zsh.sh) ------------------------

# nvm was 811ms of a 1300ms startup — it eagerly resolved and switched Node
# versions on every shell. `lazy yes` defers all of that until the first time
# you actually type node/npm/npx/yarn/pnpm or one of the lazy-cmd names below.
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' lazy-cmd node npm npx yarn pnpm pn bun vite tsc eslint prettier next
zstyle ':omz:plugins:nvm' silent-autoload yes

# eza aliases (ls/ll/la/tree). Icons and git status on, directories first.
zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'git-status' yes
zstyle ':omz:plugins:eza' 'icons' yes
zstyle ':omz:plugins:eza' 'header' yes
zstyle ':omz:plugins:eza' 'hyperlink' yes
zstyle ':omz:plugins:eza' 'time-style' long-iso

# magic-enter: a bare Enter on an empty line runs something useful instead of
# nothing. In a git repo that is a short status; anywhere else, a listing.
MAGIC_ENTER_GIT_COMMAND='git status -sb .'
MAGIC_ENTER_OTHER_COMMAND='eza -l --icons --git --group-directories-first .'

plugins=(
	# --- git ---
	git
	git-extras
	# --- languages (~/Code) ---
	golang
	rust
	python
	nvm                  # lazy-loaded, see zstyle above
	docker
	docker-compose
	# --- quality of life ---
	extract              # x <archive> unpacks anything
	sudo                 # ESC ESC prepends sudo
	dirhistory           # alt+arrows walk cd history
	colored-man-pages
	command-not-found    # arch pkg suggestion on missing cmd
	encode64             # encode64 / decode64
	urltools             # urlencode / urldecode
	jsontools            # pp_json, is_json, urlencode_json
	web-search           # ddg/google <query>
	eza                  # ls/ll/la/tree -> eza, configured above
	copybuffer           # ctrl-o copies the command line to the clipboard
	copypath             # copypath [file]  -> clipboard
	copyfile             # copyfile <file>  -> contents to clipboard
	fancy-ctrl-z         # ctrl-z toggles fg/bg instead of one-way suspend
	safe-paste           # a multiline paste never auto-executes
	magic-enter          # bare Enter -> git status / listing
	history              # h, hs, hsi
	# --- system (arch + hyprland) ---
	archlinux            # pac* aliases, incl. paclsorphans / pacrmorphans
	systemd              # sc-status, sc-restart, ...
	rsync
	# --- security work (~/bugs, pentest.zsh) ---
	nmap                 # zenmap-equivalent scan profiles
	gh                   # github cli completions
	# --- navigation / fuzzy ---
	fzf
	zlua
	zsh-completions
	fzf-tab              # AFTER completions, BEFORE syntax-highlight/autosuggest
	# --- git via fzf ---
	forgit
	# --- typing aids ---
	thefuck
	zsh-you-should-use
	# --- MUST stay last three, in this order ---
	zsh-autosuggestions
	zsh-syntax-highlighting
	history-substring-search
)

source $ZSH/oh-my-zsh.sh

# ---- key bindings ------------------------------------------------------------
# history-substring-search binds only the terminfo cursor sequences (^[OA/^[OB,
# i.e. application cursor mode). Ghostty sends ^[[A / ^[[B in normal mode, and
# OMZ's lib/key-bindings.zsh has already claimed those for
# up-line-or-beginning-search — which is *prefix* matching, not substring. So
# the plugin was effectively inert. Claim both spellings explicitly.
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down

# ---- z: fall back to a filesystem scan when the frecency DB has no match ----
# z.lua only knows directories you have already cd'd into. Without this, an
# unknown keyword silently no-ops and you stay where you were.
unalias z 2>/dev/null
function z {
	if (( $# == 1 )) && [[ "$1" != -* ]]; then
		if [[ -z "$(_zlua -e "$1" 2>/dev/null)" ]]; then
			print -u2 "z: '$1' not in DB - scanning filesystem"
			local pick
			pick="$(fd --type d --hidden --follow --max-depth 6 \
				--exclude .git --exclude node_modules --exclude .cache \
				--exclude target --exclude zig-out --exclude .venv \
				--exclude .cargo --exclude go/pkg \
				. "$HOME" 2>/dev/null \
				| fzf --height "${_ZL_FZF_HEIGHT:-40%}" --reverse \
				      --query "$1" --select-1 --exit-0)"
			[[ -n "$pick" ]] || return 1
			builtin cd "$pick" && _zlua --add "$PWD" && print "$PWD"
			return
		fi
	fi
	_zlua "$@"
}

# Seed the z.lua DB with project dirs you have not visited yet
z-seed() {
	local root="${1:-$HOME/Code}"
	fd --type d --max-depth 3 --exclude node_modules --exclude target \
	   --exclude .git --exclude zig-out . "$root" 2>/dev/null \
	| while read -r d; do _zlua --add "$d"; done
	print "seeded from $root ($(wc -l < ${_ZL_DATA:-$HOME/.zlua}) entries in DB)"
}

# ---- wallpaper-tracking shell colours ----------------------------------------
# FZF_DEFAULT_OPTS, EZA_COLORS, LS_COLORS, BAT_THEME and the fzf Ctrl-T/Alt-C
# pickers. They are written against ANSI slot numbers, which matugen already
# fills from the wallpaper via ~/.config/ghostty/themes/matugen -- so the shell
# follows the desktop with nothing extra to regenerate. See the file's header
# for why this is not a matugen template.
[[ -f "$HOME/.config/zsh/shell-theme.zsh" ]] && \
	source "$HOME/.config/zsh/shell-theme.zsh"

# ---- fzf-tab styling ----
# fzf-tab inherits FZF_DEFAULT_OPTS (set by shell-theme.zsh above), so these
# only need to carry layout and previews.
zstyle ':fzf-tab:*' fzf-flags --height=40% --reverse
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 $realpath'
zstyle ':fzf-tab:complete:z:*'  fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 $realpath'
zstyle ':fzf-tab:complete:(kill|ps):*' fzf-preview 'ps --pid=$word -o cmd --no-headers'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group ',' '.'

# ---- zsh-you-should-use: show reminder AFTER the command runs ----
export YSU_MESSAGE_POSITION="after"
export YSU_MODE=ALL

# ---- atuin: SQLite history + fuzzy Ctrl-R (keeps history-substring on Up/Down) ----
if command -v atuin >/dev/null 2>&1; then
	eval "$(atuin init zsh --disable-up-arrow)"
	# atuin's init re-binds the arrows on some versions; take them back.
	bindkey '^[[A' history-substring-search-up
	bindkey '^[[B' history-substring-search-down
fi

# ---- zig dev helper (no OMZ plugin exists for zig) ----
# zg build | run | test | fmt | check   — run from anywhere inside a zig project
zg() {
	local sub="${1:-build}"; (( $# )) && shift
	local root="$PWD"
	while [[ "$root" != "/" && ! -f "$root/build.zig" ]]; do root="${root:h}"; done
	if [[ ! -f "$root/build.zig" ]]; then
		print -u2 "zg: no build.zig found above $PWD"; return 1
	fi
	case "$sub" in
		build|run|test) ( builtin cd "$root" && zig build ${sub:#build} "$@" ) ;;
		fmt)            zig fmt "${@:-.}" ;;
		check)          ( builtin cd "$root" && zig build --summary all "$@" ) ;;
		*)              ( builtin cd "$root" && zig build "$sub" "$@" ) ;;
	esac
}

# ---- user configuration ------------------------------------------------------

export LANG=en_US.UTF-8
export ARCHFLAGS="-arch $(uname -m)"

# ---- aliases -----------------------------------------------------------------
# Longer-lived alias sets live in $ZSH_CUSTOM/*.zsh (see pentest.zsh).
alias gau='/usr/bin/gau'
alias pn=pnpm
alias tx='/usr/bin/tmux'
# ff is a real script (~/.local/bin/ff) — no alias needed. Handy shortcuts:
alias ffa='ff all'
alias ffl='ff list'
alias sps='sudo pacman -Syu'
alias ysu='yay -Syu'
alias zbr='zig build run'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ---- PATH --------------------------------------------------------------------
# GOLANG — GOBIN is $GOPATH/bin, so this covers the Beatrix CLI too.
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$PATH:/usr/lib/go/bin:$GOBIN"

# LUA
export PATH="$HOME/.luarocks/bin:$PATH"

# Generated for pdtm. Do not edit.
export PATH=$PATH:$HOME/.pdtm/go/bin

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# zvm (zig version manager)
export PATH="$HOME/.zvm/bin:$PATH"

# Android / Tauri mobile
export ANDROID_HOME="$HOME/Android/Sdk"
export NDK_HOME="$ANDROID_HOME/ndk/26.3.11579264"
export JAVA_HOME="$HOME/.sdkman/candidates/java/17.0.12-tem"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Keep ~/.local/bin ahead of everything else.
export PATH="$HOME/.local/bin:$PATH"

# ---- GPU ---------------------------------------------------------------------
export MOZ_ENABLE_WAYLAND=1
export LIBVA_DRIVER_NAME=iHD
export VAAPI_DISPLAY=wayland
export MESA_LOADER_DRIVER_OVERRIDER=i965
export _JAVA_AWT_WM_NONREPARENTING=1

# ---- machine-local ------------------------------------------------------------
# API keys etc. Kept out of the dotfiles repo — see ~/.config/zsh/secrets.zsh,
# which .gitignore excludes.
[[ -f "$HOME/.config/zsh/secrets.zsh" ]] && source "$HOME/.config/zsh/secrets.zsh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

. "$HOME/.local/bin/env"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
