# h3bzzz's Hyprland Dotfiles

Rose Pine themed Hyprland setup with Waybar, Rofi, Wofi, Cava, and custom screensaver.

## Highlights

- **Lua-driven Hyprland config** (hyprland.lua with modular includes)
- **Waybar** with centered clock flanked by Cava audio visualizer bars
- **Rofi** app launcher (fullscreen grid) + power menu (with confirm dialog)
- **Wofi** app launcher + power menu (alternative)
- **Hyprlock** lockscreen with clock, date, caps warning
- **Hypridle** timed idle → screensaver → lock → DPMS → suspend
- **TTE screensaver** (terminal text effects in fullscreen kitty)
- **`~/.config/hypr/current-wallpaper` symlink** tracks live wallpaper state
- **Wallpaper picker** via rofi (SUPER+W, browses `~/Pictures/wallpapers/`)

## Requirements

| Component | Package |
|-----------|---------|
| WM | hyprland |
| Bar | waybar |
| Launcher | rofi-wayland, wofi |
| Lockscreen | hyprlock |
| Idle daemon | hypridle |
| Wallpaper | hyprpaper |
| Audio vis | cava |
| Notifications | swaync |
| Clipboard | cliphist, wl-clipboard |
| Font | jetbrains-mono-nerd |
| Icons | papirus-icon-theme |
| Terminal | kitty (or ghostty) |
| Screensaver | tte (see below) |

### tte (screensaver)

The screensaver uses [tte](https://github.com/nicoverbruggen/tte). Install it at `~/.local/bin/tte`:
```bash
curl -sSfL https://github.com/nicoverbruggen/tte/releases/latest/download/tte-x86_64-unknown-linux-gnu -o ~/.local/bin/tte
chmod +x ~/.local/bin/tte
```

## Quick Install

```bash
# Clone and run
git clone https://github.com/h3bzzz/hyprland-dotfiles ~/hyprland-dotfiles
cd ~/hyprland-dotfiles

# Install dependencies (optional)
./install.sh --deps

# Deploy configs (symlinks ~/.config/* → repo)
./install.sh
```

Restart Hyprland or run `hyprctl reload`.

## Keybinds

| Key | Action |
|-----|--------|
| SUPER + RETURN | Terminal (kitty) |
| SUPER + Q | Close window |
| SUPER + A | Rofi app launcher |
| SUPER + W | Wallpaper picker |
| SUPER + L | Lock screen |
| SUPER + V | Toggle float |
| SUPER + S | Toggle special workspace |
| SUPER + SHIFT + S | Start screensaver |
| SUPER + 1-9 | Switch workspace |
| SUPER + SHIFT + 1-9 | Move to workspace |
| SUPER + arrows | Focus direction |
| SUPER + SHIFT + arrows | Move window |

## Structure

```
~/.config/
├── hypr/           # Hyprland (lua), hyprlock, hypridle, hyprpaper, scripts, screensaver
├── waybar/         # Bar config, style, cava Python scripts
├── wofi/           # App launcher + power menu
├── rofi/           # App launcher (type-3) + power menu (type-4)
└── cava/           # Audio visualizer configs, themes, shaders
```

## Credits

- [Rose Pine](https://rosepinetheme.com/) color palette
- [Hyprland](https://hyprland.org/)
- [Cava](https://github.com/karlstav/cava)
