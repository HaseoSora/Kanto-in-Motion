-- Kanto in Motion - Gen 3 Modern Pokedex v80
--
-- Presentation-only replacement for Game3's FR/LG Pokedex screens.  Game3
-- keeps complete ownership of Dex state, input, navigation, cries and close
-- callbacks; KIM suppresses only the native pixels while the Pokedex is open.
return function(mod)
  local unpack = table.unpack or unpack
  if not (love and love.graphics and mod and mod.hooks and type(mod.hooks.wrap)=="function") then
    return false
  end

  local G=love.graphics
  local Style=mod._kantoInMotionGen3Ui
  local okDexUi,Pokedex=pcall(require,"src.ui.game3.pokedex")
  local okPokemon,Pokemon=pcall(require,"src.core.game3.pokemon")
  local okDex,Dex=pcall(require,"src.core.game3.dex")
  local okData,PokedexData=pcall(require,"src.core.game3.pokedex_data")
  local okTypes,Types=pcall(require,"src.core.game3.battle.types")
  local okChrome,PokedexChrome=pcall(require,"src.ui.game3.pokedex_chrome")
  local okStack,Stack=pcall(require,"src.ui.game3.stack")
  if not (okDexUi and type(Pokedex)=="table" and okPokemon and type(Pokemon)=="table"
      and okDex and type(Dex)=="table" and okData and type(PokedexData)=="table") then
    return false
  end

  local FALLBACK={
    surface={0.075,0.105,0.17,1},raised={0.12,0.17,0.27,1},
    selected={0.18,0.43,0.72,1},accent={0.48,0.86,1,1},
    frame={0.48,0.86,1,1},frameShadow={0.01,0.02,0.04,0.42},
    text={0.96,0.98,1,1},muted={0.74,0.82,0.92,1},divider={0.38,0.50,0.68,0.94},
  }
  local fonts={}

  local function opt(key,fallback)
    if not (mod.options and type(mod.options.get)=="function") then return fallback end
    local ok,v=pcall(mod.options.get,mod.options,key)
    if not ok or v==nil then return fallback end
    return v
  end
  local function enabled()
    if Style and Style.presenterEnabled then return Style.presenterEnabled("pokemon") end
    return opt("gen3IntegratedModernUi",true)~=false
  end
  local function uiScaleFactor()
    if Style and Style.uiScale then local ww,wh=G.getDimensions(); return Style.uiScale(ww,wh) end
    local value=tostring(opt("gen3UiScale","100")); if value:lower()=="auto" then return 1 end
    local pct=tonumber(value) or 100; pct=math.max(75,math.min(400,pct)); return pct/100
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
    px=math.max(9,math.floor((tonumber(px) or 12)+.5))
    if fonts[px] then return fonts[px] end
    local ok,f=pcall(G.newFont,px)
    if ok and f then
      if type(f.setFilter)=="function" then pcall(f.setFilter,f,"nearest","nearest") end
      fonts[px]=f; return f
    end
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
    local suf="..."; local target=math.max(0,maxW-f:getWidth(suf))
    while #v>0 and f:getWidth(v)>target do v=v:sub(1,#v-1) end
    return v..suf
  end

  local function cleanDexText(v,compact)
    local out=tostring(v or "")
    out=out:gsub("\r\n","\n"):gsub("\r","\n")
    out=out:gsub(string.char(0xFC,0x13)..".","")
    out=out:gsub("{UNK_SPACER}"," ")
    out=out:gsub("{CLEAR_TO[^}]*}",""):gsub("{CLEAR[^}]*}","")
    out=out:gsub("[\1-\8\11\12\14-\31]","")
    if compact then
      out=out:gsub("\n+"," "):gsub("%s+"," ")
      return (out:match("^%s*(.-)%s*$") or "")
    end
    local lines={}
    for line in (out.."\n"):gmatch("(.-)\n") do
      line=line:gsub("[ \t]+"," ")
      line=line:match("^%s*(.-)%s*$") or ""
      lines[#lines+1]=line
    end
    while #lines>0 and lines[#lines]=="" do table.remove(lines) end
    return table.concat(lines,"\n")
  end

  local function wrappedLineCount(f,value,maxW)
    value=tostring(value or "")
    if value=="" then return 0 end
    if f and type(f.getWrap)=="function" then
      local ok,a,b=pcall(f.getWrap,f,value,maxW)
      if ok then
        local lines=type(a)=="table" and a or (type(b)=="table" and b or nil)
        if lines then return math.max(1,#lines) end
      end
    end
    local n=0
    for line in (value.."\n"):gmatch("(.-)\n") do
      local width=(f and f.getWidth and f:getWidth(line)) or 0
      n=n+math.max(1,math.ceil(width/math.max(1,maxW)))
    end
    return math.max(1,n)
  end

  local function drawDexParagraph(value,x,y,w,h,c,s)
    local clean=cleanDexText(value,false)
    if clean=="" or h<=0 or w<=0 then return end
    local base=5.8*s
    local minPx=math.max(2.2*s,4)
    local step=math.max(.28*s,.75)
    local chosen=font(base)
    local px=base
    while px>=minPx do
      local f=font(px)
      local lines=wrappedLineCount(f,clean,w)
      local lineH=f:getHeight()*((type(f.getLineHeight)=="function" and f:getLineHeight()) or 1)
      chosen=f
      if lines*lineH<=h+.5 then break end
      px=px-step
    end
    local ox,oy,ow,oh=G.getScissor()
    G.setScissor(x,y,w,h)
    text(clean,chosen,x,y,w,"left",c)
    if ox then G.setScissor(ox,oy,ow,oh) else G.setScissor() end
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
  local function card(x,y,w,h,fill,line,r)
    r=r or math.max(4,math.min(w,h)*.04)
    local pa=Style and Style.panelOpacity and Style.panelOpacity(1) or 1
    color(fill,math.min(1,(fill and fill[4] or 1)*pa),false); G.rectangle("fill",x,y,w,h,r,r)
    if line then
      color(line,nil,true); G.setLineWidth(math.max(1,math.min(w,h)*.008))
      G.rectangle("line",x+.5,y+.5,math.max(0,w-1),math.max(0,h-1),r,r)
    end
  end
  local function chevron(cx,cy,size,dir,c)
    size=math.max(4,tonumber(size) or 8); color(c); G.setLineWidth(math.max(1,size*.14))
    if dir=="up" then G.line(cx-size*.38,cy+size*.24,cx,cy-size*.24,cx+size*.38,cy+size*.24)
    elseif dir=="down" then G.line(cx-size*.38,cy-size*.24,cx,cy+size*.24,cx+size*.38,cy-size*.24)
    elseif dir=="left" then G.line(cx+size*.28,cy-size*.38,cx-size*.24,cy,cx+size*.28,cy+size*.38)
    else G.line(cx-size*.28,cy-size*.38,cx+size*.24,cy,cx-size*.28,cy+size*.38) end
  end
  local function modernWindow(viewport,c)
    local sx,sy,sw,sh=playfield(viewport)
    local roomy=sw>=720 and sh>=460
    local us=uiScaleFactor()
    local w=math.min(sw*.97,sw*(roomy and .82 or .95)*us)
    local h=math.min(sh*.97,sh*(roomy and .88 or .94)*us)
    if Style and Style.layoutStyle and Style.layoutStyle()=="full" then w=sw*.94; h=sh*.92 end
    local x=sx+(sw-w)*.5; local y=sy+(sh-h)*.5
    local r=math.max(7,math.min(w,h)*.018)
    if Style and Style.panel then
      Style.panel(x,y,w,h,c,1)
      color(c.accent,nil,true); G.rectangle("fill",x,y,w,math.max(2,h*.012),r,r)
    else
      color(c.frameShadow or FALLBACK.frameShadow,nil,false); G.rectangle("fill",x+w*.006,y+h*.009,w,h,r,r)
      color(c.surface,nil,false); G.rectangle("fill",x,y,w,h,r,r)
      color(c.accent,nil,true); G.rectangle("fill",x,y,w,math.max(2,h*.012),r,r)
      color(c.frame,nil,true); G.setLineWidth(math.max(1,math.min(w,h)*.0035)); G.rectangle("line",x+.5,y+.5,w-1,h-1,r,r)
    end
    return x,y,w,h
  end

  local function setFloating(on)
    if not (okStack and Stack and type(Stack._layers)=="table") then return end
    for i=#Stack._layers,1,-1 do
      local layer=Stack._layers[i]
      if layer and layer.id=="pokedex" then
        if on then
          if layer._kimGen3DexOriginal==nil then
            layer._kimGen3DexOriginal={hideBelow=layer.hideBelow,drawUnder=layer.drawUnder,fullscreen=layer.fullscreen}
          end
          layer.hideBelow=false; layer.drawUnder=true; layer.fullscreen=false
        elseif layer._kimGen3DexOriginal then
          local o=layer._kimGen3DexOriginal
          layer.hideBelow=o.hideBelow; layer.drawUnder=o.drawUnder; layer.fullscreen=o.fullscreen
          layer._kimGen3DexOriginal=nil
        end
        return
      end
    end
  end

  local function isOpen()
    if type(Pokedex.isOpen)=="function" then local ok,v=pcall(Pokedex.isOpen); if ok then return v==true end end
    return Pokedex.open==true
  end
  local function speciesName(sp)
    if type(Pokemon.name)=="function" then local ok,v=pcall(Pokemon.name,sp); if ok and v then return tostring(v) end end
    return "POKéMON"
  end
  local function natDex(sp)
    if type(Pokemon.national)=="function" then local ok,v=pcall(Pokemon.national,sp); if ok and tonumber(v) then return tonumber(v) end end
    return tonumber(sp) or 0
  end
  local function completeDexRecordFor(sp)
    local nat=natDex(sp)
    if nat < 387 or nat > 1025 then return nil,false end
    local resolver=mod._kantoInMotion1025DexRecord
    if type(resolver)~="function" then return nil,false end
    local ok,record,active=pcall(resolver,nat)
    if not ok or active~=true then return nil,false end
    return type(record)=="table" and record or nil,true
  end
  local function completeDexEntryFor(sp)
    local record,active=completeDexRecordFor(sp)
    if not active then return nil,false end
    if not record then return nil,true end
    local de=type(record.dexEntry)=="table" and record.dexEntry or {}
    local feet=tonumber(de.heightFt)
    local inches=tonumber(de.heightIn)
    if (feet==nil or inches==nil) and tonumber(de.heightM) and tonumber(de.heightM)>0 then
      local totalIn=math.floor(tonumber(de.heightM)*39.37007874+.5)
      feet=math.floor(totalIn/12); inches=totalIn-feet*12
    elseif (feet==nil or inches==nil) and tonumber(de.height) and tonumber(de.height)>0 then
      local totalIn=math.floor((tonumber(de.height)/10)*39.37007874+.5)
      feet=math.floor(totalIn/12); inches=totalIn-feet*12
    end
    feet=feet or 0; inches=inches or 0
    local weight=tonumber(de.weight)
    -- Public 1025Dex source records use pounds; Game3-shaped records use
    -- hectograms.  Prefer weightKg when present and use the height field shape
    -- to distinguish an engine record from the source record.
    if tonumber(de.weightKg) and tonumber(de.weightKg)>0 then
      weight=tonumber(de.weightKg)*2.2046226218
    elseif de.heightFt==nil and de.heightIn==nil and de.heightM==nil
        and tonumber(de.height) and tonumber(de.height)>0 and weight and weight>0 then
      weight=(weight/10)*2.2046226218
    end
    weight=weight or 0
    local kind=tostring(de.kind or "")
    local category=(kind~="" and kind or "---").." POKéMON"
    return {
      categoryName=category,
      heightFormatted=string.format("%d'%02d\"",feet,inches),
      weightFormatted=string.format("%.1f lbs.",weight),
      description=tostring(record._kimDexDescription or ""),
    },true
  end
  local function seen(sp)
    return Pokedex._dex and type(Dex.isSeen)=="function" and Dex.isSeen(Pokedex._dex,sp)==true
  end
  local function caught(sp)
    return Pokedex._dex and type(Dex.isCaught)=="function" and Dex.isCaught(Pokedex._dex,sp)==true
  end
  local function defaultPersonality(sp)
    if type(Dex.defaultPersonality)=="function" then local ok,v=pcall(Dex.defaultPersonality,Pokedex._dex,sp); if ok then return tonumber(v) or 0 end end
    return 0
  end
  local function drawDexPreview(sp,x,y,w,h)
    if not sp then return false end
    local personality=defaultPersonality(sp)
    local provider=mod._kantoInMotionGen3HdDexPreviewDraw
    if type(provider)=="function" then
      local ok,drawn=pcall(provider,sp,personality,x,y,w,h)
      if ok and drawn then return true end
    end
    local pic
    local completePic=mod._kantoInMotion1025DexFrontPic
    if type(completePic)=="function" then
      local ok,v,active1025=pcall(completePic,sp,personality,false)
      if ok and active1025==true and v and v.image then pic=v end
    end
    if not (pic and pic.image) and type(Pokemon.dexFrontPic)=="function" then
      local ok,v=pcall(Pokemon.dexFrontPic,sp,personality)
      if ok and v and v.image then pic=v end
    end
    -- Normal Gen 3 species can still use the current engine provider.
    if not (pic and pic.image) and type(Pokemon.frontPic)=="function" then
      local picSp=sp
      if type(Pokemon.picSpecies)=="function" then
        local ok,v=pcall(Pokemon.picSpecies,sp,personality); if ok and v then picSp=v end
      end
      local ok,v=pcall(Pokemon.frontPic,picSp,nil,false,personality)
      if ok and v and v.image then pic=v end
    end
    if pic and pic.image then
      local img=pic.image; local iw,ih=img:getDimensions(); local scale=math.min(w/iw,h/ih)*.88
      color({1,1,1,1}); G.draw(img,x+(w-iw*scale)*.5,y+(h-ih*scale)*.5,0,scale,scale); return true
    end
    return false
  end
  local function typeNames(sp)
    local out={}
    if type(Pokemon.types)=="function" then
      local ok,t=pcall(Pokemon.types,sp)
      if ok and type(t)=="table" then
        for i=1,2 do
          if t[i]~=nil then
            local name
            if okTypes and Types and type(Types.name)=="function" then
              local okName,v=pcall(Types.name,t[i]); if okName and v then name=tostring(v) end
            end
            name=(name or tostring(t[i])):upper()
            if #out==0 or out[#out]~=name then out[#out+1]=name end
          end
        end
      end
    end
    return table.concat(out," / ")
  end
  -- Convert 1025Dex's live map pool into the FR/LG DEX_AREA keys used by
  -- the vanilla Town Map renderer.  When 1025Dex is active its live encounter
  -- pool is authoritative; without it, fall straight back to native FR/LG data.
  local function completeDexAreas(sp)
    local resolver=mod._kantoInMotion1025DexWildMaps
    if type(resolver)~="function" then return nil,false end
    local ok,maps,active=pcall(resolver,sp)
    if not ok or active~=true then return nil,false end
    maps=type(maps)=="table" and maps or {}

    if type(PokedexData.init)=="function" then pcall(PokedexData.init) end
    local areaData=PokedexData._areaData
    local mapsecToArea=areaData and areaData.mapsecToArea or {}
    local markers=areaData and areaData.markers or {}
    local okCat,MapCatalog=pcall(require,"src.import.gba.map_catalog")
    local okFam,Family=pcall(require,"src.import.gba.family")
    local okMs,MapSectionsExtract=pcall(require,"src.import.gba.map_sections_extract")
    local groups=okFam and Family and Family.active and Family.active():groups() or nil
    local out,seen={},{ }
    if okCat and MapCatalog and groups and groups.groups and okMs and MapSectionsExtract then
      for _,mapId in ipairs(maps) do
        local g,n=MapCatalog.groupNumFor(mapId)
        local gt=g and (groups.groups[g] or groups.groups[g+1]) or nil
        local pret=gt and gt.maps and (gt.maps[(n or -1)+1] or gt.maps[n]) or nil
        local info=pret and MapSectionsExtract.getInfo and MapSectionsExtract.getInfo(nil,pret) or nil
        local area=info and mapsecToArea[info.id] or nil
        if not area and pret then
          local norm="DEX_AREA_"..tostring(pret):gsub("^FR_",""):gsub("^SEVII_",""):gsub("([a-z])([A-Z])","%1_%2"):upper()
          if markers[norm] then area=norm end
        end
        if area and not seen[area] then seen[area]=true; out[#out+1]=area end
      end
    end
    return out,true
  end

  local function counts(scope)
    local s,o=0,0
    if Pokedex._dex and type(Dex.countSeen)=="function" then local ok,v=pcall(Dex.countSeen,Pokedex._dex,scope); if ok then s=tonumber(v) or 0 end end
    if Pokedex._dex and type(Dex.countCaught)=="function" then local ok,v=pcall(Dex.countCaught,Pokedex._dex,scope); if ok then o=tonumber(v) or 0 end end
    return s,o
  end
  local function nationalUnlocked()
    if type(PokedexData.isNationalUnlocked)=="function" then local ok,v=pcall(PokedexData.isNationalUnlocked,Pokedex._session,Pokedex._dex); if ok then return v==true end end
    return false
  end
  local function habitatTitle(id)
    return tostring(id or "HABITAT"):gsub("_"," "):upper()
  end
  local function pageHeader(x,y,w,pad,titleF,smallF,c,right)
    text("POKéDEX",titleF,x+pad,y+pad*.50,w*.35,"left",c.text)
    if right then text(right,smallF,x+w*.45,y+pad*.80,w*.48-pad,"right",c.muted) end
  end
  local function footer(x,y,w,h,pad,smallF,c,label,drawPickArrows)
    color(c.divider,.55); G.rectangle("fill",x,y,w,math.max(1,h*.035))
    local ty=y+(h-smallF:getHeight())*.5
    if drawPickArrows then
      -- Do not depend on Unicode arrow glyph coverage in the selected font.
      -- Draw the up/down PICK indicator as vector chevrons so it is visible on
      -- every FR/LG font/theme just like the source D-pad hint.
      local clean=tostring(label or ""):gsub("^↑↓%s*","")
      local tw=smallF:getWidth(clean)
      local iconW=math.max(10,smallF:getHeight()*1.15)
      local gap=math.max(4,smallF:getHeight()*0.32)
      local total=iconW+gap+tw
      local sx=x+(w-total)*0.5
      local cx=sx+iconW*0.5
      local cy=y+h*0.5
      local sz=math.max(4,smallF:getHeight()*0.50)
      chevron(cx,cy-sz*.42,sz,"up",c.muted)
      chevron(cx,cy+sz*.42,sz,"down",c.muted)
      text(clean,smallF,sx+iconW+gap,ty,tw+2,"left",c.muted)
    else
      text(label,smallF,x+pad,ty,w-pad*2,"center",c.muted)
    end
  end

  local function drawModeSelect(x,y,w,h,c,s,pad,header,footerH,titleF,bodyF,smallF)
    pageHeader(x,y,w,pad,titleF,smallF,c,"TABLE OF CONTENTS")
    local cy=y+header; local fy=y+h-footerH; local leftW=w*.64
    color(c.divider,.6); G.rectangle("fill",x+leftW,cy,math.max(1,s),fy-cy)
    local rows=Pokedex.MODES or {}; local start=(tonumber(Pokedex.modeScroll) or 0)+1
    local maxVisible=9; local rowH=(fy-cy)/maxVisible
    for vr=1,maxVisible do
      local i=start+vr-1; local m=rows[i]; if not m then break end
      local ry=cy+(vr-1)*rowH
      if m.isHeader then
        text(fit(m.label or "",smallF,leftW-pad*2),smallF,x+pad,ry+(rowH-smallF:getHeight())*.5,leftW-pad*2,"left",c.accent)
      else
        local selected=i==(tonumber(Pokedex.modeCursor) or 1)
        if selected then card(x+pad*.55,ry+rowH*.08,leftW-pad*1.1,rowH*.84,c.selected,c.accent,3*s) end
        text(fit(m.label or m.id or "",bodyF,leftW-pad*2.6),bodyF,x+pad*1.3,ry+(rowH-bodyF:getHeight())*.5,leftW-pad*2.4,"left",m.unlocked==false and c.divider or (selected and c.text or c.muted))
      end
    end
    local rx=x+leftW+pad; local rw=w-leftW-pad*2
    local ks,ko=counts("kanto")
    text("SEEN",smallF,rx,cy+pad*.6,rw*.58,"left",c.muted); text(ks,bodyF,rx+rw*.58,cy+pad*.45,rw*.42,"right",c.text)
    text("OWNED",smallF,rx,cy+pad*.6+bodyF:getHeight()+7*s,rw*.58,"left",c.muted); text(ko,bodyF,rx+rw*.58,cy+pad*.45+bodyF:getHeight()+7*s,rw*.42,"right",c.text)
    text("KANTO",smallF,rx,cy+pad*.6+bodyF:getHeight()*2+14*s,rw,"left",c.accent)
    if nationalUnlocked() then
      local ns,no=counts("national"); local yy=cy+(fy-cy)*.50
      text("NATIONAL",smallF,rx,yy,rw,"left",c.accent)
      text("SEEN",smallF,rx,yy+smallF:getHeight()+6*s,rw*.58,"left",c.muted); text(ns,bodyF,rx+rw*.58,yy+smallF:getHeight()+3*s,rw*.42,"right",c.text)
      text("OWNED",smallF,rx,yy+smallF:getHeight()+bodyF:getHeight()+12*s,rw*.58,"left",c.muted); text(no,bodyF,rx+rw*.58,yy+smallF:getHeight()+bodyF:getHeight()+9*s,rw*.42,"right",c.text)
    end
    footer(x,fy,w,footerH,pad,smallF,c,"↑↓ PICK    A OK    B BACK",true)
  end

  local function drawOrderedList(x,y,w,h,c,s,pad,header,footerH,titleF,bodyF,smallF)
    local order=tostring(Pokedex.currentOrder or "numerical_kanto")
    pageHeader(x,y,w,pad,titleF,smallF,c,order=="numerical_national" and "NATIONAL" or "KANTO")
    local list=type(PokedexData.getOrderList)=="function" and PokedexData.getOrderList(Pokedex.currentOrder,Pokedex._dex) or {}
    local cy=y+header; local fy=y+h-footerH; local visible=9; local rowH=(fy-cy)/visible
    local scroll=tonumber(Pokedex.listScroll) or 0; local cursor=tonumber(Pokedex.listCursor) or 1
    for vr=1,visible do
      local idx=scroll+vr; local sp=list[idx]; if not sp then break end
      local ry=cy+(vr-1)*rowH; local sel=idx==cursor; local isSeen=seen(sp); local isCaught=caught(sp)
      if sel then card(x+pad*.55,ry+rowH*.08,w-pad*1.1,rowH*.84,c.selected,c.accent,3*s) end
      local num=(order=="numerical_kanto") and tonumber(sp) or natDex(sp)
      text(string.format("#%03d",tonumber(num) or 0),smallF,x+pad*1.25,ry+(rowH-smallF:getHeight())*.5,w*.12,"left",sel and c.text or c.muted)
      if isCaught then color(c.accent); G.circle("fill",x+w*.20,ry+rowH*.50,math.max(2,s*1.9)) end
      local name=isSeen and speciesName(sp) or "-----"
      text(fit(name,bodyF,w*.36),bodyF,x+w*.23,ry+(rowH-bodyF:getHeight())*.5,w*.36,"left",sel and c.text or c.muted)
      if isCaught then text(fit(typeNames(sp),smallF,w*.31),smallF,x+w*.62,ry+(rowH-smallF:getHeight())*.5,w*.31,"right",sel and c.text or c.muted) end
    end
    if scroll>0 then chevron(x+w-pad*.45,cy+5*s,8*s,"up",c.accent) end
    if scroll+visible<#list then chevron(x+w-pad*.45,fy-5*s,8*s,"down",c.accent) end
    footer(x,fy,w,footerH,pad,smallF,c,"↑↓ PICK    A OK    B BACK    L/R PAGE",true)
  end

  local function drawCategory(x,y,w,h,c,s,pad,header,footerH,titleF,bodyF,smallF)
    local pages=type(PokedexData.getUnlockedCategoryPages)=="function" and PokedexData.getUnlockedCategoryPages(Pokedex.currentCategory,Pokedex._dex) or {}
    local pi=math.max(1,tonumber(Pokedex.categoryPage) or 1); local page=pages[pi] or {}; local mons=page.mons or {}
    pageHeader(x,y,w,pad,titleF,smallF,c,habitatTitle(Pokedex.currentCategory).."   "..pi.."/"..math.max(1,#pages))
    local cy=y+header; local fy=y+h-footerH; local cols=2; local rows=2; local gap=pad*.75
    local cardW=(w-pad*2-gap)/cols; local cardH=(fy-cy-pad-gap)/rows
    local cur=tonumber(Pokedex.categorySlot) or 1
    for i=1,math.min(4,#mons) do
      local col=(i-1)%2; local row=math.floor((i-1)/2); local bx=x+pad+col*(cardW+gap); local by=cy+pad*.35+row*(cardH+gap)
      local sel=i==cur; card(bx,by,cardW,cardH,sel and c.selected or c.raised,sel and c.accent or c.divider,5*s)
      local sp=mons[i]; local isSeen=seen(sp); local isCaught=caught(sp); local previewW=cardW*.43
      if isSeen then drawDexPreview(sp,bx+pad*.45,by+pad*.30,previewW-pad*.4,cardH-pad*.6) else text("?",titleF,bx+pad,by+cardH*.35,previewW-pad, "center",c.muted) end
      local tx=bx+previewW; local tw=cardW-previewW-pad*.55
      local name=isSeen and speciesName(sp) or "-----"
      text(fit(name,bodyF,tw),bodyF,tx,by+cardH*.24,tw,"left",sel and c.text or c.muted)
      text(string.format("#%03d",natDex(sp)),smallF,tx,by+cardH*.24+bodyF:getHeight()+3*s,tw,"left",c.muted)
      if isCaught then text(fit(typeNames(sp),smallF,tw),smallF,tx,by+cardH*.72,tw,"left",c.accent) end
    end
    footer(x,fy,w,footerH,pad,smallF,c,"D-PAD PICK    A CHECK    B BACK    L/R PAGE")
  end

  local function entryFor(sp)
    local expanded,active=completeDexEntryFor(sp)
    local e
    if active and expanded then e=expanded
    elseif okChrome and PokedexChrome and type(PokedexChrome.getEntry)=="function" then
      local ok,v=pcall(PokedexChrome.getEntry,sp); if ok and type(v)=="table" then e=v end
    end
    e=e or {}
    return {
      categoryName=cleanDexText(e.categoryName or "---",true),
      heightFormatted=cleanDexText(e.heightFormatted or "---",true),
      weightFormatted=cleanDexText(e.weightFormatted or "---",true),
      description=cleanDexText(e.description or "",false),
      description2=cleanDexText(e.description2 or "",false),
    }
  end
  local function drawData(x,y,w,h,c,s,pad,header,footerH,titleF,bodyF,smallF)
    local sp=tonumber(Pokedex._regSpecies or Pokedex.selectedSpecies) or 1; local reg=Pokedex.screen=="registration"; local page=tonumber(Pokedex.dataPage) or 1
    pageHeader(x,y,w,pad,titleF,smallF,c,reg and "NEW DATA" or ("DATA "..page.."/2"))
    local cy=y+header; local fy=y+h-footerH; local leftW=w*.38; local split=x+leftW
    color(c.divider,.62); G.rectangle("fill",split,cy,math.max(1,s),fy-cy)
    local lx=x+pad; local lw=leftW-pad*2; local rx=split+pad; local rw=w-leftW-pad*2
    drawDexPreview(sp,lx,cy+pad*.3,lw,(fy-cy)*.48)
    text(fit(speciesName(sp),bodyF,lw),bodyF,lx,cy+(fy-cy)*.53,lw,"center",c.text)
    text(string.format("#%03d",natDex(sp)),smallF,lx,cy+(fy-cy)*.53+bodyF:getHeight()+3*s,lw,"center",c.muted)
    if caught(sp) then text(fit(typeNames(sp),smallF,lw),smallF,lx,cy+(fy-cy)*.78,lw,"center",c.accent) end
    local e=entryFor(sp)
    if page==1 or reg then
      text("SPECIES DATA",bodyF,rx,cy+pad*.4,rw,"left",c.accent)
      local yy=cy+pad*.4+bodyF:getHeight()+6*s
      local rows={{"CATEGORY",e.categoryName or "---"},{"HEIGHT",e.heightFormatted or "---"},{"WEIGHT",e.weightFormatted or "---"}}
      for _,r in ipairs(rows) do text(r[1],smallF,rx,yy,rw*.34,"left",c.muted); text(fit(r[2],bodyF,rw*.62),bodyF,rx+rw*.36,yy-1*s,rw*.64,"left",c.text); yy=yy+math.max(bodyF:getHeight(),smallF:getHeight())+7*s end
      color(c.divider,.55); G.rectangle("fill",rx,yy+2*s,rw,math.max(1,s)); yy=yy+8*s
      text("DESCRIPTION",smallF,rx,yy,rw,"left",c.accent); yy=yy+smallF:getHeight()+4*s
      drawDexParagraph(e.description or "",rx,yy,rw,math.max(1,fy-yy-2*s),c.muted,s)
    else
      text("SIZE / AREA",bodyF,rx,cy+pad*.4,rw,"left",c.accent)
      local yy=cy+pad*.4+bodyF:getHeight()+8*s
      text("HEIGHT",smallF,rx,yy,rw*.35,"left",c.muted); text(tostring(e.heightFormatted or "---"),bodyF,rx+rw*.38,yy-1*s,rw*.62,"left",c.text); yy=yy+bodyF:getHeight()+8*s
      text("WEIGHT",smallF,rx,yy,rw*.35,"left",c.muted); text(tostring(e.weightFormatted or "---"),bodyF,rx+rw*.38,yy-1*s,rw*.62,"left",c.text); yy=yy+bodyF:getHeight()+12*s
      color(c.divider,.55); G.rectangle("fill",rx,yy,rw,math.max(1,s)); yy=yy+8*s
      local compatAreas,compatActive=completeDexAreas(sp)
      local areas=compatActive and compatAreas or (type(PokedexData.getWildAreasForSpecies)=="function" and PokedexData.getWildAreasForSpecies(sp) or {})
      text("KNOWN AREAS",smallF,rx,yy,rw,"left",c.accent); yy=yy+smallF:getHeight()+4*s
      local mapDrawn=false
      if okChrome and PokedexChrome and type(PokedexChrome.drawMap)=="function" then
        -- Keep the vanilla FR/LG map art/marker shapes.  1025Dex only changes
        -- which DEX_AREA keys feed them.  If its pool lives on a Sevii island,
        -- pick the vanilla island page containing the most matching areas.
        local mapKey="kanto"
        if compatActive and type(PokedexData.getAreaMapKey)=="function" then
          local counts={}
          for _,aKey in ipairs(areas or {}) do
            local key=PokedexData.getAreaMapKey(aKey) or "kanto"
            counts[key]=(counts[key] or 0)+1
          end
          local best=counts.kanto or 0
          for key,n in pairs(counts) do if n>best then mapKey,best=key,n end end
        end
        local nativeW,nativeH=96,72
        local maxW=rw; local maxH=math.max(1,fy-yy-pad*.25)
        local mapScale=math.min(maxW/nativeW,maxH/nativeH)
        mapScale=math.max(.60,mapScale)
        local mapW,mapH=nativeW*mapScale,nativeH*mapScale
        local mapX=rx+(rw-mapW)*.5; local mapY=yy+(maxH-mapH)*.5
        PokedexChrome.drawMap(mapKey,mapX,mapY,mapScale)
        local drawn=0
        for _,aKey in ipairs(areas or {}) do
          if type(PokedexData.getAreaMapKey)~="function" or PokedexData.getAreaMapKey(aKey)==mapKey then
            local m=type(PokedexData.getAreaMarker)=="function" and PokedexData.getAreaMarker(aKey) or nil
            if m and type(PokedexChrome.drawAreaMarker)=="function" then
              PokedexChrome.drawAreaMarker(m.shape,mapX+((tonumber(m.x) or 32)-32)*mapScale,mapY+(tonumber(m.y) or 0)*mapScale)
              drawn=drawn+1
            end
          end
        end
        mapDrawn=drawn>0
      end
      if not mapDrawn then text("AREA UNKNOWN",bodyF,rx,yy+math.max(0,(fy-yy-bodyF:getHeight())*.5),rw,"center",c.muted) end
    end
    local hint=reg and "A/B CONTINUE" or (page==1 and "A NEXT DATA    B BACK    START/SELECT CRY" or "A CANCEL    B PREVIOUS DATA    START/SELECT CRY")
    footer(x,fy,w,footerH,pad,smallF,c,hint)
  end

  local function drawPokedex(viewport,c)
    if not isOpen() then return false end
    setFloating(true)
    local x,y,w,h=modernWindow(viewport,c); local s=math.min(w/240,h/160)
    local pad=math.max(8*s,w*.018); local header=math.max(26*s,h*.145); local footerH=math.max(20*s,h*.125)
    local titleF,bodyF,smallF=font(10.2*s),font(7.7*s),font(5.8*s)
    local screen=tostring(Pokedex.screen or "mode_select")
    if screen=="mode_select" then drawModeSelect(x,y,w,h,c,s,pad,header,footerH,titleF,bodyF,smallF)
    elseif screen=="ordered_list" then drawOrderedList(x,y,w,h,c,s,pad,header,footerH,titleF,bodyF,smallF)
    elseif screen=="category_grid" then drawCategory(x,y,w,h,c,s,pad,header,footerH,titleF,bodyF,smallF)
    elseif screen=="data" or screen=="registration" then drawData(x,y,w,h,c,s,pad,header,footerH,titleF,bodyF,smallF)
    else return false end
    return true
  end

  -- Pokedex is fullscreen/opaque natively.  Preserve all source update/input
  -- behavior and only replace the visual layer while KIM Modern UI is enabled.
  if not Pokedex.__kimGen3ModernDexV67 then
    local upstreamDraw=Pokedex.draw
    if type(upstreamDraw)=="function" then
      Pokedex.draw=function(...)
        if enabled() and (not Style or not Style.hideOriginal or Style.hideOriginal()) and isOpen() then return end
        return upstreamDraw(...)
      end
    end
    local upstreamShow=Pokedex.show
    if type(upstreamShow)=="function" then
      Pokedex.show=function(...)
        local out={upstreamShow(...)}; if enabled() then setFloating(true) end; return unpack(out)
      end
    end
    local upstreamReg=Pokedex.showRegistration
    if type(upstreamReg)=="function" then
      Pokedex.showRegistration=function(...)
        local out={upstreamReg(...)}; if enabled() then setFloating(true) end; return unpack(out)
      end
    end
    Pokedex.__kimGen3ModernDexV67=true
  end

  mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
    nextFn(game,viewport)
    if not enabled() then setFloating(false); return end
    if not isOpen() then return end
    local c=theme()
    G.push("all"); G.origin(); G.setShader(); G.setBlendMode("alpha")
    drawPokedex(viewport,c)
    G.setColor(1,1,1,1); G.pop()
  end,11200)

  mod.exports=mod.exports or {}; mod.exports.gen3ModernPokedexUi=true
  return true
end
