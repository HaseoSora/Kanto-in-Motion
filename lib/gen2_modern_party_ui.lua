-- Kanto in Motion v1.7.3 - Gen 2 Modern Party UI v34 -- responsive mobile parity
--
-- The native PartyMenu remains the complete input/state owner. KIM makes the
-- state transparent, hides only its native render, then draws a final-window
-- Modern UI card over the live overworld through render.hud.
return function(mod)
  local G = love.graphics
  local Style = mod._kantoInMotionGen2Ui
  local okParty, PartyMenu = pcall(require, "src.ui.gen2.PartyMenu")
  local okChrome, Chrome = pcall(require, "src.ui.gen2.Chrome")
  local okGbc, GbcPalette = pcall(require, "src.render.GbcPalette")
  local okPalettes, Gen2Palettes = pcall(require, "src.world.gen2.Palettes")
  local okStats, Stats = pcall(require, "src.pokemon.Stats")
  local okGen2Mon, Gen2Mon = pcall(require, "src.battle.gen2.Mon")
  if not (okParty and type(PartyMenu) == "table" and okChrome and Chrome) then
    return false
  end
  if PartyMenu.__kimModernOverlayV3 then return true end

  local FONT_PATH = "assets/fonts/plainpixel/PlainPixel-Regular.ttf"
  local fontCache, imageCache = {}, {}

  local FALLBACK = {
    surface={0.075,0.105,0.17,0.94}, raised={0.12,0.17,0.27,0.92},
    selected={0.18,0.43,0.72,0.96}, accent={0.48,0.86,1,1},
    frame={0.48,0.86,1,1}, frameShadow={0.01,0.02,0.04,0.42},
    text={0.96,0.98,1,1}, muted={0.74,0.82,0.92,1},
    divider={0.38,0.50,0.68,0.94},
  }

  local function opt(key, fallback)
    if not (mod.options and type(mod.options.get) == "function") then return fallback end
    local ok, value = pcall(mod.options.get, mod.options, key)
    if not ok or value == nil then return fallback end
    return value
  end

  local function enabled()
    if Style and Style.presenterEnabled then return Style.presenterEnabled("pokemon") end
    return opt("gen2IntegratedModernUi", true) ~= false
  end

  local function hideOriginal()
    if Style and Style.hideOriginal then return Style.hideOriginal() end
    return true
  end

  local function theme()
    if Style and Style.theme then return Style.theme() end
    local themes = mod._kantoInMotionGen2Themes
    return type(themes) == "table"
      and (themes[tostring(opt("gen2UiTheme", "default"))] or themes.default)
      or FALLBACK
  end

  local function color(c, a, foreground)
    if Style and Style.color then return Style.color(c,a,foreground) end
    c = c or {1,1,1,1}
    G.setColor(c[1] or 1, c[2] or 1, c[3] or 1,
      a == nil and (c[4] or 1) or a)
  end

  local function fontFor(px)
    if Style and Style.font then return Style.font(px) end
    px = math.max(8, math.floor(px + 0.5))
    if fontCache[px] then return fontCache[px] end
    local ok, f = pcall(G.newFont, FONT_PATH, px, "mono", 1)
    if not ok or not f then ok, f = pcall(G.newFont, px) end
    if ok and f then
      if f.setFilter then pcall(f.setFilter, f, "nearest", "nearest") end
      fontCache[px] = f
      return f
    end
    return G.getFont()
  end

  local function drawText(text, font, x, y, w, align, c)
    if Style and Style.text then return Style.text(text,font,x,y,w,align,c) end
    if font then G.setFont(font) end
    color(c,nil,true)
    text = tostring(text or "")
    if w then
      local ok = pcall(G.printf, text, x, y, w, align or "left")
      if ok then return end
      G.printf(text:gsub("[\128-\255]", "?"), x, y, w, align or "left")
    else
      local ok = pcall(G.print, text, x, y)
      if not ok then G.print(text:gsub("[\128-\255]", "?"), x, y) end
    end
  end

  local function truncate(text, font, width)
    text = tostring(text or "")
    if not font.getWidth or font:getWidth(text) <= width then return text end
    local tail, target = "...", width - font:getWidth("...")
    while #text > 0 and font:getWidth(text) > target do text = text:sub(1,-2) end
    return text .. tail
  end


  local function fittedFont(basePx,value,maxW,maxH)
    local px=math.max(8,tonumber(basePx) or 8)
    value=tostring(value or "")
    local f=fontFor(px)
    while px>8 and ((maxW and f:getWidth(value)>maxW)
        or (maxH and f:getHeight()>maxH)) do
      local wr=maxW and (maxW/math.max(1,f:getWidth(value))) or 1
      local hr=maxH and (maxH/math.max(1,f:getHeight())) or 1
      local ratio=math.max(.62,math.min(.96,wr,hr))
      local nextPx=math.max(8,math.min(px-1,px*ratio))
      if nextPx>=px then nextPx=px-1 end
      px=nextPx; f=fontFor(px)
    end
    return f
  end

  local function mobileHost()
    if type(mod._kantoInMotionNativeMobileHost)=="function" then
      local ok,v=pcall(mod._kantoInMotionNativeMobileHost)
      if ok then return v==true end
    end
    if love and love.system and type(love.system.getOS)=="function" then
      local ok,name=pcall(love.system.getOS)
      return ok and (name=="Android" or name=="iOS")
    end
    return false
  end
  local function loadImage(path)
    if not path then return nil end
    if imageCache[path] ~= nil then return imageCache[path] or nil end
    local ok, image = false, nil
    if mod.assets and type(mod.assets.image)=="function" then
      ok,image=pcall(mod.assets.image,mod.assets,path)
    end
    if (not ok or not image) and G and type(G.newImage)=="function" then
      ok,image=pcall(G.newImage,path)
    end
    if not ok or not image then imageCache[path] = false return nil end
    if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
    imageCache[path] = image
    return image
  end

  local function playfield()
    local ww, wh = G.getDimensions()
    if type(Chrome.playfieldRect) == "function" then
      local ok, x, y, w, h = pcall(Chrome.playfieldRect, ww, wh)
      if ok and w and h and w > 0 and h > 0 then return x,y,w,h end
    end
    return 0,0,ww,wh
  end

  local function panel(x,y,w,h,colors,alpha)
    if Style and Style.panel then return Style.panel(x,y,w,h,colors,alpha) end
    local radius = math.max(8, math.min(w,h) * 0.018)
    color(colors.frameShadow or {0,0,0,0.4}, 0.18)
    G.rectangle("fill", x+2, y+3, w,h,radius,radius)
    color(colors.surface, math.min(1,(colors.surface[4] or 1)*(alpha or 0.94)))
    G.rectangle("fill",x,y,w,h,radius,radius)
    color(colors.frame or colors.accent)
    G.setLineWidth(math.max(2, math.min(w,h)*0.005))
    G.rectangle("line",x,y,w,h,radius,radius)
  end

  -- Configurable KIM fonts do not all contain the gender glyphs. Draw the
  -- symbol as vector geometry so the party detail header always matches the
  -- Modern Summary UI and remains visible with every font.
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

  local function resolvedGender(self,mon)
    if type(mon)~="table" then return nil end
    local g=mon.gender
    if g=="M" or g=="male" or g==0 then return "male" end
    if g=="F" or g=="female" or g==1 then return "female" end
    if okGen2Mon and Gen2Mon and type(Gen2Mon.gender)=="function" and type(mon.dvs)=="table" then
      local def=self and self.game and self.game.data and self.game.data.pokemon
        and self.game.data.pokemon[mon.species]
      if def then
        local ok,v=pcall(Gen2Mon.gender,def,mon.dvs,{species=mon.species,level=mon.level})
        if ok and (v=="male" or v=="female") then return v end
      end
    end
    return nil
  end

  local function hpColor(hp,maxHp)
    local f=(tonumber(hp) or 0)/math.max(1,tonumber(maxHp) or 1)
    if f<=0.2 then return {0.93,0.20,0.18,1} end
    if f<=0.5 then return {0.96,0.70,0.16,1} end
    return {0.16,0.78,0.38,1}
  end

  local function hpBar(x,y,w,h,hp,maxHp,colors)
    local f=math.max(0,math.min(1,(tonumber(hp) or 0)/math.max(1,tonumber(maxHp) or 1)))
    color(colors.raised); G.rectangle("fill",x,y,w,h,h*0.5,h*0.5)
    color(hpColor(hp,maxHp)); G.rectangle("fill",x+1,y+1,math.max(0,(w-2)*f),math.max(1,h-2),h*0.35,h*0.35)
  end

  local function hdIcon(self, mon)
    if type(mod._kantoInMotionHdMenuIconForModernUi) ~= "function" then return nil end
    local ok,path=pcall(mod._kantoInMotionHdMenuIconForModernUi,self.game,mon)
    return ok and loadImage(path) or nil
  end

  local function monIsShiny(mon)
    if type(mon) ~= "table" then return false end
    if mon.shiny == true or mon.isShiny == true or mon.is_shiny == true then return true end
    local dvs = mon.dvs or mon.DVs or mon.dv
    if okStats and type(Stats) == "table" and type(Stats.isShiny) == "function"
        and type(dvs) == "table" then
      local ok, value = pcall(Stats.isShiny, dvs)
      if ok then return value == true end
    end
    return false
  end

  local function nativePreview(self,mon)
    if not (self and mon and self.game and self.game.data and self.game.data.pokemon) then return nil end
    local def=self.game.data.pokemon[mon.species]
    local image=def and loadImage(def.spriteFront) or nil
    local colors
    if image and okPalettes and type(Gen2Palettes) == "table"
        and type(Gen2Palettes.monColors) == "function" then
      local ok, value = pcall(Gen2Palettes.monColors, self.palettes, mon.species, monIsShiny(mon))
      if ok then colors = value end
    end
    return image, colors
  end

  local function preview(self,mon)
    if not mon then return nil end
    if tostring(opt("gen2MenuSpriteSource","kim"))=="vanilla" then
      return nativePreview(self,mon)
    end
    if mod.exports and type(mod.exports.getSprite)=="function" then
      local ok,image=pcall(mod.exports.getSprite,mon.species,{generation="hd",mon=mon})
      if ok and image then return image, nil end
    end
    -- Missing KIM art must never leave a blank Gen 2 preview.
    return nativePreview(self,mon)
  end

  local function monName(self,mon)
    local def=self.game and self.game.data and self.game.data.pokemon
      and self.game.data.pokemon[mon.species]
    return mon.nickname or (def and def.name) or mon.species or "POKéMON",def
  end

  local function moveName(self,m)
    local def=self.moves and m and self.moves[m.id]
    return (def and def.name) or (m and m.id) or "—"
  end

  local nativeIconQuads=setmetatable({}, {__mode="k"})

  local function nativeIconQuad(image,frame)
    if not image then return nil end
    local iw,ih=image:getDimensions()
    local y=(ih>=32 and ((tonumber(frame) or 0)%2)*16) or 0
    local rec=nativeIconQuads[image]
    if not rec then rec={} nativeIconQuads[image]=rec end
    local key=tostring(y)..":"..tostring(iw)..":"..tostring(ih)
    local q=rec[key]
    if not q then
      q=G.newQuad(0,y,math.min(16,iw),math.min(16,ih-y),iw,ih)
      rec[key]=q
    end
    return q
  end

  local function drawVanillaIcon(self,mon,x,y,size,selected)
    if not (self and type(self.iconFor)=="function") then return false end
    local ok,image,frame,trueColor=pcall(self.iconFor,self,mon)
    if not ok or not image then return false end
    local q=nativeIconQuad(image,frame)
    if not q then return false end
    local _,_,qw,qh=q:getViewport()
    local s=math.min(size/math.max(1,qw),size/math.max(1,qh))
    local bob=selected and ((math.floor((tonumber(self.clock) or 0)/16)%2==1) and -2 or 0) or 0
    local dx=x+(size-qw*s)/2
    local dy=y+(size-qh*s)/2+bob

    local pals=self.palettes and self.palettes.partyMenu
    local colors=pals and pals[1] or nil
    local shaded=colors and okGbc and type(GbcPalette)=="table"
      and type(GbcPalette.available)=="function" and GbcPalette.available()
    local usePalette=shaded and not (trueColor and GbcPalette.mode=="gbc")
    local previous=G.getShader and G.getShader() or nil
    color({1,1,1,1})
    if usePalette and type(GbcPalette.use)=="function" then GbcPalette.use(colors) end
    G.draw(image,q,dx,dy,0,s,s)
    if usePalette and G.setShader then G.setShader(previous) end
    return true
  end

  local function drawIcon(self,mon,x,y,size,selected)
    local image=hdIcon(self,mon)
    local bob=selected and ((math.floor((tonumber(self.clock) or 0)/16)%2==1) and -2 or 0) or 0
    if image then
      local iw,ih=image:getDimensions(); local s=math.min(size/iw,size/ih)
      color({1,1,1,1}); G.draw(image,x+(size-iw*s)/2,y+size-ih*s+bob,0,s,s)
      return true
    end
    -- POKEMON ICONS OFF means "use the game's icons", not "hide icons".
    -- Replay the native Gen 2 16x16 party icon inside KIM's modern row.
    return drawVanillaIcon(self,mon,x,y,size,selected)
  end

  local function drawParty(self)
    local colors=theme()
    local sx,sy,sw,sh=playfield()
    local mobile=mobileHost()
    local portrait=mobile and sh>sw*1.18
    local uiScale = Style and Style.uiScale and Style.uiScale(sw,sh) or 1
    local layout = Style and Style.layoutStyle and Style.layoutStyle() or "floating"
    local pw,ph,scale
    if portrait then
      pw=sw*.90; ph=sh*.62
      scale=math.min(uiScale,pw/820,ph/980)
    elseif mobile then
      pw=sw*.90; ph=sh*.82
      scale=math.min(uiScale,pw/1080,ph/690)
    else
      local compact = sw >= 900 and sh >= 600
      pw = compact and math.min(960*uiScale, sw * 0.62) or sw * 0.94
      ph = compact and math.min(470*uiScale, sh * 0.68) or math.min(sh * 0.84, pw * 0.78)
      scale=compact and uiScale or math.max(0.78,math.min(1.2,pw/760))
    end
    if layout=="full" then
      pw=sw*.94; ph=sh*.92; scale=math.min(pw/1080,ph/(portrait and 980 or 690))
    end
    scale=math.max(.52,scale)
    local x=sx+(sw-pw)/2; local y=sy+(sh-ph)/2
    panel(x,y,pw,ph,colors,0.92)
    local titleFont, bodyFont, smallFont = fontFor(34*scale), fontFor(26*scale), fontFor(19*scale)
    local pad=math.max(10,16*scale)
    local header=math.max(50*scale,titleFont:getHeight()+18*scale)
    local footer=math.max(44*scale,smallFont:getHeight()+18*scale)
    local title=("POKéMON  %d/6"):format(#self.party)
    local tf=fittedFont(34*scale,title,pw*.56,header*.76)
    drawText(title,tf,x+pad,y+math.max(6,10*scale),pw*.56,"left",colors.text)
    local prompt = type(self.bottomMessage)=="function" and self:bottomMessage() or "Choose a POKéMON."
    local pf=fittedFont(19*scale,prompt,pw*.38,header*.60)
    drawText(prompt,pf,x+pw*.59,y+math.max(8,14*scale),pw*.37-pad,"right",colors.muted)

    local contentY=y+header; local contentH=ph-header-footer
    local function rowInfo(mon,i,listX,listW,ry,rowH)
      local selected=self.index==i
      if selected then
        color(colors.selected,0.96); G.rectangle("fill",listX,ry+rowH*.06,listW,rowH*.88,5,5)
        color(colors.accent,nil,true); G.rectangle("fill",listX,ry+rowH*.06,math.max(2,3*scale),rowH*.88,2,2)
      end
      local iconSize=math.min(rowH*.74,30*scale)
      drawIcon(self,mon,listX+8*scale,ry+(rowH-iconSize)/2,iconSize,selected)
      local tx=listX+iconSize+18*scale
      local hp=self:shownHpFor(i,mon); local maxHp=mon.maxHp or (mon.stats and mon.stats.hp) or 1
      local level=("Lv %d"):format(tonumber(mon.level) or 0)
      local hpText=("%d/%d"):format(hp or 0,maxHp or 0)
      local infoW=math.max(82*scale,listW*.31)
      local nameW=math.max(40,listW-(tx-listX)-infoW-8*scale)
      local nf=fittedFont(26*scale,monName(self,mon),nameW,rowH*.44)
      local sf=fittedFont(19*scale,level,infoW*.44,rowH*.35)
      local hf=fittedFont(19*scale,hpText,infoW*.54,rowH*.35)
      local textY=ry+rowH*.12
      drawText(monName(self,mon),nf,tx,textY,nameW,"left",colors.text)
      local infoX=listX+listW-infoW
      drawText(level,sf,infoX,textY,infoW*.44,"left",colors.muted)
      local gender=resolvedGender(self,mon)
      if gender then
        local symbolSize=math.max(7,sf:getHeight()*.66)
        local gc=(gender=="male") and {0.28,0.66,1,1} or {1,0.40,0.66,1}
        local gx=math.min(infoX+infoW*.40,infoX+sf:getWidth(level)+5*scale)
        genderSymbol(gx,textY+sf:getHeight()*.50,symbolSize,gender,gc)
      end
      drawText(hpText,hf,infoX+infoW*.43,textY,infoW*.55,"right",colors.text)
      hpBar(tx,ry+rowH*.76,listW-(tx-listX)-8*scale,math.max(3,5*scale),hp,maxHp,colors)
    end

    local selected = self.party[math.max(1,math.min(#self.party,self.index or 1))]
    local function selectedStats(mon,def)
      local stats=mon.stats or {}; local computed=nil
      local function stat(...)
        local keys={...}
        for _,key in ipairs(keys) do local v=stats[key]; if tonumber(v)~=nil then return tonumber(v) end end
        for _,key in ipairs(keys) do local v=mon[key]; if tonumber(v)~=nil then return tonumber(v) end end
        if computed==nil and def and def.baseStats and mon.dvs then
          if okGen2Mon and Gen2Mon and type(Gen2Mon.stats)=="function" then
            local okCalc,value=pcall(Gen2Mon.stats,def.baseStats,mon.dvs,tonumber(mon.level) or 1,mon.statExp)
            computed=okCalc and type(value)=="table" and value or false
          else computed=false end
        end
        if type(computed)=="table" then
          for _,key in ipairs(keys) do local v=computed[key]; if tonumber(v)~=nil then return tonumber(v) end end
        end
        return "—"
      end
      return stat("attack","atk"),stat("defense","def"),stat("speed","spe"),
        stat("specialAttack","spAttack","spAtk","spa","special"),
        stat("specialDefense","spDefense","spDef","spd","special")
    end

    if portrait then
      local listH=contentH*.54
      local listX=x+pad*.55; local listW=pw-pad*1.10
      local rowH=listH/6
      for i=1,6 do local mon=self.party[i]; if mon then rowInfo(mon,i,listX,listW,contentY+(i-1)*rowH,rowH) end end
      local detailY=contentY+listH+math.max(6,8*scale)
      local detailH=y+ph-footer-detailY
      color(colors.divider,0.65,true); G.rectangle("fill",x+pad,detailY-4*scale,pw-pad*2,1)
      if selected then
        local name,def=monName(self,selected)
        local previewSize=math.min(detailH*.43,pw*.22)
        local px=x+pad; local py=detailY+6*scale
        local portraitImg,portraitColors=preview(self,selected)
        if portraitImg then
          local iw,ih=portraitImg:getDimensions(); local ss=math.min(previewSize/iw,previewSize/ih)
          local dx=px+(previewSize-iw*ss)/2; local dy=py+previewSize-ih*ss
          local function drawPortrait() color({1,1,1,1}); G.draw(portraitImg,dx,dy,0,ss,ss) end
          if portraitColors and okGbc and GbcPalette and type(GbcPalette.with)=="function" and GbcPalette.available() then GbcPalette.with(portraitColors,drawPortrait) else drawPortrait() end
        end
        local infoX=px+previewSize+10*scale; local infoW=x+pw-pad-infoX
        local nf=fittedFont(27*scale,name,infoW)
        drawText(name,nf,infoX,py,infoW,"left",colors.text)
        local levelText=("Lv %d"):format(tonumber(selected.level) or 0)
        local lf=fittedFont(18*scale,levelText,infoW*.40)
        drawText(levelText,lf,infoX,py+nf:getHeight()+3*scale,infoW*.40,"left",colors.muted)
        local gender=resolvedGender(self,selected)
        if gender then
          local symbolSize=lf:getHeight()*.74
          local gc=(gender=="male") and {0.28,0.66,1,1} or {1,0.40,0.66,1}
          genderSymbol(infoX+lf:getWidth(levelText)+6*scale,py+nf:getHeight()+3*scale+lf:getHeight()*.5,symbolSize,gender,gc)
        end
        local types=def and def.types or {}
        local typeText=table.concat(types or {}," / ")
        drawText(typeText,fittedFont(18*scale,typeText,infoW),infoX,py+nf:getHeight()+lf:getHeight()+8*scale,infoW,"left",colors.accent)
        local hp=selected.hp or 0; local maxHp=selected.maxHp or (selected.stats and selected.stats.hp) or 1
        hpBar(infoX,py+previewSize*.70,infoW,math.max(4,6*scale),hp,maxHp,colors)
        local hpText=("%d/%d"):format(hp,maxHp)
        drawText(hpText,fittedFont(18*scale,hpText,infoW),infoX,py+previewSize*.70+8*scale,infoW,"left",colors.text)

        local bottomY=py+previewSize+8*scale
        local bottomH=math.max(1,detailY+detailH-bottomY)
        local statsW=(pw-pad*2)*.43
        local movesX=x+pad+statsW+10*scale; local movesW=x+pw-pad-movesX
        local atk,defStat,speed,spAtk,spDef=selectedStats(selected,def)
        local statRows={{"ATK",atk,"SP.ATK",spAtk},{"DEF",defStat,"SP.DEF",spDef},{"SPEED",speed,"",""}}
        local step=bottomH/3
        for i,r in ipairs(statRows) do
          local yy=bottomY+(i-1)*step
          local a=tostring(r[1]).." "..tostring(r[2]); local b=r[3]~="" and (tostring(r[3]).." "..tostring(r[4])) or ""
          drawText(a,fittedFont(17*scale,a,statsW*.48,step*.8),x+pad,yy,statsW*.48,"left",colors.muted)
          if b~="" then drawText(b,fittedFont(17*scale,b,statsW*.48,step*.8),x+pad+statsW*.51,yy,statsW*.48,"left",colors.muted) end
        end
        local moves=selected.moves or {}; local moveStep=bottomH/4
        for i=1,4 do
          local m=moves[i]; if m then
            local mn=moveName(self,m); local pp=tonumber(m.pp) or 0; local maxpp=(self.moves and self.moves[m.id] and self.moves[m.id].pp) or pp
            local ppText=("PP %d/%d"):format(pp,maxpp)
            local yy=bottomY+(i-1)*moveStep
            local mnW=movesW*.62; local ppW=movesW*.36
            drawText(mn,fittedFont(17*scale,mn,mnW,moveStep*.85),movesX,yy,mnW,"left",colors.text)
            drawText(ppText,fittedFont(15*scale,ppText,ppW,moveStep*.85),movesX+mnW,yy,ppW,"right",colors.muted)
          end
        end
      end
    else
      local listW=pw*.52; local detailX=x+listW; local detailW=pw-listW
      color(colors.divider,0.7,true); G.rectangle("fill",detailX,contentY,1,contentH)
      local rowH=contentH/6
      for i=1,6 do local mon=self.party[i]; if mon then rowInfo(mon,i,x+6*scale,listW-12*scale,contentY+(i-1)*rowH,rowH) end end
      if selected then
        local name,def=monName(self,selected); local px=detailX+pad; local dw=detailW-pad*2
        local previewSize=math.min(dw*.42,contentH*.31)
        local portraitImg,portraitColors=preview(self,selected)
        if portraitImg then
          local iw,ih=portraitImg:getDimensions(); local ss=math.min(previewSize/iw,previewSize/ih)
          local dx=px+(previewSize-iw*ss)/2; local dy=contentY+pad+previewSize-ih*ss
          local function drawPortrait() color({1,1,1,1}); G.draw(portraitImg,dx,dy,0,ss,ss) end
          if portraitColors and okGbc and GbcPalette and type(GbcPalette.with)=="function" and GbcPalette.available() then GbcPalette.with(portraitColors,drawPortrait) else drawPortrait() end
        end
        local infoX=px+previewSize+8*scale; local infoW=detailX+detailW-pad-infoX
        drawText(name,fittedFont(25*scale,name,infoW),infoX,contentY+pad,infoW,"left",colors.text)
        local levelText=("Lv %d"):format(tonumber(selected.level) or 0)
        local levelFont=fittedFont(17*scale,levelText,infoW*.5)
        local levelY=contentY+pad+30*scale
        drawText(levelText,levelFont,infoX,levelY,infoW*.5,"left",colors.muted)
        local gender=resolvedGender(self,selected)
        if gender then
          local symbolSize=math.max(7,levelFont:getHeight()*.74)
          local gc=(gender=="male") and {0.28,0.66,1,1} or {1,0.40,0.66,1}
          genderSymbol(infoX+levelFont:getWidth(levelText)+6*scale,
            levelY+levelFont:getHeight()*.50,symbolSize,gender,gc)
        end
        local types=def and def.types or {}; local typeText=table.concat(types or {}," / ")
        drawText(typeText,fittedFont(17*scale,typeText,infoW),infoX,contentY+pad+52*scale,infoW,"left",colors.accent)
        local hp=selected.hp or 0; local maxHp=selected.maxHp or (selected.stats and selected.stats.hp) or 1
        hpBar(infoX,contentY+pad+77*scale,infoW,math.max(4,6*scale),hp,maxHp,colors)
        local hpText=("%d/%d"):format(hp,maxHp)
        drawText(hpText,fittedFont(17*scale,hpText,infoW),infoX,contentY+pad+87*scale,infoW,"left",colors.text)
        local statsY=contentY+math.max(previewSize+22*scale,125*scale)
        local movesY=contentY+contentH*.62
        local atk,defStat,speed,spAtk,spDef=selectedStats(selected,def)
        local statLines={{"ATK "..atk,"SP.ATK "..spAtk},{"DEF "..defStat,"SP.DEF "..spDef},{"SPEED "..speed,""}}
        local statStep=math.max(18*scale,(movesY-statsY)/3)
        for i,r in ipairs(statLines) do
          local yy=statsY+(i-1)*statStep
          drawText(r[1],fittedFont(16*scale,r[1],dw*.47,statStep*.85),px,yy,dw*.47,"left",colors.muted)
          if r[2]~="" then drawText(r[2],fittedFont(16*scale,r[2],dw*.47,statStep*.85),px+dw*.52,yy,dw*.47,"left",colors.muted) end
        end
        local moves=selected.moves or {}; local moveH=math.max(1,(contentY+contentH-movesY)/4)
        for i=1,4 do local m=moves[i]; if m then
          local mn=moveName(self,m); local pp=tonumber(m.pp) or 0; local maxpp=(self.moves and self.moves[m.id] and self.moves[m.id].pp) or pp
          local ppText=("PP %d/%d"):format(pp,maxpp); local yy=movesY+(i-1)*moveH
          drawText(mn,fittedFont(16*scale,mn,dw*.60,moveH*.85),px,yy,dw*.60,"left",colors.text)
          drawText(ppText,fittedFont(14*scale,ppText,dw*.36,moveH*.85),px+dw*.62,yy,dw*.36,"right",colors.muted)
        end end
      end
    end

    local footerY=y+ph-footer
    color(colors.divider,0.55,true); G.rectangle("fill",x+pad,footerY,pw-pad*2,1)
    local footPrompt=fittedFont(18*scale,prompt,pw*.58,footer*.72)
    drawText(prompt,footPrompt,x+pad,footerY+(footer-footPrompt:getHeight())*.50,pw*.58,"left",colors.muted)
    local cancelSelected=self:isCancel(); local cancelW=math.min(140*scale,pw*.24); local cancelX=x+pw-pad-cancelW
    if cancelSelected then color(colors.selected); G.rectangle("fill",cancelX,footerY+4*scale,cancelW,footer-8*scale,5,5) end
    local cf=fittedFont(23*scale,"CANCEL",cancelW-8*scale,footer*.70)
    drawText("CANCEL",cf,cancelX,footerY+(footer-cf:getHeight())*.50,cancelW,"center",cancelSelected and colors.text or colors.muted)

    if self.submenu and type(self.submenu.items)=="table" then
      local count=#self.submenu.items; local row=math.max(25*scale,bodyFont:getHeight()+8*scale)
      local mw=math.min(220*scale,pw*.48); local mh=count*row+16*scale
      local mx=x+pw-mw-pad; local my=math.max(y+header,y+ph-mh-footer)
      panel(mx,my,mw,mh,colors,0.98)
      for i,item in ipairs(self.submenu.items) do
        local yy=my+8*scale+(i-1)*row; local sf=fittedFont(22*scale,item.label or item.id or "?",mw-28*scale,row*.75)
        if i==self.submenu.index then color(colors.selected); G.rectangle("fill",mx+7*scale,yy+2*scale,mw-14*scale,row-4*scale,4,4) end
        drawText(item.label or item.id or "?",sf,mx+14*scale,yy+(row-sf:getHeight())*.50,mw-28*scale,"left",i==self.submenu.index and colors.text or colors.muted)
      end
    end
  end

  local upstreamNew=PartyMenu.new
  PartyMenu.new=function(game,opts)
    local self=upstreamNew(game,opts)
    if enabled() and hideOriginal() then self.isOpaque=false end
    return self
  end

  local upstreamUpdate=PartyMenu.update
  PartyMenu.update=function(self,...)
    self.isOpaque=not (enabled() and hideOriginal())
    return upstreamUpdate(self,...)
  end

  local upstreamWide=PartyMenu.drawsWidescreen
  PartyMenu.drawsWidescreen=function(self)
    if enabled() then return false end
    return upstreamWide and upstreamWide(self) or true
  end

  local function isParty(state)
    return type(state)=="table" and getmetatable(state)==PartyMenu
  end

  if mod.hooks and type(mod.hooks.wrap)=="function" then
    mod.hooks:wrap("screen.render_visible",function(nextFn,state)
      if enabled() and hideOriginal() and isParty(state) then return false end
      return nextFn(state)
    end,100000)

    mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
      local result={pcall(nextFn,game,viewport)}; local ok=table.remove(result,1)
      if not ok then error(result[1],0) end
      local top=game and game.stack and type(game.stack.top)=="function" and game.stack:top()
      if enabled() and isParty(top) then
        G.push("all"); G.origin(); pcall(drawParty,top); G.pop()
      end
      return unpack(result)
    end,100000)
  end

  PartyMenu.__kimModernOverlayV3=true
  return true
end
