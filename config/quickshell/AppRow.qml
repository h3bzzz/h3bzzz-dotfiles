import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

// One application line in the launcher list.
Rectangle {
    id: root

    required property string title
    required property string subtitle
    required property string iconName
    required property bool   selected

    signal activated()

    height: 44
    radius: 10

    readonly property bool active: selected || hover.hovered

    color: active
        ? Qt.rgba(Theme.iris.r, Theme.iris.g, Theme.iris.b, 0.15)
        : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Rectangle {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: 3
        width: 3
        height: root.active ? parent.height * 0.5 : 0
        radius: 1.5
        color: Theme.iris
        Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    }

    IconImage {
        id: appIcon
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        implicitSize: 26
        source: Quickshell.iconPath(root.iconName, "application-x-executable")
        asynchronous: true
        mipmap: true
        backer.smooth: true
        backer.sourceSize.width: 96
        backer.sourceSize.height: 96
        opacity: root.active ? 1.0 : 0.82
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    // faint bloom in the icon's own colours while selected — same treatment
    // the dock gives a hovered launcher, so the two surfaces read as one theme
    MultiEffect {
        source: appIcon
        anchors.fill: appIcon
        blurEnabled: true
        blurMax: 20
        blur: 1.0
        brightness: 0.15
        opacity: root.active ? 0.38 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animMed } }
    }

    Column {
        anchors {
            left: appIcon.right
            leftMargin: 12
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        spacing: 1

        Text {
            width: parent.width
            text: root.title
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: root.active ? Font.DemiBold : Font.Medium
            color: root.active ? Theme.text : Theme.subtle
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        Text {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            font.family: Theme.font
            font.pixelSize: 10
            color: Theme.muted
            elide: Text.ElideRight
        }
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
