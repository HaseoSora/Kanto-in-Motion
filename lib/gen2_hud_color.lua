-- Gen 2 battle HUD light-ink option. Scope all palette changes strictly to
-- BattleState:drawHud; do not change the screen, sprites, or lower battle UI.
return function(mod)
  local okHud, Hud = pcall(require, "src.ui.gen2.BattleHud")
  local okBattle, Battle = pcall(require, "src.ui.gen2.BattleState")
  local okPalette, Palette = pcall(require, "src.render.GbcPalette")
  local okChrome, Chrome = pcall(require, "src.ui.gen2.Chrome")
  if not (okHud and okBattle and okPalette and okChrome)
      or type(Hud.drawTile) ~= "function"
      or type(Battle.drawHud) ~= "function"
      or type(Chrome.printThrough) ~= "function"
      or type(Chrome.printRightThrough) ~= "function" then return end
  if Hud._kimHudColorInstalled then return end
  Hud._kimHudColorInstalled = true

  local nativeDrawHud = Battle.drawHud
  local nativeDrawTile = Hud.drawTile
  local nativePrint = Chrome.printThrough
  local nativePrintRight = Chrome.printRightThrough
  local activeDepth = 0
  local white = { 255, 255, 255 }

  local function lightInk(source)
    local palette = type(source) == "table" and source or Palette.DMG_SHADES
    if type(palette) ~= "table" then return source end
    local result = { palette[1], palette[2], palette[3], white }
    return result
  end

  -- Text and gender symbols are rendered by Chrome, *not* BattleHud's tile
  -- renderer. Resolve the native text palette exactly once before replacing
  -- only its ink shade. This preserves existing paper/background colors.
  local function textPalette(palette, invert, raw)
    if type(Chrome.throughPalette) == "function" then
      local resolved
      if raw and type(Chrome.rawPalette) == "function" then
        resolved = Chrome.rawPalette(palette, invert)
      else
        resolved = Chrome.throughPalette(palette, invert)
      end
      return lightInk(resolved)
    end
    return lightInk(palette)
  end

  Battle.drawHud = function(self, ...)
    if mod.options and mod.options:get("gen2BattleHudColor") == "inverted" then
      activeDepth = activeDepth + 1
      local results = { pcall(nativeDrawHud, self, ...) }
      activeDepth = activeDepth - 1
      if not results[1] then error(results[2], 0) end
      return unpack(results, 2)
    end
    return nativeDrawHud(self, ...)
  end

  Hud.drawTile = function(self, key, first, tile, tx, ty, colors, mirror)
    -- The EXP strip contains several separately addressed cells ($54-$5c).
    -- v190 only handled $5c, leaving dark EXP-row ink during partial fills.
    -- Apply the selected inverted HUD ink to native caught tile $5d as
    -- well as the EXP border. QOL's separate RED/GREY indicator is not a
    -- BattleHud tile and retains its own appearance.
    local expInk = key == "expBar"
    if activeDepth > 0 and (key == "enemyBorder" or key == "playerBorder"
        or key == "hpBar" or expInk) then
      colors = lightInk(colors)
    end
    return nativeDrawTile(self, key, first, tile, tx, ty, colors, mirror)
  end

  Chrome.printThrough = function(text, tx, ty, palette, invert, raw)
    if activeDepth > 0 and Palette.available() then
      return nativePrint(text, tx, ty,
        textPalette(palette or Chrome.DEFAULT_BOX_PALETTE, invert, raw),
        false, true)
    end
    return nativePrint(text, tx, ty, palette, invert, raw)
  end

  Chrome.printRightThrough = function(text, tx, ty, palette, invert, raw)
    if activeDepth > 0 and Palette.available() then
      return nativePrintRight(text, tx, ty,
        textPalette(palette or Chrome.DEFAULT_BOX_PALETTE, invert, raw),
        false, true)
    end
    return nativePrintRight(text, tx, ty, palette, invert, raw)
  end
end
