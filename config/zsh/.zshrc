# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZLUA_EXEC=$(command -v luajit)

if [[ $- == *i* ]]; then
	ff-random 2>/dev/null || fastfetch
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
	git
	fzf
	zsh-autosuggestions
	zsh-syntax-highlighting
	zsh-completions
	history-substring-search
)

source $ZSH/oh-my-zsh.sh

# Rose Pine syntax highlighting colors (valid commands = gold, unknown = love)
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red'
ZSH_HIGHLIGHT_STYLES[command]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[alias]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[function]='fg=yellow'

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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Smart directory jumping: prefer zoxide, fall back to z.lua.
# (Both bind `z`; loading both would conflict, so only one is active.)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"   # `z <dir>` to jump, `zi` for interactive fzf pick
else
  eval "$(lua /opt/z_lua/z.lua --init zsh enhanced once echo)"
fi

# Created by `pipx` on 2026-05-19 14:00:09
export PATH="$PATH:/home/h3bzzz/.local/bin"

# NODE
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Golang
export GOROOT="/usr/lib/go"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"
export GO111MODULE=on

# ─────────────────────────────────────────────────────────────────
#  Ricer QoL — editor, fzf integration, dev/pentest helpers
# ─────────────────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export MANPAGER="less -R"

# fzf powered by fd + bat previews (Ctrl-T files, Alt-C dirs, Ctrl-R history)
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
export FZF_DEFAULT_OPTS="--height 45% --layout=reverse --border=rounded --info=inline \
  --color=fg:#e0def4,bg:-1,hl:#ebbcba,fg+:#e0def4,bg+:#26233a,hl+:#ebbcba \
  --color=border:#403d52,header:#31748f,info:#9ccfd8,pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"
command -v bat >/dev/null 2>&1 && export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"

# Navigation / listing
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --icons=auto --git'
  alias la='eza -a  --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
else
  alias ll='ls -lah --group-directories-first --color=auto'
  alias la='ls -A --color=auto'
fi
alias grep='grep --color=auto'
alias catp='bat --paging=never'        # bat without shadowing real `cat`
alias reload='exec zsh'                 # reload the shell

# Dev / pentest helpers
alias ports='ss -tulpn'                 # listening sockets + owning process
alias myip="ip -brief addr | grep -v '^lo'"
alias pubip='curl -fsSL https://ifconfig.me; echo'
alias serve='python3 -m http.server'    # quick file transfer / exfil catcher
alias reqbin='nc -lvnp'                 # nc -lvnp <port> : listener/catcher
genpass() { tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c "${1:-24}"; echo; }
mkcd()    { mkdir -p -- "$1" && cd -- "$1"; }
extract() {
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;; *.tar.gz) tar xzf "$1" ;; *.tar.xz) tar xJf "$1" ;;
    *.tbz2) tar xjf "$1" ;;    *.tgz) tar xzf "$1" ;;    *.tar) tar xf "$1" ;;
    *.bz2) bunzip2 "$1" ;;     *.gz) gunzip "$1" ;;      *.zip) unzip "$1" ;;
    *.rar) unrar x "$1" ;;     *.7z) 7z x "$1" ;;        *.Z) uncompress "$1" ;;
    *) echo "extract: unknown archive '$1'" ;;
  esac
}
