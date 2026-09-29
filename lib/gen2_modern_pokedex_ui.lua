-- Kanto in Motion v1.5.3 - Gen 2 Modern Pokedex UI v28
--
-- The Pokédex data model and presentation conversion below are the exact
-- Gen2 Clean UI 0.4.1 adapter/presenter supplied by the user, vendored into
-- KIM so the Clean UI Pokédex layout/features do not depend on load order.
-- KIM only owns final-window Modern UI styling and HD Pokémon art.
return function(mod)
  local G=love.graphics
  local Style=mod._kantoInMotionGen2Ui
  local imageCache={}
  local okDex,PokedexMenu=pcall(require,"src.ui.gen2.PokedexMenu")
  local okChrome,Chrome=pcall(require,"src.ui.gen2.Chrome")
  if not (okDex and type(PokedexMenu)=="table") then return false end
  if PokedexMenu.__kimModernPokedexV4 then return true end

  local FONT_PATH="assets/fonts/plainpixel/PlainPixel-Regular.ttf"
  local fonts={}
  local FALLBACK={
    surface={.075,.105,.17,.96},raised={.12,.17,.27,.94},selected={.18,.43,.72,.96},
    accent={.48,.86,1,1},frame={.48,.86,1,1},frameShadow={.01,.02,.04,.42},
    text={.96,.98,1,1},muted={.74,.82,.92,1},divider={.38,.5,.68,.94},
  }

  local vendorCache={}
  local function loadVendor(name)
    if vendorCache[name] then return vendorCache[name] end
    local rel="lib/gen2_clean_ui_pokedex/"..name:gsub("%.","/")..".lua"
    local source,readErr=mod:read(rel)
    if not source then error(readErr or ("cannot read "..rel),0) end
    local chunk,loadErr=load(source,"@"..tostring(mod.path).."/"..rel)
    if not chunk then error(loadErr or ("cannot compile "..rel),0) end
    local factory=chunk()
    if type(factory)~="function" then error("invalid Clean UI vendor module "..name,0) end
    local value=factory({load=loadVendor})
    vendorCache[name]=value
    return value
  end

  local okPresenter,Presenter=pcall(loadVendor,"presenters.pokedex")
  if not okPresenter or type(Presenter)~="table" or type(Presenter.prepare)~="function" then
    mod.log:error("Gen2 Clean UI Pokedex vendor failed: %s",tostring(Presenter))
    return false
  end

  local function opt(k,d)
    if not(mod.options and mod.options.get) then return d end
    local ok,v=pcall(mod.options.get,mod.options,k)
    if not ok or v == nil then return d end
    return v
  end
  local function enabled()
    return Style and Style.presenterEnabled and Style.presenterEnabled("pokemon")
      or opt("gen2IntegratedModernUi",true)~=false
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
  local function playfield()
    local ww,wh=G.getDimensions()
    if okChrome and Chrome and type(Chrome.playfieldRect)=="function" then
      local ok,x,y,w,h=pcall(Chrome.playfieldRect,ww,wh)
      if ok and w and h and w>0 and h>0 then return x,y,w,h end
    end
    return 0,0,ww,wh
  end
  local function panel(x,y,w,h,c,alpha)
    if Style and Style.panel then return Style.panel(x,y,w,h,c,alpha) end
    local r=math.max(8,math.min(w,h)*.018)
    color(c.frameShadow or {0,0,0,.4},.18); G.rectangle("fill",x+2,y+3,w,h,r,r)
    color(c.surface,math.min(1,(c.surface[4] or 1)*(alpha or .95))); G.rectangle("fill",x,y,w,h,r,r)
    color(c.frame or c.accent); G.setLineWidth(math.max(2,math.min(w,h)*.0045)); G.rectangle("line",x,y,w,h,r,r)
  end
  local function loadImage(path)
    if not path or path=="" then return nil end
    if imageCache[path]~=nil then return imageCache[path] or nil end
    local ok,img=false,nil
    if mod.assets and type(mod.assets.image)=="function" then
      ok,img=pcall(mod.assets.image,mod.assets,path)
    end
    if (not ok or not img) and G and type(G.newImage)=="function" then
      ok,img=pcall(G.newImage,path)
    end
    if ok and img then
      if img.setFilter then pcall(img.setFilter,img,"nearest","nearest") end
      imageCache[path]=img; return img
    end
    imageCache[path]=false; return nil
  end
  local function hdSprite(species)
    if not species or not mod.exports or type(mod.exports.getSprite)~="function" then return nil end
    local ok,img=pcall(mod.exports.getSprite,species,{generation="hd"}); return ok and img or nil
  end
  local function prepare(state)
    local oldId=rawget(state,"screenId")
    rawset(state,"screenId","Gen2PokedexMenu")
    local ok,result=pcall(Presenter.prepare,nil,state,{game=state.game})
    rawset(state,"screenId",oldId)
    if not ok or type(result)~="table" or type(result.model)~="table" then return nil end
    return result
  end
  local function selectedSource(prepared)
    local source=prepared and prepared.sourceModel
    return source and source.current or nil
  end
  local function drawSpriteFor(prepared,x,y,w,h)
    local current=selectedSource(prepared)
    if not current then return end
    local source=tostring(opt("gen2MenuSpriteSource","kim"))
    local img=source=="vanilla" and loadImage(current.art and current.art.sprite) or hdSprite(current.species)
    if not img then img=loadImage(current.art and current.art.sprite) end
    if not img then return end
    local iw,ih=img:getDimensions(); local fit=math.min(w/iw,h/ih)
    color({1,1,1,1}); G.draw(img,x+(w-iw*fit)/2,y+h-ih*fit,0,fit,fit)
  end
  local function drawList(prepared,x,y,w,h,c,big,body,small,scale)
    local m=prepared.model
    local source=prepared.sourceModel or {}
    local listW=w*.57
    local scrollW=24*scale
    local gap=16*scale
    local rightX=x+listW+scrollW+gap
    local rightW=w-listW-scrollW-gap

    -- Header gets its own measured band so the large title can never collide
    -- with the NO./NAME/STATUS heading underneath it.
    local headerH=math.max(big:getHeight(),small:getHeight())+14*scale
    text(m.title or "POKéDEX",big,x,y,listW*.50,"left",c.text)
    text((source.sortMode and ("MODE: "..source.sortMode.."  ·  001–251")
      or "001–251"),small,x+listW*.50,y+6*scale,listW*.46,"right",c.muted)

    local columnY=y+headerH
    text("NO.   NAME                    STATUS",small,x,columnY,listW-8*scale,
      "left",c.accent)

    local listTop=columnY+small:getHeight()+10*scale
    local footerH=small:getHeight()+14*scale
    local listBottom=y+h-footerH
    local availableH=math.max(1,listBottom-listTop)
    local rows=m.rows or {}
    local selected=tonumber(m.selected) or 1
    local scroll=tonumber(m.scroll) or 0
    local den=Style and Style.density and Style.density() or 1
    local visible=math.max(5,math.min(9,math.floor(7/den+.5)))
    local rowH=availableH/visible

    for slot=1,visible do
      local i=scroll+slot
      local row=rows[i]
      if row then
        local yy=listTop+(slot-1)*rowH
        local sel=i==selected
        if sel then
          color(c.selected)
          G.rectangle("fill",x,yy,listW-8*scale,rowH-4*scale,6*scale,6*scale)
        end
        local textY=yy+math.max(2*scale,(rowH-body:getHeight())*.45)
        text(row.label or "-----",body,x+12*scale,textY,listW*.72,"left",
          sel and c.text or c.muted)
        text(row.right or "",small,x+listW*.72,
          yy+math.max(2*scale,(rowH-small:getHeight())*.48),
          listW*.23,"right",sel and c.text or c.muted)
      end
    end

    color(c.raised)
    G.rectangle("fill",x+listW+6*scale,listTop,8*scale,availableH,4*scale,4*scale)
    local total=math.max(1,#rows)
    local thumbH=math.max(24*scale,availableH*math.min(1,visible/total))
    local maxTravel=math.max(0,availableH-thumbH)
    local ratio=total>1 and ((selected-1)/(total-1)) or 0
    color(c.accent)
    G.rectangle("fill",x+listW+6*scale,listTop+maxTravel*ratio,
      8*scale,thumbH,4*scale,4*scale)

    -- Right preview rail also uses measured positions instead of fixed pixel
    -- constants, so larger fonts remain readable without stacking.
    local progressH=body:getHeight()*2+28*scale
    local progressY=y+h-footerH-progressH
    local previewTop=y+headerH+4*scale
    local previewBottom=progressY-12*scale
    local previewH=math.max(120*scale,previewBottom-previewTop)
    local spriteH=math.min(175*scale,previewH*.48)

    drawSpriteFor(prepared,rightX+rightW*.14,previewTop,rightW*.72,spriteH)

    local cur=source.current or {}
    local infoY=previewTop+spriteH+8*scale
    text(cur.name or "-----",big,rightX,infoY,rightW,"center",c.text)
    infoY=infoY+big:getHeight()+4*scale
    text(cur.dex and ("No. "..("%03d"):format(cur.dex)) or "No. ---",
      small,rightX,infoY,rightW,"center",c.muted)
    infoY=infoY+small:getHeight()+3*scale
    text(table.concat(cur.types or {}," / "),small,rightX,infoY,rightW,
      "center",c.accent)
    infoY=infoY+small:getHeight()+3*scale
    local status=cur.caught and "OWNED" or cur.seen and "SEEN" or "UNSEEN"
    text(status,body,rightX,infoY,rightW,"center",c.text)

    local totals=source.totals or {}
    panel(rightX,progressY,rightW,progressH,c,.72)
    local py=progressY+10*scale
    text(("SEEN   %d"):format(totals.seen or 0),body,
      rightX+16*scale,py,rightW-32*scale,"left",c.muted)
    py=py+body:getHeight()+4*scale
    text(("OWNED  %d"):format(totals.caught or 0),body,
      rightX+16*scale,py,rightW-32*scale,"left",c.text)

    local desc=type(m.description)=="table"
      and table.concat(m.description,"  ")
      or (m.description or "UP/DOWN SPECIES   A DATA   SELECT OPTIONS   B BACK")
    text(desc,small,x,y+h-small:getHeight(),w,"left",c.muted)
  end

  local function drawEntry(prepared,x,y,w,h,c,big,body,small,scale)
    local m=prepared.model
    local source=prepared.sourceModel or {}
    local cur=source.current or {}

    -- Use the exact tab metadata produced by the vendored Gen2 Clean UI
    -- presenter. This fixes the highlight selecting the wrong tab.
    local tabSpec=m.document and m.document.header
      and m.document.header.right or nil
    local tabs=tabSpec and tabSpec.values
      or {"INFO","AREA","EVO","MOVES","CRY","PRINT"}
    local active=tonumber(tabSpec and tabSpec.active) or 1

    local tabsWidth=w*.58
    local titleWidth=w-tabsWidth-12*scale
    local tabH=math.max(40*scale,small:getHeight()+12*scale)
    local headerH=math.max(big:getHeight(),tabH)+10*scale

    text(m.title or ((cur.name or "ENTRY").." / POKéDEX"),
      big,x,y,titleWidth,"left",c.text)

    local tabX=x+w-tabsWidth
    local tabW=tabsWidth/math.max(1,#tabs)
    for i,label in ipairs(tabs) do
      local tx=tabX+(i-1)*tabW
      if i==active then
        color(c.selected)
        G.rectangle("fill",tx,y,tabW-4*scale,tabH,5*scale,5*scale)
      end
      text(label,small,tx,y+(tabH-small:getHeight())*.48,
        tabW-4*scale,"center",i==active and c.text or c.muted)
    end

    local footerH=small:getHeight()+14*scale
    local contentBottom=y+h-footerH
    local topY=y+headerH
    local available=contentBottom-topY
    local topH=math.max(220*scale,available*.48)
    topH=math.min(topH,available*.56)
    local leftW=w*.43
    local panelGap=18*scale

    panel(x,topY,leftW,topH,c,.60)
    panel(x+leftW+panelGap,topY,w-leftW-panelGap,topH,c,.60)
    drawSpriteFor(prepared,x+28*scale,topY+18*scale,
      leftW-56*scale,topH-36*scale)

    local rx=x+leftW+panelGap+22*scale
    local rw=w-leftW-panelGap-44*scale
    local lineY=topY+18*scale
    text(cur.name or "ENTRY",big,rx,lineY,rw,"left",c.text)
    lineY=lineY+big:getHeight()+3*scale
    text(cur.kind or "POKéMON",body,rx,lineY,rw,"left",c.muted)
    lineY=lineY+body:getHeight()+3*scale
    text(cur.dex and ("No. "..("%03d"):format(cur.dex)) or "No. ---",
      body,rx,lineY,rw,"left",c.text)
    lineY=lineY+body:getHeight()+3*scale
    text(table.concat(cur.types or {}," / "),small,rx,lineY,rw,"left",c.accent)
    lineY=lineY+small:getHeight()+6*scale
    text("HEIGHT   "..tostring(cur.caught and cur.height or "?"),
      small,rx,lineY,rw,"left",c.muted)
    lineY=lineY+small:getHeight()+4*scale
    text("WEIGHT   "..tostring(cur.caught and cur.weight or "?"),
      small,rx,lineY,rw,"left",c.muted)

    local entryY=topY+topH+14*scale
    local entryH=math.max(1,contentBottom-entryY)
    panel(x,entryY,w,entryH,c,.68)

    local headingY=entryY+12*scale
    text("POKéDEX ENTRY",body,x+18*scale,headingY,w-36*scale,"left",c.accent)
    local descY=headingY+body:getHeight()+10*scale
    local lines=cur.pageLines or {}
    local desc=table.concat(lines," "):gsub("(%a)%- (%a)","%1%2")
    text(desc,body,x+28*scale,descY,w-56*scale,"left",c.text)

    text("LEFT/RIGHT PAGE   A SELECT   B BACK",small,
      x,y+h-small:getHeight(),w,"left",c.muted)
  end
  local function drawMenu(prepared,x,y,w,h,c,big,body,small)
    local m=prepared.model; text(m.title or "POKéDEX",big,x,y,w,"left",c.text)
    local rows=m.rows or {}; local selected=tonumber(m.selected) or 1
    local rh=math.max(50,body:getHeight()+22)
    for i,row in ipairs(rows) do
      if i>9 then break end
      local yy=y+58+(i-1)*rh
      if i==selected then color(c.selected); G.rectangle("fill",x,yy,w,rh-5,6,6) end
      text(row.label or row.id or "—",body,x+18,yy+11,w*.68,"left",i==selected and c.text or c.muted)
      text(row.right or "",small,x+w*.70,yy+14,w*.26,"right",i==selected and c.text or c.muted)
    end
    local desc=m.description; if type(desc)=="table" then desc=table.concat(desc,"  ") end
    text(desc or "A CHOOSE   B BACK",small,x,y+h-24,w,"left",c.muted)
  end
  local function drawDex(state)
    local prepared=prepare(state); if not prepared then return end
    local c=theme(); local sx,sy,sw,sh=playfield()
    local uiScale=Style and Style.uiScale and Style.uiScale(sw,sh) or 1
    local layout=Style and Style.layoutStyle and Style.layoutStyle() or "floating"
    local pw=sw>=1000 and math.min(1240*uiScale,sw*.82) or sw*.96
    local ph=sh>=700 and math.min(780*uiScale,sh*.88) or sh*.89
    local scale=uiScale
    if layout=="full" then pw=sw*.94; ph=sh*.92; scale=math.min(pw/1240,ph/780) end
    local x=sx+(sw-pw)/2; local y=sy+(sh-ph)/2; panel(x,y,pw,ph,c,.95)
    -- v14 keeps the text larger than the original implementation but backs
    -- off the v13 oversize tier; measured spacing now does the readability work.
    local big,body,small=font(34*scale),font(25*scale),font(19*scale)
    local pad=26*scale; local vx,vy=x+pad,y+pad; local vw,vh=pw-pad*2,ph-pad*2
    local view=tostring(prepared.model.sourceView or prepared.sourceModel and prepared.sourceModel.view or "list")
    if view=="list" then drawList(prepared,vx,vy,vw,vh,c,big,body,small,scale)
    elseif view=="entry" then drawEntry(prepared,vx,vy,vw,vh,c,big,body,small,scale)
    else drawMenu(prepared,vx,vy,vw,vh,c,big,body,small) end
  end

  local upstreamNew=PokedexMenu.new
  PokedexMenu.new=function(game,...)
    local self=upstreamNew(game,...); if enabled() and hideOriginal() then self.isOpaque=false end; return self
  end
  local upstreamUpdate=PokedexMenu.update
  PokedexMenu.update=function(self,...)
    self.isOpaque=not (enabled() and hideOriginal()); return upstreamUpdate(self,...)
  end
  local upstreamWide=PokedexMenu.drawsWidescreen
  PokedexMenu.drawsWidescreen=function(self)
    if enabled() then return false end
    return upstreamWide and upstreamWide(self) or true
  end
  local function isDex(s) return type(s)=="table" and getmetatable(s)==PokedexMenu end
  if mod.hooks and type(mod.hooks.wrap)=="function" then
    mod.hooks:wrap("screen.render_visible",function(nextFn,state)
      if enabled() and hideOriginal() and isDex(state) then return false end
      return nextFn(state)
    end,100000)
    mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
      local result={pcall(nextFn,game,viewport)}; local ok=table.remove(result,1)
      if not ok then error(result[1],0) end
      local top=game and game.stack and type(game.stack.top)=="function" and game.stack:top()
      if enabled() and isDex(top) then G.push("all"); G.origin(); pcall(drawDex,top); G.pop() end
      return unpack(result)
    end,100000)
  end
  PokedexMenu.__kimModernPokedexV4=true
  mod.exports.gen2ModernPokedex={apiVersion=4,source="Gen2 Clean UI 0.4.1 vendored adapter/presenter"}
  return true
end
