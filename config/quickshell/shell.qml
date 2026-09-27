import Quickshell

ShellRoot {
    // The dock is instanced once per connected screen: `Variants` creates a
    // Dock for every entry in Quickshell.screens, hands each instance its
    // screen via `modelData` (Dock binds `screen: modelData`), and destroys
    // instances as screens are unplugged. See Quickshell's `screens` /
    // `Variants` docs.
    Variants {
        model: Quickshell.screens
        delegate: Dock {}
    }
    PowerMenu {}
    AppLauncher {}
    WallpaperWheel {}
}