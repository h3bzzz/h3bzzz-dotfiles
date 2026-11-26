import QtQuick
import Quickshell

// One toggle in the control centre grid: glyph, label, a second line for the
// current state, filled with its accent while the thing it controls is on.
Rectangle {
    id: root

    required property string glyph
    required property string label
    property string detail: ""
    property bool   on: false
    property bool   available: true
    property color  accent: Theme.iris

    signal activated()

    height: 50
    radius: 12
    opacity: available ? 1.0 : 0.4

    color: on
        ? Qt.rgba(accent.r, accent.g, accent.b, hover.hovered ? 0.34 : 0.26)
        : Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, hover.hovered ? 0.95 : 0.6)
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    border.width: 1
    border.color: on
        ? Qt.rgba(accent.r, accent.g, accent.b, 0.55)
        : Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.16)

    Text {
        id: icon
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        text: root.glyph
        font.family: Theme.font
        font.pixelSize: 17
        color: root.on ? root.accent : Theme.subtle
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Column {
        anchors { left: icon.right; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 1

        Text {
            width: parent.width
            text: root.label
            font.family: Theme.font
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Theme.text
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: root.detail
            visible: text !== ""
            font.family: Theme.font
            font.pixelSize: 9
            color: Theme.muted
            elide: Text.ElideRight
        }
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
