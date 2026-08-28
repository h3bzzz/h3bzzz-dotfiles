# thornwatch

Idle screensaver for this Hyprland setup. After ten minutes of no input it
takes the screen with rotating panels of text pushed through
[terminaltexteffects](https://github.com/ChrisBuilds/terminaltexteffects);
the first key, pointer move or touchpad tap tears it down and drops you on
hyprlock.

It is not Omarchy's screensaver. That one plays random effects over static
ASCII art. This one renders *this machine* — the clock, its vitals, the bug
bounty board under `~/bugs`, which git trees are dirty, and a flashcard deck
of things worth remembering — and colours all of it Rose Pine.

## Layout

```
~/.config/hypr/thornwatch/
├── ctl.sh              start | stop | wake | lock | toggle | status | test
├── thornwatch.sh       the render loop, runs inside the fullscreen terminal
├── thornwatch.conf     timings, terminal, panel weights, effect denylist
├── lib/
│   ├── bigtext.py      5x5 block font (figlet is not installed, on purpose)
│   ├── layout.sh       block-local centring helpers for panels
│   └── palette.sh      Rose Pine hexes and the gradient sets
├── panels/             one script per screen, each prints plain text
│   ├── sigil.sh        hostname wordmark + session line + a tagline
│   ├── clock.sh        wall clock, date, battery
│   ├── vitals.sh       cpu / mem / swap / disk / battery bars, thermals, net
│   ├── recon.sh        ~/bugs target board, sorted by last touched (cached)
│   ├── forge.sh        git repos with uncommitted or unpushed work
│   └── lore.sh         one card from data/lore.txt
└── data/lore.txt       the flashcard deck — add your own, it is just text
```

Touched outside this directory:

| File | Change |
|---|---|
| `~/.config/hypr/hypridle.conf` | 10 min → `ctl.sh start`, resume → `ctl.sh wake`, 15 min → `ctl.sh lock` |
| `~/.config/hypr/lua/rules.lua` | `thornwatch-saver` window rule (fullscreen, pinned, focused, opaque) |
| `~/.config/hypr/lua/binds.lua` | `SUPER+CTRL+ESC` toggle, `SUPER+SHIFT+ESC` kill |

`.pre-thornwatch` backups of all three sit next to the originals.

## The idle ladder

```
 5:00   backlight dims to 20%          (existing behaviour, untouched)
10:00   thornwatch starts               and restores brightness so you can see it
        any input  ->  saver down, hyprlock up
15:00   hard lock whether or not the saver was dismissed
15:30   display off
```

Waking from the saver **always** goes through hyprlock. That is the point: a
machine that has been unattended for ten minutes should ask who you are before
handing the desktop back. Waking from the manual toggle does not lock, because
you were sitting right there.

## How it exits

Two independent detectors, because they cover different hardware:

- **Keys** land in the terminal's tty buffer even while an effect is playing,
  and are drained by a non-blocking `read` on `/dev/tty`.
- **Pointer and touchpad** motion only shows up in the compositor, so the
  loop diffs `hyprctl cursorpos` every `TW_POLL` seconds.

Either one kills the running effect immediately rather than waiting out the
animation. Separately, hypridle sees the same input event and runs
`ctl.sh wake`, which is what actually raises hyprlock — the saver never locks
the screen itself, so there is exactly one place that decision is made.

If the saver ever gets stuck holding focus, `SUPER+SHIFT+ESC` kills it. That
bind is handled by the compositor, so a wedged window cannot block it.

## Tuning

Everything lives in `thornwatch.conf`.

- `TW_HOLD_MIN` / `TW_HOLD_MAX` — how long a finished frame sits before the
  next draw.
- `TW_WEIGHT_<panel>` — how many times a panel goes into the draw bag. Set to
  `0` to disable one without removing it from `TW_PANELS`.
- `TW_EFFECT_DENY` — space-separated effect names to skip. `blackhole`,
  `bubbles` and `bouncyballs` are out by default: they are slow and they
  scramble tabular panels into unreadable soup.
- `TW_FILL` — the glyph the block font is drawn with. `█ ▓ ▒ ░ ■` all work.
- `TW_FONT_SIZE` — bigger reads better from across the room; 15 fits the
  widest panel (vitals, ~82 columns) on a 1920px display.

Change the timings in `hypridle.conf`, then `pkill hypridle && hypridle &`.
Change the window rule or binds, then `hyprctl reload`.

## Writing a panel

A panel is any executable in `panels/` that prints plain text to stdout. It
gets `TW_DIR`, `TW_COLS`, `TW_ROWS` and `TW_FILL` in the environment, and it
must not print ANSI colour — tte owns the colour.

Do **not** centre against `TW_COLS`. tte centres the finished block in the
canvas, so centring twice pushes everything right by half the slack. Source
`lib/layout.sh` and pipe through `tw_block` instead:

```bash
. "$TW_DIR/lib/layout.sh"

{
    echo "${TW_C}A HEADING"        # centred over the block
    echo
    "$TW_DIR/lib/bigtext.py" -f "$TW_FILL" "BIG" | sed "s/^/$TW_G/"
    printf '  %s\n' "left-aligned content sets the block width"
} | tw_block
```

Then add the name to `TW_PANELS` and give it a `TW_WEIGHT_<name>`.

Preview one without waiting for the idle timer:

```bash
~/.config/hypr/thornwatch/ctl.sh test vitals
~/.config/hypr/thornwatch/ctl.sh test          # lists the panels
```

## Notes and limits

- **One monitor.** The saver is a single fullscreen window. On a multi-head
  setup the other outputs keep showing the desktop until the 15-minute hard
  lock. Fixing that means one terminal per monitor with `monitor:` rules.
- **Pin does not stick on fullscreen windows.** Hyprland only pins floating
  windows, so `pinned` reads false in `hyprctl clients`. It does not matter
  while the window holds focus, which the `stay_focused` rule guarantees.
- **`hyprctl keyword` is dead on this box.** The config is Lua, and the Lua
  parser rejects it with *"keyword can't work with non-legacy parsers. Use
  eval."* Runtime rule changes go through `hyprctl eval 'hl.window_rule({...})'`,
  which is also the cheapest way to check whether a rule field name is real —
  it validates one unknown field per call.
- **Caches** live in `~/.cache/thornwatch`: the effect list, one marker per
  effect recording whether it accepts `--final-gradient-*`, and the recon
  table (15 minute TTL, because walking 400k files under `~/bugs` is not
  something to do every five seconds). Delete the directory to rebuild.
