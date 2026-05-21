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

-- Ghostty Transparency
hl.window_rule({
	name = "ghostty-opacity",
	match = { class = "^(com\\.mitchellh\\.ghostty)$" },
	opacity = "0.96 override 0.88 override",
})

-- Kitty Transparency (matches terminal opacity for consistency)
hl.window_rule({
	name = "kitty-opacity",
	match = { class = "^(kitty)$" },
	opacity = "0.96 override 0.88 override",
})
