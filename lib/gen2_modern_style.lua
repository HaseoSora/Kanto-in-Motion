-- Kanto in Motion v1.5.3 - shared Gen 2 Modern UI style/settings bridge v1
--
-- Centralizes the Gen 1-style appearance controls used by the Gen 2 Modern
-- UI adapters.  Gameplay/input/state stay native; this module only resolves
-- presentation settings, fonts, opacity, framing and responsive scale.
return function(mod)
  local G = love.graphics
  local PLAIN_PIXEL = "assets/fonts/plainpixel/PlainPixel-Regular.ttf"
  local fontCache, imageCache = {}, {}

  local FALLBACK = {
    surface={.075,.105,.17,.96},raised={.12,.17,.27,.94},
    selected={.18,.43,.72,.96},accent={.48,.86,1,1},
    frame={.48,.86,1,1},frameShadow={.01,.02,.04,.42},
    text={.96,.98,1,1},muted={.74,.82,.92,1},divider={.38,.5,.68,.94},
  }

  local function clamp(v,a,b)
    v=tonumber(v) or a
    if v<a then return a end
    if v>b then return b end
    return v
  end

  local function opt(key, fallback)
    if not (mod.options and type(mod.options.get)=="function") then return fallback end
    local ok,value=pcall(mod.options.get,mod.options,key)
    if not ok or value == nil then return fallback end
    return value
  end

  local Style={}
  Style.opt=opt

  function Style.theme()
    local themes=mod._kantoInMotionGen2Themes
    local id=tostring(opt("gen2UiTheme","default"))
    return type(themes)=="table" and (themes[id] or themes.default) or FALLBACK
  end

  function Style.masterEnabled()
    return opt("gen2IntegratedModernUi",true)~=false
  end

  function Style.presenterEnabled(kind)
    if not Style.masterEnabled() then return false end
    kind=tostring(kind or "menu")
    if kind=="dialogue" then return opt("dialogueUi",true)~=false end
    if kind=="pokemon" then return opt("pokemonUi",true)~=false end
    if kind=="manager" then return opt("managerUi",true)~=false end
    if kind=="battle" then return opt("battleUiWip",true)~=false end
    return opt("menuUi",true)~=false
  end

  function Style.hideOriginal()
    return opt("hideOriginalUi",true)~=false
  end

  local function autoScalePercent(w,h,minimum,maximum,legacyCeiling,largeFactor)
    w,h=tonumber(w) or 640,tonumber(h) or 360
    local authored
    if h>w*1.2 then authored=w/400 else authored=math.min(w/640,h/360) end
    local legacy=(legacyCeiling or maximum)/100
    largeFactor=tonumber(largeFactor) or .5
    local ratio=math.max(math.min(authored,legacy),authored*largeFactor)
    return clamp(ratio*100,minimum,maximum)
  end

  -- Gen 2 layouts were authored much larger than the Gen 1 Modern UI.  Keep
  -- an internal neutral calibration so UI SCALE=100% has the cleaner Gen 1-
  -- like footprint; the exposed setting remains a true user multiplier.
  local GEN2_NEUTRAL_BASE=.78

  function Style.uiScale(w,h)
    local value=opt("uiScale","100")
    local pct
    if tostring(value):lower()=="auto" then
      pct=autoScalePercent(w,h,75,400,150,.5)
    else
      pct=clamp(value,75,400)
    end
    local scale=(pct/100)*GEN2_NEUTRAL_BASE
    if opt("minimalUi",false)==true then scale=scale*.90 end
    return scale,pct
  end

  function Style.fontScale(w,h)
    local value=opt("fontScale","100")
    local pixel=opt("pixelFont",false)==true
    if tostring(value):lower()=="auto" then
      local ui,pct=Style.uiScale(w,h)
      if pixel then
        return clamp(math.floor((pct/100)+.5),1,4),pct
      end
      return autoScalePercent(w,h,80,500,200,2/3)/100,pct
    end
    local pct=clamp(value,80,400)
    if pixel then return clamp(math.floor(pct/100+.5),1,4),pct end
    return pct/100,pct
  end

  function Style.dialogueScale()
    local value=tostring(opt("dialogueTextScale","inherit"))
    if value=="inherit" then return 1 end
    return clamp(value,100,200)/100
  end

  function Style.density()
    local value=tostring(opt("density","auto"))
    if value=="compact" then return .86 end
    if value=="comfortable" then return 1.12 end
    return 1
  end

  function Style.layoutStyle()
    local value=tostring(opt("layoutStyle","auto"))
    if value=="full" or value=="floating" then return value end
    return "floating"
  end

  function Style.panelOpacity(extra)
    local p=clamp(opt("panelOpacity",100),0,100)/100
    return clamp(p*(tonumber(extra) or 1),0,1)
  end

  function Style.foregroundOpacity(extra)
    local p=clamp(opt("foregroundOpacity",100),0,100)/100
    return clamp(p*(tonumber(extra) or 1),0,1)
  end

  function Style.color(c,alpha,foreground)
    c=c or {1,1,1,1}
    local a=alpha==nil and (c[4] or 1) or alpha
    if foreground then a=a*Style.foregroundOpacity(1) end
    G.setColor(c[1] or 1,c[2] or 1,c[3] or 1,clamp(a,0,1))
  end

  function Style.font(px)
    local ww,wh=G.getDimensions()
    local mult=Style.fontScale(ww,wh)
    px=math.max(8,math.floor((tonumber(px) or 12)*mult+.5))
    local pixel=opt("pixelFont",false)==true
    local key=(pixel and "pixel:" or "system:")..tostring(px)
    if fontCache[key] then return fontCache[key] end
    local ok,f
    if pixel then
      ok,f=pcall(G.newFont,PLAIN_PIXEL,px,"mono",1)
      if not ok or not f then ok,f=pcall(G.newFont,PLAIN_PIXEL,px,"mono") end
    else
      ok,f=pcall(G.newFont,px)
    end
    if not ok or not f then ok,f=pcall(G.newFont,px) end
    if ok and f then
      if f.setFilter then pcall(f.setFilter,f,pixel and "nearest" or "linear",pixel and "nearest" or "linear") end
      fontCache[key]=f
      return f
    end
    return G.getFont()
  end

  function Style.text(value,font,x,y,w,align,c)
    if font then G.setFont(font) end
    Style.color(c,nil,true)
    value=tostring(value or "")
    if w then
      local ok=pcall(G.printf,value,x,y,w,align or "left")
      if not ok then G.printf(value:gsub("[\128-\255]","?"),x,y,w,align or "left") end
    else
      local ok=pcall(G.print,value,x,y)
      if not ok then G.print(value:gsub("[\128-\255]","?"),x,y) end
    end
  end

  local function frameImage()
    local id=tostring(opt("frameAsset","2"))
    local path=(id=="1" and "assets/pixel_frame1.png")
      or (id=="3" and "assets/pixel_frame3.png")
      or "assets/pixel_frame2.png"
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
      imageCache[path]=img
      return img
    end
    imageCache[path]=false
    return nil
  end

  local function drawNineSlice(img,x,y,w,h,pixelScale)
    if not (img and type(img.getDimensions)=="function" and type(G.newQuad)=="function") then return false end
    local iw,ih=img:getDimensions()
    if not iw or not ih or iw<3 or ih<3 then return false end
    local slice=math.max(1,math.min(24,math.floor(math.min(iw,ih)/2)))
    pixelScale=clamp(math.floor(tonumber(pixelScale) or 1),1,4)
    local corner=math.min(slice*pixelScale,w/2,h/2)
    local function part(sx,sy,sw,sh,dx,dy,dw,dh)
      if sw<=0 or sh<=0 or dw<=0 or dh<=0 then return end
      local ok,q=pcall(G.newQuad,sx,sy,sw,sh,iw,ih)
      if ok and q then G.draw(img,q,dx,dy,0,dw/sw,dh/sh) end
    end
    local midSW=math.max(1,iw-slice*2); local midSH=math.max(1,ih-slice*2)
    local midW=math.max(0,w-corner*2); local midH=math.max(0,h-corner*2)
    part(0,0,slice,slice,x,y,corner,corner)
    part(slice,0,midSW,slice,x+corner,y,midW,corner)
    part(iw-slice,0,slice,slice,x+w-corner,y,corner,corner)
    part(0,slice,slice,midSH,x,y+corner,corner,midH)
    part(iw-slice,slice,slice,midSH,x+w-corner,y+corner,corner,midH)
    part(0,ih-slice,slice,slice,x,y+h-corner,corner,corner)
    part(slice,ih-slice,midSW,slice,x+corner,y+h-corner,midW,corner)
    part(iw-slice,ih-slice,slice,slice,x+w-corner,y+h-corner,corner,corner)
    return true
  end

  function Style.panel(x,y,w,h,c,alpha)
    c=c or Style.theme()
    local style=tostring(opt("frameStyle","pixel"))
    if style=="theme" then style="soft" end
    local fillAlpha=Style.panelOpacity(alpha or 1)
    local radius=(style=="plain" or style=="pixel") and 0 or math.max(8,math.min(w,h)*.018)
    Style.color(c.frameShadow or {0,0,0,.4},.18*fillAlpha)
    G.rectangle("fill",x+2,y+3,w,h,radius,radius)
    Style.color(c.surface,math.min(1,(c.surface[4] or 1)*fillAlpha))
    G.rectangle("fill",x,y,w,h,radius,radius)
    if style=="pixel" then
      Style.color({1,1,1,1},Style.foregroundOpacity(1))
      local img=frameImage()
      if img and drawNineSlice(img,x,y,w,h,opt("frameScale","2")) then return end
    end
    Style.color(c.frame or c.accent,nil,true)
    G.setLineWidth(math.max(2,math.min(w,h)*.0045))
    G.rectangle("line",x,y,w,h,radius,radius)
  end

  function Style.panelBox(sx,sy,sw,sh,logicalW,logicalH,maxW,maxH)
    local scale=Style.uiScale(sw,sh)
    local w=math.min((logicalW or 900)*scale,sw*(maxW or .90))
    local h=math.min((logicalH or 640)*scale,sh*(maxH or .88))
    if Style.layoutStyle()=="full" then
      w=sw*.94; h=sh*.92
    end
    return sx+(sw-w)/2,sy+(sh-h)/2,w,h,scale
  end

  mod._kantoInMotionGen2Ui=Style
  return Style
end
