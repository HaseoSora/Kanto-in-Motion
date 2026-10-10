-- Kanto in Motion - Gen 3 Modern Options UI
--
-- Presentation-only adapter for the native Game3 Options screens. FR/LG and
-- R/S/E keep complete ownership of option rows, grouping, input, persistence,
-- child screens, and engine-side side effects. KIM suppresses only the native
-- pixels while the Options layer itself is on top, then redraws the same live
-- state in the Gen 3 Modern UI style at final-window resolution.
return function(mod)
  if not (love and love.graphics and mod and mod.hooks and type(mod.hooks.wrap) == "function") then
    return false
  end

  local G = love.graphics
  local Style = mod._kantoInMotionGen3Ui
  local okStack, Stack = pcall(require, "src.ui.game3.stack")
  local okFrlg, FrlgOptions = pcall(require, "src.ui.game3.option_menu")
  local okRse, RseOptions = pcall(require, "src.ui.game3.rse.option_menu")
  local okOptions, Options = pcall(require, "src.core.game3.options")
  local okRomText, RomText = pcall(require, "src.core.game3.rom_text")
  if not okStack or type(Stack) ~= "table" then return false end
  if not ((okFrlg and type(FrlgOptions) == "table") or (okRse and type(RseOptions) == "table")) then
    return false
  end

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
    return opt("gen3IntegratedModernUi", true) ~= false
  end

  local function uiScaleFactor()
    if Style and Style.uiScale then local ww,wh=G.getDimensions(); return Style.uiScale(ww,wh) end
    local value=tostring(opt("gen3UiScale","100")); if value:lower()=="auto" then return 1 end
    local pct=tonumber(value) or 100; pct=math.max(75,math.min(400,pct)); return pct/100
  end

  local function theme()
    if Style and Style.theme then return Style.theme() end
    local themes = mod._kantoInMotionGen3Themes
    if type(themes) == "table" then
      return themes[tostring(opt("gen3UiTheme", "default"))] or themes.default or FALLBACK
    end
    return FALLBACK
  end

  local function color(c,alpha,foreground)
    if Style and Style.color then return Style.color(c,alpha,foreground~=false) end
    c=c or {1,1,1,1}; G.setColor(c[1] or 1,c[2] or 1,c[3] or 1,alpha==nil and (c[4] or 1) or alpha)
  end

  local function fontFor(px)
    if Style and Style.font then return Style.font(px) end
    px = math.max(9, math.floor((tonumber(px) or 12) + 0.5))
    if fontCache[px] then return fontCache[px] end
    local ok, f = pcall(G.newFont, px)
    if ok and f then
      if type(f.setFilter) == "function" then pcall(f.setFilter, f, "nearest", "nearest") end
      fontCache[px] = f
      return f
    end
    return G.getFont()
  end

  local function text(v, font, x, y, w, align, c)
    if Style and Style.text then return Style.text(v,font,x,y,w,align,c) end
    if font then G.setFont(font) end
    color(c)
    v = tostring(v or "")
    if w and w > 0 then G.printf(v, x, y, w, align or "left") else G.print(v, x, y) end
  end

  local function fit(v, font, maxW)
    v = tostring(v or "")
    if not font or not maxW or font:getWidth(v) <= maxW then return v end
    local suffix = "..."
    local target = math.max(0, maxW - font:getWidth(suffix))
    while #v > 0 and font:getWidth(v) > target do v = v:sub(1, #v - 1) end
    return v .. suffix
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

  local function card(x, y, w, h, fill, line, radius)
    radius = radius or math.max(4, math.min(w,h)*0.045)
    local pa=Style and Style.panelOpacity and Style.panelOpacity(1) or 1
    color(fill,math.min(1,(fill and fill[4] or 1)*pa),false)
    G.rectangle("fill", x, y, w, h, radius, radius)
    if line then
      color(line,nil,true)
      G.setLineWidth(math.max(1, math.min(w,h)*0.008))
      G.rectangle("line", x+0.5, y+0.5, math.max(0,w-1), math.max(0,h-1), radius, radius)
    end
  end

  local function background(x,y,w,h,c)
    local pa=Style and Style.panelOpacity and Style.panelOpacity(1) or 1
    color(c.surface,math.min(1,(c.surface[4] or 1)*pa),false)
    G.rectangle("fill",x,y,w,h)
    local bar = math.max(2, h*0.012)
    color(c.accent,nil,true)
    G.rectangle("fill",x,y,w,bar)
  end

  local function chevron(cx, cy, size, dir, c)
    local s = math.max(3, size or 8)
    color(c)
    G.setLineWidth(math.max(1.25, s*0.16))
    if dir == "up" then
      G.line(cx-s*0.50,cy+s*0.28,cx,cy-s*0.28,cx+s*0.50,cy+s*0.28)
    elseif dir == "down" then
      G.line(cx-s*0.50,cy-s*0.28,cx,cy+s*0.28,cx+s*0.50,cy-s*0.28)
    elseif dir == "left" then
      G.line(cx+s*0.28,cy-s*0.50,cx-s*0.28,cy,cx+s*0.28,cy+s*0.50)
    else
      G.line(cx-s*0.28,cy-s*0.50,cx+s*0.28,cy,cx-s*0.28,cy+s*0.50)
    end
  end

  local function topLayer()
    local layers = Stack._layers
    if type(layers) ~= "table" then return nil end
    return layers[#layers]
  end

  local function setFloating(on)
    local layers = Stack._layers
    if type(layers) ~= "table" then return end
    for i = #layers, 1, -1 do
      local layer = layers[i]
      if layer and layer.id == "option" then
        if on then
          if layer._kimGen3OptionsOriginal == nil then
            layer._kimGen3OptionsOriginal = {
              hideBelow = layer.hideBelow,
              drawUnder = layer.drawUnder,
              fullscreen = layer.fullscreen,
            }
          end
          layer.hideBelow = false
          layer.drawUnder = true
          layer.fullscreen = false
        elseif layer._kimGen3OptionsOriginal then
          local o = layer._kimGen3OptionsOriginal
          layer.hideBelow, layer.drawUnder, layer.fullscreen = o.hideBelow, o.drawUnder, o.fullscreen
          layer._kimGen3OptionsOriginal = nil
        end
        return
      end
    end
  end

  local function frlgOpen()
    return okFrlg and FrlgOptions and FrlgOptions.open == true
  end

  local function rseOpen()
    return okRse and RseOptions and type(RseOptions._st) == "table"
      and type(RseOptions._st.pages) == "table"
  end

  local function active()
    local layer = topLayer()
    if not layer or layer.id ~= "option" then return nil end
    if okFrlg and layer.mod == FrlgOptions and frlgOpen() then
      local pages = FrlgOptions._pages
      local p = type(pages) == "table" and pages[#pages] or nil
      if p then return FrlgOptions, p, FrlgOptions._ctx, pages, false end
    end
    if okRse and layer.mod == RseOptions and rseOpen() then
      local st = RseOptions._st
      local pages = st.pages
      local p = pages[#pages]
      if p then return RseOptions, p, st.ctx, pages, true end
    end
    return nil
  end

  local function stripColors(s)
    s = tostring(s or "")
    s = s:gsub("{COLOR[^}]*}", ""):gsub("{SHADOW[^}]*}", ""):gsub("{HIGHLIGHT[^}]*}", "")
    s = s:gsub("\252[\1\2\3].", ""):gsub("\252\4...", "")
    return s
  end

  local function plainRom(key)
    if okRomText and RomText and type(RomText.plain) == "function" then
      local ok, v = pcall(RomText.plain, key)
      if ok and v ~= nil then return stripColors(v) end
    end
    return tostring(key or "")
  end

  local function rowLabel(row)
    if not row then return "" end
    if row.cart then return plainRom(row.cart.label or row.id or "OPTION") end
    return tostring(row.label or row.id or "OPTION")
  end

  local function rseCartValue(row, ctx)
    local r = row and row.cart
    if not r then return nil end
    local block = okOptions and Options and type(Options.block) == "function"
      and Options.block((ctx and ctx.options) or {}) or ((ctx and ctx.options) or {})
    local cur = tonumber(block and block[r.key]) or 0
    if r.frame then return "TYPE " .. tostring(cur + 1) end
    local keys = r.choices
    if type(keys) == "table" then
      local key = keys[cur + 1]
      if key then return plainRom(key) end
    end
    return tostring(cur)
  end

  local function rowValue(row, ctx, isRse)
    if not row then return "" end
    if row.group then
      if type(row.value) == "function" then
        local ok, v = pcall(row.value, ctx)
        if ok and v ~= nil then return tostring(v) end
      end
      return "OPEN"
    end
    if isRse and row.cart then return rseCartValue(row, ctx) or "" end
    if type(row.value) == "function" then
      local ok, v = pcall(row.value, ctx)
      if ok and v ~= nil then return tostring(v) end
    elseif row.value ~= nil and type(row.value) ~= "function" then
      return tostring(row.value)
    end
    if row.activate then return "OPEN" end
    return ""
  end

  local function rowAdjustable(row)
    return row and (row.cart ~= nil or type(row.step) == "function")
  end

  local function windowRect(viewport)
    local sx,sy,sw,sh = playfield(viewport)
    local roomy = sw >= 720 and sh >= 460
    local fw = roomy and 0.72 or 0.94
    local fh = roomy and 0.84 or 0.94
    local userScale = uiScaleFactor()
    local w = math.min(sw*0.97, sw*fw*userScale)
    local h = math.min(sh*0.97, sh*fh*userScale)
    if Style and Style.layoutStyle and Style.layoutStyle()=="full" then w=sw*.94; h=sh*.92 end
    return sx+(sw-w)*0.5, sy+(sh-h)*0.5, w, h
  end

  local function drawOptions(viewport, c, p, ctx, pages, isRse)
    setFloating(true)
    local x,y,w,h = windowRect(viewport)
    local r = math.max(7, math.min(w,h)*0.018)
    if Style and Style.panel then
      Style.panel(x,y,w,h,c,1)
      color(c.accent,nil,true); G.rectangle("fill",x,y,w,math.max(2,h*.012),r,r)
    else
      color(c.frameShadow or FALLBACK.frameShadow,nil,false)
      G.rectangle("fill", x+math.max(3,w*0.006), y+math.max(4,h*0.009), w, h, r, r)
      background(x,y,w,h,c)
      color(c.frame,nil,true)
      G.setLineWidth(math.max(1,math.min(w,h)*0.0035))
      G.rectangle("line",x+0.5,y+0.5,w-1,h-1,r,r)
    end

    local s = math.min(w/260,h/170)
    local pad = math.max(8*s,w*0.026)
    local titleF = fontFor(11.5*s)
    local bodyF = fontFor(7.7*s)
    local valueF = fontFor(7.0*s)
    local smallF = fontFor(5.8*s)
    local descF = fontFor(5.8*s)
    local header = math.max(28*s,h*0.16)

    local rows = type(p.rows) == "table" and p.rows or {}
    local total = #rows + 1 -- native CANCEL row
    local idx = math.max(1, math.min(total, tonumber(p.index) or 1))
    local selectedRow = idx<=#rows and rows[idx] or nil
    local isKim = p._kimDirectSettings == true

    local pageTitle = "OPTIONS"
    local subtitle
    if isKim then
      pageTitle = "KANTO IN MOTION"
      local section = tostring(p._kimSection or "main")
      subtitle = section == "ui" and "UI SETTINGS"
        or section == "battle" and "BATTLE SETTINGS"
        or "MOD SETTINGS"
    else
      local depth = type(pages) == "table" and #pages or 1
      subtitle = depth > 1 and tostring(p.title or "CATEGORY"):upper() or "SETTINGS"
    end
    text(pageTitle,titleF,x+pad,y+pad*0.55,w*0.52,"left",c.text)
    text(fit(subtitle,smallF,w*0.38),smallF,x+w*0.57,y+pad*0.9,w*0.36-pad,"right",c.accent)

    local desc = ""
    if isKim then
      if selectedRow then desc = tostring(selectedRow.description or "")
      else desc = "Return to the previous Options page." end
    end

    local hint
    if idx>#rows then
      hint = "A / B  BACK"
    elseif selectedRow and selectedRow.group then
      hint = "UP / DOWN  SELECT    A  OPEN CATEGORY    B  BACK"
    elseif selectedRow and selectedRow.activate then
      hint = "UP / DOWN  SELECT    A  OPEN    B  BACK"
    elseif rowAdjustable(selectedRow) then
      hint = "UP / DOWN  SELECT    LEFT / RIGHT  CHANGE    B  BACK"
    else
      hint = "UP / DOWN  SELECT    A  SELECT    B  BACK"
    end

    local baseFooter = math.max(25*s,h*0.15)
    local descH = 0
    if desc ~= "" then
      local _, wrapped = descF:getWrap(desc, w-pad*2.0)
      descH = (type(wrapped)=="table" and math.max(1,#wrapped) or 1) * descF:getHeight()
    end
    local footer = baseFooter
    if isKim and desc ~= "" then
      footer = math.max(baseFooter, descH + smallF:getHeight() + 20*s)
    end

    local scroll = math.max(0, tonumber(p.scroll) or 0)
    local listTop = y + header
    local listH = math.max(1,h-header-footer)
    local den=Style and Style.density and Style.density() or 1
    local minRow = (math.max(bodyF:getHeight(),valueF:getHeight()) + math.max(7*s,4))*den
    local desired = 7
    local visible = math.max(4, math.min(desired, math.floor(listH/math.max(1,minRow))))
    visible = math.min(visible,total)
    local maxScroll = math.max(0,total-visible)
    scroll = math.max(0,math.min(scroll,maxScroll))
    if idx <= scroll then scroll = idx-1 end
    if idx > scroll+visible then scroll = idx-visible end
    scroll = math.max(0,math.min(scroll,maxScroll))
    local rowH = listH/math.max(1,visible)

    for slot=1,visible do
      local ri = scroll+slot
      if ri > total then break end
      local yy = listTop+(slot-1)*rowH
      local selected = ri==idx
      local row = rows[ri]
      local isCancel = ri>#rows
      if selected then
        card(x+pad*0.72,yy+rowH*0.09,w-pad*1.44,rowH*0.82,c.selected,c.accent,4*s)
        color(c.accent)
        G.rectangle("fill",x+pad*0.72,yy+rowH*0.09,math.max(2,1.4*s),rowH*0.82,2*s,2*s)
      elseif slot%2==0 then
        color(c.raised,0.22)
        G.rectangle("fill",x+pad*0.72,yy+rowH*0.10,w-pad*1.44,rowH*0.80,3*s,3*s)
      end

      local label = isCancel and "CANCEL" or rowLabel(row)
      local value = isCancel and "" or rowValue(row,ctx,isRse)
      local lx = x+pad*1.35
      local lw = w*0.48
      local vx = x+w*0.57
      local vw = w-pad*1.55-(vx-x)
      local lab = fit(label,bodyF,lw)
      local val = fit(value,valueF,math.max(1,vw-((selected and rowAdjustable(row)) and 25*s or 0)))
      local ty = yy+(rowH-bodyF:getHeight())*0.5
      text(lab,bodyF,lx,ty,lw,"left",selected and c.text or c.muted)
      if val ~= "" then
        local vy = yy+(rowH-valueF:getHeight())*0.5
        text(val,valueF,vx,vy,vw,"right",selected and c.text or c.accent)
        if selected and rowAdjustable(row) then
          local cy = yy+rowH*0.5
          local sz = math.max(5*s,valueF:getHeight()*0.54)
          chevron(vx-4*s,cy,sz,"left",c.accent)
          chevron(x+w-pad*0.95,cy,sz,"right",c.accent)
        end
      end
    end

    if scroll > 0 then
      chevron(x+w-pad*0.30,listTop+8*s,math.max(7*s,smallF:getHeight()*0.7),"up",c.accent)
    end
    if scroll+visible < total then
      chevron(x+w-pad*0.30,listTop+listH-8*s,math.max(7*s,smallF:getHeight()*0.7),"down",c.accent)
    end

    local fy = y+h-footer
    color(c.divider,0.55)
    G.rectangle("fill",x+pad*0.7,fy,w-pad*1.4,math.max(1,s))
    if isKim and desc ~= "" then
      text(desc,descF,x+pad,fy+8*s,w-pad*2,"left",c.muted)
      text(fit(hint,smallF,w-pad*2),smallF,x+pad,y+h-smallF:getHeight()-8*s,w-pad*2,"center",c.accent)
    else
      text(fit(hint,smallF,w-pad*2),smallF,x+pad,fy+(footer-smallF:getHeight())*0.5,w-pad*2,"center",c.muted)
    end
    return true
  end

  local KIM_MOD_ID = "animated_menu_pokemon"

  -- Gen 3 does not run the normal mod.ui screen stack directly. Its OPTIONS
  -- screen belongs to src.ui.game3.stack, so trying to mod.ui.push() KIM's
  -- Gen1/2 ListMenu leaves the Game3 OPTIONS layer owning input and nothing
  -- usable appears. Build a native Game3 option page from KIM's live schema
  -- instead. The source OptionMenu still owns navigation/input/persistence;
  -- this only supplies rows for the child page.
  local function setKimOption(ctx, key, value)
    local game = ctx and ctx.game
    local options = game and game.save and game.save.options
    if options then
      options.modOptions = options.modOptions or {}
      options.modOptions[KIM_MOD_ID] = options.modOptions[KIM_MOD_ID] or {}
      options.modOptions[KIM_MOD_ID][key] = value
    end
    local loader = game and game.mods
    if loader then
      loader.modOptions = loader.modOptions or {}
      loader.modOptions[KIM_MOD_ID] = loader.modOptions[KIM_MOD_ID] or {}
      loader.modOptions[KIM_MOD_ID][key] = value
      if loader.events and type(loader.events.emit) == "function" then
        pcall(loader.events.emit, loader.events, "mod.options_changed",
          { mod = KIM_MOD_ID, key = key, value = value })
      end
    end
    if game and type(game.writeOptions) == "function" then
      pcall(game.writeOptions, game)
    end
  end

  local function kimCurrent(row)
    if not row then return nil end
    local value = opt(row.key, row.default)
    if value == nil then value = row.default end
    return value
  end

  local function kimValueLabel(row)
    if not row then return "" end
    local value = kimCurrent(row)
    if row.type == "toggle" then
      return value ~= false and "ON" or "OFF"
    end
    if row.type == "choice" then
      for _, choice in ipairs(row.choices or {}) do
        if tostring(choice[2]) == tostring(value) then
          return tostring(choice[1] or choice[2] or "")
        end
      end
      return tostring(value == nil and "----" or value)
    end
    return tostring(value == nil and "" or value)
  end

  local function stepKimRow(ctx, row, dir)
    if not row or not row.key then return false end
    if row.type == "toggle" then
      setKimOption(ctx, row.key, kimCurrent(row) == false)
      return true
    end
    if row.type == "choice" then
      local choices = row.choices or {}
      if #choices == 0 then return false end
      local current = kimCurrent(row)
      local index = 1
      for i, choice in ipairs(choices) do
        if tostring(choice[2]) == tostring(current) then index = i break end
      end
      local delta = (tonumber(dir) or 1) < 0 and -1 or 1
      index = ((index - 1 + delta) % #choices) + 1
      setKimOption(ctx, row.key, choices[index][2])
      return true
    end
    return false
  end

  local KIM_UI_KEYS = {
    gen3UiTheme=true, gen3UiScale=true, gen3FontScale=true, gen3PixelFont=true,
    gen3FrameStyle=true, gen3FrameAsset=true, gen3FrameScale=true,
    gen3Density=true, gen3LayoutStyle=true, gen3PanelOpacity=true,
    gen3ForegroundOpacity=true, gen3MinimalUi=true, gen3HideOriginalUi=true,
    gen3MenuUi=true, gen3PokemonUi=true, gen3ManagerUi=true,
    gen3StartMenuFastJump=true, gen3StartMenuInset=true,
    gen3DialogueUi=true, gen3DialogueUiScale=true, gen3DialogueTextScale=true,
  }

  local KIM_BATTLE_KEYS = {
    battleUiWip=true, battleUiSize=true, battleUiOpacity=true,
    battleTextScale=true, battleMoveLayout=true, battleMoveInfo=true,
    battleSprites=true, hdBattleBackgrounds=true,
    battleShadowQuality=true, battleShadowOpacity=true,
  }

  local function kimSchemaByKey()
    local out = {}
    for _, spec in ipairs(mod._kantoInMotionOptionSchema or {}) do
      if type(spec)=="table" and type(spec.key)=="string" then out[spec.key]=spec end
    end
    return out
  end

  local function kimOptionRow(ctx, spec)
    if not (type(spec)=="table" and type(spec.key)=="string") then return nil end
    if spec.type ~= "toggle" and spec.type ~= "choice" then return nil end
    local row = spec
    return {
      id = "kim:" .. row.key,
      label = tostring(row.label or row.key),
      description = tostring(row.description or ""),
      value = function() return kimValueLabel(row) end,
      step = function(_, dir) return stepKimRow(ctx, row, dir) end,
      _kimSpec = row,
    }
  end

  local function kimRowsForSet(ctx, keySet)
    local rows, specs = {}, {}
    for _, spec in ipairs(mod._kantoInMotionOptionSchema or {}) do
      if type(spec)=="table" and type(spec.key)=="string" and keySet[spec.key]
          and (spec.type=="toggle" or spec.type=="choice") then
        local row=kimOptionRow(ctx,spec)
        if row then rows[#rows+1]=row; specs[#specs+1]=spec end
      end
    end
    return rows,specs
  end

  local function resetKimSpecs(ctx, specs)
    for _, spec in ipairs(specs or {}) do
      if spec.default ~= nil then setKimOption(ctx,spec.key,spec.default) end
    end
  end

  local function kimPages(menu,isRse)
    if isRse then
      local st=menu and menu._st
      return st and st.pages
    end
    return menu and menu._pages
  end

  local function pushKimPage(menu,isRse,title,section,rows)
    local pages=kimPages(menu,isRse)
    if type(pages)~="table" or type(rows)~="table" then return false end
    pages[#pages+1]={
      title=title,
      rows=rows,
      index=1,
      scroll=0,
      _kimDirectSettings=true,
      _kimSection=section,
    }
    menu.cursor=1
    return true
  end

  local function buildKimCategoryRows(menu,isRse,ctx,keySet,section)
    local rows,specs=kimRowsForSet(ctx,keySet)
    rows[#rows+1]={
      id="kim:reset:"..section,
      label="RESET TO DEFAULT",
      value=function() return "RESET" end,
      description=section=="ui"
        and "Restore all Gen 3 Modern UI settings in this section to their defaults."
        or "Restore all Gen 3 battle presentation settings in this section to their defaults.",
      activate=function()
        resetKimSpecs(ctx,specs)
      end,
    }
    return rows
  end

  local function buildKimRootRows(menu,isRse,ctx)
    local byKey=kimSchemaByKey()
    local rows={}

    local master=kimOptionRow(ctx,byKey.gen3IntegratedModernUi)
    if master then rows[#rows+1]=master end

    rows[#rows+1]={
      id="kim:ui_settings",
      label="UI SETTINGS",
      group=true,
      value=function() return "OPEN" end,
      description="Customize Gen 3 themes, scale, fonts, frames, opacity, layout, dialogue and other Modern UI presentation settings.",
      activate=function()
        local child=buildKimCategoryRows(menu,isRse,ctx,KIM_UI_KEYS,"ui")
        pushKimPage(menu,isRse,"UI SETTINGS","ui",child)
      end,
    }

    for _, key in ipairs({"enabled","menuIcons","animate"}) do
      local row=kimOptionRow(ctx,byKey[key])
      if row then rows[#rows+1]=row end
    end

    rows[#rows+1]={
      id="kim:battle_settings",
      label="BATTLE SETTINGS",
      group=true,
      value=function() return "OPEN" end,
      description="Customize the Gen 3 Modern Battle UI, battle text, HD battle sprites/backgrounds and Pokémon shadows.",
      activate=function()
        local child=buildKimCategoryRows(menu,isRse,ctx,KIM_BATTLE_KEYS,"battle")
        pushKimPage(menu,isRse,"BATTLE SETTINGS","battle",child)
      end,
    }

    -- Keep future schema additions accessible even if they have not yet been
    -- assigned to one of the explicit groups above.
    local shown={gen3IntegratedModernUi=true,enabled=true,menuIcons=true,animate=true}
    for k in pairs(KIM_UI_KEYS) do shown[k]=true end
    for k in pairs(KIM_BATTLE_KEYS) do shown[k]=true end
    for _,spec in ipairs(mod._kantoInMotionOptionSchema or {}) do
      if type(spec)=="table" and type(spec.key)=="string" and not shown[spec.key] then
        local row=kimOptionRow(ctx,spec)
        if row then rows[#rows+1]=row end
      end
    end
    return rows
  end

  local function openKimSettingsPage(menu, isRse, ctx)
    local rows=buildKimRootRows(menu,isRse,ctx)
    if #rows==0 then return false end
    return pushKimPage(menu,isRse,"KANTO IN MOTION","main",rows)
  end

  local function kimSettingsRow(menu, isRse)
    return {
      id = "kanto_in_motion",
      label = "KANTO IN MOTION",
      value = function() return "OPEN" end,
      activate = function(ctx)
        local ok, opened = pcall(openKimSettingsPage, menu, isRse, ctx)
        if not ok or opened ~= true then
          mod._kantoInMotionGen3OptionsKimOpenError = tostring(ok and "NO KIM OPTION ROWS" or opened)
        else
          mod._kantoInMotionGen3OptionsKimOpenError = nil
        end
      end,
    }
  end

  local function menuPage(menu,isRse)
    local pages
    if isRse then
      local st=menu and menu._st; pages=st and st.pages
    else
      pages=menu and menu._pages
    end
    return type(pages)=="table" and pages[#pages] or nil
  end

  local function presenterEnabledFor(menu,isRse)
    local p=menuPage(menu,isRse)
    if p and p._kimDirectSettings and Style and Style.presenterEnabled then
      return Style.presenterEnabled("manager")
    end
    return enabled()
  end

  local function injectKimSettingsRow(menu, isRse)
    local pages
    if isRse then
      local st = menu and menu._st
      pages = st and st.pages
    else
      pages = menu and menu._pages
    end
    local top = type(pages) == "table" and pages[1] or nil
    local rows = top and top.rows
    if type(rows) ~= "table" then return end
    for _, row in ipairs(rows) do
      if row and row.id == "kanto_in_motion" then return end
    end
    local at = #rows + 1
    for i, row in ipairs(rows) do
      if row and row.id == "mods" then
        at = i
        break
      end
    end
    table.insert(rows, at, kimSettingsRow(menu, isRse))
  end

  local function wrapMenu(menu, flag, openFn, isRse)
    if type(menu) ~= "table" or menu[flag] then return end
    local upstreamDraw = menu.draw
    local upstreamShow = menu.show
    if type(upstreamDraw) == "function" then
      menu.draw = function(...)
        if presenterEnabledFor(menu,isRse==true) and (not Style or not Style.hideOriginal or Style.hideOriginal()) and openFn() then return end
        return upstreamDraw(...)
      end
    end
    if type(upstreamShow) == "function" then
      menu.show = function(...)
        local out = { upstreamShow(...) }
        injectKimSettingsRow(menu, isRse == true)
        if enabled() then setFloating(true) end
        return unpack(out)
      end
    end
    menu[flag] = true
  end

  if okFrlg and type(FrlgOptions) == "table" then
    wrapMenu(FrlgOptions,"__kimGen3ModernOptionsV89",frlgOpen,false)
  end
  if okRse and type(RseOptions) == "table" then
    wrapMenu(RseOptions,"__kimGen3ModernOptionsV89",rseOpen,true)
  end

  mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
    nextFn(game,viewport)
    local menu,p,ctx,pages,isRse = active()
    if not menu then if not enabled() then setFloating(false) end; return end
    if not presenterEnabledFor(menu,isRse) then setFloating(false); return end
    local c = theme()
    -- Keep this presenter leak-proof: once the graphics state is pushed, the
    -- draw itself is protected so a presentation error cannot skip the pop.
    G.push("all")
    local ok,err = pcall(function()
      G.origin(); G.setShader(); G.setBlendMode("alpha")
      drawOptions(viewport,c,p,ctx,pages,isRse)
    end)
    G.setScissor(); G.setShader(); G.setBlendMode("alpha"); G.setColor(1,1,1,1)
    G.pop()
    if not ok then mod._kantoInMotionGen3OptionsLastDrawError = tostring(err)
    else mod._kantoInMotionGen3OptionsLastDrawError = nil end
  end,11150)

  mod.exports = mod.exports or {}
  mod.exports.gen3ModernOptionsUi = true
  return true
end
