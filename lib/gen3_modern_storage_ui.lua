-- Kanto in Motion - Gen 3 Modern PC / Pokemon Storage UI
--
-- Presentation-only replacement for Game3 PC menus and the Pokemon Storage
-- System. Game3 remains authoritative for cursor movement, storage mutations,
-- party/box transfers, release/marking flows, summaries, naming, and callbacks.
return function(mod)
  if not (love and love.graphics and mod and mod.hooks and type(mod.hooks.wrap)=="function") then
    return false
  end

  local G=love.graphics
  local Style=mod._kantoInMotionGen3Ui
  local okPc,PcMenu=pcall(require,"src.ui.game3.pc_menu")
  local okBox,Box=pcall(require,"src.ui.game3.box_storage_ui")
  local okStorage,Storage=pcall(require,"src.core.game3.storage")
  local okPokemon,Pokemon=pcall(require,"src.core.game3.pokemon")
  local okItems,Items=pcall(require,"src.core.game3.items_data")
  local okTypes,Types=pcall(require,"src.core.game3.battle.types")
  local okStack,Stack=pcall(require,"src.ui.game3.stack")
  local okRelease,ReleaseSeq=pcall(require,"src.ui.game3.release_seq")
  local okChrome,PcChrome=pcall(require,"src.ui.game3.pc_chrome")
  local okRs,RseStorage=pcall(require,"src.ui.game3.rs.storage_policy")
  if not (okPc and type(PcMenu)=="table" and okBox and type(Box)=="table"
      and okStorage and type(Storage)=="table" and okPokemon and type(Pokemon)=="table") then
    return false
  end

  local FALLBACK={
    surface={.075,.105,.17,.98},raised={.12,.17,.27,1},selected={.18,.43,.72,1},
    accent={.48,.86,1,1},frame={.48,.86,1,1},frameShadow={.01,.02,.04,.42},
    text={.96,.98,1,1},muted={.74,.82,.92,1},divider={.38,.5,.68,.94},
  }
  local fonts={}

  local function opt(key,fallback)
    if not (mod.options and type(mod.options.get)=="function") then return fallback end
    local ok,v=pcall(mod.options.get,mod.options,key)
    if not ok or v==nil then return fallback end
    return v
  end
  local function enabled()
    if Style and Style.presenterEnabled then return Style.presenterEnabled("menu") end
    return opt("gen3IntegratedModernUi",true)~=false
  end
  local function hideOriginal()
    return not Style or not Style.hideOriginal or Style.hideOriginal()
  end
  local function theme()
    if Style and Style.theme then return Style.theme() end
    local t=mod._kantoInMotionGen3Themes
    if type(t)=="table" then return t[tostring(opt("gen3UiTheme","default"))] or t.default or FALLBACK end
    return FALLBACK
  end
  local function color(c,a,foreground)
    if Style and Style.color then return Style.color(c,a,foreground~=false) end
    c=c or {1,1,1,1}; G.setColor(c[1] or 1,c[2] or 1,c[3] or 1,a==nil and (c[4] or 1) or a)
  end
  local function font(px)
    if Style and Style.font then return Style.font(px) end
    px=math.max(8,math.floor((tonumber(px) or 12)+.5))
    if fonts[px] then return fonts[px] end
    local ok,f=pcall(G.newFont,px)
    if ok and f then fonts[px]=f; return f end
    return G.getFont()
  end
  local function text(v,f,x,y,w,align,c)
    if Style and Style.text then return Style.text(v,f,x,y,w,align,c) end
    if f then G.setFont(f) end
    color(c); v=tostring(v or "")
    if w and w>0 then G.printf(v,x,y,w,align or "left") else G.print(v,x,y) end
  end
  local function fit(v,f,maxW)
    v=tostring(v or "")
    if not f or not maxW or f:getWidth(v)<=maxW then return v end
    local suffix="..."; local target=math.max(0,maxW-f:getWidth(suffix))
    while #v>0 and f:getWidth(v)>target do v=v:sub(1,#v-1) end
    return v..suffix
  end
  local function card(x,y,w,h,fill,line,r)
    r=r or math.max(4,math.min(w,h)*.04)
    local pa=Style and Style.panelOpacity and Style.panelOpacity(1) or 1
    color(fill,math.min(1,(fill and fill[4] or 1)*pa),false)
    G.rectangle("fill",x,y,w,h,r,r)
    if line then color(line,nil,true); G.setLineWidth(math.max(1,math.min(w,h)*.008)); G.rectangle("line",x+.5,y+.5,math.max(0,w-1),math.max(0,h-1),r,r) end
  end
  local function playfield(viewport)
    local x=tonumber(viewport and viewport.gameX) or 0
    local y=tonumber(viewport and viewport.gameY) or 0
    local w=tonumber(viewport and viewport.gameWidth)
    local h=tonumber(viewport and viewport.gameHeight)
    if w and h and w>0 and h>0 then return x,y,w,h end
    local ww,wh=G.getDimensions(); local s=math.min(ww/240,wh/160)
    return (ww-240*s)*.5,(wh-160*s)*.5,240*s,160*s
  end
  local function uiScale()
    if Style and Style.uiScale then local ww,wh=G.getDimensions(); return Style.uiScale(ww,wh) end
    return 1
  end
  local function modernWindow(viewport,c,kind)
    local sx,sy,sw,sh=playfield(viewport)
    local roomy=sw>=720 and sh>=460
    local scale=uiScale()
    local fw=(kind=="pc") and (roomy and .56 or .90) or (roomy and .88 or .97)
    local fh=(kind=="pc") and (roomy and .72 or .88) or (roomy and .90 or .96)
    local w=math.min(sw*.98,sw*fw*scale)
    local h=math.min(sh*.98,sh*fh*scale)
    if Style and Style.layoutStyle and Style.layoutStyle()=="full" then w=sw*.95; h=sh*.93 end
    local x=sx+(sw-w)*.5; local y=sy+(sh-h)*.5
    if Style and Style.panel then Style.panel(x,y,w,h,c,1)
    else card(x,y,w,h,c.surface,c.frame,math.max(7,math.min(w,h)*.018)) end
    color(c.accent,nil,true); G.rectangle("fill",x,y,w,math.max(2,h*.010))
    return x,y,w,h
  end
  local function chevron(cx,cy,size,dir,c)
    size=math.max(4,tonumber(size) or 8); color(c); G.setLineWidth(math.max(1,size*.14))
    if dir=="left" then G.line(cx+size*.26,cy-size*.36,cx-size*.22,cy,cx+size*.26,cy+size*.36)
    elseif dir=="right" then G.line(cx-size*.26,cy-size*.36,cx+size*.22,cy,cx-size*.26,cy+size*.36)
    elseif dir=="up" then G.line(cx-size*.36,cy+size*.24,cx,cy-size*.24,cx+size*.36,cy+size*.24)
    else G.line(cx-size*.36,cy-size*.24,cx,cy+size*.24,cx+size*.36,cy-size*.24) end
  end
  local function genderSymbol(cx,cy,size,g,c)
    size=math.max(6,tonumber(size) or 9); color(c); G.setLineWidth(math.max(1,size*.12))
    local r=size*.22
    if g=="M" then
      local ox,oy=cx-size*.10,cy+size*.08; G.circle("line",ox,oy,r)
      local ex,ey=cx+size*.34,cy-size*.34; G.line(ox+r*.72,oy-r*.72,ex,ey); G.line(ex-size*.18,ey,ex,ey,ex,ey+size*.18)
    elseif g=="F" then
      local ox,oy=cx,cy-size*.12; G.circle("line",ox,oy,r)
      G.line(ox,oy+r,ox,cy+size*.34); G.line(ox-size*.18,cy+size*.16,ox+size*.18,cy+size*.16)
    end
  end

  local function setStorageFloating(on)
    if not (okStack and Stack and type(Stack._layers)=="table") then return end
    for i=#Stack._layers,1,-1 do
      local layer=Stack._layers[i]
      if layer and layer.id=="box_storage" then
        if on then
          if layer._kimGen3StorageOriginal==nil then
            layer._kimGen3StorageOriginal={hideBelow=layer.hideBelow,drawUnder=layer.drawUnder,fullscreen=layer.fullscreen}
          end
          layer.hideBelow=false; layer.drawUnder=true; layer.fullscreen=false
        elseif layer._kimGen3StorageOriginal then
          local o=layer._kimGen3StorageOriginal
          layer.hideBelow=o.hideBelow; layer.drawUnder=o.drawUnder; layer.fullscreen=o.fullscreen
          layer._kimGen3StorageOriginal=nil
        end
        return
      end
    end
  end

  local function isPcOpen()
    if type(PcMenu.isOpen)=="function" then local ok,v=pcall(PcMenu.isOpen); return ok and v==true end
    return PcMenu.open==true
  end
  local function isBoxOpen()
    if type(Box.isOpen)=="function" then local ok,v=pcall(Box.isOpen); return ok and v==true end
    return Box.open==true
  end
  local function releaseActive()
    return okRelease and ReleaseSeq and type(ReleaseSeq.isActive)=="function" and ReleaseSeq.isActive()
  end

  local function drawFooter(x,y,w,h,c,f,left,right)
    color(c.divider,.55); G.rectangle("fill",x,y,math.max(0,w),math.max(1,h*.04))
    text(left or "A SELECT",f,x,y+h*.18,w*.55,"left",c.muted)
    text(right or "B BACK",f,x+w*.55,y+h*.18,w*.45,"right",c.muted)
  end

  local function pcRows()
    local mode=PcMenu.mode
    if mode=="root" and type(PcMenu._rootEntries)=="function" then return PcMenu._rootEntries(),"PC" end
    if mode=="storage_menu" and type(PcMenu._storageOptions)=="function" then return PcMenu._storageOptions(),"POKéMON STORAGE" end
    if mode=="player_pc" then return PcMenu.TOP_ACTIONS or {},"PLAYER'S PC" end
    if mode=="item_storage" then return PcMenu.ITEM_STORAGE_ACTIONS or {},"ITEM STORAGE" end
    return nil,"PC"
  end

  local function drawPc(viewport,c)
    local x,y,w,h=modernWindow(viewport,c,"pc")
    local pad=w*.045; local title=font(math.max(13,h*.040)); local body=font(math.max(11,h*.031)); local small=font(math.max(9,h*.024))
    local rows,heading=pcRows()
    text(heading,title,x+pad,y+pad*.72,w-pad*2,"left",c.text)
    local top=y+pad+title:getHeight()+h*.025
    local statusH=h*.22
    local listH=h-(top-y)-statusH-pad*1.7
    if PcMenu.mode=="msg" then
      card(x+pad,top,w-pad*2,h-(top-y)-pad,c.raised,c.divider,6)
      text(PcMenu._status or "",body,x+pad*1.5,top+pad,w-pad*3,"left",c.text)
      drawFooter(x+pad, y+h-pad*.95,w-pad*2,pad*.65,c,small,"A CONTINUE","B BACK")
      return
    end
    rows=rows or {}
    local rowH=math.min(h*.092,listH/math.max(1,#rows))
    for i,e in ipairs(rows) do
      local yy=top+(i-1)*rowH; local selected=i==(tonumber(PcMenu.cursor) or 1)
      if selected then card(x+pad,yy,w-pad*2,rowH*.84,c.selected,c.accent,4) end
      local label=type(e)=="table" and (e.label or e.name or e.id) or e
      text(fit(label,body,w-pad*3),body,x+pad*1.4,yy+(rowH*.84-body:getHeight())*.5,w-pad*2.8,"left",selected and c.text or c.muted)
    end
    local sy=y+h-statusH-pad*.6
    card(x+pad,sy,w-pad*2,statusH,c.raised,c.divider,5)
    text("DESCRIPTION",small,x+pad*1.35,sy+pad*.45,w-pad*2.7,"left",c.accent)
    text(PcMenu._status or "",small,x+pad*1.35,sy+pad*.45+small:getHeight()*1.4,w-pad*2.7,"left",c.text)
    drawFooter(x+pad, y+h-pad*.88,w-pad*2,pad*.58,c,small,"A SELECT","B BACK")
  end

  local function monName(mon)
    if not mon then return "---" end
    if type(Pokemon.displayName)=="function" then local ok,v=pcall(Pokemon.displayName,mon); if ok and v and v~="" then return tostring(v) end end
    local sp=type(Pokemon.speciesOf)=="function" and Pokemon.speciesOf(mon) or mon.species
    if sp and type(Pokemon.name)=="function" then local ok,v=pcall(Pokemon.name,sp); if ok and v then return tostring(v) end end
    return tostring(mon.nickname or mon.name or "POKéMON")
  end
  local function species(mon)
    if not mon then return nil end
    if type(Pokemon.speciesOf)=="function" then local ok,v=pcall(Pokemon.speciesOf,mon); if ok then return v end end
    return mon.species or mon.speciesId
  end
  local function gender(mon)
    if not mon then return nil end
    local g=mon.gender
    if g=="male" or g==0 then return "M" elseif g=="female" or g==1 then return "F" elseif g=="M" or g=="F" then return g end

    -- Native Game3 gender is authoritative for the original roster. 1025Dex
    -- species can legitimately return unknown here because their genderRate
    -- lives behind the compatibility API installed by gen3_frlg.lua.
    if type(Pokemon.gender)=="function" then
      local ok,v=pcall(Pokemon.gender,species(mon),mon.personality or 0)
      if ok then
        if v=="male" or v==0 then return "M" end
        if v=="female" or v==1 then return "F" end
        if v=="M" or v=="F" then return v end
      end
    end

    -- Reuse the confirmed 1025Dex gender bridge used by the Gen 3 Party and
    -- Summary Modern UI instead of duplicating 1025Dex's gender-rate logic.
    local resolver=mod._kantoInMotion1025DexGender
    if type(resolver)=="function" then
      local ok,v=pcall(resolver,mon)
      if ok and (v=="M" or v=="F") then return v end
    end
    return nil
  end
  local function typeName(id)
    if okTypes and Types and type(Types.name)=="function" then local ok,v=pcall(Types.name,id); if ok and v then return tostring(v) end end
    return id and tostring(id) or "---"
  end
  local function monTypes(mon)
    local sp=species(mon); local t={}
    if sp and type(Pokemon.types)=="function" then local ok,v=pcall(Pokemon.types,sp); if ok and type(v)=="table" then t=v end end
    return t[1] or mon and mon.type1,t[2] or mon and mon.type2
  end
  local function heldName(mon)
    local id=mon and (mon.heldItem or mon.item)
    if not id or tonumber(id)==0 then return "NONE" end
    if okItems and Items and type(Items.displayName)=="function" then local ok,v=pcall(Items.displayName,id); if ok and v then return tostring(v) end end
    return tostring(id)
  end
  local function drawPreview(mon,x,y,w,h)
    if not mon then return false end
    local provider=mod._kantoInMotionGen3HdAnimatedPreviewDraw
    if type(provider)=="function" then local ok,drawn=pcall(provider,mon,x,y,w,h); if ok and drawn then return true end end
    if type(Pokemon.monFrontPic)=="function" then
      local ok,p=pcall(Pokemon.monFrontPic,mon,nil,"box")
      if ok and type(p)=="table" and p.image then
        local iw,ih=p.w or p.image:getWidth(),p.h or p.image:getHeight(); local sc=math.min(w/math.max(1,iw),h/math.max(1,ih),2.1)
        color({1,1,1,1}); G.draw(p.image,x+w*.5,y+h*.5,0,sc,sc,iw*.5,ih*.5); return true
      end
    end
    return false
  end
  -- Box/party icons are drawn in final-window space, so do not feed KIM's
  -- HD icon art through Game3's 32x32 native icon canvas first.  That path is
  -- correct for the original 240x160 UI, but it throws away the extra detail
  -- before this Modern Storage presenter enlarges the icon again.
  local hdIconCache,hdIconMissing={},{}
  local function hdIcon(mon)
    local provider=mod._kantoInMotionHdMenuIconForModernUi
    if type(provider)~="function" or type(mon)~="table" then return nil end
    -- The Gen 3 provider resolves National Dex through Game3's authoritative
    -- internal-species mapping, so no game/data object is required here.
    local ok,path=pcall(provider,nil,mon)
    if not ok or type(path)~="string" or path=="" or hdIconMissing[path] then return nil end
    if hdIconCache[path]~=nil then return hdIconCache[path] or nil end
    local okImg,img=pcall(G.newImage,path)
    if not okImg or not img then
      hdIconCache[path]=false; hdIconMissing[path]=true; return nil
    end
    -- These are the untouched HD Rescaled Icon images.  Linear sampling is
    -- intentional at the final output resolution; native/vanilla fallback
    -- below retains the source icon's own pixel-art presentation.
    if type(img.setFilter)=="function" then pcall(img.setFilter,img,"linear","linear") end
    hdIconCache[path]=img
    return img
  end

  local function drawIcon(mon,x,y,w,h,frame)
    if not mon then return end

    local bob=0
    if frame and tonumber(frame)%2==1 then bob=-math.max(1,math.min(w,h)*.045) end

    -- Preferred Modern UI path: original-resolution KIM HD icon drawn directly
    -- into the final-resolution storage window.
    local hd=hdIcon(mon)
    if hd then
      local iw,ih=hd:getDimensions()
      iw,ih=math.max(1,iw or 1),math.max(1,ih or 1)
      local sc=math.min(w/iw,h/ih)
      color({1,1,1,1})
      G.draw(hd,x+(w-iw*sc)*.5,y+(h-ih*sc)*.5+bob,0,sc,sc)
      return true
    end

    -- POKEMON ICONS OFF (or an unavailable HD asset) falls back to Game3's
    -- normal animated icon without altering storage logic.
    if type(Pokemon.monIcon)~="function" then return false end
    local ok,icon=pcall(Pokemon.monIcon,mon); if not ok or not icon or not icon.image then return false end
    local img=icon.image; local q=icon.quads and (icon.quads[frame or 0] or icon.quads[0])
    local iw,ih=img:getDimensions(); local qw,qh=iw,ih
    if q and type(q.getViewport)=="function" then local _,_,a,b=q:getViewport(); qw,qh=a,b end
    local sc=math.min(w/math.max(1,qw),h/math.max(1,qh),2.5)
    color({1,1,1,1})
    if q then G.draw(img,q,x+w*.5,y+h*.5+bob,0,sc,sc,qw*.5,qh*.5)
    else G.draw(img,x+w*.5,y+h*.5+bob,0,sc,sc,iw*.5,ih*.5) end
    return true
  end

  local function storageState()
    local s=Box._session; local st=Storage.ensure(s)
    if not st then return nil end
    local bId=tonumber(st.currentBox) or 1; local box=st.boxes and st.boxes[bId]
    return s,st,bId,box
  end
  local function selectedMon()
    if Box.mode=="action_menu" and Box._actionTarget then return Box._actionTarget.mon,Box._actionTarget.loc,Box._actionTarget.slot end
    local session,st,bId,box=storageState(); if not session then return nil end
    if Box.mode=="party_drawer" or Box.drawerOpen or (tonumber(Box.cursorSlot) or 0)<0 then
      local idx=tonumber(Box.partyCursor) or (-(tonumber(Box.cursorSlot) or -1))
      if idx>=1 and idx<=6 then return session.party and session.party[idx],"party",idx end
      return nil,"party",idx
    end
    local slot=tonumber(Box.cursorSlot) or 0
    if slot>=1 and slot<=30 then return box and box.mons and box.mons[slot],"box",slot end
    return nil,nil,slot
  end

  local function drawMonInfo(mon,x,y,w,h,c,title,body,small)
    card(x,y,w,h,c.raised,c.divider,6)
    text("POKéMON DATA",small,x+w*.06,y+h*.05,w*.88,"left",c.accent)
    local previewH=h*.42
    drawPreview(mon,x+w*.08,y+h*.12,w*.84,previewH)
    if not mon then
      text("NO POKéMON",body,x+w*.08,y+h*.58,w*.84,"center",c.muted); return
    end
    local name=monName(mon); local lvl=tonumber(mon.level) or 1; local g=gender(mon)
    text(fit(name,title,w*.78),title,x+w*.06,y+h*.56,w*.78,"left",c.text)
    local lv="Lv "..tostring(lvl); local lx=x+w*.06; local ly=y+h*.56+title:getHeight()*1.08
    text(lv,body,lx,ly,w*.5,"left",c.text)
    if g=="M" or g=="F" then
      local gx=lx+body:getWidth(lv)+body:getHeight()*.55
      genderSymbol(gx,ly+body:getHeight()*.55,body:getHeight()*.75,g,g=="M" and {.32,.72,1,1} or {1,.48,.72,1})
    end
    local t1,t2=monTypes(mon); local typeText=typeName(t1)
    if t2 and t2~=t1 then typeText=typeText.." / "..typeName(t2) end
    text(fit(typeText,small,w*.88),small,x+w*.06,y+h*.72,w*.88,"left",c.accent)
    local hp=tonumber(mon.hp or mon.currentHp); local max=tonumber(mon.maxHp or mon.maxhp or mon.maxHP)
    if hp and max then text(string.format("HP  %d/%d",hp,max),small,x+w*.06,y+h*.81,w*.88,"left",c.text) end
    text("ITEM  "..fit(heldName(mon),small,w*.60),small,x+w*.06,y+h*.89,w*.88,"left",c.muted)
  end

  local function boxActions()
    if Box._activeActions then return Box._activeActions end
    return {"CANCEL"}
  end
  local function genericBoxMenuActions(session)
    if okRs and RseStorage and type(RseStorage.matches)=="function" and RseStorage.matches(session) and type(RseStorage.boxActions)=="function" then
      local ok,v=pcall(RseStorage.boxActions); if ok and type(v)=="table" then return v end
    end
    return {"SWITCH BOX","WALLPAPER","CANCEL"}
  end
  local function popupList(rows,cursor,x,y,w,c,body,small,title)
    local rowH=body:getHeight()*1.55; local h=rowH*#rows+small:getHeight()*1.8+12
    card(x,y,w,h,c.surface,c.accent,5)
    if title then text(title,small,x+10,y+7,w-20,"left",c.accent) end
    local top=y+small:getHeight()*1.7+7
    for i,r in ipairs(rows) do
      local yy=top+(i-1)*rowH
      if i==(tonumber(cursor) or 1) then card(x+6,yy-2,w-12,rowH,c.selected,nil,3) end
      text(tostring(r),body,x+12,yy,w-24,"left",i==(tonumber(cursor) or 1) and c.text or c.muted)
    end
    return h
  end

  local function drawPartyDrawer(session,x,y,w,h,c,body,small)
    local party=session and session.party or {}
    card(x,y,w,h,c.surface,c.accent,6)
    text("PARTY",body,x+w*.07,y+h*.035,w*.86,"left",c.text)
    local top=y+h*.12; local rowH=(h*.78)/6
    for i=1,6 do
      local mon=party[i]; local selected=(tonumber(Box.partyCursor) or 1)==i
      if selected then card(x+w*.04,top+(i-1)*rowH,w*.92,rowH*.88,c.selected,nil,4) end
      if mon then
        drawIcon(mon,x+w*.05,top+(i-1)*rowH,w*.18,rowH*.82,selected and (Box.hoverFrame or 0) or 0)
        text(fit(monName(mon),small,w*.62),small,x+w*.25,top+(i-1)*rowH+(rowH*.88-small:getHeight())*.5,w*.62,"left",selected and c.text or c.muted)
      else
        text("---",small,x+w*.25,top+(i-1)*rowH+(rowH*.88-small:getHeight())*.5,w*.62,"left",c.muted)
      end
    end
    local cancelSelected=(tonumber(Box.partyCursor) or 1)==7
    if cancelSelected then card(x+w*.20,y+h*.91,w*.60,h*.065,c.selected,nil,4) end
    text("CANCEL",small,x+w*.20,y+h*.92,w*.60,"center",cancelSelected and c.text or c.muted)
  end

  local function drawBoxPicker(st,x,y,w,h,c,body,small)
    local count=tonumber(Storage.TOTAL_BOXES_COUNT) or 14
    local cols=4; local rows=math.ceil(count/cols); local gap=w*.018
    local cellW=(w-gap*(cols-1))/cols; local cellH=(h-gap*(rows-1))/rows
    local cur=tonumber(Box._pickBox) or tonumber(st.currentBox) or 1
    for i=1,count do
      local col=(i-1)%cols; local row=math.floor((i-1)/cols); local bx=x+col*(cellW+gap); local by=y+row*(cellH+gap)
      local sel=i==cur; card(bx,by,cellW,cellH,sel and c.selected or c.raised,sel and c.accent or c.divider,4)
      local b=st.boxes and st.boxes[i]; local nm=b and b.name or ("BOX "..i)
      text(fit(nm,small,cellW-10),small,bx+5,by+(cellH-small:getHeight())*.5,cellW-10,"center",sel and c.text or c.muted)
    end
  end

  local function drawStorage(viewport,c)
    local session,st,bId,box=storageState(); if not session then return end
    local x,y,w,h=modernWindow(viewport,c,"storage")
    local pad=w*.022; local title=font(math.max(13,h*.038)); local body=font(math.max(10,h*.026)); local small=font(math.max(8,h*.021))
    local headerH=h*.105; local footerH=h*.085
    text("POKéMON STORAGE",title,x+pad,y+pad*.60,w*.45,"left",c.text)
    local modeLabel=({withdraw="WITHDRAW",deposit="DEPOSIT",move="MOVE",move_items="MOVE ITEMS"})[Box.subMode] or "STORAGE"
    text(modeLabel,small,x+w*.58,y+pad*.78,w*.36,"right",c.accent)

    local infoW=w*.255; local contentY=y+headerH; local contentH=h-headerH-footerH-pad*.25
    local infoX=x+pad; local gridX=infoX+infoW+pad; local gridW=x+w-pad-gridX
    local mon=selectedMon(); drawMonInfo(mon,infoX,contentY,infoW,contentH,c,title,body,small)

    -- Top controls and box header.
    local controlH=h*.07; local btnW=gridW*.22
    local partySel=(tonumber(Box.cursorSlot) or 0)==-10 or Box.mode=="party_drawer"
    local closeSel=(tonumber(Box.cursorSlot) or 0)==-20
    card(gridX,contentY,btnW,controlH,partySel and c.selected or c.raised,partySel and c.accent or c.divider,4)
    text("PARTY",small,gridX,contentY+(controlH-small:getHeight())*.5,btnW,"center",partySel and c.text or c.muted)
    card(gridX+gridW-btnW,contentY,btnW,controlH,closeSel and c.selected or c.raised,closeSel and c.accent or c.divider,4)
    text("CLOSE",small,gridX+gridW-btnW,contentY+(controlH-small:getHeight())*.5,btnW,"center",closeSel and c.text or c.muted)
    local boxName=box and box.name or ("BOX "..tostring(bId)); local headX=gridX+btnW+pad*.45; local headW=gridW-btnW*2-pad*.9
    local headSel=(tonumber(Box.cursorSlot) or 0)==0
    card(headX,contentY,headW,controlH,headSel and c.selected or c.raised,headSel and c.accent or c.divider,4)
    chevron(headX+headW*.08,contentY+controlH*.5,small:getHeight()*.75,"left",headSel and c.text or c.muted)
    chevron(headX+headW*.92,contentY+controlH*.5,small:getHeight()*.75,"right",headSel and c.text or c.muted)
    text(fit(boxName,body,headW*.70),body,headX+headW*.15,contentY+(controlH-body:getHeight())*.5,headW*.70,"center",headSel and c.text or c.muted)

    local gy=contentY+controlH+pad*.45; local gh=contentY+contentH-gy
    card(gridX,gy,gridW,gh,c.raised,c.divider,6)
    local cols,rows=6,5; local gap=math.max(2,gridW*.009); local cellW=(gridW-gap*(cols+1))/cols; local cellH=(gh-gap*(rows+1))/rows
    for s=1,(tonumber(Storage.IN_BOX_COUNT) or 30) do
      local col=(s-1)%cols; local row=math.floor((s-1)/cols); local bx=gridX+gap+col*(cellW+gap); local by=gy+gap+row*(cellH+gap)
      local selected=(tonumber(Box.cursorSlot) or 0)==s and Box.mode~="party_drawer" and not Box.drawerOpen
      card(bx,by,cellW,cellH,selected and c.selected or {c.surface[1],c.surface[2],c.surface[3],.58},selected and c.accent or nil,4)
      local pm=box and box.mons and box.mons[s]
      if pm then drawIcon(pm,bx+cellW*.08,by+cellH*.06,cellW*.84,cellH*.86,selected and (Box.hoverFrame or 0) or 0) end
    end

    if Box.holdingMon then
      card(gridX+gridW*.31,gy+gh-h*.075,gridW*.38,h*.06,c.surface,c.accent,4)
      text("HOLDING: "..fit(monName(Box.holdingMon),small,gridW*.29),small,gridX+gridW*.33,gy+gh-h*.061,gridW*.34,"center",c.text)
    end

    if Box.mode=="party_drawer" or Box.drawerOpen then
      local dw=gridW*.34; drawPartyDrawer(session,gridX+gridW-dw-pad*.25,gy+pad*.15,dw,gh-pad*.3,c,body,small)
    end

    if Box.mode=="action_menu" then
      local acts=boxActions(); popupList(acts,Box.actionCursor,x+w*.72,y+h*.28,w*.23,c,body,small,"ACTION")
    elseif Box.mode=="box_menu" then
      local acts=genericBoxMenuActions(session); popupList(acts,Box.boxMenuCursor,x+w*.56,y+h*.22,w*.27,c,body,small,"BOX")
    elseif Box.mode=="pick_box" or Box.mode=="deposit_box_full" then
      card(gridX+gridW*.10,gy+gh*.08,gridW*.80,gh*.82,c.surface,c.accent,6)
      text(Box._pendingDeposit and "DEPOSIT IN WHICH BOX?" or "JUMP TO WHICH BOX?",body,gridX+gridW*.15,gy+gh*.12,gridW*.70,"center",c.text)
      drawBoxPicker(st,gridX+gridW*.17,gy+gh*.22,gridW*.66,gh*.58,c,body,small)
    elseif Box.mode=="pick_wallpaper_group" then
      popupList({"SCENERY 1","SCENERY 2","SCENERY 3","ETC."},Box._wallpaperGroup,x+w*.57,y+h*.23,w*.27,c,body,small,"THEME")
    elseif Box.mode=="pick_wallpaper" then
      local names={}
      if okChrome and PcChrome and type(PcChrome.wallpaperNames)=="function" then local ok,v=pcall(PcChrome.wallpaperNames); if ok and type(v)=="table" then names=v end end
      if #names==0 then for i=1,16 do names[i]="WALLPAPER "..i end end
      local count=#names; local cur=tonumber(Box.wallpaperCursor) or 1; local rows={}
      for i=0,3 do local id=((cur-1+i)%count)+1; rows[#rows+1]=names[id] or ("WALLPAPER "..id) end
      popupList(rows,1,x+w*.55,y+h*.20,w*.30,c,body,small,"WALLPAPER")
    elseif Box.mode=="message" then
      card(gridX+gridW*.08,y+h*.72,gridW*.84,h*.12,c.surface,c.accent,5)
      text(Box._status or "",body,gridX+gridW*.12,y+h*.745,gridW*.76,"center",c.text)
    end

    drawFooter(x+pad,y+h-footerH*.82,w-pad*2,footerH*.48,c,small,"A SELECT / MOVE","B BACK")
  end

  -- Suppress only the native pixels while KIM owns these screens. Specialized
  -- release/marking animations stay source-rendered until they receive their own
  -- KIM presentation, so this first storage pass cannot break those flows.
  if not PcMenu.__kimGen3ModernPcV116 then
    local upstream=PcMenu.draw
    if type(upstream)=="function" then
      PcMenu.draw=function(...)
        if enabled() and hideOriginal() and isPcOpen() then return end
        return upstream(...)
      end
    end
    PcMenu.__kimGen3ModernPcV116=true
  end
  if not Box.__kimGen3ModernStorageV116 then
    local upstream=Box.draw
    if type(upstream)=="function" then
      Box.draw=function(...)
        local special=(Box.mode=="markings") or releaseActive()
        if enabled() and hideOriginal() and isBoxOpen() and not special then return end
        return upstream(...)
      end
    end
    Box.__kimGen3ModernStorageV116=true
  end

  mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
    nextFn(game,viewport)
    if not enabled() then setStorageFloating(false); return end
    if isBoxOpen() then
      local special=(Box.mode=="markings") or releaseActive()
      if special then setStorageFloating(false); return end
      setStorageFloating(true)
      local c=theme(); G.push("all"); G.origin(); G.setShader(); G.setBlendMode("alpha")
      drawStorage(viewport,c)
      G.setColor(1,1,1,1); G.pop(); return
    end
    setStorageFloating(false)
    if isPcOpen() then
      local c=theme(); G.push("all"); G.origin(); G.setShader(); G.setBlendMode("alpha")
      drawPc(viewport,c)
      G.setColor(1,1,1,1); G.pop()
    end
  end,10950)

  mod.exports=mod.exports or {}; mod.exports.gen3ModernStorageUi=true
  return true
end
