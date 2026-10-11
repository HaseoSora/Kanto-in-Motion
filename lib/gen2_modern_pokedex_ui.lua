-- Kanto in Motion v1.7.3 - Gen 2 Modern Pokedex UI v37 -- responsive mobile list
--
-- The Pokédex data model and presentation conversion below are the exact
-- Gen2 Clean UI 0.4.1 adapter/presenter supplied by the user, vendored into
-- KIM so the Clean UI Pokédex layout/features do not depend on load order.
-- KIM only owns final-window Modern UI styling and HD Pokémon art.
return function(mod)
  local G=love.graphics
  local Style=mod._kantoInMotionGen2Ui
  local imageCache={}
  local vanillaCutoutCache=setmetatable({}, {__mode="k"})
  local okDex,PokedexMenu=pcall(require,"src.ui.gen2.PokedexMenu")
  local okChrome,Chrome=pcall(require,"src.ui.gen2.Chrome")
  local okGbcPalette,GbcPalette=pcall(require,"src.render.GbcPalette")
  if not (okDex and type(PokedexMenu)=="table") then return false end
  if PokedexMenu.__kimModernPokedexV5 then return true end

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
    local f=fittedFont(basePx,value,w)
    return text(value,f,x,y,w,align,c)
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
  -- Native Gen 2 front pictures are opaque four-shade images. In the cartridge
  -- renderer, shade 0 is the surrounding paper/background, not part of the mon.
  -- Modern UI draws the image outside that native tile box, so we need alpha.
  --
  -- Do NOT simply key every white pixel transparent: white is also legitimate
  -- artwork (eyes, mouths, bellies, etc.). Instead, find the dominant colour on
  -- the image border and flood-fill only that colour when it is connected to an
  -- outer edge. Enclosed regions of the same colour remain opaque. This removes
  -- Unown's white rectangle and Victreebel's outside paper without punching
  -- holes through legitimate white details inside the sprite.
  local function imageDataFor(img)
    if not img then return nil end
    if type(img.newImageData)=="function" then
      local ok,data=pcall(img.newImageData,img)
      if ok and data then return data end
    end
    if not (G and type(G.newCanvas)=="function" and type(img.getDimensions)=="function") then return nil end
    local okSize,iw,ih=pcall(img.getDimensions,img)
    if not okSize or not iw or not ih or iw<1 or ih<1 then return nil end
    local okCanvas,canvas=pcall(G.newCanvas,iw,ih,{dpiscale=1})
    if not okCanvas or not canvas then okCanvas,canvas=pcall(G.newCanvas,iw,ih) end
    if not okCanvas or not canvas then return nil end
    local previous=type(G.getCanvas)=="function" and G.getCanvas() or nil
    local pushed=pcall(G.push,"all")
    if not pushed then pcall(G.push) end
    local okDraw=pcall(function()
      G.setCanvas(canvas)
      if G.origin then G.origin() end
      G.clear(0,0,0,0)
      if G.setShader then G.setShader() end
      if G.setBlendMode then G.setBlendMode("alpha") end
      G.setColor(1,1,1,1)
      G.draw(img,0,0)
    end)
    if previous then pcall(G.setCanvas,previous) else pcall(G.setCanvas) end
    pcall(G.pop)
    if not okDraw or type(canvas.newImageData)~="function" then return nil end
    local okRead,data=pcall(canvas.newImageData,canvas)
    return okRead and data or nil
  end

  local function nativeSpriteCutout(img)
    if not img then return nil end
    local cached=vanillaCutoutCache[img]
    if cached~=nil then return cached or img end
    local data=imageDataFor(img)
    if not data or type(data.getDimensions)~="function" or type(data.getPixel)~="function"
        or type(data.setPixel)~="function" then
      vanillaCutoutCache[img]=false
      return img
    end
    local w,h=data:getDimensions()
    if not w or not h or w<1 or h<1 then vanillaCutoutCache[img]=false; return img end

    local function byte(v)
      v=tonumber(v) or 0
      if v<=1.000001 then v=v*255 end
      return math.max(0,math.min(255,math.floor(v+.5)))
    end
    local function pixelKey(x,y)
      local r,g,b,a=data:getPixel(x,y)
      if byte(a)<=0 then return nil end
      return byte(r)..":"..byte(g)..":"..byte(b)
    end

    -- Use the most common opaque border colour rather than hard-coding white.
    -- The extracted Gen 2 sheets normally make this 255:255:255, but deriving
    -- it keeps the cleanup correct if another ROM/profile uses a different
    -- shade-0 source colour.
    local counts={}
    local function countAt(x,y)
      local k=pixelKey(x,y)
      if k then counts[k]=(counts[k] or 0)+1 end
    end
    for x=0,w-1 do countAt(x,0); if h>1 then countAt(x,h-1) end end
    for y=1,h-2 do countAt(0,y); if w>1 then countAt(w-1,y) end end
    local bgKey,bgCount=nil,-1
    for k,n in pairs(counts) do if n>bgCount then bgKey,bgCount=k,n end end
    if not bgKey then vanillaCutoutCache[img]=false; return img end

    local visited={}
    local qx,qy={},{}
    local head,tail=1,0
    local function push(x,y)
      if x<0 or y<0 or x>=w or y>=h then return end
      local idx=y*w+x+1
      if visited[idx] or pixelKey(x,y)~=bgKey then return end
      visited[idx]=true; tail=tail+1; qx[tail]=x; qy[tail]=y
    end
    for x=0,w-1 do push(x,0); if h>1 then push(x,h-1) end end
    for y=1,h-2 do push(0,y); if w>1 then push(w-1,y) end end
    while head<=tail do
      local x,y=qx[head],qy[head]; head=head+1
      local r,g,b=data:getPixel(x,y)
      data:setPixel(x,y,r,g,b,0)
      -- Four-connected flood fill is intentional: it cannot leak diagonally
      -- through a one-pixel outline corner into enclosed white artwork.
      push(x-1,y); push(x+1,y); push(x,y-1); push(x,y+1)
    end

    local ok,newImg=pcall(G.newImage,data)
    if not ok or not newImg then vanillaCutoutCache[img]=false; return img end
    if newImg.setFilter then pcall(newImg.setFilter,newImg,"nearest","nearest") end
    vanillaCutoutCache[img]=newImg
    return newImg
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
    local art=current.art or {}
    local usingVanilla=source=="vanilla"
    local img=usingVanilla and loadImage(art.sprite) or hdSprite(current.species)
    if not img then
      img=loadImage(art.sprite)
      usingVanilla=true
    end
    if not img then return end
    -- Do not alpha-key ordinary native Gen 2 front pictures. Their shade-0
    -- (white) pixels are used both for the surrounding paper AND for real
    -- Pokemon artwork, and some legitimate white regions are connected to the
    -- outer paper through openings in the sprite outline (for example Gengar's
    -- teeth and parts of Goldeen's tail). Any automatic edge flood-fill can
    -- therefore erase valid pixels. Preserve the source image losslessly until
    -- KIM has explicit-alpha vanilla sprite assets.
    --
    -- Unown is the one confirmed-safe exception from the current set: its
    -- exterior white box is removable with the conservative edge flood-fill
    -- without damaging the glyph itself.
    local speciesId=tostring(current.species or art.species or ""):upper()
    if usingVanilla and (speciesId=="UNOWN" or tonumber(speciesId)==201) then
      img=nativeSpriteCutout(img)
    end
    local iw,ih=img:getDimensions(); local fit=math.min(w/iw,h/ih)
    local function body()
      color({1,1,1,1})
      G.draw(img,x+(w-iw*fit)/2,y+h-ih*fit,0,fit,fit)
    end

    -- Gen 2's extracted front pictures are four-shade source art. The native
    -- Pokédex applies the selected species' GBC palette while drawing them;
    -- Modern UI used to draw the raw sheet directly, which left VANILLA
    -- previews black-and-white. Reuse the palette snapshot already supplied by
    -- the Clean UI adapter so VANILLA matches the game's own colour rendering.
    -- GbcPalette.with also respects the player's GEN 2 / DMG / CLASSIC colour
    -- mode, so deliberately monochrome display modes remain native-correct.
    local palette=usingVanilla and art.palette or nil
    if palette and okGbcPalette and GbcPalette and type(GbcPalette.with)=="function" then
      return GbcPalette.with(palette,body)
    end
    return body()
  end
  local function splitDexLabel(row)
    local label=tostring(row and row.label or "-----")
    local num,name=label:match("^%s*(%d+)%s+(.+)$")
    if num then return num,name end
    return "",label
  end

  local function drawList(prepared,x,y,w,h,c,big,body,small,scale,portrait)
    local m=prepared.model
    local source=prepared.sourceModel or {}
    local rows=m.rows or {}
    local selected=tonumber(m.selected) or 1
    local scroll=tonumber(m.scroll) or 0
    local footerH=small:getHeight()+14*scale
    local desc=type(m.description)=="table"
      and table.concat(m.description,"  ")
      or (m.description or "UP/DOWN SPECIES   A DATA   SELECT OPTIONS   B BACK")

    if portrait then
      -- Phone portrait uses a stacked layout: the species list gets the full
      -- width and the selected-mon preview lives underneath it. This avoids
      -- forcing NO./NAME/STATUS, the preview, and totals into two tiny columns.
      local headerH=big:getHeight()+small:getHeight()+18*scale
      fittedText(m.title or "POKéDEX",big:getHeight(),x,y,w*.58,"left",c.text)
      local mode=(source.sortMode and ("MODE: "..source.sortMode.."  ·  001–251") or "001–251")
      fittedText(mode,small:getHeight(),x,y+big:getHeight()+4*scale,w,"left",c.muted)

      local headingY=y+headerH
      local scrollW=18*scale
      local usableW=w-scrollW-8*scale
      local numW=usableW*.16
      local statusW=usableW*.24
      local nameW=usableW-numW-statusW
      fittedText("NO.",small:getHeight(),x,headingY,numW,"left",c.accent)
      fittedText("NAME",small:getHeight(),x+numW,headingY,nameW,"left",c.accent)
      fittedText("STATUS",small:getHeight(),x+numW+nameW,headingY,statusW,"right",c.accent)

      local listTop=headingY+small:getHeight()+7*scale
      local previewH=math.max(210*scale,h*.27)
      local previewY=y+h-footerH-previewH
      local availableH=math.max(1,previewY-listTop-12*scale)
      local visible=math.max(5,math.min(7,math.floor(availableH/math.max(body:getHeight()*1.45,42*scale))))
      local rowH=availableH/visible
      for slot=1,visible do
        local i=scroll+slot
        local row=rows[i]
        if row then
          local yy=listTop+(slot-1)*rowH
          local sel=i==selected
          if sel then
            color(c.selected); G.rectangle("fill",x,yy,usableW,rowH-3*scale,6*scale,6*scale)
          end
          local num,name=splitDexLabel(row)
          local ny=yy+math.max(1*scale,(rowH-body:getHeight())*.48)
          fittedText(num,body:getHeight(),x+8*scale,ny,numW-12*scale,"left",sel and c.text or c.muted)
          fittedText(name,body:getHeight(),x+numW,ny,nameW-10*scale,"left",sel and c.text or c.muted)
          fittedText(row.right or "",small:getHeight(),x+numW+nameW,yy+math.max(1*scale,(rowH-small:getHeight())*.5),statusW-5*scale,"right",sel and c.text or c.muted)
        end
      end
      color(c.raised); G.rectangle("fill",x+usableW+5*scale,listTop,7*scale,availableH,4*scale,4*scale)
      local total=math.max(1,#rows)
      local thumbH=math.max(20*scale,availableH*math.min(1,visible/total))
      local ratio=total>1 and ((selected-1)/(total-1)) or 0
      color(c.accent); G.rectangle("fill",x+usableW+5*scale,listTop+(availableH-thumbH)*ratio,7*scale,thumbH,4*scale,4*scale)

      panel(x,previewY,w,previewH,c,.60)
      local cur=source.current or {}
      local spriteW=w*.31
      drawSpriteFor(prepared,x+8*scale,previewY+10*scale,spriteW-12*scale,previewH-20*scale)
      local infoX=x+spriteW+8*scale
      local infoW=w*.39
      local infoY=previewY+14*scale
      fittedText(cur.name or "-----",body:getHeight()*1.08,infoX,infoY,infoW,"left",c.text)
      infoY=infoY+body:getHeight()+5*scale
      fittedText(cur.dex and ("No. "..("%03d"):format(cur.dex)) or "No. ---",small:getHeight(),infoX,infoY,infoW,"left",c.muted)
      infoY=infoY+small:getHeight()+4*scale
      fittedText(table.concat(cur.types or {}," / "),small:getHeight(),infoX,infoY,infoW,"left",c.accent)
      infoY=infoY+small:getHeight()+5*scale
      fittedText(cur.caught and "OWNED" or cur.seen and "SEEN" or "UNSEEN",body:getHeight(),infoX,infoY,infoW,"left",c.text)

      local totals=source.totals or {}
      local countX=x+w*.73
      local countW=w*.24
      local countH=math.min(previewH-20*scale,body:getHeight()*2+28*scale)
      panel(countX,previewY+(previewH-countH)*.5,countW,countH,c,.70)
      local cy=previewY+(previewH-countH)*.5+8*scale
      fittedText(("SEEN %d"):format(totals.seen or 0),small:getHeight(),countX+8*scale,cy,countW-16*scale,"left",c.muted)
      cy=cy+small:getHeight()+7*scale
      fittedText(("OWNED %d"):format(totals.caught or 0),small:getHeight(),countX+8*scale,cy,countW-16*scale,"left",c.text)

      fittedText(desc,16*scale,x,y+h-small:getHeight(),w,"left",c.muted)
      return
    end

    -- Landscape / desktop: keep the two-column presentation but measure each
    -- column separately so long labels can never spill into the preview rail.
    local listW=w*.59
    local scrollW=22*scale
    local gap=18*scale
    local rightX=x+listW+scrollW+gap
    local rightW=w-listW-scrollW-gap
    local headerH=math.max(big:getHeight(),small:getHeight())+14*scale
    fittedText(m.title or "POKéDEX",big:getHeight(),x,y,listW*.46,"left",c.text)
    fittedText((source.sortMode and ("MODE: "..source.sortMode.."  ·  001–251") or "001–251"),small:getHeight(),x+listW*.48,y+5*scale,listW*.48,"right",c.muted)

    local columnY=y+headerH
    local usableW=listW-8*scale
    local numW=usableW*.15
    local statusW=usableW*.22
    local nameW=usableW-numW-statusW
    fittedText("NO.",small:getHeight(),x,columnY,numW,"left",c.accent)
    fittedText("NAME",small:getHeight(),x+numW,columnY,nameW,"left",c.accent)
    fittedText("STATUS",small:getHeight(),x+numW+nameW,columnY,statusW,"right",c.accent)

    local listTop=columnY+small:getHeight()+8*scale
    local listBottom=y+h-footerH
    local availableH=math.max(1,listBottom-listTop)
    local den=Style and Style.density and Style.density() or 1
    local visible=math.max(5,math.min(9,math.floor(7/den+.5)))
    local rowH=availableH/visible
    for slot=1,visible do
      local i=scroll+slot
      local row=rows[i]
      if row then
        local yy=listTop+(slot-1)*rowH
        local sel=i==selected
        if sel then color(c.selected); G.rectangle("fill",x,yy,usableW,rowH-4*scale,6*scale,6*scale) end
        local num,name=splitDexLabel(row)
        local ty=yy+math.max(1*scale,(rowH-body:getHeight())*.48)
        fittedText(num,body:getHeight(),x+8*scale,ty,numW-12*scale,"left",sel and c.text or c.muted)
        fittedText(name,body:getHeight(),x+numW,ty,nameW-10*scale,"left",sel and c.text or c.muted)
        fittedText(row.right or "",small:getHeight(),x+numW+nameW,yy+math.max(1*scale,(rowH-small:getHeight())*.50),statusW-4*scale,"right",sel and c.text or c.muted)
      end
    end

    color(c.raised); G.rectangle("fill",x+listW+6*scale,listTop,8*scale,availableH,4*scale,4*scale)
    local total=math.max(1,#rows)
    local thumbH=math.max(24*scale,availableH*math.min(1,visible/total))
    local ratio=total>1 and ((selected-1)/(total-1)) or 0
    color(c.accent); G.rectangle("fill",x+listW+6*scale,listTop+(availableH-thumbH)*ratio,8*scale,thumbH,4*scale,4*scale)

    local progressH=small:getHeight()*2+30*scale
    local progressY=y+h-footerH-progressH
    local previewTop=y+headerH+4*scale
    local previewBottom=progressY-10*scale
    local previewH=math.max(100*scale,previewBottom-previewTop)
    local spriteH=math.min(150*scale,previewH*.46)
    drawSpriteFor(prepared,rightX+rightW*.13,previewTop,rightW*.74,spriteH)
    local cur=source.current or {}
    local infoY=previewTop+spriteH+5*scale
    fittedText(cur.name or "-----",body:getHeight()*1.15,rightX,infoY,rightW,"center",c.text)
    infoY=infoY+body:getHeight()+4*scale
    fittedText(cur.dex and ("No. "..("%03d"):format(cur.dex)) or "No. ---",small:getHeight(),rightX,infoY,rightW,"center",c.muted)
    infoY=infoY+small:getHeight()+3*scale
    fittedText(table.concat(cur.types or {}," / "),small:getHeight(),rightX,infoY,rightW,"center",c.accent)
    infoY=infoY+small:getHeight()+3*scale
    fittedText(cur.caught and "OWNED" or cur.seen and "SEEN" or "UNSEEN",body:getHeight(),rightX,infoY,rightW,"center",c.text)

    local totals=source.totals or {}
    panel(rightX,progressY,rightW,progressH,c,.72)
    local py=progressY+7*scale
    fittedText(("SEEN   %d"):format(totals.seen or 0),small:getHeight(),rightX+12*scale,py,rightW-24*scale,"left",c.muted)
    py=py+small:getHeight()+5*scale
    fittedText(("OWNED  %d"):format(totals.caught or 0),small:getHeight(),rightX+12*scale,py,rightW-24*scale,"left",c.text)
    fittedText(desc,16*scale,x,y+h-small:getHeight(),w,"left",c.muted)
  end

  local function drawEntry(prepared,x,y,w,h,c,big,body,small,scale)
    local m=prepared.model
    local source=prepared.sourceModel or {}
    local cur=source.current or {}

    -- Gen 2's native entry screen has exactly four actions: PAGE, AREA,
    -- CRY and PRNT.  The vendored Clean UI document advertised EVO/MOVES
    -- placeholders that have no backing Gen 2 state or data, so do not expose
    -- dead tabs in KIM.  Keep the Modern UI aligned with the actual game.
    local tabs={"PAGE","AREA","CRY","PRINT"}
    local active=tonumber(source.entry and source.entry.selectedAction) or 1
    active=math.max(1,math.min(#tabs,active))

    local tabsWidth=w*.48
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

    fittedText("LEFT/RIGHT ACTION   A SELECT   B BACK",18*scale,
      x,y+h-small:getHeight(),w,"left",c.muted)
  end

  local areaCanvas
  local function drawAreaMap(state,prepared,x,y,w,h,c,big,body,small,scale)
    if type(state)~="table" or type(state.drawArea)~="function" then
      return false
    end
    if not areaCanvas then
      local ok,canvas=pcall(G.newCanvas,160,144)
      if not ok or not canvas then return false end
      areaCanvas=canvas
      if areaCanvas.setFilter then pcall(areaCanvas.setFilter,areaCanvas,"nearest","nearest") end
    end
    local previous=type(G.getCanvas)=="function" and G.getCanvas() or nil
    local pushed=pcall(G.push,"all")
    if not pushed then pcall(G.push) end
    local ok=pcall(function()
      G.setCanvas(areaCanvas)
      if G.origin then G.origin() end
      G.clear(0,0,0,0)
      G.setColor(1,1,1,1)
      state:drawArea()
    end)
    if previous then pcall(G.setCanvas,previous) else pcall(G.setCanvas) end
    pcall(G.pop)
    if not ok then return false end

    local source=prepared and prepared.sourceModel or {}
    local area=source.area or {}
    local title=(area.name or (source.current and source.current.name) or "POKéMON").." / HABITAT"
    text(title,big,x,y,w,"left",c.text)
    local footerH=small:getHeight()+14*scale
    local mapTop=y+big:getHeight()+14*scale
    local mapH=math.max(1,h-(mapTop-y)-footerH-8*scale)
    panel(x,mapTop,w,mapH,c,.60)
    local inset=14*scale
    local availW,availH=w-inset*2,mapH-inset*2
    local fit=math.min(availW/160,availH/144)
    local dw,dh=160*fit,144*fit
    color({1,1,1,1})
    G.draw(areaCanvas,x+(w-dw)/2,mapTop+(mapH-dh)/2,0,fit,fit)
    fittedText("LEFT/RIGHT REGION   A/B RETURN",18*scale,
      x,y+h-small:getHeight(),w,"left",c.muted)
    return true
  end

  local function drawMenu(prepared,x,y,w,h,c,big,body,small,scale)
    local m=prepared.model; text(m.title or "POKéDEX",big,x,y,w,"left",c.text)
    local rows=m.rows or {}; local selected=tonumber(m.selected) or 1
    local rh=math.max(50,body:getHeight()+22)
    for i,row in ipairs(rows) do
      if i>9 then break end
      local yy=y+58+(i-1)*rh
      local inset=2*scale
      local barY=yy+inset
      local barH=math.max(1,rh-inset*2)
      if i==selected then color(c.selected); G.rectangle("fill",x,barY,w,barH,6,6) end
      text(row.label or row.id or "—",body,x+18,barY+math.max(0,(barH-body:getHeight())*.5),w*.68,"left",i==selected and c.text or c.muted)
      text(row.right or "",small,x+w*.70,barY+math.max(0,(barH-small:getHeight())*.5),w*.26,"right",i==selected and c.text or c.muted)
    end
    local desc=m.description; if type(desc)=="table" then desc=table.concat(desc,"  ") end
    fittedText(desc or "A CHOOSE   B BACK",19*scale,x,y+h-24,w,"left",c.muted)
  end
  local function drawDex(state)
    local prepared=prepare(state); if not prepared then return end
    local c=theme(); local sx,sy,sw,sh=playfield()
    local uiScale=Style and Style.uiScale and Style.uiScale(sw,sh) or 1
    local layout=Style and Style.layoutStyle and Style.layoutStyle() or "floating"
    local portrait=sh>sw*1.15
    local pw,ph
    if portrait then
      pw=sw*.96; ph=sh*.88
    else
      pw=sw>=1000 and math.min(1480,sw*.94) or sw*.96
      ph=sh>=700 and math.min(820,sh*.90) or sh*.90
    end
    if layout=="full" then pw=sw*.94; ph=sh*.92 end

    -- Cap the authored scale to what the ACTUAL panel can contain. Mobile
    -- AUTO/UI scale can otherwise be much larger than the available portrait
    -- or landscape height, which was the source of the overlapping headers,
    -- rows, preview text and Seen/Owned box.
    local fitScale
    if portrait then fitScale=math.min(pw/760,ph/1180)
    else fitScale=math.min(pw/1240,ph/780) end
    local scale=math.max(.58,math.min(uiScale,fitScale))

    local x=sx+(sw-pw)/2; local y=sy+(sh-ph)/2; panel(x,y,pw,ph,c,.95)
    local bigBase=portrait and 30 or 32
    local bodyBase=portrait and 22 or 23
    local smallBase=portrait and 16 or 17
    local big,body,small=font(bigBase*scale),font(bodyBase*scale),font(smallBase*scale)
    local pad=(portrait and 18 or 22)*scale
    local vx,vy=x+pad,y+pad; local vw,vh=pw-pad*2,ph-pad*2
    local view=tostring(prepared.model.sourceView or prepared.sourceModel and prepared.sourceModel.view or "list")
    if view=="list" then drawList(prepared,vx,vy,vw,vh,c,big,body,small,scale,portrait)
    elseif view=="entry" then drawEntry(prepared,vx,vy,vw,vh,c,big,body,small,scale)
    elseif view=="area" and drawAreaMap(state,prepared,vx,vy,vw,vh,c,big,body,small,scale) then
      -- Native Gen 2 nest map rendered inside the Modern UI frame.
    else drawMenu(prepared,vx,vy,vw,vh,c,big,body,small,scale) end
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
  PokedexMenu.__kimModernPokedexV5=true
  mod.exports.gen2ModernPokedex={apiVersion=5,source="Gen2 Clean UI 0.4.1 vendored adapter/presenter + native Gen2 actions/map"}
  return true
end
