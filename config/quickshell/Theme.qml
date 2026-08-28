pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Palette. Colors.qml is regenerated from the current wallpaper by
    // ~/.config/hypr/scripts/apply-theme.sh, which then reloads quickshell.
    // Aliased here rather than used directly so the twenty-odd Theme.* call
    // sites across the dock, launcher and power menu keep working unchanged.
    readonly property color base:       Colors.base
    readonly property color surface:    Colors.surface
    readonly property color overlay:    Colors.overlay
    readonly property color muted:      Colors.muted
    readonly property color subtle:     Colors.subtle
    readonly property color text:       Colors.text
    readonly property color love:       Colors.love
    readonly property color gold:       Colors.gold
    readonly property color rose:       Colors.rose
    readonly property color pine:       Colors.pine
    readonly property color pineBright: Colors.pineBright
    readonly property color foam:       Colors.foam
    readonly property color iris:       Colors.iris

    readonly property string font: "JetBrainsMono Nerd Font"

    // Dock geometry
    readonly property int   slot:        58   // base cell width/height
    readonly property int   iconSize:    34
    readonly property int   padding:     10
    readonly property int   spacing:     6
    readonly property int   radius:      20
    readonly property real  magAmount:   0.55 // peak extra scale under cursor
    readonly property real  magSpread:   1.05 // how many neighbours ride along

    // ---- Popup surfaces (power menu, app launcher) ------------------
    //
    // Waybar sits at y=0 with height 34 and `margin-top: -2px` in its CSS, so
    // its painted bottom edge lands at 32. barGap is measured from there.
    readonly property int   barHeight:   34
    readonly property int   barMargin:   10   // waybar margin-left / margin-right
    readonly property int   barGap:      8    // breathing room under the bar
    readonly property int   popupTop:    barHeight - 2 + barGap
    readonly property int   popupRadius: 16
    readonly property int   popupPad:    8

    // Motion. Short enough to feel instant, long enough to read as intentional.
    readonly property int   animFast:    140
    readonly property int   animMed:     190

    // Screen dim behind an open popup.
    readonly property real  dimOpacity:  0.28

    // Safety net: a layer surface holding exclusive keyboard focus must never
    // be able to strand the session, so every popup self-closes when idle.
    readonly property int   idleCloseMs: 20000
}
