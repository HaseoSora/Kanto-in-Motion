-- Kanto in Motion - Gen 3 Modern core-menu foundation
--
-- Presentation-only floating windows for the native Game3 Start, Party and Bag screens.
-- Game3 keeps complete ownership of input, state, battle item routing, party
-- switching and child-screen transitions. KIM suppresses only the native menu
-- pixels and redraws the same live state at final window resolution, matching
-- the separate-window behavior used by the Gen 2 Modern UI.
return function(mod)
  if not (love and love.graphics and mod and mod.hooks and type(mod.hooks.wrap) == "function") then
    return false
  end

  local G = love.graphics
  local Style = mod._kantoInMotionGen3Ui
  local okParty, PartyMenu = pcall(require, "src.ui.game3.party_menu")
  local okBag, BagMenu = pcall(require, "src.ui.game3.bag_menu")
  local okPokemon, Pokemon = pcall(require, "src.core.game3.pokemon")
  local okItems, ItemsData = pcall(require, "src.core.game3.items_data")
  local okSummary, SummaryMenu = pcall(require, "src.ui.game3.summary_menu")
  local okSummaryData, SummaryData = pcall(require, "src.core.game3.summary_data")
  local okStack, Game3Stack = pcall(require, "src.ui.game3.stack")
  local okOam, Oam = pcall(require, "src.core.game3.oam")
  local okRseBag, RseBag = pcall(require, "src.ui.game3.rse.bag_menu")
  local okStart, StartMenu = pcall(require, "src.ui.game3.start_menu")
  local okRomText, RomText = pcall(require, "src.core.game3.rom_text")
  local okStatGrowth, StatGrowth = pcall(require, "src.ui.game3.stat_growth")
  local okNaming, Naming = pcall(require, "src.ui.game3.naming")
  local okEvolution, EvolutionScene = pcall(require, "src.ui.game3.evolution_scene")
  if not (okParty and type(PartyMenu) == "table" and okBag and type(BagMenu) == "table") then
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

  local function enabled(kind)
    if Style and Style.presenterEnabled then return Style.presenterEnabled(kind or "menu") end
    return opt("gen3IntegratedModernUi", true) ~= false
  end

  -- Game3's source HUD normally routes only UP/DOWN to StartMenu.move().
  -- KIM renders the EXIT confirmation as a horizontal YES / NO pair, so when
  -- Modern UI owns that prompt, make the controls match what is on screen:
  -- LEFT selects YES, RIGHT selects NO.  Keep the source behavior untouched
  -- whenever Gen 3 Modern UI is disabled.  The same StartMenu module is shared
  -- by FR/LG and R/S/E, so this applies consistently to both families.
  if okStart and StartMenu and not StartMenu.__kimGen3HorizontalExitConfirmV86 then
    StartMenu.handleInput=function(input)
      if not (input and input.wasPressed) then return end

      if enabled("menu") and StartMenu._confirmExit then
        local ci=tonumber(StartMenu._confirmCursor) or 2
        if input:wasPressed("left") then
          if ci ~= 1 then StartMenu.move(-1) end -- YES is the left button
        elseif input:wasPressed("right") then
          if ci ~= 2 then StartMenu.move(1) end  -- NO is the right button
        elseif input:wasPressed("a") then
          StartMenu.confirm()
        elseif input:wasPressed("b") or input:wasPressed("start") then
          if StartMenu.cancel then StartMenu.cancel() else StartMenu.close() end
        end
        return
      end

      -- Exact source HUD routing for the ordinary vertical Start Menu and for
      -- vanilla/non-Modern presentation.
      if enabled("menu") and opt("gen3StartMenuFastJump",true)~=false and not StartMenu._confirmExit
          and (input:wasPressed("left") or input:wasPressed("right")) then
        local n=#(StartMenu.ENTRIES or {})
        if n>0 then
          local delta=input:wasPressed("left") and -5 or 5
          local cur=tonumber(StartMenu.cursor) or 1
          local target=math.max(1,math.min(n,cur+delta))
          StartMenu.cursor=target
          if StartMenu.clampScroll then StartMenu.clampScroll(delta,cur) end
        end
      elseif input:wasPressed("up") then StartMenu.move(-1)
      elseif input:wasPressed("down") then StartMenu.move(1)
      elseif input:wasPressed("a") then StartMenu.confirm()
      elseif input:wasPressed("b") or input:wasPressed("start") then
        if StartMenu.cancel then StartMenu.cancel() else StartMenu.close() end
      end
    end
    StartMenu.__kimGen3HorizontalExitConfirmV86=true
  end

  local function uiScaleFactor()
    if Style and Style.uiScale then
      local ww,wh=G.getDimensions(); return Style.uiScale(ww,wh)
    end
    local value=tostring(opt("gen3UiScale","100"))
    if value:lower()=="auto" then return 1 end
    local pct=tonumber(value) or 100
    pct=math.max(75,math.min(400,pct))
    return pct/100
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
    if Style and Style.color then return Style.color(c,alpha,foreground~=false) end
    c = c or {1,1,1,1}
    G.setColor(c[1] or 1, c[2] or 1, c[3] or 1, alpha == nil and (c[4] or 1) or alpha)
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

  -- Game3's shop camera can hand render.hud a temporarily shortened viewport.
  -- Display.fit() is the authoritative 240x160 Game3 presentation rect and
  -- does not change between BUY and SELL.  Use it for Bag/shop-sized windows
  -- so both halves of the mart workflow resolve against the same geometry.
  local function canonicalGame3Playfield(viewport)
    local okD, Display = pcall(require, "src.core.game3.display")
    if okD and Display and type(Display.fit)=="function" then
      local ok, _, ox, oy, pw, ph = pcall(Display.fit)
      if ok and tonumber(pw) and tonumber(ph) and pw>0 and ph>0 then
        return ox,oy,pw,ph
      end
    end
    return playfield(viewport)
  end

  local function card(x, y, w, h, fill, line, radius)
    radius = radius or math.max(4, math.min(w,h)*0.045)
    local pa = Style and Style.panelOpacity and Style.panelOpacity(1) or 1
    color(fill, math.min(1,(fill and fill[4] or 1)*pa), false)
    G.rectangle("fill", x, y, w, h, radius, radius)
    if line then
      color(line,nil,true)
      G.setLineWidth(math.max(1, math.min(w,h)*0.008))
      G.rectangle("line", x+0.5, y+0.5, math.max(0,w-1), math.max(0,h-1), radius, radius)
    end
  end

  local function background(x,y,w,h,c)
    local pa = Style and Style.panelOpacity and Style.panelOpacity(1) or 1
    color(c.surface,math.min(1,(c.surface[4] or 1)*pa),false)
    G.rectangle("fill",x,y,w,h)
    local bar = math.max(2, h*0.012)
    color(c.accent,nil,true)
    G.rectangle("fill",x,y,w,bar)
  end

  -- Gen 2 opens Party/Pack as a separate Modern UI window over the live game
  -- rather than replacing the entire playfield. Keep the same interaction
  -- model for Game3: the battle/field remains fully visible as the backdrop and
  -- Party/Bag owns a centered floating window until it closes.
  local function windowRect(viewport, kind)
    local sx,sy,sw,sh
    if kind=="bag" then
      sx,sy,sw,sh=canonicalGame3Playfield(viewport)
    else
      sx,sy,sw,sh=playfield(viewport)
    end
    local roomy = sw >= 720 and sh >= 460
    local fw
    local fh
    if kind=="start" then
      fw = roomy and 0.42 or 0.70
      fh = roomy and 0.72 or 0.80
    else
      fw = roomy and ((kind=="bag") and 0.78 or 0.76) or 0.94
      fh = roomy and 0.84 or 0.92
    end
    local userScale=uiScaleFactor()
    local w=math.min(sw*0.97,sw*fw*userScale)
    local h=math.min(sh*0.97,sh*fh*userScale)
    if Style and Style.layoutStyle and Style.layoutStyle()=="full" then
      w=sw*0.94; h=sh*0.92
    end
    local x=sx+(sw-w)*0.5
    if kind=="start" then
      local inset=math.max(0,math.min(50,tonumber(opt("gen3StartMenuInset","50")) or 50))/50
      local rightX=sx+sw-w-math.max(0,sw*0.015)
      local centerX=sx+(sw-w)*0.5
      x=rightX+(centerX-rightX)*inset
    end
    return x,sy+(sh-h)*0.5,w,h,sx,sy,sw,sh
  end

  -- Shared authoritative geometry for Gen 3 floating menus.  Other KIM
  -- presenters (notably Poké Mart BUY) use this exact function so BUY and
  -- SELL/Bag cannot drift apart even if Game3 hands them different render
  -- viewports/camera states.
  mod._kantoInMotionGen3WindowRect = function(viewport,kind)
    return windowRect(viewport,kind)
  end

  local function modernWindow(viewport,c,kind)
    local x,y,w,h,sx,sy,sw,sh=windowRect(viewport,kind)
    -- Do not paint a playfield-sized dim/scrim rectangle behind floating menus.
    -- On wide displays Game3's playfield is smaller than the output surface, so
    -- that scrim appeared as a large translucent box around Start/Party/Bag.
    local r=math.max(7,math.min(w,h)*0.018)
    if Style and Style.panel then
      Style.panel(x,y,w,h,c,1)
      color(c.accent,nil,true); G.rectangle("fill",x,y,w,math.max(2,h*0.012),r,r)
    else
      local shadow=c.frameShadow or {0.01,0.02,0.04,0.42}
      color(shadow,nil,false)
      G.rectangle("fill",x+math.max(3,w*0.006),y+math.max(4,h*0.009),w,h,r,r)
      background(x,y,w,h,c)
      color(c.frame,nil,true)
      G.setLineWidth(math.max(1,math.min(w,h)*0.0035))
      G.rectangle("line",x+0.5,y+0.5,math.max(0,w-1),math.max(0,h-1),r,r)
    end
    return x,y,w,h,sx,sy,sw,sh
  end

  local function summaryOpen()
    if not (okSummary and SummaryMenu and type(SummaryMenu.isOpen)=="function") then return false end
    local ok,v=pcall(SummaryMenu.isOpen)
    return ok and v == true
  end

  local function partyModernSupported()
    if not enabled("pokemon") or not PartyMenu.open or summaryOpen() then return false end
    local mode=tostring(PartyMenu.mode or "list")
    return mode ~= "summary" and mode ~= "forget" and mode ~= "stat_growth"
  end

  local BAG_MODERN_MODES={
    list=true, action=true, toss=true, toss_confirm=true, toss_done=true,
    message=true, deposit=true, deposit_done=true, flute_wait=true,
  }
  local function bagModernSupported()
    return enabled("menu") and BagMenu.open and BAG_MODERN_MODES[tostring(BagMenu.mode or "list")] == true
  end

  local function topLayerId()
    if not (okStack and Game3Stack and type(Game3Stack._layers)=="table") then return nil end
    local layer=Game3Stack._layers[#Game3Stack._layers]
    return layer and layer.id or nil
  end

  local function startModernSupported()
    if not enabled("menu") or not (okStart and type(StartMenu)=="table" and StartMenu.open) then return false end
    local top=topLayerId()
    return top==nil or top=="start"
  end

  -- Game3's modal stack marks Party (and field Bag) as fullscreen/opaque.  For
  -- Modern UI we want the Gen 2 behavior instead: leave the live layer below
  -- drawable and let KIM's floating window provide the visual ownership.
  local function setFloatingLayer(id,on)
    if not (okStack and Game3Stack and type(Game3Stack._layers)=="table") then return end
    for i=#Game3Stack._layers,1,-1 do
      local layer=Game3Stack._layers[i]
      if layer and layer.id==id then
        if on then
          if layer._kimGen3WindowOriginal==nil then
            layer._kimGen3WindowOriginal={
              hideBelow=layer.hideBelow, drawUnder=layer.drawUnder, fullscreen=layer.fullscreen,
            }
          end
          layer.hideBelow=false
          layer.drawUnder=true
          layer.fullscreen=false
        elseif layer._kimGen3WindowOriginal then
          local o=layer._kimGen3WindowOriginal
          layer.hideBelow=o.hideBelow
          layer.drawUnder=o.drawUnder
          layer.fullscreen=o.fullscreen
          layer._kimGen3WindowOriginal=nil
        end
        return
      end
    end
  end

  local function evolutionModernSupported()
    if not enabled("pokemon") or not (okEvolution and type(EvolutionScene)=="table") then return false end
    local open=EvolutionScene.open==true
    if type(EvolutionScene.isOpen)=="function" then
      local ok,v=pcall(EvolutionScene.isOpen)
      if ok then open=v==true end
    end
    return open and topLayerId()=="evolution_scene"
  end

  -- EvolutionScene is source-owned for timing, cries, cancellation, species
  -- mutation and move learning.  KIM changes only how that live state is
  -- presented and makes its Stack layer float over the field.
  if okEvolution and type(EvolutionScene)=="table"
      and not EvolutionScene.__kimGen3ModernEvolutionV142 then
    local upstreamEvolutionStart=EvolutionScene.start
    local upstreamEvolutionDraw=EvolutionScene.draw
    if type(upstreamEvolutionStart)=="function" then
      EvolutionScene.start=function(...)
        local out={upstreamEvolutionStart(...)}
        if out[1]~=false and enabled("pokemon") then
          setFloatingLayer("evolution_scene",true)
        end
        return (table.unpack or unpack)(out)
      end
    end
    if type(upstreamEvolutionDraw)=="function" then
      EvolutionScene.draw=function(...)
        if evolutionModernSupported()
            and (not Style or not Style.hideOriginal or Style.hideOriginal()) then
          return
        end
        return upstreamEvolutionDraw(...)
      end
    end
    EvolutionScene.__kimGen3ModernEvolutionV142=true
  end

  local function hpColor(hp,maxHp)
    local f=(tonumber(hp) or 0)/math.max(1,tonumber(maxHp) or 1)
    if f <= 0.20 then return {0.93,0.20,0.18,1} end
    if f <= 0.50 then return {0.96,0.70,0.16,1} end
    return {0.16,0.78,0.38,1}
  end

  local function hpBar(x,y,w,h,hp,maxHp,c)
    local f=math.max(0,math.min(1,(tonumber(hp) or 0)/math.max(1,tonumber(maxHp) or 1)))
    color(c.raised); G.rectangle("fill",x,y,w,h,h*0.5,h*0.5)
    color(hpColor(hp,maxHp)); G.rectangle("fill",x+1,y+1,math.max(0,(w-2)*f),math.max(1,h-2),h*0.4,h*0.4)
  end

  -- v77: party-list gender display only. This intentionally leaves the v67
  -- Pokédex and graphics pipeline untouched.
  local function genderSymbol(cx,cy,size,g,c)
    size=math.max(7,tonumber(size) or 10)
    color(c); G.setLineWidth(math.max(1,size*.12))
    local r=size*.22
    if g=="M" then
      local ox,oy=cx-size*.10,cy+size*.08
      G.circle("line",ox,oy,r)
      local ex,ey=cx+size*.34,cy-size*.34
      G.line(ox+r*.72,oy-r*.72,ex,ey)
      G.line(ex-size*.18,ey,ex,ey,ex,ey+size*.18)
    elseif g=="F" then
      local ox,oy=cx,cy-size*.12
      G.circle("line",ox,oy,r)
      local stemTop=oy+r
      local stemBottom=cy+size*.34
      G.line(ox,stemTop,ox,stemBottom)
      G.line(ox-size*.18,cy+size*.16,ox+size*.18,cy+size*.16)
    end
  end

  local function monGender(mon)
    if type(mon)~="table" then return nil end
    local g=mon.gender
    if g=="male" or g==0 then g="M" elseif g=="female" or g==1 then g="F" end
    if g=="M" or g=="F" then return g end
    if okSummaryData and SummaryData and type(SummaryData.gender)=="function" then
      local ok,v=pcall(SummaryData.gender,mon)
      if ok and (v=="M" or v=="F") then return v end
    end
    local resolver=mod._kantoInMotion1025DexGender
    if type(resolver)=="function" then
      local ok,v=pcall(resolver,mon)
      if ok and (v=="M" or v=="F") then return v end
    end
    return nil
  end

  local function monName(mon)
    if type(mon) ~= "table" then return "POKéMON" end
    if okPokemon and Pokemon and type(Pokemon.displayMonName) == "function" then
      local ok, v = pcall(Pokemon.displayMonName, mon)
      if ok and v and v ~= "" then return tostring(v) end
    end
    return tostring(mon.nickname or mon.name or mon.speciesName or mon.species or "POKéMON")
  end

  local function monIcon(mon)
    if not (okPokemon and Pokemon and type(Pokemon.monIcon) == "function" and type(mon) == "table") then return nil end
    local ok, entry = pcall(Pokemon.monIcon, mon)
    if ok and type(entry) == "table" and entry.image then return entry end
    return nil
  end

  -- The native Game3 party icon is a 32x32 GBA image.  It is fine on the
  -- source 240x160 surface, but v47 was drawing that same image directly in
  -- the final-resolution Modern UI and enlarging it for the selected preview,
  -- which made both icons visibly blocky.  Reuse KIM's shared final-window HD
  -- menu-icon provider instead.  The provider honors POKEMON ICONS, shiny
  -- state and National Dex mapping, and resolves the external asset cache.
  local hdIconCache, hdIconMissing = {}, {}
  local function hdMonIcon(game, mon)
    local provider = mod._kantoInMotionHdMenuIconForModernUi
    if type(provider) ~= "function" or type(mon) ~= "table" then return nil end
    local ok, path = pcall(provider, game, mon)
    if not ok or type(path) ~= "string" or path == "" or hdIconMissing[path] then return nil end
    if hdIconCache[path] ~= nil then return hdIconCache[path] or nil end
    local okImg, image = pcall(G.newImage, path)
    if not okImg or not image then
      hdIconCache[path] = false
      hdIconMissing[path] = true
      return nil
    end
    if type(image.setFilter) == "function" then pcall(image.setFilter, image, "linear", "linear") end
    hdIconCache[path] = image
    return image
  end

  local function drawMonIcon(game,mon,x,y,size,selected,maxScale)
    local bob=0
    if selected and love.timer and love.timer.getTime then bob=(math.floor(love.timer.getTime()*5)%2==1) and -2 or 0 end

    -- Preferred path: original-resolution HD Rescaled Icon art drawn directly
    -- at the final window resolution.  Never route it through Game3's 32x32
    -- canvas first.
    local hd=hdMonIcon(game,mon)
    if hd then
      local iw,ih=hd:getDimensions()
      iw,ih=math.max(1,iw or 1),math.max(1,ih or 1)
      -- The original HD Rescaled Icon files are only ~36-40 px square.
      -- They look clean in Party/Storage because those slots stay close to
      -- source size, but the naming header is much larger.  Do not blow the
      -- source art up to the full header card; cap enlargement there so the
      -- final-window image keeps its extra detail instead of looking like a
      -- magnified 32x32 GBA icon.
      local s=math.min(size/iw,size/ih,tonumber(maxScale) or math.huge)
      color({1,1,1,1})
      G.draw(hd,x+(size-iw*s)*0.5,y+(size-ih*s)*0.5+bob,0,s,s)
      return true
    end

    -- Fail open to Game3's native icon if the HD asset is unavailable or the
    -- POKEMON ICONS option is disabled.
    local e=monIcon(mon)
    if not e then return false end
    local img=e.image
    local quad=e.quads and (e.quads[0] or e.quads[1]) or nil
    local iw,ih
    if quad and quad.getViewport then
      local _,_,qw,qh=quad:getViewport(); iw,ih=qw,qh
    else
      iw,ih=img:getDimensions()
      if (e.frames or 1)>1 then ih=e.h or math.floor(ih/(e.frames or 1)) end
    end
    iw,ih=math.max(1,iw or 32),math.max(1,ih or 32)
    local s=math.min(size/iw,size/ih,tonumber(maxScale) or math.huge)
    color({1,1,1,1})
    if quad then G.draw(img,quad,x+(size-iw*s)*0.5,y+(size-ih*s)*0.5+bob,0,s,s)
    else G.draw(img,x+(size-iw*s)*0.5,y+(size-ih*s)*0.5+bob,0,s,s) end
    return true
  end

  -- Game3 uses one shared naming modal for FR/LG and R/S/E.  Keep its input,
  -- cursor, page switching, deletion, callbacks and PC-transfer result flow
  -- source-owned, but expose a final-resolution Modern UI presentation instead
  -- of scaling the native 240x160 keyboard.  `st.pages` comes from the active
  -- ROM's extracted naming manifest; the fallback mirrors the engine defaults
  -- for installations where that manifest is unavailable.
  local GEN3_NAMING_FALLBACK_PAGES = {
    {
      id="UPPER",
      rows={
        {"A","B","C","D","E","F"," ","."},
        {"G","H","I","J","K","L"," ",","},
        {"M","N","O","P","Q","R","S"},
        {"T","U","V","W","X","Y","Z"},
      },
    },
    {
      id="LOWER",
      rows={
        {"a","b","c","d","e","f"," ","."},
        {"g","h","i","j","k","l"," ",","},
        {"m","n","o","p","q","r","s"},
        {"t","u","v","w","x","y","z"},
      },
    },
    {
      id="OTHERS",
      rows={
        {"0","1","2","3","4"},
        {"5","6","7","8","9"},
        {"!","?","♂","♀","/","-"},
        {"…","“","”","‘","'"},
      },
    },
  }

  local function namingState()
    if not (okNaming and type(Naming)=="table") then return nil end
    local open=Naming.openFlag==true
    if type(Naming.isOpen)=="function" then
      local ok,value=pcall(Naming.isOpen)
      if ok then open=value==true end
    end
    return open and type(Naming._state)=="table" and Naming._state or nil
  end

  local function namingModernSupported()
    return enabled("menu") and namingState()~=nil
  end

  local function namingPages(st)
    local pages=type(st) == "table" and st.pages or nil
    if type(pages)~="table" or #pages==0 then pages=GEN3_NAMING_FALLBACK_PAGES end
    return pages
  end

  local function namingDisplayPage(st)
    local pages=namingPages(st)
    local index=math.max(1,math.min(#pages,tonumber(st.page) or 1))
    -- Native Game3 swaps the keyboard over 128 ticks.  Flip the Modern page at
    -- the visual midpoint while the original state machine continues timing.
    if st.swapT~=nil and st.swapTo~=nil and (tonumber(st.swapT) or 0)>=64 then
      index=math.max(1,math.min(#pages,tonumber(st.swapTo) or index))
    end
    return pages,index,pages[index] or pages[1]
  end

  local function utf8Chars(value)
    local out={}
    for ch in tostring(value or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
      out[#out+1]=ch
    end
    return out
  end

  local function namingPageButtonLabel(pages,index)
    if #pages==0 then return "PAGE" end
    local nextPage=pages[index%#pages+1] or {}
    local id=tostring(nextPage.id or "PAGE"):upper()
    if id=="LOWER" then return "abc" end
    if id=="UPPER" then return "ABC" end
    if id=="OTHERS" then return "123" end
    return id
  end

  local function drawMonPreview(game,mon,x,y,w,h)
    -- Large selected-Pokemon preview: use KIM's full animated HD battler art,
    -- not the HD menu icon used by the party rows.
    local provider=mod._kantoInMotionGen3HdAnimatedPreviewDraw
    if type(provider)=="function" and type(mon)=="table" then
      local ok,drawn=pcall(provider,mon,x,y,w,h)
      if ok and drawn then return true end
    end

    -- Fail open to the HD/native menu-icon path when a species has no KIM HD
    -- battler record (for example an unsupported special form).
    local size=math.min(w,h)
    return drawMonIcon(game,mon,x+(w-size)*0.5,y+(h-size)*0.5,size,true)
  end

  -- Game3 Party uses global OAM sprites for its Pokeball/mon/status/item
  -- decorations. Suppressing PartyMenu.draw() alone does not hide those
  -- objects because the engine flushes OAM separately after menu rendering.
  -- Hide only PartyMenu-owned sprite ids while KIM owns the floating party
  -- window, then rebuild the native sprites if ownership is released.
  local partyOamSuppressed = false
  local function suppressPartyOam(on)
    if not (okOam and Oam and type(Oam.setInvisible) == "function") then return end
    if on then
      local slots = PartyMenu._oam
      if type(slots) == "table" then
        for _, slot in pairs(slots) do
          if type(slot) == "table" then
            for _, key in ipairs({ "mon", "ball", "status", "item" }) do
              local id = slot[key]
              if id ~= nil then pcall(Oam.setInvisible, id, true) end
            end
          end
        end
      end
      if PartyMenu._summaryIcon ~= nil then
        pcall(Oam.setInvisible, PartyMenu._summaryIcon, true)
      end
      partyOamSuppressed = true
      return
    end

    if partyOamSuppressed then
      partyOamSuppressed = false
      -- Rebuild instead of blindly forcing every sprite visible: native Party
      -- decides which objects should actually be hidden for the current mode.
      if PartyMenu.open and type(PartyMenu.reloadSprites) == "function" then
        pcall(PartyMenu.reloadSprites)
      end
    end
  end

  -- Suppress only the native Party/Bag pixels while KIM has a modeled
  -- floating presenter. State, input, animations, callbacks and battle item
  -- routing remain 100% source-owned. Unsupported child modes fall through to
  -- the native renderer instead of being hidden.
  if not PartyMenu.__kimGen3ModernWindowV51 then
    local upstreamPartyDraw=PartyMenu.draw
    local upstreamPartyShow=PartyMenu.show
    if type(upstreamPartyDraw)=="function" then
      PartyMenu.draw=function(...)
        -- Summary is a child of Party in Game3. When the Modern Summary owns
        -- presentation, keep the parent Party pixels/OAM hidden as well so the
        -- live game remains the clean backdrop instead of exposing the native
        -- GBA Party screen underneath the floating Summary window.
        if enabled("pokemon") and (not Style or not Style.hideOriginal or Style.hideOriginal()) and (partyModernSupported() or summaryOpen() or evolutionModernSupported()) then
          suppressPartyOam(true)
          return
        end
        suppressPartyOam(false)
        return upstreamPartyDraw(...)
      end
    end
    if type(upstreamPartyShow)=="function" then
      PartyMenu.show=function(...)
        local out={upstreamPartyShow(...)}
        if enabled("pokemon") then
          setFloatingLayer("party",true)
          if partyModernSupported() then suppressPartyOam(true) end
        end
        return unpack(out)
      end
    end
    PartyMenu.__kimGen3ModernWindowV51=true
  end

  if okStart and type(StartMenu)=="table" and not StartMenu.__kimGen3ModernWindowV64 then
    local upstreamStartDraw=StartMenu.draw
    local upstreamStartShow=StartMenu.show
    if type(upstreamStartDraw)=="function" then
      StartMenu.draw=function(...)
        -- Keep the native Start-menu pixels suppressed even while a child
        -- screen is on top. The Start layer stays transparent so Party/Bag/
        -- Summary can reveal the live field instead of the old GBA menu.
        if enabled("menu") and (not Style or not Style.hideOriginal or Style.hideOriginal()) and StartMenu.open then return end
        return upstreamStartDraw(...)
      end
    end
    if type(upstreamStartShow)=="function" then
      StartMenu.show=function(...)
        local out={upstreamStartShow(...)}
        if enabled("menu") then setFloatingLayer("start",true) end
        return unpack(out)
      end
    end
    StartMenu.__kimGen3ModernWindowV64=true
  end

  if not BagMenu.__kimGen3ModernWindowV51 then
    local upstreamBagDraw=BagMenu.draw
    local upstreamBagShow=BagMenu.show
    if type(upstreamBagDraw)=="function" then
      BagMenu.draw=function(...)
        if enabled("menu") and (not Style or not Style.hideOriginal or Style.hideOriginal()) and (bagModernSupported() or evolutionModernSupported()) then return end
        return upstreamBagDraw(...)
      end
    end
    if type(upstreamBagShow)=="function" then
      BagMenu.show=function(...)
        local out={upstreamBagShow(...)}
        if enabled("menu") then setFloatingLayer("bag",true) end
        return unpack(out)
      end
    end
    BagMenu.__kimGen3ModernWindowV51=true
  end

  -- Emerald routes BAG drawing through its RSE skin instead of BagMenu.draw.
  -- v50 only suppressed the base module, so the Emerald skin continued to
  -- paint the vanilla bag behind KIM's floating window. Keep the skin's
  -- input/state adapter intact and suppress only its draw method.
  if okRseBag and type(RseBag)=="table" and not RseBag.__kimGen3ModernWindowV51 then
    local upstreamRseBagDraw=RseBag.draw
    if type(upstreamRseBagDraw)=="function" then
      RseBag.draw=function(...)
        if enabled("menu") and (not Style or not Style.hideOriginal or Style.hideOriginal()) and (bagModernSupported() or evolutionModernSupported()) then return end
        return upstreamRseBagDraw(...)
      end
    end
    RseBag.__kimGen3ModernWindowV51=true
  end

  local function plainRomText(key,vars)
    if okRomText and RomText and type(RomText.plain)=="function" then
      local ok,v=pcall(RomText.plain,key,vars and { stringVars=vars } or nil)
      if ok and v and v~="" then return tostring(v) end
    end
    return tostring(key or "")
  end

  local function startExtraText()
    local d=StartMenu._data
    local ctx=StartMenu._ctx
    if not (d and type(d.extraWindow)=="function" and ctx) then return nil end
    local ok,ex=pcall(d.extraWindow,StartMenu._kind,ctx)
    if not (ok and type(ex)=="table" and ex.key) then return nil end
    local value=plainRomText(ex.key,ex.vars)
    value=value:gsub("\n$","")
    return value~="" and value or nil
  end

  local function drawStart(viewport,c)
    if not startModernSupported() then return false end
    setFloatingLayer("start",true)

    local x,y,w,h=modernWindow(viewport,c,"start")
    local s=math.min(w/150,h/120)
    local pad=math.max(7*s,w*0.045)
    local header=math.max(22*s,h*0.16)
    local footer=math.max(17*s,h*0.13)
    local titleF=fontFor(10.5*s)
    local bodyF=fontFor(8.0*s)
    local smallF=fontFor(6.1*s)

    local session=StartMenu._session or {}
    local player=tostring(session.name or session.playerName or "PLAYER")
    text("MENU",titleF,x+pad,y+pad*0.55,w*0.40,"left",c.text)
    text(player:upper(),smallF,x+w*0.42,y+pad*0.82,w*0.50-pad,"right",c.muted)

    local extra=startExtraText()
    local cy=y+header
    local fy=y+h-footer
    if extra then
      local eh=math.max(smallF:getHeight()*2.2,18*s)
      card(x+pad,cy,w-pad*2,eh,c.raised,c.divider,4*s)
      text(extra,smallF,x+pad*1.5,cy+(eh-smallF:getHeight()*2)*0.5,w-pad*3,"left",c.text)
      cy=cy+eh+pad*0.55
    end

    local entries=StartMenu.ENTRIES or {}
    local d=StartMenu._data
    local maxVisible=tonumber(d and d.maxVisible) or tonumber(StartMenu.MAX_VISIBLE) or 8
    local visible=math.min(#entries,maxVisible)
    local scroll=math.max(0,tonumber(StartMenu._scrollOffset) or 0)
    local listH=math.max(1,fy-cy-pad*0.25)
    local gap=math.max(1.25*s,listH*0.014)
    -- The Pokédex adds an eighth normal entry in Emerald.  Do not enforce a
    -- minimum row height here: that pushed EXIT through the footer once all
    -- entries were present.  Fit every live source entry inside the list and
    -- reduce only the row font when space is tight.
    local rowH=math.max(1,(listH-gap*math.max(0,visible-1))/math.max(1,visible))
    rowH=math.min(18*s,rowH)
    local rowFont=bodyF
    if rowH < bodyF:getHeight()+4*s then
      rowFont=fontFor(math.max(5.2*s,rowH*0.48))
    end

    for r=1,visible do
      local i=scroll+r
      local entry=entries[i]
      if not entry then break end
      local ry=cy+(r-1)*(rowH+gap)
      local selected=(not StartMenu._confirmExit and i==(tonumber(StartMenu.cursor) or 1))
      card(x+pad,ry,w-pad*2,rowH,selected and c.selected or c.raised,selected and c.accent or c.divider,4*s)
      text(tostring(entry.label or entry.id or ""):upper(),rowFont,x+pad*1.65,ry+(rowH-rowFont:getHeight())*0.5,w-pad*3.3,"left",selected and c.text or c.muted)
    end

    if #entries>visible and not StartMenu._confirmExit then
      local markerW=math.max(3*s,w*0.012)
      local trackY=cy
      local trackH=math.max(1,math.min(listH,visible*(rowH+gap)-gap))
      -- Keep the scrollbar in the panel's right gutter instead of laying it
      -- over the row cards.  The old x+w-pad-markerW placement shared the
      -- same right edge as the selectable rows, so Glass themes made the
      -- overlap especially obvious.
      local markerX=x+w-pad*0.38-markerW
      color(c.divider,0.55); G.rectangle("fill",markerX,trackY,markerW,trackH,markerW*0.5,markerW*0.5)
      local thumbH=math.max(8*s,trackH*(visible/math.max(1,#entries)))
      local denom=math.max(1,#entries-visible)
      local thumbY=trackY+(trackH-thumbH)*(scroll/denom)
      color(c.accent); G.rectangle("fill",markerX,thumbY,markerW,thumbH,markerW*0.5,markerW*0.5)
    end

    card(x+pad,fy+pad*0.15,w-pad*2,footer-pad*0.45,c.raised,c.divider,4*s)
    text("A  SELECT     B  BACK",smallF,x+pad*1.55,fy+(footer-smallF:getHeight())*0.5,w-pad*3.1,"center",c.muted)

    if StartMenu._confirmExit then
      local ow=math.min(w*0.82,120*s)
      local oh=math.min(h*0.44,62*s)
      local ox=x+(w-ow)*0.5
      local oy=y+(h-oh)*0.5
      card(ox,oy,ow,oh,c.surface,c.frame,6*s)
      text("RETURN TO MAIN MENU?",bodyF,ox+pad,oy+pad,ow-pad*2,"center",c.text)
      local bw=(ow-pad*3)*0.5
      local bh=math.max(15*s,bodyF:getHeight()+6*s)
      local by=oy+oh-bh-pad
      local ci=tonumber(StartMenu._confirmCursor) or 2
      for i,v in ipairs({"YES","NO"}) do
        local bx=ox+pad+(i-1)*(bw+pad)
        card(bx,by,bw,bh,i==ci and c.selected or c.raised,i==ci and c.accent or c.divider,4*s)
        text(v,bodyF,bx,by+(bh-bodyF:getHeight())*0.5,bw,"center",c.text)
      end
    end
    return true
  end

  local function partyPrompt(mode)
    if mode=="switch" then return "Move to where?" end
    if mode=="use" then return "Use on which POKéMON?" end
    if mode=="give" then return "Give to which POKéMON?" end
    if mode=="move_tutor" then return "Teach which POKéMON?" end
    if mode=="battle_faint" then return "Choose a POKéMON to send out." end
    if mode=="battle_switch" then return "Choose a POKéMON." end
    if mode=="choose_multi" then return "Choose POKéMON." end
    return "Choose a POKéMON."
  end

  local function drawParty(game,viewport,c)
    if not partyModernSupported() then return false end
    setFloatingLayer("party",true)

    local x,y,w,h=modernWindow(viewport,c,"party")
    local s=math.min(w/240,h/160)
    local pad=math.max(8*s,w*0.018)
    local header=math.max(22*s,h*0.135)
    local footer=math.max(20*s,h*0.13)
    local titleF=fontFor(11*s)
    local bodyF=fontFor(8.1*s)
    local smallF=fontFor(6.2*s)
    local party=PartyMenu._party or {}
    local count=0; for i=1,6 do if party[i] then count=count+1 end end

    text("POKéMON",titleF,x+pad,y+pad*0.6,w*0.45,"left",c.text)
    text(string.format("%d / 6",count),smallF,x+w*0.72,y+pad*0.9,w*0.22,"right",c.muted)

    local cy=y+header
    local ch=h-header-footer
    local listW=w*0.58
    local detailX=x+listW
    color(c.divider,0.65); G.rectangle("fill",detailX,cy,math.max(1,s),ch)
    local rowH=ch/6
    local cursor=tonumber(PartyMenu.cursor) or 1
    local switchFrom=tonumber(PartyMenu.switchFrom)

    for i=1,6 do
      local mon=party[i]
      local ry=cy+(i-1)*rowH
      if mon then
        local selected=(cursor==i)
        local marked=(switchFrom==i)
        if selected or marked then
          color(selected and c.selected or c.raised,0.98)
          G.rectangle("fill",x+pad*0.45,ry+rowH*0.06,listW-pad*0.8,rowH*0.88,math.max(3,s*2),math.max(3,s*2))
          if selected then color(c.accent); G.rectangle("fill",x+pad*0.45,ry+rowH*0.06,math.max(2,s*1.4),rowH*0.88) end
        end
        local iconSize=math.min(rowH*0.82,24*s)
        drawMonIcon(game,mon,x+pad,ry+(rowH-iconSize)*0.5,iconSize,selected)
        local tx=x+pad+iconSize+5*s
        local name=fit(monName(mon),bodyF,listW-(tx-x)-pad*1.1)
        text(name,bodyF,tx,ry+rowH*0.12,listW-(tx-x)-pad,"left",c.text)
        local hp=tonumber(mon.hp) or 0
        local maxHp=tonumber(mon.maxHp or mon.maxhp) or 1
        local lvl=tonumber(mon.level) or 0
        local levelText="Lv "..lvl
        local levelY=ry+rowH*0.53
        text(levelText,smallF,tx,levelY,listW*0.23,"left",c.muted)
        local g=monGender(mon)
        if g then
          local symbolSize=smallF:getHeight()*.72
          local gc=(g=="M") and {0.28,0.66,1,1} or {1,0.40,0.66,1}
          local gx=tx+smallF:getWidth(levelText)+3*s+symbolSize*.36
          genderSymbol(gx,levelY+smallF:getHeight()*.50,symbolSize,g,gc)
        end
        text(string.format("%d/%d",hp,maxHp),smallF,x+listW-pad-listW*0.29,levelY,listW*0.26,"right",c.text)
        hpBar(tx,ry+rowH*0.82,listW-(tx-x)-pad,math.max(3,s*2.1),hp,maxHp,c)
      end
    end

    local selected=(cursor>=1 and cursor<=6) and party[cursor] or nil
    local dx=detailX+pad
    local dw=w-listW-pad*2
    if selected then
      local previewSize=math.min(dw*0.58,ch*0.34)
      drawMonPreview(game,selected,dx+(dw-previewSize)*0.5,cy+pad*0.5,previewSize,previewSize)
      local dy=cy+pad+previewSize
      text(fit(monName(selected),bodyF,dw),bodyF,dx,dy,dw,"center",c.text)
      local levelText="Lv "..tostring(tonumber(selected.level) or 0)
      local gy=dy+bodyF:getHeight()+2*s
      local g=monGender(selected)
      if g then
        local symbolSize=smallF:getHeight()*.72
        local gap=3*s
        local symbolW=symbolSize*.72
        local total=smallF:getWidth(levelText)+gap+symbolW
        local gx=dx+(dw-total)*.5
        text(levelText,smallF,gx,gy,nil,nil,c.muted)
        local gc=(g=="M") and {0.28,0.66,1,1} or {1,0.40,0.66,1}
        genderSymbol(gx+smallF:getWidth(levelText)+gap+symbolW*.5,gy+smallF:getHeight()*.50,symbolSize,g,gc)
      else
        text(levelText,smallF,dx,gy,dw,"center",c.muted)
      end
      local hp=tonumber(selected.hp) or 0
      local maxHp=tonumber(selected.maxHp or selected.maxhp) or 1
      hpBar(dx,dy+bodyF:getHeight()+smallF:getHeight()+6*s,dw,math.max(4,s*2.6),hp,maxHp,c)
      text(string.format("HP %d / %d",hp,maxHp),smallF,dx,dy+bodyF:getHeight()+smallF:getHeight()+10*s,dw,"center",c.text)
      local desc=type(PartyMenu.slotDescription)=="function" and PartyMenu.slotDescription(cursor) or nil
      if desc and desc~="" then text(fit(desc,smallF,dw),smallF,dx,cy+ch-smallF:getHeight()-pad*0.35,dw,"center",c.accent) end
    else
      text("CANCEL",bodyF,dx,cy+ch*0.44,dw,"center",cursor==7 and c.accent or c.muted)
    end

    local fy=y+h-footer
    color(c.divider,0.55); G.rectangle("fill",x,fy,w,math.max(1,s))
    text(partyPrompt(PartyMenu.mode),smallF,x+pad,fy+(footer-smallF:getHeight())*0.5,w*0.60,"left",c.muted)
    if cursor==7 then
      card(x+w-70*s,fy+4*s,58*s,footer-8*s,c.selected,c.accent,4*s)
      text("CANCEL",bodyF,x+w-70*s,fy+(footer-bodyF:getHeight())*0.5,58*s,"center",c.text)
    else
      text("CANCEL",smallF,x+w-70*s,fy+(footer-smallF:getHeight())*0.5,58*s,"center",c.muted)
    end

    if PartyMenu.mode=="oak" then
      local fx=PartyMenu._oakFx or {}
      local level=math.max(0,math.min(6,tonumber(fx.y) or 0))
      if level>0 then
        G.setColor(0,0,0,0.44*(level/6))
        G.rectangle("fill",x,y,w,h)
      end
      if fx.phase~="darken" and fx.phase~="normal" then
        local msg=PartyMenu._oakWrapped
        if not msg or msg=="" then
          local pages=PartyMenu._oakPages or {}
          msg=pages[tonumber(PartyMenu._oakPage) or 1]
        end
        msg=tostring(msg or "")
        if msg~="" then
          local mh=math.max(footer*2.15,bodyF:getHeight()*3.5)
          local mx=x+pad
          local my=y+h-mh-pad
          card(mx,my,w-pad*2,mh,c.raised,c.frame,5*s)
          text(msg,bodyF,mx+pad*0.85,my+pad*0.55,w-pad*3.7,"left",c.text)
          text("A / B",smallF,mx+w-pad*3.2,my+mh-smallF:getHeight()-pad*0.45,pad*1.6,"right",c.accent)
        end
      end
    elseif PartyMenu.mode=="action" or PartyMenu.mode=="item_action" then
      local acts=PartyMenu.mode=="action" and (PartyMenu.ACTIONS or {}) or (PartyMenu.ITEM_ACTIONS or {})
      local ai=PartyMenu.mode=="action" and (tonumber(PartyMenu.actionCursor) or 1) or (tonumber(PartyMenu.itemActionCursor) or 1)
      local rw=math.min(w*0.34,92*s)
      local rh=math.max(13*s,bodyF:getHeight()+5*s)
      local ph=#acts*rh+pad
      local px=x+w-rw-pad
      local py=math.max(y+header,fy-ph-pad*0.25)
      card(px,py,rw,ph,c.surface,c.frame,5*s)
      for i,a in ipairs(acts) do
        local yy=py+pad*0.5+(i-1)*rh
        if i==ai then card(px+4*s,yy,rw-8*s,rh-1*s,c.selected,c.accent,3*s) end
        text(tostring(a):gsub("_"," "),bodyF,px+8*s,yy+(rh-bodyF:getHeight())*0.5,rw-16*s,"left",i==ai and c.text or c.muted)
      end
    elseif PartyMenu.mode=="message" and PartyMenu._messageText then
      local mh=footer*1.8
      card(x+pad,y+h-mh-pad,w-2*pad,mh,c.raised,c.frame,5*s)
      text(tostring(PartyMenu._messageText),bodyF,x+pad*1.7,y+h-mh,w-pad*3.4,"left",c.text)
    elseif PartyMenu.mode=="yesno" then
      local prompt=tostring(PartyMenu._yesNoPrompt or "")
      local mh=footer*1.8
      card(x+pad,y+h-mh-pad,w-2*pad,mh,c.raised,c.frame,5*s)
      text(prompt,bodyF,x+pad*1.7,y+h-mh,w*0.62,"left",c.text)
      local opts={"YES","NO"}; local ci=tonumber(PartyMenu._yesNoCursor) or 1
      for i,v in ipairs(opts) do
        local bw=34*s; local bh=14*s; local bx=x+w-pad-(3-i)*(bw+3*s); local by=y+h-mh+4*s
        card(bx,by,bw,bh,i==ci and c.selected or c.surface,i==ci and c.accent or c.divider,3*s)
        text(v,smallF,bx,by+(bh-smallF:getHeight())*0.5,bw,"center",c.text)
      end
    end
    return true
  end

  local function statGrowthOpen()
    if not (okStatGrowth and StatGrowth and type(StatGrowth.isOpen)=="function") then return false end
    local ok,v=pcall(StatGrowth.isOpen)
    return ok and v==true
  end

  local function drawStatGrowth(viewport,c)
    if not statGrowthOpen() then return false end
    local sx,sy,sw,sh=playfield(viewport)
    local userScale=uiScaleFactor()
    local w=math.min(sw*0.46*userScale,sw*0.62)
    local h=math.min(sh*0.66*userScale,sh*0.82)
    w=math.max(w,sw*0.30)
    h=math.max(h,sh*0.48)
    local x=sx+sw-w-sw*0.035
    local y=sy+sh*0.035
    local r=math.max(7,math.min(w,h)*0.022)
    color(c.frameShadow or FALLBACK.frameShadow)
    G.rectangle("fill",x+math.max(3,w*0.008),y+math.max(4,h*0.012),w,h,r,r)
    background(x,y,w,h,c)
    color(c.frame); G.setLineWidth(math.max(1,math.min(w,h)*0.004))
    G.rectangle("line",x+0.5,y+0.5,w-1,h-1,r,r)

    local sc=math.min(w/128,h/112)
    local pad=math.max(7*sc,w*0.045)
    local titleF=fontFor(10.5*sc)
    local bodyF=fontFor(7.5*sc)
    local smallF=fontFor(5.7*sc)
    local mon=StatGrowth._mon
    local name=monName(mon)
    local page=tonumber(StatGrowth._page) or 1
    text("LEVEL UP",titleF,x+pad,y+pad*0.55,w*0.52,"left",c.text)
    text(fit(name,smallF,w*0.40),smallF,x+w*0.54,y+pad*0.90,w*0.40-pad,"right",c.accent)
    text(page==1 and "STAT INCREASE" or "NEW STATS",smallF,x+pad,y+pad+titleF:getHeight()+2*sc,w-pad*2,"left",c.muted)

    local oldS=StatGrowth._oldStats or {}
    local newS=StatGrowth._newStats or {}
    local oldList={oldS.maxHp or 0,oldS.atk or 0,oldS.def or 0,oldS.spa or 0,oldS.spd or 0,oldS.spe or 0}
    local newList={newS.maxHp or 0,newS.atk or 0,newS.def or 0,newS.spa or 0,newS.spd or 0,newS.spe or 0}
    local labels={"MAX HP","ATTACK","DEFENSE","SP. ATK","SP. DEF","SPEED"}
    local top=y+pad*2+titleF:getHeight()+smallF:getHeight()+2*sc
    local footerH=math.max(18*sc,h*0.14)
    local rowH=(y+h-footerH-top)/6
    for i=1,6 do
      local ry=top+(i-1)*rowH
      if i%2==0 then color(c.raised,0.55); G.rectangle("fill",x+pad*0.75,ry,w-pad*1.5,rowH) end
      text(labels[i],bodyF,x+pad,ry+(rowH-bodyF:getHeight())*0.5,w*0.58,"left",c.text)
      local value
      if page==1 then
        local diff=(tonumber(newList[i]) or 0)-(tonumber(oldList[i]) or 0)
        value=string.format("%+d",diff)
      else
        value=tostring(tonumber(newList[i]) or 0)
      end
      text(value,bodyF,x+w*0.62,ry+(rowH-bodyF:getHeight())*0.5,w*0.28,"right",page==1 and c.accent or c.text)
    end
    local fy=y+h-footerH
    color(c.divider,0.55); G.rectangle("fill",x,fy,w,math.max(1,sc))
    text(page==1 and "A / B  NEXT" or "A / B  CONTINUE",smallF,x+pad,fy+(footerH-smallF:getHeight())*0.5,w-pad*2,"center",c.muted)
    return true
  end

  -- Naming is a full-screen Game3 Stack modal, not a Party/Bag child.  Hide
  -- only its stock pixels while Modern UI owns presentation. This also makes
  -- the final-resolution keyboard navigate like it is drawn: LEFT/RIGHT stay
  -- within a keyboard row, DOWN from the last keyboard row enters the bottom
  -- ABC/DELETE/OK action bar, LEFT/RIGHT moves across that action bar, and UP
  -- returns to the keyboard.  A/B/SELECT/START and all callbacks remain owned
  -- by Game3's original Naming.handleInput implementation.
  if okNaming and type(Naming)=="table" and not Naming.__kimGen3ModernNamingV120 then
    local upstreamNamingDraw=Naming.draw
    local upstreamNamingInput=Naming.handleInput

    local function namingRowsForInput(st)
      local _,_,page=namingDisplayPage(st)
      local rows=type(page)=="table" and page.rows or nil
      return type(rows)=="table" and rows or {}
    end

    local function namingActionRow(rows,btn)
      local n=math.max(1,#rows)
      if btn<=1 then return 1 end
      if btn==2 then return math.min(2,n) end
      return n
    end

    local function namingActionTargetCol(rows,btn)
      local r=#rows
      local row=rows[r] or {}
      local n=math.max(1,#row)
      -- Center each of the three bottom actions over roughly one third of the
      -- bottom keyboard row so UP from the action bar lands where expected.
      return math.max(1,math.min(n,math.floor(((btn-.5)/3)*n+.5)))
    end

    local function namingSetAction(st,rows,btn,returnCol)
      btn=math.max(1,math.min(3,tonumber(btn) or 1))
      local r=namingActionRow(rows,btn)
      local row=rows[r] or {}
      st.btn=btn
      st.row=r
      st.col=#row+1 -- Game3's source convention for PAGE/BACK/OK focus.
      st.__kimNamingReturnCol=tonumber(returnCol) or namingActionTargetCol(rows,btn)
    end

    local function namingModernMove(st,dir)
      local rows=namingRowsForInput(st)
      if #rows==0 then return false end
      local r=math.max(1,math.min(#rows,tonumber(st.row) or 1))
      local row=rows[r] or {}
      local c=math.max(1,tonumber(st.col) or 1)
      local onAction=c>#row

      if onAction then
        local btn=math.max(1,math.min(3,tonumber(st.btn) or 1))
        if dir=="left" then
          btn=math.max(1,btn-1)
          namingSetAction(st,rows,btn,namingActionTargetCol(rows,btn))
        elseif dir=="right" then
          btn=math.min(3,btn+1)
          namingSetAction(st,rows,btn,namingActionTargetCol(rows,btn))
        elseif dir=="up" then
          local rr=#rows
          local bottom=rows[rr] or {}
          local cc=tonumber(st.__kimNamingReturnCol) or namingActionTargetCol(rows,btn)
          st.row=rr
          st.col=math.max(1,math.min(math.max(1,#bottom),cc))
        elseif dir=="down" then
          -- Already at the bottom-most control row; keep focus there.
        end
        return true
      end

      st.__kimNamingReturnCol=c
      if dir=="left" then
        local n=math.max(1,#row)
        st.col=c-1
        if st.col<1 then st.col=n end
      elseif dir=="right" then
        local n=math.max(1,#row)
        st.col=c+1
        if st.col>n then st.col=1 end
      elseif dir=="up" then
        local nr=r-1
        if nr<1 then nr=#rows end
        local nrow=rows[nr] or {}
        st.row=nr
        st.col=math.max(1,math.min(math.max(1,#nrow),c))
      elseif dir=="down" then
        if r>=#rows then
          local maxCols=1
          for _,rr in ipairs(rows) do if type(rr)=="table" then maxCols=math.max(maxCols,#rr) end end
          local btn=math.max(1,math.min(3,math.floor(((c-1)*3)/maxCols)+1))
          namingSetAction(st,rows,btn,c)
        else
          local nr=r+1
          local nrow=rows[nr] or {}
          st.row=nr
          st.col=math.max(1,math.min(math.max(1,#nrow),c))
        end
      end
      return true
    end

    if type(upstreamNamingInput)=="function" then
      Naming.handleInput=function(input,...)
        if namingModernSupported() then
          local st=namingState()
          if st and not st.finished and not st.pcPages and st.swapT==nil
              and not (st.rs and st.fullNameWait) and input and input.wasPressed then
            if input:wasPressed("left") then namingModernMove(st,"left"); return end
            if input:wasPressed("right") then namingModernMove(st,"right"); return end
            if input:wasPressed("up") then namingModernMove(st,"up"); return end
            if input:wasPressed("down") then namingModernMove(st,"down"); return end
          end
        end
        return upstreamNamingInput(input,...)
      end
    end

    if type(upstreamNamingDraw)=="function" then
      Naming.draw=function(...)
        if namingModernSupported()
            and (not Style or not Style.hideOriginal or Style.hideOriginal()) then
          return
        end
        return upstreamNamingDraw(...)
      end
    end
    Naming.__kimGen3ModernNamingV120=true
  end

  -- The battle EXP sequence owns this standalone native window; it does not
  -- go through PartyMenu.  Suppress only its pixels and leave its input/page/
  -- callback lifecycle fully source-owned.
  if okStatGrowth and StatGrowth and not StatGrowth.__kimGen3ModernV67 then
    local upstreamStatDraw=StatGrowth.draw
    if type(upstreamStatDraw)=="function" then
      StatGrowth.draw=function(...)
        if enabled() and statGrowthOpen() then return end
        return upstreamStatDraw(...)
      end
    end
    StatGrowth.__kimGen3ModernV67=true
  end

  local function pocketLabel(v)
    v=tostring(v or "ITEMS"):gsub("_"," ")
    if v=="POKE BALLS" then v="POKé BALLS" end
    if v=="TM HM" then v="TM / HM" end
    return v
  end

  local function drawBag(viewport,c)
    if not bagModernSupported() then return false end
    setFloatingLayer("bag",true)
    local x,y,w,h=modernWindow(viewport,c,"bag")
    local s=math.min(w/240,h/160)
    local pad=math.max(8*s,w*0.018)
    local header=math.max(25*s,h*0.16)
    local footer=math.max(31*s,h*0.20)
    local titleF=fontFor(11*s)
    local bodyF=fontFor(7.6*s)
    local smallF=fontFor(5.8*s)

    text("BAG",titleF,x+pad,y+pad*0.65,w*0.20,"left",c.text)
    local pockets=(okItems and ItemsData and ItemsData.BAG_POCKET_ORDER) or {}
    local pidx=tonumber(BagMenu.pocketIdx) or 1

    -- Pocket tabs are content-sized instead of five equal boxes.  Equal-width
    -- tabs clipped long labels (especially BERRY POUCH / KEY ITEMS) once UI or
    -- font scaling was raised.  Measure every full label first, then distribute
    -- spare width across the tabs.  If an extreme font/UI combination still
    -- cannot fit, shrink only the tab-label font just enough to preserve every
    -- pocket name; the rest of the Bag keeps the user's requested text scale.
    local tabLabels={}
    for i,p in ipairs(pockets) do tabLabels[i]=pocketLabel(p) end
    local tabCount=math.max(1,#tabLabels)
    local bagTitleRight=x+pad+titleF:getWidth("BAG")
    local tabsX=math.max(x+w*0.20,bagTitleRight+pad*1.15)
    local tabsRight=x+w-pad*0.55
    local tabsW=math.max(1,tabsRight-tabsX)
    local tabNominal=5.8*s
    local tabFont=smallF
    local function tabMetrics(font)
      local hp=math.max(3*s,font:getHeight()*0.34)
      local widths,total={},0
      for i,lab in ipairs(tabLabels) do
        widths[i]=font:getWidth(lab)+hp*2
        total=total+widths[i]
      end
      return widths,total,hp
    end
    local natural,totalNatural,tabPad=tabMetrics(tabFont)
    local tries=0
    while totalNatural>tabsW and tries<10 do
      local ratio=math.max(0.72,math.min(0.94,tabsW/totalNatural))
      tabNominal=tabNominal*ratio
      tabFont=fontFor(tabNominal)
      natural,totalNatural,tabPad=tabMetrics(tabFont)
      tries=tries+1
    end
    if totalNatural>tabsW then
      -- Last-resort gutter compression for the smallest window / largest text
      -- combinations; labels remain complete and centered.
      tabPad=math.max(1*s,(tabsW-totalNatural+tabPad*2*tabCount)/(2*tabCount))
      natural,totalNatural={},0
      for i,lab in ipairs(tabLabels) do
        natural[i]=tabFont:getWidth(lab)+tabPad*2
        totalNatural=totalNatural+natural[i]
      end
    end
    local extra=math.max(0,(tabsW-totalNatural)/tabCount)
    local cursorX=tabsX
    local tabTextH=tabFont:getHeight()
    local highlightV=math.max(2*s,tabTextH*0.22)
    local highlightH=math.min(header-pad*0.55,tabTextH+highlightV*2)
    local tabY=y+(header-highlightH)*0.5
    for i,lab in ipairs(tabLabels) do
      local segW=(natural[i] or tabsW/tabCount)+extra
      local textW=tabFont:getWidth(lab)
      local highlightW=math.min(segW-math.max(1,s),textW+tabPad*1.55)
      local hx=cursorX+(segW-highlightW)*0.5
      if i==pidx then
        card(hx,tabY,highlightW,highlightH,c.selected,c.accent,math.max(3*s,highlightH*0.16))
      end
      local ty=tabY+(highlightH-tabTextH)*0.5
      text(lab,tabFont,cursorX,ty,segW,"center",i==pidx and c.text or c.muted)
      cursorX=cursorX+segW
    end

    local cy=y+header
    local ch=h-header-footer
    local detailW=w*0.34
    local listX=x+detailW
    local listW=w-detailW-pad
    color(c.divider,0.65); G.rectangle("fill",listX,cy,math.max(1,s),ch)

    local rows=type(BagMenu.list)=="function" and BagMenu.list() or {}
    local scroll=math.max(0,tonumber(BagMenu.scroll) or 0)
    local cursor=math.max(1,tonumber(BagMenu.cursor) or 1)
    local visible=6
    local rowH=ch/visible
    for vr=1,visible do
      local idx=scroll+vr
      local r=rows[idx]
      local isClose=(idx==#rows+1)
      if r or isClose then
        local ry=cy+(vr-1)*rowH
        if idx==cursor then
          color(c.selected); G.rectangle("fill",listX+5*s,ry+rowH*0.08,listW-8*s,rowH*0.84,4*s,4*s)
          color(c.accent); G.rectangle("fill",listX+5*s,ry+rowH*0.08,math.max(2,s*1.4),rowH*0.84)
        end
        local name=isClose and "CLOSE BAG" or tostring(r.name or r.id or "ITEM")
        text(fit(name,bodyF,listW*0.67),bodyF,listX+12*s,ry+(rowH-bodyF:getHeight())*0.5,listW*0.67,"left",idx==cursor and c.text or c.muted)
        if r then text("× "..tostring(tonumber(r.qty) or 1),smallF,listX+listW*0.77,ry+(rowH-smallF:getHeight())*0.5,listW*0.18,"right",idx==cursor and c.text or c.muted) end
      end
    end

    local sel=(cursor<=#rows) and rows[cursor] or nil
    local dx=x+pad
    local dw=detailW-pad*2
    text(pocketLabel(type(BagMenu.currentPocket)=="function" and BagMenu.currentPocket() or "ITEMS"),bodyF,dx,cy+pad*0.6,dw,"left",c.accent)
    if sel then
      text(fit(sel.name or sel.id,bodyF,dw),bodyF,dx,cy+pad*0.6+bodyF:getHeight()+4*s,dw,"left",c.text)
      text("QTY  "..tostring(tonumber(sel.qty) or 1),smallF,dx,cy+pad*0.6+bodyF:getHeight()+smallF:getHeight()+7*s,dw,"left",c.muted)
      local desc=tostring(sel.description or "")
      text(desc,smallF,dx,cy+ch*0.49,dw,"left",c.muted)
    else
      text("CLOSE BAG",bodyF,dx,cy+ch*0.43,dw,"center",c.text)
    end

    local fy=y+h-footer
    color(c.divider,0.55); G.rectangle("fill",x,fy,w,math.max(1,s))
    local mode=tostring(BagMenu.mode or "list")
    local prompt="Choose an item."
    if mode=="action" and sel then prompt=tostring(sel.name or "ITEM").." is selected."
    elseif mode=="toss" then prompt="Toss out how many?"
    elseif mode=="toss_confirm" then prompt="Throw these away?"
    elseif mode=="message" then prompt=tostring(BagMenu.messageText or "") end
    text(prompt,smallF,x+pad,fy+5*s,w*0.62,"left",c.muted)

    if mode=="action" then
      local acts=BagMenu.ACTIONS or {}
      local ai=tonumber(BagMenu.actionCursor) or 1
      local rw=math.min(w*0.30,72*s)
      local rh=math.max(12*s,bodyF:getHeight()+4*s)
      local ph=#acts*rh+pad
      local px=x+w-rw-pad
      local py=math.max(cy,fy-ph-pad*0.25)
      card(px,py,rw,ph,c.surface,c.frame,5*s)
      for i,a in ipairs(acts) do
        local yy=py+pad*0.5+(i-1)*rh
        if i==ai then card(px+4*s,yy,rw-8*s,rh-1*s,c.selected,c.accent,3*s) end
        text(tostring(a):gsub("_"," "),bodyF,px+8*s,yy+(rh-bodyF:getHeight())*0.5,rw-16*s,"left",i==ai and c.text or c.muted)
      end
    elseif mode=="toss" and sel then
      local q=tonumber(BagMenu.tossQty) or 1
      text("× "..q,titleF,x+w*0.68,fy+4*s,w*0.25,"right",c.text)
    elseif mode=="toss_confirm" then
      local ci=tonumber(BagMenu.yesNoCursor) or 1
      for i,v in ipairs({"YES","NO"}) do
        local bw=34*s; local bh=14*s; local bx=x+w-pad-(3-i)*(bw+3*s); local by=fy+4*s
        card(bx,by,bw,bh,i==ci and c.selected or c.raised,i==ci and c.accent or c.divider,3*s)
        text(v,smallF,bx,by+(bh-smallF:getHeight())*0.5,bw,"center",c.text)
      end
    end
    return true
  end

  local function drawNaming(game,viewport,c)
    local st=namingState()
    if not st then return false end

    local sx,sy,sw,sh=playfield(viewport)
    local scale=math.min(sw/640,sh/360)*uiScaleFactor()
    scale=math.max(.55,scale)

    -- Naming is intentionally a fullscreen source modal.  Give it a themed
    -- Modern backdrop so suppressing the native 240x160 background never
    -- leaves black/undefined pixels when the Stack hides the field below it.
    color(c.surface,1,false)
    G.rectangle("fill",sx,sy,sw,sh)

    local desiredW=sw*.92*uiScaleFactor()
    local desiredH=sh*.92*uiScaleFactor()
    local w=math.min(sw*.97,desiredW)
    local h=math.min(sh*.97,desiredH)
    local x=sx+(sw-w)*.5
    local y=sy+(sh-h)*.5
    if Style and Style.panel then Style.panel(x,y,w,h,c,1)
    else card(x,y,w,h,c.surface,c.frame,math.max(6,8*scale)) end

    local pad=math.max(10,w*.022)
    local titleF=fontFor(math.max(13,16*scale))
    local bodyF=fontFor(math.max(11,13*scale))
    local keyF=fontFor(math.max(10,12*scale))
    local smallF=fontFor(math.max(9,9.5*scale))

    local headerH=math.max(78*scale,h*.24)
    local footerH=math.max(28*scale,h*.09)
    local actionH=math.max(38*scale,h*.12)
    local title=tostring(st.title or "POKéMON NAME")

    -- Header icon is shown for Pokémon naming templates.  HD menu art is used
    -- when available, with the same POKÉMON ICONS fallback policy as Party/PC.
    local isMon=st.template=="NICKNAME" or st.template=="CAUGHT_MON"
    local iconSize=isMon and math.min(headerH-pad*1.35,w*.12) or 0
    local iconX=x+pad
    local iconY=y+pad*.75
    if isMon and iconSize>8 then
      card(iconX,iconY,iconSize,iconSize,c.raised,c.divider,math.max(4,5*scale))
      drawMonIcon(game,{
        species=st.species,personality=st.personality,
        gender=st.monGender or st.gender,
      },iconX,iconY,iconSize,false,1.6)
    end

    local textX=x+pad+(isMon and iconSize+pad or 0)
    local textW=x+w-pad-textX
    text(fit(title,titleF,textW),titleF,textX,y+pad*.75,textW,"left",c.accent)

    local chars=utf8Chars(st.name)
    local maxLen=math.max(1,tonumber(st.maxLen) or 10)
    local slotTop=y+headerH-math.max(34*scale,h*.10)
    local slotH=math.max(25*scale,h*.075)
    local counter=tostring(#chars).." / "..tostring(maxLen)
    local counterW=smallF:getWidth(counter)+8*scale
    local slotsW=math.max(80,textW-counterW-pad*.5)
    local gap=math.max(2,2.4*scale)
    local slotW=(slotsW-gap*(maxLen-1))/maxLen
    if slotW<5 then gap=1; slotW=(slotsW-gap*(maxLen-1))/maxLen end
    for i=1,maxLen do
      local bx=textX+(i-1)*(slotW+gap)
      local active=i<=#chars
      color(active and c.selected or c.raised,active and .94 or .72,false)
      G.rectangle("fill",bx,slotTop,math.max(1,slotW),slotH,math.max(2,3*scale))
      local glyph=chars[i] or "_"
      local f=(slotW>=bodyF:getWidth("W")+3) and bodyF or smallF
      text(glyph,f,bx,slotTop+(slotH-f:getHeight())*.46,math.max(1,slotW),"center",
        active and c.text or c.muted)
    end
    text(counter,smallF,textX+slotsW+pad*.5,
      slotTop+(slotH-smallF:getHeight())*.48,counterW,"right",c.muted)

    local pages,pageIndex,page=namingDisplayPage(st)
    local rows=type(page) == "table" and page.rows or {}
    local maxCols=1
    for _,row in ipairs(rows) do if type(row)=="table" then maxCols=math.max(maxCols,#row) end end
    local kbTop=y+headerH+pad*.25
    local actionsY=y+h-footerH-actionH-pad*.35
    local kbBottom=actionsY-pad*.45
    local kbH=math.max(30,kbBottom-kbTop)
    local rowCount=math.max(1,#rows)
    local cellH=kbH/rowCount
    local cellW=(w-pad*2)/maxCols
    local selectedRow=math.max(1,tonumber(st.row) or 1)
    local selectedCol=math.max(1,tonumber(st.col) or 1)
    local currentRow=rows[selectedRow] or {}
    local onSide=selectedCol>#currentRow

    for r,row in ipairs(rows) do
      if type(row)=="table" then
        for col=1,maxCols do
          local ch=row[col]
          local bx=x+pad+(col-1)*cellW
          local by=kbTop+(r-1)*cellH
          local selected=not onSide and selectedRow==r and selectedCol==col
          if ch~=nil then
            color(selected and c.selected or c.raised,selected and .98 or .58,false)
            G.rectangle("fill",bx+2*scale,by+2*scale,
              math.max(1,cellW-4*scale),math.max(1,cellH-4*scale),math.max(3,4*scale))
            if tostring(ch)~=" " then
              local glyph=tostring(ch)
              if glyph=="♂" or glyph=="♀" then
                -- The configurable Modern UI fonts do not all contain the GBA
                -- male/female glyphs.  Draw them procedurally so the symbol
                -- page never shows missing-glyph boxes after ! / ?.
                local gc=selected and c.text or c.muted
                local gs=math.min(cellH*.42,keyF:getHeight()*.92)
                genderSymbol(bx+cellW*.5,by+cellH*.51,gs,glyph=="♂" and "M" or "F",gc)
              else
                text(glyph,keyF,bx,
                  by+(cellH-keyF:getHeight())*.46,cellW,"center",
                  selected and c.text or c.muted)
              end
            end
          end
        end
      end
    end

    local actions={namingPageButtonLabel(pages,pageIndex),"DELETE","OK"}
    local actionW=(w-pad*2)/3
    local selectedAction=math.max(1,math.min(3,tonumber(st.btn) or 1))
    for i,label in ipairs(actions) do
      local bx=x+pad+(i-1)*actionW
      local selected=onSide and selectedAction==i
      color(selected and c.selected or c.raised,selected and .98 or .78,false)
      G.rectangle("fill",bx+3*scale,actionsY,math.max(1,actionW-6*scale),actionH,
        math.max(4,5*scale))
      if selected then
        color(c.accent,nil,true)
        G.setLineWidth(math.max(1,1.5*scale))
        G.rectangle("line",bx+3*scale,actionsY,math.max(1,actionW-6*scale),actionH,
          math.max(4,5*scale))
      end
      text(label,bodyF,bx,actionsY+(actionH-bodyF:getHeight())*.46,
        actionW,"center",selected and c.text or c.muted)
    end

    local footerY=y+h-footerH
    color(c.divider,.75,false)
    G.rectangle("fill",x+pad,footerY,w-pad*2,math.max(1,scale))
    text("D-PAD  move   A  choose   B  delete   SELECT  page   START  done",
      smallF,x+pad,footerY+(footerH-smallF:getHeight())*.5,w-pad*2,"center",c.muted)

    -- Caught Pokémon sent to the PC can produce one or more source-owned
    -- transfer result pages before Naming closes.  Keep those pages visible in
    -- a Modern modal while the original A-to-advance lifecycle remains intact.
    if type(st.pcPages)=="table" and #st.pcPages>0 then
      local pageNo=math.max(1,math.min(#st.pcPages,tonumber(st.pcPage) or 1))
      local mw=math.min(w-pad*3,w*.78)
      local mh=math.max(92*scale,h*.28)
      local mx=x+(w-mw)*.5
      local my=y+h-mh-pad*1.4
      color(c.frameShadow or {0,0,0,.45},.52,false)
      G.rectangle("fill",x,y,w,h)
      if Style and Style.panel then Style.panel(mx,my,mw,mh,c,1)
      else card(mx,my,mw,mh,c.surface,c.frame,math.max(5,6*scale)) end
      text(tostring(st.pcPages[pageNo] or ""),bodyF,mx+pad,my+pad,mw-pad*2,"left",c.text)
      text("A  continue",smallF,mx+pad,my+mh-smallF:getHeight()-pad*.7,
        mw-pad*2,"right",c.muted)
    end
    return true
  end

  local function evolutionSpeciesMon(species)
    local src=EvolutionScene and EvolutionScene._mon
    local mon={}
    if type(src)=="table" then
      for k,v in pairs(src) do mon[k]=v end
    end
    mon.species=species
    mon.speciesId=species
    return mon
  end

  local function drawEvolutionMon(game,species,x,y,w,h,scaleMul)
    if not species then return false end
    scaleMul=math.max(.05,math.min(1,tonumber(scaleMul) or 1))
    local dw,dh=w*scaleMul,h*scaleMul
    return drawMonPreview(game,evolutionSpeciesMon(species),
      x+(w-dw)*.5,y+(h-dh)*.5,dw,dh)
  end

  local function drawEvolution(game,viewport,c)
    if not evolutionModernSupported() then return false end
    setFloatingLayer("evolution_scene",true)
    local sx,sy,sw,sh=playfield(viewport)
    local scale=uiScaleFactor()
    local roomy=sw>=720 and sh>=460
    local w=math.min(sw*.96,(roomy and 760 or 660)*scale)
    local h=math.min(sh*.72,(roomy and 500 or 430)*scale)
    local x=sx+(sw-w)*.5
    -- Keep room for the shared Modern dialogue presenter along the bottom.
    local y=sy+math.max(12*scale,(sh-h)*.16)
    if Style and Style.panel then Style.panel(x,y,w,h,c,.96)
    else card(x,y,w,h,c.surface,c.frame,math.max(6,7*scale)) end

    local titleF=fontFor(math.max(15,29*scale))
    local smallF=fontFor(math.max(10,15*scale))
    text("EVOLUTION",titleF,x+24*scale,y+18*scale,w*.55,"left",c.text)
    local canStop=EvolutionScene._canStop~=false
    text(canStop and "B  stop evolution" or "Evolution cannot be stopped",
      smallF,x+w*.48,y+27*scale,w*.46,"right",c.muted)
    color(c.divider,.72,false)
    G.rectangle("fill",x+22*scale,y+62*scale,w-44*scale,1)

    local artTop=y+74*scale
    local artH=math.max(80*scale,h-100*scale)
    local artW=math.min(w*.54,artH)
    local artX=x+(w-artW)*.5
    local st=tostring(EvolutionScene._state or "")
    local pre=EvolutionScene._preSpecies
    local post=EvolutionScene._postSpecies

    if st=="cycle" then
      drawEvolutionMon(game,pre,artX,artTop,artW,artH,EvolutionScene._preScale or 1)
      drawEvolutionMon(game,post,artX,artTop,artW,artH,EvolutionScene._postScale or .06)
    elseif st=="flash_reveal" or st=="evo_cry" or st=="congrats" or st=="learn_moves" then
      drawEvolutionMon(game,post,artX,artTop,artW,artH,1)
    else
      drawEvolutionMon(game,pre,artX,artTop,artW,artH,1)
    end

    -- Keep a lightweight version of the source sparkle motion around the HD
    -- art.  Positions are remapped from the native 240x160 evolution canvas.
    if type(EvolutionScene._particles)=="table" then
      for i,p in ipairs(EvolutionScene._particles) do
        if i>48 then break end
        local px=artX+artW*.5+((tonumber(p.x) or 120)-120)*(artW/150)
        local py=artTop+artH*.5+((tonumber(p.y) or 64)-64)*(artH/105)
        local life=math.max(0,math.min(1,((tonumber(p.maxT) or 1)-(tonumber(p.t) or 0))/10))
        color(c.accent,life,true)
        G.circle("fill",px,py,math.max(1.5*scale,(tonumber(p.size) or 2)*scale*.7))
      end
    end

    local flash=tonumber(EvolutionScene._flashAlpha) or 0
    if flash>0 then
      color({1,1,1,1},math.min(.72,flash*.72),false)
      G.rectangle("fill",x+2,y+2,w-4,h-4,math.max(5,6*scale))
    end
    return true
  end

  mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
    nextFn(game,viewport)
    if not (enabled("menu") or enabled("pokemon")) then
      suppressPartyOam(false)
      setFloatingLayer("start",false)
      setFloatingLayer("party",false)
      setFloatingLayer("bag",false)
      setFloatingLayer("evolution_scene",false)
      return
    end
    if PartyMenu.open and not partyModernSupported() then
      if summaryOpen() then
        suppressPartyOam(true)
      else
        suppressPartyOam(false)
        setFloatingLayer("party",false)
      end
    end
    if okStart and StartMenu and StartMenu.open and not startModernSupported() then
      -- Keep the layer transparent while a child screen is on top, but do not
      -- paint the Start window underneath that child.
      setFloatingLayer("start",true)
    elseif okStart and StartMenu and not StartMenu.open then
      setFloatingLayer("start",false)
    end
    if BagMenu.open and not bagModernSupported() then setFloatingLayer("bag",false) end
    if evolutionModernSupported() then setFloatingLayer("evolution_scene",true)
    elseif not (okEvolution and EvolutionScene and EvolutionScene.open) then setFloatingLayer("evolution_scene",false) end
    local c=theme()
    local owns=false
    G.push("all")
    G.origin(); G.setShader(); G.setBlendMode("alpha")
    if evolutionModernSupported() then owns=drawEvolution(game,viewport,c)
    elseif namingModernSupported() then owns=drawNaming(game,viewport,c)
    elseif statGrowthOpen() then owns=drawStatGrowth(viewport,c)
    elseif startModernSupported() then owns=drawStart(viewport,c)
    elseif partyModernSupported() then owns=drawParty(game,viewport,c)
    elseif bagModernSupported() then owns=drawBag(viewport,c) end
    G.setColor(1,1,1,1)
    G.pop()
    return owns
  end,11000)

  mod.exports=mod.exports or {}
  mod.exports.gen3ModernCoreMenus=true
  return true
end
