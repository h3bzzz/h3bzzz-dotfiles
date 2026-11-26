import QtQuick
import Quickshell

// A labelled 0-100 slider. `value` is fed from outside; while the user drags,
// the slider shows its own value and emits `moved` (throttled) so the polled
// state cannot yank the handle back mid-drag.
Item {
    id: root

    required property string glyph
    property int   value: 0
    property color accent: Theme.iris
    property bool  dimmed: false          // e.g. muted

    readonly property bool dragging: area.pressed
    property int shownValue: value

    signal moved(int value)
    signal iconClicked()

    width: parent ? parent.width : 0
    implicitHeight: 34

    onValueChanged: if (!dragging) shownValue = value

    Text {
        id: icon
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        width: 22
        text: root.glyph
        font.family: Theme.font
        font.pixelSize: 15
        color: root.dimmed ? Theme.muted : root.accent

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Rectangle {
        id: track
        anchors { left: icon.right; leftMargin: 8; right: readout.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        height: 8
        radius: 4
        color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.9)

        Rectangle {
            width: Math.max(height, parent.width * Math.min(root.shownValue, 100) / 100)
            height: parent.height
            radius: parent.radius
            color: root.dimmed ? Theme.muted : root.accent
            opacity: root.dimmed ? 0.5 : 1.0
        }

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -10
            cursorShape: Qt.PointingHandCursor

            function apply(mouseX: real): void {
                const x = Math.max(0, Math.min(track.width, mouseX - 10));
                root.shownValue = Math.round(100 * x / track.width);
                if (!throttle.running) throttle.start();
            }
            onPressed: (mouse) => apply(mouse.x)
            onPositionChanged: (mouse) => { if (pressed) apply(mouse.x) }
            onReleased: root.moved(root.shownValue)
        }
    }

    // Emit at most ~16 times a second while dragging: each emission spawns a
    // process, and a free-running drag would spawn hundreds.
    Timer {
        id: throttle
        interval: 60
        onTriggered: root.moved(root.shownValue)
    }

    Text {
        id: readout
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        width: 30
        horizontalAlignment: Text.AlignRight
        text: root.shownValue + "%"
        font.family: Theme.font
        font.pixelSize: 10
        color: Theme.subtle
    }
}
