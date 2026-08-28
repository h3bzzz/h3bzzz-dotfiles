import QtQuick
import Quickshell

// One action line in the power dropdown. Icon plate on the left, label, and a
// keyboard hint on the right — the hint is the whole reason the menu is worth
// opening with the keyboard at all.
Rectangle {
    id: root

    required property string glyph
    required property string label
    required property string hint
    required property color  accent

    property bool selected: false

    signal activated()

    width: parent ? parent.width : 0
    height: 36
    radius: 10

    readonly property bool active: selected || hover.hovered

    color: active
        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
        : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    // accent rail that grows in from the left edge on hover
    Rectangle {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: 3
        width: 3
        height: root.active ? parent.height * 0.55 : 0
        radius: 1.5
        color: root.accent
        Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    }

    Text {
        id: icon
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: root.glyph
        font.family: Theme.font
        font.pixelSize: 15
        color: root.active ? root.accent : Theme.subtle
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Text {
        anchors { left: icon.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
        text: root.label
        font.family: Theme.font
        font.pixelSize: 12
        font.weight: root.active ? Font.DemiBold : Font.Medium
        color: root.active ? Theme.text : Theme.subtle
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Text {
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: root.hint
        font.family: Theme.font
        font.pixelSize: 10
        color: Theme.muted
        opacity: root.active ? 0.95 : 0.5
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
