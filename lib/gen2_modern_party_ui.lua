-- Kanto in Motion v1.7.1 - Gen 2 Modern Party UI v33
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
    local compact = sw >= 900 and sh >= 600
    local uiScale = Style and Style.uiScale and Style.uiScale(sw,sh) or 1
    local layout = Style and Style.layoutStyle and Style.layoutStyle() or "floating"
    -- Keep the six-slot party screen closer to the compact Gen 1 footprint.
    -- The previous 1080x690 authored box left a large unused lower-right area
    -- after the four moves were drawn.  The detail pane still has room for the
    -- portrait, all five Gen 2 battle stats and four moves at this size.
    local pw = compact and math.min(960*uiScale, sw * 0.62) or sw * 0.94
    local ph = compact and math.min(470*uiScale, sh * 0.68)
      or math.min(sh * 0.84, pw * 0.78)
    local scale=compact and uiScale or math.max(0.78,math.min(1.2,pw/760))
    if layout=="full" then
      pw=sw*.94; ph=sh*.92; scale=math.min(pw/1080,ph/690)
    end
    local x=sx+(sw-pw)/2; local y=sy+(sh-ph)/2
    panel(x,y,pw,ph,colors,0.92)
    local titleFont, bodyFont, smallFont =
      fontFor(34*scale), fontFor(26*scale), fontFor(19*scale)
    local pad=16*scale; local header=58*scale; local footer=44*scale
    drawText(("POKéMON  %d/6"):format(#self.party),titleFont,x+pad,y+12*scale,pw*0.45,"left",colors.text)
    local prompt = type(self.bottomMessage)=="function" and self:bottomMessage() or "Choose a POKéMON."
    drawText(prompt,smallFont,x+pw*0.52,y+18*scale,pw*0.44-pad,"right",colors.muted)

    local contentY=y+header; local contentH=ph-header-footer
    local listW=pw*0.52; local detailX=x+listW; local detailW=pw-listW
    color(colors.divider,0.7,true); G.rectangle("fill",detailX,contentY,1,contentH)

    local rows=math.max(6,#self.party)
    local rowH=contentH/6
    for i=1,6 do
      local mon=self.party[i]
      if mon then
        local ry=contentY+(i-1)*rowH
        local selected=self.index==i
        if selected then
          color(colors.selected,0.96); G.rectangle("fill",x+6,ry+2,listW-12,rowH-4,5,5)
          color(colors.accent,nil,true); G.rectangle("fill",x+6,ry+2,3,rowH-4,2,2)
        end
        local iconSize=math.min(rowH-8,30*scale)
        drawIcon(self,mon,x+14*scale,ry+(rowH-iconSize)/2,iconSize,selected)
        local name=monName(self,mon)
        local hp=self:shownHpFor(i,mon); local maxHp=mon.maxHp or (mon.stats and mon.stats.hp) or 1
        drawText(truncate(name,bodyFont,listW*0.42),bodyFont,x+52*scale,ry+7*scale,listW*0.45,"left",colors.text)
        drawText(("Lv %d"):format(tonumber(mon.level) or 0),smallFont,x+listW*0.66,ry+9*scale,listW*0.13,"right",colors.muted)
        drawText(("%d/%d"):format(hp or 0,maxHp or 0),smallFont,x+listW*0.80,ry+9*scale,listW*0.17,"right",colors.text)
        hpBar(x+52*scale,ry+rowH-9*scale,listW-68*scale,5*scale,hp,maxHp,colors)
      end
    end

    local selected = self.party[math.max(1,math.min(#self.party,self.index or 1))]
    if selected then
      local name,def=monName(self,selected)
      local px=detailX+pad; local py=contentY+pad
      local portrait,portraitColors=preview(self,selected)
      local portraitBox=88*scale
      if portrait then
        local iw,ih=portrait:getDimensions(); local s=math.min(portraitBox/iw,portraitBox/ih)
        local dx=px+(portraitBox-iw*s)/2
        local dy=py+portraitBox-ih*s
        local function drawPortrait()
          color({1,1,1,1}); G.draw(portrait,dx,dy,0,s,s)
        end
        if portraitColors and okGbc and type(GbcPalette)=="table"
            and type(GbcPalette.with)=="function" and type(GbcPalette.available)=="function"
            and GbcPalette.available() then
          GbcPalette.with(portraitColors,drawPortrait)
        else
          drawPortrait()
        end
      end
      local tx=px+portraitBox+10*scale
      drawText(name,bodyFont,tx,py,detailW-(tx-detailX)-pad,"left",colors.text)
      local levelText=("Lv %d"):format(tonumber(selected.level) or 0)
      local levelY=py+30*scale
      drawText(levelText,smallFont,tx,levelY,140*scale,"left",colors.muted)
      local gender=resolvedGender(self,selected)
      if gender=="male" or gender=="female" then
        local symbolSize=smallFont:getHeight()*.78
        local gx=tx+smallFont:getWidth(levelText)+6*scale+symbolSize*.36
        local gy=levelY+smallFont:getHeight()*.50
        local gc=(gender=="male") and {0.28,0.66,1,1} or {1,0.40,0.66,1}
        genderSymbol(gx,gy,symbolSize,gender,gc)
      end
      local types=def and def.types or {}
      drawText(table.concat(types or {}, " / "),smallFont,tx,py+52*scale,detailW-(tx-detailX)-pad,"left",colors.accent)

      local hp=selected.hp or 0; local maxHp=selected.maxHp or (selected.stats and selected.stats.hp) or 1
      hpBar(tx,py+78*scale,detailW-(tx-detailX)-pad,7*scale,hp,maxHp,colors)
      drawText(("%d/%d"):format(hp,maxHp),smallFont,tx,py+89*scale,detailW-(tx-detailX)-pad,"left",colors.text)

      -- Gen 2 has five non-HP battle stats.  Party records normally carry
      -- attack/defense/speed/specialAttack/specialDefense, but imported or
      -- older records can arrive with aliases or an incomplete cached block.
      -- Resolve aliases first, then recompute from the native Gen 2 formula
      -- without mutating the saved Pokémon so the detail pane never shows a
      -- misleading dash for Speed / Sp. Atk / Sp. Def.
      local stats=selected.stats or {}
      local computed=nil
      local function stat(...)
        local keys={...}
        for _,key in ipairs(keys) do
          local v=stats[key]
          if tonumber(v)~=nil then return tonumber(v) end
        end
        for _,key in ipairs(keys) do
          local v=selected[key]
          if tonumber(v)~=nil then return tonumber(v) end
        end
        if computed==nil and def and def.baseStats and selected.dvs then
          local okMon,Gen2Mon=pcall(require,"src.battle.gen2.Mon")
          if okMon and Gen2Mon and type(Gen2Mon.stats)=="function" then
            local okCalc,value=pcall(Gen2Mon.stats,def.baseStats,selected.dvs,
              tonumber(selected.level) or 1,selected.statExp)
            computed=okCalc and type(value)=="table" and value or false
          else
            computed=false
          end
        end
        if type(computed)=="table" then
          for _,key in ipairs(keys) do
            local v=computed[key]
            if tonumber(v)~=nil then return tonumber(v) end
          end
        end
        return "—"
      end

      local atk=stat("attack","atk")
      local defStat=stat("defense","def")
      local speed=stat("speed","spe")
      local spAtk=stat("specialAttack","spAttack","spAtk","spa","special")
      local spDef=stat("specialDefense","spDefense","spDef","spd","special")
      local sy2=py+portraitBox+16*scale
      -- Give the five Gen 2 battle stats room to breathe.  The compact Party
      -- window still has plenty of horizontal and vertical space in the
      -- detail pane, so keep two clearly separated columns and increase the
      -- row pitch instead of packing the labels together.
      local statLeft=detailW*0.38
      local statRightX=px+detailW*0.58
      local statRightW=detailW*0.34
      local statStep=22*scale
      drawText("ATK "..tostring(atk),smallFont,px,sy2,statLeft,"left",colors.muted)
      drawText("SP.ATK "..tostring(spAtk),smallFont,statRightX,sy2,statRightW,"left",colors.muted)
      drawText("DEF "..tostring(defStat),smallFont,px,sy2+statStep,statLeft,"left",colors.muted)
      drawText("SP.DEF "..tostring(spDef),smallFont,statRightX,sy2+statStep,statRightW,"left",colors.muted)
      drawText("SPEED "..tostring(speed),smallFont,px,sy2+statStep*2,statLeft,"left",colors.muted)

      local my=sy2+statStep*3+6*scale
      for i,m in ipairs(selected.moves or {}) do
        if i>4 then break end
        local pp=tonumber(m.pp) or 0
        local maxpp=(self.moves and self.moves[m.id] and self.moves[m.id].pp) or pp
        drawText(moveName(self,m),smallFont,px,my+(i-1)*24*scale,detailW*0.58,"left",colors.text)
        drawText(("PP %d/%d"):format(pp,maxpp),smallFont,px+detailW*0.58,my+(i-1)*24*scale,detailW*0.33,"right",colors.muted)
      end
    end

    local footerY = y + ph - footer
    drawText("Choose a POKéMON.",smallFont,x+pad,
      footerY + (footer-smallFont:getHeight())*0.50,
      pw*0.60,"left",colors.muted)
    local cancelSelected=self:isCancel()
    local cancelH=footer-8*scale
    local cancelY=footerY+4*scale
    if cancelSelected then
      color(colors.selected); G.rectangle("fill",x+pw-150*scale,cancelY,126*scale,cancelH,5,5)
    end
    drawText("CANCEL",bodyFont,x+pw-150*scale,
      cancelY+(cancelH-bodyFont:getHeight())*0.50,126*scale,"center",
      cancelSelected and colors.text or colors.muted)

    if self.submenu and type(self.submenu.items)=="table" then
      local count=#self.submenu.items; local row=25*scale
      local mw=180*scale; local mh=count*row+16*scale
      local mx=x+pw-mw-18*scale; local my=y+ph-mh-18*scale
      panel(mx,my,mw,mh,colors,0.98)
      for i,item in ipairs(self.submenu.items) do
        local yy=my+8*scale+(i-1)*row
        local textH=bodyFont:getHeight()
        local textY=yy+(row-textH)*0.50
        if i==self.submenu.index then
          -- Keep the selection bar centered on the row/text instead of
          -- starting at the row's top edge. This mirrors the main party list
          -- highlight and stays centered when UI/font scale changes.
          local highlightH=math.min(row-4*scale,textH+8*scale)
          local highlightY=yy+(row-highlightH)*0.50
          color(colors.selected)
          G.rectangle("fill",mx+7*scale,highlightY,mw-14*scale,highlightH,4,4)
        end
        drawText(item.label or item.id or "?",bodyFont,mx+14*scale,textY,mw-28*scale,"left",
          i==self.submenu.index and colors.text or colors.muted)
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
