import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

// A dropdown that hangs off one top corner of the screen, directly beneath
// waybar. Fullscreen layer surface so it can dim the desktop and swallow the
// click that dismisses it, but only the card itself is ever visible.
//
// Children are laid out in a Column inside the card; give them
// `width: parent.width` and an implicitHeight.
PanelWindow {
    id: win

    default property alias cardContent: cardBody.data

    // --- inputs -------------------------------------------------------
    property bool  shown: false
    property string edge: "right"          // which top corner the card hugs
    property int   cardWidth: 240
    property color accent: Theme.iris
    property int   sideMargin: Theme.barMargin

    signal aboutToOpen()
    // Key events that reach the surface, so subclasses can add shortcuts
    // without needing an Item of their own to attach to.
    signal keyPressed(var event)

    // --- animation driver ----------------------------------------------
    // One value drives dim, scale, fade and slide, so the card can finish its
    // exit animation before the surface is torn down.
    property real t: shown ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

    visible: t > 0.002

    onShownChanged: {
        if (shown) {
            aboutToOpen();
            idleGuard.restart();
        } else {
            idleGuard.stop();
        }
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:dropsurface"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // A surface holding exclusive keyboard focus must never be able to strand
    // the session if something upstream stops talking to it.
    Timer {
        id: idleGuard
        interval: Theme.idleCloseMs
        onTriggered: win.shown = false
    }

    FocusScope {
        id: scope
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: win.shown = false
        Keys.onPressed: (event) => {
            idleGuard.restart();
            win.keyPressed(event);
        }

        // desktop dim
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: Theme.dimOpacity * win.t
        }

        // click-anywhere-else to dismiss
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: win.shown = false
        }

        Item {
            id: anchorBox
            width: win.cardWidth
            height: card.height

            y: Theme.popupTop
            x: win.edge === "left"
                ? win.sideMargin
                : parent.width - win.cardWidth - win.sideMargin

            transform: Translate { y: (1 - win.t) * -12 }
            opacity: win.t
            scale: 0.94 + 0.06 * win.t
            transformOrigin: win.edge === "left" ? Item.TopLeft : Item.TopRight

            MultiEffect {
                source: card
                anchors.fill: card
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.6)
                shadowBlur: 1.0
                shadowVerticalOffset: 8
                opacity: 0.9
            }

            Rectangle {
                id: card
                width: parent.width
                height: cardBody.implicitHeight + Theme.popupPad * 2
                radius: Theme.popupRadius
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.97)
                border.width: 1
                border.color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.95)

                // accent hairline, same trick the dock uses
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: win.accent
                    opacity: 0.42
                }

                // top sheen
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    anchors.margins: 1
                    height: parent.height / 2
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.05) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // swallow stray clicks on the card's own padding so they do not
                // reach the dismiss handler behind it
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onPressed: idleGuard.restart()
                }

                Column {
                    id: cardBody
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    anchors.margins: Theme.popupPad
                    spacing: 2
                }
            }
        }
    }
}
