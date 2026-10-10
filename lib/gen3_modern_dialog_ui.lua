-- Kanto in Motion - Gen 3 Modern dialogue + shop presentation
--
-- Presentation only:
--   * src.ui.game3.message keeps typewriter/page/sfx/input state.
--   * src.ui.game3.choice keeps YES/NO/multichoice cursor + callbacks.
--   * src.ui.game3.shop_menu (+ RSE delegate) keeps all shop logic.
-- KIM suppresses only their native pixels while DIALOGUE UI is enabled and
-- mirrors the live state at final-window resolution.
return function(mod)
  local G = love.graphics
  local Style = mod._kantoInMotionGen3Ui

  local okMessage, Message = pcall(require, "src.ui.game3.message")
  local okChoice, Choice = pcall(require, "src.ui.game3.choice")
  local okShop, ShopMenu = pcall(require, "src.ui.game3.shop_menu")
  local okStack, Stack = pcall(require, "src.ui.game3.stack")
  local okItems, ItemsData = pcall(require, "src.core.game3.items_data")
  local okBag, Bag = pcall(require, "src.core.game3.bag")
  local okRom, RomText = pcall(require, "src.core.game3.rom_text")
  local okFont, FrlgFont = pcall(require, "src.ui.game3.frlg_font")
  local okRseDecor, RseDecor = pcall(require, "src.core.game3.rse.decoration_inventory")

  if not (okMessage and okChoice and okShop and okStack) then return false end

  local function enabled()
    if Style and Style.presenterEnabled then return Style.presenterEnabled("dialogue") end
    return mod.options:get("gen3IntegratedModernUi") ~= false
      and mod.options:get("gen3DialogueUi") ~= false
  end

  local function hideOriginal()
    if Style and Style.hideOriginal then return Style.hideOriginal() end
    return true
  end

  local function theme()
    if Style and Style.theme then return Style.theme() end
    return {
      surface={.075,.105,.17,.98},raised={.12,.17,.27,1},selected={.18,.43,.72,1},
      accent={.48,.86,1,1},frame={.48,.86,1,1},frameShadow={.01,.02,.04,.42},
      text={.96,.98,1,1},muted={.74,.82,.92,1},divider={.38,.5,.68,.94},
    }
  end

  local function color(c,a,foreground)
    if Style and Style.color then return Style.color(c,a,foreground) end
    c=c or {1,1,1,1}; G.setColor(c[1] or 1,c[2] or 1,c[3] or 1,a==nil and (c[4] or 1) or a)
  end

  local function text(v,font,x,y,w,align,c)
    if Style and Style.text then return Style.text(v,font,x,y,w,align,c) end
    if font then G.setFont(font) end
    color(c)
    v=tostring(v or "")
    if w and w>0 then G.printf(v,x,y,w,align or "left") else G.print(v,x,y) end
  end

  local function fontFor(px)
    if Style and Style.font then return Style.font(px) end
    return G.newFont(math.max(8,math.floor(tonumber(px) or 12)))
  end

  local function panel(x,y,w,h,c,alpha)
    if Style and Style.panel then return Style.panel(x,y,w,h,c,alpha) end
    local r=math.max(6,math.min(w,h)*.025)
    color(c.surface,alpha or .96); G.rectangle("fill",x,y,w,h,r,r)
    color(c.frame or c.accent); G.rectangle("line",x,y,w,h,r,r)
  end

  local function playfield(viewport)
    local x=tonumber(viewport and viewport.gameX) or 0
    local y=tonumber(viewport and viewport.gameY) or 0
    local w=tonumber(viewport and viewport.gameWidth)
    local h=tonumber(viewport and viewport.gameHeight)
    if w and h and w>0 and h>0 then return x,y,w,h end
    local ww,wh=G.getDimensions()
    return 0,0,ww,wh
  end

  local function canonicalGame3Playfield(viewport)
    local okD, Display = pcall(require, "src.core.game3.display")
    if okD and Display and type(Display.fit)=="function" then
      local ok, _, ox, oy, pw, ph = pcall(Display.fit)
      if ok and tonumber(pw) and tonumber(ph) and pw>0 and ph>0 then
        return ox,oy,pw,ph
      end
    end
    return playfield(viewport)
  end

  local function uiScale(sw,sh)
    if Style and Style.uiScale then return Style.uiScale(sw,sh) end
    return math.min(sw/640,sh/360)
  end

  local function dialogueScale()
    return Style and Style.dialogueScale and Style.dialogueScale() or 1
  end

  local function dialogueUiScale()
    if Style and Style.dialogueUiScale then return Style.dialogueUiScale() end
    local value=mod.options and mod.options.get and mod.options:get("gen3DialogueUiScale") or "100"
    local pct=tonumber(value) or 100
    return math.max(.5,math.min(2,pct/100))
  end

  local function density()
    return Style and Style.density and Style.density() or 1
  end

  local function layoutStyle()
    return Style and Style.layoutStyle and Style.layoutStyle() or "floating"
  end

  -- Keep full-screen menu presenters visually consistent.  Bag already uses
  -- this exact window policy; the v93 shop used its own 86% x 82% rectangle,
  -- so UI SCALE changed Bag without changing the shop footprint.
  local function menuWindowRect(viewport)
    -- Use the *same function* that draws the Modern Bag/SELL window whenever
    -- it is available.  This removes the last duplicated geometry path: at
    -- 100% UI scale BUY and SELL now literally receive the same x/y/w/h.
    if type(mod._kantoInMotionGen3WindowRect)=="function" then
      local ok,x,y,w,h,sx,sy,sw,sh=pcall(mod._kantoInMotionGen3WindowRect,viewport,"bag")
      if ok and tonumber(w) and tonumber(h) and w>0 and h>0 then
        -- SELL is already the Modern Bag, so it is the size reference.  Do not
        -- shrink or otherwise normalize the Bag to the mart.  The mart root
        -- and BUY presenter instead expand to the Bag's authored footprint.
        --
        -- In the shop-camera path Game3 can report a shortened vertical render
        -- surface even though the horizontal span is unchanged.  That made the
        -- shop keep the Bag width while losing height.  Reconstruct the Bag
        -- height from the same 240x160 authored proportions using the returned
        -- Bag width, then re-center it in the canonical playfield.
        local roomy=(tonumber(sw) or 0)>=720 and (tonumber(sh) or 0)>=460
        local full=layoutStyle()=="full"
        local fw=full and .94 or (roomy and .78 or .94)
        local fh=full and .92 or (roomy and .84 or .92)
        local bagAspectH=(160*fh)/(240*fw)
        local targetH=w*bagAspectH
        if tonumber(sh) and sh>0 then targetH=math.min(sh*.97,targetH) end
        if targetH>h+1 then
          h=targetH
          if tonumber(sy) and tonumber(sh) then y=sy+(sh-h)*.5 end
        end
        return x,y,w,h,sx,sy,sw,sh
      end
    end

    -- Fallback for older loader orders/engine builds.
    -- Do not trust the shop-camera render viewport here: BUY can report a
    -- shorter gameHeight than the field/Bag path.  Display.fit() is stable and
    -- is the same presentation rectangle used when SELL opens the Modern Bag.
    local sx,sy,sw,sh=canonicalGame3Playfield(viewport)
    local roomy=sw>=720 and sh>=460
    local fw=roomy and .78 or .94
    local fh=roomy and .84 or .92

    -- Match gen3_modern_core_menus.lua's Bag window *exactly*.  The sell
    -- screen is the Bag menu, whose AUTO UI scale is resolved from the final
    -- output dimensions.  Resolving the shop's scale from the smaller Game3
    -- playfield made BUY stay at the base .84 height while SELL/Bag could
    -- grow to the .97 cap.  That is why the two shop modes had the same width
    -- but visibly different heights.
    local userScale
    if Style and Style.uiScale then
      local ww,wh=G.getDimensions()
      userScale=Style.uiScale(ww,wh)
    else
      userScale=uiScale(sw,sh)
    end

    local w=math.min(sw*.97,sw*fw*userScale)
    local h=math.min(sh*.97,sh*fh*userScale)
    if layoutStyle()=="full" then w=sw*.94; h=sh*.92 end
    return sx+(sw-w)*.5,sy+(sh-h)*.5,w,h,sx,sy,sw,sh
  end

  local function centeredTextY(y,h,font)
    return y+math.max(0,(h-(font and font:getHeight() or 0))*.5)
  end

  local function rowHighlight(x,y,w,h,c)
    color(c.selected)
    G.rectangle("fill",x,y,w,h,math.max(4,h*.15),math.max(4,h*.15))
    color(c.accent)
    G.rectangle("fill",x,y,math.max(3,w*.008),h,2,2)
  end

  local function chevron(cx,cy,size,dir,c)
    local s=math.max(3,size or 8)
    color(c)
    G.setLineWidth(math.max(1.25,s*.16))
    if dir=="up" then
      G.line(cx-s*.5,cy+s*.28,cx,cy-s*.28,cx+s*.5,cy+s*.28)
    elseif dir=="down" then
      G.line(cx-s*.5,cy-s*.28,cx,cy+s*.28,cx+s*.5,cy-s*.28)
    elseif dir=="left" then
      G.line(cx+s*.28,cy-s*.5,cx-s*.28,cy,cx+s*.28,cy+s*.5)
    else
      G.line(cx-s*.28,cy-s*.5,cx+s*.28,cy,cx-s*.28,cy+s*.5)
    end
  end

  local function topLayer()
    return Stack and Stack.top and Stack.top() or nil
  end

  local function overworldDialogueAllowed()
    local top=topLayer()
    return not (top and top.hideBelow)
  end

  local function supportedMessage()
    if not (Message and Message.isOpen and Message.isOpen()) then return false end
    local kind=Message.frameKind and Message.frameKind() or Message._frame or "dialogue"
    -- Battle has its own Modern Battle UI; braille/sign retain their authored
    -- source presentation.  This first pass owns ordinary field NPC dialogue.
    return kind=="dialogue"
  end

  local function revealedText(value,limit)
    value=tostring(value or "")
    limit=math.max(0,tonumber(limit) or 0)
    if limit<=0 then return "" end
    if not (okFont and FrlgFont and type(FrlgFont.countChars)=="function") then
      local okUtf,utf=pcall(require,"utf8")
      if okUtf and utf and utf.offset then
        local p=utf.offset(value,limit+1)
        return p and value:sub(1,p-1) or value
      end
      return value:sub(1,limit)
    end
    if FrlgFont.countChars(value)<=limit then return value end
    local okUtf,utf=pcall(require,"utf8")
    if not (okUtf and utf and utf.codes and utf.offset) then return value:sub(1,limit) end
    local last=0
    for pos in utf.codes(value) do
      local nextPos=utf.offset(value,2,pos)
      local e=(nextPos and nextPos-1) or #value
      local prefix=value:sub(1,e)
      if FrlgFont.countChars(prefix)>limit then break end
      last=e
    end
    return value:sub(1,last)
  end

  local function drawContinueArrow(x,y,size,c)
    color(c)
    G.polygon("fill",x-size*.5,y-size*.18,x+size*.5,y-size*.18,x,y+size*.45)
  end

  local function drawMessage(viewport,c)
    if not supportedMessage() or not overworldDialogueAllowed() then return false end
    local sx,sy,sw,sh=playfield(viewport)
    local us=uiScale(sw,sh)
    local ds=dialogueScale()
    local boxScale=dialogueUiScale()
    local den=density()
    local body=fontFor(math.max(12,18*us*ds))
    local small=fontFor(math.max(9,11*us*ds))
    local full=layoutStyle()=="full"
    local neutralW=math.min(sw*(full and .96 or .88),full and 1500*us or 1150*us)
    local w=math.min(sw*.98,neutralW*boxScale)
    local lineH=body:getHeight()
    local neutralH=math.max(102*us*den,lineH*2+42*us*den)
    if full then neutralH=math.max(neutralH,sh*.28) end

    local padX=math.max(12*us,math.max(16*us,body:getHeight()*.72)*math.min(1.35,boxScale))
    local padY=math.max(8*us,math.max(12*us,body:getHeight()*.45)*math.min(1.35,boxScale))
    local page=Message.currentPage and Message.currentPage() or ""
    local visible=revealedText(page,Message._revealed or 0)
    -- At small box scales, preserve the user's text size and grow vertically
    -- only as much as wrapping requires instead of clipping dialogue.
    local wrapW=math.max(1,w-padX*2)
    local wrappedLines=2
    if body and type(body.getWrap)=="function" then
      local okWrap,_,lines=pcall(body.getWrap,body,visible,wrapW)
      if okWrap and type(lines)=="table" then wrappedLines=math.max(1,#lines) end
    end
    local neededH=wrappedLines*lineH+padY*2+math.max(16*us,small:getHeight())
    local h=math.min(sh*.72,math.max(neededH,neutralH*boxScale))
    local x=sx+(sw-w)*.5
    local y=sy+sh-h-math.max(12*us,sh*.024)
    panel(x,y,w,h,c,.98)

    text(visible,body,x+padX,y+padY,w-padX*2,"left",c.text)

    if Message._waiting and not Message._stay and not Message._held then
      local blink=math.floor((Message._arrowTicks or 0)/10)%2==0
      if blink then
        local sz=math.max(9*us,small:getHeight()*.65)
        drawContinueArrow(x+w-padX-sz*.5,y+h-padY-sz*.28,sz,c.accent)
      end
    end
    return true,x,y,w,h,body,us
  end

  local function choiceLabels()
    local out={}
    for i,v in ipairs(Choice.options or {}) do out[i]=tostring(v or "") end
    return out
  end

  local function drawChoice(viewport,c,msgRect)
    if not (Choice.active and Choice.options and Choice.style~="battle") then return false end
    if not overworldDialogueAllowed() then return false end
    local sx,sy,sw,sh=playfield(viewport)
    local us=uiScale(sw,sh)
    local ds=dialogueScale()
    local boxScale=dialogueUiScale()
    local den=density()
    local body=fontFor(math.max(11,17*us*ds))
    local labels=choiceLabels()
    if #labels==0 then return false end
    local cols=math.max(1,tonumber(Choice.cols) or 1)
    local rows=math.ceil(#labels/cols)
    local maxLabel=0
    for _,v in ipairs(labels) do maxLabel=math.max(maxLabel,body:getWidth(v)) end
    local cellW=math.max(maxLabel+math.max(18*us,34*us*boxScale),125*us*boxScale)
    local cellH=math.max(body:getHeight()+math.max(8*us,14*us*boxScale),34*us*boxScale)*den
    local outerPad=math.max(12*us,24*us*boxScale)
    local w=math.min(sw*.82,cols*cellW+outerPad)
    local h=rows*cellH+outerPad
    local x,y
    if msgRect then
      local mx,my,mw=msgRect[1],msgRect[2],msgRect[3]
      x=math.min(sx+sw-w-12*us,mx+mw-w-14*us)
      y=math.max(sy+12*us,my-h-8*us)
    else
      x=sx+(sw-w)*.5; y=sy+(sh-h)*.52
    end
    panel(x,y,w,h,c,.99)
    local innerW=w-20*us
    local actualCellW=innerW/cols
    for i,label in ipairs(labels) do
      local idx=i-1; local col=idx%cols; local row=math.floor(idx/cols)
      local cx=x+10*us+col*actualCellW
      local cy=y+10*us+row*cellH
      if i==(Choice.cursor or 1) then rowHighlight(cx+2*us,cy+2*us,actualCellW-4*us,cellH-4*us,c) end
      text(label,body,cx+12*us,centeredTextY(cy,cellH,body),actualCellW-24*us,
        cols>1 and "center" or "left",i==(Choice.cursor or 1) and c.text or c.muted)
    end
    return true
  end

  local function money(shop)
    return math.max(0,math.floor(tonumber(shop and shop._session and shop._session.money) or 0))
  end

  local function itemName(id,isDecor)
    if id==nil then return "CANCEL" end
    if isDecor and okRseDecor and RseDecor and RseDecor.info then
      local d=RseDecor.info(id); return d and d.name or tostring(id)
    end
    if okItems and ItemsData and ItemsData.displayName then
      local ok,v=pcall(ItemsData.displayName,id); if ok and v then return tostring(v) end
    end
    return tostring(id)
  end

  local function itemPrice(id,isDecor)
    if id==nil then return 0 end
    if isDecor and okRseDecor and RseDecor and RseDecor.info then
      local d=RseDecor.info(id); return math.max(0,math.floor(tonumber(d and d.price) or 0))
    end
    if okItems and ItemsData and ItemsData.info then
      local info=ItemsData.info(id); return math.max(0,math.floor(tonumber(info and info.price) or 0))
    end
    return 0
  end

  local function itemDesc(id,isDecor)
    if id==nil then
      if okRom and RomText and RomText.plain then
        local ok,v=pcall(RomText.plain,"gText_QuitShopping"); if ok and v then return tostring(v) end
      end
      return "Stop shopping."
    end
    if isDecor and okRseDecor and RseDecor and RseDecor.info then
      local d=RseDecor.info(id); return tostring(d and d.description or "")
    end
    if okItems and ItemsData and ItemsData.description then
      local ok,v=pcall(ItemsData.description,id); if ok and v then return tostring(v) end
    end
    return ""
  end

  local function isRseShop(shop)
    return shop and shop._rse~=nil
  end

  local function isDecorShop(shop)
    return isRseShop(shop) and shop._martType and tostring(shop._martType)~="NORMAL"
  end

  local function shopRootRows(shop)
    if isDecorShop(shop) then return {"BUY","QUIT"} end
    return {"BUY","SELL","QUIT"}
  end

  local function shopState(shop)
    if isRseShop(shop) then return tostring(shop.state or shop.mode or "root") end
    return tostring(shop.mode or "root")
  end

  local function shopBrowsing(shop)
    local st=shopState(shop)
    return st=="buy" or st=="list" or st=="buy_qty" or st=="qty"
      or st=="buy_confirm" or st=="confirm" or st=="buy_msg" or st=="msg"
  end

  local function selectedItem(shop)
    if isRseShop(shop) then
      if shop._itemId~=nil and (shop.state=="qty" or shop.state=="confirm" or shop.state=="msg") then return shop._itemId end
      local idx=(tonumber(shop.scroll) or 0)+(tonumber(shop.row) or 0)+1
      return shop._items and shop._items[idx] or nil
    end
    if shop._pending and shop._pending.id~=nil then return shop._pending.id end
    local idx=tonumber(shop.cursor) or 1
    return shop._items and shop._items[idx] or nil
  end

  local function shopListPosition(shop)
    if isRseShop(shop) then
      local scroll=tonumber(shop.scroll) or 0
      local row=tonumber(shop.row) or 0
      return scroll,row+1,8
    end
    return tonumber(shop.scroll) or 0,(tonumber(shop.cursor) or 1)-(tonumber(shop.scroll) or 0),6
  end

  local function shopStatus(shop)
    return tostring(shop and shop._status or "")
  end

  local function drawScrollbar(x,y,h,total,first,visible,c,us)
    if total<=visible then return end
    local trackW=math.max(3*us,2)
    color(c.divider,.5,true); G.rectangle("fill",x,y,trackW,h,trackW*.5,trackW*.5)
    local thumbH=math.max(16*us,h*(visible/total))
    local denom=math.max(1,total-visible)
    local ty=y+(h-thumbH)*(math.max(0,first)/denom)
    color(c.accent,nil,true); G.rectangle("fill",x,ty,trackW,thumbH,trackW*.5,trackW*.5)
  end

  local function drawShop(viewport,c)
    if not (ShopMenu and ShopMenu.open) then return false end
    local top=topLayer()
    if not top or top.id~="shop" then return false end -- sell Bag owns the top layer

    local x,y,w,h,sx,sy,sw,sh=menuWindowRect(viewport)

    -- The Poké Mart outer frame already shares the exact Bag/SELL rectangle.
    -- What was still visually smaller was the *inside* of the shop: it used a
    -- screen-space UI scale (~1.0 at 100%) while the Bag lays itself out from
    -- its 240x160 authored surface.  Use the Bag's authored scale and the same
    -- header/footer/font metrics here so ROOT, BUY and SELL read as one UI.
    local s=math.min(w/240,h/160)
    local us=s
    local den=density()
    local titleF=fontFor(11*s)
    local bodyF=fontFor(7.6*s)
    local smallF=fontFor(5.8*s)
    local priceF=fontFor(6.4*s)
    panel(x,y,w,h,c,.98)
    local pad=math.max(8*s,w*.018)
    local headerH=math.max(25*s,h*.16)
    local footerH=math.max(31*s,h*.20)

    text("POKé MART",titleF,x+pad,y+pad*.65,w*.45,"left",c.text)
    text(("MONEY  ¥%d"):format(money(ShopMenu)),bodyF,x+w*.50,y+pad*.72,w*.46-pad,"right",c.accent)
    color(c.divider,.7,true); G.rectangle("fill",x+pad,y+headerH,w-pad*2,math.max(1,s))

    local st=shopState(ShopMenu)
    local contentY=y+headerH
    local contentH=h-headerH-footerH

    if st=="root" then
      local rows=shopRootRows(ShopMenu)
      local menuW=w*.33
      -- Match the Bag's six-row rhythm even though the root only has 2/3
      -- choices.  This keeps row/text scale identical instead of making the
      -- root menu a separate, tiny layout.
      local rh=(contentH/6)*den
      local rowGap=math.max(1,s*.8)
      for i,label in ipairs(rows) do
        local yy=contentY+(i-1)*(rh+rowGap)
        if i==(ShopMenu.cursor or 1) then rowHighlight(x+pad,yy,menuW-pad,rh-rowGap,c) end
        text(label,bodyF,x+pad+12*s,centeredTextY(yy,rh-rowGap,bodyF),menuW-pad-20*s,"left",
          i==(ShopMenu.cursor or 1) and c.text or c.muted)
      end
      local dx=x+w*.39; local dw=w*.57-pad
      panel(dx,contentY,dw,math.min(contentH*.62,58*s),c,.72)
      text(shopStatus(ShopMenu),bodyF,dx+6*s,contentY+5*s,dw-12*s,"left",c.text)
    elseif shopBrowsing(ShopMenu) then
      local isDecor=isDecorShop(ShopMenu)
      local listW=w*.54
      local listX=x+pad
      local detailX=x+listW+pad*.7
      local detailW=x+w-pad-detailX
      local scroll,selectedSlot,visible=shopListPosition(ShopMenu)
      local total=#(ShopMenu._items or {})+1
      local rh=contentH/visible
      for slot=1,visible do
        local idx=scroll+slot
        if idx>total then break end
        local id=ShopMenu._items and ShopMenu._items[idx] or nil
        local yy=contentY+(slot-1)*rh
        local selected=slot==selectedSlot
        if selected then rowHighlight(listX,yy,listW-pad*1.3,rh-math.max(1,s*.6),c) end
        local label=id~=nil and itemName(id,isDecor) or "CANCEL"
        text(label,bodyF,listX+12*s,centeredTextY(yy,rh,bodyF),listW*.61,"left",selected and c.text or c.muted)
        if id~=nil then
          text(("¥%d"):format(itemPrice(id,isDecor)),priceF,listX+listW*.64,centeredTextY(yy,rh,priceF),listW*.24,"right",selected and c.text or c.muted)
        end
      end
      drawScrollbar(listX+listW-pad*.92,contentY+4*us,contentH-8*us,total,scroll,visible,c,us)

      local id=selectedItem(ShopMenu)
      local name=id~=nil and itemName(id,isDecor) or "CANCEL"
      text(name,titleF,detailX,contentY+2*s,detailW,"left",c.text)
      text(itemDesc(id,isDecor),bodyF,detailX,contentY+titleF:getHeight()+5*s,detailW,"left",c.muted)

      local qtyState=(st=="buy_qty" or st=="qty")
      local confirmState=(st=="buy_confirm" or st=="confirm")
      if qtyState then
        local q=math.max(1,tonumber(ShopMenu.qty) or 1)
        local unit=itemPrice(id,isDecor)
        local qh=math.max(27*s,bodyF:getHeight()*2+8*s)
        local qy=contentY+contentH-qh
        panel(detailX,qy,detailW,qh,c,.86)
        chevron(detailX+7*s,qy+qh*.30,3*s,"up",c.muted)
        chevron(detailX+7*s,qy+qh*.72,3*s,"down",c.muted)
        text(("QTY  %d"):format(q),bodyF,detailX+13*s,qy+5*s,detailW*.42,"left",c.text)
        local totalCost=isRseShop(ShopMenu) and (tonumber(ShopMenu._totalCost) or unit*q) or unit*q
        text(("TOTAL  ¥%d"):format(totalCost),bodyF,detailX+detailW*.38,qy+5*s,detailW*.56,"right",c.accent)
        if okBag and Bag and ShopMenu._session and ShopMenu._session.bag and id~=nil then
          local ok,n=pcall(Bag.get,ShopMenu._session.bag,id)
          if ok then text(("IN BAG  %d"):format(tonumber(n) or 0),smallF,detailX+13*s,qy+17*s,detailW-18*s,"left",c.muted) end
        end
      end

      if confirmState then
        local labels={"YES","NO"}
        local selected=isRseShop(ShopMenu) and (tonumber(ShopMenu.yesCursor) or 1) or (tonumber(ShopMenu.yesNoCursor) or 1)
        local rowH=math.max(12*s,bodyF:getHeight()+4*s)
        local cw=math.min(detailW,72*s)
        local ch=rowH*2+6*s
        local cx=detailX+detailW-cw; local cy=contentY+contentH-ch
        panel(cx,cy,cw,ch,c,.99)
        for i,label in ipairs(labels) do
          local yy=cy+3*s+(i-1)*rowH
          if i==selected then rowHighlight(cx+2*s,yy,cw-4*s,rowH-math.max(1,s*.5),c) end
          text(label,bodyF,cx+7*s,centeredTextY(yy,rowH,bodyF),cw-14*s,"left",i==selected and c.text or c.muted)
        end
      end

      local status=shopStatus(ShopMenu)
      if status~="" and (st=="buy_msg" or st=="msg" or qtyState or confirmState) then
        local dh=math.max(28*s,bodyF:getHeight()*2+8*s)
        local dx=x+pad; local dy=y+h-footerH-dh-3*s
        panel(dx,dy,w-pad*2,dh,c,.99)
        text(status,bodyF,dx+6*s,dy+5*s,w-pad*2-12*s,"left",c.text)
      end
    end

    local hint="A SELECT   B BACK"
    if st=="buy_qty" or st=="qty" then hint="UP/DOWN QTY   LEFT/RIGHT x10   A OK   B BACK" end
    text(hint,smallF,x+pad,y+h-footerH+5*s,w-pad*2,"center",c.muted)
    return true
  end

  -- Suppress source pixels only while the Modern presenter owns that exact
  -- surface.  State/input remain entirely native.
  if type(Message.draw)=="function" and not Message.__kimGen3ModernDialogV93 then
    local upstream=Message.draw
    Message.draw=function(...)
      if enabled() and hideOriginal() and supportedMessage() then return end
      return upstream(...)
    end
    Message.__kimGen3ModernDialogV93=true
  end

  if type(Choice.draw)=="function" and not Choice.__kimGen3ModernDialogV93 then
    local upstream=Choice.draw
    Choice.draw=function(...)
      if enabled() and hideOriginal() and Choice.active and Choice.style~="battle" then return end
      return upstream(...)
    end
    Choice.__kimGen3ModernDialogV93=true
  end

  if type(ShopMenu.draw)=="function" and not ShopMenu.__kimGen3ModernDialogV93 then
    local upstream=ShopMenu.draw
    ShopMenu.draw=function(...)
      if enabled() and hideOriginal() and ShopMenu.open then return end
      return upstream(...)
    end
    ShopMenu.__kimGen3ModernDialogV93=true
  end

  mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
    nextFn(game,viewport)
    if not enabled() then return end
    local c=theme()
    G.push("all")
    local ok,err=pcall(function()
      G.origin(); G.setShader(); G.setBlendMode("alpha")
      -- The Poké Mart camera can leave a native scissor active on render.hud.
      -- That clipped the BUY presenter vertically even when its requested
      -- rectangle matched the Bag/SELL rectangle.  Clear it only inside this
      -- pushed graphics state; G.pop() restores the engine's original scissor.
      G.setScissor()
      if drawShop(viewport,c) then return end
      local drew,mx,my,mw,mh=drawMessage(viewport,c)
      local rect=drew and {mx,my,mw,mh} or nil
      drawChoice(viewport,c,rect)
    end)
    G.setScissor(); G.setShader(); G.setBlendMode("alpha"); G.setColor(1,1,1,1)
    G.pop()
    if not ok then mod._kantoInMotionGen3DialogLastDrawError=tostring(err)
    else mod._kantoInMotionGen3DialogLastDrawError=nil end
  end,11180)

  mod.exports=mod.exports or {}
  mod.exports.gen3ModernDialogUi=true
  return true
end
