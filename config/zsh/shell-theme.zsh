# =============================================================================
#  shell-theme.zsh  —  make every shell popup and listing follow the wallpaper
#
#  Sourced from ~/.zshrc. Deployed to ~/.config/zsh/shell-theme.zsh.
#
#  WHY THIS FILE IS NOT A MATUGEN TEMPLATE
#  ---------------------------------------
#  It would be the obvious move: add a [templates.shell-theme] block and emit
#  literal hex from the wallpaper, the way waybar and rofi do. It is the wrong
#  move here, because every colour these tools need already exists as an ANSI
#  slot that matugen fills.
#
#  ~/.config/matugen/templates/ghostty-theme writes the 16-colour palette:
#
#      0  surface_container_high      8  outline (muted)
#      1  love        9  love         12 primary
#      2  foam       10  foam
#      3  gold       11  gold
#      4  pine       13  iris
#      5  iris       14  rose
#      6  rose       15  on_surface
#      7  on_surface
#
#  So referring to slot 5 gets iris *for the current wallpaper*, forever, with
#  no regeneration step, no gitignore entry for build output, and nothing new
#  that can fail inside apply-theme.sh. It also degrades gracefully: over SSH,
#  in tmux, or in a terminal that is not ghostty, these stay readable instead
#  of painting one wallpaper's hex onto someone else's background.
#
#  Hex belongs in a matugen template only where a tool needs a tone that is not
#  in the 16-colour set. Nothing below does.
# =============================================================================

# ---- fzf ---------------------------------------------------------------------
# `-1` means "terminal default", which keeps ghostty's background-opacity
# showing through the popup instead of punching an opaque rectangle in it.
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border=rounded
  --info=inline
  --prompt='  '
  --pointer='▸'
  --marker='✓'
  --color=fg:-1,bg:-1,gutter:-1
  --color=fg+:7,bg+:0,hl:1,hl+:3
  --color=info:8,border:8,separator:8,scrollbar:8,label:8
  --color=prompt:5,pointer:3,marker:4,spinner:6,header:2,query:7
  --bind=ctrl-/:toggle-preview
  --bind=ctrl-u:preview-half-page-up
  --bind=ctrl-d:preview-half-page-down
"

# Respect .gitignore, show hidden files, skip the noise directories.
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow \
  --exclude .git --exclude node_modules --exclude target \
  --exclude zig-out --exclude .venv --exclude .cache"

# Ctrl-T — file picker with a syntax-highlighted preview.
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
  --preview 'bat --style=numbers --color=always --line-range=:300 {} 2>/dev/null || eza -1 --icons --color=always {}'
  --preview-window=right:60%:border-left
"

# Alt-C — directory picker with a listing preview.
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow \
  --exclude .git --exclude node_modules --exclude target \
  --exclude zig-out --exclude .venv --exclude .cache"
export FZF_ALT_C_OPTS="
  --preview 'eza -1 --icons --color=always --group-directories-first {}'
  --preview-window=right:50%:border-left
"

# Ctrl-R is atuin's (see .zshrc), so no FZF_CTRL_R_OPTS here.

# ---- bat ---------------------------------------------------------------------
# bat's `ansi` theme draws only from the terminal's 16 colours, so it tracks the
# wallpaper for free. Any of the named themes (Dracula, Nord, ...) would pin bat
# to one palette while the rest of the desktop moved.
export BAT_THEME="ansi"
export BAT_STYLE="numbers,changes,header"

# colored-man-pages hands off to $MANPAGER; route it through bat when present.
if command -v bat >/dev/null 2>&1; then
	export MANROFFOPT="-c"
	export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -l man'"
fi

# ---- eza ---------------------------------------------------------------------
# ANSI slots again: 31 love, 32 foam, 33 gold, 34 pine, 35 iris, 36 rose,
# 90 outline. Bold (1;) selects the bright half of the palette.
export EZA_COLORS="\
di=1;34:\
ex=1;32:\
fi=0:\
ln=36:\
or=1;31:\
pi=33:\
so=35:\
bd=33:\
cd=33:\
su=1;31:\
sf=1;31:\
uu=33:\
gu=33:\
ur=33:uw=31:ux=32:ue=32:\
gr=33:gw=31:gx=32:\
tr=33:tw=31:tx=32:\
sn=32:sb=32:\
df=35:ds=35:\
da=90:\
xx=90:\
in=90:\
gm=33:ga=32:gd=31:gv=35:gt=36:\
hd=1;4:\
lp=36:cc=1;31"

# ---- LS_COLORS ---------------------------------------------------------------
# Used by coreutils `ls`, and by the completion system's list-colors below, so
# fzf-tab's menu entries are tinted the same way as an eza listing.
export LS_COLORS="\
di=1;34:ln=36:or=1;31:mh=00:pi=33:so=35:do=35:bd=33:cd=33:\
su=1;31:sg=1;31:ca=00:tw=1;34:ow=1;34:st=1;34:ex=1;32:\
*.tar=31:*.tgz=31:*.zip=31:*.gz=31:*.bz2=31:*.xz=31:*.zst=31:*.7z=31:*.rar=31:\
*.jpg=35:*.jpeg=35:*.png=35:*.gif=35:*.webp=35:*.svg=35:*.mp4=35:*.mkv=35:\
*.mp3=36:*.flac=36:*.wav=36:*.ogg=36:\
*.pdf=33:*.md=33:*.txt=33:\
*.zig=33:*.rs=33:*.go=36:*.py=33:*.js=33:*.ts=36:*.lua=34:*.c=34:*.h=34:\
*.json=33:*.toml=33:*.yaml=33:*.yml=33:*.conf=33:\
*.log=90:*.lock=90:*.bak=90:*~=90"

# Colour the completion menu (and therefore fzf-tab) from LS_COLORS.
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;90=0=01;33'

# ---- delta (git pager, when installed) ---------------------------------------
# `ansi` for the same reason bat uses it.
export DELTA_FEATURES="+"
export GIT_PAGER_SYNTAX_THEME="ansi"
