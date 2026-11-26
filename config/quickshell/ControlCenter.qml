import QtQuick
import Quickshell
import Quickshell.Io

// Control centre + dashboard: clock, system vitals, volume / brightness, the
// session toggles and the current track, in one card under the right end of
// the bar.
//
// It owns no state of its own. ~/.config/hypr/scripts/control-status.sh
// reports everything as one JSON object (polled only while the card is open),
// and every tile acts through the same toggle.sh / Rice.* entry points the
// keybinds and the SUPER+X menu use -- so the three can never disagree.
DropSurface {
    id: cc

    edge: "right"
    cardWidth: 348
    accent: Theme.iris

    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts/"

    // Last status report. Defaults keep the layout stable before the first one.
    property var st: ({
        cpu: 0, mem: 0, disk: 0, battery: -1, charging: false,
        volume: 0, muted: false, brightness: -1,
        wifi: "na", ssid: "", bluetooth: "na",
        nightlight: "off", caffeine: "off", dnd: "off", power: "",
        game: "off", candy: "off", title: "", artist: "", playing: false
    })
    property date now: new Date()

    IpcHandler {
        target: "control"
        function toggle(): void { cc.shown = !cc.shown }
        function open(): void { cc.shown = true }
        function dismiss(): void { cc.shown = false }
    }

    onAboutToOpen: {
        now = new Date();
        statusProc.running = true;
    }

    Timer {
        interval: 2000
        repeat: true
        running: cc.shown
        onTriggered: {
            cc.now = new Date();
            statusProc.running = true;
        }
    }

    Process {
        id: statusProc
        command: [cc.scripts + "control-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { cc.st = JSON.parse(text); } catch (e) { /* keep the last good report */ }
            }
        }
    }

    // Run something, then re-read state shortly after so the tile flips
    // without waiting for the next poll.
    Timer { id: refresh; interval: 350; onTriggered: statusProc.running = true }
    function act(argv: var): void {
        Quickshell.execDetached(argv);
        refresh.restart();
    }
    function toggle(name: string): void { act([scripts + "toggle.sh", name]) }
    function lua(code: string): void { act(["hyprctl", "eval", code]) }

    // ---- clock --------------------------------------------------------

    Item {
        width: parent.width
        implicitHeight: 58

        Text {
            id: clock
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            text: Qt.formatTime(cc.now, "HH:mm")
            font.family: Theme.font
            font.pixelSize: 34
            font.weight: Font.Bold
            color: Theme.text
        }
        Column {
            anchors { left: clock.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
            spacing: 2
            Text {
                text: Qt.formatDate(cc.now, "dddd")
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: cc.accent
            }
            Text {
                text: Qt.formatDate(cc.now, "d MMMM yyyy")
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.muted
            }
        }
    }

    // ---- vitals -------------------------------------------------------

    Item {
        width: parent.width
        implicitHeight: 46

        Row {
            id: vitals
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            anchors.margins: 6
            spacing: 6

            readonly property var cells: {
                const c = [
                    { glyph: "󰻠", label: "CPU",  value: cc.st.cpu,  accent: Theme.foam },
                    { glyph: "󰍛", label: "RAM",  value: cc.st.mem,  accent: Theme.iris },
                    { glyph: "󰋊", label: "DISK", value: cc.st.disk, accent: Theme.gold }
                ];
                if (cc.st.battery >= 0)
                    c.push({ glyph: cc.st.charging ? "󰂄" : "󰁹", label: "BAT", value: cc.st.battery, accent: Theme.pineBright });
                return c;
            }

            Repeater {
                model: vitals.cells
                Rectangle {
                    required property var modelData
                    width: (vitals.width - vitals.spacing * (vitals.cells.length - 1)) / vitals.cells.length
                    height: 38
                    radius: 10
                    color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.6)

                    // level, drawn as a fill rising from the bottom edge
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: parent.height * Math.min(modelData.value, 100) / 100
                        radius: parent.radius
                        color: modelData.accent
                        opacity: modelData.value >= 90 ? 0.34 : 0.16
                        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
                        text: modelData.glyph
                        font.family: Theme.font
                        font.pixelSize: 14
                        color: modelData.accent
                    }
                    Column {
                        anchors { right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
                        Text {
                            anchors.right: parent.right
                            text: modelData.value + "%"
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }
                        Text {
                            anchors.right: parent.right
                            text: modelData.label
                            font.family: Theme.font
                            font.pixelSize: 8
                            color: Theme.muted
                        }
                    }
                }
            }
        }
    }

    // ---- sliders ------------------------------------------------------

    ControlSlider {
        glyph: cc.st.muted ? "󰖁" : "󰕾"
        value: cc.st.volume
        dimmed: cc.st.muted
        accent: Theme.pineBright
        onMoved: (v) => Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)])
        onIconClicked: cc.act(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    }

    ControlSlider {
        visible: cc.st.brightness >= 0
        glyph: "󰃠"
        value: Math.max(cc.st.brightness, 0)
        accent: Theme.gold
        // never 0%: a black laptop panel is a bad place to land from a slider
        onMoved: (v) => Quickshell.execDetached(["brightnessctl", "-q", "set", Math.max(v, 2) + "%"])
    }

    Item { width: parent.width; implicitHeight: 4 }

    // ---- toggles ------------------------------------------------------

    Item {
        width: parent.width
        implicitHeight: grid.implicitHeight

        Grid {
            id: grid
            anchors { left: parent.left; right: parent.right }
            anchors.margins: 6
            columns: 2
            spacing: 6

            readonly property real cell: (width - spacing) / 2

            ControlTile {
                width: grid.cell
                glyph: "󰖩"; label: "Wi-Fi"; accent: Theme.pineBright
                available: cc.st.wifi !== "na"
                on: cc.st.wifi === "on"
                detail: cc.st.wifi === "na" ? "unavailable" : (cc.st.ssid !== "" ? cc.st.ssid : cc.st.wifi)
                onActivated: cc.toggle("wifi")
            }
            ControlTile {
                width: grid.cell
                glyph: "󰂯"; label: "Bluetooth"; accent: Theme.foam
                available: cc.st.bluetooth !== "na"
                on: cc.st.bluetooth === "on"
                detail: cc.st.bluetooth === "na" ? "unavailable" : cc.st.bluetooth
                onActivated: cc.toggle("bluetooth")
            }
            ControlTile {
                width: grid.cell
                glyph: "󰖔"; label: "Night light"; accent: Theme.gold
                on: cc.st.nightlight === "on"
                detail: cc.st.nightlight
                onActivated: cc.toggle("nightlight")
            }
            ControlTile {
                width: grid.cell
                glyph: "󰅶"; label: "Caffeine"; accent: Theme.rose
                on: cc.st.caffeine === "on"
                detail: cc.st.caffeine === "on" ? "no dim or lock" : "idle timers on"
                onActivated: cc.toggle("idle")
            }
            ControlTile {
                width: grid.cell
                glyph: "󰂛"; label: "Do not disturb"; accent: Theme.love
                on: cc.st.dnd === "on"
                detail: cc.st.dnd
                onActivated: cc.toggle("dnd")
            }
            ControlTile {
                width: grid.cell
                glyph: "󱐋"; label: "Power"; accent: Theme.iris
                on: cc.st.power === "performance"
                detail: cc.st.power
                onActivated: cc.toggle("power")
            }
            ControlTile {
                width: grid.cell
                glyph: "󰊴"; label: "Game mode"; accent: Theme.foam
                on: cc.st.game === "on"
                detail: cc.st.game === "on" ? "effects off" : "off"
                onActivated: cc.lua("Rice.toggle_game_mode()")
            }
            ControlTile {
                width: grid.cell
                glyph: "󰄛"; label: "Eye candy"; accent: Theme.iris
                on: cc.st.candy === "on"
                detail: cc.st.candy === "on" ? "frost, wobble, glow" : "off"
                onActivated: cc.lua("Rice.toggle_eye_candy()")
            }
        }
    }

    // ---- now playing --------------------------------------------------

    Item { width: parent.width; implicitHeight: 6; visible: media.visible }

    Item {
        id: media
        width: parent.width
        implicitHeight: 46
        visible: cc.st.title !== ""

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            radius: 12
            color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.6)

            Column {
                anchors { left: parent.left; leftMargin: 12; right: transport.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 1
                Text {
                    width: parent.width
                    text: cc.st.title
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.text
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: cc.st.artist
                    visible: text !== ""
                    font.family: Theme.font
                    font.pixelSize: 9
                    color: Theme.muted
                    elide: Text.ElideRight
                }
            }

            Row {
                id: transport
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 12

                Repeater {
                    model: [
                        { glyph: "󰒮", cmd: "previous" },
                        { glyph: cc.st.playing ? "󰏤" : "󰐊", cmd: "play-pause" },
                        { glyph: "󰒭", cmd: "next" }
                    ]
                    Text {
                        required property var modelData
                        text: modelData.glyph
                        font.family: Theme.font
                        font.pixelSize: 17
                        color: tap.containsMouse ? cc.accent : Theme.subtle

                        MouseArea {
                            id: tap
                            anchors.fill: parent
                            anchors.margins: -5
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cc.act(["playerctl", modelData.cmd])
                        }
                    }
                }
            }
        }
    }

    Item { width: parent.width; implicitHeight: 2 }
}
