-- Kanto in Motion v1.7.1 - Gen 2 Modern Core Menus v47 -- PC icon/gender follow-up
--
-- Modern overlay presentation for the native Gen 2 Start Menu, Pack,
-- Pokegear, Trainer Card, Save Menu, Options Menu and KIM Mod Settings. Their original objects remain authoritative for
-- input, state transitions, item logic, calls/maps/radio and page navigation.
return function(mod)
  local G=love.graphics
  local okChrome,Chrome=pcall(require,"src.ui.gen2.Chrome")
  local okGbcPalette,GbcPalette=pcall(require,"src.render.GbcPalette")
  local okStart,StartMenu=pcall(require,"src.ui.gen2.StartMenu")
  local okMain,MainMenu=pcall(require,"src.ui.gen2.MainMenu")
  local okTitle,Gen2TitleState=pcall(require,"src.ui.gen2.TitleState")
  local okPack,PackMenu=pcall(require,"src.ui.gen2.PackMenu")
  local okGear,Pokegear=pcall(require,"src.ui.gen2.Pokegear")
  local okCard,TrainerCard=pcall(require,"src.ui.gen2.TrainerCard")
  local okCenterPc,CenterPcMenu=pcall(require,"src.ui.gen2.CenterPcMenu")
  local okPc,PcMenu=pcall(require,"src.ui.gen2.PcMenu")
  local okBoxPc,BoxMenu=pcall(require,"src.ui.gen2.BoxMenu")
  local okEvolution,EvolutionAnim=pcall(require,"src.ui.gen2.EvolutionAnim")
  local okBoxes,Boxes=pcall(require,"src.core.gen2.Boxes")
  local okGen2Mon,Gen2Mon=pcall(require,"src.battle.gen2.Mon")
  local okSaveMenu,SaveMenu=pcall(require,"src.ui.gen2.SaveMenu")
  local okOptions,OptionsMenu=pcall(require,"src.ui.gen2.OptionsMenu")
  local okListMenu,ListMenu=pcall(require,"src.ui.ListMenu")
  local okSaveCore,SaveCore=pcall(require,"src.core.gen2.Save")
  local okTyper,Typer=pcall(require,"src.ui.gen2.Typer")
  local okStrings,Strings=pcall(require,"src.core.Strings")
  local okManager,ManagerState=pcall(require,"src.mods.ManagerState")
  if not (okStart and okPack and okGear and okCard and okSaveMenu and okOptions) then
    return false
  end

  -- A save can never legally contain LOVE userdata: SaveSerializer only
  -- accepts Lua scalars/tables.  If a presentation/cache object ever leaks
  -- into the live Gen 2 save, discard only that impossible value before the
  -- engine serializes it so saving cannot hard-error.  Ordinary save data is
  -- left untouched.
  if okSaveCore and SaveCore and type(SaveCore.save)=="function"
      and not SaveCore.__kimGen2UserdataSaveGuard then
    local oldSave=SaveCore.save
    local function stripUserdata(root)
      if type(root)~="table" then return end
      local seen={}
      local function walk(t)
        if seen[t] then return end
        seen[t]=true
        local remove={}
        for k,v in pairs(t) do
          if type(k)=="userdata" or type(v)=="userdata" then
            remove[#remove+1]=k
          elseif type(v)=="table" then
            walk(v)
          end
        end
        for _,k in ipairs(remove) do t[k]=nil end
      end
      walk(root)
    end
    SaveCore.save=function(save,...)
      stripUserdata(save)
      return oldSave(save,...)
    end
    SaveCore.__kimGen2UserdataSaveGuard=true
  end

  local Style=mod._kantoInMotionGen2Ui
  local FONT_PATH="assets/fonts/plainpixel/PlainPixel-Regular.ttf"
  local fonts={}
  local FALLBACK={
    surface={.075,.105,.17,.96},raised={.12,.17,.27,.94},
    selected={.18,.43,.72,.96},accent={.48,.86,1,1},
    frame={.48,.86,1,1},frameShadow={.01,.02,.04,.42},
    text={.96,.98,1,1},muted={.74,.82,.92,1},divider={.38,.5,.68,.94},
  }
  local function opt(k,d)
    if Style and Style.opt then return Style.opt(k,d) end
    if not(mod.options and mod.options.get) then return d end
    local ok,v=pcall(mod.options.get,mod.options,k)
    if not ok or v == nil then return d end
    return v
  end
  local function enabled()
    if Style and Style.masterEnabled then return Style.masterEnabled() end
    return opt("gen2IntegratedModernUi",true)~=false
  end
  local function presenterEnabled(kind)
    -- MODERN UI is the master gate for every Gen 2 Modern presenter, including
    -- the title/main menu.  Per-surface switches can only narrow that choice.
    if not enabled() then return false end
    if Style and Style.presenterEnabled then return Style.presenterEnabled(kind) end
    return true
  end
  local function hideOriginal()
    if Style and Style.hideOriginal then return Style.hideOriginal() end
    return true
  end
  local function theme()
    if Style and Style.theme then return Style.theme() end
    local t=mod._kantoInMotionGen2Themes
    return type(t)=="table" and (t[tostring(opt("gen2UiTheme","default"))] or t.default) or FALLBACK
  end
  local function color(c,a,foreground)
    if Style and Style.color then return Style.color(c,a,foreground) end
    c=c or {1,1,1,1}; G.setColor(c[1],c[2],c[3],a==nil and (c[4] or 1) or a)
  end
  local function font(px)
    if Style and Style.font then return Style.font(px) end
    px=math.max(8,math.floor(px+.5)); if fonts[px] then return fonts[px] end
    local ok,f=pcall(G.newFont,FONT_PATH,px,"mono",1); if not ok then ok,f=pcall(G.newFont,px) end
    if ok and f then if f.setFilter then pcall(f.setFilter,f,"nearest","nearest") end fonts[px]=f return f end
    return G.getFont()
  end
  local function text(s,f,x,y,w,align,c)
    if Style and Style.text then return Style.text(s,f,x,y,w,align,c) end
    G.setFont(f); color(c,nil,true); s=tostring(s or "")
    if w then
      local ok=pcall(G.printf,s,x,y,w,align or "left")
      if not ok then G.printf(s:gsub("[\128-\255]","?"),x,y,w,align or "left") end
    else G.print(s,x,y) end
  end
  local function boldText(s,f,x,y,c)
    G.setFont(f); color(c,nil,true); s=tostring(s or "")
    G.print(s,x,y); G.print(s,x+1,y)
  end
  local function normalizeUiText(value,joiner)
    if type(value)=="table" then value=table.concat(value,joiner or " ") end
    value=tostring(value or "")
    value=value:gsub("<PO><KE>","POKé")
    value=value:gsub("<PK><MN>","POKéMON")
    return value
  end
  local function fittedFont(basePx,value,maxW)
    local px=math.max(8,tonumber(basePx) or 8)
    local f=font(px)
    value=tostring(value or "")
    if not maxW or maxW<=0 then return f end
    while px>8 and f:getWidth(value)>maxW do
      local ratio=maxW/math.max(1,f:getWidth(value))
      local nextPx=math.max(8,math.min(px-1,px*math.max(.72,ratio*.97)))
      if nextPx>=px then nextPx=px-1 end
      px=nextPx
      f=font(px)
    end
    return f
  end
  local function fittedText(value,basePx,x,y,w,align,c)
    value=tostring(value or "")
    local f=fittedFont(basePx,value,w)
    return text(value,f,x,y,w,align or "left",c)
  end
  local function playfield()
    local ww,wh=G.getDimensions()
    if okChrome and Chrome and type(Chrome.playfieldRect)=="function" then
      local ok,x,y,w,h=pcall(Chrome.playfieldRect,ww,wh)
      if ok and w and h and w>0 and h>0 then return x,y,w,h end
    end
    return 0,0,ww,wh
  end
  local function uiScale(sw,sh)
    if Style and Style.uiScale then return Style.uiScale(sw,sh) end
    return math.max(.88,math.min(1.42,(sh or 720)/760))
  end
  local function density()
    return Style and Style.density and Style.density() or 1
  end
  local function layoutStyle()
    return Style and Style.layoutStyle and Style.layoutStyle() or "floating"
  end
  local function panel(x,y,w,h,c,alpha)
    if Style and Style.panel then return Style.panel(x,y,w,h,c,alpha) end
    local r=math.max(8,math.min(w,h)*.018)
    color(c.frameShadow or {0,0,0,.4},.18); G.rectangle("fill",x+2,y+3,w,h,r,r)
    color(c.surface,math.min(1,(c.surface[4] or 1)*(alpha or .94))); G.rectangle("fill",x,y,w,h,r,r)
    color(c.frame or c.accent); G.setLineWidth(math.max(2,math.min(w,h)*.0045)); G.rectangle("line",x,y,w,h,r,r)
  end
  local function centeredRowRect(y,h,inset)
    inset=math.max(0,tonumber(inset) or 0)
    local rh=math.max(1,h-inset*2)
    return y+inset,rh
  end
  local function centeredTextY(y,h,font)
    local fh=(font and type(font.getHeight)=="function") and font:getHeight() or 0
    return y+math.max(0,(h-fh)*.5)
  end

  local function modal(x,y,w,h,c,title,rows,selected,body,small,message)
    color({0,0,0,1},.35); G.rectangle("fill",0,0,G.getDimensions())
    local rh=math.max(52,small:getHeight()+20)
    local mw=math.min(620,w*.68)
    local textW=mw-40
    local _,wrappedTitle=body:getWrap(tostring(title or ""),textW)
    local titleLines=type(wrappedTitle)=="table" and #wrappedTitle or 1
    local titleH=math.max(body:getHeight(),titleLines*body:getHeight())
    local messageH=0
    if message and message~="" then
      local _,wrappedMessage=small:getWrap(tostring(message),textW)
      local messageLines=type(wrappedMessage)=="table" and #wrappedMessage or 1
      messageH=messageLines*small:getHeight()+8
    end
    local listTop=22+titleH+10+messageH+10
    local listH=math.max(0,#rows*rh)
    local contentH=listTop+listH+18
    local mh=math.max(150,contentH)
    local mx=x+(w-mw)/2; local my=y+(h-mh)/2; panel(mx,my,mw,mh,c,.98)
    text(title,body,mx+20,my+18,textW,"left",c.text)
    if message and message~="" then
      text(message,small,mx+20,my+18+titleH+10,textW,"left",c.muted)
    end
    local startY=my+listTop
    for i,row in ipairs(rows) do
      local yy=startY+(i-1)*rh
      local barY,barH=centeredRowRect(yy,rh,2)
      if i==selected then color(c.selected); G.rectangle("fill",mx+12,barY,mw-24,barH,5,5) end
      text(row,small,mx+24,centeredTextY(barY,barH,small),mw-48,"left",i==selected and c.text or c.muted)
    end
  end

  local function makeTransparent(Class,presenterKind)
    if not Class or Class.__kimModernTransparent then return end
    local oldNew=Class.new
    if type(oldNew)=="function" then
      Class.new=function(...)
        local self=oldNew(...)
        if presenterEnabled(presenterKind) and hideOriginal() and type(self)=="table" then self.isOpaque=false end
        return self
      end
    end
    local oldUpdate=Class.update
    if type(oldUpdate)=="function" then
      Class.update=function(self,...)
        self.isOpaque=not (presenterEnabled(presenterKind) and hideOriginal())
        return oldUpdate(self,...)
      end
    end
    Class.__kimModernTransparent=true
  end
  makeTransparent(PackMenu,"menu"); makeTransparent(Pokegear,"menu"); makeTransparent(TrainerCard,"pokemon")
  makeTransparent(SaveMenu,"menu"); makeTransparent(OptionsMenu,"menu")
  if okCenterPc then makeTransparent(CenterPcMenu,"menu") end
  if okPc then makeTransparent(PcMenu,"menu") end
  if okBoxPc then makeTransparent(BoxMenu,"pokemon") end
  if okEvolution then makeTransparent(EvolutionAnim,"pokemon") end

  -- PcMenu, BoxMenu and EvolutionAnim normally claim the full widescreen
  -- surround.  Modern UI owns them as floating windows, so let Game2 fall
  -- through to its ordinary overworld draw while the source state keeps all
  -- input/state ownership.
  local function floatingWidescreen(Class,kind,marker)
    if not Class or type(Class.drawsWidescreen)~="function" or Class[marker] then return end
    local old=Class.drawsWidescreen
    Class.drawsWidescreen=function(self,...)
      if presenterEnabled(kind) and hideOriginal() then return false end
      return old(self,...)
    end
    Class[marker]=true
  end
  floatingWidescreen(PcMenu,"menu","__kimModernPcFloatingV142")
  floatingWidescreen(BoxMenu,"pokemon","__kimModernBoxFloatingV142")
  floatingWidescreen(EvolutionAnim,"pokemon","__kimModernEvolutionFloatingV142")

  -- The category pages created by OptionsMenu's local pushGroup() still use
  -- OptionsMenu:drawsWidescreen().  Disable that path only while KIM owns
  -- Modern UI so every OPTION submenu reaches the same final-window overlay.
  if OptionsMenu and type(OptionsMenu.drawsWidescreen)=="function"
      and not OptionsMenu.__kimModernWideWrapped then
    local oldDrawsWidescreen=OptionsMenu.drawsWidescreen
    OptionsMenu.drawsWidescreen=function(self,...)
      if presenterEnabled("menu") then return false end
      return oldDrawsWidescreen(self,...)
    end
    OptionsMenu.__kimModernWideWrapped=true
  end

  local function isClass(s,Class) return type(s)=="table" and getmetatable(s)==Class end

  local function isDexRadarState(s)
    if type(s)~="table" then return false end
    local id=tostring(s.screenId or s.id or "")
    local shape=type(s.rows)=="table"
      and type(s.monIndex)=="table"
      and type(s.cursor)=="number"
      and type(s.mapLabel)=="string"
      and type(s.ownedN)=="number"
      and type(s.totalN)=="number"
    if not shape then return false end
    return id=="DexRadar"
      or (type(s.reloadForTod)=="function" and type(s.moveCursor)=="function")
  end

  local function target(s)
    if okMain and isClass(s,MainMenu) then return "titlemenu" end
    if isClass(s,StartMenu) then return "start" end
    if isClass(s,PackMenu) then return "pack" end
    if isClass(s,Pokegear) then return "gear" end
    if isClass(s,TrainerCard) then return "card" end
    if okCenterPc and isClass(s,CenterPcMenu) then return "centerpc" end
    if okPc and isClass(s,PcMenu) then return "pc" end
    if okBoxPc and isClass(s,BoxMenu) then return "boxpc" end
    if okEvolution and isClass(s,EvolutionAnim) then return "evolution" end
    if isClass(s,SaveMenu) then return "save" end
    if isClass(s,OptionsMenu) then return "options" end
    if isDexRadarState(s) then return "dexradar" end
    if type(s)=="table" and rawget(s,"_kimModernSettings") then
      return "kimsettings"
    end
    -- KIM's own mod-options page is hosted by ManagerState rather than the
    -- game's OptionsMenu. Modernize only Kanto in Motion's option page; leave
    -- the general Mod Manager and other mods untouched.
    local stateId=tostring(s and (s.screenId or s.id or "") or "")
    local isManagerState=(okManager and isClass(s,ManagerState)) or stateId=="ManagerState"
    if isManagerState
        and s.screen=="options"
        and s.currentMod
        and (tostring(s.currentMod.id or "")=="animated_menu_pokemon"
          or tostring(s.currentMod.name or ""):lower()=="kanto in motion") then
      return "modoptions"
    end
  end

  -- KIM's Gen 2 Start Menu intentionally omits the stray top-level MAPA row.
  -- Keep this as a final state sanitizer as well as a ui.start_menu.items hook:
  -- another wrapper can append a row after our hook returns, and StartMenu's
  -- Chrome.List keeps its own item array.  Pruning both tables here prevents an
  -- invisible/selectable ghost row and makes the cleanup independent of hook
  -- ordering.
  local function startRowIsMap(row)
    if type(row)=="string" then
      return tostring(row):upper():match("^%s*MAPA%s*$")~=nil
    end
    if type(row)~="table" then return false end
    local id=tostring(row.value or row.id or row.key or ""):lower()
    local label=tostring(row.label or row.text or row.name or ""):upper()
    label=label:gsub("^%s+",""):gsub("%s+$","")
    return label=="MAPA" or id=="mapa" or id=="map"
      or id=="townmap" or id=="town_map"
  end

  local function pruneStartMapRow(s)
    if not presenterEnabled("menu") or type(s)~="table" then return false end
    local removed=false
    local function prune(rows)
      if type(rows)~="table" then return end
      for i=#rows,1,-1 do
        if startRowIsMap(rows[i]) then
          table.remove(rows,i)
          removed=true
        end
      end
    end
    prune(s.items)
    if s.list then prune(s.list.items) end
    if removed and s.list then
      local n=type(s.list.items)=="table" and #s.list.items or 0
      if n>0 then
        s.list.index=math.max(1,math.min(tonumber(s.list.index) or 1,n))
        s.list.rows=math.min(tonumber(s.list.rows) or n,n)
      else
        s.list.index=1
        s.list.rows=0
        s.list.scroll=0
      end
      if type(s.list.ensureVisible)=="function" then pcall(s.list.ensureVisible,s.list) end
    end
    return removed
  end

  if StartMenu and type(StartMenu.new)=="function" and not StartMenu.__kimMapRowPruneNewWrapped then
    local oldStartNew=StartMenu.new
    StartMenu.new=function(...)
      local self=oldStartNew(...)
      pruneStartMapRow(self)
      return self
    end
    StartMenu.__kimMapRowPruneNewWrapped=true
  end

  local function drawStart(s)
    pruneStartMapRow(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh); local den=density()
    local rows=s.items or {}; local count=#rows
    local w=math.min(520*scale,sw*.44)
    local naturalRh=60*scale*den
    local h=math.min(sh*.88,94*scale+math.min(count,9)*naturalRh+76*scale)
    local inset=(tonumber(opt("startMenuInset","0")) or 0)/100
    local x=sx+sw-w-28*scale-(sw-w)*inset; local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.95)
    local big, body, small = font(40*scale), font(31*scale), font(23*scale)
    text("START",big,x+18*scale,y+15*scale,w-36*scale,"left",c.text)
    local index=(s.list and tonumber(s.list.index)) or 1

    -- Chrome.List is authoritative for input and can expose up to eight rows.
    -- KIM used to calculate a smaller visual row count when UI SCALE or
    -- COMFORTABLE density made each Modern row taller.  The native list then
    -- believed QUIT/MODS was already visible and did not advance its scroll,
    -- leaving a selectable row below KIM's card (the description changed, but
    -- the highlighted row itself was invisible).  First compress only the row
    -- spacing enough to match the native viewport when that remains readable;
    -- if a very large UI/font scale still cannot fit, maintain a presentation-
    -- only scroll that always keeps the native selected index on screen.
    local listRows=tonumber(s.list and s.list.rows) or math.min(count,8)
    listRows=math.max(1,math.min(count>0 and count or 1,listRows))
    local rowAreaH=math.max(1,h-165*scale)
    local minRh=math.max(body:getHeight()+8*scale,42*scale)
    local fitRh=rowAreaH/listRows
    local rh=math.max(minRh,math.min(naturalRh,fitRh))
    local maxRows=math.max(1,math.min(count>0 and count or 1,math.floor(rowAreaH/rh)))

    local scroll=(s.list and tonumber(s.list.scroll)) or 0
    local maxScroll=math.max(0,count-maxRows)
    scroll=math.max(0,math.min(scroll,maxScroll))
    if index<=scroll then scroll=math.max(0,index-1) end
    if index>scroll+maxRows then scroll=math.min(maxScroll,index-maxRows) end

    for slot=1,maxRows do
      local i=scroll+slot; local row=rows[i]; if not row then break end
      local yy=y+70*scale+(slot-1)*rh
      local barY,barH=centeredRowRect(yy,rh,2*scale)
      if i==index then color(c.selected); G.rectangle("fill",x+12*scale,barY,w-24*scale,barH,5,5) end
      local label = row.label or row.value or "OPTION"
      if tostring(row.value or row.id or ""):lower() == "pokegear" then
        label = "POKéGEAR"
      end
      text(label,body,x+28*scale,centeredTextY(barY,barH,body),w-56*scale,"left",i==index and c.text or c.muted)
    end
    local row=rows[index]; local desc=row and row.desc or {}
    local descText=normalizeUiText(desc,"  ")
    color(c.divider,nil,true); G.rectangle("fill",x+16*scale,y+h-86*scale,w-32*scale,1)
    fittedText(descText,23*scale,x+18*scale,y+h-66*scale,w-36*scale,"left",c.muted)

    if s.phase=="confirm" or s.phase=="confirmContest" then
      modal(x,y,w,h,c,s.phase=="confirm" and "Return to the title screen?" or "End the Contest?",
        {"YES","NO"},tonumber(s.confirmChoice) or 2,body,small)
    end
  end


  -- Gen 2's title screen hands off to a separate MainMenu state, whereas
  -- Gen 1 keeps its title artwork underneath the menu.  Recreate that same
  -- presentation relationship here: MainMenu keeps all input/callback/state
  -- ownership, while KIM draws an animated Gen 2 title backdrop and the
  -- Modern UI navigation card above it.
  local function ensureTitleBackdrop(s)
    if not (okTitle and Gen2TitleState and type(Gen2TitleState.new)=="function") then
      return nil
    end
    if type(s._kimModernTitleBackdrop)=="table" then return s._kimModernTitleBackdrop end
    local game=s and s.game
    local ok,bg=pcall(Gen2TitleState.new,game,{ title=game and game.titleData or {} })
    if ok and type(bg)=="table" then
      -- MainMenu is entered only after the real title entrance has completed.
      -- A freshly constructed TitleState starts with the logo interlace/gem
      -- entrance active, which produces split/duplicated title artwork when it
      -- is used only as a backdrop.  Start this presentation copy at the
      -- settled title state instead; MainMenu continues to own all logic.
      bg.entranceScx=0
      bg.gemY=bg.gemRestY or bg.gemY
      bg.fadeStart=nil
      bg.onContinue=nil
      bg.onTimeout=nil
      bg.timeoutStart=tonumber(bg.frameCounter) or 0
      s._kimModernTitleBackdrop=bg
      return bg
    end
    return nil
  end

  local function stepTitleBackdrop(s)
    local bg=ensureTitleBackdrop(s)
    if not bg then return end
    -- Advance only the settled title animation.  Do not run TitleState:update
    -- itself: that state owns title-screen input/timeouts, while MainMenu must
    -- remain the sole owner once this screen is open.
    bg.frameCounter=(tonumber(bg.frameCounter) or 0)+1
    if type(bg.advanceHooh)=="function" then pcall(bg.advanceHooh,bg) end
    if type(bg.advanceSuicune)=="function" then pcall(bg.advanceSuicune,bg) end
    local every=math.max(1,tonumber(bg.cloudScrollEvery) or 8)
    if bg.frameCounter%every==0 then
      bg.cloudScroll=((tonumber(bg.cloudScroll) or 0)-1)%160
    end
    if type(bg.spawnTrail)=="function" then pcall(bg.spawnTrail,bg) end
    if type(bg.stepTrails)=="function" then pcall(bg.stepTrails,bg) end
  end

  if okMain and MainMenu and type(MainMenu.update)=="function"
      and not MainMenu.__kimModernTitleUpdateWrapped then
    local oldMainUpdate=MainMenu.update
    MainMenu.update=function(self,dt,...)
      if presenterEnabled("menu") then stepTitleBackdrop(self) end
      return oldMainUpdate(self,dt,...)
    end
    MainMenu.__kimModernTitleUpdateWrapped=true
  end

  -- Gold's ui.title_menu.items hook deliberately accepts the same descriptor
  -- style as Gen 1, but its native MainMenu routes built-in rows by `value`.
  -- Honor source-authored onSelect callbacks too so KIM ASSETS and third-party
  -- title actions remain functional under the Modern presenter.
  if okMain and MainMenu and type(MainMenu.choose)=="function"
      and not MainMenu.__kimModernTitleChooseWrapped then
    local oldMainChoose=MainMenu.choose
    MainMenu.choose=function(self,value,...)
      local item=self and self.list and type(self.list.items)=="table"
        and self.list.items[tonumber(self.list.index) or 1] or nil
      if value==nil and type(item)=="table" and type(item.onSelect)=="function" then
        -- Gen 2 injected rows use onSelect(game, menu) only when the row has
        -- no native `value`.  Keep that distinction here.  Battle Art Gen2
        -- deliberately turns CONTINUE into an onSelect preload row, then
        -- resumes by calling menu:choose("continue").  Re-running onSelect
        -- for that explicit native value recurses back into the preload hook
        -- until Lua stack-overflows.  An explicit value must therefore fall
        -- through to the original MainMenu.choose path.
        return item.onSelect(self.game, self)
      end
      return oldMainChoose(self,value,...)
    end
    MainMenu.__kimModernTitleChooseWrapped=true
  end

  local function titleTimeText(s)
    if not (s and s.hasSave and type(s.clockParts)=="function") then return "" end
    local ok,hour,minute,weekday=pcall(s.clockParts,s)
    if not ok then return "" end
    local days={"SUN","MON","TUE","WED","THU","FRI","SAT"}
    local clock
    if MainMenu and type(MainMenu.timeString)=="function" then
      local okClock,value=pcall(MainMenu.timeString,hour,minute)
      if okClock then clock=tostring(value or "") end
    end
    if not clock or clock=="" then
      local h=tonumber(hour) or 0; local m=tonumber(minute) or 0
      local period=h>=12 and "PM" or "AM"; local h12=h%12; if h12==0 then h12=12 end
      clock=("%d:%02d %s"):format(h12,m,period)
    end
    return ((days[tonumber(weekday) or 1] or "DAY").."  "..clock)
  end

  local function titleSaveSummary(s)
    local save=s and s.save or nil
    if okSaveCore and SaveCore and type(SaveCore.summary)=="function" then
      local ok,summary=pcall(SaveCore.summary,save)
      if ok and type(summary)=="table" then return summary end
    end
    if type(save)~="table" then return nil end
    local player=save.player or {}; local pd=save.pokedex or {}; local pt=save.playTime or {}
    local caught=0; for _,v in pairs(pd.caught or {}) do if v then caught=caught+1 end end
    local badges=0; for _,v in pairs(player.badges or {}) do if v then badges=badges+1 end end
    return { name=player.name or "GOLD", badges=badges, caught=caught,
      hours=pt.hours or 0, minutes=pt.minutes or 0 }
  end

  local function drawTitleMainMenu(s)
    local c=theme(); local ww,wh=G.getDimensions()
    local bg=ensureTitleBackdrop(s)
    local drewBackdrop=false
    if bg and type(bg.drawWidescreen)=="function" then
      drewBackdrop=pcall(bg.drawWidescreen,bg,ww,wh)
    end
    if not drewBackdrop then
      color(c.surface,1); G.rectangle("fill",0,0,ww,wh)
    end
    -- Match Gen 1's title-menu treatment: keep the title artwork visible and
    -- float a readable Modern navigation card over it rather than replacing
    -- the whole screen with a native menu box.
    color({0,0,0,1},.12); G.rectangle("fill",0,0,ww,wh)

    local sx,sy,sw,sh=playfield(); local scale=uiScale(sw,sh); local den=density()
    local rows=s and s.list and s.list.items or {}
    local index=s and s.list and (tonumber(s.list.index) or 1) or 1
    local full=layoutStyle()=="full"
    local body,small=font(31*scale),font(21*scale)
    -- UI DENSITY may make the nominal row shorter, but FONT SCALE must never
    -- be allowed to make the text taller than the selectable row.  This is the
    -- combination that used to break at COMPACT + 75% UI + 200% font.
    local rh=math.max(64*scale*den,body:getHeight()+math.max(8,10*scale))
    local footerLines=(s and s.hasSave) and 2 or 1
    local footerH=math.max((s and s.hasSave) and 78*scale or 58*scale,
      footerLines*small:getHeight()+math.max(16,22*scale))
    local w=full and sw*.70 or math.min(540*scale,sw*.44)
    local h=math.min(sh*.84,28*scale+math.max(1,#rows)*rh+footerH)
    -- The CONTINUE/save-summary phase is taller than the ordinary title menu:
    -- it always shows four information rows plus its own footer.  Basing this
    -- card on the title-menu row count pulls the footer divider into TIME on
    -- small windows.  Give confirm mode its own height budget, then compress
    -- only the summary rows if the playfield itself is too short.
    if s and s.phase=="confirm" then
      h=math.min(sh*.92,math.max(h,364*scale))
    end
    -- Title/main-menu parity with Gen 1: this is a modal navigation card over
    -- the title artwork, not the in-game side Start Menu, so always center it.
    local x=sx+(sw-w)/2
    local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.95)
    local top=y+18*scale

    if s and s.phase=="confirm" then
      local summary=titleSaveSummary(s)
      local titleFont=font(38*scale); local labelFont=font(24*scale)
      text("CONTINUE",titleFont,x+26*scale,top,w-52*scale,"left",c.text)
      local yy=top+62*scale
      local info={
        {"PLAYER",summary and summary.name or "----"},
        {"BADGES",summary and tostring(summary.badges or 0) or "0"},
        {"POKéDEX",summary and tostring(summary.caught or 0) or "0"},
        {"TIME",summary and ("%d:%02d"):format(summary.hours or 0,summary.minutes or 0) or "0:00"},
      }
      local dividerY=y+h-58*scale
      local infoBottom=dividerY-8*scale
      local rowH=math.min(54*scale,math.max(1,(infoBottom-yy)/#info))
      local rowInset=math.min(5*scale,math.max(2,rowH*.10))
      for i,r in ipairs(info) do
        local ry=yy+(i-1)*rowH
        local barY,barH=centeredRowRect(ry,rowH,rowInset)
        color(c.raised,.78); G.rectangle("fill",x+20*scale,barY,w-40*scale,barH,5,5)
        text(r[1],labelFont,x+34*scale,centeredTextY(barY,barH,labelFont),w*.42,"left",c.muted)
        text(r[2],labelFont,x+w*.50,centeredTextY(barY,barH,labelFont),w*.40,"right",c.text)
      end
      color(c.divider); G.rectangle("fill",x+20*scale,dividerY,w-40*scale,1)
      fittedText("A  CONTINUE    B  BACK",21*scale,x+24*scale,y+h-42*scale,w-48*scale,"left",c.accent)
      return
    end

    local footerY=y+h-footerH
    local rowAreaH=math.max(1,footerY-top)
    local maxRows=math.max(1,math.min(#rows>0 and #rows or 1,math.floor(rowAreaH/rh)))
    local scroll=math.max(0,math.min((s and s.list and tonumber(s.list.scroll)) or 0,
      math.max(0,#rows-maxRows)))
    if index<=scroll then scroll=math.max(0,index-1) end
    if index>scroll+maxRows then scroll=math.min(math.max(0,#rows-maxRows),index-maxRows) end
    for slot=1,maxRows do
      local i=scroll+slot
      local row=rows[i]
      if not row then break end
      local yy=top+(slot-1)*rh
      local barY,barH=centeredRowRect(yy,rh,2*scale)
      if i==index then
        color(c.selected); G.rectangle("fill",x+12*scale,barY,w-24*scale,barH,6,6)
      end
      local label=type(row)=="table" and (row.label or row.name or row.value) or row
      local labelText=tostring(label or "OPTION")
      local rowFont=fittedFont(31*scale,labelText,w-56*scale)
      text(labelText,rowFont,x+28*scale,centeredTextY(barY,barH,rowFont),w-56*scale,"left",
        i==index and c.text or c.muted)
    end
    color(c.divider); G.rectangle("fill",x+18*scale,footerY,w-36*scale,1)
    local clock=titleTimeText(s)
    if clock~="" then
      local lineGap=math.max(4,5*scale)
      local firstY=footerY+math.max(6,8*scale)
      text(clock,small,x+22*scale,firstY,w-44*scale,"left",c.muted)
      text("A  SELECT",small,x+22*scale,firstY+small:getHeight()+lineGap,w-44*scale,"left",c.accent)
    else
      text("A  SELECT",small,x+22*scale,
        footerY+math.max(6,(footerH-small:getHeight())*.5),w-44*scale,"left",c.accent)
    end
  end

  local POCKET_LABELS={"ITEMS","POKé BALLS","KEY ITEMS","TM/HM"}
  local function normalizeInlineText(value)
    value=normalizeUiText(value," ")
    value=value:gsub("<NEXT>","\n")
    return value
  end
  local function itemDescription(s,row)
    local def=row and s.items and s.items[row.id]
    local d=def and def.description
    return normalizeInlineText(d)
  end
  local function drawChevronPair(x,y,size,colorValue,gap)
    gap=gap or math.max(10,size*.85)
    local cx=x
    local cy=y+size*.52
    color(colorValue)
    G.setLineWidth(math.max(2,size*.16))
    G.setLineJoin("miter")
    G.line(cx+size*.55,cy-size*.42,cx+size*.05,cy,cx+size*.55,cy+size*.42)
    cx=x+gap
    G.line(cx-size*.55,cy-size*.42,cx-size*.05,cy,cx-size*.55,cy+size*.42)
  end
  local function drawVerticalArrow(cx,y,size,direction,colorValue)
    local half=size*.5
    local top=y
    local midY=y+half
    local bottom=y+size
    color(colorValue)
    if direction=="up" then
      G.polygon("fill", cx, top, cx-half, bottom, cx+half, bottom)
    else
      G.polygon("fill", cx-half, top, cx+half, top, cx, bottom)
    end
  end
  local function packFooterSpec(maxW,scale)
    local function metrics(footerPx,buttonPx)
      local ff=font(footerPx)
      local bf=font(buttonPx)
      local arrowSize=math.max(8,ff:getHeight()*.50)
      local gap=math.max(7,ff:getHeight()*.38)
      local micro=math.max(4,ff:getHeight()*.18)
      local arrowBlock=arrowSize*2.35
      local pocketW=ff:getWidth("POCKET")
      local line2W=bf:getWidth("A")+micro+ff:getWidth("CHOOSE")+gap
        +bf:getWidth("B")+micro+ff:getWidth("BACK")
      return {footerFont=ff,buttonFont=bf,arrowSize=arrowSize,gap=gap,micro=micro,
        arrowBlock=arrowBlock,pocketW=pocketW,line2W=line2W,
        totalW=arrowBlock+gap+pocketW+gap+line2W}
    end

    local baseFooterPx=21*scale
    local baseButtonPx=23*scale
    local spec=metrics(baseFooterPx,baseButtonPx)
    if spec.totalW<=maxW then
      spec.wrapped=false
      spec.height=math.max(62*scale,spec.footerFont:getHeight()+24*scale)
      return spec
    end

    -- Small overages (typical phone landscape at 100% font size) stay on one
    -- line and scale down only as much as needed. Larger accessibility-font
    -- overages switch to two rows instead of running past the card edge.
    local fit=(maxW/math.max(1,spec.totalW))*.97
    if fit>=.78 then
      spec=metrics(baseFooterPx*fit,baseButtonPx*fit)
      spec.wrapped=false
      spec.height=math.max(62*scale,spec.footerFont:getHeight()+24*scale)
      return spec
    end

    local line1=metrics(baseFooterPx,baseButtonPx)
    local line2=line1
    if line1.line2W>maxW then
      local f2=(maxW/math.max(1,line1.line2W))*.97
      line2=metrics(baseFooterPx*f2,baseButtonPx*f2)
    end
    line1.wrapped=true
    line1.line2Font=line2.footerFont
    line1.line2ButtonFont=line2.buttonFont
    line1.line2Gap=line2.gap
    line1.line2Micro=line2.micro
    line1.height=math.max(94*scale,line1.footerFont:getHeight()+line2.footerFont:getHeight()+34*scale)
    return line1
  end

  local function drawPack(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh); local den=density()
    local w=math.min(1080*scale,sw*.72); local h=math.min(690*scale,sh*.82)
    if layoutStyle()=="full" then w=sw*.94; h=sh*.92; scale=math.min(w/1080,h/690) end
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2; panel(x,y,w,h,c,.95)
    local big, body, small = font(35*scale), font(26*scale), font(19*scale)
    local tabFont = font(23*scale)
    local countFont = font(22*scale)
    local pad=22*scale
    text("PACK",big,x+pad,y+15*scale,w*.32,"left",c.text)

    local tabW=(w-pad*2)/4
    for i,label in ipairs(POCKET_LABELS) do
      local tx=x+pad+(i-1)*tabW; local sel=i==(tonumber(s.pocketIndex) or 1)
      if sel then color(c.selected); G.rectangle("fill",tx,y+56*scale,tabW-4,42*scale,5,5) end
      text(label,tabFont,tx+4,y+64*scale,tabW-10,"center",sel and c.text or c.muted)
    end

    local contentY=y+112*scale
    local listW=w*.57; local detailX=x+listW+16*scale
    local footerRight=x+w-20*scale
    local footerAvail=math.max(80,footerRight-detailX)
    local footerSpec=packFooterSpec(footerAvail,scale)
    local footerH=footerSpec.height
    local contentH=math.max(140*scale,h-112*scale-footerH)
    color(c.divider,nil,true); G.rectangle("fill",x+listW+8*scale,contentY,1,contentH)
    local rows=s.rows or {}; local idx=tonumber(s.index) or 1; local scroll=tonumber(s.scroll) or 0
    local desiredVisible=math.max(5,math.min(10,math.floor(8/den+.5)))
    local minRowH=math.max(body:getHeight(),countFont:getHeight())+math.max(6,8*scale)
    local fitVisible=math.max(1,math.floor(contentH/math.max(1,minRowH)))
    local visible=math.max(1,math.min(desiredVisible,fitVisible))
    local maxScroll=math.max(0,(#rows+1)-visible)
    scroll=math.max(0,math.min(scroll,maxScroll))
    if idx<=scroll then scroll=math.max(0,idx-1) end
    if idx>scroll+visible then scroll=math.min(maxScroll,idx-visible) end
    local rh=contentH/visible
    for slot=1,visible do
      local i=scroll+slot; local row=rows[i]
      if i==#rows+1 then row={name="CANCEL"} end
      if not row then break end
      local yy=contentY+(slot-1)*rh; local sel=i==idx
      local barY,barH=centeredRowRect(yy,rh,2*scale)
      if sel then color(c.selected); G.rectangle("fill",x+pad*.65,barY,listW-pad*1.2,barH,5,5) end
      text(row.name or "CANCEL",body,x+pad,centeredTextY(barY,barH,body),listW*.62,"left",sel and c.text or c.muted)
      local right=row.teaches or (row.showCount and ("x"..tostring(row.count or 0))) or ""
      text(right,countFont,x+listW*.65,centeredTextY(barY,barH,countFont),listW*.27,"right",sel and c.text or c.muted)
    end
    local selected=idx<=#rows and rows[idx] or nil
    text(selected and selected.name or "CANCEL",big,detailX,contentY+12*scale,w-listW-40*scale,"left",c.text)
    text(itemDescription(s,selected),body,detailX,contentY+78*scale,w-listW-40*scale,"left",c.muted)

    local footerTop=y+h-footerH
    local function drawActionRow(fx,fy,ff,bf,gap,micro)
      boldText("A",bf,fx,fy-1*scale,c.accent)
      fx=fx+bf:getWidth("A")+micro
      text("CHOOSE",ff,fx,fy,nil,nil,c.accent)
      fx=fx+ff:getWidth("CHOOSE")+gap
      boldText("B",bf,fx,fy-1*scale,c.accent)
      fx=fx+bf:getWidth("B")+micro
      text("BACK",ff,fx,fy,nil,nil,c.accent)
    end

    if footerSpec.wrapped then
      local line1Y=footerTop+10*scale
      local fx=detailX
      local arrowSize=footerSpec.arrowSize
      drawChevronPair(fx+arrowSize*.55,line1Y+footerSpec.footerFont:getHeight()*.08,
        arrowSize,c.accent,arrowSize*1.45)
      fx=fx+footerSpec.arrowBlock+footerSpec.gap
      text("POCKET",footerSpec.footerFont,fx,line1Y,nil,nil,c.accent)
      local line2Y=line1Y+footerSpec.footerFont:getHeight()+8*scale
      drawActionRow(detailX,line2Y,footerSpec.line2Font,footerSpec.line2ButtonFont,
        footerSpec.line2Gap,footerSpec.line2Micro)
    else
      local lineY=footerTop+(footerH-footerSpec.footerFont:getHeight())*.5
      local fx=detailX
      local arrowSize=footerSpec.arrowSize
      drawChevronPair(fx+arrowSize*.55,lineY+footerSpec.footerFont:getHeight()*.08,
        arrowSize,c.accent,arrowSize*1.45)
      fx=fx+footerSpec.arrowBlock+footerSpec.gap
      text("POCKET",footerSpec.footerFont,fx,lineY,nil,nil,c.accent)
      fx=fx+footerSpec.pocketW+footerSpec.gap
      drawActionRow(fx,lineY,footerSpec.footerFont,footerSpec.buttonFont,
        footerSpec.gap,footerSpec.micro)
    end

    if s.submenu and type(s.submenu.rows)=="table" then
      local labels={use="USE",give="GIVE",toss="TOSS",sel="REGISTER",quit="QUIT"}
      local rr={}; for _,id in ipairs(s.submenu.rows) do rr[#rr+1]=labels[id] or tostring(id) end
      modal(x,y,w,h,c,selected and selected.name or "ITEM",rr,tonumber(s.submenu.index) or 1,body,small)
    elseif s.qtyState then
      modal(x,y,w,h,c,"HOW MANY?",{("x%d / %d"):format(s.qtyState.qty or 1,s.qtyState.max or 1)},1,body,small)
    elseif s.confirm then
      modal(x,y,w,h,c,"ARE YOU SURE?",{"YES","NO"},tonumber(s.confirm.choice) or 1,body,small)
    elseif s.message then
      local msg=type(s.message)=="table" and table.concat(s.message," ") or tostring(s.message)
      modal(x,y,w,h,c,msg,{},nil,body,small)
    end
  end

  local trainerCardCanvas
  local trainerCardQuads={}
  local function captureNativeTrainerCard(s)
    if type(s)~="table" or type(s.drawPanel)~="function" then return nil end
    if not trainerCardCanvas then
      local ok,canvas=pcall(G.newCanvas,160,144)
      if not ok or not canvas then return nil end
      trainerCardCanvas=canvas
      if canvas.setFilter then pcall(canvas.setFilter,canvas,"nearest","nearest") end
    end
    local previous=type(G.getCanvas)=="function" and G.getCanvas() or nil
    local pushed=pcall(G.push,"all")
    if not pushed then pcall(G.push) end

    -- Pages 2/3 normally composite the animated badge OAM directly over the
    -- Gym Leader art. KIM crops the leader faces out of this native render, so
    -- capturing that composite also bakes part of the old-position badge into
    -- the portrait. Temporarily suppress only the native badge-sprite pass
    -- while making KIM's private source canvas; the real TrainerCard state,
    -- badge ownership and page logic are untouched.
    local suppressBadges=(tonumber(s.page) or 1)>1
    local oldBadgeDraw=rawget(s,"drawBadgeSprites")
    if suppressBadges then s.drawBadgeSprites=function() end end

    local ok=pcall(function()
      G.setCanvas(trainerCardCanvas)
      if G.origin then G.origin() end
      G.clear(0,0,0,0)
      G.setColor(1,1,1,1)
      s:drawPanel()
    end)

    if suppressBadges then
      if oldBadgeDraw~=nil then s.drawBadgeSprites=oldBadgeDraw
      else s.drawBadgeSprites=nil end
    end
    if previous then pcall(G.setCanvas,previous) else pcall(G.setCanvas) end
    pcall(G.pop)
    return ok and trainerCardCanvas or nil
  end
  local function cardQuad(key,qx,qy,qw,qh)
    if trainerCardQuads[key] then return trainerCardQuads[key] end
    if type(G.newQuad)~="function" then return nil end
    local ok,q=pcall(G.newQuad,qx,qy,qw,qh,160,144)
    if ok then trainerCardQuads[key]=q; return q end
    return nil
  end
  local function drawCardCrop(canvas,key,qx,qy,qw,qh,x,y,w,h)
    if not canvas then return false end
    local q=cardQuad(key,qx,qy,qw,qh)
    if not q then return false end
    local fit=math.min(w/qw,h/qh)
    local dw,dh=qw*fit,qh*fit
    G.setColor(1,1,1,1)
    G.draw(canvas,q,x+(w-dw)/2,y+(h-dh)/2,0,fit,fit)
    return true
  end

  -- The native Gen 2 Trainer Card art is authored against a white card
  -- background, so simply cropping it into KIM leaves a white rectangle around
  -- the player and leader portraits.  Remove only near-white pixels connected
  -- to the crop edge.  This keeps white pixels enclosed by the sprite outline
  -- (Chris/Kris clothing, eyes, highlights, etc.) instead of color-keying every
  -- white pixel in the artwork.
  local trainerCardTransparentCrops={}
  local function transparentCardCrop(canvas,key,qx,qy,qw,qh)
    local cached=trainerCardTransparentCrops[key]
    if cached~=nil then return cached or nil end
    if not (canvas and love and love.image and type(love.image.newImageData)=="function"
        and type(canvas.newImageData)=="function" and type(G.newImage)=="function") then
      trainerCardTransparentCrops[key]=false
      return nil
    end
    local okSource,source=pcall(function() return canvas:newImageData() end)
    if not okSource or not source then
      trainerCardTransparentCrops[key]=false
      return nil
    end
    local okOut,out=pcall(love.image.newImageData,qw,qh)
    if not okOut or not out then
      trainerCardTransparentCrops[key]=false
      return nil
    end
    local okCopy=pcall(function()
      for yy=0,qh-1 do
        for xx=0,qw-1 do
          local r,g,b,a=source:getPixel(qx+xx,qy+yy)
          out:setPixel(xx,yy,r,g,b,a)
        end
      end
    end)
    if not okCopy then
      trainerCardTransparentCrops[key]=false
      return nil
    end

    local function nearWhite(xx,yy)
      local r,g,b,a=out:getPixel(xx,yy)
      return (a or 0)>.001 and (r or 0)>.93 and (g or 0)>.93 and (b or 0)>.93
    end
    local function opaqueNonWhite(xx,yy)
      if xx<0 or yy<0 or xx>=qw or yy>=qh then return false end
      local r,g,b,a=out:getPixel(xx,yy)
      return (a or 0)>.001 and not ((r or 0)>.93 and (g or 0)>.93 and (b or 0)>.93)
    end

    -- Morty (FOG) and Pryce (GLACIER) have legitimate white hair that can
    -- touch the source card paper.  Preserve that white without leaving the
    -- broad halo used by v132: build a tight silhouette from the non-white
    -- portrait pixels and allow only ONE source pixel of white padding around
    -- it.  Row and column spans are both required, so empty card paper cannot
    -- grow outward just because it shares the same white shade.
    local protectWhite={}
    local protectLeaderWhite=(key=="leader_2_4" or key=="leader_2_7")
    if protectLeaderWhite then
      local rowMin,rowMax,colMin,colMax={},{},{},{}
      for yy=0,qh-1 do
        for xx=0,qw-1 do
          if opaqueNonWhite(xx,yy) then
            rowMin[yy]=rowMin[yy] and math.min(rowMin[yy],xx) or xx
            rowMax[yy]=rowMax[yy] and math.max(rowMax[yy],xx) or xx
            colMin[xx]=colMin[xx] and math.min(colMin[xx],yy) or yy
            colMax[xx]=colMax[xx] and math.max(colMax[xx],yy) or yy
          end
        end
      end
      local function rowSpan(yy)
        local lo,hi
        for sy=math.max(0,yy-1),math.min(qh-1,yy+1) do
          if rowMin[sy]~=nil then
            lo=lo and math.min(lo,rowMin[sy]) or rowMin[sy]
            hi=hi and math.max(hi,rowMax[sy]) or rowMax[sy]
          end
        end
        if lo==nil then return nil,nil end
        return math.max(0,lo-1),math.min(qw-1,hi+1)
      end
      local function colSpan(xx)
        local lo,hi
        for sx=math.max(0,xx-1),math.min(qw-1,xx+1) do
          if colMin[sx]~=nil then
            lo=lo and math.min(lo,colMin[sx]) or colMin[sx]
            hi=hi and math.max(hi,colMax[sx]) or colMax[sx]
          end
        end
        if lo==nil then return nil,nil end
        return math.max(0,lo-1),math.min(qh-1,hi+1)
      end
      for yy=0,qh-1 do
        local rlo,rhi=rowSpan(yy)
        if rlo~=nil then
          for xx=rlo,rhi do
            if nearWhite(xx,yy) then
              local clo,chi=colSpan(xx)
              if clo~=nil and yy>=clo and yy<=chi then
                protectWhite[yy*qw+xx+1]=true
              end
            end
          end
        end
      end
    end

    local seen={}
    local xs,ys={},{}
    local head=1
    local function add(xx,yy)
      if xx<0 or yy<0 or xx>=qw or yy>=qh then return end
      local k=yy*qw+xx+1
      if seen[k] or protectWhite[k] then return end
      seen[k]=true
      -- Gen 2 card paper is pure/near white after palette presentation.
      if nearWhite(xx,yy) then
        xs[#xs+1]=xx; ys[#ys+1]=yy
      end
    end
    for xx=0,qw-1 do add(xx,0); add(xx,qh-1) end
    for yy=1,qh-2 do add(0,yy); add(qw-1,yy) end
    while head<=#xs do
      local xx,yy=xs[head],ys[head]; head=head+1
      out:setPixel(xx,yy,0,0,0,0)
      add(xx-1,yy); add(xx+1,yy); add(xx,yy-1); add(xx,yy+1)
    end

    local okImg,img=pcall(G.newImage,out)
    if not okImg or not img then
      trainerCardTransparentCrops[key]=false
      return nil
    end
    if img.setFilter then pcall(img.setFilter,img,"nearest","nearest") end
    trainerCardTransparentCrops[key]=img
    return img
  end

  local function drawTransparentCardCrop(canvas,key,qx,qy,qw,qh,x,y,w,h)
    local img=transparentCardCrop(canvas,key,qx,qy,qw,qh)
    if not img then return drawCardCrop(canvas,key,qx,qy,qw,qh,x,y,w,h) end
    local iw,ih=img:getDimensions()
    local fit=math.min(w/iw,h/ih)
    local dw,dh=iw*fit,ih*fit
    G.setColor(1,1,1,1)
    G.draw(img,x+(w-dw)/2,y+(h-dh)/2,0,fit,fit)
    return true
  end

  local JOHTO={"ZEPHYR","HIVE","PLAIN","FOG","STORM","MINERAL","GLACIER","RISING"}
  local KANTO={"BOULDER","CASCADE","THUNDER","RAINBOW","SOUL","MARSH","VOLCANO","EARTH"}
  -- Native badge OAM is not in the same order as the visible leader grid:
  -- Mineral precedes Storm in the source table.
  local JOHTO_BADGE_OAM={
    ZEPHYR=1,HIVE=2,PLAIN=3,FOG=4,MINERAL=5,STORM=6,GLACIER=7,RISING=8,
  }
  local KANTO_BADGE_ART={
    BOULDER="assets/trainer_card/badges/01_bolder.png",
    CASCADE="assets/trainer_card/badges/02_cascade.png",
    THUNDER="assets/trainer_card/badges/03_thunder.png",
    RAINBOW="assets/trainer_card/badges/04_rainbow.png",
    SOUL="assets/trainer_card/badges/05_soul.png",
    MARSH="assets/trainer_card/badges/06_marsh.png",
    VOLCANO="assets/trainer_card/badges/07_volcano.png",
    EARTH="assets/trainer_card/badges/08_earth.png",
  }
  local trainerCardImageCache={}
  local function loadTrainerCardImage(path)
    if type(path)~="string" or path=="" then return nil end
    if trainerCardImageCache[path]~=nil then return trainerCardImageCache[path] or nil end
    local ok,img=pcall(G.newImage,path)
    if not ok then img=nil end
    if img and img.setFilter then pcall(img.setFilter,img,"nearest","nearest") end
    trainerCardImageCache[path]=img or false
    return img
  end
  local function drawImageFit(img,x,y,w,h)
    if not img then return false end
    local iw,ih=img:getDimensions()
    if not iw or not ih or iw<=0 or ih<=0 then return false end
    local fit=math.min(w/iw,h/ih)
    local dw,dh=iw*fit,ih*fit
    G.setColor(1,1,1,1)
    G.draw(img,x+(w-dw)/2,y+(h-dh)/2,0,fit,fit)
    return true
  end
  local function drawJohtoBadgeSprite(s,name,x,y,size)
    local oi=JOHTO_BADGE_OAM[name]
    local obj=oi and s.gfx and s.gfx.badgeOam and s.gfx.badgeOam[oi]
    local sheet=s.badges
    if not (obj and sheet and type(sheet.image)=="function" and type(sheet.quad)=="function") then
      return false
    end
    local img=sheet:image()
    if not img then return false end
    local frame=math.floor((tonumber(s.frames) or 0)/32)%8
    local tile=(obj.frames and obj.frames[frame+1]) or 0
    local flip=tile>=0x80
    local base=flip and (tile-0x80) or tile
    local cell=size/2
    local function body()
      G.setColor(1,1,1,1)
      for _,part in ipairs({{0,0,0},{1,0,1},{0,1,2},{1,1,3}}) do
        local q=sheet:quad(base+part[3])
        if q then
          local dx=flip and (1-part[1]) or part[1]
          if flip then
            G.draw(img,q,x+(dx+1)*cell,y+part[2]*cell,0,-cell/8,cell/8)
          else
            G.draw(img,q,x+dx*cell,y+part[2]*cell,0,cell/8,cell/8)
          end
        end
      end
    end
    if okGbcPalette and GbcPalette and s.gfx and s.gfx.badgePalette
        and type(GbcPalette.with)=="function" then
      local ok=pcall(GbcPalette.with,s.gfx.badgePalette,body)
      if not ok then body() end
    else
      body()
    end
    return true
  end

  local function drawOwnedBadge(s,nativeCard,page,name,i,x,y,size)
    if page==2 then
      -- Draw straight from BadgeGFX.  Cropping the already-composited native
      -- Trainer Card also captured whatever leader pixels happened to sit
      -- underneath the badge OAM position, which is where the stray hair came
      -- from.  The extracted badge sheet already has transparent shade 0.
      return drawJohtoBadgeSprite(s,name,x,y,size)
    else
      local img=loadTrainerCardImage(KANTO_BADGE_ART[name])
      if img then return drawImageFit(img,x,y,size,size) end
    end
    return false
  end
  local function badgeOwned(tbl,name,i) return type(tbl)=="table" and (tbl[name]==true or tbl[i]==true) end
  local function drawCard(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh); local den=density()
    local w=math.min(940*scale,sw*.68); local h=math.min(620*scale,sh*.80)
    if layoutStyle()=="full" then w=sw*.94; h=sh*.92; scale=math.min(w/940,h/620) end
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2; panel(x,y,w,h,c,.95)
    local big, body, small = font(35*scale), font(26*scale), font(20*scale)
    local pageFont = font(23*scale)
    local footerFont = font(22*scale)
    local save=s.save or {}; local player=save.player or {}; local page=tonumber(s.page) or 1
    local pageCount=(player.kantoBadges and next(player.kantoBadges)) and 3 or 2
    text("TRAINER CARD",big,x+24*scale,y+20*scale,w*.55,"left",c.text)
    text(("PAGE %d / %d"):format(page,pageCount),pageFont,x+w*.56,y+22*scale,w*.38,"right",c.accent)
    local contentY=y+96*scale
    local nativeCard=captureNativeTrainerCard(s)
    if page==1 then
      local pd=save.pokedex or {}; local pt=save.playTime or {}
      local rows={
        {"NAME",player.name or "GOLD"},
        {"ID No.",("%05d"):format(tonumber(player.id) or 0)},
        {"MONEY",tostring(player.money or 0)},
        {"POKéDEX",tostring((function() local n=0 for _,v in pairs(pd.caught or {}) do if v then n=n+1 end end return n end)())},
        {"PLAY TIME",("%d:%02d"):format(pt.hours or 0,pt.minutes or 0)},
      }
      local portraitX=x+w*.70
      local portraitY=contentY-8*scale
      local portraitW=w*.24
      local portraitH=250*scale
      panel(portraitX,portraitY,portraitW,portraitH,c,.58)
      -- Native Trainer Card portrait is the 5x7 tile block at (14,1).
      drawTransparentCardCrop(nativeCard,"portrait_"..tostring(s.female==true),112,8,40,56,
        portraitX+12*scale,portraitY+12*scale,portraitW-24*scale,portraitH-24*scale)
      for i,r in ipairs(rows) do
        local yy=contentY+(i-1)*68*scale
        text(r[1],body,x+45*scale,yy,w*.28,"left",c.muted)
        text(r[2],body,x+w*.34,yy,w*.29,"right",c.text)
      end
    else
      local names=page==2 and JOHTO or KANTO
      local owned=page==2 and player.badges or player.kantoBadges
      local colW=(w-80*scale)/2
      for i,name in ipairs(names) do
        local col=(i-1)%2; local row=math.floor((i-1)/2)
        local bx=x+40*scale+col*colW; local by=contentY+row*94*scale
        local yes=badgeOwned(owned,name,i)
        local cardH=78*scale
        color(yes and c.selected or c.raised); G.rectangle("fill",bx,by,colW-14*scale,cardH,6,6)
        -- Reuse the game's native Gym Leader portraits, but strip the card's
        -- white paper around them and give the artwork more room than v130.
        local faceCol=(i-1)%4
        local faceRow=math.floor((i-1)/4)
        -- Each native leader record is ten tiles: the first 8x8 tile on
        -- the top-left is the little numbered marker, while the actual leader
        -- portrait occupies the 3x3 block to its right/below.  Crop only the 24x24 portrait block for the Gym Leader art. Draw the
        -- small number tile separately with its own transparency pass so the
        -- numbers keep no white box while the portrait keeps its 1 px white-hair protection.
        local cropX=24+faceCol*32
        local cropY=80+faceRow*24
        local numX=cropX-8
        local numY=cropY
        local artW=112*scale
        local artH=68*scale
        local numSize=18*scale
        local numDrawX=bx+6*scale
        local numDrawY=by+9*scale
        drawTransparentCardCrop(nativeCard,"leader_num_"..page.."_"..i,numX,numY,8,8,
          numDrawX,numDrawY,numSize,numSize)
        local portraitX=numDrawX+numSize+4*scale
        local portraitW=math.max(24*scale,artW-(portraitX-bx)-4*scale)
        drawTransparentCardCrop(nativeCard,"leader_"..page.."_"..i,cropX,cropY,24,24,
          portraitX,by+5*scale,portraitW,artH)
        local tx=bx+artW+14*scale
        local tw=colW-artW-34*scale
        local badgeSize=42*scale
        local cardInnerW=(colW-14*scale)
        local badgeX=bx+cardInnerW-badgeSize-10*scale
        local badgeY=by+18*scale
        local nameW=math.max(24*scale,badgeX-tx-8*scale)
        fittedText(name,22*scale,tx,by+12*scale,nameW,"left",yes and c.text or c.muted)
        if yes then
          -- Show the actual earned badge emblem instead of the word EARNED.
          -- Johto comes from the native animated badge OAM; Kanto reuses KIM's
          -- existing high-resolution badge emblems.
          drawOwnedBadge(s,nativeCard,page,name,i,
            badgeX,badgeY,badgeSize)
        else
          text("----",small,badgeX,by+44*scale,badgeSize,"center",c.muted)
        end
      end
    end
    local footerY=y+h-54*scale
    local footerX=x+24*scale
    local footerArrowSize=math.max(10*scale,footerFont:getHeight()*.5)
    drawChevronPair(footerX+footerArrowSize*.55, footerY+footerFont:getHeight()*.1, footerArrowSize, c.muted, footerArrowSize*1.45)
    footerX=footerX+footerArrowSize*2.45
    fittedText("PAGE   A NEXT   B/START BACK",22*scale,footerX,footerY,w-48*scale-(footerArrowSize*2.45),"left",c.muted)
  end

  local function cardId(s)
    local card=type(s.card)=="function" and s:card() or (s.cards and s.cards[s.cardIndex or 1])
    return card and card.id or "clock", card
  end
  local mapCanvas
  local function drawNativeMapCard(s,x,y,w,h,c)
    if type(s.drawMap)~="function" then return false end
    if not mapCanvas then
      local ok,canvas=pcall(G.newCanvas,160,144)
      if not ok or not canvas then return false end
      mapCanvas=canvas
      if mapCanvas.setFilter then pcall(mapCanvas.setFilter,mapCanvas,"nearest","nearest") end
    end
    local ok=pcall(function()
      G.push("all")
      G.setCanvas(mapCanvas)
      G.origin()
      G.clear(0,0,0,0)
      s:drawMap()
      G.pop()
    end)
    if not ok then pcall(G.pop); return false end
    color(c.raised,.90); G.rectangle("fill",x,y,w,h,8,8)
    local sx=w/160; local sy=h/144; local fit=math.min(sx,sy)
    local dw,dh=160*fit,144*fit
    color({1,1,1,1})
    G.draw(mapCanvas,x+(w-dw)/2,y+(h-dh)/2,0,fit,fit)
    return true
  end
  local function drawGear(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh); local den=density()
    local w=math.min(1080*scale,sw*.72); local h=math.min(680*scale,sh*.82)
    if layoutStyle()=="full" then w=sw*.94; h=sh*.92; scale=math.min(w/1080,h/680) end
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2; panel(x,y,w,h,c,.95)
    local big, body, small = font(35*scale), font(26*scale), font(19*scale)
    local tabFont = font(23*scale)
    local footerFont = font(21*scale)
    text("POKéGEAR",big,x+24*scale,y+18*scale,w*.35,"left",c.text)

    local tabs=s.cards or {}; local tabW=(w-48*scale)/math.max(1,#tabs)
    for i,card in ipairs(tabs) do
      local label=type(s.cardLabel)=="function" and s:cardLabel(card) or card.label or card.id
      local tx=x+24*scale+(i-1)*tabW; local sel=i==(s.cardIndex or 1)
      if sel then color(c.selected); G.rectangle("fill",tx,y+60*scale,tabW-5,54*scale,5,5) end
      text(label,tabFont,tx+4,y+69*scale,tabW-8,"center",sel and c.text or c.muted)
    end

    local id=cardId(s); local cy=y+138*scale; local ch=h-202*scale
    if s.mode=="strip" then
      text("Choose a POKéGEAR card.",body,x+36*scale,cy,w-72*scale,"center",c.text)
      local footerText = "CARD   A OPEN   B BACK"
      local tw = small:getWidth(footerText)
      local tx = x + (w - tw) * .5
      local ty = y + h - 52*scale
      local arrowSize = math.max(10*scale, small:getHeight()*.5)
      drawChevronPair(tx - arrowSize*1.9, ty + small:getHeight()*.08, arrowSize, c.muted, arrowSize*1.45)
      fittedText(footerText,19*scale,tx,ty,math.max(1,x+w-24*scale-tx),"left",c.muted)
      return
    end
    if id=="clock" then
      local hour,minute,weekday=0,0,1
      if type(s.clockParts)=="function" then local ok,a,b,d=pcall(s.clockParts,s); if ok then hour,minute,weekday=a,b,d end end
      local days={"SUN","MON","TUE","WED","THU","FRI","SAT"}
      local period=hour>=12 and "PM" or "AM"; local h12=hour%12; if h12==0 then h12=12 end
      text(("%d:%02d %s"):format(h12,minute or 0,period),font(62*scale),x+40*scale,cy+70*scale,w-80*scale,"center",c.text)
      text(days[weekday or 1] or "DAY",big,x+40*scale,cy+150*scale,w-80*scale,"center",c.accent)
    elseif id=="map" then
      local region=type(s.region)=="function" and s:region() or "johto"
      text((tostring(region):upper()).." MAP",big,x+36*scale,cy+4*scale,w-72*scale,"left",c.text)
      local mapX=x+42*scale; local mapY=cy+48*scale
      local mapW=w-84*scale; local mapH=math.max(120*scale,ch-80*scale)
      if not drawNativeMapCard(s,mapX,mapY,mapW,mapH,c) then
        text("MAP UNAVAILABLE",body,mapX,mapY+50*scale,mapW,"center",c.muted)
      end
    elseif id=="radio" then
      text("RADIO",big,x+36*scale,cy+12*scale,w-72*scale,"left",c.text)
      text(("CHANNEL %d"):format(tonumber(s.station) or 1),font(48*scale),x+36*scale,cy+80*scale,w-72*scale,"center",c.accent)
      text(s.radioOn and "ON AIR" or "NO SIGNAL",body,x+36*scale,cy+145*scale,w-72*scale,"center",c.text)
    elseif id=="phone" then
      text("PHONE",big,x+36*scale,cy+12*scale,w-72*scale,"left",c.text)
      local list=type(s.phoneList)=="function" and s:phoneList() or {}
      local start=(tonumber(s.phoneScroll) or 0)+1
      for slot=1,4 do
        local idx=start+slot-1; local yy=cy+62*scale+(slot-1)*66*scale
        local selected=(slot-1)==(tonumber(s.phoneCursor) or 0)
        if selected then color(c.selected); G.rectangle("fill",x+60*scale,yy,w-120*scale,46*scale,5,5) end
        local value=list[idx] or 0
        local label, className = "----------", nil
        if value ~= 0 and type(s.contactRow) == "function" then
          local okContact, name, class = pcall(s.contactRow, s, value)
          if okContact then
            label = tostring(name or "----------"):gsub(":$", "")
            className = class
          end
        end
        text(label,body,x+80*scale,yy+7*scale,w-160*scale,"left",selected and c.text or c.muted)
        if className then
          text(className,small,x+96*scale,yy+35*scale,w-176*scale,"left",
            selected and c.text or c.muted)
        end
      end
    else
      text(tostring(id):upper(),big,x+36*scale,cy+20*scale,w-72*scale,"center",c.text)
    end
    local footerY=y+h-58*scale
    local leftText="B RETURN"
    local rightText="CARD"
    local arrowSize=math.max(10*scale,footerFont:getHeight()*.5)
    local gap=18*scale
    local groupW=footerFont:getWidth(leftText)+gap+arrowSize*2.35+gap+footerFont:getWidth(rightText)
    local gx=x+(w-groupW)*.5
    text(leftText,footerFont,gx,footerY,nil,nil,c.muted)
    gx=gx+footerFont:getWidth(leftText)+gap
    drawChevronPair(gx+arrowSize*.55, footerY+footerFont:getHeight()*.1, arrowSize, c.muted, arrowSize*1.45)
    gx=gx+arrowSize*2.35+gap
    text(rightText,footerFont,gx,footerY,nil,nil,c.muted)
  end


  local function saveSummary(s)
    if okSaveCore and SaveCore and type(SaveCore.summary)=="function" then
      local ok,summary=pcall(SaveCore.summary,s.save)
      if ok and type(summary)=="table" then return summary end
    end
    local save=s.save or {}
    local player=save.player or {}
    local pd=save.pokedex or {}
    local caught=0
    for _,v in pairs(pd.caught or {}) do if v then caught=caught+1 end end
    local badges=0
    for _,v in pairs(player.badges or {}) do if v then badges=badges+1 end end
    local pt=save.playTime or {}
    return {
      name=player.name or "GOLD",
      badges=badges,
      caught=caught,
      hours=pt.hours or 0,
      minutes=pt.minutes or 0,
    }
  end

  local function savePromptLines(s)
    local lines=type(s.prompt)=="function" and s:prompt() or {""}
    if type(lines)~="table" then lines={tostring(lines or "")} end
    if okTyper and Typer and s.typedPhase==s.phase and type(Typer.text)=="function" then
      local ok,typed=pcall(Typer.text,s,lines)
      if ok and type(typed)=="table" then lines=typed end
    end
    return lines
  end

  local function drawSave(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh); local den=density()
    local w=math.min(980*scale,sw*.70)
    local h=math.min(610*scale,sh*.80)
    if layoutStyle()=="full" then w=sw*.94; h=sh*.92; scale=math.min(w/980,h/610) end
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.97)

    local big=font(38*scale)
    local body=font(27*scale)
    local small=font(20*scale)
    local labelFont=font(23*scale)

    text("SAVE GAME",big,x+26*scale,y+18*scale,w-52*scale,"left",c.text)

    local summary=saveSummary(s)
    local infoY=y+92*scale
    local infoH=230*scale
    panel(x+24*scale,infoY,w-48*scale,infoH,c,.66)

    local rows={
      {"PLAYER",summary.name or "GOLD"},
      {"BADGES",tostring(summary.badges or 0)},
      {"POKéDEX",tostring(summary.caught or 0)},
      {"TIME",("%d:%02d"):format(summary.hours or 0,summary.minutes or 0)},
    }
    for i,row in ipairs(rows) do
      local yy=infoY+22*scale+(i-1)*50*scale
      text(row[1],labelFont,x+52*scale,yy,w*.34,"left",c.muted)
      text(row[2],body,x+w*.50,yy-3*scale,w*.38,"right",c.text)
    end

    local promptY=infoY+infoH+18*scale
    local promptH=h-(promptY-y)-34*scale
    panel(x+24*scale,promptY,w-48*scale,promptH,c,.82)

    local showChoice=type(s.yesNoVisible)=="function" and s:yesNoVisible()
    local choiceW=0
    local choiceGap=0
    if showChoice then
      choiceW=260*scale
      choiceGap=26*scale
    end

    local lines=savePromptLines(s)
    local textW=(w-96*scale)-choiceW-choiceGap
    for i,line in ipairs(lines) do
      if i>3 then break end
      text(line,body,x+48*scale,
        promptY+24*scale+(i-1)*(body:getHeight()+9*scale),
        textW,"left",c.text)
    end

    local phase=tostring(s.phase or "confirm")
    local status=phase=="saving" and "SAVING..."
      or phase=="done" and (s.saved and "SAVED" or "SAVE FAILED")
      or phase=="overwrite" and "OVERWRITE"
      or "CONFIRM"

    if showChoice then
      local cw=choiceW
      local rh=52*scale
      local ch=rh*2+20*scale
      local cx=x+w-cw-38*scale
      local cy=promptY+promptH-ch-18*scale
      panel(cx,cy,cw,ch,c,.99)
      for i,label in ipairs({"YES","NO"}) do
        local yy=cy+10*scale+(i-1)*rh
        if i==(tonumber(s.choice) or 1) then
          color(c.selected)
          G.rectangle("fill",cx+9*scale,yy,cw-18*scale,rh-5*scale,6,6)
        end
        text(label,body,cx+28*scale,
          yy+(rh-body:getHeight())*.40,cw-50*scale,"left",
          i==(tonumber(s.choice) or 1) and c.text or c.muted)
      end
    end

    -- Keep the save-state label in the small footer strip below the
    -- prompt panel, matching the v23 mock: aligned to the prompt's right
    -- edge, but no longer inside the YES/NO box or the prompt body.
    text(status,small,
      x+48*scale,promptY+promptH-2*scale,
      w-96*scale,"right",c.accent)
  end

  local function optionLabel(row)
    if not row then return "" end
    local label=row.label or row.id or "OPTION"
    if okStrings and Strings then
      local ok,v=pcall(Strings,label)
      if ok and v then label=v end
    end
    return tostring(label or "")
  end

  local function optionValue(s,row)
    if not row or row.group then return row and row.group and "OPEN" or "" end
    if row.cancel then return "" end
    if row.frame then return "TYPE "..tostring(s.options and s.options.frame or 1) end
    if type(row.text)=="function" then
      local ok,v=pcall(row.text,s.options)
      if ok and v~=nil then return tostring(v) end
    end
    if row.values then
      local value=s.options and s.options[row.key]
      local out=row.display and row.display[value] or value
      if okStrings and Strings and out~=nil then
        local ok,v=pcall(Strings,out)
        if ok and v then out=v end
      end
      return tostring(out or "")
    end
    if type(row.value)=="function" then
      local ok,v=pcall(row.value,s.game)
      if ok and v~=nil then return tostring(v) end
    end
    if row.activate then return "OPEN" end
    return ""
  end

  local function drawOptions(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh); local den=density()
    local w=math.min(1080*scale,sw*.72)
    local h=math.min(700*scale,sh*.84)
    if layoutStyle()=="full" then w=sw*.94; h=sh*.92; scale=math.min(w/1080,h/700) end
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.97)

    local big=font(38*scale)
    local body=font(26*scale)
    local valueFont=font(23*scale)
    local small=font(19*scale)

    fittedText("OPTIONS",38*scale,x+28*scale,y+18*scale,w*.55,"left",c.text)
    fittedText(s.sub and "CATEGORY" or "SETTINGS",19*scale,x+w*.62,y+30*scale,w*.30,"right",c.accent)

    local rows=type(s.visible)=="function" and s:visible() or (s.view or s.rows or {})
    local idx=tonumber(s.index) or 1
    local scroll=tonumber(s.scroll) or 0
    local selected=rows[idx]
    local hint="UP/DOWN SELECT   LEFT/RIGHT CHANGE   A OPEN/CHANGE   B BACK"
    if selected and selected.group then
      hint="A OPEN CATEGORY   B BACK"
    elseif selected and selected.cancel then
      hint="A/B BACK"
    elseif selected and selected.activate then
      hint="A OPEN   B BACK"
    end
    local titleBlockH=math.max(big:getHeight(),small:getHeight())
    local top=y+math.max(86*scale,18*scale+titleBlockH+14*scale)
    local hintFont=fittedFont(19*scale,hint,w-56*scale)
    local footerH=math.max(62*scale,hintFont:getHeight()+30*scale)
    local listH=math.max(1,h-(top-y)-footerH)
    local desiredVisible=math.max(5,math.min(9,math.floor(7/den+.5)))
    local minRowH=math.max(body:getHeight(),valueFont:getHeight())+math.max(6,9*scale)
    local fitVisible=math.max(1,math.floor(listH/math.max(1,minRowH)))
    local visible=math.max(1,math.min(desiredVisible,fitVisible))
    local maxScroll=math.max(0,#rows-visible)
    scroll=math.max(0,math.min(scroll,maxScroll))
    if idx<=scroll then scroll=math.max(0,idx-1) end
    if idx>scroll+visible then scroll=math.min(maxScroll,idx-visible) end
    local rh=listH/visible

    for slot=1,visible do
      local i=scroll+slot
      local row=rows[i]
      if not row then break end
      local yy=top+(slot-1)*rh
      local selected=i==idx
      local barY,barH=centeredRowRect(yy,rh,3*scale)
      if selected then
        color(c.selected)
        G.rectangle("fill",x+22*scale,barY,w-44*scale,barH,7,7)
        color(c.accent,nil,true)
        G.rectangle("fill",x+22*scale,barY,5*scale,barH,2,2)
      end

      local label=tostring(optionLabel(row) or "")
      local value=tostring(optionValue(s,row) or "")
      local arrowGutter=30*scale
      local labelW=w*.53
      local valueX=x+w*.63
      local valueRight=x+w-34*scale-arrowGutter
      local valueW=math.max(80*scale,valueRight-valueX)
      local rowLabelFont=fittedFont(26*scale,label,labelW)
      text(label,rowLabelFont,x+48*scale,
        centeredTextY(barY,barH,rowLabelFont),
        labelW,"left",selected and c.text or c.muted)

      if value~="" then
        local rowValueFont=fittedFont(23*scale,value,valueW)
        text(value,rowValueFont,valueX,
          centeredTextY(barY,barH,rowValueFont),
          valueW,"right",selected and c.text or c.accent)
      end
    end

    color(c.divider)
    G.rectangle("fill",x+24*scale,y+h-footerH,w-48*scale,1)

    text(hint,hintFont,x+28*scale,
      y+h-hintFont:getHeight()-14*scale,w-56*scale,"left",c.muted)

    if scroll>0 then
      drawVerticalArrow(x+w-30*scale,y+22*scale,math.max(12*scale,body:getHeight()*.65),"up",c.accent)
    end
    if scroll+visible<#rows then
      drawVerticalArrow(x+w-30*scale,y+h-footerH-42*scale,math.max(12*scale,body:getHeight()*.65),"down",c.accent)
    end
  end

  local function managerOptionValue(row)
    if not row then return "" end
    if type(row.value)=="function" then
      local ok,v=pcall(row.value)
      if ok and v~=nil then return tostring(v) end
    end
    if row.value~=nil and type(row.value)~="function" then
      return tostring(row.value)
    end
    return ""
  end

  local function managerOptionDescription(s,row)
    if not (s and row and row.id and s.currentMod
        and type(s.schemaFor)=="function") then return "" end
    local ok,schema=pcall(s.schemaFor,s,s.currentMod)
    if not ok or type(schema)~="table" then return "" end
    for _,spec in ipairs(schema) do
      if type(spec)=="table" and spec.key==row.id then
        return tostring(spec.description or "")
      end
    end
    if row.id=="__reset" then
      return "Restore all Kanto in Motion settings to their defaults."
    end
    return ""
  end

  local function drawModOptions(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh); local den=density()
    local w=math.min(1160*scale,sw*.76)
    local h=math.min(720*scale,sh*.86)
    if layoutStyle()=="full" then w=sw*.94; h=sh*.92; scale=math.min(w/1160,h/720) end
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.97)

    local titleFont=font(38*scale)
    local body=font(27*scale)
    local valueFont=font(25*scale)
    local small=font(19*scale)
    local descFont=font(20*scale)

    local title=(s.currentMod and (s.currentMod.name or s.currentMod.id))
      or "KANTO IN MOTION"
    fittedText(string.upper(tostring(title)),38*scale,
      x+28*scale,y+18*scale,w*.58,"left",c.text)
    fittedText("MOD SETTINGS",19*scale,x+w*.63,y+30*scale,w*.30,"right",c.accent)

    local rows=s.optionRows or {}
    local idx=tonumber(s.cursor) or 1
    local scroll=tonumber(s.scroll) or 0
    local selectedRow=rows[idx]
    local desc=managerOptionDescription(s,selectedRow)
    local hint="UP/DOWN  SELECT   LEFT/RIGHT  CHANGE   A  CHANGE   B  DONE"
    local titleBlockH=math.max(titleFont:getHeight(),small:getHeight())
    local listTop=y+math.max(86*scale,18*scale+titleBlockH+14*scale)
    local descLines=0
    if desc~="" then
      local _,wrapped=descFont:getWrap(desc,w-64*scale)
      descLines=type(wrapped)=="table" and math.max(1,#wrapped) or 1
    end
    local descH=descLines*descFont:getHeight()
    local hintFont=fittedFont(19*scale,hint,w-64*scale)
    local footerNeeded=14*scale+descH+(descH>0 and 10*scale or 0)
      +hintFont:getHeight()+16*scale
    local footerH=math.max(128*scale,footerNeeded)
    local listH=math.max(1,h-(listTop-y)-footerH)
    local desiredVisible=math.max(5,math.min(9,math.floor(7/den+.5)))
    local minRowH=math.max(body:getHeight(),valueFont:getHeight())+math.max(6,9*scale)
    local fitVisible=math.max(1,math.floor(listH/math.max(1,minRowH)))
    local visible=math.max(1,math.min(desiredVisible,fitVisible))
    local maxScroll=math.max(0,#rows-visible)
    scroll=math.max(0,math.min(scroll,maxScroll))
    if idx<=scroll then scroll=math.max(0,idx-1) end
    if idx>scroll+visible then scroll=math.min(maxScroll,idx-visible) end
    local rh=listH/visible

    for slot=1,visible do
      local i=scroll+slot
      local row=rows[i]
      if not row then break end
      local yy=listTop+(slot-1)*rh
      local selected=i==idx
      local barY,barH=centeredRowRect(yy,rh,3*scale)

      if selected then
        color(c.selected)
        G.rectangle("fill",x+22*scale,barY,w-44*scale,barH,7,7)
        color(c.accent,nil,true)
        G.rectangle("fill",x+22*scale,barY,5*scale,barH,2,2)
      end

      local label=tostring(row.label or row.id or "OPTION")
      local value=tostring(managerOptionValue(row) or "")
      local arrowGutter=30*scale
      local labelW=w*.54
      local valueX=x+w*.64
      local valueRight=x+w-34*scale-arrowGutter
      local valueW=math.max(76*scale,valueRight-valueX)
      local rowLabelFont=fittedFont(27*scale,label,labelW)

      text(label,rowLabelFont,x+50*scale,
        centeredTextY(barY,barH,rowLabelFont),
        labelW,"left",selected and c.text or c.muted)

      if value~="" then
        local rowValueFont=fittedFont(25*scale,value,valueW)
        text(value,rowValueFont,valueX,
          centeredTextY(barY,barH,rowValueFont),
          valueW,"right",selected and c.text or c.accent)
      end
    end

    local footerY=y+h-footerH
    color(c.divider)
    G.rectangle("fill",x+26*scale,footerY,w-52*scale,1)

    if desc~="" then
      text(desc,descFont,x+32*scale,footerY+14*scale,
        w-64*scale,"left",c.muted)
    end

    text(hint,hintFont,x+32*scale,
      y+h-hintFont:getHeight()-14*scale,w-64*scale,"left",c.accent)

    if scroll>0 then
      drawVerticalArrow(x+w-30*scale,y+24*scale,math.max(12*scale,body:getHeight()*.65),"up",c.accent)
    end
    if scroll+visible<#rows then
      drawVerticalArrow(x+w-30*scale,y+h-footerH-42*scale,math.max(12*scale,body:getHeight()*.65),"down",c.accent)
    end
  end

  local function drawKimSettings(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh); local den=density()
    local w=math.min(1120*scale,sw*.76)
    local h=math.min(720*scale,sh*.86)
    if layoutStyle()=="full" then w=sw*.94; h=sh*.92; scale=math.min(w/1120,h/720) end
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.97)

    local titleFont=font(38*scale)
    local body=font(27*scale)
    local valueFont=font(25*scale)
    local small=font(19*scale)
    local descFont=font(20*scale)

    local title=tostring(s.title or "KANTO IN MOTION")
    fittedText(title,38*scale,x+28*scale,y+18*scale,w*.56,"left",c.text)
    local section=rawget(s,"_kimModernSettings")
    local sectionLabel=section=="battle" and "BATTLE SETTINGS"
      or section=="ui" and "UI SETTINGS" or "MOD SETTINGS"
    fittedText(sectionLabel,19*scale,x+w*.60,y+30*scale,w*.33,"right",c.accent)

    local rows=s.items or {}
    local idx=tonumber(s.index) or 1
    local scroll=tonumber(s.scroll) or 0
    local selected=rows[idx]
    local desc=selected and selected.option and selected.option.description or ""
    if selected and selected.resetBattleDefaults then
      desc="Restore all battle settings to their defaults."
    elseif selected and selected.resetUiDefaults then
      desc="Restore all Modern UI settings to their defaults."
    elseif selected and selected.submenu then
      desc=selected.submenu and tostring(selected.submenu):find("ui_settings",1,true)
        and "Open the Kanto in Motion Modern UI settings."
        or "Open the Kanto in Motion battle settings."
    elseif selected and selected.cancel then
      local currentSection=rawget(s,"_kimModernSettings")
      desc=(currentSection=="battle" or currentSection=="ui")
        and "Return to Kanto in Motion settings."
        or "Close Kanto in Motion settings."
    end
    local hint="UP/DOWN  SELECT   LEFT/RIGHT  CHANGE   A  CHANGE/OPEN   B  BACK"
    local titleBlockH=math.max(titleFont:getHeight(),small:getHeight())
    local listTop=y+math.max(86*scale,18*scale+titleBlockH+14*scale)
    local descLines=0
    if desc and tostring(desc)~="" then
      local _,wrapped=descFont:getWrap(tostring(desc),w-64*scale)
      descLines=type(wrapped)=="table" and math.max(1,#wrapped) or 1
    end
    local descH=descLines*descFont:getHeight()
    local hintFont=fittedFont(19*scale,hint,w-64*scale)
    local footerNeeded=14*scale+descH+(descH>0 and 10*scale or 0)
      +hintFont:getHeight()+16*scale
    local footerH=math.max(132*scale,footerNeeded)
    local listH=math.max(1,h-(listTop-y)-footerH)
    local desiredVisible=math.max(5,math.min(9,math.floor(7/den+.5)))
    local minRowH=math.max(body:getHeight(),valueFont:getHeight())+math.max(6,9*scale)
    local fitVisible=math.max(1,math.floor(listH/math.max(1,minRowH)))
    local visible=math.max(1,math.min(desiredVisible,fitVisible))
    local maxScroll=math.max(0,#rows-visible)
    scroll=math.max(0,math.min(scroll,maxScroll))
    if idx<=scroll then scroll=math.max(0,idx-1) end
    if idx>scroll+visible then scroll=math.min(maxScroll,idx-visible) end
    local rh=listH/visible

    for slot=1,visible do
      local i=scroll+slot
      local row=rows[i]
      if not row then break end
      local yy=listTop+(slot-1)*rh
      local selected=i==idx
      local barY,barH=centeredRowRect(yy,rh,3*scale)

      if selected then
        color(c.selected)
        G.rectangle("fill",x+22*scale,barY,w-44*scale,barH,7,7)
        color(c.accent,nil,true)
        G.rectangle("fill",x+22*scale,barY,5*scale,barH,2,2)
      end

      local label=tostring(row.label or row.id or "OPTION")
      local value=tostring(row.right or "")
      local labelW=w*.54
      local valueX=x+w*.64
      local valueW=w*.27
      local rowLabelFont=fittedFont(27*scale,label,labelW)

      text(label,rowLabelFont,x+50*scale,
        centeredTextY(barY,barH,rowLabelFont),
        labelW,"left",selected and c.text or c.muted)

      if value~="" then
        local rowValueFont=fittedFont(25*scale,value,valueW)
        text(value,rowValueFont,valueX,
          centeredTextY(barY,barH,rowValueFont),
          valueW,"right",selected and c.text or c.accent)
      end
    end

    local footerY=y+h-footerH
    color(c.divider)
    G.rectangle("fill",x+26*scale,footerY,w-52*scale,1)

    if desc and tostring(desc)~="" then
      text(tostring(desc),descFont,x+32*scale,footerY+14*scale,
        w-64*scale,"left",c.muted)
    end

    text(hint,hintFont,x+32*scale,
      y+h-hintFont:getHeight()-14*scale,w-64*scale,"left",c.accent)

    if scroll>0 then
      drawVerticalArrow(x+w-30*scale,y+24*scale,math.max(12*scale,body:getHeight()*.65),"up",c.accent)
    end
    if scroll+visible<#rows then
      drawVerticalArrow(x+w-30*scale,y+h-footerH-42*scale,math.max(12*scale,body:getHeight()*.65),"down",c.accent)
    end
  end

  -- Dex Radar 1.2.0 compatibility.  The source screen remains authoritative
  -- for map collection, encounter rates, cursor movement, repeat behavior,
  -- hotkeys and B-to-close.  KIM only replaces its final draw when Gen 2
  -- Modern UI + MENU UI are enabled.
  local radarImageCache={}
  local function loadRadarImage(path)
    if type(path)~="string" or path=="" then return nil end
    if radarImageCache[path]~=nil then return radarImageCache[path] or nil end
    local img=nil
    local okA,Assets=pcall(require,"src.render.Assets")
    if okA and Assets and type(Assets.image)=="function" then
      local ok,value=pcall(Assets.image,path)
      if ok then img=value end
    end
    if not img then
      local ok,value=pcall(G.newImage,path)
      if ok then img=value end
    end
    if img and img.setFilter then pcall(img.setFilter,img,"nearest","nearest") end
    radarImageCache[path]=img or false
    return img
  end

  local function radarIcon(game,row)
    if type(row)~="table" then return nil,nil end
    -- Respect KIM's own POKEMON ICONS switch first.  When it is OFF, fall
    -- through to Dex Radar's native icon path instead of forcing KIM artwork.
    if type(mod._kantoInMotionHdMenuIconForModernUi)=="function" and row.id then
      local ok,path=pcall(mod._kantoInMotionHdMenuIconForModernUi,
        game,{species=row.id})
      if ok and path then
        local img=loadRadarImage(path)
        if img then return img,nil end
      end
    end
    local img=loadRadarImage(row.iconPath)
    if not img then return nil,nil end
    local iw,ih=img:getDimensions()
    if tostring(row.iconName or ""):sub(1,5)=="ICON_" and ih>=32
        and type(G.newQuad)=="function" then
      local ok,q=pcall(G.newQuad,0,0,math.min(16,iw),16,iw,ih)
      if ok then return img,q end
    end
    return img,nil
  end

  local function radarLevel(row)
    if type(row)~="table" then return "" end
    local lo,hi=tonumber(row.minLv),tonumber(row.maxLv)
    if not lo then return "" end
    if not hi or hi==lo then return ("L%d"):format(lo) end
    return ("L%d-%d"):format(lo,hi)
  end

  local function radarRate(row)
    if type(row)~="table" or row.rate==nil then return "" end
    local rate=tonumber(row.rate)
    if not rate then return "" end
    if row.todLabel then return ("RATE %d (%s)"):format(rate,tostring(row.todLabel)) end
    return ("RATE %d"):format(rate)
  end

  local function drawDexRadar(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh); local den=density()
    local w=math.min(1040*scale,sw*.78)
    local h=math.min(720*scale,sh*.88)
    if layoutStyle()=="full" then w=sw*.94; h=sh*.92; scale=math.min(w/1040,h/720) end
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2

    -- Keep Dex Radar feeling like the other Modern UI overlays rather than a
    -- replacement white GB screen.  Its source object is made non-opaque while
    -- this presenter is active so the live overworld remains behind the card.
    color({0,0,0,1},.24); G.rectangle("fill",sx,sy,sw,sh)
    panel(x,y,w,h,c,.97)

    local titleFont=font(36*scale)
    local body=font(25*scale)
    local small=font(18*scale)
    local tiny=font(16*scale)
    local pad=26*scale
    local headerH=94*scale
    local footerH=52*scale

    text("DEX RADAR",titleFont,x+pad,y+18*scale,w*.52,"left",c.text)
    local owned=("%d/%d OWNED"):format(tonumber(s.ownedN) or 0,tonumber(s.totalN) or 0)
    text(owned,small,x+w*.56,y+29*scale,w*.38-pad,"right",c.accent)
    text(tostring(s.mapLabel or "UNKNOWN"):upper(),small,x+pad,
      y+58*scale,w-pad*2,"left",c.muted)
    color(c.divider); G.rectangle("fill",x+pad,y+headerH-8*scale,w-pad*2,1)

    local listTop=y+headerH
    local listBottom=y+h-footerH
    local listH=math.max(1,listBottom-listTop)
    local sectionH=math.max(28*scale,small:getHeight()+10*scale)
    local rowH=math.max(64*scale,body:getHeight()+tiny:getHeight()+18*scale)
    local rows=s.rows or {}; local monIndex=s.monIndex or {}
    local cursor=math.max(1,math.min(#monIndex,tonumber(s.cursor) or 1))
    local selectedRaw=monIndex[cursor]

    local function rh(row) return row and row.kind=="header" and sectionH or rowH end
    local first,last=1,#rows
    if selectedRaw and #rows>0 then
      first,last=selectedRaw,selectedRaw
      local used=rh(rows[selectedRaw])
      while first>1 do
        local add=rh(rows[first-1]); if used+add>listH*.55 then break end
        first=first-1; used=used+add
      end
      while last<#rows do
        local add=rh(rows[last+1]); if used+add>listH then break end
        last=last+1; used=used+add
      end
      while first>1 do
        local add=rh(rows[first-1]); if used+add>listH then break end
        first=first-1; used=used+add
      end
    end

    local cursorByRaw={}
    for i,raw in ipairs(monIndex) do cursorByRaw[raw]=i end
    G.setScissor(x+10*scale,listTop,w-20*scale,listH)
    local yy=listTop+5*scale
    if #monIndex==0 then
      text("NO WILD POKEMON",body,x+pad,listTop+listH*.42,w-pad*2,"center",c.text)
    else
      for raw=first,last do
        local row=rows[raw]
        local height=rh(row)
        if row and row.kind=="header" then
          text(tostring(row.text or row.label or ""):upper(),small,
            x+pad,yy+(height-small:getHeight())/2,w-pad*2,"left",c.accent)
          color(c.divider); G.rectangle("fill",x+pad,yy+height-1,w-pad*2,1)
        elseif row then
          local selected=cursorByRaw[raw]==cursor
          local rx=x+14*scale; local rw=w-28*scale
          if selected then
            color(c.selected); G.rectangle("fill",rx,yy+2*scale,rw,height-4*scale,6,6)
            color(c.accent); G.rectangle("fill",rx,yy+2*scale,4*scale,height-4*scale,2,2)
          end
          local iconSize=math.min(48*scale,height-12*scale)
          local ix=x+pad; local iy=yy+(height-iconSize)/2
          local img,quad=radarIcon(s.game,row)
          if img then
            local iw,ih=img:getDimensions()
            local qw,qh=iw,ih
            if quad and quad.getViewport then
              local _,_,vw,vh=quad:getViewport(); qw,qh=vw,vh
            end
            local fit=math.min(iconSize/math.max(1,qw),iconSize/math.max(1,qh))
            color(row.seen==false and {0,0,0,1} or {1,1,1,1},nil,true)
            if quad then
              G.draw(img,quad,ix+(iconSize-qw*fit)/2,iy+(iconSize-qh*fit)/2,0,fit,fit)
            else
              G.draw(img,ix+(iconSize-iw*fit)/2,iy+(iconSize-ih*fit)/2,0,fit,fit)
            end
          else
            color(c.divider); G.rectangle("line",ix,iy,iconSize,iconSize,4,4)
          end
          local tx=ix+iconSize+16*scale
          local right=x+w-pad
          text(tostring(row.name or "?????"),body,tx,yy+8*scale,
            math.max(20,right-tx-150*scale),"left",selected and c.text or c.muted)
          local detail={}
          if s.showLevels~=false and row.seen~=false then
            local lv=radarLevel(row); if lv~="" then detail[#detail+1]=lv end
          end
          if s.showRates~=false and row.seen~=false then
            local rt=radarRate(row); if rt~="" then detail[#detail+1]=rt end
          end
          text(table.concat(detail,"   "),tiny,tx,
            yy+height-tiny:getHeight()-9*scale,
            math.max(20,right-tx-120*scale),"left",c.muted)
          if row.owned and row.seen~=false then
            text("OWNED",tiny,right-105*scale,
              yy+(height-tiny:getHeight())/2,100*scale,"right",c.accent)
          end
        end
        yy=yy+height
      end
    end
    G.setScissor()

    color(c.divider); G.rectangle("fill",x+pad,y+h-footerH,w-pad*2,1)
    fittedText("UP/DOWN/LEFT/RIGHT  MOVE    B  BACK",16*scale,x+pad,
      y+h-footerH+17*scale,w-pad*2,"left",c.accent)
    if first>1 then drawVerticalArrow(x+w-52*scale,listTop+4*scale,math.max(12*scale,body:getHeight()*.65),"up",c.accent) end
    if last<#rows then drawVerticalArrow(x+w-52*scale,listBottom-34*scale,math.max(12*scale,body:getHeight()*.65),"down",c.accent) end
  end


  ---------------------------------------------------------------------------
  -- Gen 2 PC / Storage + Evolution Modern UI

  local pcImageCache={}
  local function pcLoadImage(path)
    if type(path)~="string" or path=="" then return nil end
    if pcImageCache[path]~=nil then return pcImageCache[path] or nil end
    local ok,img=false,nil
    if mod.assets and type(mod.assets.image)=="function" then
      ok,img=pcall(mod.assets.image,mod.assets,path)
    end
    if (not ok or not img) and type(G.newImage)=="function" then
      ok,img=pcall(G.newImage,path)
    end
    if not ok or not img then pcImageCache[path]=false; return nil end
    if img.setFilter then pcall(img.setFilter,img,"linear","linear") end
    pcImageCache[path]=img
    return img
  end
  local function pcHdIcon(game,mon)
    if type(mon)~="table" then return nil end
    local provider=mod._kantoInMotionHdMenuIconForModernUi
    if type(provider)=="function" then
      local ok,path=pcall(provider,game,mon)
      local img=ok and pcLoadImage(path) or nil
      if img then return img end
    end

    -- Hard fallback for a live Gen 2 storage record.  The shared provider is
    -- normally authoritative, but evolved/legacy records can lack the helper
    -- id it was handed.  The actual species row is still enough to find the
    -- National Dex asset, so do not leave an empty slot in Modern PC UI.
    local data=game and game.data
    local def=data and data.pokemon and mon.species and data.pokemon[mon.species]
    local dex=def and tonumber(def.nationalDex or def.dex or def.index) or nil
    if not (dex and dex>=1 and dex<=386) then
      local key=tostring(mon.species or mon.name or ""):upper():gsub("[^A-Z0-9]+","_"):gsub("_+","_")
      local johto={CYNDAQUIL=155,QUILAVA=156,TYPHLOSION=157}
      dex=johto[key]
    end
    if not (dex and dex>=1 and dex<=386) then return nil end
    local stem=string.format("%03d",math.floor(dex))
    if mon.shiny==true then
      local img=pcLoadImage("assets/menu_icons/hd/shiny/"..stem..".png")
      if img then return img end
    end
    return pcLoadImage("assets/menu_icons/hd/normal/"..stem..".png")
  end
  local function pcFullSprite(mon)
    if type(mon)~="table" or not (mod.exports and type(mod.exports.getSprite)=="function") then return nil end
    local ok,img=pcall(mod.exports.getSprite,mon.species,{generation="hd",mon=mon,side="front"})
    return ok and img or nil
  end
  local function drawFitImage(img,x,y,w,h,maxScale)
    if not img or type(img.getDimensions)~="function" then return false end
    local iw,ih=img:getDimensions(); iw,ih=math.max(1,iw or 1),math.max(1,ih or 1)
    local sc=math.min(w/iw,h/ih,tonumber(maxScale) or math.huge)
    color({1,1,1,1}); G.draw(img,x+(w-iw*sc)/2,y+(h-ih*sc)/2,0,sc,sc)
    return true
  end
  local function pcMonName(s,mon)
    if type(mon)~="table" then return "POKéMON" end
    local def=s and s.game and s.game.data and s.game.data.pokemon and s.game.data.pokemon[mon.species]
    return tostring(mon.nickname or mon.name or (def and def.name) or mon.species or "POKéMON")
  end
  local function pcGender(s,mon)
    if type(mon)~="table" then return nil end
    local g=mon.gender
    if g=="M" or g=="male" or g==0 then return "male" end
    if g=="F" or g=="female" or g==1 then return "female" end
    if okGen2Mon and Gen2Mon and type(Gen2Mon.gender)=="function" and type(mon.dvs)=="table" then
      local def=s and s.game and s.game.data and s.game.data.pokemon and s.game.data.pokemon[mon.species]
      if def then
        local ok,v=pcall(Gen2Mon.gender,def,mon.dvs,{species=mon.species,level=mon.level})
        if ok and (v=="male" or v=="female") then return v end
      end
    end
    return nil
  end
  local function pcGenderSymbol(cx,cy,size,g,c)
    size=math.max(7,tonumber(size) or 10)
    color(c,nil,true); G.setLineWidth(math.max(1,size*.12))
    local r=size*.22
    if g=="male" then
      local ox,oy=cx-size*.10,cy+size*.08
      G.circle("line",ox,oy,r)
      local ex,ey=cx+size*.34,cy-size*.34
      G.line(ox+r*.72,oy-r*.72,ex,ey)
      G.line(ex-size*.18,ey,ex,ey,ex,ey+size*.18)
    elseif g=="female" then
      local ox,oy=cx,cy-size*.12
      G.circle("line",ox,oy,r)
      local stemTop=oy+r; local stemBottom=cy+size*.34
      G.line(ox,stemTop,ox,stemBottom)
      G.line(ox-size*.18,cy+size*.16,ox+size*.18,cy+size*.16)
    end
  end
  local function drawPcHeader(x,y,w,scale,c,title,subtitle)
    local tf=font(34*scale); local sf=font(18*scale)
    text(title or "PC",tf,x+20*scale,y+14*scale,w-40*scale,"left",c.text)
    if subtitle and subtitle~="" then
      text(subtitle,sf,x+20*scale,y+52*scale,w-40*scale,"left",c.muted)
    end
  end
  local function drawPcRows(x,y,w,h,rows,selected,scale,c)
    local f=font(24*scale); local small=font(18*scale)
    local n=math.max(1,#rows); local rh=math.min(58*scale,h/n)
    for i,row in ipairs(rows) do
      local yy=y+(i-1)*rh
      local sel=i==selected
      if sel then color(c.selected,.96); G.rectangle("fill",x,yy,w,rh-4*scale,5,5) end
      local label=type(row)=="table" and (row.label or row.text or row.name) or row
      text(normalizeUiText(label),f,x+15*scale,yy+(rh-f:getHeight())*.45,w-30*scale,"left",sel and c.text or c.muted)
      if type(row)=="table" and row.right then
        text(tostring(row.right),small,x+w*.62,yy+(rh-small:getHeight())*.48,w*.34,"right",sel and c.text or c.muted)
      end
    end
  end

  local function drawCenterPc(s)
    local c=theme(); local sx,sy,sw,sh=playfield(); local scale=uiScale(sw,sh)
    local w=math.min(sw*.62,680*scale); local h=math.min(sh*.72,520*scale)
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2; panel(x,y,w,h,c,.96)
    drawPcHeader(x,y,w,scale,c,"PC","Access whose PC?")
    local body=font(24*scale); local small=font(18*scale)
    if s.message then
      local lines
      if okTyper and Typer and type(Typer.text)=="function" and type(s.message)=="table" then
        local page=s.message.pages and s.message.pages[s.message.page or 1]
        local ok,v=pcall(Typer.text,s,page); if ok then lines=v end
      end
      if type(lines)~="table" then
        local page=type(s.message)=="table" and s.message.pages and s.message.pages[s.message.page or 1]
        lines=type(page)=="table" and page or {tostring(page or "")}
      end
      text(table.concat(lines,"\n"),body,x+30*scale,y+110*scale,w-60*scale,"left",c.text)
      text("A / B  continue",small,x+30*scale,y+h-48*scale,w-60*scale,"right",c.muted)
      return
    end
    if s.confirm then
      local prompt=type(s.confirm.prompt)=="table" and table.concat(s.confirm.prompt,"\n") or tostring(s.confirm.prompt or "")
      text(prompt,body,x+30*scale,y+105*scale,w-60*scale,"left",c.text)
      local labels={"YES","NO"}; local bw=(w-80*scale)/2
      for i,label in ipairs(labels) do
        local bx=x+30*scale+(i-1)*(bw+20*scale); local by=y+h-120*scale
        color((s.confirm.choice or 1)==i and c.selected or c.raised)
        G.rectangle("fill",bx,by,bw,58*scale,5,5)
        text(label,body,bx,by+(58*scale-body:getHeight())*.45,bw,"center",c.text)
      end
      return
    end
    local rows={}
    for _,e in ipairs(s.entries or {}) do rows[#rows+1]={label=e.label or e.id} end
    drawPcRows(x+24*scale,y+92*scale,w-48*scale,h-150*scale,rows,s.index or 1,scale,c)
    text("D-PAD  move    A  select    B  back",small,x+24*scale,y+h-40*scale,w-48*scale,"center",c.muted)
  end

  local function drawPcMenuModern(s)
    local c=theme(); local sx,sy,sw,sh=playfield(); local scale=uiScale(sw,sh)
    local w=math.min(sw*.64,720*scale); local h=math.min(sh*.78,570*scale)
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2; panel(x,y,w,h,c,.96)
    drawPcHeader(x,y,w,scale,c,"BILL'S PC","POKéMON Storage System")
    local body=font(23*scale); local small=font(18*scale)
    if s.message then
      text(normalizeUiText(s.message),body,x+28*scale,y+115*scale,w-56*scale,"left",c.text)
      text("A / B  continue",small,x+28*scale,y+h-44*scale,w-56*scale,"right",c.muted)
      return
    end
    if s.picking then
      local rows={}; local total=(okBoxes and Boxes and Boxes.NUM_BOXES) or 14
      local first=math.max(1,math.min(total-5,(tonumber(s.pickIndex) or 1)-2))
      for i=first,math.min(total,first+5) do
        local name=(okBoxes and Boxes and type(Boxes.name)=="function") and Boxes.name(s.save,i) or ("BOX "..i)
        local count=(okBoxes and Boxes and type(Boxes.count)=="function") and Boxes.count(s.save,i) or 0
        local cap=(okBoxes and Boxes and Boxes.MONS_PER_BOX) or 20
        rows[#rows+1]={label=name,right=("%d/%d"):format(count,cap),_index=i}
      end
      local sel=1
      for i,r in ipairs(rows) do if r._index==(s.pickIndex or 1) then sel=i break end end
      drawPcRows(x+28*scale,y+94*scale,w-56*scale,h-165*scale,rows,sel,scale,c)
      if s.savePhase then
        local mh=150*scale; local my=y+h-mh-18*scale
        color(c.surface,.98); G.rectangle("fill",x+22*scale,my,w-44*scale,mh,7,7)
        local prompt=type(s.savePrompt)=="function" and s:savePrompt() or {"Save before changing BOX?"}
        if type(prompt)=="table" then prompt=table.concat(prompt,"\n") end
        text(prompt,small,x+40*scale,my+20*scale,w-80*scale,"left",c.text)
        if type(s.saveYesNoVisible)=="function" and s:saveYesNoVisible() then
          text((s.saveChoice or 1)==1 and "> YES     NO" or "  YES   > NO",body,x+40*scale,my+85*scale,w-80*scale,"center",c.accent)
        end
      else
        text("Which BOX?",small,x+28*scale,y+h-44*scale,w-56*scale,"left",c.muted)
      end
      return
    end
    local rows={}
    for _,e in ipairs(s.entries or {}) do
      local label=e.builtin and okStrings and Strings and Strings(e.label) or e.label or e.id
      rows[#rows+1]={label=label}
    end
    drawPcRows(x+28*scale,y+94*scale,w-56*scale,h-160*scale,rows,s.index or 1,scale,c)
    text("A  select    B  back",small,x+28*scale,y+h-42*scale,w-56*scale,"center",c.muted)
  end

  local function drawBoxPcModern(s)
    local c=theme(); local sx,sy,sw,sh=playfield(); local scale=uiScale(sw,sh)
    local w=math.min(sw*.78,980*scale); local h=math.min(sh*.82,620*scale)
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2; panel(x,y,w,h,c,.96)
    local title=type(s.title)=="function" and s:title() or "POKéMON STORAGE"
    drawPcHeader(x,y,w,scale,c,normalizeUiText(title),normalizeUiText(type(s.prompt)=="function" and s:prompt() or "Choose a POKéMON."))
    local body=font(22*scale); local small=font(17*scale); local tiny=font(15*scale)
    local listX=x+22*scale; local listY=y+92*scale; local listW=w*.49; local listH=h-150*scale
    local detailX=x+w*.52; local detailW=w*.45
    color(c.divider,.65); G.rectangle("fill",x+w*.505,listY,1,listH)
    local list=type(s.list)=="function" and s:list() or {}
    local first=(tonumber(s.scroll) or 0)+1; local rows=6; local rh=listH/rows
    for r=1,rows do
      local i=first+r-1; local mon=list[i]; local yy=listY+(r-1)*rh
      local isCancel=(not mon and type(s.total)=="function" and i==s:total())
      if mon or isCancel then
        local sel=i==(s.index or 1)
        if sel then color(c.selected,.96); G.rectangle("fill",listX,yy,listW,rh-4*scale,5,5) end
        if mon then
          local icon=pcHdIcon(s.game,mon); local isz=math.min(42*scale,rh-8*scale)
          if icon then drawFitImage(icon,listX+7*scale,yy+(rh-isz)/2,isz,isz,1.7) end
          text(pcMonName(s,mon),body,listX+56*scale,yy+(rh-body:getHeight())*.42,listW-64*scale,"left",sel and c.text or c.muted)
        else
          text("CANCEL",body,listX+18*scale,yy+(rh-body:getHeight())*.42,listW-36*scale,"left",sel and c.text or c.muted)
        end
      end
    end
    local mon=type(s.selected)=="function" and s:selected() or nil
    if mon then
      local preview=pcFullSprite(mon)
      local box=math.min(detailW*.48,150*scale)
      if preview then drawFitImage(preview,detailX+(detailW-box)/2,listY+4*scale,box,box) end
      local ty=listY+box+12*scale
      text(pcMonName(s,mon),body,detailX,ty,detailW,"center",c.text); ty=ty+30*scale
      local levelText=("Lv %d"):format(tonumber(mon.level) or 1)
      text(levelText,small,detailX,ty,detailW*.48,"left",c.muted)
      local gender=pcGender(s,mon)
      if gender then
        local symbolSize=small:getHeight()*.78
        local gx=detailX+small:getWidth(levelText)+7*scale+symbolSize*.36
        local gy=ty+small:getHeight()*.50
        local gc=(gender=="male") and {0.28,0.66,1,1} or {1,0.40,0.66,1}
        pcGenderSymbol(gx,gy,symbolSize,gender,gc)
      end
      local hp=tonumber(mon.hp) or 0; local maxHp=tonumber(mon.maxHp or (mon.stats and mon.stats.hp)) or hp
      text(("HP %d/%d"):format(hp,maxHp),small,detailX+detailW*.48,ty,detailW*.52,"right",c.text); ty=ty+29*scale
      for _,mv in ipairs(mon.moves or {}) do
        local id=type(mv)=="table" and mv.id or mv
        local def=s.game and s.game.data and s.game.data.moves and s.game.data.moves[id]
        text(tostring((def and def.name) or id or ""),tiny,detailX+8*scale,ty,detailW-16*scale,"left",c.muted)
        ty=ty+22*scale
      end
    end
    if s.phase=="submenu" and type(s.submenuRows)=="function" then
      local subs=s:submenuRows(); local mw=math.min(260*scale,w*.30); local mh=#subs*48*scale+28*scale
      local mx=x+w-mw-24*scale; local my=y+105*scale
      panel(mx,my,mw,mh,c,.99)
      drawPcRows(mx+10*scale,my+12*scale,mw-20*scale,mh-24*scale,subs,s.submenuIndex or 1,scale,c)
    end
    if s.message then
      local mw=w*.64; local mh=125*scale; local mx=x+(w-mw)/2; local my=y+h-mh-18*scale
      panel(mx,my,mw,mh,c,.99); text(normalizeUiText(s.message),small,mx+22*scale,my+20*scale,mw-44*scale,"left",c.text)
    else
      text("A  select    B  back",small,x+24*scale,y+h-42*scale,w-48*scale,"center",c.muted)
    end
  end

  local function gen2EvolutionSprite(s,species)
    if not species or not (mod.exports and type(mod.exports.getSprite)=="function") then return nil end
    local mon={}
    if type(s.mon)=="table" then for k,v in pairs(s.mon) do mon[k]=v end end
    mon.species=species
    local ok,img=pcall(mod.exports.getSprite,species,{generation="hd",mon=mon,side="front"})
    return ok and img or nil
  end
  local function drawGen2Evolution(s)
    local c=theme(); local sx,sy,sw,sh=playfield(); local scale=uiScale(sw,sh)
    local w=math.min(sw*.58,720*scale); local h=math.min(sh*.70,520*scale)
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2; panel(x,y,w,h,c,.96)
    drawPcHeader(x,y,w,scale,c,"EVOLUTION",s.force and "Evolution cannot be stopped" or "B  stop evolution")
    local species=s.showNew and s.newSpecies or s.oldSpecies
    if s.phase=="reveal" or s.phase=="picAnim" or s.phase=="congrats" or s.phase=="paragraph" or s.phase=="evolved" then
      if not s.canceled then species=s.newSpecies end
    end
    local img=gen2EvolutionSprite(s,species)
    local art=math.min(w*.48,h*.48)
    if img and s.phase~="learn" then drawFitImage(img,x+(w-art)/2,y+92*scale,art,art) end
    if type(s.balls)=="table" and #s.balls>0 then
      color(c.accent,.9,true)
      local cx=x+w/2; local cy=y+92*scale+art/2
      for i,b in ipairs(s.balls) do
        if i<=10 then G.circle("fill",cx+(tonumber(b.x) or 0)*scale*.7,cy+(tonumber(b.y) or 0)*scale*.7,math.max(2,3*scale)) end
      end
    end
    local body=font(23*scale); local small=font(17*scale)
    local msg=type(s.lines)=="table" and table.concat(s.lines,"\n") or ""
    if msg~="" then
      local my=y+h-145*scale; color(c.raised,.92); G.rectangle("fill",x+24*scale,my,w-48*scale,92*scale,6,6)
      text(msg,body,x+42*scale,my+18*scale,w-84*scale,"left",c.text)
    else
      text("Evolution in progress…",small,x+30*scale,y+h-72*scale,w-60*scale,"center",c.muted)
    end
  end

  local function syncDexRadarOpacity(game)
    local states=game and game.stack and game.stack.states
    if type(states)~="table" then return end
    local modern=presenterEnabled("menu") and hideOriginal()
    for _,state in ipairs(states) do
      if isDexRadarState(state) then
        if rawget(state,"_kimDexRadarOriginalOpaque")==nil then
          rawset(state,"_kimDexRadarOriginalOpaque",state.isOpaque~=false)
        end
        state.isOpaque=modern and false
          or (rawget(state,"_kimDexRadarOriginalOpaque")~=false)
      end
    end
  end

  local renderers={
    titlemenu=drawTitleMainMenu,start=drawStart,pack=drawPack,gear=drawGear,card=drawCard,
    centerpc=drawCenterPc,pc=drawPcMenuModern,boxpc=drawBoxPcModern,evolution=drawGen2Evolution,
    save=drawSave,options=drawOptions,modoptions=drawModOptions,
    kimsettings=drawKimSettings,dexradar=drawDexRadar,
  }

  -- Gen 1 parity: LEFT/RIGHT can jump five Start Menu rows when enabled.
  if StartMenu and type(StartMenu.update)=="function" and not StartMenu.__kimFastJumpWrapped then
    local oldStartUpdate=StartMenu.update
    StartMenu.update=function(self,dt,...)
      pruneStartMapRow(self)
      if presenterEnabled("menu") and opt("startMenuFastJump",true)~=false
          and self and self.list and type(self.items)=="table" then
        local input=self.game and self.game.input
        local delta=0
        if input and input:wasPressed("left") then delta=-5
        elseif input and input:wasPressed("right") then delta=5 end
        if delta~=0 and #self.items>0 then
          local idx=math.max(1,math.min(#self.items,(tonumber(self.list.index) or 1)+delta))
          self.list.index=idx
          local scroll=tonumber(self.list.scroll) or 0
          local visible=9
          if idx<=scroll then scroll=idx-1 end
          if idx>scroll+visible then scroll=idx-visible end
          self.list.scroll=math.max(0,math.min(scroll,math.max(0,#self.items-visible)))
          return
        end
      end
      return oldStartUpdate(self,dt,...)
    end
    StartMenu.__kimFastJumpWrapped=true
  end

  if mod.hooks and type(mod.hooks.wrap)=="function" then
    -- Dex Radar declares itself opaque because its native presentation is a
    -- full 160x144 white screen.  Flip only that live state to non-opaque while
    -- KIM owns the Modern presenter, before the render pass selects visible
    -- stack layers.  Switching Modern UI/MENU UI off restores its source value.
    mod.hooks:wrap("input.step",function(nextFn,game,dt)
      syncDexRadarOpacity(game)
      local result={pcall(nextFn,game,dt)}
      local ok=table.remove(result,1)
      syncDexRadarOpacity(game)
      if not ok then error(result[1],0) end
      return (table.unpack or unpack)(result)
    end,100000)

    mod.hooks:wrap("ui.start_menu.items",function(nextFn,game,items)
      local rows=nextFn(game,items)
      if not presenterEnabled("menu") then return rows end
      if type(rows)~="table" then return rows end
      local out={}
      for _,row in ipairs(rows) do
        -- KIM removes only the redundant MAP row. Keep Gen1Recomp's MODS row
        -- intact so the full Mod Manager remains reachable from the Start Menu.
        if not startRowIsMap(row) then out[#out+1]=row end
      end
      return out
    end,100000)
    local function presenterForKind(kind)
      if kind=="card" or kind=="boxpc" or kind=="evolution" then return "pokemon" end
      if kind=="kimsettings" or kind=="modoptions" then return "manager" end
      return "menu"
    end
    mod.hooks:wrap("screen.render_visible",function(nextFn,state)
      -- Evolution is presented as a floating Modern window over the live field.
      -- Post-battle evolution is pushed above BattleState, so merely hiding the
      -- EvolutionAnim pixels would otherwise leave the battle screen underneath.
      -- While EvolutionAnim itself is the top state, hide the lower stack states
      -- from this render pass as well; their update/state ownership is untouched.
      local game=type(state)=="table" and state.game or nil
      local stack=game and game.stack
      local top=stack and type(stack.top)=="function" and stack:top() or nil
      if top and top~=state and target(top)=="evolution"
          and presenterEnabled("pokemon") and hideOriginal() then
        return false
      end
      local kind=target(state)
      if kind=="dexradar" and type(state)=="table" then
        if rawget(state,"_kimDexRadarOriginalOpaque")==nil then
          rawset(state,"_kimDexRadarOriginalOpaque",state.isOpaque~=false)
        end
        state.isOpaque=not (presenterEnabled("menu") and hideOriginal())
          and (rawget(state,"_kimDexRadarOriginalOpaque")~=false) or false
      end
      if kind and presenterEnabled(presenterForKind(kind)) and hideOriginal() then return false end
      return nextFn(state)
    end,100000)
    mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
      local result={pcall(nextFn,game,viewport)}; local ok=table.remove(result,1)
      if not ok then error(result[1],0) end
      local top=game and game.stack and type(game.stack.top)=="function" and game.stack:top()
      local kind=target(top)
      if kind and presenterEnabled(presenterForKind(kind)) then
        G.push("all"); G.origin(); pcall(renderers[kind],top); G.pop()
      end
      return unpack(result)
    end,100000)
  end

  mod.exports.gen2ModernCoreMenus={apiVersion=1}
  return true
end
