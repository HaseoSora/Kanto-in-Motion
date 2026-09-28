-- Kanto in Motion v1.5.2 - Gen 2 Modern Core Menus v27 -- 23
--
-- Modern overlay presentation for the native Gen 2 Start Menu, Pack,
-- Pokegear, Trainer Card, Save Menu, Options Menu and KIM Mod Settings. Their original objects remain authoritative for
-- input, state transitions, item logic, calls/maps/radio and page navigation.
return function(mod)
  local G=love.graphics
  local okChrome,Chrome=pcall(require,"src.ui.gen2.Chrome")
  local okStart,StartMenu=pcall(require,"src.ui.gen2.StartMenu")
  local okPack,PackMenu=pcall(require,"src.ui.gen2.PackMenu")
  local okGear,Pokegear=pcall(require,"src.ui.gen2.Pokegear")
  local okCard,TrainerCard=pcall(require,"src.ui.gen2.TrainerCard")
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

  local FONT_PATH="assets/fonts/plainpixel/PlainPixel-Regular.ttf"
  local fonts={}
  local FALLBACK={
    surface={.075,.105,.17,.96},raised={.12,.17,.27,.94},
    selected={.18,.43,.72,.96},accent={.48,.86,1,1},
    frame={.48,.86,1,1},frameShadow={.01,.02,.04,.42},
    text={.96,.98,1,1},muted={.74,.82,.92,1},divider={.38,.5,.68,.94},
  }
  local function opt(k,d)
    if not(mod.options and mod.options.get) then return d end
    local ok,v=pcall(mod.options.get,mod.options,k); return ok and v~=nil and v or d
  end
  local function enabled() return opt("gen2IntegratedModernUi",true)~=false end
  local function theme()
    local t=mod._kantoInMotionGen2Themes
    return type(t)=="table" and (t[tostring(opt("gen2UiTheme","default"))] or t.default) or FALLBACK
  end
  local function color(c,a)
    c=c or {1,1,1,1}; G.setColor(c[1],c[2],c[3],a==nil and (c[4] or 1) or a)
  end
  local function font(px)
    px=math.max(8,math.floor(px+.5)); if fonts[px] then return fonts[px] end
    local ok,f=pcall(G.newFont,FONT_PATH,px,"mono",1); if not ok then ok,f=pcall(G.newFont,px) end
    if ok and f then if f.setFilter then pcall(f.setFilter,f,"nearest","nearest") end fonts[px]=f return f end
    return G.getFont()
  end
  local function text(s,f,x,y,w,align,c)
    G.setFont(f); color(c); s=tostring(s or "")
    if w then
      local ok=pcall(G.printf,s,x,y,w,align or "left")
      if not ok then G.printf(s:gsub("[\128-\255]","?"),x,y,w,align or "left") end
    else G.print(s,x,y) end
  end
  local function boldText(s,f,x,y,c)
    G.setFont(f); color(c); s=tostring(s or "")
    -- PlainPixel has one weight, so double-strike by one pixel to make
    -- controller button glyphs read like the bold prompts in Modern UI.
    G.print(s,x,y)
    G.print(s,x+1,y)
  end
  local function playfield()
    local ww,wh=G.getDimensions()
    if okChrome and Chrome and type(Chrome.playfieldRect)=="function" then
      local ok,x,y,w,h=pcall(Chrome.playfieldRect,ww,wh)
      if ok and w and h and w>0 and h>0 then return x,y,w,h end
    end
    return 0,0,ww,wh
  end
  local function panel(x,y,w,h,c,alpha)
    local r=math.max(8,math.min(w,h)*.018)
    color(c.frameShadow or {0,0,0,.4},.18); G.rectangle("fill",x+2,y+3,w,h,r,r)
    color(c.surface,math.min(1,(c.surface[4] or 1)*(alpha or .94))); G.rectangle("fill",x,y,w,h,r,r)
    color(c.frame or c.accent); G.setLineWidth(math.max(2,math.min(w,h)*.0045)); G.rectangle("line",x,y,w,h,r,r)
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
      if i==selected then color(c.selected); G.rectangle("fill",mx+12,yy,mw-24,rh-4,5,5) end
      text(row,small,mx+24,yy+8,mw-48,"left",i==selected and c.text or c.muted)
    end
  end

  local function makeTransparent(Class)
    if not Class or Class.__kimModernTransparent then return end
    local oldNew=Class.new
    if type(oldNew)=="function" then
      Class.new=function(...)
        local self=oldNew(...)
        if enabled() and type(self)=="table" then self.isOpaque=false end
        return self
      end
    end
    local oldUpdate=Class.update
    if type(oldUpdate)=="function" then
      Class.update=function(self,...)
        self.isOpaque=not enabled()
        return oldUpdate(self,...)
      end
    end
    Class.__kimModernTransparent=true
  end
  makeTransparent(PackMenu); makeTransparent(Pokegear); makeTransparent(TrainerCard)
  makeTransparent(SaveMenu); makeTransparent(OptionsMenu)

  -- The category pages created by OptionsMenu's local pushGroup() still use
  -- OptionsMenu:drawsWidescreen().  Disable that path only while KIM owns
  -- Modern UI so every OPTION submenu reaches the same final-window overlay.
  if OptionsMenu and type(OptionsMenu.drawsWidescreen)=="function"
      and not OptionsMenu.__kimModernWideWrapped then
    local oldDrawsWidescreen=OptionsMenu.drawsWidescreen
    OptionsMenu.drawsWidescreen=function(self,...)
      if enabled() then return false end
      return oldDrawsWidescreen(self,...)
    end
    OptionsMenu.__kimModernWideWrapped=true
  end

  local function isClass(s,Class) return type(s)=="table" and getmetatable(s)==Class end
  local function target(s)
    if isClass(s,StartMenu) then return "start" end
    if isClass(s,PackMenu) then return "pack" end
    if isClass(s,Pokegear) then return "gear" end
    if isClass(s,TrainerCard) then return "card" end
    if isClass(s,SaveMenu) then return "save" end
    if isClass(s,OptionsMenu) then return "options" end
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

  local function drawStart(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=math.max(.9,math.min(1.35,sh/720))
    local rows=s.items or {}; local count=#rows
    local w=math.min(520*scale,sw*.40); local rh=60*scale
    local h=math.min(sh*.88,94*scale+math.min(count,9)*rh+76*scale)
    local x=sx+sw-w-28*scale; local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.95)
    local big, body, small = font(40*scale), font(31*scale), font(23*scale)
    text("START",big,x+18*scale,y+15*scale,w-36*scale,"left",c.text)
    local index=(s.list and tonumber(s.list.index)) or 1
    local scroll=(s.list and tonumber(s.list.scroll)) or 0
    local maxRows=math.max(1,math.floor((h-165*scale)/rh))
    for slot=1,maxRows do
      local i=scroll+slot; local row=rows[i]; if not row then break end
      local yy=y+70*scale+(slot-1)*rh
      if i==index then color(c.selected); G.rectangle("fill",x+12*scale,yy,w-24*scale,rh-5*scale,5,5) end
      local label = row.label or row.value or "OPTION"
      if tostring(row.value or row.id or ""):lower() == "pokegear" then
        label = "POKéGEAR"
      end
      text(label,body,x+28*scale,yy+11*scale,w-56*scale,"left",i==index and c.text or c.muted)
    end
    local row=rows[index]; local desc=row and row.desc or {}
    color(c.divider); G.rectangle("fill",x+16*scale,y+h-86*scale,w-32*scale,1)
    text(type(desc)=="table" and table.concat(desc,"  ") or "",small,x+18*scale,y+h-66*scale,w-36*scale,"left",c.muted)
    if s.phase=="confirm" or s.phase=="confirmContest" then
      modal(x,y,w,h,c,s.phase=="confirm" and "Return to the title screen?" or "End the Contest?",
        {"YES","NO"},tonumber(s.confirmChoice) or 2,body,small)
    end
  end

  local POCKET_LABELS={"ITEMS","POKé BALLS","KEY ITEMS","TM/HM"}
  local function itemDescription(s,row)
    local def=row and s.items and s.items[row.id]
    local d=def and def.description
    if type(d)=="table" then return table.concat(d," ") end
    return tostring(d or "")
  end
  local function drawPack(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local w=math.min(1080,sw*.64); local h=math.min(690,sh*.76)
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2; panel(x,y,w,h,c,.95)
    local scale=math.max(.95,math.min(1.5,w/900))
    local big, body, small = font(35*scale), font(26*scale), font(19*scale)
    local tabFont = font(23*scale)
    local countFont = font(22*scale)
    local footerFont = font(21*scale)
    local buttonFont = font(23*scale)
    local pad=22*scale
    text("PACK",big,x+pad,y+15*scale,w*.32,"left",c.text)

    local tabW=(w-pad*2)/4
    for i,label in ipairs(POCKET_LABELS) do
      local tx=x+pad+(i-1)*tabW; local sel=i==(tonumber(s.pocketIndex) or 1)
      if sel then color(c.selected); G.rectangle("fill",tx,y+56*scale,tabW-4,42*scale,5,5) end
      text(label,tabFont,tx+4,y+64*scale,tabW-10,"center",sel and c.text or c.muted)
    end

    local contentY=y+112*scale; local contentH=h-176*scale
    local listW=w*.57; local detailX=x+listW+16*scale
    color(c.divider); G.rectangle("fill",x+listW+8*scale,contentY,1,contentH)
    local rows=s.rows or {}; local idx=tonumber(s.index) or 1; local scroll=tonumber(s.scroll) or 0
    local visible=8; local rh=contentH/visible
    for slot=1,visible do
      local i=scroll+slot; local row=rows[i]
      if i==#rows+1 then row={name="CANCEL"} end
      if not row then break end
      local yy=contentY+(slot-1)*rh; local sel=i==idx
      if sel then color(c.selected); G.rectangle("fill",x+pad*.65,yy,listW-pad*1.2,rh-4,5,5) end
      text(row.name or "CANCEL",body,x+pad,yy+12*scale,listW*.62,"left",sel and c.text or c.muted)
      local right=row.teaches or (row.showCount and ("x"..tostring(row.count or 0))) or ""
      text(right,countFont,x+listW*.65,yy+9*scale,listW*.27,"right",sel and c.text or c.muted)
    end
    local selected=idx<=#rows and rows[idx] or nil
    text(selected and selected.name or "CANCEL",big,detailX,contentY+12*scale,w-listW-40*scale,"left",c.text)
    text(itemDescription(s,selected),body,detailX,contentY+78*scale,w-listW-40*scale,"left",c.muted)
    local footerY = y+h-62*scale
    local fx = detailX
    text("←/→ POCKET",footerFont,fx,footerY,nil,nil,c.accent)
    fx = fx + footerFont:getWidth("←/→ POCKET") + 18*scale
    boldText("A",buttonFont,fx,footerY-1*scale,c.accent)
    fx = fx + buttonFont:getWidth("A") + 5*scale
    text("CHOOSE",footerFont,fx,footerY,nil,nil,c.accent)
    fx = fx + footerFont:getWidth("CHOOSE") + 18*scale
    boldText("B",buttonFont,fx,footerY-1*scale,c.accent)
    fx = fx + buttonFont:getWidth("B") + 5*scale
    text("BACK",footerFont,fx,footerY,nil,nil,c.accent)

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

  local JOHTO={"ZEPHYR","HIVE","PLAIN","FOG","STORM","MINERAL","GLACIER","RISING"}
  local KANTO={"BOULDER","CASCADE","THUNDER","RAINBOW","SOUL","MARSH","VOLCANO","EARTH"}
  local function badgeOwned(tbl,name,i) return type(tbl)=="table" and (tbl[name]==true or tbl[i]==true) end
  local function drawCard(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local w=math.min(940,sw*.58); local h=math.min(620,sh*.70)
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2; panel(x,y,w,h,c,.95)
    local scale=math.max(.95,math.min(1.45,w/850))
    local big, body, small = font(35*scale), font(26*scale), font(20*scale)
    local pageFont = font(23*scale)
    local footerFont = font(22*scale)
    local save=s.save or {}; local player=save.player or {}; local page=tonumber(s.page) or 1
    local pageCount=(player.kantoBadges and next(player.kantoBadges)) and 3 or 2
    text("TRAINER CARD",big,x+24*scale,y+20*scale,w*.55,"left",c.text)
    text(("PAGE %d / %d"):format(page,pageCount),pageFont,x+w*.56,y+22*scale,w*.38,"right",c.accent)
    local contentY=y+96*scale
    if page==1 then
      local pd=save.pokedex or {}; local pt=save.playTime or {}
      local rows={
        {"NAME",player.name or "GOLD"},
        {"ID No.",("%05d"):format(tonumber(player.id) or 0)},
        {"MONEY",tostring(player.money or 0)},
        {"POKéDEX",tostring((function() local n=0 for _,v in pairs(pd.caught or {}) do if v then n=n+1 end end return n end)())},
        {"PLAY TIME",("%d:%02d"):format(pt.hours or 0,pt.minutes or 0)},
      }
      for i,r in ipairs(rows) do
        local yy=contentY+(i-1)*68*scale
        text(r[1],body,x+45*scale,yy,w*.35,"left",c.muted)
        text(r[2],body,x+w*.48,yy,w*.42,"right",c.text)
      end
    else
      local names=page==2 and JOHTO or KANTO
      local owned=page==2 and player.badges or player.kantoBadges
      local colW=(w-80*scale)/2
      for i,name in ipairs(names) do
        local col=(i-1)%2; local row=math.floor((i-1)/2)
        local bx=x+40*scale+col*colW; local by=contentY+row*88*scale
        local yes=badgeOwned(owned,name,i)
        color(yes and c.selected or c.raised); G.rectangle("fill",bx,by,colW-14*scale,66*scale,6,6)
        text(name,body,bx+12*scale,by+17*scale,colW-28*scale,"left",yes and c.text or c.muted)
        text(yes and "EARNED" or "----",small,bx+12*scale,by+43*scale,colW-28*scale,"right",yes and c.accent or c.muted)
      end
    end
    text("←/→ PAGE   A NEXT   B/START BACK",footerFont,x+24*scale,y+h-54*scale,w-48*scale,"left",c.muted)
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
    local w=math.min(1080,sw*.64); local h=math.min(680,sh*.74)
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2; panel(x,y,w,h,c,.95)
    local scale=math.max(.95,math.min(1.45,w/900))
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
      text("←/→ CARD   A OPEN   B BACK",small,x+36*scale,y+h-52*scale,w-72*scale,"center",c.muted)
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
    text("B RETURN   ←/→ CARD",footerFont,x+36*scale,y+h-58*scale,w-72*scale,"center",c.muted)
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
    local scale=math.max(.9,math.min(1.45,sh/760))
    local w=math.min(980*scale,sw*.62)
    local h=math.min(610*scale,sh*.72)
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
    local scale=math.max(.88,math.min(1.42,sh/760))
    local w=math.min(1080*scale,sw*.66)
    local h=math.min(700*scale,sh*.78)
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.97)

    local big=font(38*scale)
    local body=font(26*scale)
    local valueFont=font(23*scale)
    local small=font(19*scale)

    text(s.sub and "OPTIONS" or "OPTIONS",big,x+28*scale,y+18*scale,w*.55,"left",c.text)
    text(s.sub and "CATEGORY" or "SETTINGS",small,x+w*.62,y+30*scale,w*.30,"right",c.accent)

    local rows=type(s.visible)=="function" and s:visible() or (s.view or s.rows or {})
    local idx=tonumber(s.index) or 1
    local scroll=tonumber(s.scroll) or 0
    local visible=7
    local top=y+86*scale
    local footerH=62*scale
    local listH=h-(top-y)-footerH
    local rh=listH/visible

    for slot=1,visible do
      local i=scroll+slot
      local row=rows[i]
      if not row then break end
      local yy=top+(slot-1)*rh
      local selected=i==idx
      if selected then
        color(c.selected)
        G.rectangle("fill",x+22*scale,yy,w-44*scale,rh-6*scale,7,7)
        color(c.accent)
        G.rectangle("fill",x+22*scale,yy,5*scale,rh-6*scale,2,2)
      end

      local label=optionLabel(row)
      local value=optionValue(s,row)
      text(label,body,x+48*scale,
        yy+math.max(4*scale,(rh-body:getHeight())*.42),
        w*.57,"left",selected and c.text or c.muted)

      if value~="" then
        text(value,valueFont,x+w*.63,
          yy+math.max(5*scale,(rh-valueFont:getHeight())*.45),
          w*.29,"right",selected and c.text or c.accent)
      end
    end

    color(c.divider)
    G.rectangle("fill",x+24*scale,y+h-footerH,w-48*scale,1)

    local selected=rows[idx]
    local hint="UP/DOWN SELECT   LEFT/RIGHT CHANGE   A OPEN/CHANGE   B BACK"
    if selected and selected.group then
      hint="A OPEN CATEGORY   B BACK"
    elseif selected and selected.cancel then
      hint="A/B BACK"
    elseif selected and selected.activate then
      hint="A OPEN   B BACK"
    end
    text(hint,small,x+28*scale,y+h-footerH+18*scale,w-56*scale,"left",c.muted)

    if scroll>0 then
      text("▲",body,x+w-58*scale,y+22*scale,nil,nil,c.accent)
    end
    if scroll+visible<#rows then
      text("▼",body,x+w-58*scale,y+h-footerH-42*scale,nil,nil,c.accent)
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
    local scale=math.max(.88,math.min(1.42,sh/760))
    local w=math.min(1160*scale,sw*.70)
    local h=math.min(720*scale,sh*.80)
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.97)

    local titleFont=font(38*scale)
    local body=font(27*scale)
    local valueFont=font(25*scale)
    local small=font(19*scale)
    local descFont=font(20*scale)

    local title=(s.currentMod and (s.currentMod.name or s.currentMod.id))
      or "KANTO IN MOTION"
    text(string.upper(tostring(title)),titleFont,
      x+28*scale,y+18*scale,w*.62,"left",c.text)
    text("MOD SETTINGS",small,x+w*.63,y+30*scale,w*.30,"right",c.accent)

    local rows=s.optionRows or {}
    local idx=tonumber(s.cursor) or 1
    local scroll=tonumber(s.scroll) or 0
    local visible=7

    local listTop=y+86*scale
    local footerH=128*scale
    local listH=h-(listTop-y)-footerH
    local rh=listH/visible

    for slot=1,visible do
      local i=scroll+slot
      local row=rows[i]
      if not row then break end
      local yy=listTop+(slot-1)*rh
      local selected=i==idx

      if selected then
        color(c.selected)
        G.rectangle("fill",x+22*scale,yy,w-44*scale,rh-6*scale,7,7)
        color(c.accent)
        G.rectangle("fill",x+22*scale,yy,5*scale,rh-6*scale,2,2)
      end

      local label=tostring(row.label or row.id or "OPTION")
      local value=managerOptionValue(row)

      text(label,body,x+50*scale,
        yy+math.max(4*scale,(rh-body:getHeight())*.42),
        w*.60,"left",selected and c.text or c.muted)

      if value~="" then
        text(value,valueFont,x+w*.64,
          yy+math.max(4*scale,(rh-valueFont:getHeight())*.44),
          w*.27,"right",selected and c.text or c.accent)
      end
    end

    local footerY=y+h-footerH
    color(c.divider)
    G.rectangle("fill",x+26*scale,footerY,w-52*scale,1)

    local selectedRow=rows[idx]
    local desc=managerOptionDescription(s,selectedRow)
    if desc~="" then
      text(desc,descFont,x+32*scale,footerY+14*scale,
        w-64*scale,"left",c.muted)
    end

    text("UP/DOWN  SELECT   LEFT/RIGHT  CHANGE   A  CHANGE   B  DONE",
      small,x+32*scale,y+h-small:getHeight()-16*scale,
      w-64*scale,"left",c.accent)

    if scroll>0 then
      text("▲",body,x+w-58*scale,y+24*scale,nil,nil,c.accent)
    end
    if scroll+visible<#rows then
      text("▼",body,x+w-58*scale,y+h-footerH-42*scale,nil,nil,c.accent)
    end
  end

  local function drawKimSettings(s)
    local c=theme(); local sx,sy,sw,sh=playfield()
    local scale=math.max(.88,math.min(1.42,sh/760))
    local w=math.min(1120*scale,sw*.70)
    local h=math.min(720*scale,sh*.80)
    local x=sx+(sw-w)/2; local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.97)

    local titleFont=font(38*scale)
    local body=font(27*scale)
    local valueFont=font(25*scale)
    local small=font(19*scale)
    local descFont=font(20*scale)

    local title=tostring(s.title or "KANTO IN MOTION")
    text(title,titleFont,x+28*scale,y+18*scale,w*.62,"left",c.text)
    text(rawget(s,"_kimModernSettings")=="battle" and "BATTLE SETTINGS" or "MOD SETTINGS",
      small,x+w*.60,y+30*scale,w*.33,"right",c.accent)

    local rows=s.items or {}
    local idx=tonumber(s.index) or 1
    local scroll=tonumber(s.scroll) or 0
    local visible=7
    local listTop=y+86*scale
    local footerH=132*scale
    local listH=h-(listTop-y)-footerH
    local rh=listH/visible

    for slot=1,visible do
      local i=scroll+slot
      local row=rows[i]
      if not row then break end
      local yy=listTop+(slot-1)*rh
      local selected=i==idx

      if selected then
        color(c.selected)
        G.rectangle("fill",x+22*scale,yy,w-44*scale,rh-6*scale,7,7)
        color(c.accent)
        G.rectangle("fill",x+22*scale,yy,5*scale,rh-6*scale,2,2)
      end

      local label=tostring(row.label or row.id or "OPTION")
      local value=tostring(row.right or "")

      text(label,body,x+50*scale,
        yy+math.max(4*scale,(rh-body:getHeight())*.42),
        w*.60,"left",selected and c.text or c.muted)

      if value~="" then
        text(value,valueFont,x+w*.64,
          yy+math.max(4*scale,(rh-valueFont:getHeight())*.44),
          w*.27,"right",selected and c.text or c.accent)
      end
    end

    local footerY=y+h-footerH
    color(c.divider)
    G.rectangle("fill",x+26*scale,footerY,w-52*scale,1)

    local selected=rows[idx]
    local desc=selected and selected.option and selected.option.description or ""
    if selected and selected.resetBattleDefaults then
      desc="Restore all battle settings to their defaults."
    elseif selected and selected.submenu then
      desc="Open the Kanto in Motion battle settings."
    elseif selected and selected.cancel then
      desc=rawget(s,"_kimModernSettings")=="battle"
        and "Return to Kanto in Motion settings."
        or "Close Kanto in Motion settings."
    end

    if desc and tostring(desc)~="" then
      text(tostring(desc),descFont,x+32*scale,footerY+14*scale,
        w-64*scale,"left",c.muted)
    end

    text("UP/DOWN  SELECT   LEFT/RIGHT  CHANGE   A  CHANGE/OPEN   B  BACK",
      small,x+32*scale,y+h-small:getHeight()-16*scale,
      w-64*scale,"left",c.accent)

    if scroll>0 then
      text("▲",body,x+w-58*scale,y+24*scale,nil,nil,c.accent)
    end
    if scroll+visible<#rows then
      text("▼",body,x+w-58*scale,y+h-footerH-42*scale,nil,nil,c.accent)
    end
  end

  local renderers={
    start=drawStart,pack=drawPack,gear=drawGear,card=drawCard,
    save=drawSave,options=drawOptions,modoptions=drawModOptions,
    kimsettings=drawKimSettings,
  }

  if mod.hooks and type(mod.hooks.wrap)=="function" then
    mod.hooks:wrap("ui.start_menu.items",function(nextFn,game,items)
      local rows=nextFn(game,items)
      if not enabled() then return rows end
      if type(rows)~="table" then return rows end
      local out={}
      for _,row in ipairs(rows) do
        local id=tostring(row and (row.value or row.id) or ""):lower()
        local label=tostring(row and row.label or ""):upper()
        if id~="mods" and label~="MODS" and label~="MAPA" then
          out[#out+1]=row
        end
      end
      return out
    end,100000)
    mod.hooks:wrap("screen.render_visible",function(nextFn,state)
      if enabled() and target(state) then return false end
      return nextFn(state)
    end,100000)
    mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
      local result={pcall(nextFn,game,viewport)}; local ok=table.remove(result,1)
      if not ok then error(result[1],0) end
      local top=game and game.stack and type(game.stack.top)=="function" and game.stack:top()
      local kind=enabled() and target(top)
      if kind then G.push("all"); G.origin(); pcall(renderers[kind],top); G.pop() end
      return unpack(result)
    end,100000)
  end

  mod.exports.gen2ModernCoreMenus={apiVersion=1}
  return true
end
