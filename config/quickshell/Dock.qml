import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    anchors { bottom: true }
    margins { bottom: 6 }

    // Never reserve space, never take focus, and sit on the BOTTOM layer so
    // ordinary windows (terminal, neovim, browser) paint straight over it.
    // The dock is visible on the bare desktop and nowhere else.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell:dock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // headroom above the bar for lifted icons + tooltips
    readonly property int headroom: 74

    implicitWidth: bar.implicitWidth + 80
    implicitHeight: bar.implicitHeight + headroom

    // Auto-hide. The dock is up while the pointer has moved recently, or while
    // it is resting on the dock itself -- without the hover term a motionless
    // cursor would fade the bar out from underneath itself. Typing is not
    // activity, so the dock stays down for as long as the mouse does.
    readonly property bool shown: CursorWatch.active || hoveredIndex >= 0

    // Delay the first evaluation by one tick so the Behaviors below have a
    // false -> true edge to animate: that is what plays the start-up reveal.
    property bool ready: false
    Component.onCompleted: ready = true

    readonly property bool up: ready && shown

    // Only the bar itself eats clicks, and only while the dock is up --
    // a hidden dock must not swallow clicks on the bare desktop.
    mask: Region { item: win.up ? bar : null }

    // fractional index under the cursor; -1 when idle
    property real hoveredIndex: -1
    onUpChanged: if (!up) hoveredIndex = -1

    // slot layout, computed once -- nothing here reacts to hover
    readonly property int itemCount: 6
    readonly property int dividerAt: 5           // divider sits before the last item
    readonly property int dividerWidth: 13
    readonly property real pitch: Theme.slot + Theme.spacing

    Item {
        id: shell
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        implicitWidth: bar.implicitWidth
        implicitHeight: bar.implicitHeight

        // Reveal and hide are the same transition, so the start-up slide-up
        // costs nothing extra: `up` is false for the first tick, then true.
        // The offset goes through the anchor margin rather than `y`, which the
        // bottom anchor would just overwrite on the next layout pass. A
        // negative margin walks the bar off the bottom of the layer surface,
        // and the surface edge clips it -- that clipping is the slide.
        opacity: win.up ? 1 : 0
        anchors.bottomMargin: win.up ? 0 : -Theme.dockSlide
        visible: opacity > 0.01   // stop compositing a dock nobody can see

        Behavior on opacity {
            NumberAnimation {
                duration: win.up ? Theme.dockShowMs : Theme.dockHideMs
                easing.type: Easing.OutCubic
            }
        }
        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: win.up ? Theme.dockShowMs : Theme.dockHideMs
                easing.type: Easing.OutCubic
            }
        }

        // soft shadow under the bar
        MultiEffect {
            source: bar
            anchors.fill: bar
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.55)
            shadowBlur: 1.0
            shadowVerticalOffset: 6
            opacity: 0.9
        }

        Rectangle {
            id: bar
            anchors.centerIn: parent

            // FIXED width -- the whole point. Icons magnify upward, never sideways,
            // so the hit-test grid below is always valid.
            implicitWidth: win.itemCount * Theme.slot
                         + (win.itemCount - 1) * Theme.spacing
                         + win.dividerWidth
                         + Theme.padding * 2
            implicitHeight: Theme.slot + Theme.padding * 2

            radius: Theme.radius
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.88)
            border.width: 1
            border.color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.9)

            // iris hairline that brightens while the dock is in use
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Theme.iris
                opacity: win.hoveredIndex >= 0 ? 0.8 : 0.28
                Behavior on opacity { NumberAnimation { duration: 260 } }
            }

            // faint top sheen
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.margins: 1
                height: parent.height / 2
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.045) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: Theme.spacing

                DockItem {
                    index: 0; hoveredIndex: win.hoveredIndex
                    label: "Zen Browser"; accent: Theme.iris
                    iconSource: Quickshell.iconPath("zen-browser")
                    exec: ["zen-browser"]
                    appIdMatch: ["zen"]
                }
                DockItem {
                    index: 1; hoveredIndex: win.hoveredIndex
                    label: "Ghostty"; accent: Theme.gold
                    iconSource: Quickshell.iconPath("com.mitchellh.ghostty")
                    exec: ["ghostty"]
                    appIdMatch: ["ghostty"]
                }
                DockItem {
                    index: 2; hoveredIndex: win.hoveredIndex
                    label: "Neovim"; accent: Theme.foam
                    iconSource: Quickshell.iconPath("nvim")
                    exec: ["ghostty", "-e", "nvim"]
                    appIdMatch: []
                }
                DockItem {
                    index: 3; hoveredIndex: win.hoveredIndex
                    label: "Discord"; accent: Theme.pineBright
                    iconSource: "file://" + Quickshell.shellDir + "/icons/discord.svg"
                    exec: ["discord"]
                    appIdMatch: ["discord", "vesktop"]
                }
                DockItem {
                    index: 4; hoveredIndex: win.hoveredIndex
                    label: "Spotify"; accent: Theme.rose
                    iconSource: Quickshell.iconPath("spotify")
                    exec: ["spotify"]
                    appIdMatch: ["spotify"]
                }

                Item {
                    width: win.dividerWidth
                    height: Theme.slot
                    Rectangle {
                        anchors.centerIn: parent
                        width: 1
                        height: Theme.slot * 0.42
                        radius: 0.5
                        color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.45)
                    }
                }

                DockItem {
                    index: 5; hoveredIndex: win.hoveredIndex
                    label: "Files"; accent: Theme.love
                    // Thunar's own logo does not sit with the rest of the row,
                    // and this slot reads as "files" rather than as one vendor,
                    // so its icon is drawn from the wallpaper palette instead.
                    // matugen regenerates it -- see templates/filemanager.svg.
                    iconSource: "file://" + Quickshell.shellDir + "/icons/filemanager.svg"
                    exec: ["thunar"]
                    appIdMatch: ["thunar"]
                }
            }

            // Single source of hover truth. Because every slot is a fixed
            // Theme.slot wide, this maps cursor -> fractional index with plain
            // arithmetic and can never disagree with the rendered layout.
            HoverHandler {
                id: barHover
                onPointChanged: win.hoveredIndex = win.indexAt(point.position.x)
                onHoveredChanged: if (!hovered) win.hoveredIndex = -1
            }
        }
    }

    // Map an x inside the bar to a fractional slot index. Fixed grid, so the
    // divider's extra width is simply subtracted once past it.
    function indexAt(x: real): real {
        let local = x - Theme.padding;

        // the gap holding the divider, in bar coordinates
        const gapStart = (dividerAt - 1) * pitch + Theme.slot;
        const gapEnd   = dividerAt * pitch + dividerWidth + Theme.spacing;

        if (local >= gapStart && local < gapEnd) {
            // over the divider: sit exactly between its two neighbours
            return dividerAt - 0.5;
        }
        // past the divider, collapse back onto the uniform grid
        if (local >= gapEnd) local -= dividerWidth + Theme.spacing;

        // slot i is centred at i * pitch + slot / 2
        const idx = (local - Theme.slot / 2) / pitch;
        if (idx < -0.6 || idx > itemCount - 0.4) return -1;
        return Math.max(0, Math.min(itemCount - 1, idx));
    }
}
