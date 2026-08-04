-- Smart Gaps
hl.window_rule({
	name = "no-border-wtv1",
	match = { float = false, workspace = "w[tv1]" },
	border_size = 0,
	rounding = 0,
})

hl.window_rule({
	name = "no-border-f1",
	match = { float = false, workspace = "f[1]" },
	border_size = 0,
	rounding = 0,
})

-- Fix Wayland Drag Issues
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- Dialogs, Pickers, etc...
hl.window_rule({
	name = "float-nm-editor",
	match = { class = "nm-connection-editor" },
	float = true,
	center = true,
})

hl.window_rule({
	name = "float-blueman",
	match = { class = "pavucontrol" },
	float = true,
	center = true,
})

hl.window_rule({
	name = "float-file-progress",
	match = { title = "File Operation Progress" },
	float = true,
})

hl.window_rule({
	name = "float-confirm-replace",
	match = { title = "Confirm to replace files" },
	float = true,
})

hl.window_rule({
	name = "float-auth-required",
	match = { title = "Authentication Required" },
	float = true,
})

-- Portal file picker (open/save dialogs) — float + center
hl.window_rule({
	name = "float-portal-filechooser",
	match = { class = "xdg-desktop-portal-gtk" },
	float = true,
	center = true,
})

-- Browser Picture-in-Picture — float + pin to all workspaces
hl.window_rule({
	name = "pip-float",
	match = { title = "Picture-in-Picture" },
	float = true,
	pin = true,
})

-- Ghostty Transparency
hl.window_rule({
	name = "ghostty-opacity",
	match = { class = "^(com\\.mitchellh\\.ghostty)$" },
	opacity = "0.96 override 0.88 override",
})

-- Screensaver fullscreen per monitor
-- Each ghostty instance uses a unique GTK app ID (com.tte.screensaver.MONITOR)
-- so the rule can assign it to the correct display + fullscreen
hl.window_rule({
	name = "screensaver-DP-3",
	match = { class = "^(com\\.tte\\.screensaver\\.DP-3)$" },
	fullscreen = true,
	monitor = "DP-3",
	border_size = 0,
	rounding = 0,
})

hl.window_rule({
	name = "screensaver-HDMI-A-1",
	match = { class = "^(com\\.tte\\.screensaver\\.HDMI-A-1)$" },
	fullscreen = true,
	monitor = "HDMI-A-1",
	border_size = 0,
	rounding = 0,
})
