hl.monitor({
	output = --"INSERT YOUR MONITOR INFO HERE, use hyprctl monitors",
	mode = "1920x1080@60",
	position = "0x0",
	scale = 1,
})

hl.monitor({
	output = --" 'hyprctl monitors' is the way",
	mode = "1920x1080@60",
	position = "2560x0",
	scale = 1,
})

hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 4,
		border_size = 2,
		col = {
			active_border = { colors = {"rgba(31748fee)", "rgba(c4a7e7ee)"}, angle = 45 },
			inactive_border = "rgba(6e6a8644)",
		},
		resize_on_border = true,
		allow_tearing = true,
		layout = "dwindle",
	}
})

hl.config({
	decoration = {
		rounding = 8,
		rounding_power = 2.0,
		active_opacity = 1.0,
		inactive_opacity = 0.92,
		shadow = {
			enabled = true,
			range = 12,
			render_power = 3,
			color = 0x73000000,
			color_inactive = 0x33000000,
			offset = { 0, 4 },
		},
		blur = {
			enabled = true,
			size = 6,
			passes = 2,
			noise = 0.02,
			contrast = 0.9,
			brightness = 0.85,
			xray = false,
			ignore_opacity = true,
			new_optimizations = true,
			special = true,
		},
		dim_inactive = true,
		dim_strength = 0.08,
		dim_special = 0.4,
	}
})

hl.curve("easeOut", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })
hl.curve("easeInOut", { type = "bezier", points = { { 0.45, 0.05}, {0.55, 0.95} } })
hl.curve("snap", { type = "bezier", points = { { 0.1, 0}, {0.9, 1} } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "overshot", style = "popin 92%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "overshot", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "easeInOut", style = "popin 92%" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "easeOut" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 50, bezier = "easeInOut", loop = true })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "easeOut" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "easeOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "easeInOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "snap", style = "slide" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "easeOut" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "easeOut", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "easeInOut", style = "fade" })

hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

hl.config({ dwindle = { preserve_split = true } })
hl.config({ master = { new_status = "master" } })

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		vrr = 1,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
		animate_manual_resizes = false,
		animate_mouse_windowdragging = false,
		initial_workspace_tracking = 0,
		focus_on_activate = false,
	}
})

hl.config({
	input = {
		kb_layout = "us",
		kb_options = "caps:escape",
		follow_mouse = 1,
		sensitivity = 0,
	}
})
