import QtQuick
import Quickshell
import Quickshell.Io

// Compact session dropdown pinned under the right end of waybar.
// Replaces the full-screen rofi powermenu — same five actions, none of the
// screen real estate.
DropSurface {
    id: menu

    edge: "right"
    cardWidth: 232
    accent: Theme.love

    property string uptime: ""
    property string whoAmI: ""
    property int selected: -1

    onAboutToOpen: {
        selected = -1;
        uptimeProc.running = true;
    }

    IpcHandler {
        target: "power"
        // `show` / `hide` collide with `qs ipc show` on the CLI, so the verbs
        // here are deliberately different.
        function toggle(): void { menu.shown = !menu.shown }
        function open(): void { menu.shown = true }
        function dismiss(): void { menu.shown = false }
    }

    // One shot on open: line 1 is user@host, line 2 is the trimmed uptime.
    Process {
        id: uptimeProc
        command: ["sh", "-c", "printf '%s@%s\\n' \"$(id -un)\" \"$(uname -n)\"; uptime -p 2>/dev/null | sed 's/^up //'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                menu.whoAmI = (lines[0] || "").trim();
                menu.uptime = (lines[1] || "").trim();
            }
        }
    }

    // Shutdown and reboot go through hyprshutdown when it is installed so the
    // session still gets its farewell splash; systemctl is the fallback.
    function run(argv: var): void {
        menu.shown = false;
        Quickshell.execDetached(argv);
    }

    readonly property var actions: [
        {
            glyph: "⏻", label: "Shutdown", hint: "S", accent: Theme.love,
            argv: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && exec hyprshutdown -t 'Shutting down...See ya h3bzzz' --post-cmd 'shutdown -P 0' || exec systemctl poweroff"]
        },
        {
            glyph: "󰜉", label: "Reboot", hint: "R", accent: Theme.gold,
            argv: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && exec hyprshutdown -t 'Restarting...Give me a sec' --post-cmd 'reboot' || exec systemctl reboot"]
        },
        {
            glyph: "⏾", label: "Suspend", hint: "U", accent: Theme.foam,
            argv: ["systemctl", "suspend"]
        },
        {
            glyph: "󰌾", label: "Lock", hint: "L", accent: Theme.iris,
            argv: ["sh", "-c", "pidof hyprlock >/dev/null 2>&1 || exec hyprlock"]
        },
        {
            glyph: "󰍃", label: "Log Out", hint: "O", accent: Theme.rose,
            argv: ["hyprctl", "dispatch", "exit"]
        }
    ]

    function activate(i: int): void {
        if (i < 0 || i >= actions.length) return;
        menu.run(actions[i].argv);
    }

    onKeyPressed: (event) => {
        if (event.key === Qt.Key_Up) {
            selected = selected <= 0 ? actions.length - 1 : selected - 1;
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            selected = (selected + 1) % actions.length;
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activate(selected);
            event.accepted = true;
        } else {
            // single-letter accelerators, matching the hint column
            const k = String.fromCharCode(event.key).toUpperCase();
            for (let i = 0; i < actions.length; i++) {
                if (actions[i].hint === k) {
                    activate(i);
                    event.accepted = true;
                    return;
                }
            }
        }
    }

    // ---- card contents ------------------------------------------------

    Item {
        width: parent.width
        implicitHeight: 34

        Text {
            anchors { left: parent.left; leftMargin: 14; top: parent.top; topMargin: 4 }
            text: menu.whoAmI === "" ? (Quickshell.env("USER") || "session") : menu.whoAmI
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Theme.text
        }

        Text {
            anchors { left: parent.left; leftMargin: 14; bottom: parent.bottom; bottomMargin: 3 }
            text: menu.uptime === "" ? "session active" : "up " + menu.uptime
            font.family: Theme.font
            font.pixelSize: 10
            color: Theme.muted
            elide: Text.ElideRight
            width: parent.width - 26
        }
    }

    Item {
        width: parent.width
        implicitHeight: 1
        Rectangle {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            anchors.margins: 8
            height: 1
            color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.28)
        }
    }

    Item { width: parent.width; implicitHeight: 4 }

    Repeater {
        model: menu.actions
        PowerRow {
            required property int index
            required property var modelData

            glyph: modelData.glyph
            label: modelData.label
            hint: modelData.hint
            accent: modelData.accent
            selected: menu.selected === index
            onActivated: menu.activate(index)
        }
    }
}
