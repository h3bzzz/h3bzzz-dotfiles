import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: root

    // --- inputs -------------------------------------------------------
    required property string iconSource  // real application icon (theme lookup or file://)
    required property string label       // tooltip text
    required property color  accent      // Rose Pine accent for chrome, never the logo
    required property var    exec        // argv array passed to execDetached
    property var appIdMatch: []          // substrings identifying running windows

    required property int index
    required property real hoveredIndex  // fractional; -1 when the dock is idle

    // Fixed slot. The width NEVER reacts to hover -- that feedback loop
    // (width -> relayout -> new hit-test index -> new width) is what made
    // the old dock feel glitchy. Magnification is vertical only.
    implicitWidth: Theme.slot
    implicitHeight: Theme.slot

    readonly property real distance: hoveredIndex < 0
        ? 99
        : Math.abs(index - hoveredIndex)

    readonly property bool hovered: distance < 0.5

    // Gaussian falloff so neighbours ride along in a wave
    readonly property real magTarget: 1.0 + Theme.magAmount
        * Math.exp(-(distance * distance) / (2 * Theme.magSpread * Theme.magSpread))

    // Cursor-driven values must not overshoot; a short ease-out just smooths
    // the discrete jumps and the idle transition.
    property real mag: root.magTarget
    Behavior on mag {
        NumberAnimation { duration: 130; easing.type: Easing.OutQuad }
    }

    readonly property real liftAmount: (mag - 1.0) * Theme.slot * 0.42

    // --- is the app already open? --------------------------------------
    readonly property bool running: {
        if (appIdMatch.length === 0) return false;
        const tl = ToplevelManager.toplevels;
        if (!tl) return false;
        const list = tl.values;
        for (let i = 0; i < list.length; i++) {
            const id = (list[i].appId || "").toLowerCase();
            for (let j = 0; j < appIdMatch.length; j++)
                if (id.includes(appIdMatch[j])) return true;
        }
        return false;
    }

    // --- visuals --------------------------------------------------------
    Item {
        id: lift
        width: Theme.slot
        height: Theme.slot
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        scale: root.mag
        transformOrigin: Item.Bottom
        y: -root.liftAmount + bounceY

        // launch bounce, independent of the hover transform
        property real bounceY: 0
        SequentialAnimation {
            id: bounce
            NumberAnimation { target: lift; property: "bounceY"; to: -14; duration: 170; easing.type: Easing.OutQuad }
            NumberAnimation { target: lift; property: "bounceY"; to: 0;   duration: 340; easing.type: Easing.OutBounce }
        }

        // hover halo behind the logo
        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: 13
            color: root.accent
            opacity: root.hovered ? 0.15 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // the real application icon
        IconImage {
            id: icon
            anchors.centerIn: parent
            implicitSize: Theme.iconSize
            source: root.iconSource
            asynchronous: true
            mipmap: true
            backer.smooth: true
            // request well above display size so magnified icons stay crisp
            backer.sourceSize.width: Theme.iconSize * 4
            backer.sourceSize.height: Theme.iconSize * 4

            opacity: root.hovered ? 1.0 : (root.running ? 0.96 : 0.84)
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // bloom in the icon's own colours -- no colorization, logos stay authentic
        MultiEffect {
            source: icon
            anchors.fill: icon
            blurEnabled: true
            blurMax: 24
            blur: 1.0
            brightness: 0.15
            opacity: root.hovered ? 0.5 : (root.running ? 0.18 : 0.0)
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // running indicator dot, pinned to the bar (does not ride the lift)
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        width: root.running ? 5 : 0
        height: 5
        radius: 2.5
        color: root.accent
        opacity: root.running ? 0.95 : 0
        Behavior on width   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // tooltip, floating above the magnified icon
    Rectangle {
        id: tip
        visible: opacity > 0.01
        opacity: root.hovered ? 1 : 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 10 + root.liftAmount + (root.mag - 1.0) * Theme.slot * 0.5
        implicitWidth: tipText.implicitWidth + 18
        implicitHeight: tipText.implicitHeight + 10
        radius: 8
        color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.96)
        border.width: 1
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)

        Behavior on opacity { NumberAnimation { duration: 140 } }

        Text {
            id: tipText
            anchors.centerIn: parent
            text: root.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 12
        }
    }

    // clicks only -- all hover state comes from the bar-level handler so the
    // two never disagree
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            bounce.restart();
            Quickshell.execDetached(root.exec);
        }
    }
}
