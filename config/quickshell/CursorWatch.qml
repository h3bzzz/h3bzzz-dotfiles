pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pointer-activity watchdog for the dock.
//
// Hyprland publishes no "pointer moved" event on its event socket, and a layer
// surface only learns about the pointer once it is already over the surface --
// neither can tell us the cursor moved somewhere else on the desktop. So this
// polls `cursorpos` over Hyprland's request socket. That is a plain unix-socket
// round trip rather than a `hyprctl` fork, cheap enough to run a few times a
// second and leave running for the life of the session.
//
// Keyboard input deliberately does NOT count as activity: the dock is meant to
// stay out of the way while typing, and only mouse / touchpad motion brings it
// back.
Singleton {
    id: root

    // Poll fast while hidden so the dock feels instant on the first twitch of
    // the mouse; once it is up we only need to notice continued motion before
    // the idle timer fires, so back off.
    property int wakeMs: 110
    property int restMs: 320
    property int idleMs: Theme.dockIdleMs

    readonly property bool available: socketPath !== ""
    property bool active: true

    property int lastX: -1
    property int lastY: -1

    readonly property string socketPath: {
        const dir = Quickshell.env("XDG_RUNTIME_DIR");
        const sig = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE");
        if (!dir || !sig) return "";
        return dir + "/hypr/" + sig + "/.socket.sock";
    }

    // Any surface can vote itself awake -- the dock uses this so a pointer
    // resting motionless on it does not fade out from under the cursor.
    function poke() {
        root.active = true;
        idle.restart();
    }

    Timer {
        id: idle
        interval: root.idleMs
        running: root.available
        onTriggered: root.active = false
    }

    Timer {
        interval: root.active ? root.restMs : root.wakeMs
        repeat: true
        running: root.available
        onTriggered: if (!sock.connected) sock.connected = true
    }

    // Hyprland answers and then closes, so every poll is its own
    // connect -> write -> read -> close cycle.
    Socket {
        id: sock
        path: root.socketPath

        onConnectedChanged: if (connected) write("cursorpos")

        // The reply carries no trailing newline, so an empty split marker is
        // required: it makes the parser hand over each chunk as it arrives
        // instead of waiting for a delimiter that never comes.
        parser: SplitParser {
            splitMarker: ""
            onRead: data => {
                // Hang up before Hyprland does. Its FIN would otherwise reach
                // us as a PeerClosedError, once per poll, several times a
                // second, for the life of the session.
                sock.connected = false;

                const parts = data.split(",");
                if (parts.length !== 2) return;
                const x = parseInt(parts[0], 10);
                const y = parseInt(parts[1], 10);
                if (isNaN(x) || isNaN(y)) return;
                if (x === root.lastX && y === root.lastY) return;
                root.lastX = x;
                root.lastY = y;
                root.poke();
            }
        }
    }
}
