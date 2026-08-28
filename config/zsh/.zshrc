# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

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

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	# --- git ---
	git
	git-extras
	# --- languages (~/Code) ---
	golang
	rust
	python
	docker
	docker-compose
	# --- quality of life ---
	extract              # x <archive> unpacks anything
	sudo                 # ESC ESC prepends sudo
	dirhistory           # alt+arrows walk cd history
	colored-man-pages
	command-not-found    # arch pkg suggestion on missing cmd
	encode64             # encode64 / decode64
	jsontools            # pp_json, is_json, urlencode_json
	web-search           # ddg/google <query>
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
	# --- MUST stay last two, in this order ---
	zsh-autosuggestions
	zsh-syntax-highlighting
	history-substring-search
)

source $ZSH/oh-my-zsh.sh

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

# ---- fzf-tab styling ----
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

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias gau='/usr/bin/gau'
alias pn=pnpm
alias tx='/usr/bin/tmux'
# ff is a real script (~/.local/bin/ff) — no alias needed. Handy shortcuts:
alias ffa='ff all'
alias ffl='ff list'
alias sps='sudo pacman -Syu'
alias ysu='yay -Syu'
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# GOLANG
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$PATH:/usr/lib/go/bin:$GOBIN"

# LUA
export PATH="$HOME/.luarocks/bin:$PATH"

# Generated for pdtm. Do not edit.
export PATH=$PATH:/home/h3bzzz/.pdtm/go/bin

# GPU ACCLERATE THYSELF
export MOZ_ENABLE_WAYLAND=1
export LIBVA_DRIVER_NAME=iHD
export VAAPI_DISPLAY=wayland
export MESA_LOADER_DRIVER_OVERRIDER=i965
export _JAVA_AWT_WM_NONREPARENTING=1

# Just making sure
export PATH="$HOME/.local/bin:$PATH"

# Machine-local secrets (API keys etc). Kept out of the dotfiles repo --
# see ~/.config/zsh/secrets.zsh, which .gitignore excludes.
[[ -f "$HOME/.config/zsh/secrets.zsh" ]] && source "$HOME/.config/zsh/secrets.zsh"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

. "$HOME/.local/bin/env"

# opencode
export PATH=/home/h3bzzz/.opencode/bin:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "/home/h3bzzz/.bun/_bun" ] && source "/home/h3bzzz/.bun/_bun"

# pnpm
export PNPM_HOME="/home/h3bzzz/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Beatrix CLI
export PATH="/home/h3bzzz/go/bin:$PATH"

# ZVM INIT
export PATH="$HOME/.zvm/bin:$PATH"

# Android / Tauri mobile
export ANDROID_HOME="$HOME/Android/Sdk"
export NDK_HOME="$ANDROID_HOME/ndk/26.3.11579264"
export JAVA_HOME="$HOME/.sdkman/candidates/java/17.0.12-tem"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
