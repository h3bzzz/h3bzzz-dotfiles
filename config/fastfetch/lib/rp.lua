-- Rosé Pine helpers shared by every fastfetch theme.
-- Loaded once per run via dofile() from the first module of a theme.
-- The Lua interpreter instance is shared across modules, so everything
-- assigned to _G here is visible to every later module in the same run.

local E = string.char(27)

-- Palette. matugen regenerates lib/palette.lua from the wallpaper on every
-- theme change (see ~/.config/matugen/config.toml). The Rose Pine values below
-- are the fallback for a machine where matugen has not run yet -- a fresh
-- install.sh checkout, or a wallpaper change that failed. Every theme reads RP,
-- so wiring it here is what makes all eight of them follow the wallpaper.
RP = {
  base = '38;2;25;23;36',    surface = '38;2;31;29;46',   overlay = '38;2;38;35;58',
  muted = '38;2;110;106;134', subtle = '38;2;144;140;170', text = '38;2;224;222;244',
  love  = '38;2;235;111;146', gold   = '38;2;246;193;119', rose = '38;2;235;188;186',
  pine  = '38;2;49;116;143',  foam   = '38;2;156;207;216', iris = '38;2;196;167;231',
  hlmed = '38;2;64;61;82',    hlhigh = '38;2;82;79;103',
}

do
  -- '#rrggbb' -> '38;2;r;g;b'
  local function sgr(hex)
    local r, g, b = tostring(hex):match('^#?(%x%x)(%x%x)(%x%x)$')
    if not r then return nil end
    return '38;2;' .. tonumber(r, 16) .. ';' .. tonumber(g, 16) .. ';' .. tonumber(b, 16)
  end
  local gen = os.getenv('HOME') .. '/.config/fastfetch/lib/palette.lua'
  local f = loadfile(gen)
  if f then
    pcall(f)
    if type(PALETTE_HEX) == 'table' then
      for name, hex in pairs(PALETTE_HEX) do
        local v = sgr(hex)
        if v then RP[name] = v end
      end
    end
  end
end

-- c('foam', 'text') -> colored string, reset afterwards
function c(name, s) return E .. '[' .. (RP[name] or name) .. 'm' .. s .. E .. '[0m' end
function raw(name) return E .. '[' .. (RP[name] or name) .. 'm' end
local RESET = E .. '[0m'

-- Strip a percentage out of a possibly ANSI-colored fastfetch value ("22%").
function pc(s) return tonumber(tostring(s):match('(%d+%.?%d*)%%')) or 0 end

-- Visible width of a UTF-8 string, ignoring ANSI SGR sequences.
function vlen(s)
  s = s:gsub(E .. '%[[%d;]*m', '')
  local n = 0
  for _ in s:gmatch('[^\128-\191]') do n = n + 1 end
  return n
end

-- Threshold color: low usage = foam, mid = gold, high = love.
function heat(p) return p < 50 and RP.foam or (p < 80 and RP.gold or RP.love) end

-- Gradient usage bar. glyphs = {filled, empty}
function bar(p, w, glyphs)
  p = tonumber(p) or 0; w = w or 20
  local g = glyphs or { '▇', '▇' }
  local n = math.floor(p * w / 100 + 0.5)
  if n > w then n = w end
  return raw(heat(p)) .. string.rep(g[1], n) .. raw('hlmed') .. string.rep(g[2], w - n) .. RESET
end

-- Braille-ish meter: a compact 8-cell block gauge.
function meter(p, w)
  p = tonumber(p) or 0; w = w or 10
  local blocks = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' }
  local out, col = {}, raw(heat(p))
  for i = 1, w do
    local lvl = math.max(0, math.min(8, math.ceil((p / 100 * w - (i - 1)) * 8)))
    out[i] = lvl == 0 and (raw('hlmed') .. '▁') or (col .. blocks[lvl])
  end
  return table.concat(out) .. RESET
end

-- Box frame line padded to W columns. side = 'top' | 'bottom'
W = 66
function frame(side, body)
  local l, r = '╭', '╮'
  if side == 'bottom' then l, r = '╰', '╯' end
  local pad = W - 5 - vlen(body)
  if pad < 1 then pad = 1 end
  return raw('hlmed') .. l .. '── ' .. body .. ' ' .. raw('hlmed') .. string.rep('─', pad) .. r .. RESET
end

function rule(ch, n) return c('hlmed', string.rep(ch or '─', n or W)) end

-- Time-of-day greeting + accent color.
function greet(hour)
  if hour < 5  then return 'burning the midnight oil', 'iris'  end
  if hour < 12 then return 'good morning',             'gold'  end
  if hour < 17 then return 'good afternoon',           'foam'  end
  if hour < 22 then return 'good evening',             'rose'  end
  return 'still up', 'love'
end

-- Deterministic-per-minute picks so a burst of new terminals feels varied
-- but a single fetch stays internally consistent.
function seed(dt) math.randomseed(dt.year * 1000000 + dt.dayInYear * 10000 + dt.hour * 100 + dt.minute + dt.second * 7) end
function pick(t) return t[math.random(1, #t)] end

KOANS = {
  'the kernel does not care about your feelings',
  'rm -rf is a lifestyle, not a mistake',
  'it compiles. ship it.',
  'there is no cloud, only someone else computer',
  'grep is the only debugger you need',
  'a dotfile repo is a self portrait',
  'every config is temporary until it is not',
  'the terminal is the last honest interface',
  'suckless until it does',
  'i use arch, but quietly',
  'entropy is just uncommitted work',
  'ricing is meditation with a compiler',
}

-- ── CRT / BBS box helpers ───────────────────────────────────────────────
-- Double-line box row padded to W columns: ║ LABEL......... value        ║
function boxrow(label, value, labelcolor, valuecolor, dotcolor)
  labelcolor = labelcolor or 'gold'; valuecolor = valuecolor or 'rose'; dotcolor = dotcolor or 'hlmed'
  local dots = 14 - #label
  if dots < 1 then dots = 1 end
  local body = label .. string.rep('.', dots) .. ' ' .. value
  local pad = W - 4 - vlen(body)
  if pad < 0 then pad = 0 end
  return c('hlmed', '║ ') .. c(labelcolor, label) .. c(dotcolor, string.rep('.', dots)) .. ' '
      .. c(valuecolor, value) .. string.rep(' ', pad) .. c('hlmed', ' ║')
end

function boxline(kind)
  local l, m, r = '╔', '═', '╗'
  if kind == 'mid'    then l, m, r = '╠', '═', '╣' end
  if kind == 'bottom' then l, m, r = '╚', '═', '╝' end
  return c('hlmed', l .. string.rep(m, W - 2) .. r)
end

function boxtitle(text, color)
  local pad = W - 4 - vlen(text)
  if pad < 0 then pad = 0 end
  return c('hlmed', '║ ') .. c(color or 'love', text) .. string.rep(' ', pad) .. c('hlmed', ' ║')
end

-- ── matrix rain ─────────────────────────────────────────────────────────
GREEN = { '38;2;15;47;26', '38;2;22;101;52', '38;2;34;164;73', '38;2;57;211;83', '38;2;150;255;170' }
GLYPHS = { 'ｱ','ｲ','ｳ','ｴ','ｵ','ｶ','ｷ','ｸ','ｹ','ｺ','ｻ','ｼ','ｽ','ｾ','ｿ','ﾀ','ﾁ','ﾂ','ﾃ','ﾄ','ﾅ','ﾆ','ﾇ','ﾈ','ﾉ','ﾊ','ﾋ','ﾌ','ﾍ','ﾎ','0','1','7','9','Z','X','λ','Ξ','Ψ' }

-- One row of rain. density 0..1 controls how many columns are lit.
function rainrow(cols, density)
  local out = {}
  for _ = 1, cols do
    if math.random() < (density or 0.55) then
      local shade = GREEN[math.random(1, #GREEN)]
      out[#out + 1] = raw(shade) .. GLYPHS[math.random(1, #GLYPHS)]
    else
      out[#out + 1] = ' '
    end
  end
  return table.concat(out) .. string.char(27) .. '[0m'
end

function rainblock(rows, cols)
  local out = {}
  for i = 1, rows do out[i] = rainrow(cols, 0.30 + (i / rows) * 0.45) end
  return table.concat(out, '\n')
end

-- ── line-merge helpers (ticker theme) ───────────────────────────────────
-- fastfetch prints one line per module and offers no way to suppress a line,
-- so "stash" modules (format returns '') each leave a blank line behind.
-- The final module rewinds over them with CUU and repaints, then ED clears
-- whatever is left below. Only safe when logo.type is "none".
function rewind(n) return string.char(27) .. '[' .. n .. 'A' end
function clearbelow() return string.char(27) .. '[J' end
function dot() return c('hlmed', '  ·  ') end
