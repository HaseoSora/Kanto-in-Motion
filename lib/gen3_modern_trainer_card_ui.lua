-- Kanto in Motion - Gen 3 Modern Trainer Card
--
-- Presentation-only replacement for the native FR/LG, Ruby/Sapphire and
-- Emerald Trainer Card.  Game3 retains complete ownership of card data,
-- A/B input, front/back flipping, fades, link-card state and close callbacks.
return function(mod)
  if not (love and love.graphics and mod and mod.hooks and type(mod.hooks.wrap)=="function") then
    return false
  end

  local G=love.graphics
  local Style=mod._kantoInMotionGen3Ui
  local okCard,Card=pcall(require,"src.ui.game3.trainer_card")
  local okRs,RsCard=pcall(require,"src.ui.game3.rs.trainer_card")
  local okKit,Kit=pcall(require,"src.ui.game3.rse.scene_kit")
  local okStack,Stack=pcall(require,"src.ui.game3.stack")
  local okPokemon,Pokemon=pcall(require,"src.core.game3.pokemon")
  if not okCard and not okRs then return false end

  local FALLBACK={
    surface={.075,.105,.17,.98},raised={.12,.17,.27,1},selected={.18,.43,.72,1},
    accent={.48,.86,1,1},frame={.48,.86,1,1},frameShadow={.01,.02,.04,.42},
    text={.96,.98,1,1},muted={.74,.82,.92,1},divider={.38,.50,.68,.94},
  }

  local fontCache={}
  local function opt(key,fallback)
    if not (mod.options and type(mod.options.get)=="function") then return fallback end
    local ok,v=pcall(mod.options.get,mod.options,key)
    if not ok or v==nil then return fallback end
    return v
  end
  local function enabled()
    if Style and Style.presenterEnabled then return Style.presenterEnabled("menu") end
    return opt("gen3IntegratedModernUi",true)~=false and opt("gen3MenuUi",true)~=false
  end
  local function hideOriginal()
    return not Style or not Style.hideOriginal or Style.hideOriginal()
  end
  local function theme()
    if Style and Style.theme then return Style.theme() end
    local themes=mod._kantoInMotionGen3Themes
    return type(themes)=="table" and (themes[tostring(opt("gen3UiTheme","default"))] or themes.default) or FALLBACK
  end
  local function color(c,a,foreground)
    if Style and Style.color then return Style.color(c,a,foreground~=false) end
    c=c or {1,1,1,1}; G.setColor(c[1] or 1,c[2] or 1,c[3] or 1,a==nil and (c[4] or 1) or a)
  end
  local function font(px)
    if Style and Style.font then return Style.font(px) end
    px=math.max(9,math.floor((tonumber(px) or 12)+.5))
    if fontCache[px] then return fontCache[px] end
    local ok,f=pcall(G.newFont,px); if ok and f then fontCache[px]=f; return f end
    return G.getFont()
  end
  local function text(v,f,x,y,w,align,c)
    if Style and Style.text then return Style.text(v,f,x,y,w,align,c) end
    if f then G.setFont(f) end; color(c,nil,true); v=tostring(v or "")
    if w and w>0 then G.printf(v,x,y,w,align or "left") else G.print(v,x,y) end
  end
  local function fit(v,f,maxW)
    v=tostring(v or "")
    if not f or not maxW or f:getWidth(v)<=maxW then return v end
    local suffix="..."; local target=math.max(0,maxW-f:getWidth(suffix))
    while #v>0 and f:getWidth(v)>target do v=v:sub(1,#v-1) end
    return v..suffix
  end
  local function uiScale()
    if Style and Style.uiScale then local w,h=G.getDimensions(); return Style.uiScale(w,h) end
    local v=tostring(opt("gen3UiScale","100")); if v:lower()=="auto" then return 1 end
    return math.max(.75,math.min(4,(tonumber(v) or 100)/100))
  end
  local function panel(x,y,w,h,c,a)
    if Style and Style.panel then return Style.panel(x,y,w,h,c,a or 1) end
    local r=math.max(6,math.min(w,h)*.018)
    color(c.frameShadow or FALLBACK.frameShadow,.22,false); G.rectangle("fill",x+3,y+4,w,h,r,r)
    color(c.surface,nil,false); G.rectangle("fill",x,y,w,h,r,r)
    color(c.frame,nil,true); G.setLineWidth(math.max(1,math.min(w,h)*.004)); G.rectangle("line",x+.5,y+.5,w-1,h-1,r,r)
  end
  local function card(x,y,w,h,fill,line,r)
    r=r or math.max(4,math.min(w,h)*.035)
    local pa=Style and Style.panelOpacity and Style.panelOpacity(1) or 1
    color(fill,math.min(1,(fill and fill[4] or 1)*pa),false); G.rectangle("fill",x,y,w,h,r,r)
    if line then color(line,nil,true); G.setLineWidth(math.max(1,math.min(w,h)*.008)); G.rectangle("line",x+.5,y+.5,w-1,h-1,r,r) end
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

  local function openGeneric()
    if not (okCard and type(Card)=="table") then return false end
    if type(Card.isOpen)=="function" then local ok,v=pcall(Card.isOpen); if ok then return v==true end end
    return Card.open==true
  end
  local function openRs()
    if not (okRs and type(RsCard)=="table") then return false end
    if type(RsCard.isOpen)=="function" then local ok,v=pcall(RsCard.isOpen); if ok then return v==true end end
    return RsCard.open==true
  end
  local function active()
    if openRs() then return RsCard,"rs" end
    if openGeneric() then return Card,(Card._rse and "emerald" or "frlg") end
    return nil,nil
  end

  -- Game3 opens Trainer Card as a fullscreen modal. Modern UI should match
  -- the other KIM Gen 3 menus instead: keep the live overworld drawable
  -- underneath the floating card while leaving source input/state ownership
  -- untouched. The original flags are restored if Modern UI is disabled while
  -- the card is still open.
  local function setFloating(on)
    if not (okStack and Stack and type(Stack._layers)=="table") then return end
    for i=#Stack._layers,1,-1 do
      local layer=Stack._layers[i]
      if layer and layer.id=="trainer" then
        if on then
          if layer._kimGen3TrainerCardOriginal==nil then
            layer._kimGen3TrainerCardOriginal={
              hideBelow=layer.hideBelow, drawUnder=layer.drawUnder, fullscreen=layer.fullscreen,
            }
          end
          layer.hideBelow=false
          layer.drawUnder=true
          layer.fullscreen=false
        elseif layer._kimGen3TrainerCardOriginal then
          local o=layer._kimGen3TrainerCardOriginal
          layer.hideBelow=o.hideBelow
          layer.drawUnder=o.drawUnder
          layer.fullscreen=o.fullscreen
          layer._kimGen3TrainerCardOriginal=nil
        end
        return
      end
    end
  end

  -- Suppress only the source pixels.  Source update/input/flip/fade/callback
  -- state remains authoritative and is read live by the final-resolution card.
  if okCard and type(Card)=="table" and not Card.__kimGen3ModernTrainerCardV126 then
    local upstream=Card.draw
    if type(upstream)=="function" then
      Card.draw=function(...)
        if enabled() and hideOriginal() and openGeneric() then return end
        return upstream(...)
      end
    end
    Card.__kimGen3ModernTrainerCardV126=true
  end
  if okRs and type(RsCard)=="table" and not RsCard.__kimGen3ModernTrainerCardV126 then
    local upstream=RsCard.draw
    if type(upstream)=="function" then
      RsCard.draw=function(...)
        if enabled() and hideOriginal() and openRs() then return end
        return upstream(...)
      end
    end
    RsCard.__kimGen3ModernTrainerCardV126=true
  end

  local imageCache={}
  local function image(path)
    if not path then return nil end
    if imageCache[path]~=nil then return imageCache[path] or nil end
    local img
    if okKit and Kit and Kit.image then
      local ok,v=pcall(Kit.image,path); if ok then img=v end
    end
    if not img and mod.assets and type(mod.assets.image)=="function" then
      local ok,v=pcall(mod.assets.image,mod.assets,path); if ok then img=v end
    end
    if not img then local ok,v=pcall(G.newImage,path); if ok then img=v end end
    imageCache[path]=img or false
    return img
  end
  local function rgba(path,w,h)
    local key=tostring(path).."#"..tostring(w).."x"..tostring(h)
    if imageCache[key]~=nil then return imageCache[key] or nil end
    local img
    if okKit and Kit and Kit.rgbaImage then
      local ok,v=pcall(Kit.rgbaImage,path,w,h); if ok then img=v end
    end
    imageCache[key]=img or false
    return img
  end
  local function loadLua(path)
    if okKit and Kit and Kit.loadLua then local ok,v=pcall(Kit.loadLua,path); if ok then return v end end
    return nil
  end

  local KANTO_BADGES={"BOULDER","CASCADE","THUNDER","RAINBOW","SOUL","MARSH","VOLCANO","EARTH"}
  local HOENN_BADGES={"STONE","KNUCKLE","DYNAMO","HEAT","BALANCE","FEATHER","MIND","RAIN"}

  local function female(c)
    if c.female~=nil then return c.female==true end
    local g=c.gender or c.playerGender
    return g==1 or g=="female" or g=="F"
  end
  local function dataFor(menu,kind)
    local c=type(menu._card)=="table" and menu._card or {}
    local version=(menu._session and menu._session.version) or c.version or (kind=="emerald" and "emerald") or ""
    return c,tostring(version or "")
  end
  local function playerName(c)
    local n=c.playerName or c.name or "TRAINER"
    n=tostring(n); if n=="" then n="TRAINER" end
    return n
  end
  local function moneyText(v) return "¥"..tostring(math.max(0,math.floor(tonumber(v) or 0))) end
  local function timeText(c)
    return string.format("%d:%02d",math.max(0,math.floor(tonumber(c.playTimeHours) or 0)),math.max(0,math.min(59,math.floor(tonumber(c.playTimeMinutes) or 0))))
  end
  local function trainerIdText(c) return string.format("%05d",(math.floor(tonumber(c.trainerId) or 0))%100000) end
  local function stars(c) return math.max(0,math.min(4,math.floor(tonumber(c.stars) or 0))) end

  local function drawStar(cx,cy,r,filled,c)
    local pts={}
    for i=0,9 do
      local rr=(i%2==0) and r or r*.43
      local a=-math.pi/2+i*math.pi/5
      pts[#pts+1]=cx+math.cos(a)*rr; pts[#pts+1]=cy+math.sin(a)*rr
    end
    color(filled and c.accent or c.raised,filled and .98 or .72,filled)
    G.polygon("fill",pts)
    color(filled and c.accent or c.divider,nil,true); G.setLineWidth(math.max(1,r*.12)); G.polygon("line",pts)
  end

  local function trainerPortrait(menu,kind,c)
    if not (okKit and Kit) then return nil end
    local isFemale=female(c)
    if kind=="rs" then
      local m=menu._man
      local p=m and m.pics and m.pics[isFemale and "female" or "male"]
      return p and image(p.png) or nil
    end
    if kind=="emerald" then
      local m=loadLua("data/generated/gba/rse/trainer_card/manifest.lua")
      local id=m and m.pics and m.pics[isFemale and "female" or "male"]
      if type(id)=="table" then return image(id.png) end
      if tonumber(id) then return rgba("data/generated/gba/trainers/front/"..tostring(id)..".rgba",64,64) end
      return nil
    end
    local m=loadLua("data/generated/gba/trainer_card/manifest.lua")
    local id=m and m.pics and m.pics[isFemale and "female" or "male"]
    if type(id)=="table" then return image(id.png) end
    if tonumber(id) then return rgba("data/generated/gba/trainers/front/"..tostring(id)..".rgba",64,64) end
    return nil
  end

  local badgeQuadCache=setmetatable({},{__mode="k"})
  local function badgeSheet(menu,kind)
    if kind=="frlg" then return rgba("data/generated/gba/trainer_card/badges.rgba",128,16) end
    local m=(kind=="rs") and menu._man or loadLua("data/generated/gba/rse/trainer_card/manifest.lua")
    return m and m.badges and image(m.badges.png) or nil
  end
  local function badgeQuad(img,i)
    if not (img and G.newQuad) then return nil end
    local q=badgeQuadCache[img]; if not q then q={}; badgeQuadCache[img]=q end
    if q[i] then return q[i] end
    local iw,ih=img:getDimensions(); if iw<16*i or ih<16 then return nil end
    q[i]=G.newQuad((i-1)*16,0,16,16,iw,ih); return q[i]
  end

  local function monIcon(species,x,y,size)
    if not (okPokemon and Pokemon and Pokemon.icon and tonumber(species) and tonumber(species)>0) then return false end
    local ok,ic=pcall(Pokemon.icon,tonumber(species)); if not ok or not ic or not ic.image then return false end
    local iw=tonumber(ic.w) or ic.image:getWidth(); local ih=tonumber(ic.h) or ic.image:getHeight()
    local q=ic.quads and (ic.quads[0] or ic.quads[1])
    local sc=math.min(size/iw,size/ih,1.75)
    color({1,1,1,1},1,true)
    if q then G.draw(ic.image,q,x+size*.5,y+size*.5,0,sc,sc,iw*.5,ih*.5)
    else G.draw(ic.image,x+size*.5,y+size*.5,0,sc,sc,iw*.5,ih*.5) end
    return true
  end

  local function labelValue(label,value,x,y,w,labelF,valueF,c)
    text(label,labelF,x,y,w*.48,"left",c.muted)
    text(value,valueF,x+w*.46,y,w*.54,"right",c.text)
  end

  local function drawBadges(menu,kind,c,colors,x,y,w,h,smallF,tinyF,sc)
    local names=(kind=="frlg") and KANTO_BADGES or HOENN_BADGES
    local img=badgeSheet(menu,kind)
    local gap=math.max(3,5*sc); local cellW=(w-gap*7)/8
    local cellH=h
    for i=1,8 do
      local bx=x+(i-1)*(cellW+gap); local owned=type(c.badges)=="table" and c.badges[i]==true
      card(bx,y,cellW,cellH,owned and colors.selected or colors.raised,owned and colors.accent or colors.divider,math.max(3,4*sc))
      local iconSize=math.min(cellW*.44,cellH*.48)
      local q=img and badgeQuad(img,i)
      if owned and q then
        color({1,1,1,1},1,true)
        G.draw(img,q,bx+cellW*.5,y+cellH*.32,0,iconSize/16,iconSize/16,8,8)
      else
        -- A simple badge number remains visible even when the native badge
        -- sheet is unavailable in an older cache.
        text(tostring(i),smallF,bx,y+cellH*.16,cellW,"center",owned and colors.text or colors.muted)
      end
      text(names[i],tinyF,bx+2*sc,y+cellH*.66,cellW-4*sc,"center",owned and colors.text or colors.muted)
    end
  end

  local function drawFront(menu,kind,c,colors,x,y,w,h,sc)
    local pad=math.max(12*sc,w*.025)
    local titleF,bodyF,smallF,tinyF=font(19*sc),font(13*sc),font(10.2*sc),font(8.1*sc)
    local headerH=math.max(54*sc,h*.105)
    text("TRAINER CARD",titleF,x+pad,y+pad*.68,w*.55,"left",colors.text)
    local version=tostring((menu._session and menu._session.version) or c.version or kind or ""):upper()
    if version=="FRLG" then version="FIRE RED / LEAF GREEN" end
    text(version,smallF,x+pad,y+pad*.68+titleF:getHeight()+2*sc,w*.5,"left",colors.muted)

    local starR=math.max(7*sc,headerH*.12); local starGap=starR*2.35
    local sx0=x+w-pad-starGap*4+starR
    for i=1,4 do drawStar(sx0+(i-1)*starGap,y+headerH*.52,starR,i<=stars(c),colors) end

    local contentY=y+headerH
    local badgeH=math.max(80*sc,h*.17)
    local footerH=math.max(38*sc,h*.075)
    local contentH=h-headerH-badgeH-footerH-pad*.7
    local leftW=w*.55
    local rightX=x+leftW+pad*.15
    local rightW=x+w-pad-rightX

    card(x+pad,contentY,leftW-pad*1.25,contentH,colors.raised,colors.divider,6*sc)
    local rx=x+pad*1.75; local rw=leftW-pad*2.7
    local rows={
      {"NAME",playerName(c)}, {"ID No.",trainerIdText(c)}, {"MONEY",moneyText(c.money)},
    }
    if c.hasPokedex then rows[#rows+1]={"POKéDEX",tostring(c.caughtMonsCount or c.pokedexSeen or 0)} end
    rows[#rows+1]={"PLAY TIME",timeText(c)}
    local rowH=contentH/math.max(5,#rows)
    local yy=contentY+rowH*.28
    for i,r in ipairs(rows) do
      labelValue(r[1],r[2],rx,yy+(i-1)*rowH,rw,smallF,bodyF,colors)
      if i<#rows then color(colors.divider,.35,false); G.rectangle("fill",rx,yy+i*rowH-rowH*.22,rw,math.max(1,sc)) end
    end

    card(rightX,contentY,rightW,contentH,colors.raised,colors.divider,6*sc)
    text("TRAINER",smallF,rightX+pad*.55,contentY+pad*.45,rightW-pad*1.1,"left",colors.accent)
    local pic=trainerPortrait(menu,kind,c)
    local picAreaH=contentH-pad*2.3-smallF:getHeight()
    if pic then
      local iw,ih=pic:getDimensions(); local maxW=rightW*.68; local maxH=picAreaH*.82
      local ps=math.min(maxW/iw,maxH/ih)
      color({1,1,1,1},1,true)
      G.draw(pic,rightX+rightW*.5,contentY+smallF:getHeight()+pad+picAreaH*.48,0,ps,ps,iw*.5,ih*.5)
    else
      text(female(c) and "♀" or "♂",titleF,rightX,contentY+contentH*.43,rightW,"center",colors.muted)
    end
    text(playerName(c),bodyF,rightX+pad*.4,contentY+contentH-bodyF:getHeight()-pad*.55,rightW-pad*.8,"center",colors.text)

    local badgeY=y+h-footerH-badgeH
    text((kind=="frlg") and "KANTO BADGES" or "HOENN BADGES",smallF,x+pad,badgeY-smallF:getHeight()-3*sc,w-pad*2,"left",colors.accent)
    drawBadges(menu,kind,c,colors,x+pad,badgeY,w-pad*2,badgeH-smallF:getHeight()*.15,smallF,tinyF,sc)

    local footerY=y+h-footerH
    color(colors.divider,.65,false); G.rectangle("fill",x+pad,footerY,w-pad*2,math.max(1,sc))
    text("A  view records     B  close",smallF,x+pad,footerY+(footerH-smallF:getHeight())*.52,w-pad*2,"center",colors.muted)
  end

  local function addRecord(rows,label,value)
    if value==nil then return end
    value=tostring(value); if value=="" then return end
    rows[#rows+1]={label,value}
  end
  local function drawBack(menu,kind,c,colors,x,y,w,h,sc)
    local pad=math.max(12*sc,w*.025)
    local titleF,bodyF,smallF,tinyF=font(19*sc),font(12.2*sc),font(9.8*sc),font(8*sc)
    local headerH,footerH=math.max(54*sc,h*.105),math.max(38*sc,h*.075)
    text("TRAINER CARD",titleF,x+pad,y+pad*.68,w*.55,"left",colors.text)
    text("RECORDS",smallF,x+pad,y+pad*.68+titleF:getHeight()+2*sc,w*.35,"left",colors.accent)
    text(playerName(c),bodyF,x+w*.58,y+pad*.9,w*.36,"right",colors.text)

    local rows={}
    if c.hasHofResult or (tonumber(c.hofDebutHours) or 0)~=0 or (tonumber(c.hofDebutMinutes) or 0)~=0 then
      addRecord(rows,"HALL OF FAME",string.format("%d:%02d:%02d",tonumber(c.hofDebutHours) or 0,tonumber(c.hofDebutMinutes) or 0,tonumber(c.hofDebutSeconds) or 0))
    end
    if c.hasLinkResults or (tonumber(c.linkBattleWins) or 0)~=0 or (tonumber(c.linkBattleLosses) or 0)~=0 then
      addRecord(rows,"LINK BATTLES",string.format("W %d   /   L %d",tonumber(c.linkBattleWins) or 0,tonumber(c.linkBattleLosses) or 0))
    end
    if c.hasTrades or (tonumber(c.pokemonTrades) or 0)~=0 then addRecord(rows,"POKéMON TRADES",tonumber(c.pokemonTrades) or 0) end
    if kind=="frlg" then
      if (tonumber(c.unionRoomNum) or 0)~=0 then addRecord(rows,"UNION ROOM",tonumber(c.unionRoomNum) or 0) end
      if (tonumber(c.berryCrushPoints) or 0)~=0 then addRecord(rows,"BERRY CRUSH",tonumber(c.berryCrushPoints) or 0) end
    else
      if (tonumber(c.pokeblocksWithFriends) or 0)~=0 then addRecord(rows,"POKéBLOCKS WITH FRIENDS",tonumber(c.pokeblocksWithFriends) or 0) end
      if (tonumber(c.contestsWithFriends) or 0)~=0 then addRecord(rows,"CONTESTS WITH FRIENDS",tonumber(c.contestsWithFriends) or 0) end
      if (tonumber(c.frontierBP) or 0)~=0 then addRecord(rows,"BATTLE POINTS",tonumber(c.frontierBP) or 0) end
      if (tonumber(c.battleTowerWins) or 0)~=0 then addRecord(rows,"BATTLE TOWER WINS",tonumber(c.battleTowerWins) or 0) end
      if (tonumber(c.battleTowerLosses) or 0)~=0 then addRecord(rows,"BEST TOWER STREAK",tonumber(c.battleTowerLosses) or 0) end
    end

    local contentY=y+headerH
    local iconsPresent=false
    if type(c.monSpecies)=="table" then for i=1,6 do if tonumber(c.monSpecies[i] or 0)>0 then iconsPresent=true break end end end
    local iconsH=iconsPresent and math.max(76*sc,h*.17) or 0
    local contentH=h-headerH-footerH-iconsH-pad*.45
    card(x+pad,contentY,w-pad*2,contentH,colors.raised,colors.divider,6*sc)

    if #rows==0 then
      text("No record data yet.",bodyF,x+pad*1.7,contentY+contentH*.43,w-pad*3.4,"center",colors.muted)
    else
      local cols=(#rows>=7) and 2 or 1
      local perCol=math.ceil(#rows/cols)
      local colGap=pad
      local colW=(w-pad*3-colGap*(cols-1))/cols
      local rowH=contentH/math.max(1,perCol)
      for i,r in ipairs(rows) do
        local col=math.floor((i-1)/perCol); local row=(i-1)%perCol
        local bx=x+pad*1.5+col*(colW+colGap); local by=contentY+row*rowH
        text(fit(r[1],smallF,colW*.63),smallF,bx,by+rowH*.28,colW*.63,"left",colors.muted)
        text(fit(r[2],bodyF,colW*.36),bodyF,bx+colW*.64,by+rowH*.23,colW*.36,"right",colors.text)
        if row<perCol-1 then color(colors.divider,.30,false); G.rectangle("fill",bx,by+rowH-1*sc,colW,math.max(1,sc)) end
      end
    end

    if iconsPresent then
      local iy=y+h-footerH-iconsH+pad*.20
      text("PROFILE POKéMON",smallF,x+pad,iy,w-pad*2,"left",colors.accent)
      local boxY=iy+smallF:getHeight()+4*sc
      local gap=math.max(5,7*sc); local bw=(w-pad*2-gap*5)/6; local bh=iconsH-smallF:getHeight()-8*sc
      for i=1,6 do
        local bx=x+pad+(i-1)*(bw+gap); card(bx,boxY,bw,bh,colors.raised,colors.divider,4*sc)
        local sp=tonumber(c.monSpecies[i] or 0)
        if sp and sp>0 then monIcon(sp,bx,boxY,math.min(bw,bh)) end
      end
    end

    local footerY=y+h-footerH
    color(colors.divider,.65,false); G.rectangle("fill",x+pad,footerY,w-pad*2,math.max(1,sc))
    text("B  front side     A  close",smallF,x+pad,footerY+(footerH-smallF:getHeight())*.52,w-pad*2,"center",colors.muted)
  end

  local function drawModern(menu,kind,viewport)
    local c=type(menu._card)=="table" and menu._card or nil
    if not c then return false end
    if kind=="rs" and tostring(menu._phase or "") == "setup" then return false end
    local colors=theme(); local sx,sy,sw,sh=playfield(viewport); local us=uiScale()
    local w=math.min(sw*.82,980*math.min(sw/1280,sh/720)*us)
    local h=math.min(sh*.88,630*math.min(sw/1280,sh/720)*us)
    w=math.max(w,sw*.58); h=math.max(h,sh*.62)
    if Style and Style.layoutStyle and Style.layoutStyle()=="full" then w=sw*.94; h=sh*.92 end
    local x=sx+(sw-w)*.5; local y=sy+(sh-h)*.5
    local sc=math.max(.72,math.min(w/900,h/560))

    -- Keep the live overworld visible around the card, matching Party, Bag,
    -- Summary, Pokédex and the other floating Modern UI screens. The source
    -- Trainer Card pixels are already suppressed above, so no playfield-sized
    -- theme backdrop is needed here.

    local flip=menu._flip
    local scaleY=1
    if type(flip)=="table" and tonumber(flip.top) then scaleY=math.max(.045,1-math.min(79,math.max(0,tonumber(flip.top)))/80) end
    G.push()
    if scaleY<.999 then
      local cy=y+h*.5; G.translate(0,cy); G.scale(1,scaleY); G.translate(0,-cy)
    end
    panel(x,y,w,h,colors,1)
    color(colors.accent,nil,true); G.rectangle("fill",x,y,w,math.max(3,h*.009))
    local side=tostring(menu.side or "front")
    if side=="back" then drawBack(menu,kind,c,colors,x,y,w,h,sc) else drawFront(menu,kind,c,colors,x,y,w,h,sc) end
    G.pop()
    return true
  end

  mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
    nextFn(game,viewport)
    local menu,kind=active()
    if not enabled() then
      if menu then setFloating(false) end
      return
    end
    if not menu then return end
    setFloating(true)
    G.push("all")
    local ok,err=pcall(function()
      G.origin(); G.setShader(); G.setBlendMode("alpha"); G.setScissor()
      drawModern(menu,kind,viewport)
    end)
    G.setScissor(); G.setShader(); G.setBlendMode("alpha"); G.setColor(1,1,1,1); G.pop()
    if ok then mod._kantoInMotionGen3TrainerCardLastDrawError=nil
    else mod._kantoInMotionGen3TrainerCardLastDrawError=tostring(err) end
  end,11210)

  mod.exports=mod.exports or {}; mod.exports.gen3ModernTrainerCardUi=true
  return true
end
