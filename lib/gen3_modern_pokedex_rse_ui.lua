-- Kanto in Motion - Gen 3 R/S/E Modern Pokedex v85
--
-- Emerald/Ruby/Sapphire use src.ui.game3.rse.pokedex, which is a separate
-- implementation from FR/LG's src.ui.game3.pokedex.  Keep the RSE Pokedex as
-- the sole owner of navigation, search, cries, area/size pages and callbacks;
-- KIM replaces only the final presentation and uses the same HD Dex preview
-- provider as the FR/LG Modern Pokedex.
return function(mod)
  local unpack=table.unpack or unpack
  if not (love and love.graphics and mod and mod.hooks and type(mod.hooks.wrap)=="function") then
    return false
  end

  local G=love.graphics
  local Style=mod._kantoInMotionGen3Ui
  local okDex,RseDex=pcall(require,"src.ui.game3.rse.pokedex")
  local okPokemon,Pokemon=pcall(require,"src.core.game3.pokemon")
  local okTypes,Types=pcall(require,"src.core.game3.battle.types")
  local okStack,Stack=pcall(require,"src.ui.game3.stack")
  if not (okDex and type(RseDex)=="table" and okPokemon and type(Pokemon)=="table") then
    return false
  end

  local PAGE=RseDex.PAGE or { MAIN=0,INFO=1,SEARCH=2,SEARCH_RESULTS=3,AREA=5,CRY=6,SIZE=7,CAUGHT=8 }
  local SCREEN=RseDex.SCREEN or { AREA=0,CRY=1,SIZE=2,CANCEL=3 }
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
    c=c or {1,1,1,1}
    G.setColor(c[1] or 1,c[2] or 1,c[3] or 1,a==nil and (c[4] or 1) or a)
  end
  local function font(px)
    if Style and Style.font then return Style.font(px) end
    px=math.max(9,math.floor((tonumber(px) or 12)+.5))
    if fonts[px] then return fonts[px] end
    local ok,f=pcall(G.newFont,px)
    if ok and f then
      if type(f.setFilter)=="function" then pcall(f.setFilter,f,"nearest","nearest") end
      fonts[px]=f
      return f
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
    local suffix="..."; local target=math.max(0,maxW-f:getWidth(suffix))
    while #v>0 and f:getWidth(v)>target do v=v:sub(1,#v-1) end
    return v..suffix
  end

  -- R/S/E's native Pokédex strings can contain renderer-only control data.
  -- Those bytes/tags are meaningful to FrlgFont, but become visible garbage
  -- when a modern Love2D font receives the same string.  Normalize them at
  -- the presentation boundary instead of changing Game3's source state.
  local function cleanDexText(v,compact)
    local out=tostring(v or "")
    out=out:gsub("\r\n","\n"):gsub("\r","\n")
    -- pokeemerald EXT_CTRL_CODE_CLEAR_TO: FC 13 <pixel>.  Modern layout does
    -- its own alignment, so the entire three-byte directive is unnecessary.
    out=out:gsub(string.char(0xFC,0x13)..".","")
    -- CHAR_SPACER (0x77) is decoded to this tag by Game3.  It only pads
    -- right-aligned native numeric fields; normal spaces are sufficient here.
    out=out:gsub("{UNK_SPACER}"," ")
    out=out:gsub("{CLEAR_TO[^}]*}",""):gsub("{CLEAR[^}]*}","")
    -- Remove stray C0 controls while preserving newlines/tabs and UTF-8 text.
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

  -- Fit the complete flavor text into the description region.  This is only
  -- an adaptive presentation font: the underlying entry remains untouched.
  local function drawDexParagraph(value,x,y,w,h,c,sc)
    local clean=cleanDexText(value,false)
    if clean=="" or h<=0 or w<=0 then return end
    local base=5.8*sc
    local minPx=math.max(2.2*sc,4)
    local step=math.max(.28*sc,.75)
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
  local function pageHeader(x,y,w,pad,titleF,smallF,c,right)
    text("POKéDEX",titleF,x+pad,y+pad*.50,w*.35,"left",c.text)
    if right then text(right,smallF,x+w*.45,y+pad*.80,w*.48-pad,"right",c.muted) end
  end
  local function footer(x,y,w,h,pad,smallF,c,label)
    color(c.divider,.55); G.rectangle("fill",x,y,w,math.max(1,h*.035))
    text(label,smallF,x+pad,y+(h-smallF:getHeight())*.5,w-pad*2,"center",c.muted)
  end
  local function footerNav(x,y,w,h,pad,smallF,c,parts)
    color(c.divider,.55); G.rectangle("fill",x,y,w,math.max(1,h*.035))
    local gap=math.max(6,smallF:getHeight()*.72)
    local iconW=math.max(13,smallF:getHeight()*1.45)
    local total=0
    for _,part in ipairs(parts or {}) do
      total=total+((part=="lr" or part=="left" or part=="right") and iconW or smallF:getWidth(tostring(part)))
    end
    total=total+gap*math.max(0,#(parts or {})-1)
    local px=x+(w-total)*.5; local cy=y+h*.5; local ty=y+(h-smallF:getHeight())*.5
    for _,part in ipairs(parts or {}) do
      if part=="lr" then
        local sz=math.max(5,smallF:getHeight()*.58)
        chevron(px+iconW*.28,cy,sz,"left",c.muted)
        chevron(px+iconW*.72,cy,sz,"right",c.muted)
        px=px+iconW
      elseif part=="left" or part=="right" then
        local sz=math.max(5,smallF:getHeight()*.62)
        chevron(px+iconW*.5,cy,sz,part,c.muted)
        px=px+iconW
      else
        local label=tostring(part); local tw=smallF:getWidth(label)
        text(label,smallF,px,ty,tw+2,"left",c.muted); px=px+tw
      end
      px=px+gap
    end
  end

  local function active()
    if type(RseDex.active)=="function" then
      local ok,v=pcall(RseDex.active)
      if ok then return v end
    end
    return nil
  end
  local function setFloating(on)
    if not (okStack and Stack and type(Stack._layers)=="table") then return end
    for i=#Stack._layers,1,-1 do
      local layer=Stack._layers[i]
      if layer and layer.id=="rse_pokedex" then
        if on then
          if layer._kimGen3RseDexOriginal==nil then
            layer._kimGen3RseDexOriginal={hideBelow=layer.hideBelow,drawUnder=layer.drawUnder,fullscreen=layer.fullscreen}
          end
          layer.hideBelow=false; layer.drawUnder=true; layer.fullscreen=false
        elseif layer._kimGen3RseDexOriginal then
          local o=layer._kimGen3RseDexOriginal
          layer.hideBelow=o.hideBelow; layer.drawUnder=o.drawUnder; layer.fullscreen=o.fullscreen
          layer._kimGen3RseDexOriginal=nil
        end
        return
      end
    end
  end

  local function speciesOf(nat)
    if type(RseDex.speciesOf)=="function" then
      local ok,v=pcall(RseDex.speciesOf,nat); if ok then return tonumber(v) or 0 end
    end
    if type(Pokemon.speciesFromNational)=="function" then
      local ok,v=pcall(Pokemon.speciesFromNational,nat); if ok then return tonumber(v) or 0 end
    end
    return tonumber(nat) or 0
  end
  local function speciesName(sp)
    if type(Pokemon.name)=="function" then local ok,v=pcall(Pokemon.name,sp); if ok and v then return tostring(v) end end
    return "POKéMON"
  end
  local function completeDexRecordForNat(nat)
    nat=tonumber(nat)
    if not nat or nat < 387 or nat > 1025 then return nil,false end
    local resolver=mod._kantoInMotion1025DexRecord
    if type(resolver)~="function" then return nil,false end
    local ok,record,active=pcall(resolver,nat)
    if not ok or active~=true then return nil,false end
    return type(record)=="table" and record or nil,true
  end
  local function completeDexMeta(nat,owned)
    local record,active=completeDexRecordForNat(nat)
    if not active then return nil,false end
    if not record then return nil,true end
    local de=type(record.dexEntry)=="table" and record.dexEntry or {}
    local extra=type(RseDex.extraEntries)=="table" and RseDex.extraEntries[tonumber(nat)] or nil
    local kind=tostring(de.kind or (type(extra)=="table" and extra.category) or "")
    local feet=tonumber(de.heightFt)
    local inches=tonumber(de.heightIn)
    -- Depending on which layer of 1025Dex supplied the public record, the
    -- imperial convenience fields may be absent/zero while Emerald's
    -- extraEntries still carries the canonical decimetres.  Use whichever
    -- representation is actually populated.
    if (feet==nil or inches==nil or ((feet or 0)==0 and (inches or 0)==0))
        and type(extra)=="table" and tonumber(extra.height) and tonumber(extra.height)>0 then
      local totalIn=math.floor((tonumber(extra.height)/10)*39.37007874+.5)
      feet=math.floor(totalIn/12); inches=totalIn-feet*12
    elseif (feet==nil or inches==nil) and tonumber(de.heightM) and tonumber(de.heightM)>0 then
      local totalIn=math.floor(tonumber(de.heightM)*39.37007874+.5)
      feet=math.floor(totalIn/12); inches=totalIn-feet*12
    end
    feet=feet or 0; inches=inches or 0

    -- 1025Dex's generated dexEntry.weight is pounds, while RSE extraEntries
    -- stores hectograms.  Do not divide the public pounds value by ten.
    local weight=tonumber(de.weight)
    if tonumber(de.weightKg) and tonumber(de.weightKg)>0 then
      weight=tonumber(de.weightKg)*2.2046226218
    elseif de.heightFt==nil and de.heightIn==nil and de.heightM==nil
        and tonumber(de.height) and tonumber(de.height)>0 and weight and weight>0 then
      -- Game3-shaped dexEntry: height is decimetres and weight is hectograms.
      weight=(weight/10)*2.2046226218
    end
    if (weight==nil or weight<=0) and type(extra)=="table" and tonumber(extra.weight) and tonumber(extra.weight)>0 then
      weight=(tonumber(extra.weight)/10)*2.2046226218
    end
    weight=weight or 0
    local desc=tostring(record._kimDexDescription or (type(extra)=="table" and extra.description) or "")
    return {
      number=string.format("#%03d",tonumber(nat) or 0),
      name=tostring(record.name or speciesName(speciesOf(nat))),
      category=owned and ((kind~="" and kind or "---").." POKéMON") or "????? POKéMON",
      height=owned and string.format("%d'%02d\"",feet,inches) or "?????",
      weight=owned and string.format("%.1f lbs.",weight) or "?????",
      description=owned and desc or "",
    },true
  end
  local function typeNames(sp)
    local out={}
    if type(Pokemon.types)=="function" then
      local ok,t=pcall(Pokemon.types,sp)
      if ok and type(t)=="table" then
        for i=1,2 do
          if t[i]~=nil then
            local n
            if okTypes and Types and type(Types.name)=="function" then local o,v=pcall(Types.name,t[i]); if o and v then n=tostring(v) end end
            n=(n or tostring(t[i])):upper()
            if #out==0 or out[#out]~=n then out[#out+1]=n end
          end
        end
      end
    end
    return table.concat(out," / ")
  end
  local function drawDexPreview(sp,personality,x,y,w,h)
    if not sp or sp==0 then return false end
    personality=tonumber(personality) or 0
    local provider=mod._kantoInMotionGen3HdDexPreviewDrawNoPush or mod._kantoInMotionGen3HdDexPreviewDraw
    if type(provider)=="function" then
      local ok,drawn=pcall(provider,sp,personality,x,y,w,h)
      if ok and drawn then return true end
    end
    local pic
    -- KIM is the outer Pokemon.frontPic provider.  For post-Gen3 species ask
    -- the captured 1025Dex provider directly so the Modern Dex cannot recurse
    -- through KIM or fall into a non-existent ROM slot.
    local completePic=mod._kantoInMotion1025DexFrontPic
    if type(completePic)=="function" then
      local ok,v,active1025=pcall(completePic,sp,personality,false)
      if ok and active1025==true and v and v.image then pic=v end
    end
    if not (pic and pic.image) and type(Pokemon.dexFrontPic)=="function" then
      local ok,v=pcall(Pokemon.dexFrontPic,sp,personality); if ok and v and v.image then pic=v end
    end
    if not (pic and pic.image) and type(Pokemon.frontPic)=="function" then
      local picSp=sp
      if type(Pokemon.picSpecies)=="function" then
        local ok,v=pcall(Pokemon.picSpecies,sp,personality); if ok and v then picSp=v end
      end
      local ok,v=pcall(Pokemon.frontPic,picSp,nil,false,personality); if ok and v and v.image then pic=v end
    end
    if pic and pic.image then
      local img=pic.image; local iw,ih=img:getDimensions(); local sc=math.min(w/math.max(1,iw),h/math.max(1,ih))*.88
      color({1,1,1,1}); G.draw(img,x+(w-iw*sc)*.5,y+(h-ih*sc)*.5,0,sc,sc); return true
    end
    return false
  end
  local function currentItem(s)
    if not (s and s.list and type(s.list.items)=="table") then return nil end
    return s.list.items[tonumber(s.selected) or 0]
  end
  local function currentNat(s)
    local it=currentItem(s); return it and tonumber(it.dexNum) or nil
  end
  local function hoennNum(nat)
    if type(RseDex.hoennNumber)=="function" then local ok,v=pcall(RseDex.hoennNumber,nat); if ok and v then return tonumber(v) end end
    return tonumber(nat) or 0
  end
  local function displayNum(s,nat)
    if tonumber(s and s.dexMode)==0 then return hoennNum(nat) or nat end
    return tonumber(nat) or 0
  end
  local function monPersonality(s,sp)
    local dex=s and s.dex or {}
    local n=speciesName(sp):upper()
    if n=="UNOWN" then return tonumber(dex.unownPersonality) or 0 end
    if n=="SPINDA" then return tonumber(dex.spindaPersonality) or 0 end
    return 0
  end

  local function drawStartSubmenu(s,x,y,w,h,c,sc,pad,bodyF,smallF)
    if not s.menuIsOpen then return end
    local results=s.page==PAGE.SEARCH_RESULTS
    local labels=results and {"CANCEL","LIST TOP","LIST BOTTOM","BACK TO LIST","EXIT POKéDEX"}
                         or {"CANCEL","LIST TOP","LIST BOTTOM","EXIT POKéDEX"}
    local rw=math.min(w*.42,110*sc); local rh=math.max(14*sc,bodyF:getHeight()+5*sc)
    local ph=#labels*rh+pad; local px=x+w-rw-pad; local py=y+h-ph-pad
    card(px,py,rw,ph,c.surface,c.frame,5*sc)
    local cur=(tonumber(s.menuCursorPos) or 0)+1
    for i,v in ipairs(labels) do
      local yy=py+pad*.5+(i-1)*rh
      if i==cur then card(px+4*sc,yy,rw-8*sc,rh-1*sc,c.selected,c.accent,3*sc) end
      text(v,bodyF,px+8*sc,yy+(rh-bodyF:getHeight())*.5,rw-16*sc,"left",i==cur and c.text or c.muted)
    end
  end

  local function drawMain(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    local results=s.page==PAGE.SEARCH_RESULTS
    pageHeader(x,y,w,pad,titleF,smallF,c,results and "SEARCH RESULTS" or (tonumber(s.dexMode)==0 and "HOENN" or "NATIONAL"))
    local cy=y+header; local fy=y+h-footerH
    local leftW=w*.36; local split=x+leftW
    color(c.divider,.58); G.rectangle("fill",split,cy,math.max(1,sc),fy-cy)

    local nat=currentNat(s); local sp=nat and speciesOf(nat) or 0
    if sp~=0 then
      drawDexPreview(sp,monPersonality(s,sp),x+pad,cy+pad,leftW-pad*2,(fy-cy)*.53)
      text(fit(speciesName(sp),bodyF,leftW-pad*2),bodyF,x+pad,cy+(fy-cy)*.60,leftW-pad*2,"center",c.text)
      text(string.format("#%03d",displayNum(s,nat)),smallF,x+pad,cy+(fy-cy)*.60+bodyF:getHeight()+3*sc,leftW-pad*2,"center",c.muted)
      local it=currentItem(s)
      if it and it.owned then text(fit(typeNames(sp),smallF,leftW-pad*2),smallF,x+pad,cy+(fy-cy)*.78,leftW-pad*2,"center",c.accent) end
    end
    local counts=s.counts or {}
    local seen=tonumber(s.seenCount) or (tonumber(s.dexMode)==0 and tonumber(counts.hoennSeen) or tonumber(counts.nationalSeen)) or 0
    local owned=tonumber(s.ownCount) or (tonumber(s.dexMode)==0 and tonumber(counts.hoennOwned) or tonumber(counts.nationalOwned)) or 0
    text("SEEN  "..seen,smallF,x+pad,fy-smallF:getHeight()*2.2,leftW-pad*2,"left",c.muted)
    text("OWN  "..owned,smallF,x+pad,fy-smallF:getHeight()*1.1,leftW-pad*2,"left",c.muted)

    local listX=split+pad; local listW=w-leftW-pad*2
    local visible=8; local count=math.max(0,tonumber(s.list and s.list.count) or 0)
    local sel=math.max(0,math.min(math.max(0,count-1),tonumber(s.selected) or 0))
    local start=math.max(0,sel-math.floor(visible/2))
    if start+visible>count then start=math.max(0,count-visible) end
    local rowH=(fy-cy)/visible
    for vr=1,visible do
      local idx=start+vr-1
      if idx>=count then break end
      local it=s.list.items[idx]
      if it then
        local ry=cy+(vr-1)*rowH; local selected=idx==sel
        if selected then card(listX-pad*.35,ry+rowH*.08,listW+pad*.35,rowH*.84,c.selected,c.accent,3*sc) end
        local dn=displayNum(s,it.dexNum)
        text(string.format("#%03d",dn),smallF,listX,ry+(rowH-smallF:getHeight())*.5,listW*.22,"left",selected and c.text or c.muted)
        if it.owned then color(c.accent); G.circle("fill",listX+listW*.24,ry+rowH*.50,math.max(2,sc*1.8)) end
        local nm=it.seen and speciesName(speciesOf(it.dexNum)) or "-----"
        text(fit(nm,bodyF,listW*.64),bodyF,listX+listW*.29,ry+(rowH-bodyF:getHeight())*.5,listW*.64,"left",selected and c.text or c.muted)
      end
    end
    if start>0 then chevron(x+w-pad*.35,cy+5*sc,8*sc,"up",c.accent) end
    if start+visible<count then chevron(x+w-pad*.35,fy-5*sc,8*sc,"down",c.accent) end
    footer(x,fy,w,footerH,pad,smallF,c,"D-PAD PICK    A CHECK    START MENU    SELECT SEARCH    B BACK")
    drawStartSubmenu(s,x,y,w,h,c,sc,pad,bodyF,smallF)
  end

  local function infoTexts(s,nat,owned)
    local expanded,active=completeDexMeta(nat,owned)
    if active and expanded then
      return cleanDexText(expanded.number,true),cleanDexText(expanded.name,true),
        cleanDexText(expanded.category,true),cleanDexText(expanded.height,true),
        cleanDexText(expanded.weight,true),cleanDexText(expanded.description,false)
    end
    local arr=s.info and s.info.text or {}
    local function at(i,compact) return cleanDexText(arr[i] and arr[i].text or "",compact) end
    return at(1,true),at(2,true),at(3,true),at(6,true),at(7,true),at(#arr,false)
  end
  local function drawInfo(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    local info=s.info or {}; local nat=tonumber(info.dexNum) or currentNat(s) or 0; local sp=speciesOf(nat)
    pageHeader(x,y,w,pad,titleF,smallF,c,"POKéMON DATA")
    local cy=y+header; local fy=y+h-footerH

    -- Keep AREA / CRY / SIZE / CANCEL in a persistent top navigation row.
    local tabs={"AREA","CRY","SIZE","CANCEL"}; local sel=(tonumber(s.selectedScreen) or 0)+1
    local tabH=math.max(14*sc,smallF:getHeight()+5*sc); local tabW=(w-pad*2)/4
    local ty=cy+1.5*sc
    for i,v in ipairs(tabs) do
      local bx=x+pad+(i-1)*tabW
      if i==sel then card(bx,ty,tabW-2*sc,tabH,c.selected,c.accent,3*sc) end
      text(v,smallF,bx,ty+(tabH-smallF:getHeight())*.5,tabW-2*sc,"center",i==sel and c.text or c.muted)
    end

    local contentY=ty+tabH+4*sc; local leftW=w*.40; local split=x+leftW
    color(c.divider,.58); G.rectangle("fill",split,contentY,math.max(1,sc),fy-contentY)
    local contentH=math.max(1,fy-contentY)
    drawDexPreview(sp,monPersonality(s,sp),x+pad,contentY+pad*.20,leftW-pad*2,contentH*.52)
    text(fit(speciesName(sp),bodyF,leftW-pad*2),bodyF,x+pad,contentY+contentH*.60,leftW-pad*2,"center",c.text)
    text(string.format("#%03d",displayNum(s,nat)),smallF,x+pad,contentY+contentH*.60+bodyF:getHeight()+3*sc,leftW-pad*2,"center",c.muted)
    if info.owned then text(fit(typeNames(sp),smallF,leftW-pad*2),smallF,x+pad,contentY+contentH*.80,leftW-pad*2,"center",c.accent) end

    local num,name,category,heightText,weightText,desc=infoTexts(s,nat,info.owned==true)
    local rx=split+pad; local rw=w-leftW-pad*2; local yy=contentY+pad*.20
    text(name~="" and name or speciesName(sp),titleF,rx,yy,rw,"left",c.text); yy=yy+titleF:getHeight()+3*sc
    -- The native RSE info string uses the Numero sign (№), which the modern
    -- Love2D font can render as a missing-glyph box.  Use the same explicit
    -- ASCII # + three-digit display number as the left-side modern card.
    text(string.format("#%03d",displayNum(s,nat)),smallF,rx,yy,rw*.45,"left",c.muted); yy=yy+smallF:getHeight()+4*sc
    text("CATEGORY",smallF,rx,yy,rw*.35,"left",c.muted); text(fit(category,bodyF,rw*.60),bodyF,rx+rw*.38,yy-1*sc,rw*.62,"left",c.text); yy=yy+bodyF:getHeight()+5*sc
    text("HEIGHT",smallF,rx,yy,rw*.35,"left",c.muted); text(heightText,bodyF,rx+rw*.38,yy-1*sc,rw*.62,"left",c.text); yy=yy+bodyF:getHeight()+5*sc
    text("WEIGHT",smallF,rx,yy,rw*.35,"left",c.muted); text(weightText,bodyF,rx+rw*.38,yy-1*sc,rw*.62,"left",c.text); yy=yy+bodyF:getHeight()+5*sc
    color(c.divider,.45); G.rectangle("fill",rx,yy,rw,math.max(1,sc)); yy=yy+4*sc
    drawDexParagraph(desc,rx,yy,rw,math.max(1,fy-yy-2*sc),c.muted,sc)

    footerNav(x,fy,w,footerH,pad,smallF,c,{"lr","SELECT PAGE","A OPEN","B BACK"})
  end

  -- Resolve the current 1025Dex live encounter pool to Hoenn region-map
  -- section ids.  We keep Emerald's vanilla map image and only add presentation
  -- highlights for the locations 1025Dex says are currently valid.
  local function completeDexMapSecs(s,sp)
    local resolver=mod._kantoInMotion1025DexWildMaps
    if type(resolver)~="function" then return nil,false end
    local ok,maps,active=pcall(resolver,sp)
    if not ok or active~=true then return nil,false end
    maps=type(maps)=="table" and maps or {}
    local okR,Runtime=pcall(require,"src.core.game3.runtime")
    local game=okR and Runtime and (Runtime._game or (Runtime.getGame and Runtime.getGame())) or nil
    local defs=game and game.data and game.data.maps or {}
    local okCat,MapCatalog=pcall(require,"src.import.gba.map_catalog")
    local okRm,RegionMap=pcall(require,"src.ui.game3.rse.region_map")
    local out,seen={},{}
    for _,mapId in ipairs(maps) do
      local id=okCat and MapCatalog and MapCatalog.resolve and MapCatalog.resolve(mapId) or mapId
      local def=defs[id] or defs[mapId]
      local sec=def and tonumber(def.regionMapSectionId) or nil
      if sec and okRm and RegionMap and type(RegionMap.correctSpecialMapSecId)=="function" then
        local okC,v=pcall(RegionMap.correctSpecialMapSecId,{session=s.session},sec)
        if okC and tonumber(v) then sec=tonumber(v) end
      end
      if sec and not seen[sec] then seen[sec]=true; out[#out+1]=sec end
    end
    return out,true
  end

  local function drawArea(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    pageHeader(x,y,w,pad,titleF,smallF,c,"AREA")
    local cy=y+header; local fy=y+h-footerH; local a=s.area or {}
    local boxX=x+pad; local boxY=cy+pad*.35; local boxW=w-pad*2; local boxH=fy-boxY-pad*.35
    card(boxX,boxY,boxW,boxH,c.raised,c.divider,5*sc)
    local nat=currentNat(s) or 0; local sp=speciesOf(nat)
    local compatSecs,compatActive=completeDexMapSecs(s,sp)
    local compatSet={}; for _,sec in ipairs(compatSecs or {}) do compatSet[sec]=true end
    local compatHas=next(compatSet)~=nil
    if a.map then
      local iw,ih=a.map:getDimensions(); local drawW=boxW-pad*2; local drawH=boxH-pad*2
      local scale=math.min(drawW/math.max(1,iw),drawH/math.max(1,ih)); local dx=boxX+(boxW-iw*scale)*.5; local dy=boxY+(boxH-ih*scale)*.5
      local minf,magf,aniso
      if type(a.map.getFilter)=="function" then minf,magf,aniso=a.map:getFilter() end
      if type(a.map.setFilter)=="function" then pcall(a.map.setFilter,a.map,"linear","linear") end
      color({1,1,1,1}); G.draw(a.map,dx,dy,0,scale,scale)
      if type(a.map.setFilter)=="function" and minf and magf then pcall(a.map.setFilter,a.map,minf,magf,aniso or 1) end

      if compatActive then
        -- RegionMap's vanilla layout is a 28x15 grid in 8px cells.  Highlight
        -- every cell whose map-section id belongs to 1025Dex's live pool.
        local okRm,RegionMap=pcall(require,"src.ui.game3.rse.region_map")
        if okRm and RegionMap and type(RegionMap.mapSecAt)=="function" then
          for gy=RegionMap.CURSOR_Y_MIN or 2,RegionMap.CURSOR_Y_MAX or 16 do
            for gx=RegionMap.CURSOR_X_MIN or 1,RegionMap.CURSOR_X_MAX or 28 do
              local sec=RegionMap.mapSecAt(gx,gy)
              if compatSet[sec] then
                local px=dx+gx*8*scale; local py=dy+(gy*8+8)*scale
                color(c.accent,.34); G.rectangle("fill",px,py,8*scale,8*scale,math.max(1,1.4*sc),math.max(1,1.4*sc))
                color(c.accent,.92); G.setLineWidth(math.max(1,sc*.65)); G.rectangle("line",px,py,8*scale,8*scale,math.max(1,1.4*sc),math.max(1,1.4*sc))
              end
            end
          end
        end
      else
        for _,m in ipairs(a.markers or {}) do
          local mx=dx+(tonumber(m.x) or 0)*scale; local my=dy+(tonumber(m.y) or 0)*scale
          color(c.accent); G.circle("fill",mx,my,math.max(3,3.2*sc))
        end
      end
      if a.player and not a.player.hidden then
        local px=dx+(tonumber(a.player.x) or 0)*scale; local py=dy+(tonumber(a.player.y) or 0)*scale
        color(c.text); G.circle("line",px,py,math.max(4,4.2*sc))
      end
    end
    local unknown=compatActive and not compatHas or (not compatActive and a.unknown)
    if unknown then
      text("AREA UNKNOWN",bodyF,boxX,boxY+boxH*.45,boxW,"center",{0.20,0.07,0.10,0.96})
    end
    footerNav(x,fy,w,footerH,pad,smallF,c,{"lr","CHANGE PAGE","B BACK"})
  end

  local function drawCry(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    local nat=currentNat(s) or 0; local sp=speciesOf(nat)
    pageHeader(x,y,w,pad,titleF,smallF,c,"CRY")
    local cy=y+header; local fy=y+h-footerH
    local leftW=w*.32; drawDexPreview(sp,monPersonality(s,sp),x+pad,cy+pad,leftW-pad*2,(fy-cy)*.58)
    text(fit(speciesName(sp),bodyF,leftW-pad*2),bodyF,x+pad,cy+(fy-cy)*.67,leftW-pad*2,"center",c.text)
    local wx=x+leftW+pad*.2; local wy=cy+pad; local ww=w-leftW-pad*1.7; local wh=(fy-cy)-pad*2
    card(wx,wy,ww,wh,c.raised,c.divider,5*sc)
    text("WAVEFORM",smallF,wx+pad*.6,wy+pad*.5,ww-pad,"left",c.accent)
    local wave=s.cry and s.cry.pixels
    if type(wave)=="table" then
      local gx=wx+pad*.6; local gy=wy+pad*1.5+smallF:getHeight(); local gw=ww-pad*1.2; local gh=wh-pad*2.1-smallF:getHeight()
      color(c.divider,.45); G.line(gx,gy+gh*.5,gx+gw,gy+gh*.5)
      color(c.accent); G.setLineWidth(math.max(1,sc*.8))
      -- Native Emerald renders the waveform as a circular 256px buffer and
      -- scrolls it by cry.playhead.  Compensate for that scroll here so each
      -- new cry starts at the same visual X instead of appearing in a random
      -- horizontal location after repeated A presses.
      local playhead=tonumber(s.cry and s.cry.playhead) or 0
      local step=4
      for ix=0,255,step do
        local ymin,ymax=nil,nil
        for ox=0,step-1 do
          local displayX=math.min(255,ix+ox)
          local xx=(displayX+playhead)%256
          for yy=0,55 do
            local v=tonumber(wave[yy*256+xx]) or 0
            local base=s.cry and s.cry.bgTile and tonumber(s.cry.bgTile[(yy%8)*8+(xx%8)]) or 0
            if v~=base then ymin=math.min(ymin or yy,yy); ymax=math.max(ymax or yy,yy) end
          end
        end
        if ymin then
          local px=gx+(ix/255)*gw; local y1=gy+(ymin/55)*gh; local y2=gy+(ymax/55)*gh
          G.line(px,y1,px,y2)
        end
      end
    else
      text("PRESS A TO PLAY",bodyF,wx,wy+wh*.47,ww,"center",c.muted)
    end
    footerNav(x,fy,w,footerH,pad,smallF,c,{"A PLAY CRY","lr","CHANGE PAGE","B BACK"})
  end

  local function drawSize(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    local nat=currentNat(s) or 0; local sp=speciesOf(nat)
    pageHeader(x,y,w,pad,titleF,smallF,c,"SIZE")
    local cy=y+header; local fy=y+h-footerH
    local stageX=x+pad; local stageY=cy+pad*.35; local stageW=w-pad*2; local stageH=fy-stageY-pad*.35
    card(stageX,stageY,stageW,stageH,c.raised,c.divider,5*sc)
    local monScale=256/math.max(1,tonumber(s.sizeMon and s.sizeMon.scale) or 256)
    local trScale=256/math.max(1,tonumber(s.sizeTrainer and s.sizeTrainer.scale) or 256)
    monScale=math.max(.35,math.min(1.65,monScale)); trScale=math.max(.35,math.min(1.65,trScale))
    local base=math.min(stageW*.27,stageH*.58)
    local monBox=base*monScale; local trBox=base*trScale
    drawDexPreview(sp,monPersonality(s,sp),stageX+stageW*.28-monBox*.5,stageY+stageH*.48-monBox*.5,monBox,monBox)
    if s.sizeTrainer and s.sizeTrainer.img then
      local img=s.sizeTrainer.img; local iw,ih=img:getDimensions(); local ds=math.min(trBox/math.max(1,iw),trBox/math.max(1,ih))
      color({1,1,1,1}); G.draw(img,stageX+stageW*.70-iw*ds*.5,stageY+stageH*.48-ih*ds*.5,0,ds,ds)
    end
    text(speciesName(sp),bodyF,stageX+stageW*.10,stageY+stageH*.80,stageW*.36,"center",c.text)
    local player=tostring(s.session and (s.session.name or s.session.playerName) or "TRAINER")
    text(player,bodyF,stageX+stageW*.54,stageY+stageH*.80,stageW*.36,"center",c.text)
    text("SIZE COMPARISON",smallF,stageX,stageY+pad*.6,stageW,"center",c.accent)
    footerNav(x,fy,w,footerH,pad,smallF,c,{"left","CHANGE PAGE","B BACK"})
  end

  local function drawSearch(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    pageHeader(x,y,w,pad,titleF,smallF,c,"SEARCH")
    local cy=y+header; local fy=y+h-footerH; local q=s.searchState or {}
    local tabs={"SEARCH","SHIFT","CANCEL"}; local ti=(tonumber(q.topBar) or 0)+1; local tabW=(w-pad*2)/3
    for i,v in ipairs(tabs) do
      local bx=x+pad+(i-1)*tabW; local bh=math.max(15*sc,bodyF:getHeight()+5*sc)
      if i==ti then card(bx,cy,tabW-2*sc,bh,c.selected,c.accent,3*sc) end
      text(v,bodyF,bx,cy+(bh-bodyF:getHeight())*.5,tabW-2*sc,"center",i==ti and c.text or c.muted)
    end
    local boxY=cy+math.max(18*sc,bodyF:getHeight()+8*sc); local boxH=fy-boxY-pad*.35
    card(x+pad,boxY,w-pad*2,boxH,c.raised,c.divider,5*sc)
    local entries={}
    for _,e in ipairs(s.searchText or {}) do
      local t=tostring(e.text or "")
      if t~="" then entries[#entries+1]={text=t,x=tonumber(e.x) or 0,y=tonumber(e.y) or 0} end
    end
    for _,e in ipairs(entries) do
      local px=x+pad*1.6+(e.x/240)*(w-pad*3.2)
      local py=boxY+pad*.55+(e.y/160)*(boxH-pad*1.1)
      local maxW=x+w-pad*1.6-px
      text(fit(e.text,smallF,maxW),smallF,px,py,maxW,"left",c.text)
    end
    if q.phase and q.phase~="topbar" then text(tostring(q.phase):upper(),smallF,x+pad*1.5,fy-smallF:getHeight()-4*sc,w-pad*3,"right",c.accent) end
    footer(x,fy,w,footerH,pad,smallF,c,"D-PAD SELECT    A OK    B BACK")
  end

  local function caughtTexts(s,nat)
    local expanded,active=completeDexMeta(nat,true)
    if active and expanded then
      return cleanDexText(expanded.number,true),cleanDexText(expanded.name,true),
        cleanDexText(expanded.category,true),cleanDexText(expanded.height,true),
        cleanDexText(expanded.weight,true),cleanDexText(expanded.description,false)
    end
    local arr=s.caught and s.caught.text or {}
    local function at(i,compact) return cleanDexText(arr[i] and arr[i].text or "",compact) end
    return at(2,true),at(3,true),at(4,true),at(7,true),at(8,true),at(#arr,false)
  end
  local function drawCaught(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    local ca=s.caught or {}; local nat=tonumber(ca.dexNum) or 0; local sp=speciesOf(nat)
    pageHeader(x,y,w,pad,titleF,smallF,c,"NEW POKéDEX DATA")
    local cy=y+header; local fy=y+h-footerH; local leftW=w*.42; local split=x+leftW
    color(c.divider,.58); G.rectangle("fill",split,cy,math.max(1,sc),fy-cy)
    drawDexPreview(sp,tonumber(ca.personality) or 0,x+pad,cy+pad,leftW-pad*2,(fy-cy)*.64)
    text(fit(speciesName(sp),bodyF,leftW-pad*2),bodyF,x+pad,cy+(fy-cy)*.70,leftW-pad*2,"center",c.text)
    text(string.format("#%03d",displayNum(s,nat)),smallF,x+pad,cy+(fy-cy)*.70+bodyF:getHeight()+3*sc,leftW-pad*2,"center",c.muted)
    local num,name,category,heightText,weightText,desc=caughtTexts(s,nat)
    local rx=split+pad; local rw=w-leftW-pad*2; local yy=cy+pad*.45
    text(name~="" and name or speciesName(sp),titleF,rx,yy,rw,"left",c.text); yy=yy+titleF:getHeight()+4*sc
    text(string.format("#%03d",displayNum(s,nat)),smallF,rx,yy,rw,"left",c.muted); yy=yy+smallF:getHeight()+5*sc
    text(category,bodyF,rx,yy,rw,"left",c.text); yy=yy+bodyF:getHeight()+6*sc
    text("HEIGHT",smallF,rx,yy,rw*.35,"left",c.muted); text(heightText,bodyF,rx+rw*.38,yy-1*sc,rw*.62,"left",c.text); yy=yy+bodyF:getHeight()+5*sc
    text("WEIGHT",smallF,rx,yy,rw*.35,"left",c.muted); text(weightText,bodyF,rx+rw*.38,yy-1*sc,rw*.62,"left",c.text); yy=yy+bodyF:getHeight()+6*sc
    color(c.divider,.45); G.rectangle("fill",rx,yy,rw,math.max(1,sc)); yy=yy+5*sc
    drawDexParagraph(desc,rx,yy,rw,math.max(1,fy-yy-2*sc),c.muted,sc)
    footer(x,fy,w,footerH,pad,smallF,c,"A / B CONTINUE")
  end

  local function drawRseDex(viewport,c,s)
    if not s then return false end
    setFloating(true)
    local x,y,w,h=modernWindow(viewport,c); local sc=math.min(w/240,h/160)
    local pad=math.max(8*sc,w*.018); local header=math.max(26*sc,h*.145); local footerH=math.max(20*sc,h*.125)
    local titleF,bodyF,smallF=font(10.2*sc),font(7.7*sc),font(5.8*sc)
    local page=tonumber(s.page)
    if page==PAGE.MAIN or page==PAGE.SEARCH_RESULTS then drawMain(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    elseif page==PAGE.INFO then drawInfo(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    elseif page==PAGE.AREA then drawArea(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    elseif page==PAGE.CRY then drawCry(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    elseif page==PAGE.SIZE then drawSize(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    elseif page==PAGE.SEARCH then drawSearch(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    elseif page==PAGE.CAUGHT then drawCaught(s,x,y,w,h,c,sc,pad,header,footerH,titleF,bodyF,smallF)
    else return false end
    return true
  end

  local function completeDexActive()
    local ask=mod._kantoInMotion1025DexActive
    if type(ask)~="function" then return false end
    local ok,v=pcall(ask)
    return ok and v==true
  end

  local function preferCompleteDexNational(s)
    if not (type(s)=="table" and completeDexActive() and s.nationalEnabled==true) then return s end
    -- 1025Dex intentionally enables Emerald's National Dex and extends its
    -- numerical order to 1025.  Default to that mode only while the mod is
    -- active; without 1025Dex KIM never changes Emerald's native mode.
    s.dexMode=1
    s.dexModeBackup=1
    if type(s.session)=="table" then
      s.session.pokedex=type(s.session.pokedex)=="table" and s.session.pokedex or {}
      s.session.pokedex.mode=1
    end
    return s
  end

  if not RseDex.__kimGen3ModernRseDexV68 then
    local upstreamDraw=RseDex.draw
    if type(upstreamDraw)=="function" then
      RseDex.draw=function(s,...)
        if enabled() and (not Style or not Style.hideOriginal or Style.hideOriginal()) and active() then return end
        return upstreamDraw(s,...)
      end
    end
    local upstreamShow=RseDex.show
    if type(upstreamShow)=="function" then
      RseDex.show=function(...)
        local out={upstreamShow(...)}
        if out[1] then preferCompleteDexNational(out[1]) end
        if enabled() then setFloating(true) end
        return unpack(out)
      end
    end
    local upstreamCaught=RseDex.showCaughtMon
    if type(upstreamCaught)=="function" then
      RseDex.showCaughtMon=function(...)
        local out={upstreamCaught(...)}; if enabled() then setFloating(true) end; return unpack(out)
      end
    end
    RseDex.__kimGen3ModernRseDexV68=true
  end

  mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
    nextFn(game,viewport)
    if not enabled() then setFloating(false); return end
    local s=active()
    if not s then return end
    local c=theme()
    -- Game3:_drawHud already wraps the complete render.hud chain in one
    -- engine-owned push("all").  Draw the RSE Modern Dex directly inside
    -- that scope so an owned-entry presenter failure cannot leak another
    -- graphics-stack level every frame.  pcall keeps the hook alive long
    -- enough to restore a neutral final-window state without adding a push.
    G.origin(); G.setShader(); G.setBlendMode("alpha")
    local ok,err=pcall(drawRseDex,viewport,c,s)
    G.setShader(); G.setBlendMode("alpha"); G.setScissor(); G.setColor(1,1,1,1)
    if not ok then
      mod._kantoInMotionGen3RseDexLastDrawError=tostring(err)
    else
      mod._kantoInMotionGen3RseDexLastDrawError=nil
    end
  end,11220)

  mod.exports=mod.exports or {}; mod.exports.gen3ModernRsePokedexUi=true
  return true
end
