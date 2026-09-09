-- Kanto in Motion: lightweight Gen 2 Modern UI bridge.
-- Gold/Crystal route most menu presentation through src.ui.gen2.Chrome, so
-- styling those shared primitives gives the native Gen 2 layouts a coherent
-- Modern UI treatment without replacing their game-specific logic.
return function(mod)
  local Chrome = require("src.ui.gen2.Chrome")
  if Chrome.__kantoInMotionModernUi then return true end
  Chrome.__kantoInMotionModernUi = true

  local Font = require("src.render.Font")
  local GbcPalette = require("src.render.GbcPalette")
  local G = love.graphics

  local SURFACE = { 0.095, 0.022, 0.036, 1.00 }
  local RAISED  = { 0.155, 0.035, 0.058, 1.00 }
  local ACCENT  = { 0.863, 0.078, 0.235, 1.00 }
  local TEXT    = { 0.965, 0.925, 0.940, 1.00 }
  -- GbcPalette entries are 0..255 RGB. Shade 3 is the font ink.
  local TEXT_PAL = {
    { 24, 6, 9 }, { 76, 18, 29 }, { 210, 90, 120 }, { 246, 236, 240 },
  }

  local original = {
    clear = Chrome.clear,
    box = Chrome.box,
    textbox = Chrome.textbox,
    print = Chrome.print,
    printThrough = Chrome.printThrough,
    printInverted = Chrome.printInverted,
    printRight = Chrome.printRight,
    cursor = Chrome.cursor,
    cursorThrough = Chrome.cursorThrough,
  }

  local function shaderReady()
    local ok, value = pcall(GbcPalette.available)
    return ok and value == true
  end

  local function modernText(text, px, py)
    if not shaderReady() then
      return Font.draw(text, px, py)
    end
    local previous = G.getShader()
    G.setColor(1, 1, 1, 1)
    GbcPalette.useRaw(TEXT_PAL)
    local width = Font.draw(text, px, py)
    G.setShader(previous)
    G.setColor(TEXT)
    return width
  end

  function Chrome.clear()
    G.setShader()
    G.setColor(SURFACE)
    G.rectangle("fill", 0, 0, Chrome.SCREEN_W * 8, Chrome.SCREEN_H * 8)
    G.setColor(TEXT)
  end

  function Chrome.box(tx, ty, tw, th)
    local x, y, w, h = tx * 8, ty * 8, tw * 8, th * 8
    G.setShader()
    G.setColor(RAISED)
    G.rectangle("fill", x, y, w, h)
    G.setColor(ACCENT)
    G.rectangle("line", x + 0.5, y + 0.5, math.max(0, w - 1), math.max(0, h - 1))
    G.setColor(TEXT)
  end

  function Chrome.textbox(tx, ty, interiorW, interiorH)
    Chrome.box(tx, ty, interiorW + 2, interiorH + 2)
  end

  function Chrome.print(text, tx, ty)
    return modernText(text, tx * 8, ty * 8)
  end

  function Chrome.printRight(text, txEnd, ty)
    local width = Font.width(text)
    return modernText(text, txEnd * 8 - width, ty * 8)
  end

  function Chrome.printThrough(text, tx, ty, palette, invert)
    return Chrome.print(text, tx, ty)
  end

  function Chrome.printInverted(text, tx, ty, palette)
    return Chrome.print(text, tx, ty)
  end

  local function modernCursor(tx, ty, hollow)
    if not shaderReady() then return original.cursor(tx, ty, hollow) end
    local previous = G.getShader()
    -- Cursor uses the same palette shader but with a saturated accent as ink.
    local cursorPal = {
      { 24, 6, 9 }, { 76, 18, 29 }, { 190, 45, 75 }, { 220, 20, 60 },
    }
    G.setColor(1, 1, 1, 1)
    GbcPalette.useRaw(cursorPal)
    Font.drawCode(hollow and Chrome.CURSOR_HOLLOW or Chrome.CURSOR,
      tx * 8, ty * 8)
    G.setShader(previous)
    G.setColor(TEXT)
  end

  Chrome.cursor = modernCursor
  function Chrome.cursorThrough(tx, ty, palette, invert, hollow)
    return modernCursor(tx, ty, hollow)
  end

  return true
end
