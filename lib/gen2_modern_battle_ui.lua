-- Kanto in Motion v1.7.3 - Gen 2 Modern Battle UI adapter v32
--
-- Presentation-only: Gold/Silver/Crystal keep their native BattleState,
-- input, battle logic, HP/status HUD, trainers, child menus and move
-- animations.  KIM suppresses only BattleState:drawBottom() through the
-- public battle.bottom_ui_visible seam and redraws that lower surface at
-- final window resolution through render.hud. v2 follows the native battle\n-- panel width (160px normal / 304px WideBattle) instead of a fixed card.
return function(mod)
  local G = love.graphics
  local Style = mod._kantoInMotionGen2Ui
  local okStrings, Strings = pcall(require, "src.core.Strings")
  local okTypeChart, TypeChart = pcall(require, "src.battle.TypeChart")
  local okChrome, Chrome = pcall(require, "src.ui.gen2.Chrome")

  -- Reuse the same built-in color identities as KIM's Gen 1 Modern UI.
  -- This Gen 2 adapter only needs the battle-panel color tokens; layout and
  -- the native G/S/C HP/status HUD remain Gen 2-owned.
  local THEMES = {
    default = {
      surface = { 0.075, 0.105, 0.17, 0.98 },
      raised = { 0.12, 0.17, 0.27, 1.00 },
      selected = { 0.18, 0.43, 0.72, 1.00 },
      accent = { 0.48, 0.86, 1.00, 1.00 },
      frame = { 0.48, 0.86, 1.00, 1.00 },
      frameShadow = { 0.01, 0.02, 0.04, 0.42 },
      text = { 0.96, 0.98, 1.00, 1.00 },
      muted = { 0.74, 0.82, 0.92, 1.00 },
      divider = { 0.38, 0.50, 0.68, 0.94 },
    },
    ["gen1_modern_ui:classic_mono"] = {
      surface = { 0.96, 0.95, 0.89, 1 },
      raised = { 0.86, 0.85, 0.78, 1 },
      selected = { 0.72, 0.77, 0.72, 1 },
      accent = { 0.06, 0.09, 0.12, 1 },
      frame = { 0.06, 0.09, 0.12, 1 },
      frameShadow = { 0.16, 0.17, 0.16, 0.55 },
      text = { 0.035, 0.045, 0.055, 1 },
      muted = { 0.25, 0.30, 0.36, 1 },
      divider = { 0.34, 0.40, 0.47, 0.94 },
    },
    ["gen1_modern_ui:crimson"] = {
      surface = { 0.095, 0.022, 0.036, 0.99 },
      raised = { 0.155, 0.035, 0.058, 1.00 },
      selected = { 0.300, 0.055, 0.100, 1.00 },
      accent = { 0.863, 0.078, 0.235, 1.00 },
      frame = { 0.863, 0.078, 0.235, 1.00 },
      frameShadow = { 0.190, 0.018, 0.045, 0.98 },
      text = { 1.000, 0.955, 0.965, 1.00 },
      muted = { 0.850, 0.660, 0.700, 1.00 },
      divider = { 0.500, 0.105, 0.190, 0.96 },
    },
    ["gen1_modern_ui:crimson_glass"] = {
      surface = { 0.095, 0.022, 0.036, 0.88 },
      raised = { 0.155, 0.035, 0.058, 0.92 },
      selected = { 0.300, 0.055, 0.100, 0.94 },
      accent = { 0.863, 0.078, 0.235, 1.00 },
      frame = { 0.863, 0.078, 0.235, 1.00 },
      frameShadow = { 0.190, 0.018, 0.045, 0.86 },
      text = { 1.000, 0.955, 0.965, 1.00 },
      muted = { 0.850, 0.660, 0.700, 1.00 },
      divider = { 0.500, 0.105, 0.190, 0.88 },
    },
    ["gen1_modern_ui:modern_glass"] = {
      surface = { 0.055, 0.085, 0.15, 0.94 },
      raised = { 0.105, 0.155, 0.25, 0.96 },
      selected = { 0.20, 0.48, 0.78, 0.98 },
      accent = { 0.48, 0.86, 1.00, 1.00 },
      frame = { 0.48, 0.86, 1.00, 1.00 },
      frameShadow = { 0.01, 0.02, 0.04, 0.36 },
      text = { 0.96, 0.98, 1.00, 1.00 },
      muted = { 0.76, 0.84, 0.94, 1 },
      divider = { 0.38, 0.52, 0.72, 0.92 },
    },
    ["gen1_modern_ui:pocket_green"] = {
      surface = { 0.84, 0.88, 0.70, 1 },
      raised = { 0.73, 0.80, 0.58, 1 },
      selected = { 0.62, 0.73, 0.46, 1 },
      accent = { 0.07, 0.20, 0.14, 1 },
      frame = { 0.07, 0.20, 0.14, 1 },
      frameShadow = { 0.07, 0.12, 0.08, 0.55 },
      text = { 0.045, 0.095, 0.065, 1 },
      muted = { 0.18, 0.27, 0.19, 1 },
      divider = { 0.27, 0.38, 0.24, 0.96 },
    },
    ["gen1_modern_ui:midnight"] = {
      surface = { 0.035, 0.045, 0.075, 1 },
      raised = { 0.075, 0.090, 0.150, 1 },
      selected = { 0.24, 0.18, 0.48, 1 },
      accent = { 0.70, 0.58, 1.00, 1 },
      frame = { 0.70, 0.58, 1.00, 1 },
      frameShadow = { 0.025, 0.02, 0.06, 0.90 },
      text = { 0.96, 0.95, 1.00, 1 },
      muted = { 0.74, 0.76, 0.89, 1 },
      divider = { 0.34, 0.38, 0.54, 0.96 },
    },
    ["gen1_modern_ui:midnight_glass"] = {
      surface = { 0.035, 0.045, 0.075, 0.94 },
      raised = { 0.075, 0.090, 0.150, 0.96 },
      selected = { 0.24, 0.18, 0.48, 0.98 },
      accent = { 0.70, 0.58, 1.00, 1 },
      frame = { 0.70, 0.58, 1.00, 1 },
      frameShadow = { 0.025, 0.02, 0.06, 0.62 },
      text = { 0.96, 0.95, 1.00, 1 },
      muted = { 0.74, 0.76, 0.89, 1 },
      divider = { 0.34, 0.38, 0.54, 0.94 },
    },
    ["gen1_modern_ui:frost"] = {
      surface = { 0.96, 0.98, 1.00, 1 },
      raised = { 0.88, 0.93, 0.98, 1 },
      selected = { 0.38, 0.63, 0.88, 1 },
      accent = { 0.04, 0.38, 0.66, 1 },
      frame = { 0.04, 0.38, 0.66, 1 },
      frameShadow = { 0.17, 0.25, 0.34, 0.48 },
      text = { 0.055, 0.095, 0.160, 1 },
      muted = { 0.24, 0.32, 0.43, 1 },
      divider = { 0.36, 0.49, 0.63, 0.96 },
    },
    ["gen1_modern_ui:light"] = {
      surface = { 0.98, 0.98, 0.96, 1 },
      raised = { 0.89, 0.90, 0.88, 1 },
      selected = { 0.40, 0.63, 0.88, 1 },
      accent = { 0.07, 0.24, 0.46, 1 },
      frame = { 0.07, 0.24, 0.46, 1 },
      frameShadow = { 0.20, 0.22, 0.25, 0.42 },
      text = { 0.035, 0.050, 0.085, 1 },
      muted = { 0.24, 0.29, 0.36, 1 },
      divider = { 0.36, 0.43, 0.52, 1 },
    },
    ["gen1_modern_ui:dark"] = {
      surface = { 0.055, 0.065, 0.085, 1 },
      raised = { 0.105, 0.125, 0.155, 1 },
      selected = { 0.25, 0.52, 0.78, 1 },
      accent = { 0.52, 0.85, 1.00, 1 },
      frame = { 0.52, 0.85, 1.00, 1 },
      frameShadow = { 0.01, 0.015, 0.025, 0.90 },
      text = { 0.96, 0.98, 1.00, 1 },
      muted = { 0.73, 0.78, 0.88, 1 },
      divider = { 0.34, 0.44, 0.56, 1 },
    },
  }

  local COLORS = THEMES.default

  -- Shared palette source for the rest of the Gen 2 Modern UI adapters.
  -- Party/Summary/Pokedex can reuse the exact same theme selector without
  -- copying a second, independently drifting set of colours.
  mod._kantoInMotionGen2Themes = THEMES

  local fontCache = {}
  local PLAIN_PIXEL = "assets/fonts/plainpixel/PlainPixel-Regular.ttf"

  local function opt(key, fallback)
    if not (mod.options and type(mod.options.get) == "function") then
      return fallback
    end
    local ok, value = pcall(mod.options.get, mod.options, key)
    if not ok or value == nil then return fallback end
    return value
  end

  local function enabled()
    if Style and Style.presenterEnabled then return Style.presenterEnabled("battle") end
    return opt("gen2IntegratedModernUi", true) ~= false
      and opt("battleUiWip", true) ~= false
  end

  local function hideOriginal()
    if Style and Style.hideOriginal then return Style.hideOriginal() end
    return true
  end

  local function color(c, alpha, foreground)
    if Style and Style.color then return Style.color(c,alpha,foreground) end
    local a = alpha == nil and (c[4] or 1) or alpha
    G.setColor(c[1] or 1, c[2] or 1, c[3] or 1, a)
  end

  local function currentCanvasSize()
    local canvas = type(G.getCanvas) == "function" and G.getCanvas() or nil
    if canvas and type(canvas.getDimensions) == "function" then
      local ok, w, h = pcall(canvas.getDimensions, canvas)
      if ok and w and h then return w, h end
    end
    if type(G.getDimensions) == "function" then return G.getDimensions() end
    return 160, 144
  end

  local function mobileHost()
    if type(mod._kantoInMotionNativeMobileHost) == "function" then
      local ok, value = pcall(mod._kantoInMotionNativeMobileHost)
      if ok then return value == true end
    end
    if love and love.system and type(love.system.getOS) == "function" then
      local ok, name = pcall(love.system.getOS)
      return ok and (name == "Android" or name == "iOS")
    end
    return false
  end

  local UNSUPPORTED = {
    ["choose-forget"] = true,
    ["ask-nickname"] = true,
    ["ask-forget"] = true,
    ["stop-learning"] = true,
    ["ask-shift"] = true,
    ["ask-next-mon"] = true,
    ["stats-box"] = true,
  }

  local function hasMessage(state)
    return state and type(state.message) == "string" and state.message ~= ""
  end

  local function supportedSurface(state)
    if not (enabled() and type(state) == "table" and state.isBattle == true) then
      return false
    end
    local phase = tostring(state.phase or "")
    if UNSUPPORTED[phase] then return false end
    if phase == "menu" or phase == "moves" then return true end
    return hasMessage(state)
  end

  local function topGen2Battle(game)
    local stack = game and game.stack
    local top = stack and type(stack.top) == "function" and stack:top() or nil
    if type(top) == "table" and top.isBattle == true
        and top.battle ~= nil and top.phase ~= nil then
      return top
    end
    return nil
  end

  local function battleRect(state, viewport)
    local winW = tonumber(viewport and viewport.width)
    local winH = tonumber(viewport and viewport.height)
    if not (winW and winH and winW > 0 and winH > 0) then
      winW, winH = G.getDimensions()
    end

    -- Gen 2 has two native battle surfaces:
    --   normal: 160x144
    --   WIDE:   304x144
    --
    -- render.hud's gameWidth/gameHeight always describe the ordinary
    -- 160x144 fit rectangle, even when BattleState itself is currently
    -- drawing the 304px WideBattle surface. v1 therefore looked like a
    -- narrow centred card inside a widescreen battle. Reconstruct the same
    -- battle panel rectangle BattleState/WideBattle actually uses so KIM's
    -- Modern lower UI naturally expands and contracts with the active layout.
    if okChrome and Chrome and type(state) == "table"
        and type(state.panelSize) == "function"
        and type(state.battlePanelScale) == "function"
        and type(Chrome.fitOriginFor) == "function" then
      local okSize, panelW, panelH = pcall(state.panelSize, state)
      local okScale, scale = pcall(state.battlePanelScale, state, winW, winH)
      panelW, panelH, scale = tonumber(panelW), tonumber(panelH), tonumber(scale)
      if okSize and okScale and panelW and panelH and scale
          and panelW > 0 and panelH > 0 and scale > 0 then
        local tilesW, tilesH = panelW / 8, panelH / 8
        local okOrigin, ox, oy = pcall(Chrome.fitOriginFor,
          winW, winH, scale, tilesW, tilesH)
        if okOrigin and tonumber(ox) and tonumber(oy) then
          return ox, oy, panelW * scale, panelH * scale, scale
        end
      end
    end

    -- Fallback to the ordinary 160x144 render.hud viewport.
    local x = tonumber(viewport and viewport.gameX) or 0
    local y = tonumber(viewport and viewport.gameY) or 0
    local w = tonumber(viewport and viewport.gameWidth)
    local h = tonumber(viewport and viewport.gameHeight)
    if not (w and h and w > 0 and h > 0) then
      local scale = math.max(1, math.floor(math.min(winW / 160, winH / 144)))
      w, h = 160 * scale, 144 * scale
      x, y = (winW - w) * 0.5, (winH - h) * 0.5
      return x, y, w, h, scale
    end
    return x, y, w, h, math.max(0.5, math.min(w / 160, h / 144))
  end

  local function fontFor(px)
    if Style and Style.font then return Style.font(px) end
    px = math.max(8, math.floor(px + 0.5))
    local hit = fontCache[px]
    if hit then return hit end
    local ok, f = pcall(G.newFont, PLAIN_PIXEL, px, "mono", 1)
    if not ok or not f then ok, f = pcall(G.newFont, px) end
    if ok and f then
      if type(f.setFilter) == "function" then
        pcall(f.setFilter, f, "nearest", "nearest")
      end
      fontCache[px] = f
      return f
    end
    return G.getFont()
  end

  local function fitBattleFont(basePx,value,maxW,maxH)
    local px=math.max(7,tonumber(basePx) or 7)
    value=tostring(value or "")
    local f=fontFor(px)
    while px>7 and ((maxW and f:getWidth(value)>maxW)
        or (maxH and f:getHeight()>maxH)) do
      local wr=maxW and (maxW/math.max(1,f:getWidth(value))) or 1
      local hr=maxH and (maxH/math.max(1,f:getHeight())) or 1
      local ratio=math.max(.62,math.min(.96,wr,hr))
      local nextPx=math.max(7,math.min(px-1,px*ratio))
      if nextPx>=px then nextPx=px-1 end
      px=nextPx; f=fontFor(px)
    end
    return f
  end

  local function localized(text)
    if okStrings and type(Strings) == "table" then return tostring(text or "") end
    if okStrings and type(Strings) == "function" then
      local ok, value = pcall(Strings, text)
      if ok and value ~= nil then return tostring(value) end
    end
    return tostring(text or "")
  end

  local function truncate(text, font, maxW)
    text = tostring(text or "")
    if not font or type(font.getWidth) ~= "function"
        or font:getWidth(text) <= maxW then return text end
    local ellipsis = "..."
    local target = math.max(0, maxW - font:getWidth(ellipsis))
    while #text > 0 and font:getWidth(text) > target do
      text = text:sub(1, #text - 1)
    end
    return text .. ellipsis
  end

  local function drawText(text, font, x, y, maxW, align, c)
    if Style and Style.text then return Style.text(text,font,x,y,maxW,align,c or COLORS.text) end
    if font then G.setFont(font) end
    color(c or COLORS.text,nil,true)
    text = tostring(text or "")
    if maxW and maxW > 0 then
      local ok = pcall(G.printf, text, x, y, maxW, align or "left")
      if ok then return end
      text = text:gsub("[\128-\255]", "?")
      G.printf(text, x, y, maxW, align or "left")
    else
      local ok = pcall(G.print, text, x, y)
      if not ok then G.print(text:gsub("[\128-\255]", "?"), x, y) end
    end
  end

  local function drawDownArrow(x,y,size,colorValue)
    local half=size*.5
    color(colorValue)
    G.polygon("fill", x-half, y, x+half, y, x, y+size)
  end

  local function roundedPanel(x, y, w, h, alpha, scale)
    if Style and Style.panel then return Style.panel(x,y,w,h,COLORS,alpha) end
    local r = math.max(3, 3.0 * scale)
    local shadow = COLORS.frameShadow or { 0.01, 0.02, 0.04, 0.42 }
    local lineW = math.max(1, scale * 0.65)

    -- The user-facing expectation here is a centered inner surface, not a
    -- theme-colored drop shadow that makes the fill appear shifted down/right.
    -- Keep only a very subtle neutral shadow so the panel reads cleanly.
    local shadowAlpha = math.min(0.18, (shadow[4] or 1) * 0.18 * alpha)
    color({ 0.0, 0.0, 0.0, 1.0 }, shadowAlpha)
    G.rectangle("fill", x + scale * 0.5, y + scale * 0.75, w, h, r, r)

    -- Inset the interior by the full effective frame thickness so the surface
    -- sits visually centered inside the border on all themes, including crimson.
    local inset = math.max(1.5, lineW + math.max(0.75, scale * 0.35))
    local innerX = x + inset
    local innerY = y + inset
    local innerW = math.max(1, w - inset * 2)
    local innerH = math.max(1, h - inset * 2)
    local innerR = math.max(1, r - inset * 0.45)
    local surfaceAlpha = math.min(1, (COLORS.surface[4] or 1) * alpha)
    color(COLORS.surface, surfaceAlpha)
    G.rectangle("fill", innerX, innerY, innerW, innerH, innerR, innerR)

    color(COLORS.frame or COLORS.accent, 1)
    G.setLineWidth(lineW)
    G.rectangle("line", x, y, w, h, r, r)
  end

  local function selectedCell(x, y, w, h, scale)
    local r = math.max(2, 2 * scale)
    color(COLORS.selected)
    G.rectangle("fill", x, y, w, h, r, r)
    color(COLORS.accent,nil,true)
    G.rectangle("fill", x, y, math.max(2, 1.5 * scale), h, r, r)
  end

  local function stateMessageLines(state)
    if type(state.messageLines) == "function" then
      local ok, lines = pcall(state.messageLines, state)
      if ok and type(lines) == "table" then return lines end
    end
    local message = tostring(state.message or "")
    local lines = {}
    for line in message:gmatch("[^\n\r]+") do lines[#lines + 1] = line end
    if #lines == 0 and message ~= "" then lines[1] = message end
    return lines
  end

  local function commandLabels(state)
    -- Use ordinary localized labels rather than Gen 2's two-glyph <PK><MN>
    -- tile macro because this presenter is a TTF/final-window surface.
    local labels = {
      localized("FIGHT"),
      localized("POKéMON"),
      localized(state.contest and "PARK BALL" or "PACK"),
      localized("RUN"),
    }
    return labels
  end

  local function moveDefinition(state, move)
    local moves = state and state.game and state.game.data and state.game.data.moves
    return moves and move and moves[move.id] or nil
  end

  local function moveName(state, move)
    local def = moveDefinition(state, move)
    return tostring((def and def.name) or (move and move.id) or "—")
  end

  local function typeName(state, move)
    local def = moveDefinition(state, move)
    local value = def and def.type
    if okTypeChart and type(TypeChart) == "table"
        and type(TypeChart.displayName) == "function" and value then
      local ok, name = pcall(TypeChart.displayName, value,
        state and state.game and state.game.data)
      if ok and name then return tostring(name) end
    end
    return tostring(value or "—")
  end

  local function maxPp(state, move)
    if not move then return 0 end
    if tonumber(move.maxPp) then return tonumber(move.maxPp) end
    local def = moveDefinition(state, move)
    return tonumber(def and def.pp) or 0
  end

  local function powerText(def)
    local p = tonumber(def and def.power)
    if not p or p <= 0 then return "—" end
    return tostring(math.floor(p))
  end

  local function accuracyText(def)
    local a = tonumber(def and def.accuracy)
    if not a or a <= 0 then return "—" end
    if a <= 1 then a = a * 100 end
    -- Gen 2 extracted move records can expose either percent or the cart's
    -- 0-255 accuracy byte. Convert the latter to a readable percentage.
    if a > 100 and a <= 255 then a = a * 100 / 255 end
    return tostring(math.floor(a + 0.5)) .. "%"
  end

  -- PlainPixel and some user-selected fonts omit Unicode gender glyphs.
  -- Keep the engine's original battle text/typewriter state and replace only
  -- displayed gender characters with the same vector marks as the Party UI.
  local function drawMessageGender(cx, cy, size, female)
    size=math.max(7,tonumber(size) or 10)
    color(COLORS.text,nil,true)
    local previousWidth=G.getLineWidth()
    G.setLineWidth(math.max(1,size*.12))
    local r=size*.22
    if female then
      local ox,oy=cx,cy-size*.12
      G.circle("line",ox,oy,r)
      G.line(ox,oy+r,ox,cy+size*.34)
      G.line(ox-size*.18,cy+size*.16,ox+size*.18,cy+size*.16)
    else
      local ox,oy=cx-size*.10,cy+size*.08
      G.circle("line",ox,oy,r)
      local ex,ey=cx+size*.34,cy-size*.34
      G.line(ox+r*.72,oy-r*.72,ex,ey)
      G.line(ex-size*.18,ey,ex,ey,ex,ey+size*.18)
    end
    G.setLineWidth(previousWidth)
  end

  local function drawMessageWithGender(line,font,x,y,maxW)
    line=tostring(line or "")
    if not (line:find("♀",1,true) or line:find("♂",1,true)) then
      return drawText(line,font,x,y,maxW,"left",COLORS.text)
    end
    local remaining=line
    local cursor=x
    local symbolSize=math.max(7,font:getHeight()*.70)
    local glyphAdvance=math.max(symbolSize*.85,font:getHeight()*.56)
    while #remaining>0 do
      local fi=remaining:find("♀",1,true)
      local mi=remaining:find("♂",1,true)
      local at,female
      if fi and (not mi or fi<mi) then at=fi;female=true
      elseif mi then at=mi;female=false end
      if not at then
        if cursor<x+maxW then drawText(remaining,font,cursor,y,math.max(1,x+maxW-cursor),"left",COLORS.text) end
        break
      end
      local prefix=remaining:sub(1,at-1)
      if prefix~="" then
        drawText(prefix,font,cursor,y,math.max(1,x+maxW-cursor),"left",COLORS.text)
        cursor=cursor+font:getWidth(prefix)
      end
      if cursor+glyphAdvance>x+maxW then break end
      drawMessageGender(cursor+glyphAdvance*.5,y+font:getHeight()*.52,symbolSize,female)
      cursor=cursor+glyphAdvance
      remaining=remaining:sub(at+3) -- UTF-8 gender signs each occupy three bytes
    end
  end

  local function drawMessage(state, x, y, w, h, bodyFont, captionFont, scale)
    local pad = math.max(4, 4 * scale)
    local lines = stateMessageLines(state)
    local lineH = bodyFont:getHeight()
    local maxLines = math.max(1, math.floor((h - pad * 2) / math.max(1, lineH)))
    for i = 1, math.min(#lines, maxLines) do
      drawMessageWithGender(lines[i], bodyFont, x + pad,
        y + pad + (i - 1) * lineH, w - pad * 2)
    end
    if type(state.messageArrowVisible) == "function" then
      local ok, visible = pcall(state.messageArrowVisible, state)
      if ok and visible then
        local arrowSize=math.max(8, captionFont:getHeight()*.68)
        drawDownArrow(x + w - pad - arrowSize*.45,
          y + h - pad - arrowSize,
          arrowSize, COLORS.accent)
      end
    end
  end

  local function drawCommands(state, x, y, w, h, bodyFont, captionFont, scale, portrait)
    local pad = math.max(3, 3.5 * scale)
    local labels = commandLabels(state)
    local gap = math.max(2, 2 * scale)
    local menuX,menuY,menuW,menuH=x,y,w,h
    if hasMessage(state) then
      if portrait then
        local msgH=math.min(h*.28,bodyFont:getHeight()*2+pad*2)
        drawMessage(state,x,y,w,msgH,bodyFont,captionFont,scale)
        color(COLORS.divider,nil,true)
        G.rectangle("fill",x+pad,y+msgH+gap*.25,w-pad*2,math.max(1,scale*.45))
        menuY=y+msgH+gap; menuH=h-msgH-gap
      else
        local messageW = math.max(w * 0.32, 42 * scale)
        menuX=x+messageW+gap; menuW=w-messageW-gap
        drawMessage(state,x,y,messageW,h,bodyFont,captionFont,scale)
        color(COLORS.divider,nil,true)
        G.rectangle("fill",menuX-gap*.5,y+pad,math.max(1,scale*.45),h-pad*2)
      end
    end

    local cellGap = math.max(2, 2 * scale)
    local cellW = (menuW - cellGap) * 0.5
    local cellH = (menuH - cellGap) * 0.5
    local selected = tonumber(state.menuIndex) or 1
    for i = 1, 4 do
      local col = (i - 1) % 2
      local row = math.floor((i - 1) / 2)
      local cx = menuX + col * (cellW + cellGap)
      local cy = menuY + row * (cellH + cellGap)
      if i == selected then selectedCell(cx, cy, cellW, cellH, scale) end
      local f=fitBattleFont((bodyFont:getHeight()/math.max(1,scale))*scale,labels[i],cellW-pad*2,cellH*.72)
      drawText(labels[i],f,cx+pad,cy+(cellH-f:getHeight())*.5,
        cellW-pad*2,"center",i==selected and COLORS.text or COLORS.muted)
    end
  end

  local function drawMoveInfo(state, move, x, y, w, h, bodyFont, captionFont, scale)
    local pad = math.max(3, 3.5 * scale)
    local def = moveDefinition(state, move)
    local arrowSize=math.max(8, captionFont:getHeight()*.68)
    drawDownArrow(x + w - pad - arrowSize*.45,
      y + h - pad - arrowSize,
      arrowSize, COLORS.accent)

    -- Do not hard-truncate the selected move at larger BATTLE TEXT SIZE values.
    -- Fit the complete name to the info column first, then fit each detail row
    -- independently. This keeps 125-200% useful instead of turning names into
    -- strings such as "HYDRO P..." or dropping the lower detail rows.
    local name = moveName(state, move)
    local nameFont = fitBattleFont(bodyFont:getHeight(), name,
      w - pad * 2, math.max(8, h * .30))
    local yy = y + pad
    drawText(name, nameFont, x + pad, yy, w - pad * 2, "left", COLORS.text)
    yy = yy + nameFont:getHeight() + math.max(1, scale * .55)

    local rows = {
      "TYPE  " .. typeName(state, move),
      ("PP    %d/%d"):format(tonumber(move and move.pp) or 0, maxPp(state, move)),
      "POW   " .. powerText(def),
      "ACC   " .. accuracyText(def),
    }
    local available = math.max(1, y + h - pad - arrowSize * .35 - yy)
    local rowH = available / #rows
    for _, row in ipairs(rows) do
      local rf = fitBattleFont(captionFont:getHeight(), row,
        w - pad * 2, math.max(6, rowH * .88))
      drawText(row, rf, x + pad, yy, w - pad * 2, "left", COLORS.muted)
      yy = yy + rowH
    end
  end

  local function drawMoveInfoCompact(state, move, x, y, w, h, bodyFont, captionFont, scale)
    local pad=math.max(3,3*scale)
    local def=moveDefinition(state,move)
    local name=moveName(state,move)
    local nf=fitBattleFont(bodyFont:getHeight(),name,w-pad*2,h*.38)
    drawText(name,nf,x+pad,y+pad,w-pad*2,"left",COLORS.text)
    local rows={
      "TYPE "..typeName(state,move),
      ("PP %d/%d"):format(tonumber(move and move.pp) or 0,maxPp(state,move)),
      "POW "..powerText(def),
      "ACC "..accuracyText(def),
    }
    local infoY=y+pad+nf:getHeight()+math.max(1,scale)
    local cellW=(w-pad*2)/4
    for i,row in ipairs(rows) do
      local f=fitBattleFont(captionFont:getHeight(),row,cellW-math.max(2,2*scale),h-(infoY-y)-pad)
      drawText(row,f,x+pad+(i-1)*cellW,infoY,cellW-math.max(2,2*scale),"center",COLORS.muted)
    end
  end

  local function drawMoves(state, x, y, w, h, bodyFont, captionFont, scale, portrait)
    local moves = type(state.playerMoves) == "function" and state:playerMoves() or {}
    local selected = tonumber(state.moveIndex) or 1
    local layout = tostring(opt("battleMoveLayout", "grid")):lower()
    local showInfo = opt("battleMoveInfo", true) ~= false
    local gap = math.max(2, 2 * scale)
    local listX,listY,listW,listH=x,y,w,h
    if showInfo then
      if portrait then
        local infoH=math.max(captionFont:getHeight()*2.4,h*.30)
        infoH=math.min(infoH,h*.40)
        listH=h-infoH-gap
        local infoY=y+listH+gap
        color(COLORS.divider,nil,true)
        G.rectangle("fill",x+3*scale,infoY-gap*.5,w-6*scale,math.max(1,scale*.45))
        drawMoveInfoCompact(state,moves[selected],x,infoY,w,infoH,bodyFont,captionFont,scale)
      else
        local infoW = math.max(w * 0.32, 58 * scale)
        local dividerX = x + (w - infoW - gap) + gap * 0.25
        listW = w - infoW - gap
        local infoX = x + w - infoW
        color(COLORS.divider,nil,true)
        G.rectangle("fill",dividerX,y+3*scale,math.max(1,scale*.45),h-6*scale)
        drawMoveInfo(state,moves[selected],infoX,y,infoW,h,bodyFont,captionFont,scale)
      end
    end

    local pad = math.max(2, 2.5 * scale)
    if layout == "vertical" then
      local rowGap = math.max(1, scale)
      local rowH = (listH - rowGap * 3) / 4
      for i = 1, 4 do
        local move = moves[i]
        local cy = listY + (i - 1) * (rowH + rowGap)
        if i == selected then selectedCell(listX, cy, listW, rowH, scale) end
        local name = move and moveName(state, move) or "—"
        local pp = move and (("%d/%d"):format(tonumber(move.pp) or 0,maxPp(state,move))) or ""
        local ppW=math.max(captionFont:getWidth(pp)+pad*2,listW*.24)
        local nf=fitBattleFont(bodyFont:getHeight(),name,listW-ppW-pad*2,rowH*.70)
        drawText(name,nf,listX+pad,cy+(rowH-nf:getHeight())*.5,listW-ppW-pad*2,"left",i==selected and COLORS.text or COLORS.muted)
        if move then
          local pf=fitBattleFont(captionFont:getHeight(),pp,ppW-pad,rowH*.60)
          drawText(pp,pf,listX+listW-ppW,cy+(rowH-pf:getHeight())*.5,ppW-pad,"right",i==selected and COLORS.text or COLORS.muted)
        end
      end
    else
      local cellGap = math.max(2, 2 * scale)
      local cellW = (listW - cellGap) * 0.5
      local cellH = (listH - cellGap) * 0.5
      for i = 1, 4 do
        local move = moves[i]
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local cx = listX + col * (cellW + cellGap)
        local cy = listY + row * (cellH + cellGap)
        if i == selected then selectedCell(cx, cy, cellW, cellH, scale) end
        local name = move and moveName(state, move) or "—"
        local pp = move and (("PP %d/%d"):format(tonumber(move.pp) or 0,maxPp(state,move))) or ""
        local nameMaxH=cellH-(move and captionFont:getHeight()+pad*2 or pad*2)
        local nf=fitBattleFont(bodyFont:getHeight(),name,cellW-pad*2,math.max(8,nameMaxH))
        drawText(name,nf,cx+pad,cy+math.max(scale,cellH*.12),cellW-pad*2,"left",i==selected and COLORS.text or COLORS.muted)
        if move then
          local pf=fitBattleFont(captionFont:getHeight(),pp,cellW-pad*2,cellH*.34)
          drawText(pp,pf,cx+pad,cy+cellH-pf:getHeight()-math.max(scale,cellH*.09),cellW-pad*2,"right",i==selected and COLORS.text or COLORS.muted)
        end
      end
    end
  end

  local function drawModernBattleUi(game, state, viewport)
    if not supportedSurface(state) then return end

    -- Theme changes are live; no restart/reinstall is needed while testing.
    local themeId = tostring(opt("gen2UiTheme", "default"))
    COLORS = (Style and Style.theme and Style.theme()) or THEMES[themeId] or THEMES.default

    local gx, gy, gw, gh, fit = battleRect(state, viewport)
    fit = tonumber(fit) or math.max(0.5, math.min(gw / 160, gh / 144))
    local winW,winH=G.getDimensions()
    local isMobile=mobileHost()
    local portrait=isMobile and (tonumber(winH) or 0)>(tonumber(winW) or 0)*1.18

    -- Match Gen 1's OG/WIDE wording instead of exposing this as a boolean.
    -- This remains a KIM presentation preference only: it selects the surface
    -- used by the Modern lower battle UI without changing the native Gen 2
    -- battle world, HP HUD, or Gen1Recomp's own saved battle-layout setting.
    -- Older v166 saves used booleans, so true migrates to WIDE and false to OG.
    -- Portrait keeps its dedicated mobile layout regardless of this option.
    local savedBattleUiMode = opt("battleWideUi", "wide")
    local battleUiMode
    if savedBattleUiMode == true then battleUiMode = "wide"
    elseif savedBattleUiMode == false then battleUiMode = "og"
    else battleUiMode = tostring(savedBattleUiMode or "wide"):lower() end
    if battleUiMode ~= "og" then battleUiMode = "wide" end

    if not portrait and okChrome and Chrome
        and type(Chrome.fitScaleFor) == "function"
        and type(Chrome.fitOriginFor) == "function" then
      local tilesW = battleUiMode == "wide" and 38 or 20
      local targetW = battleUiMode == "wide" and 304 or 160
      local canUse=true
      if battleUiMode == "wide" and type(Chrome.playfieldRect)=="function" then
        local okPlay,_,_,pw,ph=pcall(Chrome.playfieldRect,winW,winH)
        if okPlay and tonumber(pw) and tonumber(ph) then
          canUse=(pw>=304 and ph>=144)
        end
      end
      if canUse then
        local okFit, modeFit = pcall(Chrome.fitScaleFor,winW,winH,tilesW,18)
        modeFit=okFit and tonumber(modeFit) or nil
        if modeFit and modeFit>0 then
          local okOrigin,ox,oy=pcall(Chrome.fitOriginFor,
            winW,winH,modeFit,tilesW,18)
          if okOrigin and tonumber(ox) and tonumber(oy) then
            gx,gy,gw,gh,fit=ox,oy,targetW*modeFit,144*modeFit,modeFit
          end
        end
      end
    end
    -- Keep BATTLE UI SIZE at a user-facing/default 100%, but calibrate the
    -- authored Gen 2 lower panel so new 100% matches the former 95% footprint.
    local uiScale = math.max(0.60, math.min(1.50,
      (tonumber(opt("battleUiSize", "100")) or 100) / 100)) * 0.95
    local opacity = math.max(0.25, math.min(1.00,
      (tonumber(opt("battleUiOpacity", "100")) or 100) / 100))
    -- Gen 2/3 share the same practical battle-text range. Clamp saved
    -- legacy values too, so an older 225-400% setting cannot escape the
    -- new 200% ceiling after updating KIM.
    local textPercent = math.max(50, math.min(200,
      tonumber(opt("battleTextScale", "100")) or 100))

    -- 100% is the user-facing neutral/default size. Preserve the former
    -- 150%-default physical footprint at 100%, then scale symmetrically
    -- around that neutral reference.
    local logicalBody = 7.0 * (textPercent / 100)
    local logicalCaption = 5.3 * (textPercent / 100)
    local bodyFont = fontFor(logicalBody * fit)
    local captionFont = fontFor(logicalCaption * fit)

    local baseH = (portrait and 60 or 48) * fit * uiScale
    local phase = tostring(state.phase or "")
    local moveLayout = tostring(opt("battleMoveLayout", "grid")):lower()
    local showMoveInfo = opt("battleMoveInfo", true) ~= false
    local bodyH, captionH = bodyFont:getHeight(), captionFont:getHeight()
    local minH
    if phase == "moves" then
      if moveLayout == "vertical" then
        minH = (bodyH + 3 * fit) * 4 + 11 * fit
      else
        -- A grid cell contains both a move name and a PP caption. Account for
        -- BOTH when calculating panel height; the old formula only counted the
        -- name, which is why 150% text collapsed back down or lost move info.
        local rowNeed = bodyH + captionH + 5 * fit
        minH = rowNeed * 2 + 9 * fit
      end
      if showMoveInfo then
        if portrait then
          local infoNeed = bodyH + captionH * 1.25 + 8 * fit
          minH = minH + infoNeed
        else
          -- Landscape info is beside the move grid, so require enough height
          -- for the selected name plus TYPE/PP/POW/ACC rows.
          local infoNeed = bodyH + captionH * 4.15 + 10 * fit
          minH = math.max(minH, infoNeed)
        end
      end
    elseif phase == "menu" then
      minH = bodyH * 2 + 14 * fit
    else
      minH = bodyH * 2 + 10 * fit
    end
    if portrait and phase=="moves" and showMoveInfo then
      minH=math.max(minH,86*fit*uiScale)
    elseif portrait and phase=="menu" then
      minH=math.max(minH,62*fit*uiScale)
    end
    -- 100% remains the same default footprint, but larger BATTLE UI SIZE and
    -- BATTLE TEXT SIZE settings are now allowed to consume more of the free
    -- lower playfield instead of being hard-capped at the old 100% geometry.
    local panelCap=portrait and math.min(gh*0.78,winH*0.30) or gh*0.80
    local panelH = math.min(panelCap, math.max(baseH, minH))
    local margin = math.max(2 * fit, math.min(gw, gh) * 0.008)
    local x = gx + margin
    local y
    if portrait then
      -- On phones the native 160x144 battle field sits in the upper half of
      -- the display and touch controls occupy the bottom. The old KIM panel
      -- was anchored INSIDE that field, covering the player mon and HP HUD.
      -- Prefer the free band directly below the battle field and keep a touch-
      -- control reserve at the bottom. If a device is unusually short, clamp
      -- downward rather than climbing back over the battlers.
      local desiredY=gy+gh+margin*1.5
      local bottomReserve=math.max(28*fit,winH*0.27)
      local maxY=winH-panelH-bottomReserve
      y=math.max(gy+gh-panelH*0.08,math.min(desiredY,maxY))
    else
      -- Mobile landscape has much more vertical room than the authored
      -- 304x144 battle canvas. Anchoring the Modern UI to the bottom of that
      -- canvas can cover tall player battlers and the native player HP HUD
      -- (Feraligatr is an obvious example). Anchor the lower panel to the
      -- bottom of the actual usable playfield instead. Chrome.playfieldRect
      -- already respects TouchSkin cutouts, so phones keep clear of any
      -- reserved controller area while handhelds with physical controls can
      -- use the otherwise-empty lower band.
      if okChrome and Chrome and type(Chrome.playfieldRect)=="function"
          and (isMobile or battleUiMode=="wide") then
        local okPlay,px,py,pw,ph=pcall(Chrome.playfieldRect,winW,winH)
        if okPlay and tonumber(py) and tonumber(ph) and ph>0 then
          local maxY=py+ph-panelH-margin*1.5
          if isMobile then
            -- Mobile landscape can use the bottom of its touch-safe playfield.
            y=maxY
          else
            -- Desktop WIDE used to pin the panel to the bottom of the authored
            -- 304x144 battle canvas. At 100% that puts its top edge directly
            -- through the player battler / player HP HUD. Keep the same width,
            -- but reserve the lower ~20% of the authored battle surface for the
            -- Modern panel and allow it to extend into the otherwise-unused
            -- lower desktop playfield. This mirrors the spacing mobile WIDE now
            -- gets without forcing the panel all the way to the window edge.
            local clearY=gy+gh*0.86
            -- Keep the full translucent panel visible on shorter desktops;
            -- move it down into free space rather than covering EXP / battler.
            y=math.min(clearY,maxY,winH-panelH-margin*1.5)
          end
        else
          y=gy+gh-panelH-margin
        end
      else
        y = gy + gh - panelH - margin
      end
    end
    local w = gw - margin * 2
    local h = panelH

    G.push("all")
    G.origin()
    roundedPanel(x, y, w, h, opacity, fit)

    local inner = math.max(3 * fit, 5)
    local ix, iy = x + inner, y + inner
    local iw, ih = w - inner * 2, h - inner * 2

    if phase == "menu" then
      drawCommands(state, ix, iy, iw, ih, bodyFont, captionFont, fit, portrait)
    elseif phase == "moves" then
      drawMoves(state, ix, iy, iw, ih, bodyFont, captionFont, fit, portrait)
    else
      drawMessage(state, ix, iy, iw, ih, bodyFont, captionFont, fit)
    end
    G.pop()
  end

  -- Hide ONLY the native lower battle surface. The Gen 2 HP/status HUD stays
  -- fully native, which is intentional for v1.5.3.
  if mod.hooks and type(mod.hooks.wrap) == "function" then
    mod.hooks:wrap("battle.bottom_ui_visible", function(nextFn, state)
      if supportedSurface(state) and hideOriginal() then return false end
      return nextFn(state)
    end, 25000)

    -- Match input navigation to the visual 2x2 move grid. Vertical mode leaves
    -- Gen1Recomp's normal four-row Gen 2 movement untouched.
    mod.hooks:wrap("battle.move_grid_navigation", function(nextFn, state)
      if enabled() and type(state) == "table" and state.isBattle == true
          and tostring(opt("battleMoveLayout", "grid")):lower() == "grid" then
        return true
      end
      return nextFn(state)
    end, 25000)

    mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
      local result = { pcall(nextFn, game, viewport) }
      local ok = table.remove(result, 1)
      if not ok then error(result[1], 0) end
      local state = topGen2Battle(game)
      if state then pcall(drawModernBattleUi, game, state, viewport) end
      return unpack(result)
    end, 25000)
  end

  mod.exports.gen2ModernBattleUi = {
    apiVersion = 1,
    active = function(state) return supportedSurface(state) end,
  }
end
