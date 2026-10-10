-- Kanto in Motion v1.7.0 - Gen 2 Modern Summary UI v2
--
-- Presentation-only adapter for Gold/Silver/Crystal SummaryMenu. The native
-- SummaryMenu remains the authoritative state/input owner (page changes,
-- party cycling, move reordering, cries, callbacks). KIM hides only the
-- original 160x144 rendering and redraws the live state at final resolution.
return function(mod)
  local G = love.graphics
  local Style = mod._kantoInMotionGen2Ui
  local okSummary, SummaryMenu = pcall(require, "src.ui.gen2.SummaryMenu")
  local okChrome, Chrome = pcall(require, "src.ui.gen2.Chrome")
  local okGbc, GbcPalette = pcall(require, "src.render.GbcPalette")
  local okPalettes, Gen2Palettes = pcall(require, "src.world.gen2.Palettes")
  local okMon, Mon = pcall(require, "src.battle.gen2.Mon")
  if not (okSummary and type(SummaryMenu) == "table" and okChrome and Chrome) then
    return false
  end
  if SummaryMenu.__kimModernSummaryV2 then return true end

  local fontCache, imageCache = {}, {}
  local FALLBACK = {
    surface={0.075,0.105,0.17,0.94}, raised={0.12,0.17,0.27,0.92},
    selected={0.18,0.43,0.72,0.96}, accent={0.48,0.86,1,1},
    frame={0.48,0.86,1,1}, frameShadow={0.01,0.02,0.04,0.42},
    text={0.96,0.98,1,1}, muted={0.74,0.82,0.92,1},
    divider={0.38,0.50,0.68,0.94},
  }

  local function opt(key, fallback)
    if not (mod.options and type(mod.options.get)=="function") then return fallback end
    local ok,value=pcall(mod.options.get,mod.options,key)
    if not ok or value==nil then return fallback end
    return value
  end

  local function enabled()
    if Style and Style.presenterEnabled then return Style.presenterEnabled("pokemon") end
    return opt("gen2IntegratedModernUi",true)~=false
  end

  local function hideOriginal()
    if Style and Style.hideOriginal then return Style.hideOriginal() end
    return true
  end

  local function theme()
    if Style and Style.theme then return Style.theme() end
    local themes=mod._kantoInMotionGen2Themes
    return type(themes)=="table" and (themes[tostring(opt("gen2UiTheme","default"))] or themes.default) or FALLBACK
  end

  local function color(c,a,foreground)
    if Style and Style.color then return Style.color(c,a,foreground) end
    c=c or {1,1,1,1}
    G.setColor(c[1] or 1,c[2] or 1,c[3] or 1,a==nil and (c[4] or 1) or a)
  end

  local function fontFor(px)
    if Style and Style.font then return Style.font(px) end
    px=math.max(8,math.floor((tonumber(px) or 12)+.5))
    if fontCache[px] then return fontCache[px] end
    local ok,f=pcall(G.newFont,px)
    if ok and f then fontCache[px]=f return f end
    return G.getFont()
  end

  local function text(value,font,x,y,w,align,c)
    if Style and Style.text then return Style.text(value,font,x,y,w,align,c) end
    if font then G.setFont(font) end
    color(c,nil,true)
    value=tostring(value or "")
    if w then
      local ok=pcall(G.printf,value,x,y,w,align or "left")
      if not ok then G.printf(value:gsub("[\128-\255]","?"),x,y,w,align or "left") end
    else
      local ok=pcall(G.print,value,x,y)
      if not ok then G.print(value:gsub("[\128-\255]","?"),x,y) end
    end
  end

  local function panel(x,y,w,h,c,alpha)
    if Style and Style.panel then return Style.panel(x,y,w,h,c,alpha) end
    color(c.surface,alpha or .94); G.rectangle("fill",x,y,w,h,8,8)
    color(c.frame); G.rectangle("line",x,y,w,h,8,8)
  end

  -- Configurable UI fonts do not consistently contain arrow or gender glyphs.
  -- Draw both as vector marks so they remain visible with every KIM font.
  local function chevron(cx,cy,size,dir,c)
    size=math.max(4,tonumber(size) or 8)
    color(c,nil,true); G.setLineWidth(math.max(1,size*.14))
    if dir=="left" then
      G.line(cx+size*.28,cy-size*.38,cx-size*.24,cy,cx+size*.28,cy+size*.38)
    elseif dir=="right" then
      G.line(cx-size*.28,cy-size*.38,cx+size*.24,cy,cx-size*.28,cy+size*.38)
    elseif dir=="up" then
      G.line(cx-size*.38,cy+size*.24,cx,cy-size*.24,cx+size*.38,cy+size*.24)
    else
      G.line(cx-size*.38,cy-size*.24,cx,cy+size*.24,cx+size*.38,cy-size*.24)
    end
  end

  local function genderSymbol(cx,cy,size,g,c)
    size=math.max(7,tonumber(size) or 10)
    color(c,nil,true); G.setLineWidth(math.max(1,size*.12))
    local r=size*.22
    if g=="male" or g=="M" then
      local ox,oy=cx-size*.10,cy+size*.08
      G.circle("line",ox,oy,r)
      local ex,ey=cx+size*.34,cy-size*.34
      G.line(ox+r*.72,oy-r*.72,ex,ey)
      G.line(ex-size*.18,ey,ex,ey,ex,ey+size*.18)
    elseif g=="female" or g=="F" then
      local ox,oy=cx,cy-size*.12
      G.circle("line",ox,oy,r)
      local stemTop=oy+r
      local stemBottom=cy+size*.34
      G.line(ox,stemTop,ox,stemBottom)
      G.line(ox-size*.18,cy+size*.16,ox+size*.18,cy+size*.16)
    end
  end

  local function playfield()
    local ww,wh=G.getDimensions()
    if type(Chrome.playfieldRect)=="function" then
      local ok,x,y,w,h=pcall(Chrome.playfieldRect,ww,wh)
      if ok and w and h and w>0 and h>0 then return x,y,w,h end
    end
    return 0,0,ww,wh
  end

  local function loadImage(path)
    if not path then return nil end
    if imageCache[path]~=nil then return imageCache[path] or nil end
    local ok,img=false,nil
    if mod.assets and type(mod.assets.image)=="function" then
      ok,img=pcall(mod.assets.image,mod.assets,path)
    end
    if (not ok or not img) and G and type(G.newImage)=="function" then
      ok,img=pcall(G.newImage,path)
    end
    if not ok or not img then imageCache[path]=false return nil end
    if img.setFilter then pcall(img.setFilter,img,"nearest","nearest") end
    imageCache[path]=img
    return img
  end

  local function nativePreview(self,mon)
    if not (self and mon) then return nil end
    if type(self.picFor)=="function" then
      local ok,img,trueColor=pcall(self.picFor,self,mon)
      if ok and img then
        local colors
        if okPalettes and type(Gen2Palettes)=="table" and type(Gen2Palettes.monColors)=="function" then
          local shiny=mon.shiny==true or mon.isShiny==true
          local okp,pal=pcall(Gen2Palettes.monColors,self.palettes,mon.species,shiny)
          if okp then colors=pal end
        end
        return img,colors,trueColor
      end
    end
    return nil
  end

  local function preview(self,mon)
    if not mon then return nil end
    -- SUMMARY SPRITES / MENU SPRITES OFF means use the native G/S/C picture.
    if opt("menuSprites",true)==false or tostring(opt("gen2MenuSpriteSource","kim"))=="vanilla" then
      return nativePreview(self,mon)
    end
    if mod.exports and type(mod.exports.getSprite)=="function" then
      local ok,img=pcall(mod.exports.getSprite,mon.species,{generation="hd",mon=mon,side="front"})
      if ok and img then return img,nil,true end
    end
    return nativePreview(self,mon)
  end

  local function drawPreview(self,mon,x,y,w,h)
    local img,pal,trueColor=preview(self,mon)
    if not img then return end
    local iw,ih=img:getDimensions()
    local s=math.min(w/math.max(1,iw),h/math.max(1,ih))
    local dx=x+(w-iw*s)/2
    local dy=y+(h-ih*s)/2
    local function body()
      color({1,1,1,1}); G.draw(img,dx,dy,0,s,s)
    end
    if pal and okGbc and type(GbcPalette)=="table" and type(GbcPalette.with)=="function"
        and type(GbcPalette.available)=="function" and GbcPalette.available()
        and not (trueColor and GbcPalette.mode=="gbc") then
      GbcPalette.with(pal,body)
    else
      body()
    end
  end

  local function hpColor(hp,maxHp)
    local f=(tonumber(hp) or 0)/math.max(1,tonumber(maxHp) or 1)
    if f<=.2 then return {.93,.20,.18,1} end
    if f<=.5 then return {.96,.70,.16,1} end
    return {.16,.78,.38,1}
  end

  local function bar(x,y,w,h,f,fill,c)
    f=math.max(0,math.min(1,tonumber(f) or 0))
    color(c.raised); G.rectangle("fill",x,y,w,h,h*.5,h*.5)
    color(fill); G.rectangle("fill",x+1,y+1,math.max(0,(w-2)*f),math.max(1,h-2),h*.4,h*.4)
  end

  local function monDef(self,mon)
    return self and self.pokemon and mon and self.pokemon[mon.species] or nil
  end

  local function displayName(self,mon)
    local def=monDef(self,mon)
    return (mon and (mon.nickname or mon.name)) or (def and def.name) or (mon and mon.species) or "POKéMON"
  end

  local function typeLine(self)
    if type(self.typeNames)=="function" then
      local ok,a,b=pcall(self.typeNames,self)
      if ok then
        if a and b then return tostring(a).." / "..tostring(b) end
        if a then return tostring(a) end
      end
    end
    local def=monDef(self,self.mon)
    return def and table.concat(def.types or {}," / ") or "—"
  end

  local STATUS_LABELS={psn="PSN",poison="PSN",brn="BRN",burn="BRN",slp="SLP",sleep="SLP",frz="FRZ",freeze="FRZ",par="PAR",paralysis="PAR"}
  local function statusLine(mon)
    if not mon then return "—" end
    if (tonumber(mon.hp) or 0)<=0 then return "FNT" end
    local s=mon.status
    if not s or s==0 or s=="" then return "OK" end
    return STATUS_LABELS[tostring(s):lower()] or tostring(s):upper()
  end

  local function expFraction(self,mon)
    if not (okMon and Mon and mon and type(Mon.experienceForLevel)=="function" and type(self.growth)=="function") then return 0 end
    local level=math.max(1,tonumber(mon.level) or 1)
    if level>=100 then return 1 end
    local okg,growth=pcall(self.growth,self)
    if not okg or not growth then return 0 end
    local ok1,lo=pcall(Mon.experienceForLevel,growth,level)
    local ok2,hi=pcall(Mon.experienceForLevel,growth,level+1)
    if not ok1 or not ok2 then return 0 end
    local span=math.max(1,(tonumber(hi) or 0)-(tonumber(lo) or 0))
    return math.max(0,math.min(1,((tonumber(mon.experience) or 0)-(tonumber(lo) or 0))/span))
  end

  local function moveRows(self)
    local out={}
    local list=type(self.moveList)=="function" and self:moveList() or (self.mon and self.mon.moves) or {}
    for i=1,4 do
      local m=list[i]
      local def=m and type(self.moveDef)=="function" and self:moveDef(m.id) or nil
      out[i]={
        move=m,
        name=m and ((type(self.moveName)=="function" and self:moveName(m)) or (def and def.name) or m.id) or "—",
        pp=m and (tonumber(m.pp) or 0) or 0,
        maxpp=m and (tonumber(m.maxPp) or (def and tonumber(def.pp)) or tonumber(m.pp) or 0) or 0,
        def=def,
      }
    end
    return out
  end

  local function sectionTitle(label,font,x,y,w,c)
    text(label,font,x,y,w,"left",c.accent)
    color(c.divider,.62,true); G.rectangle("fill",x,y+font:getHeight()+4,w,1)
  end

  local function drawHeader(self,x,y,w,scale,c,titleFont,bodyFont,smallFont)
    local mon=self.mon or {}
    local def=monDef(self,mon)
    local portrait=math.min(150*scale,w*.24)
    drawPreview(self,mon,x,y,portrait,portrait)
    local tx=x+portrait+18*scale
    local name=displayName(self,mon)
    text(name,titleFont,tx,y,w-portrait-18*scale,"left",c.text)
    local dex=def and tonumber(def.dex)
    local dexText=dex and ("No. %03d"):format(dex) or "No. ---"
    text(dexText,smallFont,tx,y+titleFont:getHeight()+3*scale,w*.28,"left",c.muted)
    local level=("Lv %d"):format(tonumber(mon.level) or 1)
    local levelX=tx+w*.30
    local levelY=y+titleFont:getHeight()
    text(level,bodyFont,levelX,levelY,w*.22,"left",c.text)
    local gender=tostring(mon.gender or ""):lower()
    if gender=="m" then gender="male" elseif gender=="f" then gender="female" end
    if gender=="male" or gender=="female" then
      local symbolSize=bodyFont:getHeight()*.70
      local gx=levelX+bodyFont:getWidth(level)+6*scale+symbolSize*.36
      local gy=levelY+bodyFont:getHeight()*.50
      local gc=(gender=="male") and {0.28,0.66,1,1} or {1,0.40,0.66,1}
      genderSymbol(gx,gy,symbolSize,gender,gc)
    end
    text((def and def.name) or tostring(mon.species or ""),bodyFont,tx,y+titleFont:getHeight()+bodyFont:getHeight()+10*scale,w-portrait-18*scale,"left",c.text)
    text(typeLine(self),smallFont,tx,y+titleFont:getHeight()+bodyFont:getHeight()*2+15*scale,w-portrait-18*scale,"left",c.accent)
    if mon.shiny then text("✦ SHINY",smallFont,tx,y+portrait-smallFont:getHeight(),w-portrait-18*scale,"left",c.accent) end
    return portrait
  end

  local function drawTabs(self,x,y,w,h,scale,c,smallFont)
    local labels={"STATUS","MOVES","STATS"}
    local gap=8*scale
    local tw=(w-gap*2)/3
    for i,label in ipairs(labels) do
      local xx=x+(i-1)*(tw+gap)
      if self.page==i and not self.moveDetail then
        color(c.selected,.96); G.rectangle("fill",xx,y,tw,h,5*scale,5*scale)
      else
        color(c.raised,.76); G.rectangle("fill",xx,y,tw,h,5*scale,5*scale)
      end
      text(label,smallFont,xx,y+(h-smallFont:getHeight())*.5,tw,"center",self.page==i and c.text or c.muted)
    end
  end

  local function drawStatusPage(self,x,y,w,h,scale,c,bodyFont,smallFont)
    local mon=self.mon or {}
    local maxHp=tonumber(mon.maxHp) or (mon.stats and tonumber(mon.stats.hp)) or 1
    local leftW=w*.48
    sectionTitle("HP / STATUS",bodyFont,x,y,leftW,c)
    local yy=y+bodyFont:getHeight()+18*scale
    text(("%d / %d"):format(tonumber(mon.hp) or 0,maxHp),bodyFont,x,yy,leftW,"left",c.text)
    bar(x,yy+bodyFont:getHeight()+8*scale,leftW,10*scale,(tonumber(mon.hp) or 0)/math.max(1,maxHp),hpColor(mon.hp,maxHp),c)
    text("STATUS",smallFont,x,yy+bodyFont:getHeight()+32*scale,leftW*.45,"left",c.muted)
    text(statusLine(mon),bodyFont,x+leftW*.48,yy+bodyFont:getHeight()+27*scale,leftW*.52,"right",c.text)
    text("TYPE",smallFont,x,yy+bodyFont:getHeight()+62*scale,leftW*.45,"left",c.muted)
    text(typeLine(self),bodyFont,x,yy+bodyFont:getHeight()+82*scale,leftW,"left",c.accent)

    local rx=x+leftW+28*scale; local rw=w-leftW-28*scale
    sectionTitle("EXPERIENCE",bodyFont,rx,y,rw,c)
    local exp=tonumber(mon.experience) or 0
    local toNext=type(self.expToNext)=="function" and self:expToNext() or 0
    text("EXP POINTS",smallFont,rx,yy,rw*.55,"left",c.muted)
    text(tostring(exp),bodyFont,rx,yy+22*scale,rw,"right",c.text)
    text("LEVEL UP",smallFont,rx,yy+62*scale,rw*.55,"left",c.muted)
    text(("%d TO Lv %d"):format(tonumber(toNext) or 0,math.min(100,(tonumber(mon.level) or 1)+1)),bodyFont,rx,yy+84*scale,rw,"right",c.text)
    bar(rx,yy+126*scale,rw,9*scale,expFraction(self,mon),c.accent,c)
  end

  local function drawMovesPage(self,x,y,w,h,scale,c,bodyFont,smallFont)
    local item=type(self.itemName)=="function" and self:itemName() or nil
    text("HELD ITEM",smallFont,x,y,w*.25,"left",c.muted)
    text(item or "NONE",bodyFont,x+w*.25,y-3*scale,w*.75,"left",item and c.text or c.muted)
    local rows=moveRows(self)
    local start=y+42*scale
    local rowH=math.min(58*scale,(h-46*scale)/4)
    for i,row in ipairs(rows) do
      local ry=start+(i-1)*rowH
      if self.moveDetail and i==self.moveIndex then
        color(c.selected,.92); G.rectangle("fill",x,ry,w,rowH-5*scale,5*scale,5*scale)
      end
      text(row.name,bodyFont,x+10*scale,ry+7*scale,w*.62,"left",row.move and c.text or c.muted)
      if row.move then
        text(("PP %d/%d"):format(row.pp,row.maxpp),smallFont,x+w*.66,ry+11*scale,w*.31,"right",c.muted)
      end
    end
  end

  local function drawStatsPage(self,x,y,w,h,scale,c,bodyFont,smallFont)
    local mon=self.mon or {}; local stats=mon.stats or {}
    local leftW=w*.42
    sectionTitle("TRAINER",bodyFont,x,y,leftW,c)
    local ot=type(self.otName)=="function" and self:otName() or "—"
    local id=type(self.otId)=="function" and self:otId() or 0
    text("OT",smallFont,x,y+bodyFont:getHeight()+20*scale,leftW*.35,"left",c.muted)
    text(tostring(ot),bodyFont,x,y+bodyFont:getHeight()+42*scale,leftW,"left",c.text)
    text("ID No.",smallFont,x,y+bodyFont:getHeight()+83*scale,leftW*.35,"left",c.muted)
    text(tostring(id),bodyFont,x,y+bodyFont:getHeight()+105*scale,leftW,"left",c.text)

    local rx=x+leftW+30*scale; local rw=w-leftW-30*scale
    sectionTitle("STATS",bodyFont,rx,y,rw,c)
    local vals={
      {"ATTACK",stats.attack}, {"DEFENSE",stats.defense},
      {"SP. ATK",stats.specialAttack or stats.spAttack or stats.special},
      {"SP. DEF",stats.specialDefense or stats.spDefense or stats.special},
      {"SPEED",stats.speed},
    }
    local yy=y+bodyFont:getHeight()+19*scale
    local rh=math.min(42*scale,(h-bodyFont:getHeight()-24*scale)/5)
    for i,row in ipairs(vals) do
      text(row[1],smallFont,rx,yy+(i-1)*rh,rw*.62,"left",c.muted)
      text(tostring(row[2] or "—"),bodyFont,rx+rw*.63,yy-4*scale+(i-1)*rh,rw*.37,"right",c.text)
    end
  end

  local function drawMoveDetail(self,x,y,w,h,scale,c,titleFont,bodyFont,smallFont)
    local rows=moveRows(self)
    local listW=w*.47
    text("MOVE DETAILS",titleFont,x,y,listW,"left",c.text)
    local start=y+titleFont:getHeight()+16*scale
    local rowH=math.min(60*scale,(h-titleFont:getHeight()-20*scale)/4)
    for i,row in ipairs(rows) do
      local ry=start+(i-1)*rowH
      if i==self.moveIndex then
        color(c.selected,.96); G.rectangle("fill",x,ry,listW,rowH-6*scale,5*scale,5*scale)
      end
      if self.swapFrom==i then
        color(c.accent,nil,true); G.setLineWidth(math.max(2,2*scale)); G.rectangle("line",x+2,ry+2,listW-4,rowH-10*scale,5*scale,5*scale)
      end
      text(row.name,bodyFont,x+10*scale,ry+8*scale,listW*.64,"left",row.move and c.text or c.muted)
      if row.move then text(("PP %d/%d"):format(row.pp,row.maxpp),smallFont,x+listW*.62,ry+12*scale,listW*.34,"right",c.muted) end
    end
    local sel=rows[math.max(1,math.min(4,tonumber(self.moveIndex) or 1))]
    local rx=x+listW+30*scale; local rw=w-listW-30*scale
    sectionTitle(sel and sel.name or "—",bodyFont,rx,y,rw,c)
    if sel and sel.move then
      local d=sel.def or {}
      local typ=tostring(d.type or sel.move.type or "—")
      text("TYPE",smallFont,rx,y+bodyFont:getHeight()+23*scale,rw*.40,"left",c.muted)
      text(typ,bodyFont,rx,y+bodyFont:getHeight()+45*scale,rw,"left",c.accent)
      text("POWER",smallFont,rx,y+bodyFont:getHeight()+87*scale,rw*.45,"left",c.muted)
      text(tostring(d.power or "—"),bodyFont,rx+rw*.50,y+bodyFont:getHeight()+82*scale,rw*.50,"right",c.text)
      text("ACCURACY",smallFont,rx,y+bodyFont:getHeight()+125*scale,rw*.55,"left",c.muted)
      text(tostring(d.accuracy or "—"),bodyFont,rx+rw*.58,y+bodyFont:getHeight()+120*scale,rw*.42,"right",c.text)
      local desc=d.description or d.desc or d.text
      if desc then text(desc,smallFont,rx,y+bodyFont:getHeight()+170*scale,rw,"left",c.text) end
    end
    text(self.swapFrom and "A: PLACE MOVE   B: CANCEL" or "A: PICK UP MOVE   B/SELECT: BACK",smallFont,rx,y+h-smallFont:getHeight(),rw,"right",c.muted)
  end

  local function drawSummary(self)
    local c=theme()
    local sx,sy,sw,sh=playfield()
    local uiScale=Style and Style.uiScale and Style.uiScale(sw,sh) or 1
    local layout=Style and Style.layoutStyle and Style.layoutStyle() or "floating"
    local pw=math.min(sw*.90,1050*uiScale)
    local ph=math.min(sh*.88,700*uiScale)
    if layout=="full" then pw=sw*.94; ph=sh*.92 end
    local scale=math.max(.72,math.min(1.28,math.min(pw/980,ph/630)))
    local x=sx+(sw-pw)/2; local y=sy+(sh-ph)/2
    panel(x,y,pw,ph,c,.94)

    local titleFont=fontFor(32*scale); local bodyFont=fontFor(24*scale); local smallFont=fontFor(18*scale)
    local pad=22*scale
    local headerH=174*scale
    local tabsH=38*scale
    local footerH=38*scale

    if self.moveDetail then
      drawMoveDetail(self,x+pad,y+pad,pw-pad*2,ph-pad*2,scale,c,titleFont,bodyFont,smallFont)
      return
    end

    drawHeader(self,x+pad,y+pad,pw-pad*2,scale,c,titleFont,bodyFont,smallFont)
    local tabsY=y+headerH
    drawTabs(self,x+pad,tabsY,pw-pad*2,tabsH,scale,c,smallFont)
    local contentY=tabsY+tabsH+18*scale
    local contentH=y+ph-footerH-contentY
    color(c.divider,.55,true); G.rectangle("fill",x+pad,contentY-9*scale,pw-pad*2,1)

    if self.page==SummaryMenu.GREEN_PAGE then
      drawMovesPage(self,x+pad,contentY,pw-pad*2,contentH,scale,c,bodyFont,smallFont)
    elseif self.page==SummaryMenu.BLUE_PAGE then
      drawStatsPage(self,x+pad,contentY,pw-pad*2,contentH,scale,c,bodyFont,smallFont)
    else
      drawStatusPage(self,x+pad,contentY,pw-pad*2,contentH,scale,c,bodyFont,smallFont)
    end

    local footerY=y+ph-footerH
    local fcy=footerY+footerH*.52
    local icon=math.max(5*scale,smallFont:getHeight()*.38)
    local gap=7*scale
    local itemGap=18*scale
    local pageW=icon*1.56+gap+smallFont:getWidth("PAGE")
    local monW=icon*.78+gap+smallFont:getWidth("POKéMON")
    local extra=(self.page==SummaryMenu.GREEN_PAGE) and smallFont:getWidth("SELECT MOVE DETAILS") or 0
    local backW=smallFont:getWidth("B BACK")
    local total=pageW+itemGap+monW+itemGap+backW
    if extra>0 then total=total+itemGap+extra end
    local tx=x+(pw-total)*.5
    local ty=fcy-smallFont:getHeight()*.5

    chevron(tx+icon*.34,fcy,icon*.82,"left",c.muted)
    tx=tx+icon*.78
    chevron(tx+icon*.34,fcy,icon*.82,"right",c.muted)
    tx=tx+icon*.78+gap
    text("PAGE",smallFont,tx,ty,nil,nil,c.muted)
    tx=tx+smallFont:getWidth("PAGE")+itemGap

    chevron(tx+icon*.34,fcy-icon*.36,icon*.62,"up",c.muted)
    chevron(tx+icon*.34,fcy+icon*.36,icon*.62,"down",c.muted)
    tx=tx+icon*.78+gap
    text("POKéMON",smallFont,tx,ty,nil,nil,c.muted)
    tx=tx+smallFont:getWidth("POKéMON")+itemGap

    if extra>0 then
      text("SELECT MOVE DETAILS",smallFont,tx,ty,nil,nil,c.muted)
      tx=tx+extra+itemGap
    end
    text("B BACK",smallFont,tx,ty,nil,nil,c.muted)
  end

  local upstreamNew=SummaryMenu.new
  SummaryMenu.new=function(game,opts)
    local self=upstreamNew(game,opts)
    if enabled() and hideOriginal() then self.isOpaque=false end
    return self
  end

  local upstreamUpdate=SummaryMenu.update
  SummaryMenu.update=function(self,...)
    self.isOpaque=not (enabled() and hideOriginal())
    return upstreamUpdate(self,...)
  end

  local upstreamWide=SummaryMenu.drawsWidescreen
  SummaryMenu.drawsWidescreen=function(self)
    if enabled() then return false end
    return upstreamWide and upstreamWide(self) or true
  end

  local function isSummary(state)
    return type(state)=="table" and getmetatable(state)==SummaryMenu
  end

  if mod.hooks and type(mod.hooks.wrap)=="function" then
    mod.hooks:wrap("screen.render_visible",function(nextFn,state)
      if enabled() and hideOriginal() and isSummary(state) then return false end
      return nextFn(state)
    end,100000)

    mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
      local result={pcall(nextFn,game,viewport)}; local ok=table.remove(result,1)
      if not ok then error(result[1],0) end
      local top=game and game.stack and type(game.stack.top)=="function" and game.stack:top()
      if enabled() and isSummary(top) then
        G.push("all"); G.origin(); pcall(drawSummary,top); G.pop()
      end
      return unpack(result)
    end,100000)
  end

  SummaryMenu.__kimModernSummaryV2=true
  return true
end
