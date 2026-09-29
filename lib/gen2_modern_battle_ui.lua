-- Kanto in Motion v1.5.3 - Gen 2 Modern Battle UI adapter v28
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

  local function drawMessage(state, x, y, w, h, bodyFont, captionFont, scale)
    local pad = math.max(4, 4 * scale)
    local lines = stateMessageLines(state)
    local lineH = bodyFont:getHeight()
    local maxLines = math.max(1, math.floor((h - pad * 2) / math.max(1, lineH)))
    for i = 1, math.min(#lines, maxLines) do
      drawText(lines[i], bodyFont, x + pad, y + pad + (i - 1) * lineH,
        w - pad * 2, "left", COLORS.text)
    end
    if type(state.messageArrowVisible) == "function" then
      local ok, visible = pcall(state.messageArrowVisible, state)
      if ok and visible then
        drawText("▼", captionFont, x + w - pad - captionFont:getWidth("▼"),
          y + h - pad - captionFont:getHeight(), nil, nil, COLORS.accent)
      end
    end
  end

  local function drawCommands(state, x, y, w, h, bodyFont, captionFont, scale)
    local pad = math.max(3, 3.5 * scale)
    local labels = commandLabels(state)
    local messageW = math.max(w * 0.50, 45 * scale)
    local gap = math.max(2, 2 * scale)
    local menuX = x + messageW + gap
    local menuW = w - messageW - gap
    drawMessage(state, x, y, messageW, h, bodyFont, captionFont, scale)

    color(COLORS.divider,nil,true)
    G.rectangle("fill", menuX - gap * 0.5, y + pad, math.max(1, scale * 0.45),
      h - pad * 2)

    local cellGap = math.max(2, 2 * scale)
    local cellW = (menuW - cellGap) * 0.5
    local cellH = (h - cellGap) * 0.5
    local selected = tonumber(state.menuIndex) or 1
    for i = 1, 4 do
      local col = (i - 1) % 2
      local row = math.floor((i - 1) / 2)
      local cx = menuX + col * (cellW + cellGap)
      local cy = y + row * (cellH + cellGap)
      if i == selected then selectedCell(cx, cy, cellW, cellH, scale) end
      local label = truncate(labels[i], bodyFont, cellW - pad * 2)
      drawText(label, bodyFont, cx + pad,
        cy + (cellH - bodyFont:getHeight()) * 0.5,
        cellW - pad * 2, "center",
        i == selected and COLORS.text or COLORS.muted)
    end
  end

  local function drawMoveInfo(state, move, x, y, w, h, bodyFont, captionFont, scale)
    local pad = math.max(3, 3.5 * scale)
    local def = moveDefinition(state, move)
    drawText("MOVE INFO", captionFont, x + pad, y + pad,
      w - pad * 2, "left", COLORS.accent)
    local yy = y + pad + captionFont:getHeight() + scale
    drawText(truncate(moveName(state, move), bodyFont, w - pad * 2),
      bodyFont, x + pad, yy, w - pad * 2, "left", COLORS.text)
    yy = yy + bodyFont:getHeight() + scale
    local rows = {
      "TYPE  " .. typeName(state, move),
      ("PP    %d/%d"):format(tonumber(move and move.pp) or 0, maxPp(state, move)),
      "POW   " .. powerText(def),
      "ACC   " .. accuracyText(def),
    }
    for _, row in ipairs(rows) do
      if yy + captionFont:getHeight() > y + h - pad then break end
      drawText(row, captionFont, x + pad, yy, w - pad * 2,
        "left", COLORS.muted)
      yy = yy + captionFont:getHeight() + scale * 0.25
    end
  end

  local function drawMoves(state, x, y, w, h, bodyFont, captionFont, scale)
    local moves = type(state.playerMoves) == "function" and state:playerMoves() or {}
    local selected = tonumber(state.moveIndex) or 1
    local layout = tostring(opt("battleMoveLayout", "grid")):lower()
    local showInfo = opt("battleMoveInfo", false) == true
    local gap = math.max(2, 2 * scale)
    local listX, listW = x, w
    if showInfo then
      local infoW = math.max(w * 0.33, 47 * scale)
      local dividerX = x + (w - infoW - gap) + gap * 0.25
      listX = x
      listW = w - infoW - gap
      local infoX = x + w - infoW
      color(COLORS.divider,nil,true)
      G.rectangle("fill", dividerX, y + 3 * scale,
        math.max(1, scale * 0.45), h - 6 * scale)
      drawMoveInfo(state, moves[selected], infoX, y, infoW, h,
        bodyFont, captionFont, scale)
    end

    local pad = math.max(2, 2.5 * scale)
    if layout == "vertical" then
      local rowGap = math.max(1, scale)
      local rowH = (h - rowGap * 3) / 4
      for i = 1, 4 do
        local move = moves[i]
        local cy = y + (i - 1) * (rowH + rowGap)
        if i == selected then selectedCell(listX, cy, listW, rowH, scale) end
        local name = move and moveName(state, move) or "—"
        drawText(truncate(name, bodyFont, listW - pad * 2),
          bodyFont, listX + pad, cy + (rowH - bodyFont:getHeight()) * 0.5,
          listW - pad * 2, "left",
          i == selected and COLORS.text or COLORS.muted)
        if move then
          local pp = ("%d/%d"):format(tonumber(move.pp) or 0, maxPp(state, move))
          drawText(pp, captionFont, listX + pad, cy + (rowH - captionFont:getHeight()) * 0.5,
            listW - pad * 2, "right",
            i == selected and COLORS.text or COLORS.muted)
        end
      end
    else
      local cellGap = math.max(2, 2 * scale)
      local cellW = (listW - cellGap) * 0.5
      local cellH = (h - cellGap) * 0.5
      for i = 1, 4 do
        local move = moves[i]
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local cx = listX + col * (cellW + cellGap)
        local cy = y + row * (cellH + cellGap)
        if i == selected then selectedCell(cx, cy, cellW, cellH, scale) end
        local name = move and moveName(state, move) or "—"
        drawText(truncate(name, bodyFont, cellW - pad * 2),
          bodyFont, cx + pad, cy + math.max(scale, cellH * 0.14),
          cellW - pad * 2, "left",
          i == selected and COLORS.text or COLORS.muted)
        if move then
          local pp = ("PP %d/%d"):format(tonumber(move.pp) or 0, maxPp(state, move))
          drawText(pp, captionFont, cx + pad,
            cy + cellH - captionFont:getHeight() - math.max(scale, cellH * 0.10),
            cellW - pad * 2, "right",
            i == selected and COLORS.text or COLORS.muted)
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
    local uiScale = math.max(0.60, math.min(1.00,
      (tonumber(opt("battleUiSize", "100")) or 100) / 100))
    local opacity = math.max(0.25, math.min(1.00,
      (tonumber(opt("battleUiOpacity", "100")) or 100) / 100))
    local textPercent = math.max(100, math.min(400,
      tonumber(opt("battleTextScale", "150")) or 150))

    -- 150% is KIM's authored/default battle text size. Scale around that
    -- reference instead of multiplying the native 8px font by 1.5 twice.
    local logicalBody = 7.0 * (textPercent / 150)
    local logicalCaption = 5.3 * (textPercent / 150)
    local bodyFont = fontFor(logicalBody * fit)
    local captionFont = fontFor(logicalCaption * fit)

    local baseH = 48 * fit * uiScale
    local phase = tostring(state.phase or "")
    local minRows = (phase == "moves"
        and tostring(opt("battleMoveLayout", "grid")):lower() == "vertical")
      and 4 or 2
    local minH = (bodyFont:getHeight() + 3 * fit) * minRows + 8 * fit
    if phase ~= "moves" and phase ~= "menu" then
      minH = bodyFont:getHeight() * 2 + 10 * fit
    end
    local panelH = math.min(gh * 0.62, math.max(baseH, minH))
    local margin = math.max(2 * fit, math.min(gw, gh) * 0.008)
    local x = gx + margin
    local y = gy + gh - panelH - margin
    local w = gw - margin * 2
    local h = panelH

    G.push("all")
    G.origin()
    roundedPanel(x, y, w, h, opacity, fit)

    local inner = math.max(3 * fit, 5)
    local ix, iy = x + inner, y + inner
    local iw, ih = w - inner * 2, h - inner * 2

    if phase == "menu" then
      drawCommands(state, ix, iy, iw, ih, bodyFont, captionFont, fit)
    elseif phase == "moves" then
      drawMoves(state, ix, iy, iw, ih, bodyFont, captionFont, fit)
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
