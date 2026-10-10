-- Kanto in Motion - Gen 3 Modern boot / main-menu presenter
--
-- Presentation-only replacement for the Game3 main menu shown after the title
-- screen. FireRed/LeafGreen, Ruby/Sapphire, and Emerald keep their native boot
-- state, input, fades, save checks, options routing, Mystery Gift/Events logic,
-- and callbacks. KIM suppresses only the normal native main-menu pixels and
-- redraws the same live state at final window resolution.
return function(mod)
  if not (love and love.graphics and mod and mod.hooks and type(mod.hooks.wrap) == "function") then
    return false
  end

  local G = love.graphics
  local Style = mod._kantoInMotionGen3Ui
  local okBoot, Boot = pcall(require, "src.ui.game3.boot")
  local okRseMenu, RseMenu = pcall(require, "src.ui.game3.rse.main_menu_rse")
  local okRsMenu, RsMenu = pcall(require, "src.ui.game3.rs.main_menu")
  local okKit, SceneKit = pcall(require, "src.ui.game3.rse.scene_kit")
  local okVersion, GameVersion = pcall(require, "src.core.GameVersion")
  if not (okBoot and type(Boot) == "table") then return false end

  local FALLBACK = {
    surface={0.075,0.105,0.17,1}, raised={0.12,0.17,0.27,1},
    selected={0.18,0.43,0.72,1}, accent={0.48,0.86,1,1},
    frame={0.48,0.86,1,1}, frameShadow={0.01,0.02,0.04,0.42},
    text={0.96,0.98,1,1}, muted={0.74,0.82,0.92,1}, divider={0.38,0.50,0.68,0.94},
  }

  local fontCache = {}
  local function opt(key, fallback)
    if not (mod.options and type(mod.options.get) == "function") then return fallback end
    local ok, value = pcall(mod.options.get, mod.options, key)
    if not ok or value == nil then return fallback end
    return value
  end

  local function enabled()
    if Style and Style.presenterEnabled then return Style.presenterEnabled("menu") end
    return opt("gen3IntegratedModernUi", true) ~= false and opt("gen3MenuUi", true) ~= false
  end

  local function theme()
    if Style and Style.theme then return Style.theme() end
    local themes = mod._kantoInMotionGen3Themes
    if type(themes) == "table" then
      return themes[tostring(opt("gen3UiTheme", "default"))] or themes.default or FALLBACK
    end
    return FALLBACK
  end

  local function color(c, alpha, foreground)
    if Style and Style.color then return Style.color(c, alpha, foreground ~= false) end
    c = c or {1,1,1,1}
    G.setColor(c[1] or 1, c[2] or 1, c[3] or 1, alpha == nil and (c[4] or 1) or alpha)
  end

  local function fontFor(px)
    if Style and Style.font then return Style.font(px) end
    px = math.max(8, math.floor((tonumber(px) or 12) + 0.5))
    if fontCache[px] then return fontCache[px] end
    local ok, f = pcall(G.newFont, px)
    if ok and f then
      if f.setFilter then pcall(f.setFilter, f, "linear", "linear") end
      fontCache[px] = f
      return f
    end
    return G.getFont()
  end

  local function text(v, font, x, y, w, align, c)
    if Style and Style.text then return Style.text(v, font, x, y, w, align, c) end
    if font then G.setFont(font) end
    color(c)
    v = tostring(v or "")
    if w and w > 0 then G.printf(v, x, y, w, align or "left") else G.print(v, x, y) end
  end

  local function uiScaleFactor()
    if Style and Style.uiScale then
      local ww, wh = G.getDimensions()
      local s = Style.uiScale(ww, wh)
      return tonumber(s) or 1
    end
    local value = tostring(opt("gen3UiScale", "100"))
    if value:lower() == "auto" then return 1 end
    local pct = tonumber(value) or 100
    pct = math.max(75, math.min(400, pct))
    return pct / 100
  end

  local function panel(x, y, w, h, c, alpha)
    if Style and Style.panel then return Style.panel(x, y, w, h, c, alpha or 1) end
    local radius = math.max(7, math.min(w, h) * 0.025)
    color(c.surface, alpha or 1, false)
    G.rectangle("fill", x, y, w, h, radius, radius)
    color(c.frame, nil, true)
    G.setLineWidth(math.max(1.5, math.min(w, h) * 0.006))
    G.rectangle("line", x, y, w, h, radius, radius)
  end

  local function playfield(viewport)
    local x = tonumber(viewport and viewport.gameX) or 0
    local y = tonumber(viewport and viewport.gameY) or 0
    local w = tonumber(viewport and viewport.gameWidth)
    local h = tonumber(viewport and viewport.gameHeight)
    if w and h and w > 0 and h > 0 then return x, y, w, h end
    local ww, wh = G.getDimensions()
    local s = math.min(ww / 240, wh / 160)
    return (ww - 240*s)*0.5, (wh - 160*s)*0.5, 240*s, 160*s
  end

  local function versionLabel()
    if not (okVersion and GameVersion and type(GameVersion.get) == "function") then return "GENERATION III" end
    local ok, v = pcall(GameVersion.get)
    v = ok and tostring(v or ""):lower() or ""
    if v == "firered" or v == "fire_red" or v == "fire red" then return "FIRE RED" end
    if v == "leafgreen" or v == "leaf_green" or v == "leaf green" then return "LEAF GREEN" end
    if v == "emerald" then return "EMERALD" end
    if v == "ruby" then return "RUBY" end
    if v == "sapphire" then return "SAPPHIRE" end
    return "GENERATION III"
  end

  local LABELS = {
    CONTINUE = "CONTINUE",
    NEW_GAME = "NEW GAME",
    OPTION = "OPTION",
    MYSTERY_GIFT = "MYSTERY GIFT",
    MYSTERY_GIFT2 = "MYSTERY GIFT",
    MYSTERY_EVENTS = "MYSTERY EVENTS",
    EXIT = "EXIT",
  }

  local function labelOf(id)
    id = tostring(id or "")
    local key = id:gsub(" ", "_"):upper()
    return LABELS[key] or id:gsub("_", " ")
  end

  local function customMenuUsable(menu)
    if type(menu) ~= "table" then return false end
    local st = tostring(menu.state or "")
    if st == "" or st == "closed" or st == "options" or st == "events" or st == "mystery_gift"
        or st == "save_error" or st == "rtc_error" or st == "battery_error" or st == "invalid_action" then
      return false
    end
    if st:sub(1, 6) == "event_" then return false end
    return type(menu.items) == "table" and #menu.items > 0
  end

  local function activeMenu(game)
    if not enabled() or type(game) ~= "table" or game.phase ~= "boot" then return nil end
    local state = game.boot
    if type(state) ~= "table" or state.phase ~= Boot.PHASE.MENU then return nil end

    if not state.custom then
      if state.saveError then return nil end
      local items = type(Boot.menuItems) == "function" and Boot.menuItems(state) or nil
      if type(items) ~= "table" or #items == 0 then return nil end
      return {
        family = "frlg", state = state, items = items,
        cursor = tonumber(state.menuIndex) or 1,
        info = state.continueInfo,
      }
    end

    local menu = state.custom and state.custom.menu
    if not customMenuUsable(menu) then return nil end
    return {
      family = "rse", state = state, menu = menu, items = menu.items,
      cursor = tonumber(menu.cursor) or 1,
      info = menu.info,
    }
  end

  local function drawStatRow(label, value, font, x, y, w, c)
    text(label, font, x, y, w * 0.48, "left", c.muted)
    text(value, font, x + w * 0.50, y, w * 0.50, "right", c.text)
  end

  local function drawMenu(active, viewport)
    local c = theme()
    local sx, sy, sw, sh = playfield(viewport)
    local ui = uiScaleFactor()
    local s = math.max(0.55, math.min(sw / 640, sh / 360) * ui)

    -- Cover the scaled native boot menu completely. The title/intros are left
    -- untouched; this presenter exists only while the source main menu is live.
    color(c.surface, 1, false)
    G.rectangle("fill", sx, sy, sw, sh)
    color(c.accent, 0.22, false)
    G.rectangle("fill", sx, sy, sw, math.max(3, 4*s))

    local desiredW = sw * 0.82 * ui
    local desiredH = sh * 0.84 * ui
    local w = math.min(sw * 0.96, desiredW)
    local h = math.min(sh * 0.94, desiredH)
    local x = sx + (sw - w) * 0.5
    local y = sy + (sh - h) * 0.5
    panel(x, y, w, h, c, 1)

    local pad = math.max(12, w * 0.027)
    local titleF = fontFor(math.max(15, 18*s))
    local subF = fontFor(math.max(9, 10*s))
    local itemF = fontFor(math.max(12, 14*s))
    local infoF = fontFor(math.max(10, 11*s))
    local valueF = fontFor(math.max(11, 12*s))

    text("MAIN MENU", titleF, x + pad, y + pad * 0.72, w * 0.55, "left", c.accent)
    text(versionLabel(), subF, x + pad, y + pad * 0.72 + titleF:getHeight() + 2*s,
      w * 0.55, "left", c.muted)

    local footerH = math.max(28*s, h * 0.095)
    local contentTop = y + pad * 1.7 + titleF:getHeight() + subF:getHeight()
    local contentBottom = y + h - footerH - pad * 0.65
    local contentH = math.max(40, contentBottom - contentTop)
    local hasInfo = type(active.info) == "table"
    local gap = math.max(10, pad * 0.75)
    local listW = hasInfo and (w - pad*2 - gap) * 0.46 or math.min(w - pad*2, w * 0.66)
    local infoW = hasInfo and (w - pad*2 - gap - listW) or 0
    local listX = hasInfo and (x + pad) or (x + (w - listW) * 0.5)
    local infoX = listX + listW + gap

    local n = math.max(1, #active.items)
    local rowGap = math.max(4*s, contentH * 0.018)
    local rowH = (contentH - rowGap * (n - 1)) / n
    rowH = math.max(28*s, rowH)
    local totalRowsH = rowH * n + rowGap * (n - 1)
    if totalRowsH > contentH then
      rowH = math.max(20*s, (contentH - rowGap * (n - 1)) / n)
      totalRowsH = rowH * n + rowGap * (n - 1)
    end
    local listY = contentTop + math.max(0, (contentH - totalRowsH) * 0.5)

    for i, id in ipairs(active.items) do
      local selected = i == math.max(1, math.min(n, active.cursor))
      local ry = listY + (i - 1) * (rowH + rowGap)
      color(selected and c.selected or c.raised, selected and 0.98 or 0.78, false)
      local radius = math.max(4, 6*s)
      G.rectangle("fill", listX, ry, listW, rowH, radius, radius)
      if selected then
        color(c.accent, nil, true)
        G.setLineWidth(math.max(1.5, 1.5*s))
        G.rectangle("line", listX + 0.5, ry + 0.5, listW - 1, rowH - 1, radius, radius)
        color(c.accent, nil, true)
        G.rectangle("fill", listX, ry, math.max(4, 5*s), rowH, radius, radius)
      end
      text(labelOf(id), itemF, listX + pad * 0.75,
        ry + (rowH - itemF:getHeight()) * 0.47,
        listW - pad * 1.15, "left", selected and c.text or c.muted)
    end

    if hasInfo then
      local infoY = contentTop
      panel(infoX, infoY, infoW, contentH, c, 0.94)
      local ip = math.max(10, pad * 0.78)
      text("SAVE DATA", itemF, infoX + ip, infoY + ip * 0.82, infoW - ip*2, "left", c.accent)
      color(c.divider, 0.65, false)
      G.rectangle("fill", infoX + ip, infoY + ip * 0.82 + itemF:getHeight() + 5*s,
        infoW - ip*2, math.max(1, s))

      local ii = active.info or {}
      local lineH = math.max(valueF:getHeight() * 1.55, 26*s)
      local yy = infoY + ip * 1.65 + itemF:getHeight() + 7*s
      local innerW = infoW - ip*2
      drawStatRow("PLAYER", tostring(ii.name or "---"), valueF, infoX + ip, yy, innerW, c); yy = yy + lineH
      drawStatRow("TIME", string.format("%d:%02d", tonumber(ii.hours) or 0, tonumber(ii.minutes) or 0), valueF,
        infoX + ip, yy, innerW, c); yy = yy + lineH
      if ii.hasDex ~= false then
        drawStatRow("POKéDEX", tostring(tonumber(ii.dexCount) or 0), valueF, infoX + ip, yy, innerW, c); yy = yy + lineH
      end
      drawStatRow("BADGES", tostring(tonumber(ii.badges) or 0), valueF, infoX + ip, yy, innerW, c)

      if tostring(active.items[active.cursor] or ""):upper():gsub(" ", "_") == "CONTINUE" then
        color(c.accent, 0.22, false)
        G.rectangle("fill", infoX + 2*s, infoY + 2*s, math.max(2, 4*s), contentH - 4*s,
          math.max(2, 2*s), math.max(2, 2*s))
      end
    end

    local footerY = y + h - footerH
    color(c.divider, 0.72, false)
    G.rectangle("fill", x + pad, footerY, w - pad*2, math.max(1, s))
    text("D-PAD  move     A  select     B  back", subF,
      x + pad, footerY + (footerH - subF:getHeight()) * 0.51,
      w - pad*2, "center", c.muted)

    -- Preserve the source menu's visual fade timing while keeping the Modern
    -- menu presentation. FRLG exposes fadeT directly; RSE/RS use PalFade.
    if active.family == "frlg" then
      local st = active.state
      local t = tonumber(st.fadeT) or 0
      if t > 0 then
        if st.fadeColor == "white" then G.setColor(1,1,1,math.min(1,t/16))
        else G.setColor(0,0,0,math.min(1,t/16)) end
        G.rectangle("fill", sx, sy, sw, sh)
      end
    elseif active.menu and okKit and SceneKit and type(SceneKit.fadeY) == "function" then
      local ok, amount, fc = pcall(SceneKit.fadeY, active.menu.pal, 0)
      if ok and tonumber(amount) and amount > 0 and type(fc) == "table" then
        G.setColor((fc[1] or 0)/31, (fc[2] or 0)/31, (fc[3] or 0)/31, math.min(1, amount/16))
        G.rectangle("fill", sx, sy, sw, sh)
      end
    end

    G.setColor(1,1,1,1)
    return true
  end

  -- Suppress only the normal FRLG main-menu renderer. Error pages, Mystery
  -- Gift, title, intro and the entire new-game scene stay source-owned.
  if not Boot.__kimGen3ModernMainMenuV121 and type(Boot.draw) == "function" then
    local upstreamBootDraw = Boot.draw
    Boot.draw = function(state, ...)
      if enabled() and type(state) == "table" and not state.custom
          and state.phase == Boot.PHASE.MENU and not state.saveError then
        G.clear(0,0,0,1)
        return
      end
      return upstreamBootDraw(state, ...)
    end
    Boot.__kimGen3ModernMainMenuV121 = true
  end

  local function wrapCustomMenu(menu, flag)
    if type(menu) ~= "table" or menu[flag] or type(menu.draw) ~= "function" then return end
    local upstream = menu.draw
    menu.draw = function(self, ...)
      if enabled() and customMenuUsable(self) then
        G.clear(0,0,0,1)
        return
      end
      return upstream(self, ...)
    end
    menu[flag] = true
  end

  if okRseMenu then wrapCustomMenu(RseMenu, "__kimGen3ModernMainMenuV121") end
  if okRsMenu then wrapCustomMenu(RsMenu, "__kimGen3ModernMainMenuV121") end

  -- Round-robin navigation for every Gen 3 title/main menu variant.
  -- Presentation is still KIM-owned, while the source menu keeps selection,
  -- sounds, fades, callbacks, and actions. We only fill the two edge cases
  -- the original bounded input handlers intentionally leave unchanged.
  local function pressed(input, key)
    return input and input.wasPressed and input:wasPressed(key)
  end

  if not Boot.__kimGen3ModernMainMenuRoundRobinV124 and type(Boot.update) == "function" then
    local upstreamBootUpdate = Boot.update
    Boot.update = function(state, input, dt, ...)
      local wrapUp, wrapDown, count = false, false, 0
      if enabled() and type(state) == "table" and not state.custom
          and state.phase == Boot.PHASE.MENU and not state.saveError
          and not state.fadeThen then
        local items = type(Boot.menuItems) == "function" and Boot.menuItems(state) or nil
        count = type(items) == "table" and #items or 0
        local cur = tonumber(state.menuIndex) or 1
        wrapUp = count > 1 and cur <= 1 and pressed(input, "up")
        wrapDown = count > 1 and cur >= count and pressed(input, "down")
      end

      local result = upstreamBootUpdate(state, input, dt, ...)
      if enabled() and type(state) == "table" and not state.custom
          and state.phase == Boot.PHASE.MENU and not state.saveError and count > 1 then
        if wrapUp then
          state.menuIndex = count
          -- FRLG's four-row Mystery Gift menu scrolls the last item into view.
          state.menuScroll = count >= 4 and 4 or 0
        elseif wrapDown then
          state.menuIndex = 1
          state.menuScroll = 0
        end
      end
      return result
    end
    Boot.__kimGen3ModernMainMenuRoundRobinV124 = true
  end

  local function wrapCustomRoundRobin(menu, flag)
    if type(menu) ~= "table" or menu[flag] or type(menu.frame) ~= "function" then return end
    local upstreamFrame = menu.frame
    menu.frame = function(self, inp, ...)
      local wrapUp, wrapDown, count = false, false, 0
      if enabled() and type(self) == "table" and tostring(self.state or "") == "input"
          and type(self.items) == "table" then
        count = #self.items
        local cur = tonumber(self.cursor) or 1
        local new = inp and inp.new or {}
        wrapUp = count > 1 and cur <= 1 and new.up == true
        wrapDown = count > 1 and cur >= count and new.down == true
      end

      local result = upstreamFrame(self, inp, ...)
      if enabled() and type(self) == "table" and count > 1 then
        if wrapUp then
          self.cursor = count
          if type(self._fixScroll) == "function" then self:_fixScroll() end
          -- RS normally enters its one-frame highlight state after a move.
          if tostring(self.state or "") == "input" and menu == RsMenu then self.state = "highlight" end
        elseif wrapDown then
          self.cursor = 1
          if type(self._fixScroll) == "function" then self:_fixScroll() end
          if tostring(self.state or "") == "input" and menu == RsMenu then self.state = "highlight" end
        end
      end
      return result
    end
    menu[flag] = true
  end

  if okRseMenu then wrapCustomRoundRobin(RseMenu, "__kimGen3ModernMainMenuRoundRobinV124") end
  if okRsMenu then wrapCustomRoundRobin(RsMenu, "__kimGen3ModernMainMenuRoundRobinV124") end

  mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
    nextFn(game, viewport)
    local active = activeMenu(game)
    if not active then return end
    G.push("all")
    local ok, err = pcall(function()
      G.origin(); G.setShader(); G.setBlendMode("alpha")
      drawMenu(active, viewport)
    end)
    G.setScissor(); G.setShader(); G.setBlendMode("alpha"); G.setColor(1,1,1,1)
    G.pop()
    if not ok then
      mod._kantoInMotionGen3BootMenuLastDrawError = tostring(err)
    else
      mod._kantoInMotionGen3BootMenuLastDrawError = nil
    end
  end, 11250)

  mod.exports = mod.exports or {}
  mod.exports.gen3ModernBootMainMenu = true
  return true
end
