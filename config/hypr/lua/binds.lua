local home          = os.getenv("HOME") or "/home/h3bzzz"
local terminal      = "/usr/bin/ghostty"
local fileManager   = "dolphin"
-- `hyprlauncher` was never installed, so this bind was dead. Use rofi's drun mode
-- (SUPER+R = app-only launcher, complementing SUPER+A = combined apps/run/windows).
local menu          = "rofi -show drun -theme ~/.config/rofi/launchers/type-3/style-3.rasi"
local mainMod       = "SUPER"
local screenShotDir = home .. "/Pictures/Screenshots"
local clipHist      = "cliphist list | rofi -dmenu -display-columns 2 -theme ~/.config/rofi/launchers/type-3/style-3.rasi | cliphist decode | wl-copy"

-- ── Main KeyBinds ────────────────────────────────────────────────
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { description = "Open Terminal" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close Active Window" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("command -v uwsm >/dev/null 2>&1 && uwsm stop || command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"), { description = "Exit Hyprland" })

-- ── App Launchers ────────────────────────────────────────────────
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("rofi -show combi -theme ~/.config/rofi/launchers/type-3/style-3.rasi"), { description = "App Launcher" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "Open File Manager" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Floating" })
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu), { description = "Open Launcher" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Dwindle pseudotile" })
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle Split" })
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("/usr/bin/google-chrome-stable"), { description = "Open Chrome" })
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-switcher.sh"), { description = "Pick Wallpaper" })

-- ── Workspace Switching ──────────────────────────────────────────
for i = 1, 9 do
	hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
	hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
end

-- ── Move Focus ───────────────────────────────────────────────────
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "Move focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Move focus right" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Move focus up" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Move focus down" })

-- ── Move Window ──────────────────────────────────────────────────
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })

-- ── Scroll Through Workspaces ────────────────────────────────────
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { mouse = true, description = "Next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { mouse = true, description = "Previous workspace" })

-- ── Special Workspace ────────────────────────────────────────────
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special(), { description = "Toggle special workspace" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/screensaver/start-screensaver.sh"), { description = "Start screensaver test" })

-- ── Lock Screen ──────────────────────────────────────────────────
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"), { description = "Lock screen" })

-- ── Mouse Move/Resize ────────────────────────────────────────────
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move Window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize Window" })

-- ── Window State ─────────────────────────────────────────────────
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }), { description = "Toggle fullscreen" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Toggle maximized" })
hl.bind(mainMod .. " + T", hl.dsp.window.pin({ action = "toggle" }), { description = "Pin floating window (all workspaces)" })
hl.bind(mainMod .. " + K", hl.dsp.group.toggle(), { description = "Toggle window group (tabbed)" })

-- ── Keyboard Resize (SUPER+CTRL+arrows) ──────────────────────────
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive -60 0"),  { description = "Shrink width" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 60 0"),   { description = "Grow width" })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -60"),  { description = "Shrink height" })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 60"),   { description = "Grow height" })

-- ── Screenshots (hyprshot → ~/Pictures/Screenshots + clipboard) ──
hl.bind("Print",           hl.dsp.exec_cmd("hyprshot -m region --freeze -o " .. screenShotDir), { description = "Screenshot region" })
hl.bind("SHIFT + Print",   hl.dsp.exec_cmd("hyprshot -m window --freeze -o " .. screenShotDir), { description = "Screenshot window" })
hl.bind("CTRL + Print",    hl.dsp.exec_cmd("hyprshot -m output -o " .. screenShotDir),          { description = "Screenshot monitor" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m region --freeze --clipboard-only"),{ description = "Screenshot region → clipboard only" })
-- Capture a region then open satty to annotate (arrows/boxes/blur) → clipboard + saved
hl.bind("ALT + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | satty --filename - --output-filename " .. screenShotDir .. "/satty-$(date +%Y%m%d-%H%M%S).png --copy-command wl-copy --early-exit"), { description = "Screenshot region → annotate (satty)" })

-- ── Color Picker (hyprpicker → hex to clipboard) ─────────────────
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a -f hex"), { description = "Pick color → clipboard (hex)" })

-- ── OCR a region → clipboard (tesseract) ─────────────────────────
hl.bind("ALT + SHIFT + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | tesseract - - 2>/dev/null | wl-copy && notify-send 'OCR' 'Text copied to clipboard'"), { description = "OCR region → clipboard" })

-- ── Clipboard History (cliphist + rofi) ──────────────────────────
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(clipHist), { description = "Clipboard history picker" })

-- ── Volume / Mic (WirePlumber) — locked so they work on lockscreen ─
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true, description = "Mute output" })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true, description = "Mute mic" })

-- ── Media (playerctl) ────────────────────────────────────────────
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/Pause" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Previous track" })
