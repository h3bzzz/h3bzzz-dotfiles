# fastfetch — rotating Rosé Pine themes

Every new terminal runs `ff`, which picks one of the themes below at random and
avoids the last two picks. Ghostty windows, tabs and splits each spawn a fresh
interactive shell, so every one of them draws its own theme.

Wired up near the top of `~/.zshrc`:

```sh
if [[ -o interactive && -t 1 && -z $TMUX && -z $_FF_GREETED ]]; then
	typeset -g _FF_GREETED=1
	if [[ -x $HOME/.local/bin/ff ]]; then
		$HOME/.local/bin/ff
	else
		command -v ff >/dev/null && ff || fastfetch
	fi
fi
```

Why it looks like that:

- `-t 1` — skip when stdout is redirected, so `zsh -c ... > file` stays clean.
- `-z $TMUX` — a tmux pane is not a new terminal; the window already greeted.
- `_FF_GREETED` — re-sourcing `~/.zshrc` does not re-fetch.
- **absolute path** — this block runs at line ~17 but `~/.local/bin` is only
  added to `PATH` at line ~250, so a bare `ff` is a coin flip depending on
  whatever `PATH` the compositor happened to export.

Ghostty is single-instance: `mainMod + Enter` opens a new window inside the
already-running `ghostty` process. That is fine — each window still spawns its
own shell — but it does mean **windows opened before a config change keep the
old behaviour**. Run `exec zsh` in an old window, or just open a new one.

## Layout

```
~/.config/fastfetch/
  config.jsonc      # plain `fastfetch` with no args (mirror of themes/classic)
  lib/rp.lua        # shared Rosé Pine palette + bar/frame/rain helpers
  themes/*.jsonc    # one file per theme
~/.local/bin/ff     # dispatcher
~/.local/state/fastfetch/last-theme
```

## Commands

| command | what it does |
| --- | --- |
| `ff` | random theme |
| `ff <theme>` | one theme by name (extra args pass through to fastfetch) |
| `ff list` / `ffl` | list themes, mark the last one used |
| `ff all` / `ffa` | render every theme back to back |
| `ff watch [secs]` | live dashboard, refreshes every N seconds (default 1) |
| `ff doctor` | what ff detected: resolved path, width, history, image support |
| `FF_THEME=crt ff` | pin a theme without editing anything |
| `FF_NO_NARROW=1 ff` | allow wide themes in a narrow terminal |

## Themes

| theme | look | cost |
| --- | --- | --- |
| `classic` | Arch logo, sectioned system/session/hardware, dashed bars | ~19 ms |
| `cyberdeck` | logo-less telemetry HUD, gradient bars, boxed frame | ~73 ms |
| `crt` | 1987 BBS status screen, double-line box, dot leaders | ~80 ms |
| `matrix` | monochrome green, procedural katakana rain header | ~66 ms |
| `wallpaper` | current Hyprland wallpaper as the logo (Kitty graphics) | ~11 ms |
| `minimal` | eight lines, small logo, muted | ~7 ms |
| `ticker` | three dense lines, no logo | ~66 ms |
| `live` | cyberdeck + real net/disk throughput — `ff watch` only | 1 s/frame |

Weights live in the `POOL` array in `~/.local/bin/ff`; repeat a name to make it
come up more often. Below 84 columns the dispatcher only draws `minimal` or
`ticker` so a cramped pane never renders a broken box — 84 is the floor where
`classic` (35-col logo + ~45-col info block) still fits. A half-screen Ghostty
tile on this display is 92 columns, so tiled windows keep the full pool.

Picks are recorded in `~/.local/state/fastfetch/history` (last two), written
atomically via `mktemp`+`mv` so two windows opening at once cannot tear it, and
drawn with `$SRANDOM` (kernel CSPRNG) so simultaneous launches cannot collide
on a seed.

If a theme ever repeats when you did not expect it, `ff doctor` shows the
detected width, the recent history, and whether the terminal can draw images.

## How the Lua works

fastfetch 2.64+ runs a format string as Lua when it starts with `lua:`. The
module's own values arrive as varargs, so `local d=...` then `d.percentage`.
One interpreter instance is shared by every module in a run, which is why the
first module can `dofile` the shared library and every later module just calls
`bar()`, `c()`, `frame()`.

```jsonc
{ "type": "memory", "format":
  "lua:local d=... return bar(pc(d.percentage),22)..c('muted',d.used..' / '..d.total)" }
```

To discover what a module exposes, dump it:

```jsonc
{ "type": "gpu", "format": "lua:return json_encode({...}, true)" }
```

The sandbox has `string`, `table`, `math`, `dofile` and fastfetch's
`json_encode` — no `os`, `io` or `package`. Randomness is seeded from the
`datetime` module (`seed(d)`), which is why the koans and the matrix rain differ
between terminals opened minutes apart.

## Gotchas found while building this

- Module options were removed from the CLI in 2.67 — `--custom-format` and
  friends now error out and everything has to go in the JSON config.
- `netio` and `diskio` sample over a hardcoded 1 s window and ignore
  `waitTime`, so they cost a full second. They are only in `live`. `cpuusage`
  *does* honour `waitTime` (set to 60 ms in the greeter themes).
- An unrecognised key on a module makes it render nothing instead of erroring.
- Percentage bars need bit 2 of `display.percent.type`; `10`/`11` give a
  monochrome bar you can colour yourself.
- `display.bar.charElapsed` was renamed to `display.bar.char.elapsed`.
- fastfetch prints one line per module and cannot suppress a line, so `ticker`
  stashes data in shared Lua state and its last module rewinds with `CUU`
  over the blanks. That trick is only safe when `logo.type` is `none`.

## Backups

`config.jsonc.bak` and `ff.old.bak` are the previous config and the old
root-owned `ff` script. `~/.zshrc.bak.ff` is the shell config from before.
