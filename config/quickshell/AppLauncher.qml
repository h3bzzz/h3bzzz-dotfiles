import QtQuick
import Quickshell
import Quickshell.Io

// Arch-badge application browser, pinned under the left end of waybar.
// Type to filter, or pick a category chip and browse.
DropSurface {
    id: launcher

    edge: "left"
    cardWidth: 420
    accent: Theme.foam

    property int  selected: 0
    property string category: ""   // "" == All

    IpcHandler {
        target: "launcher"
        // `show` / `hide` collide with `qs ipc show` on the CLI, so the verbs
        // here are deliberately different.
        function toggle(): void { launcher.shown = !launcher.shown }
        function open(): void { launcher.shown = true }
        function dismiss(): void { launcher.shown = false }

        // Open pre-filled. `shown` is set first because opening resets both.
        function query(text: string): void {
            launcher.shown = true;
            search.text = text;
            search.cursorPosition = text.length;
        }
        function filter(chip: string): void {
            launcher.shown = true;
            launcher.category = chip === "All" ? "" : chip;
        }
    }

    onAboutToOpen: {
        search.text = "";
        launcher.category = "";
        launcher.selected = 0;
    }

    // Focus has to wait for the surface to actually exist; `shown` flips a
    // frame before `visible` does.
    onVisibleChanged: if (visible) search.forceActiveFocus()

    // ---- catalogue ------------------------------------------------------

    // Chip label -> freedesktop category tokens it stands for.
    readonly property var chips: [
        { label: "All",     cats: [] },
        { label: "Web",     cats: ["Network", "WebBrowser", "Email"] },
        { label: "Dev",     cats: ["Development", "IDE", "TextEditor"] },
        { label: "Media",   cats: ["AudioVideo", "Audio", "Video", "Player", "Music"] },
        { label: "Design",  cats: ["Graphics", "Photography", "2DGraphics", "3DGraphics"] },
        { label: "Games",   cats: ["Game"] },
        { label: "Office",  cats: ["Office", "TextTools", "Documentation"] },
        { label: "System",  cats: ["System", "Settings", "Security", "TerminalEmulator"] },
        { label: "Utils",   cats: ["Utility", "Accessories", "FileTools", "FileManager"] }
    ]

    readonly property var allApps: {
        const model = DesktopEntries.applications;
        if (!model) return [];
        const src = model.values;
        const out = [];
        for (let i = 0; i < src.length; i++) {
            const e = src[i];
            if (!e || e.noDisplay) continue;
            if (!e.name || e.name === "") continue;
            out.push(e);
        }
        out.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" }));
        return out;
    }

    // Categories and Keywords come back as string lists, but older builds
    // hand over the raw semicolon-joined string. Accept either.
    function tokens(value: var): var {
        if (!value) return [];
        if (Array.isArray(value)) return value;
        return String(value).split(/[;,]/).filter(s => s !== "");
    }

    function inCategory(entry: var, chipCats: var): bool {
        if (chipCats.length === 0) return true;
        const have = tokens(entry.categories);
        for (let i = 0; i < have.length; i++)
            for (let j = 0; j < chipCats.length; j++)
                if (have[i] === chipCats[j]) return true;
        return false;
    }

    // Higher is better; -1 drops the entry. Prefix hits on the visible name
    // outrank everything, so typing "fir" puts Firefox first, not Thunderbird.
    function score(entry: var, q: string): int {
        const name = (entry.name || "").toLowerCase();
        if (name.startsWith(q)) return 100 - Math.min(name.length, 40);
        const wordStart = name.split(/[\s\-_.]+/).some(w => w.startsWith(q));
        if (wordStart) return 70;
        if (name.includes(q)) return 55;
        if ((entry.genericName || "").toLowerCase().includes(q)) return 40;
        if ((entry.id || "").toLowerCase().includes(q)) return 35;
        if (tokens(entry.keywords).join(" ").toLowerCase().includes(q)) return 25;
        if ((entry.comment || "").toLowerCase().includes(q)) return 15;
        return -1;
    }

    readonly property var apps: {
        const q = search.text.trim().toLowerCase();
        const chipCats = (() => {
            for (let i = 0; i < chips.length; i++)
                if (chips[i].label === launcher.category) return chips[i].cats;
            return [];
        })();

        const pool = [];
        for (let i = 0; i < allApps.length; i++) {
            const e = allApps[i];
            if (!inCategory(e, chipCats)) continue;
            if (q === "") { pool.push({ e: e, s: 0 }); continue; }
            const s = score(e, q);
            if (s >= 0) pool.push({ e: e, s: s });
        }
        if (q !== "")
            pool.sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name));
        return pool.map(x => x.e);
    }

    onAppsChanged: launcher.selected = 0

    function launchAt(i: int): void {
        if (i < 0 || i >= apps.length) return;
        launcher.shown = false;
        apps[i].execute();
    }

    onKeyPressed: (event) => {
        const n = apps.length;
        if (n === 0) return;
        if (event.key === Qt.Key_Down) {
            launcher.selected = (launcher.selected + 1) % n;
            list.positionViewAtIndex(launcher.selected, ListView.Contain);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            launcher.selected = launcher.selected <= 0 ? n - 1 : launcher.selected - 1;
            list.positionViewAtIndex(launcher.selected, ListView.Contain);
            event.accepted = true;
        } else if (event.key === Qt.Key_PageDown) {
            launcher.selected = Math.min(n - 1, launcher.selected + 7);
            list.positionViewAtIndex(launcher.selected, ListView.Contain);
            event.accepted = true;
        } else if (event.key === Qt.Key_PageUp) {
            launcher.selected = Math.max(0, launcher.selected - 7);
            list.positionViewAtIndex(launcher.selected, ListView.Contain);
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            // cycle category chips
            let idx = 0;
            for (let i = 0; i < chips.length; i++)
                if (chips[i].label === launcher.category) idx = i;
            const next = chips[(idx + 1) % chips.length];
            launcher.category = next.label === "All" ? "" : next.label;
            event.accepted = true;
        }
    }

    // ---- card contents --------------------------------------------------

    // header: arch badge + title + count
    Item {
        width: parent.width
        implicitHeight: 38

        Image {
            id: archMark
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            source: "file:///usr/share/pixmaps/archlinux-logo.svg"
            sourceSize: Qt.size(52, 52)
            width: 22
            height: 22
            smooth: true
            fillMode: Image.PreserveAspectFit
        }

        Text {
            anchors { left: archMark.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: "Applications"
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.text
        }

        Text {
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: launcher.apps.length + " / " + launcher.allApps.length
            font.family: Theme.font
            font.pixelSize: 10
            color: Theme.muted
        }
    }

    // search field
    Item {
        width: parent.width
        implicitHeight: 40

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 10
            color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.85)
            border.width: 1
            border.color: search.activeFocus
                ? Qt.rgba(Theme.foam.r, Theme.foam.g, Theme.foam.b, 0.55)
                : Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.28)
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            Text {
                id: searchGlyph
                anchors { left: parent.left; leftMargin: 11; verticalCenter: parent.verticalCenter }
                text: "󰍉"
                font.family: Theme.font
                font.pixelSize: 13
                color: search.activeFocus ? Theme.foam : Theme.muted
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            TextInput {
                id: search
                anchors {
                    left: searchGlyph.right
                    leftMargin: 9
                    right: parent.right
                    rightMargin: 11
                    verticalCenter: parent.verticalCenter
                }
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.text
                selectionColor: Qt.rgba(Theme.iris.r, Theme.iris.g, Theme.iris.b, 0.45)
                selectedTextColor: Theme.text
                selectByMouse: true
                clip: true

                onAccepted: launcher.launchAt(launcher.selected)

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: search.text === ""
                    text: "Search applications…"
                    font: search.font
                    color: Theme.muted
                }
            }
        }
    }

    // category chips — a Flow, not a scrolling row, so every category is
    // reachable without discovering that the strip scrolls
    Item {
        width: parent.width
        implicitHeight: chipFlow.implicitHeight + 8

        Flow {
            id: chipFlow
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.topMargin: 4
            spacing: 5

            Repeater {
                model: launcher.chips

                Rectangle {
                    id: chip
                    required property var modelData

                    readonly property bool picked:
                        (modelData.label === "All" && launcher.category === "")
                        || modelData.label === launcher.category

                    width: chipLabel.implicitWidth + 20
                    height: 24
                    radius: 12
                    color: picked
                        ? Qt.rgba(Theme.foam.r, Theme.foam.g, Theme.foam.b, 0.22)
                        : Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.7)
                    border.width: 1
                    border.color: picked
                        ? Qt.rgba(Theme.foam.r, Theme.foam.g, Theme.foam.b, 0.55)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: chip.modelData.label
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.weight: chip.picked ? Font.DemiBold : Font.Medium
                        color: chip.picked ? Theme.foam : Theme.subtle
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            launcher.category = chip.modelData.label === "All"
                                ? "" : chip.modelData.label;
                            search.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }

    // result list — grows with the results and stops at a fixed ceiling, so a
    // one-hit search is a small card rather than a mostly-empty one
    Item {
        width: parent.width
        implicitHeight: list.count === 0
            ? 64
            : Math.min(352, list.contentHeight + 8)

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 4
            anchors.rightMargin: 8
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: launcher.apps
            currentIndex: launcher.selected

            delegate: AppRow {
                required property int index
                required property var modelData

                width: list.width
                title: modelData.name
                subtitle: modelData.genericName && modelData.genericName !== modelData.name
                    ? modelData.genericName
                    : (modelData.comment || "")
                iconName: modelData.icon || ""
                selected: launcher.selected === index
                onActivated: launcher.launchAt(index)
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "nothing matches"
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.muted
            }
        }

        // hairline scrollbar
        Rectangle {
            visible: list.contentHeight > list.height
            anchors { right: parent.right; rightMargin: 2 }
            width: 3
            radius: 1.5
            color: Qt.rgba(Theme.iris.r, Theme.iris.g, Theme.iris.b, 0.55)
            y: 4 + list.visibleArea.yPosition * (parent.height - 8)
            height: Math.max(24, list.visibleArea.heightRatio * (parent.height - 8))
        }
    }

    // footer hints
    Item {
        width: parent.width
        implicitHeight: 22

        Text {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: "↑↓ move   ⏎ launch   ⇥ category   esc close"
            font.family: Theme.font
            font.pixelSize: 10
            color: Theme.muted
            opacity: 0.75
        }
    }
}
