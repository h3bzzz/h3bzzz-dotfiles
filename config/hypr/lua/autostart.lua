local home = os.getenv("HOME") or "/home/h3bzzz"

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRSHOT_DIR", home .. "/Pictures/wallpapers")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("MOZ_DBUS_REMOTE", "1")
--hl.env("AQ_DRM_DEVICES", "/dev/dri/by-path/pci-0000:00:02.0-card:/dev/dri/by-path/pci-0000:01:00.0-card")


-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("waybar")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd(home .. "/.config/hypr/scripts/set-wallpaper-autostart.sh")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("ghostty")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
end)

-- Shutdown hook
hl.on("hyprland.shutdown", function()
	hl.exec_cmd("notify-send Session-ended is-that-time")
end)
