import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Coverflow wallpaper picker. Fullscreen layer surface: the centre image is
// face-on and full size, its neighbours recede along a horizontal path and
// rotate away around the vertical axis, so the strip reads as a wheel turning
// past the viewer rather than a list scrolling.
//
// Picking commits through set-wallpaper.sh, which is also what re-derives the
// palette -- scrolling itself changes nothing, so browsing thirty wallpapers
// costs no matugen runs and no bar reloads.
PanelWindow {
    id: win

    property bool shown: false

    // [{ path, name }], newest scan wins. Filled on open, not at start-up:
    // the directory is the user's and can change between openings.
    property var papers: []
    property string currentPath: ""

    // --- animation driver, same shape as DropSurface -------------------
    property real t: shown ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

    visible: t > 0.002

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:wallpaperwheel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    IpcHandler {
        target: "wallpaper"
        // `show` / `hide` collide with `qs ipc show` on the CLI, so the verbs
        // here match the launcher's and the power menu's.
        function toggle(): void { win.shown = !win.shown }
        function open(): void { win.shown = true }
        function dismiss(): void { win.shown = false }
    }

    // Browsing is slower than picking an app, so this surface gets a longer
    // leash than Theme.idleCloseMs -- but it still gets one. Nothing holding
    // exclusive keyboard focus may be able to strand the session.
    Timer {
        id: idleGuard
        interval: 90000
        onTriggered: win.shown = false
    }

    onShownChanged: {
        if (shown) {
            scan.running = true;
            idleGuard.restart();
        } else {
            idleGuard.stop();
        }
    }

    // Line 1 is the current wallpaper (empty if the link is missing), the rest
    // are the candidates. One process rather than two, so the view never
    // renders a list before it knows which entry to open on.
    Process {
        id: scan
        command: ["sh", "-c",
            "readlink -f ~/.config/hypr/current-wallpaper 2>/dev/null || echo; " +
            "find -L ~/Pictures/wallpapers -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) " +
            "2>/dev/null | LC_ALL=C sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                win.currentPath = (lines.shift() || "").trim();

                const found = [];
                for (let i = 0; i < lines.length; i++) {
                    const p = lines[i].trim();
                    if (p === "") continue;
                    found.push({ path: p, name: p.slice(p.lastIndexOf("/") + 1) });
                }
                win.papers = found;

                // Open on whatever is already set, so the wheel starts where
                // the desktop is rather than at an arbitrary end.
                let start = 0;
                for (let i = 0; i < found.length; i++)
                    if (found[i].path === win.currentPath) { start = i; break; }
                wheel.positionViewAtIndex(start, PathView.SnapPosition);
                wheel.currentIndex = start;
            }
        }
    }

    function commit(): void {
        if (win.papers.length === 0) return;
        const chosen = win.papers[wheel.currentIndex];
        if (!chosen) return;
        win.shown = false;
        // set-wallpaper.sh sets the link, restarts hyprpaper and calls
        // apply-theme.sh, which is what repaints the rest of the desktop.
        Quickshell.execDetached([
            Quickshell.env("HOME") + "/.config/hypr/scripts/set-wallpaper.sh",
            chosen.path
        ]);
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: win.shown = false
        Keys.onPressed: (event) => {
            idleGuard.restart();
            const n = win.papers.length;
            if (n === 0) return;

            if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                wheel.decrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                wheel.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Home) {
                wheel.positionViewAtIndex(0, PathView.SnapPosition);
                wheel.currentIndex = 0;
                event.accepted = true;
            } else if (event.key === Qt.Key_End) {
                wheel.positionViewAtIndex(n - 1, PathView.SnapPosition);
                wheel.currentIndex = n - 1;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                       || event.key === Qt.Key_Space) {
                win.commit();
                event.accepted = true;
            }
        }

        // desktop dim -- heavier than a dropdown's, because the wallpapers
        // themselves are the content and need the contrast
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.72 * win.t
        }

        // click-anywhere-else to dismiss
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: win.shown = false
        }

        Item {
            anchors.fill: parent
            opacity: win.t
            scale: 0.97 + 0.03 * win.t

            // ---- title --------------------------------------------------
            Text {
                id: title
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 54 }
                text: "Wallpapers"
                font.family: Theme.font
                font.pixelSize: 15
                font.weight: Font.Bold
                color: Theme.text
                opacity: 0.85
            }

            // ---- the wheel ----------------------------------------------
            PathView {
                id: wheel

                readonly property int cardW: Math.round(Math.min(560, parent.width * 0.34))
                readonly property int cardH: Math.round(cardW * 9 / 16)

                anchors.fill: parent
                model: win.papers

                // Nine on screen at once: four receding each side is enough to
                // read as a wheel, and caps how many full-size images decode.
                pathItemCount: 9
                cacheItemCount: 4

                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                snapMode: PathView.SnapOneItem
                highlightMoveDuration: 260

                // Straight horizontal run; the wheel comes entirely from the
                // per-item rotation and scale, which is cheaper to animate and
                // does not bow the row out of the screen's centre line.
                path: Path {
                    startX: -wheel.width * 0.12
                    startY: wheel.height / 2

                    PathAttribute { name: "itemZ";       value: 0 }
                    PathAttribute { name: "itemAngle";   value: 66 }
                    PathAttribute { name: "itemScale";   value: 0.52 }
                    PathAttribute { name: "itemOpacity"; value: 0.0 }

                    PathLine { x: wheel.width * 0.33; y: wheel.height / 2 }
                    PathPercent { value: 0.40 }
                    PathAttribute { name: "itemZ";       value: 40 }
                    PathAttribute { name: "itemAngle";   value: 56 }
                    PathAttribute { name: "itemScale";   value: 0.70 }
                    PathAttribute { name: "itemOpacity"; value: 0.72 }

                    PathLine { x: wheel.width * 0.50; y: wheel.height / 2 }
                    PathPercent { value: 0.50 }
                    PathAttribute { name: "itemZ";       value: 100 }
                    PathAttribute { name: "itemAngle";   value: 0 }
                    PathAttribute { name: "itemScale";   value: 1.0 }
                    PathAttribute { name: "itemOpacity"; value: 1.0 }

                    PathLine { x: wheel.width * 0.67; y: wheel.height / 2 }
                    PathPercent { value: 0.60 }
                    PathAttribute { name: "itemZ";       value: 40 }
                    PathAttribute { name: "itemAngle";   value: -56 }
                    PathAttribute { name: "itemScale";   value: 0.70 }
                    PathAttribute { name: "itemOpacity"; value: 0.72 }

                    PathLine { x: wheel.width * 1.12; y: wheel.height / 2 }
                    PathPercent { value: 1.0 }
                    PathAttribute { name: "itemZ";       value: 0 }
                    PathAttribute { name: "itemAngle";   value: -66 }
                    PathAttribute { name: "itemScale";   value: 0.52 }
                    PathAttribute { name: "itemOpacity"; value: 0.0 }
                }

                delegate: Item {
                    id: card

                    required property var modelData
                    required property int index

                    readonly property bool centred: PathView.view.currentIndex === index
                    readonly property bool isCurrent: modelData.path === win.currentPath

                    width: wheel.cardW
                    height: wheel.cardH

                    z: PathView.itemZ
                    scale: PathView.itemScale
                    opacity: PathView.itemOpacity

                    transform: Rotation {
                        origin.x: card.width / 2
                        origin.y: card.height / 2
                        axis { x: 0; y: 1; z: 0 }
                        angle: card.PathView.itemAngle
                    }

                    // Frame. The image sits inset rather than clipped: a
                    // rounded Rectangle clips rectangularly in Qt 6, so a
                    // rounded-off photo would need a mask pass per card.
                    Rectangle {
                        id: frame
                        anchors.fill: parent
                        radius: 14
                        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.96)
                        border.width: card.centred ? 2 : 1
                        border.color: card.centred
                            ? Theme.iris
                            : Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.95)
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        Image {
                            anchors.fill: parent
                            anchors.margins: 5
                            source: "file://" + card.modelData.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            // Decode at roughly display size. Without this a
                            // directory of 4K wallpapers decodes nine full
                            // frames every time the wheel opens.
                            sourceSize.width: 720
                            smooth: true
                            clip: true
                        }

                        // "this one is live" marker, so the wheel says which
                        // wallpaper the desktop is currently wearing
                        Rectangle {
                            visible: card.isCurrent
                            anchors { top: parent.top; right: parent.right; margins: 10 }
                            width: liveLabel.implicitWidth + 16
                            height: 20
                            radius: 10
                            color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.85)
                            border.width: 1
                            border.color: Theme.foam

                            Text {
                                id: liveLabel
                                anchors.centerIn: parent
                                text: "current"
                                font.family: Theme.font
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                color: Theme.foam
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            idleGuard.restart();
                            // First click brings a side card to the centre;
                            // clicking the centred one is the commit. Nothing
                            // is applied by a click that was only aiming.
                            if (card.centred) win.commit();
                            else wheel.currentIndex = card.index;
                        }
                    }
                }

                // Discrete steps rather than the inherited flick: a notch of
                // the wheel should advance exactly one wallpaper.
                WheelHandler {
                    onWheel: (event) => {
                        idleGuard.restart();
                        if (event.angleDelta.y > 0 || event.angleDelta.x < 0)
                            wheel.decrementCurrentIndex();
                        else
                            wheel.incrementCurrentIndex();
                    }
                }
            }

            // ---- caption -------------------------------------------------
            Column {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 58 }
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.papers.length === 0
                        ? "nothing in ~/Pictures/wallpapers"
                        : (win.papers[wheel.currentIndex]
                           ? win.papers[wheel.currentIndex].name
                           : "")
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Theme.text
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: win.papers.length > 0
                    text: (wheel.currentIndex + 1) + " / " + win.papers.length
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: Theme.iris
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "←→ turn   ⏎ apply   esc close"
                    font.family: Theme.font
                    font.pixelSize: 10
                    color: Theme.muted
                    opacity: 0.75
                }
            }
        }
    }
}
