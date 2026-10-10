-- Kanto in Motion - Gen 3 Modern Battle UI foundation
--
-- Presentation-only adapter for FireRed / LeafGreen / Emerald.  The Game3
-- battle engine remains authoritative for input, selection, messages, state,
-- move targeting and child menus.  KIM covers only the native 240x48 lower
-- battle surface after the finished frame is presented and redraws it at final
-- window resolution.
return function(mod)
  if not (love and love.graphics and mod and mod.hooks and type(mod.hooks.wrap) == "function") then
    return false
  end

  local G = love.graphics
  local okBattle, Battle = pcall(require, "src.core.game3.battle.init")
  local okUi, Ui = pcall(require, "src.core.game3.battle.ui")
  local okMoves, Moves = pcall(require, "src.core.game3.battle.moves")
  local okTypes, Types = pcall(require, "src.core.game3.battle.types")
  local okMessage, Message = pcall(require, "src.ui.game3.message")
  local okChoice, Choice = pcall(require, "src.ui.game3.choice")
  local okHealthbox, Healthbox = pcall(require, "src.core.game3.battle.healthbox")
  local okFrlgFont, FrlgFont = pcall(require, "src.ui.game3.frlg_font")
  local okBattleChrome, BattleChrome = pcall(require, "src.ui.game3.battle_chrome")
  local okWindow, Window = pcall(require, "src.ui.game3.window")
  if not (okBattle and type(Battle) == "table" and okUi and type(Ui) == "table") then
    return false
  end

  local THEMES = {
    default = {
      surface={0.075,0.105,0.17,0.98}, raised={0.12,0.17,0.27,1},
      selected={0.18,0.43,0.72,1}, accent={0.48,0.86,1,1},
      frame={0.48,0.86,1,1}, frameShadow={0.01,0.02,0.04,0.42},
      text={0.96,0.98,1,1}, muted={0.74,0.82,0.92,1}, divider={0.38,0.50,0.68,0.94},
    },
    ["gen1_modern_ui:classic_mono"] = {
      surface={0.96,0.95,0.89,1}, raised={0.86,0.85,0.78,1},
      selected={0.72,0.77,0.72,1}, accent={0.06,0.09,0.12,1},
      frame={0.06,0.09,0.12,1}, frameShadow={0.16,0.17,0.16,0.55},
      text={0.035,0.045,0.055,1}, muted={0.25,0.30,0.36,1}, divider={0.34,0.40,0.47,0.94},
    },
    ["gen1_modern_ui:crimson"] = {
      surface={0.095,0.022,0.036,0.99}, raised={0.155,0.035,0.058,1},
      selected={0.300,0.055,0.100,1}, accent={0.863,0.078,0.235,1},
      frame={0.863,0.078,0.235,1}, frameShadow={0.190,0.018,0.045,0.98},
      text={1,0.955,0.965,1}, muted={0.850,0.660,0.700,1}, divider={0.500,0.105,0.190,0.96},
    },
    ["gen1_modern_ui:crimson_glass"] = {
      surface={0.095,0.022,0.036,0.68}, raised={0.155,0.035,0.058,0.76},
      selected={0.300,0.055,0.100,0.84}, accent={0.863,0.078,0.235,1},
      frame={0.863,0.078,0.235,1}, frameShadow={0.190,0.018,0.045,0.86},
      text={1,0.955,0.965,1}, muted={0.850,0.660,0.700,1}, divider={0.500,0.105,0.190,0.88},
    },
    ["gen1_modern_ui:modern_glass"] = {
      surface={0.055,0.085,0.15,0.70}, raised={0.105,0.155,0.25,0.78},
      selected={0.20,0.48,0.78,0.86}, accent={0.48,0.86,1,1},
      frame={0.48,0.86,1,1}, frameShadow={0.01,0.02,0.04,0.36},
      text={0.96,0.98,1,1}, muted={0.76,0.84,0.94,1}, divider={0.38,0.52,0.72,0.92},
    },
    ["gen1_modern_ui:pocket_green"] = {
      surface={0.84,0.88,0.70,1}, raised={0.73,0.80,0.58,1},
      selected={0.62,0.73,0.46,1}, accent={0.07,0.20,0.14,1},
      frame={0.07,0.20,0.14,1}, frameShadow={0.07,0.12,0.08,0.55},
      text={0.045,0.095,0.065,1}, muted={0.18,0.27,0.19,1}, divider={0.27,0.38,0.24,0.96},
    },
    ["gen1_modern_ui:midnight"] = {
      surface={0.035,0.045,0.075,1}, raised={0.075,0.090,0.150,1},
      selected={0.24,0.18,0.48,1}, accent={0.70,0.58,1,1},
      frame={0.70,0.58,1,1}, frameShadow={0.025,0.02,0.06,0.90},
      text={0.96,0.95,1,1}, muted={0.74,0.76,0.89,1}, divider={0.34,0.38,0.54,0.96},
    },
    ["gen1_modern_ui:midnight_glass"] = {
      surface={0.035,0.045,0.075,0.68}, raised={0.075,0.090,0.150,0.76},
      selected={0.24,0.18,0.48,0.84}, accent={0.70,0.58,1,1},
      frame={0.70,0.58,1,1}, frameShadow={0.025,0.02,0.06,0.62},
      text={0.96,0.95,1,1}, muted={0.74,0.76,0.89,1}, divider={0.34,0.38,0.54,0.94},
    },
    ["gen1_modern_ui:frost"] = {
      surface={0.96,0.98,1,1}, raised={0.88,0.93,0.98,1},
      selected={0.38,0.63,0.88,1}, accent={0.04,0.38,0.66,1},
      frame={0.04,0.38,0.66,1}, frameShadow={0.17,0.25,0.34,0.48},
      text={0.055,0.095,0.160,1}, muted={0.24,0.32,0.43,1}, divider={0.36,0.49,0.63,0.96},
    },
    ["gen1_modern_ui:light"] = {
      surface={0.98,0.98,0.96,1}, raised={0.89,0.90,0.88,1},
      selected={0.40,0.63,0.88,1}, accent={0.07,0.24,0.46,1},
      frame={0.07,0.24,0.46,1}, frameShadow={0.20,0.22,0.25,0.42},
      text={0.035,0.050,0.085,1}, muted={0.24,0.29,0.36,1}, divider={0.36,0.43,0.52,1},
    },
    ["gen1_modern_ui:dark"] = {
      surface={0.055,0.065,0.085,1}, raised={0.105,0.125,0.155,1},
      selected={0.25,0.52,0.78,1}, accent={0.52,0.85,1,1},
      frame={0.52,0.85,1,1}, frameShadow={0.01,0.015,0.025,0.90},
      text={0.96,0.98,1,1}, muted={0.73,0.78,0.88,1}, divider={0.34,0.44,0.56,1},
    },
  }
  mod._kantoInMotionGen3Themes = THEMES

  local fontCache = {}
  local function opt(key, fallback)
    if not (mod.options and type(mod.options.get) == "function") then return fallback end
    local ok, value = pcall(mod.options.get, mod.options, key)
    if not ok or value == nil then return fallback end
    return value
  end

  local function enabled()
    local Style=mod._kantoInMotionGen3Ui
    if Style and Style.presenterEnabled then return Style.presenterEnabled("battle") end
    return opt("gen3IntegratedModernUi", true) ~= false
      and opt("battleUiWip", true) ~= false
  end

  local function theme()
    return THEMES[tostring(opt("gen3UiTheme", "default"))] or THEMES.default
  end

  -- The caught-Pokemon nickname prompt is a battle-owned Message +
  -- Choice.yesNo pair.  Earlier Modern Battle UI deliberately yielded whenever
  -- *any* Choice was active, which caused this one prompt to snap back to the
  -- vanilla GBA textbox/Yes-No window.  Scope ownership narrowly to the
  -- post-catch nickname question; Game3 still owns the Choice cursor/callback.
  local function modernCatchNicknameChoice()
    return enabled() and okChoice and Choice and Choice.active==true
      and Choice.kind=="yesno" and Choice.style=="battle"
      and Battle._phase=="catch_nickname_prompt"
  end

  -- KIM has to remove Game3's native lower battle surface at the source for
  -- BATTLE UI OPACITY to have anything behind it to reveal.  Painting an
  -- opaque KIM-colored rectangle over the native panel (the old behaviour)
  -- hid the native chrome, but it also made every opacity value look like
  -- 100%.  Keep source ownership of battle state/input while suppressing only
  -- the native y=112..159 presentation whenever KIM owns that surface.
  local function ownsLowerPanel()
    if not enabled() then return false end
    if type(Battle.isActive) == "function" then
      local ok, active = pcall(Battle.isActive)
      if not ok or not active then return false end
    end
    if Ui._caughtDexScene then return false end
    if okChoice and Choice and Choice.active and not modernCatchNicknameChoice() then return false end
    local st = (type(Battle.getState) == "function" and Battle.getState()) or Battle._st
    if type(st) ~= "table" then return false end
    -- These controllers still use their specialized native lower UI.
    if st.safari or st.oldManTutorial or st.pokedude then return false end
    return true
  end

  -- Native panel chrome itself.  With this gone, KIM can alpha-blend its
  -- Modern card over the live battle/background instead of over an opaque
  -- copy of the old Game3 panel.
  if okBattleChrome and type(BattleChrome) == "table" then
    if type(BattleChrome.drawPanel) == "function" and not BattleChrome._kimModernPanelOpacityBridge then
      BattleChrome._kimModernPanelOpacityBridge = BattleChrome.drawPanel
      local nativeDrawPanel = BattleChrome.drawPanel
      BattleChrome.drawPanel = function(...)
        if ownsLowerPanel() then return true end
        return nativeDrawPanel(...)
      end
    end
    if type(BattleChrome.drawMenuFrames) == "function" and not BattleChrome._kimModernMenuFramesOpacityBridge then
      BattleChrome._kimModernMenuFramesOpacityBridge = BattleChrome.drawMenuFrames
      local nativeDrawMenuFrames = BattleChrome.drawMenuFrames
      BattleChrome.drawMenuFrames = function(...)
        if ownsLowerPanel() then return true end
        return nativeDrawMenuFrames(...)
      end
    end
  end

  -- Keep KIM's opacity ownership away from Game3's global font/cursor
  -- functions.  Those functions are shared by the final-resolution HD battle
  -- replay and other Gen 3 presenters; wrapping them globally can interfere
  -- with the HD battler pipeline even though the lower panel itself is the
  -- only surface KIM needs to replace.  Native lower glyphs are allowed to
  -- exist in the source canvas and are covered by KIM's own command/message
  -- cards at final resolution.

  -- Battle messages normally draw their own native text/frame after Ui.draw.
  -- KIM reads the same Message state and presents it in the Modern panel, so
  -- suppress only battle/voiceover presentation while KIM owns the surface.
  if okMessage and type(Message) == "table" and type(Message.draw) == "function"
      and not Message._kimModernBattleOpacityBridge then
    Message._kimModernBattleOpacityBridge = Message.draw
    local nativeMessageDraw = Message.draw
    Message.draw = function(...)
      if ownsLowerPanel() then
        local kind = type(Message.frameKind) == "function" and Message.frameKind() or Message._frame
        if kind == "battle" or kind == "voiceover" then return true end
      end
      return nativeMessageDraw(...)
    end
  end


  -- Suppress only the native caught-Pokemon Yes/No pixels while KIM mirrors
  -- that live Choice state at final resolution.  Input and callbacks remain
  -- entirely in src.ui.game3.choice.
  if okChoice and type(Choice)=="table" and type(Choice.draw)=="function"
      and not Choice._kimModernCaughtNicknameChoice then
    Choice._kimModernCaughtNicknameChoice=Choice.draw
    local nativeChoiceDraw=Choice.draw
    Choice.draw=function(...)
      if modernCatchNicknameChoice() then return true end
      return nativeChoiceDraw(...)
    end
  end


  -- -----------------------------------------------------------------------
  -- Modern-font healthbox bridge
  -- -----------------------------------------------------------------------
  -- Game3 draws the battle healthboxes on the native 240x160 canvas with its
  -- FRLG/E pixel font.  KIM's lower Modern UI is rendered later in window
  -- space with Love's scalable font, so simply changing the engine font would
  -- still rasterize it at GBA resolution and look pixelated when enlarged.
  --
  -- While Modern UI owns presentation, capture the healthbox text calls and
  -- suppress only their native glyph draw.  The healthbox chrome, HP/EXP bars,
  -- status icons, caught marker, animation offsets and all engine state remain
  -- native.  render.hud then replays the captured text at final resolution
  -- using the exact same scalable font family as the Gen 3 Modern UI.
  local healthboxText = {}

  local function copyColor(c)
    if type(c) ~= "table" then return nil end
    return { tonumber(c[1]) or 1, tonumber(c[2]) or 1, tonumber(c[3]) or 1, tonumber(c[4]) or 1 }
  end

  local healthboxGroupSeq = 0

  local function recordHealthbox(kind, text, x, y, colors, group)
    healthboxText[#healthboxText + 1] = {
      kind = kind or "text",
      text = tostring(text or ""),
      x = tonumber(x) or 0,
      y = tonumber(y) or 0,
      color = copyColor(colors and colors.fg),
      group = group,
    }
  end

  if okHealthbox and type(Healthbox) == "table"
      and okFrlgFont and type(FrlgFont) == "table"
      and type(Healthbox.draw) == "function" and type(FrlgFont.draw) == "function"
      and not Healthbox._kimModernFontBridge then
    Healthbox._kimModernFontBridge = true
    local originalHealthboxDraw = Healthbox.draw
    local originalUiDraw = Ui.draw

    -- A battle frame starts here, before any singles/doubles healthbox is
    -- emitted. Reset the capture list exactly once for the frame. While the
    -- native Game3 battle renderer is executing, suppress only lower-plane
    -- command/move glyphs and cursor pips. The overrides are restored before
    -- render.hud reaches KIM's final-resolution HD battler pass, so the opacity
    -- bridge cannot disable the HD sprite renderer (the v102 regression).
    if type(originalUiDraw) == "function" then
      Ui.draw = function(...)
        healthboxText = {}
        if not ownsLowerPanel() then return originalUiDraw(...) end

        local savedFontDraw = okFrlgFont and FrlgFont and FrlgFont.draw or nil
        local savedCursorPx = okWindow and Window and Window.cursorPx or nil

        if type(savedFontDraw) == "function" then
          FrlgFont.draw = function(text, x, y, opts)
            if (tonumber(y) or 0) >= 112 then
              return 0, tonumber(x) or 0, tonumber(y) or 0
            end
            return savedFontDraw(text, x, y, opts)
          end
        end
        if type(savedCursorPx) == "function" then
          Window.cursorPx = function(x, y, ...)
            if (tonumber(y) or 0) >= 112 then return true end
            return savedCursorPx(x, y, ...)
          end
        end

        local packed = { pcall(originalUiDraw, ...) }
        if type(savedFontDraw) == "function" then FrlgFont.draw = savedFontDraw end
        if type(savedCursorPx) == "function" then Window.cursorPx = savedCursorPx end
        if not packed[1] then error(packed[2], 0) end
        return unpack(packed, 2)
      end
    end

    Healthbox.draw = function(side, battler, opts)
      if not enabled() then return originalHealthboxDraw(side, battler, opts) end

      -- 1025Dex keeps expanded-species genderRate in its public dex API rather
      -- than Game3's compact species metadata.  If Game3 cannot resolve a
      -- gender, temporarily expose KIM's compatibility result so the native
      -- healthbox emits its normal gender glyph for our capture below.
      local mon = battler and battler.mon
      local oldMonGender = type(mon) == "table" and mon.gender or nil
      local resolver = mod._kantoInMotion1025DexGender
      local injectedGender
      if type(mon) == "table" and type(resolver) == "function"
          and oldMonGender ~= "M" and oldMonGender ~= "F" then
        local ok, value = pcall(resolver, mon)
        if ok and (value == "M" or value == "F") then
          injectedGender = value
          mon.gender = value
        end
      end

      local oldDraw = FrlgFont.draw
      local oldGlyph = FrlgFont.drawGlyph
      local oldBold = okBattleChrome and BattleChrome and BattleChrome.drawHpBoldChar or nil

      healthboxGroupSeq = healthboxGroupSeq + 1
      local group = healthboxGroupSeq
      local sawName = false
      local afterLevelPrefix = false
      local lastRole = nil

      FrlgFont.draw = function(text, x, y, fopts)
        local shown = tostring(text or "")
        local compact = shown:gsub("%s+", "")
        local role = "text"
        if afterLevelPrefix then
          role = "levelDigits"
          afterLevelPrefix = false
        elseif compact:match("^%d+/$") then
          role = "hpCur"
        elseif lastRole == "hpCur" and compact:match("^%d+$") then
          role = "hpMax"
        elseif not sawName and compact ~= "" and not compact:match("^%d+$") then
          role = "name"
          sawName = true
        end
        recordHealthbox(role, shown, x, y, fopts and fopts.colors, group)
        lastRole = role
      end

      if type(oldGlyph) == "function" then
        FrlgFont.drawGlyph = function(code, x, y, fopts)
          if code == FrlgFont.CHAR_LV_2 then
            recordHealthbox("levelPrefix", "Lv", x, y, fopts and fopts.colors, group)
            afterLevelPrefix = true
            lastRole = "levelPrefix"
          elseif code == FrlgFont.CHAR_MALE then
            recordHealthbox("male", "", x, y, fopts and fopts.colors, group)
            lastRole = "male"
          elseif code == FrlgFont.CHAR_FEMALE then
            recordHealthbox("female", "", x, y, fopts and fopts.colors, group)
            lastRole = "female"
          else
            -- Healthbox currently uses only Lv / gender special glyphs.  Keep
            -- an unknown future glyph native rather than silently losing it.
            return oldGlyph(code, x, y, fopts)
          end
        end
      end

      -- Double-battle HP-number mode can bypass FrlgFont and use the bold
      -- healthbox digit helper.  Capture those characters as well.
      if oldBold then
        BattleChrome.drawHpBoldChar = function(ch, x, y)
          recordHealthbox("hpDigit", ch, x, y, nil, group)
        end
      end

      local packed = { pcall(originalHealthboxDraw, side, battler, opts) }
      FrlgFont.draw = oldDraw
      if oldGlyph then FrlgFont.drawGlyph = oldGlyph end
      if oldBold then BattleChrome.drawHpBoldChar = oldBold end
      if injectedGender and type(mon) == "table" then mon.gender = oldMonGender end
      if not packed[1] then error(packed[2], 0) end
      return unpack(packed, 2)
    end
  end

  local function setColor(c, alpha)
    c = c or {1,1,1,1}
    G.setColor(c[1] or 1, c[2] or 1, c[3] or 1, alpha == nil and (c[4] or 1) or alpha)
  end

  local function fontFor(px)
    px = math.max(9, math.floor((tonumber(px) or 12) + 0.5))
    local f = fontCache[px]
    if f then return f end
    local ok, value = pcall(G.newFont, px)
    if ok and value then
      if type(value.setFilter) == "function" then pcall(value.setFilter, value, "nearest", "nearest") end
      fontCache[px] = value
      return value
    end
    return G.getFont()
  end

  local function frame(viewport)
    local gx = tonumber(viewport and viewport.gameX) or 0
    local gy = tonumber(viewport and viewport.gameY) or 0
    local gw = tonumber(viewport and viewport.gameWidth)
    local gh = tonumber(viewport and viewport.gameHeight)
    if not (gw and gh and gw > 0 and gh > 0) then
      local ww, wh = G.getDimensions()
      local s = math.min(ww / 240, wh / 160)
      return (ww - 240*s)*0.5, (wh - 160*s)*0.5, s, s
    end
    return gx, gy, gw / 240, gh / 160
  end

  local function panelRect(viewport)
    local ox, oy, ux, uy = frame(viewport)
    local pct = tonumber(opt("battleUiSize", "100")) or 100
    pct = math.max(60, math.min(100, pct)) / 100
    local h = 48 * uy * pct
    return ox, oy + 160 * uy - h, 240 * ux, h, ux, uy, pct
  end

  local function rect(x,y,w,h,c,outline)
    setColor(c)
    G.rectangle(outline and "line" or "fill", x, y, w, h)
  end

  local function card(x,y,w,h,c,frameC)
    local r = math.max(3, math.min(w,h) * 0.055)
    local op=math.max(.25,math.min(1,(tonumber(opt("battleUiOpacity","100")) or 100)/100))
    local cc={c[1] or 1,c[2] or 1,c[3] or 1,math.min(1,(c[4] or 1)*op)}
    setColor(cc)
    local ok = pcall(G.rectangle, "fill", x, y, w, h, r, r)
    if not ok then G.rectangle("fill", x,y,w,h) end
    if frameC then
      setColor(frameC)
      local ok2 = pcall(G.rectangle, "line", x+0.5, y+0.5, math.max(0,w-1), math.max(0,h-1), r, r)
      if not ok2 then G.rectangle("line", x+0.5,y+0.5,math.max(0,w-1),math.max(0,h-1)) end
    end
  end

  local function fitText(text, font, maxW)
    text = tostring(text or "")
    if not font or not maxW or font:getWidth(text) <= maxW then return text end
    local ell = "..."
    local target = math.max(0, maxW - font:getWidth(ell))
    while #text > 0 and font:getWidth(text) > target do text = text:sub(1, #text-1) end
    return text .. ell
  end

  local function printText(text,font,x,y,w,align,c)
    if font then G.setFont(font) end
    setColor(c)
    text = tostring(text or "")
    if w and w > 0 then G.printf(text,x,y,w,align or "left") else G.print(text,x,y) end
  end

  local function activeBattler(st)
    if type(Ui.activeBattlerObject) == "function" then
      local ok, b = pcall(Ui.activeBattlerObject, st)
      if ok and b then return b end
    end
    local id = tonumber(Ui._active) or 0
    if id == 0 then return st and st.player end
    return st and st.battlers and st.battlers[id]
  end

  local function monName(mon)
    if type(mon) ~= "table" then return "POKéMON" end
    return tostring(mon.nickname or mon.name or mon.speciesName or "POKéMON")
  end

  local function moveName(id)
    if okMoves and Moves and type(Moves.displayName) == "function" then
      local ok, v = pcall(Moves.displayName, id)
      if ok and v then return tostring(v) end
    end
    return tostring(id or "-")
  end

  local function moveDef(id)
    if okMoves and Moves and type(Moves.get) == "function" then
      local ok, v = pcall(Moves.get, id)
      if ok and type(v) == "table" then return v end
    end
    return nil
  end

  local function typeName(id)
    if okTypes and Types and type(Types.name) == "function" then
      local ok, v = pcall(Types.name, id)
      if ok and v then return tostring(v) end
    end
    return tostring(id or "-")
  end


  local function drawGenderSymbol(kind, cx, cy, size, color)
    -- Draw around a real center point so the symbol can be aligned to the
    -- vertical center of the Modern-font nickname instead of inheriting the
    -- native GBA glyph baseline.
    local r = math.max(2, size * 0.22)
    setColor(color or (kind == "male" and {0.18,0.55,0.95,1} or {0.95,0.34,0.55,1}))
    G.setLineWidth(math.max(1.5, size * 0.09))
    G.circle("line", cx, cy, r)
    if kind == "male" then
      local d = r * 1.45
      G.line(cx + r*0.70, cy - r*0.70, cx + d, cy - d)
      G.line(cx + d, cy - d, cx + d*0.55, cy - d)
      G.line(cx + d, cy - d, cx + d, cy - d*0.55)
    else
      G.line(cx, cy + r, cx, cy + r*2.15)
      G.line(cx - r*0.55, cy + r*1.65, cx + r*0.55, cy + r*1.65)
    end
  end

  local function drawHealthboxModernText(viewport)
    if not enabled() or #healthboxText == 0 then return end
    local ox, oy, ux, uy = frame(viewport)
    local s = math.min(ux, uy)

    -- The HUD chrome is still the native Gen 3 size, so its replacement text
    -- needs to stay noticeably smaller than the lower Modern UI.  Use a
    -- heavier two-pass draw to match the visual weight of KIM's UI without
    -- letting the names/HP figures crowd the bars.
    local nameFont = fontFor(math.max(9, 5.55 * s))
    local levelFont = fontFor(math.max(9, 4.95 * s))
    local hpFont = fontFor(math.max(9, 5.35 * s))
    local fallback = {0.16,0.16,0.15,1}
    local namesByGroup = {}
    local hpByGroup = {}

    -- Singles HP is emitted by the native healthbox as two separate text
    -- calls ("%3d/" and "%3d").  Pre-join those pieces so the scalable
    -- Modern font reproduces the compact native "17/21" layout instead of
    -- spreading the current and max values across their old pixel-font Xs.
    for _, row in ipairs(healthboxText) do
      local g = hpByGroup[row.group] or {}
      hpByGroup[row.group] = g
      if row.kind == "hpCur" then
        g.cur = row
      elseif row.kind == "hpMax" then
        g.max = row
      elseif row.kind == "text" and g.cur and not g.max then
        -- Be tolerant of engine/font call-order differences: if the native
        -- max-HP number arrives as a generic numeric text call after hpCur,
        -- still fold it into the one compact Modern-font HP value.
        local compact = tostring(row.text or ""):gsub("%s+", "")
        if compact:match("^%d+$") and (tonumber(row.x) or 0) > (tonumber(g.cur.x) or -1) then
          g.max = row
          row._kimHpMax = true
        end
      end
    end

    local function boldPrint(text, font, x, y, color)
      G.setFont(font)
      setColor(color or fallback)
      G.print(text, x, y)
      G.print(text, x + math.max(0.65, 0.20 * s), y)
    end

    G.push("all")
    G.origin()
    G.setShader()
    G.setBlendMode("alpha")
    for _, row in ipairs(healthboxText) do
      local x = ox + row.x * ux
      local y = oy + row.y * uy

      if row.kind == "name" then
        -- The final-resolution font has a taller ascender than the native GBA
        -- font.  Drop the nickname a few pixels so it sits visually centered
        -- inside the healthbox header strip.
        y = y + 0.60 * s
        boldPrint(row.text, nameFont, x, y, row.color)
        namesByGroup[row.group] = { x = x, y = y, w = nameFont:getWidth(row.text) }

      elseif row.kind == "male" or row.kind == "female" then
        -- Anchor to the measured Modern-font nickname, leave a little more
        -- breathing room after the last letter, and center the symbol on the
        -- actual text line rather than the old pixel-font glyph baseline.
        local n = namesByGroup[row.group]
        local symbolSize = 5.25 * s
        local r = math.max(2, symbolSize * 0.22)
        local gx = n and (n.x + n.w + 1.45 * s + r) or (x + r)
        local gy = n and (n.y + nameFont:getHeight() * 0.54) or (y + r)
        drawGenderSymbol(row.kind, gx, gy, symbolSize,
          row.color or (row.kind == "male" and {0.18,0.55,0.95,1} or {0.95,0.34,0.55,1}))

      elseif row.kind == "levelPrefix" or row.kind == "levelDigits" then
        -- Match the slightly-lowered nickname baseline.
        boldPrint(row.text, levelFont, x, y + 0.85 * s, row.color)

      elseif row.kind == "hpCur" then
        local pair = hpByGroup[row.group]
        if pair and pair.cur and pair.max then
          local cur = tostring(pair.cur.text or ""):gsub("%s+", "")
          local maxv = tostring(pair.max.text or ""):gsub("%s+", "")
          local joined = cur .. maxv
          -- Preserve the native max-HP right edge.  v61 compacted the value
          -- from the current-HP X position, which pulled the whole string too
          -- far left.  Right-align the joined Modern-font string where the
          -- original max-HP number ended, effectively moving `17/` to `21`.
          local nativeMaxW = 18
          if type(FrlgFont.measure) == "function" then
            local okW, w = pcall(FrlgFont.measure, tostring(pair.max.text or ""), { small = true })
            if okW and tonumber(w) then nativeMaxW = tonumber(w) end
          end
          local right = ox + ((tonumber(pair.max.x) or tonumber(pair.cur.x) or 0) + nativeMaxW) * ux
          local joinedX = right - hpFont:getWidth(joined)
          boldPrint(joined, hpFont, joinedX, y + 2.55 * s, row.color)
        else
          boldPrint(row.text, hpFont, x, y + 2.55 * s, row.color)
        end

      elseif row.kind == "hpMax" or row._kimHpMax then
        -- Drawn together with hpCur above to preserve native compact spacing.

      elseif row.kind == "hpDigit" then
        -- Double-battle HP text still arrives one character at a time.
        boldPrint(row.text, hpFont, x, y + 2.55 * s, row.color)

      else
        boldPrint(row.text, nameFont, x, y + 0.60 * s, row.color)
      end
    end
    G.setColor(1,1,1,1)
    G.pop()
  end

  local function revealedMessage()
    if not (okMessage and Message and Message.open and type(Message.currentPage) == "function") then return nil end
    -- FRLG's first-battle Oak tutorial uses the special "voiceover" frame while
    -- the battlefield is dimmed.  It is still battle-owned dialogue and must be
    -- routed into KIM's lower Modern UI card just like the normal "battle"
    -- frame.  Reject field/sign/braille messages so this bridge remains scoped
    -- to the active battle presenter.
    if type(Message.frameKind) == "function" then
      local kind = Message.frameKind()
      if kind ~= "battle" and kind ~= "voiceover" then return nil end
    end
    local text = tostring(Message.currentPage() or "")
    local n = tonumber(Message._revealed)
    if not n or n >= #text then return text end
    if n <= 0 then return "" end
    -- Game3's battle text reaching this point is already plain display text.
    -- Most glyphs are single-byte ASCII; preserve UTF-8 boundaries when the
    -- runtime exposes utf8.offset, otherwise fall back to byte slicing.
    if utf8 and type(utf8.offset) == "function" then
      local ok, pos = pcall(utf8.offset, text, n + 1)
      if ok and pos then return text:sub(1, pos - 1) end
    end
    return text:sub(1, n)
  end

  local function drawBackdrop(viewport, c)
    local x,y,w,h = panelRect(viewport)
    local _,_,ux,uy = frame(viewport)

    -- The native lower panel is now suppressed at its source while KIM owns
    -- presentation.  Draw only KIM's requested alpha here; do not place an
    -- opaque clearing rectangle underneath it or the opacity slider would be
    -- visually neutralized again.
    local op=math.max(.25,math.min(1,(tonumber(opt("battleUiOpacity","100")) or 100)/100))
    rect(x,y,w,h,{c.surface[1],c.surface[2],c.surface[3],math.min(1,(c.surface[4] or 1)*op)})
    rect(x,y,w,math.max(1,2*math.min(ux,uy)),c.accent)
    return x,y,w,h
  end

  local function actionLabels(st)
    if st and st.safari then return nil end
    return { "FIGHT", "BAG", "POKéMON", "RUN" }
  end

  local function drawAction(viewport, st, c)
    local x,y,w,h,ux,uy = panelRect(viewport)
    drawBackdrop(viewport,c)
    local s = math.min(ux,uy)
    local textScale = math.max(0.50, math.min(2.00, (tonumber(opt("battleTextScale","100")) or 100) / 100)) * 1.50
    local body = fontFor(math.max(10, 5.9*s*textScale))
    local small = fontFor(math.max(9, 4.3*s*textScale))
    local pad = math.max(5*s, h*0.09)
    local gap = math.max(2*s, h*0.045)
    local leftW = w * 0.48
    local labels = actionLabels(st)
    if not labels then return false end

    card(x+pad,y+pad,leftW-pad-gap,h-2*pad,c.raised,c.frame)
    local b = activeBattler(st)
    local prompt = "What will " .. monName(b and b.mon) .. " do?"
    printText(prompt,small,x+pad*1.65,y+pad*1.65,leftW-pad*2.2,"left",c.text)

    local gx = x + leftW + gap
    local gw = w - (gx-x) - pad
    local gh = h - 2*pad
    local cw = (gw-gap)/2
    local ch = (gh-gap)/2
    local selected = math.max(1,math.min(4,tonumber(Ui._menuIndex) or 1))
    for i=1,4 do
      local col=(i-1)%2
      local row=math.floor((i-1)/2)
      local bx=gx+col*(cw+gap)
      local by=y+pad+row*(ch+gap)
      local fill=(i==selected) and c.selected or c.raised
      card(bx,by,cw,ch,fill,(i==selected) and c.accent or c.divider)
      local label=fitText(labels[i],body,cw-pad)
      local ty=by+(ch-body:getHeight())*0.5
      printText(label,body,bx+pad*0.5,ty,cw-pad,"center",c.text)
    end
    return true
  end

  local function drawMove(viewport, st, c)
    local x,y,w,h,ux,uy = panelRect(viewport)
    drawBackdrop(viewport,c)
    local s=math.min(ux,uy)
    local textScale=math.max(0.50,math.min(2.00,(tonumber(opt("battleTextScale","100")) or 100)/100))*1.50
    local body=fontFor(math.max(9,5.0*s*textScale))
    local infoFont=fontFor(math.max(8,3.6*s*textScale))
    local pad=math.max(4*s,h*0.075)
    local gap=math.max(2*s,h*0.04)
    local b=activeBattler(st)
    local mon=b and b.mon or nil
    local selected=math.max(1,math.min(4,tonumber(Ui._moveIndex) or 1))
    local showInfo=opt("battleMoveInfo",true)~=false
    local infoW=showInfo and w*0.30 or 0
    local listW=w-2*pad-(showInfo and (infoW+gap) or 0)
    local lx=x+pad
    local ly=y+pad
    local lh=h-2*pad
    local layout=tostring(opt("battleMoveLayout","grid"))

    if layout=="vertical" then
      local rh=(lh-3*gap)/4
      for i=1,4 do
        local by=ly+(i-1)*(rh+gap)
        local fill=(i==selected) and c.selected or c.raised
        card(lx,by,listW,rh,fill,(i==selected) and c.accent or c.divider)
        local mv=mon and mon.moves and mon.moves[i]
        local label=(mv and mv~=0 and mv~="") and moveName(mv) or "-"
        printText(fitText(label,body,listW-pad),body,lx+pad*0.7,by+(rh-body:getHeight())*0.5,listW-pad*1.4,"left",c.text)
      end
    else
      local cw=(listW-gap)/2
      local ch=(lh-gap)/2
      for i=1,4 do
        local col=(i-1)%2
        local row=math.floor((i-1)/2)
        local bx=lx+col*(cw+gap)
        local by=ly+row*(ch+gap)
        local fill=(i==selected) and c.selected or c.raised
        card(bx,by,cw,ch,fill,(i==selected) and c.accent or c.divider)
        local mv=mon and mon.moves and mon.moves[i]
        local label=(mv and mv~=0 and mv~="") and moveName(mv) or "-"
        printText(fitText(label,body,cw-pad),body,bx+pad*0.5,by+(ch-body:getHeight())*0.5,cw-pad,"center",c.text)
      end
    end

    if showInfo then
      local ix=lx+listW+gap
      card(ix,ly,infoW,lh,c.raised,c.frame)
      local mv=mon and mon.moves and mon.moves[selected]
      local def=(mv and mv~=0 and mv~="") and moveDef(mv) or nil
      local pp=mon and mon.pp and tonumber(mon.pp[selected]) or 0
      local maxPp=mon and mon.maxPp and tonumber(mon.maxPp[selected]) or (def and tonumber(def.pp)) or pp
      local typeLabel=def and typeName(def.type) or "-"
      local power=def and tonumber(def.power)
      local acc=def and tonumber(def.accuracy)
      local lines={
        "TYPE  "..typeLabel,
        string.format("PP    %d/%d",pp or 0,maxPp or 0),
        "POWER "..((power and power>0) and tostring(power) or "--"),
        "ACC   "..((acc and acc>0) and tostring(acc).."%" or "--"),
      }
      if Ui._mode=="target" then lines[4]="CHOOSE TARGET" end
      local lineH=lh/4
      for i,line in ipairs(lines) do
        printText(fitText(line,infoFont,infoW-pad*1.4),infoFont,ix+pad*0.7,ly+(i-1)*lineH+(lineH-infoFont:getHeight())*0.5,infoW-pad*1.4,"left",i==1 and c.accent or c.text)
      end
    end
    return true
  end

  local function drawMessage(viewport,c,text)
    local x,y,w,h,ux,uy=panelRect(viewport)
    drawBackdrop(viewport,c)
    local s=math.min(ux,uy)
    local textScale=math.max(0.50,math.min(2.00,(tonumber(opt("battleTextScale","100")) or 100)/100))*1.50
    local font=fontFor(math.max(10,5.2*s*textScale))
    local pad=math.max(5*s,h*0.10)
    card(x+pad,y+pad,w-2*pad,h-2*pad,c.raised,c.frame)
    printText(text or "",font,x+pad*1.65,y+pad*1.45,w-pad*3.3,"left",c.text)
    if okMessage and Message and Message._waiting and not Message._stay and not Message._held then
      local t=(love.timer and love.timer.getTime and love.timer.getTime()) or 0
      local bounce=math.floor(t*8)%4
      local aw=math.max(4*s,font:getHeight()*0.35)
      local ax=x+w-pad*1.9
      local ay=y+h-pad*1.4+bounce*(0.45*s)
      setColor(c.accent)
      G.polygon("fill",ax-aw,ay-aw*0.5,ax,ay+aw*0.5,ax+aw,ay-aw*0.5)
    end
    return true
  end

  local function drawCatchNicknamePrompt(viewport,c,msg)
    local x,y,w,h,ux,uy=panelRect(viewport)
    drawBackdrop(viewport,c)
    local s=math.min(ux,uy)
    local textScale=math.max(0.50,math.min(2.00,(tonumber(opt("battleTextScale","100")) or 100)/100))*1.50
    local body=fontFor(math.max(10,5.0*s*textScale))
    local choiceFont=fontFor(math.max(10,4.8*s*textScale))
    local pad=math.max(5*s,h*.09)
    local gap=math.max(3*s,w*.012)
    local choiceW=math.max(w*.22,choiceFont:getWidth("YES")+pad*3.0)
    choiceW=math.min(choiceW,w*.30)
    local msgW=w-3*pad-gap-choiceW
    local innerH=h-2*pad

    card(x+pad,y+pad,msgW,innerH,c.raised,c.frame)
    printText(msg or "",body,x+pad*1.55,y+pad*1.42,msgW-pad*2.55,"left",c.text)

    local cx=x+2*pad+msgW+gap
    local rowGap=math.max(2*s,innerH*.055)
    local rowH=(innerH-rowGap)/2
    for i=1,2 do
      local by=y+pad+(i-1)*(rowH+rowGap)
      local selected=i==(tonumber(Choice.cursor) or 1)
      card(cx,by,choiceW,rowH,selected and c.selected or c.raised,selected and c.accent or c.divider)
      local label=tostring((Choice.options and Choice.options[i]) or (i==1 and "YES" or "NO"))
      printText(fitText(label,choiceFont,choiceW-pad),choiceFont,cx+pad*.5,by+(rowH-choiceFont:getHeight())*.5,choiceW-pad,"center",selected and c.text or c.muted)
    end
    return true
  end

  local function fullscreenOwnsFrame()
    local stack=package.loaded["src.ui.game3.stack"]
    if not stack then local ok,v=pcall(require,"src.ui.game3.stack"); if ok then stack=v end end
    if stack and type(stack.fullscreen)=="function" then
      local ok,v=pcall(stack.fullscreen)
      if ok and v==true then return true end
    end
    return false
  end

  mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
    nextFn(game,viewport)
    if not enabled() then return end
    if type(Battle.isActive)~="function" or not Battle.isActive() then return end

    -- Healthbox text is captured from the native renderer and replayed at
    -- final window resolution before any child menu or lower-panel ownership
    -- checks.  This keeps names/levels/HP visible behind KIM's floating Party
    -- and Bag windows while still using the Modern UI font.
    drawHealthboxModernText(viewport)

    if fullscreenOwnsFrame() then return end
    if Ui._caughtDexScene then return end
    local catchNicknameChoice=modernCatchNicknameChoice()
    if okChoice and Choice and Choice.active and not catchNicknameChoice then return end

    -- Child menus own the whole interaction surface while open.  Battle Bag
    -- intentionally does not mark itself fullscreen in Game3 because the
    -- native battle remains underneath, so Stack.fullscreen() alone is not
    -- enough to suppress KIM's lower battle card.  Explicitly yield to Party
    -- Bag and Summary here; the Gen 3 Modern menu presenters redraw them when
    -- Modern UI is enabled.
    local PartyMenu=package.loaded["src.ui.game3.party_menu"]
    local BagMenu=package.loaded["src.ui.game3.bag_menu"]
    local SummaryMenu=package.loaded["src.ui.game3.summary_menu"]
    local Stack=package.loaded["src.ui.game3.stack"]
    if Stack and type(Stack.has)=="function" then
      if Stack.has("party") or Stack.has("bag") or Stack.has("summary") then return end
    end
    if PartyMenu and (PartyMenu.open or (PartyMenu.isOpen and PartyMenu.isOpen())) then return end
    if BagMenu and (BagMenu.open or (BagMenu.isOpen and BagMenu.isOpen())) then return end
    if SummaryMenu and (SummaryMenu.open or (SummaryMenu.isOpen and SummaryMenu.isOpen())) then return end

    local st=(type(Battle.getState)=="function" and Battle.getState()) or Battle._st
    if type(st)~="table" then return end
    -- The Old Man/Pokedude/Safari controllers have specialized native command
    -- labels and tutorials. Keep them native until their dedicated adapters
    -- land instead of presenting misleading standard FIGHT/BAG labels.
    if st.safari or st.oldManTutorial or st.pokedude then return end

    local c=theme()
    G.push("all")
    G.origin()
    G.setShader()
    G.setBlendMode("alpha")

    local msg=revealedMessage()
    if catchNicknameChoice then
      drawCatchNicknamePrompt(viewport,c,msg or "")
    elseif msg~=nil then
      drawMessage(viewport,c,msg)
    elseif Ui._mode=="menu" then
      drawAction(viewport,st,c)
    elseif Ui._mode=="moves" or Ui._mode=="target" then
      drawMove(viewport,st,c)
    else
      -- Native Game3 keeps its lower textbox plane alive between scripted
      -- battle messages. Replace that idle surface too so the transition never
      -- flashes back to FRLG/E chrome for a frame.
      drawMessage(viewport,c,"")
    end

    G.setColor(1,1,1,1)
    G.pop()
  end,9900)

  mod.exports=mod.exports or {}
  mod.exports.gen3ModernBattleUi=true
  return true
end
