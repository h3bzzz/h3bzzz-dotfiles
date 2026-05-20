local terminal      = "kitty"
local fileManager   = "dolphin"
local menu          = "hyprlauncher"
local mainMod       = "SUPER"
local screenShotDir = (os.getenv("HOME") or "/home/h3bzzz") .. "/Pictures/wallpapers"

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
