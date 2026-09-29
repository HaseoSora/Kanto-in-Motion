-- Kanto in Motion v1.5.3 - Gen 2 Modern Dialog UI v30 -- Full NEW GAME Modern UI
--
-- Shared Modern UI presentation for Gen 2 dialogue/choice surfaces.
--
-- This is intentionally presentation-only:
--   * TextBox keeps typewriter/page/prompt/sfx behavior.
--   * ChoiceBox keeps YES/NO input and callbacks.
--   * ScriptMenu keeps its native cursor/grid/input logic.
--   * MartMenu keeps all buy/sell/quantity/money/item logic.
--   * BattleState keeps its level-up/learn-move state machine.
--
-- KIM only hides the vanilla draw and mirrors the live state into the same
-- themed final-window Modern UI used by the rest of v1.5.3.
return function(mod)
  local G = love.graphics
  local Style = mod._kantoInMotionGen2Ui
  local okFont, Font = pcall(require, "src.render.Font")
  local okText, TextBox = pcall(require, "src.render.TextBox")
  local okChoice, ChoiceBox = pcall(require, "src.ui.ChoiceBox")
  local okStrings, Strings = pcall(require, "src.core.Strings")
  local okChrome, Chrome = pcall(require, "src.ui.gen2.Chrome")
  local okScript, ScriptMenu = pcall(require, "src.ui.gen2.ScriptMenu")
  local okMart, MartMenu = pcall(require, "src.ui.gen2.MartMenu")
  local okBattle, BattleState = pcall(require, "src.ui.gen2.BattleState")
  local okGender, GenderSelect = pcall(require, "src.ui.gen2.GenderSelect")
  local okClock, InitClock = pcall(require, "src.ui.gen2.InitClock")
  local okOak, OakSpeech = pcall(require, "src.ui.gen2.OakSpeech")
  local okNamePick, NamePick = pcall(require, "src.ui.gen2.NamePick")
  local okNaming, NamingScreen = pcall(require, "src.ui.gen2.NamingScreen")
  local okPal, GbcPalette = pcall(require, "src.render.GbcPalette")
  local okTyper, Typer = pcall(require, "src.ui.gen2.Typer")
  local unpackCompat = table.unpack or unpack

  if not (okText and okChoice) then return false end

  local FONT_PATH = "assets/fonts/plainpixel/PlainPixel-Regular.ttf"
  local fontCache = {}

  local FALLBACK = {
    surface = { 0.075, 0.105, 0.17, 0.96 },
    raised = { 0.12, 0.17, 0.27, 0.94 },
    selected = { 0.18, 0.43, 0.72, 0.96 },
    accent = { 0.48, 0.86, 1.00, 1.00 },
    frame = { 0.48, 0.86, 1.00, 1.00 },
    frameShadow = { 0.01, 0.02, 0.04, 0.42 },
    text = { 0.96, 0.98, 1.00, 1.00 },
    muted = { 0.74, 0.82, 0.92, 1.00 },
    divider = { 0.38, 0.50, 0.68, 0.94 },
  }

  local function opt(key, fallback)
    if not (mod.options and type(mod.options.get) == "function") then
      return fallback
    end
    local ok, value = pcall(mod.options.get, mod.options, key)
    if not ok or value == nil then return fallback end
    return value
  end

  local function enabled()
    if Style and Style.masterEnabled then return Style.masterEnabled() end
    return opt("gen2IntegratedModernUi", true) ~= false
  end
  local function dialogueEnabled()
    if Style and Style.presenterEnabled then return Style.presenterEnabled("dialogue") end
    return enabled()
  end
  local function menuEnabled()
    if Style and Style.presenterEnabled then return Style.presenterEnabled("menu") end
    return enabled()
  end

  local function hideOriginal()
    if Style and Style.hideOriginal then return Style.hideOriginal() end
    return true
  end

  local function uiScale(sw,sh)
    return Style and Style.uiScale and Style.uiScale(sw,sh)
      or math.max(.85, math.min(1.5,(sh or 760)/760))
  end

  local function dialogueScale()
    return Style and Style.dialogueScale and Style.dialogueScale() or 1
  end

  local function theme()
    if Style and Style.theme then return Style.theme() end
    local themes = mod._kantoInMotionGen2Themes
    if type(themes) ~= "table" then return FALLBACK end
    return themes[tostring(opt("gen2UiTheme", "default"))]
      or themes.default or FALLBACK
  end

  local function color(c, alpha, foreground)
    if Style and Style.color then return Style.color(c,alpha,foreground) end
    c = c or {1,1,1,1}
    G.setColor(c[1] or 1, c[2] or 1, c[3] or 1,
      alpha == nil and (c[4] or 1) or alpha)
  end

  local function fontFor(px)
    px=(tonumber(px) or 12)*dialogueScale()
    if Style and Style.font then return Style.font(px) end
    px = math.max(9, math.floor(px + 0.5))
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

  local function drawText(value, font, x, y, w, align, c)
    if Style and Style.text then return Style.text(value,font,x,y,w,align,c) end
    if font then G.setFont(font) end
    color(c,nil,true)
    value = tostring(value or "")
    if w then
      local ok = pcall(G.printf, value, x, y, w, align or "left")
      if ok then return end
      G.printf(value:gsub("[\128-\255]", "?"), x, y, w, align or "left")
    else
      local ok = pcall(G.print, value, x, y)
      if not ok then G.print(value:gsub("[\128-\255]", "?"), x, y) end
    end
  end

  local function panel(x, y, w, h, c, alpha)
    if Style and Style.panel then return Style.panel(x,y,w,h,c,alpha) end
    local r = math.max(8, math.min(w,h) * 0.025)
    color(c.frameShadow or {0,0,0,.4}, 0.20)
    G.rectangle("fill", x + 2, y + 3, w, h, r, r)
    color(c.surface, math.min(1, (c.surface[4] or 1) * (alpha or .96)))
    G.rectangle("fill", x, y, w, h, r, r)
    color(c.frame or c.accent)
    G.setLineWidth(math.max(2, math.min(w,h) * 0.006))
    G.rectangle("line", x, y, w, h, r, r)
  end

  local function playfield()
    local ww, wh = G.getDimensions()
    if okChrome and Chrome and type(Chrome.playfieldRect) == "function" then
      local ok, x, y, w, h = pcall(Chrome.playfieldRect, ww, wh)
      if ok and w and h and w > 0 and h > 0 then return x,y,w,h end
    end
    return 0,0,ww,wh
  end

  local function splitVisibleLine(text, glyphCount)
    text = tostring(text or "")
    if not (okFont and Font and type(Font.split) == "function") then
      return text
    end
    local spans = Font.split(text)
    glyphCount = math.max(0, math.min(#spans, tonumber(glyphCount) or #spans))
    if glyphCount <= 0 then return "" end
    local last = spans[glyphCount]
    return last and text:sub(1, last.to) or ""
  end

  -- Mirror exactly what the TextBox typewriter has revealed.
  local function textBoxLines(box)
    local page = box.pages and box.pages[box.pageIndex]
    if type(page) ~= "table" then return {""} end
    local shownCount = math.max(1, #(box.shown or {}))
    local first = math.max(1, (tonumber(box.lineIndex) or 1) - shownCount + 1)
    local out = {}
    for i = first, math.min(#page, tonumber(box.lineIndex) or first) do
      local line = tostring(page[i] or "")
      if i == tonumber(box.lineIndex) then
        line = splitVisibleLine(line, box.charIndex)
      end
      out[#out + 1] = line
    end
    while #out > 2 do table.remove(out, 1) end
    return out
  end

  local function resolveLabel(value)
    if okStrings and Strings then
      local ok, s = pcall(Strings, value)
      if ok and s then return tostring(s) end
    end
    return tostring(value or "")
  end

  local function drawDialogBox(box, choice)
    local c = theme()
    local sx, sy, sw, sh = playfield()
    local scale = uiScale(sw,sh)
    local body = fontFor(28 * scale)
    local small = fontFor(18 * scale)

    local w = math.min(sw * .90, 1500 * scale)
    local lineH = body:getHeight()
    local h = math.max(150 * scale, lineH * 2 + 56 * scale)
    local x = sx + (sw - w) / 2
    local y = sy + sh - h - math.max(18 * scale, sh * .025)

    panel(x,y,w,h,c,.97)

    local padX = 28 * scale
    local padY = 20 * scale
    local lines = textBoxLines(box)
    for i,line in ipairs(lines) do
      drawText(line, body, x + padX,
        y + padY + (i - 1) * (lineH + 8 * scale),
        w - padX * 2, "left", c.text)
    end

    if type(box.moneyVisible) == "function" then
      local ok, visible = pcall(box.moneyVisible, box)
      if ok and visible and type(box.money) == "function" then
        local money = box.money() or 0
        local mw = math.max(210 * scale, w * .16)
        local mh = 56 * scale
        local mx = x + w - mw
        local my = y - mh - 10 * scale
        panel(mx,my,mw,mh,c,.98)
        drawText(("MONEY   ¥%d"):format(money), small,
          mx + 14*scale, my + (mh-small:getHeight())*.5,
          mw - 28*scale, "right", c.text)
      end
    end

    local arrow = false
    if type(box.arrowVisible) == "function" then
      local ok, visible = pcall(box.arrowVisible, box)
      arrow = ok and visible
    end
    if arrow and ((tonumber(box.blink) or 0) % 32 < 16) then
      drawText("▼", body, x + w - padX - body:getWidth("▼"),
        y + h - body:getHeight() - 10*scale, nil, nil, c.accent)
    end

    if choice then
      local labels = choice.labels or {"YES","NO"}
      local cw = math.max(250 * scale, w * .20)
      local rowH = math.max(48 * scale, body:getHeight() + 14 * scale)
      local ch = rowH * 2 + 20 * scale
      local cx = x + w - cw - 18 * scale
      local cy = y - ch - 10 * scale
      panel(cx,cy,cw,ch,c,.99)
      for i=1,2 do
        local yy = cy + 10*scale + (i-1)*rowH
        if i == (choice.index or 1) then
          color(c.selected)
          G.rectangle("fill", cx+8*scale, yy, cw-16*scale,rowH-4*scale,6,6)
          color(c.accent)
          G.rectangle("fill", cx+8*scale, yy, 4*scale,rowH-4*scale,2,2)
        end
        drawText(resolveLabel(labels[i]), body,
          cx+24*scale, yy+(rowH-body:getHeight())*.42,
          cw-40*scale, "left",
          i==(choice.index or 1) and c.text or c.muted)
      end
    end
  end

  local function drawBareChoice(choice)
    local c=theme()
    local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh)
    local body=fontFor(28*scale)
    local labels=choice.labels or {"YES","NO"}
    local rowH=math.max(52*scale,body:getHeight()+16*scale)
    local w=math.min(360*scale,sw*.38)
    local h=rowH*2+24*scale
    local x=sx+sw-w-34*scale
    local y=sy+(sh-h)*.53
    panel(x,y,w,h,c,.99)
    for i=1,2 do
      local yy=y+12*scale+(i-1)*rowH
      if i==(choice.index or 1) then
        color(c.selected); G.rectangle("fill",x+10*scale,yy,w-20*scale,rowH-5*scale,6,6)
      end
      drawText(resolveLabel(labels[i]),body,x+28*scale,
        yy+(rowH-body:getHeight())*.4,w-50*scale,"left",
        i==(choice.index or 1) and c.text or c.muted)
    end
  end

  local function drawScriptMenu(menu)
    local c=theme()
    local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh)
    local titleFont=fontFor(25*scale)
    local body=fontFor(23*scale)
    local small=fontFor(17*scale)
    local items=menu.items or {}
    local cols=math.max(1,tonumber(menu.cols) or 1)
    local rows=math.max(1,tonumber(menu.rows) or math.ceil(#items/cols))
    local cellH=math.max(48*scale,body:getHeight()+16*scale)
    local cellW=math.max(190*scale,sw*.14)
    local w=math.min(sw*.78,cols*cellW+48*scale)
    local h=math.min(sh*.72,rows*cellH+90*scale)
    local x=sx+(sw-w)/2
    local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.98)
    drawText(menu._kimTitle or "CHOOSE",titleFont,x+22*scale,y+15*scale,w-44*scale,"left",c.text)

    local selected=((tonumber(menu.row) or 1)-1)*cols+(tonumber(menu.col) or 1)
    local top=y+58*scale
    local innerW=w-36*scale
    local actualCellW=innerW/cols
    for i,label in ipairs(items) do
      local r=math.floor((i-1)/cols)
      local col=(i-1)%cols
      local cx=x+18*scale+col*actualCellW
      local cy=top+r*cellH
      if i==selected then
        color(c.selected)
        G.rectangle("fill",cx+3*scale,cy,actualCellW-6*scale,cellH-5*scale,6,6)
      end
      drawText(resolveLabel(label),body,cx+16*scale,
        cy+(cellH-body:getHeight())*.42,actualCellW-32*scale,
        cols>1 and "center" or "left",
        i==selected and c.text or c.muted)
    end

    local balance=menu.balance
    if balance then
      local player=menu.save and menu.save.player
      local money=(player and player.money) or 0
      local suffix=balance=="coins" and "COINS" or "MONEY"
      drawText(suffix.."  "..tostring(money),small,x+22*scale,
        y+h-small:getHeight()-15*scale,w-44*scale,"right",c.muted)
    end
  end

  local function martMessageLines(mart)
    local src=mart.message or mart.confirm
    if src and src.pages and src.pages[src.page or 1] then
      local page=src.pages[src.page or 1]
      local out={}
      for _,line in ipairs(page or {}) do out[#out+1]=tostring(line or "") end
      return out
    end
    local out={}
    for _,line in ipairs(mart.topLines or {}) do out[#out+1]=tostring(line or "") end
    return out
  end

  local function drawMart(mart)
    local c=theme()
    local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh)
    local big=fontFor(30*scale)
    local body=fontFor(23*scale)
    local small=fontFor(17*scale)
    local priceFont=fontFor(22*scale)
    local moneyFont=fontFor(23*scale)
    local w=math.min(sw*.82,1220*scale)
    local h=math.min(sh*.82,720*scale)
    local x=sx+(sw-w)/2
    local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.97)

    drawText("POKé MART",big,x+22*scale,y+14*scale,w*.45,"left",c.text)
    drawText(("MONEY  ¥%d"):format(type(mart.money)=="function" and mart:money() or 0),
      moneyFont,x+w*.52,y+18*scale,w*.43,"right",c.accent)

    local phase=tostring(mart.phase or "top")
    local contentY=y+65*scale
    local contentH=h-120*scale

    if phase=="top" or phase=="intro" or phase=="outro" then
      local opts={"BUY","SELL","QUIT"}
      local mw=w*.34
      for i,label in ipairs(opts) do
        local rh=58*scale
        local yy=contentY+(i-1)*(rh+8*scale)
        if phase=="top" and i==(mart.topIndex or 1) then
          color(c.selected); G.rectangle("fill",x+24*scale,yy,mw,rh,6,6)
        end
        drawText(label,body,x+42*scale,yy+(rh-body:getHeight())*.42,
          mw-36*scale,"left",
          phase=="top" and i==(mart.topIndex or 1) and c.text or c.muted)
      end
      local lines=martMessageLines(mart)
      panel(x+w*.41,contentY,w*.54,contentH*.60,c,.72)
      for i,line in ipairs(lines) do
        drawText(line,body,x+w*.44,contentY+22*scale+(i-1)*(body:getHeight()+8*scale),
          w*.48,"left",c.text)
      end
    elseif phase=="sell" and mart.pack then
      local pack=mart.pack
      local rows=pack.rows or {}
      local idx=tonumber(pack.index) or 1
      local scroll=tonumber(pack.scroll) or 0
      local visible=7
      local listW=w*.55
      local rowH=contentH/visible
      for slot=1,visible do
        local i=scroll+slot
        local row=rows[i]
        if not row then break end
        local yy=contentY+(slot-1)*rowH
        if i==idx then
          color(c.selected); G.rectangle("fill",x+22*scale,yy,listW-36*scale,rowH-5*scale,6,6)
        end
        drawText(row.name or row.id or "ITEM",body,x+38*scale,
          yy+(rowH-body:getHeight())*.35,listW*.62,"left",
          i==idx and c.text or c.muted)
        drawText("x"..tostring(row.count or 0),priceFont,x+listW*.69,
          yy+(rowH-priceFont:getHeight())*.40,listW*.21,"right",
          i==idx and c.text or c.muted)
      end
      drawText("SELL",big,x+listW,contentY,w-listW-30*scale,"center",c.accent)
      drawText("Choose an item to sell.",body,x+listW+18*scale,
        contentY+80*scale,w-listW-40*scale,"left",c.muted)
    else
      local entries=mart.entries or {}
      local idx=tonumber(mart.index) or 1
      local scroll=tonumber(mart.scroll) or 0
      local listW=w*.55
      local visible=6
      local rowH=contentH/visible
      for slot=1,visible do
        local i=scroll+slot
        local entry=entries[i]
        local isCancel=(not entry and i==#entries+1)
        if not entry and not isCancel then break end
        local yy=contentY+(slot-1)*rowH
        if i==idx then
          color(c.selected); G.rectangle("fill",x+22*scale,yy,listW-36*scale,rowH-5*scale,6,6)
        end
        local label=entry and entry.name or "CANCEL"
        drawText(label,body,x+38*scale,
          yy+(rowH-body:getHeight())*.35,listW*.62,"left",
          i==idx and c.text or c.muted)
        if entry then
          drawText(("¥%d"):format(entry.price or 0),priceFont,x+listW*.67,
            yy+(rowH-priceFont:getHeight())*.40,listW*.22,"right",
            i==idx and c.text or c.muted)
        end
      end

      local selected=type(mart.selected)=="function" and mart:selected() or nil
      local rx=x+listW+18*scale
      local rw=w-listW-42*scale
      drawText(selected and selected.name or "POKé MART",big,rx,contentY+8*scale,rw,"left",c.text)
      local desc=type(mart.description)=="function" and mart:description() or nil
      if type(desc)=="table" then desc=table.concat(desc," ") end
      if type(desc)=="string" then
        -- Crystal item descriptions retain the original game's <NEXT>
        -- control marker in extracted text. Native MartMenu treats it as the
        -- second description line; Modern UI should do the same rather than
        -- showing "<NEXT>" to the player.
        desc=desc:gsub("<NEXT>","\n")
      end
      drawText(desc or "Choose an item.",body,rx,contentY+70*scale,rw,"left",c.muted)

      if phase=="buyQuantity" or phase=="sellQuantity" then
        local total=0
        local item=mart.qtyItem
        if item then
          if phase=="buyQuantity" and type(MartMenu.buyPrice)=="function" then
            total=MartMenu.buyPrice(item.price,mart.qty)
          elseif type(MartMenu.sellPrice)=="function" then
            total=MartMenu.sellPrice(item.price,mart.qty)
          end
        end
        panel(rx,contentY+190*scale,rw,100*scale,c,.86)
        drawText(("QTY   %d"):format(mart.qty or 1),body,
          rx+18*scale,contentY+210*scale,rw*.42,"left",c.text)
        drawText(("TOTAL   ¥%d"):format(total),body,
          rx+rw*.44,contentY+210*scale,rw*.50,"right",c.accent)
      end
    end

    if mart.message or mart.confirm then
      local lines=martMessageLines(mart)
      local dh=math.max(140*scale,body:getHeight()*2+46*scale)
      local dy=y+h-dh-18*scale
      panel(x+18*scale,dy,w-36*scale,dh,c,.99)
      for i,line in ipairs(lines) do
        if i>2 then break end
        drawText(line,body,x+42*scale,
          dy+20*scale+(i-1)*(body:getHeight()+8*scale),
          w-84*scale,"left",c.text)
      end
      if mart.confirm and type(mart.yesNoVisible)=="function" and mart:yesNoVisible() then
        local cw=250*scale; local ch=104*scale
        local cx=x+w-cw-32*scale; local cy=dy-ch-10*scale
        panel(cx,cy,cw,ch,c,.99)
        for i,label in ipairs({"YES","NO"}) do
          local yy=cy+10*scale+(i-1)*44*scale
          if i==(mart.confirm.choice or 1) then
            color(c.selected); G.rectangle("fill",cx+8*scale,yy,cw-16*scale,40*scale,5,5)
          end
          drawText(label,body,cx+24*scale,yy+4*scale,cw-42*scale,"left",
            i==(mart.confirm.choice or 1) and c.text or c.muted)
        end
      end
    end

    drawText("A CHOOSE   B BACK",small,x+22*scale,y+h-small:getHeight()-12*scale,
      w-44*scale,"left",c.muted)
  end

  -- Crystal's NEW GAME gender prompt is its own full-screen state rather than
  -- a TextBox/ChoiceBox pair.  Present it through the same Modern dialogue
  -- language while leaving GenderSelect:update/choose/onDone completely native.
  -- The master MODERN UI toggle remains authoritative; DIALOGUE UI can further
  -- opt this surface back to vanilla without affecting the rest of Modern UI.
  local function isGenderSelect(state)
    return okGender and type(state)=="table" and getmetatable(state)==GenderSelect
  end

  local function genderVisibleText(state)
    if okTyper and Typer and type(Typer.text)=="function" then
      local ok,lines=pcall(Typer.text,state,{})
      if ok and type(lines)=="table" then
        local value=table.concat(lines,"\n")
        if value~="" then return value end
      end
    end
    return tostring(state and state.text or "Are you a boy?\nOr are you a girl?")
  end

  local function drawGenderSelect(state)
    local c=theme()
    local ww,wh=G.getDimensions()
    -- Keep the original Crystal gender-screen field color behind the Modern
    -- cards so the screen still belongs visually to the New Game sequence.
    color({1,1,1,1},1)
    G.rectangle("fill",0,0,ww,wh)
    local sx,sy,sw,sh=playfield()
    local ground=(GenderSelect and GenderSelect.GROUND) or {74,247,255}
    local gr=(ground[1] or 74); local gg=(ground[2] or 247); local gb=(ground[3] or 255)
    if gr>1 or gg>1 or gb>1 then gr,gg,gb=gr/255,gg/255,gb/255 end
    color({gr,gg,gb,1},1)
    G.rectangle("fill",sx,sy,sw,sh)

    local scale=uiScale(sw,sh)
    local body=fontFor(30*scale)
    local small=fontFor(20*scale)
    local title=fontFor(24*scale)

    local dialogW=math.min(sw*.88,1180*scale)
    local dialogH=math.max(150*scale,body:getHeight()*2+58*scale)
    local dialogX=sx+(sw-dialogW)/2
    local dialogY=sy+sh-dialogH-math.max(18*scale,sh*.03)
    panel(dialogX,dialogY,dialogW,dialogH,c,.98)
    drawText(genderVisibleText(state),body,
      dialogX+28*scale,dialogY+22*scale,dialogW-56*scale,"left",c.text)

    -- The native menu opens only after the typewriter finishes and its short
    -- four-frame delay.  Mirror that timing instead of exposing the answers
    -- early just because Modern UI owns the presentation.
    local menuOpen=true
    if state and type(state.menuOpen)=="function" then
      local ok,v=pcall(state.menuOpen,state)
      menuOpen=ok and v or false
    end
    if not menuOpen then
      drawText("...",small,dialogX+28*scale,
        dialogY+dialogH-small:getHeight()-18*scale,
        dialogW-56*scale,"right",c.muted)
      return
    end

    local rows=GenderSelect and GenderSelect.OPTIONS or {
      {label="Boy"},{label="Girl"},
    }
    local rowH=math.max(58*scale,body:getHeight()+18*scale)
    local choiceW=math.min(sw*.42,470*scale)
    local choiceH=54*scale+#rows*rowH+18*scale
    local choiceX=sx+(sw-choiceW)/2
    -- Center the selector in the free space above the lower dialogue card.
    local freeTop=sy+16*scale
    local freeBottom=dialogY-14*scale
    local choiceY=freeTop+math.max(0,(freeBottom-freeTop-choiceH)/2)
    panel(choiceX,choiceY,choiceW,choiceH,c,.99)
    drawText("PLAYER",title,choiceX+22*scale,choiceY+14*scale,
      choiceW-44*scale,"left",c.accent)
    local selected=tonumber(state and state.cursor) or 1
    for i,row in ipairs(rows) do
      local yy=choiceY+48*scale+(i-1)*rowH
      if i==selected then
        color(c.selected)
        G.rectangle("fill",choiceX+12*scale,yy,choiceW-24*scale,rowH-5*scale,6,6)
        color(c.accent)
        G.rectangle("fill",choiceX+12*scale,yy,4*scale,rowH-5*scale,2,2)
      end
      drawText(resolveLabel(type(row)=="table" and row.label or row),body,
        choiceX+30*scale,yy+(rowH-body:getHeight())*.42,
        choiceW-60*scale,"left",i==selected and c.text or c.muted)
    end
  end


  -- NEW GAME continues through several Gen 2-owned full-screen states after
  -- Crystal's gender question.  Keep all of their state machines native and
  -- replace presentation only, so MODERN UI OFF always falls straight back to
  -- the original G/S/C screens.
  local function isInitClock(state)
    return okClock and type(state)=="table" and getmetatable(state)==InitClock
  end
  local function isOakSpeech(state)
    return okOak and type(state)=="table" and getmetatable(state)==OakSpeech
  end
  local function isNamePick(state)
    return okNamePick and type(state)=="table" and getmetatable(state)==NamePick
  end
  local function isNamingScreen(state)
    return okNaming and type(state)=="table" and getmetatable(state)==NamingScreen
  end

  local function visibleTyperText(state, fallback)
    if okTyper and Typer and type(Typer.text)=="function" then
      local ok,lines=pcall(Typer.text,state,{})
      if ok and type(lines)=="table" then
        local value=table.concat(lines,"\n")
        if value~="" then return value end
      end
    end
    if state and type(state.pageText)=="function" then
      local ok,value=pcall(state.pageText,state)
      if ok and value then return tostring(value) end
    end
    return tostring(fallback or "")
  end

  local function drawInitClock(state)
    local c=theme()
    local ww,wh=G.getDimensions()
    local sx,sy,sw,sh=playfield()

    -- InitClock is opaque during NEW GAME.  Paint a deliberate Modern backdrop
    -- instead of letting the hidden vanilla screen reveal OakSpeech beneath it.
    if tostring(state.mode or "clock")~="day" then
      color({0.015,0.02,0.035,1},1)
      G.rectangle("fill",0,0,ww,wh)
    end

    local scale=uiScale(sw,sh)
    local body=fontFor(30*scale)
    local small=fontFor(19*scale)
    local title=fontFor(22*scale)

    local question=""
    if type(state.question)=="function" then
      local ok,value=pcall(state.question,state)
      if ok and value then question=value end
    end
    question=visibleTyperText(state,question)

    local dialogW=math.min(sw*.88,1180*scale)
    local dialogH=math.max(145*scale,body:getHeight()*2+54*scale)
    local dialogX=sx+(sw-dialogW)/2
    local dialogY=sy+sh-dialogH-math.max(18*scale,sh*.03)
    panel(dialogX,dialogY,dialogW,dialogH,c,.98)
    drawText(question,body,dialogX+28*scale,dialogY+20*scale,
      dialogW-56*scale,"left",c.text)

    local phase=tostring(state.phase or "")
    local display=nil
    if type(state.display)=="function" then
      local ok,value=pcall(state.display,state)
      if ok then display=value end
    end

    if phase=="hour" or phase=="minute" or phase=="day" then
      local cardW=math.min(sw*.44,520*scale)
      local cardH=190*scale
      local cardX=sx+(sw-cardW)/2
      local freeBottom=dialogY-14*scale
      local cardY=sy+math.max(18*scale,(freeBottom-sy-cardH)/2)
      panel(cardX,cardY,cardW,cardH,c,.99)
      drawText(phase=="day" and "DAY" or "TIME",title,
        cardX+22*scale,cardY+15*scale,cardW-44*scale,"left",c.accent)
      drawText("▲",small,cardX,cardY+53*scale,cardW,"center",c.muted)
      drawText(tostring(display or ""),body,
        cardX+24*scale,cardY+79*scale,cardW-48*scale,"center",c.text)
      drawText("▼",small,cardX,cardY+132*scale,cardW,"center",c.muted)
      drawText("UP/DOWN CHANGE   A CONFIRM",small,
        cardX+18*scale,cardY+cardH-small:getHeight()-12*scale,
        cardW-36*scale,"center",c.muted)
    elseif phase=="confirm-hour" or phase=="confirm-minute"
        or phase=="confirm-day" then
      local labels={"YES","NO"}
      local selected=tonumber(state.yesNo) or 1
      local rowH=math.max(54*scale,body:getHeight()+16*scale)
      local cardW=math.min(sw*.38,410*scale)
      local cardH=46*scale+#labels*rowH+14*scale
      local cardX=sx+(sw-cardW)/2
      local freeBottom=dialogY-14*scale
      local cardY=sy+math.max(18*scale,(freeBottom-sy-cardH)/2)
      panel(cardX,cardY,cardW,cardH,c,.99)
      drawText("CONFIRM",title,cardX+22*scale,cardY+13*scale,
        cardW-44*scale,"left",c.accent)
      for i,label in ipairs(labels) do
        local yy=cardY+43*scale+(i-1)*rowH
        if i==selected then
          color(c.selected)
          G.rectangle("fill",cardX+10*scale,yy,cardW-20*scale,rowH-5*scale,6,6)
          color(c.accent)
          G.rectangle("fill",cardX+10*scale,yy,4*scale,rowH-5*scale,2,2)
        end
        drawText(label,body,cardX+28*scale,
          yy+(rowH-body:getHeight())*.42,cardW-56*scale,"left",
          i==selected and c.text or c.muted)
      end
    end
  end

  local function drawNamePick(state)
    -- NamePick's wrapped native draw keeps only the moving player portrait.
    -- The actual list is redrawn here as a centered Modern card.
    if tostring(state.slide or "")=="in" then return end
    local c=theme()
    local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh)
    local body=fontFor(28*scale)
    local title=fontFor(22*scale)
    local items=type(state.items)=="table" and state.items or {}
    local rowH=math.max(52*scale,body:getHeight()+15*scale)
    local w=math.min(sw*.48,560*scale)
    local h=55*scale+#items*rowH+16*scale
    local x=sx+(sw-w)/2
    local y=sy+(sh-h)/2
    panel(x,y,w,h,c,.99)
    drawText("NAME",title,x+22*scale,y+15*scale,w-44*scale,"left",c.accent)
    local selected=tonumber(state.cursor) or 1
    for i,item in ipairs(items) do
      local yy=y+50*scale+(i-1)*rowH
      if i==selected then
        color(c.selected)
        G.rectangle("fill",x+10*scale,yy,w-20*scale,rowH-5*scale,6,6)
        color(c.accent)
        G.rectangle("fill",x+10*scale,yy,4*scale,rowH-5*scale,2,2)
      end
      local label=(i==1) and resolveLabel(item) or tostring(item or "")
      drawText(label,body,x+30*scale,yy+(rowH-body:getHeight())*.42,
        w-60*scale,"left",i==selected and c.text or c.muted)
    end
  end

  local function drawNamingScreen(state)
    local c=theme()
    local ww,wh=G.getDimensions()
    color(c.surface or {0.06,0.08,0.12,1},1)
    G.rectangle("fill",0,0,ww,wh)
    local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh)
    local body=fontFor(24*scale)
    local small=fontFor(17*scale)
    local title=fontFor(21*scale)

    local x,y,w,h
    if Style and Style.panelBox then
      x,y,w,h,scale=Style.panelBox(sx,sy,sw,sh,1100,780,.92,.92)
    else
      w=sw*.90; h=sh*.90; x=sx+(sw-w)/2; y=sy+(sh-h)/2
    end
    panel(x,y,w,h,c,.99)
    local pad=24*scale

    local prompt=state.monName
      and (tostring(state.monName).."'S NICKNAME?")
      or resolveLabel(state.prompt or "YOUR NAME?")
    drawText(prompt,title,x+pad,y+18*scale,w-pad*2,"left",c.accent)

    local maxLen=tonumber(state.maxLength) or 7
    local entered=tostring(state.text or "")
    local shown=entered
    for _=#entered+1,maxLen do shown=shown.."_" end
    drawText(shown,body,x+pad,y+58*scale,w-pad*2,"left",c.text)

    local grid=type(state.rows)=="function" and state:rows() or {}
    local rows=#grid
    local kbTop=y+112*scale
    local bottomArea=70*scale
    local kbH=h-(kbTop-y)-bottomArea-18*scale
    local cellW=(w-pad*2)/9
    local cellH=math.max(36*scale,kbH/math.max(1,rows))
    local selectedRow=tonumber(state.row) or 0
    local selectedCol=tonumber(state.col) or 0
    local onBottom=type(state.onBottomRow)=="function" and state:onBottomRow()

    for r=1,rows do
      local line=grid[r] or {}
      for col=1,9 do
        local cx=x+pad+(col-1)*cellW
        local cy=kbTop+(r-1)*cellH
        if not onBottom and selectedRow==r-1 and selectedCol==col-1 then
          color(c.selected)
          G.rectangle("fill",cx+2*scale,cy+2*scale,cellW-4*scale,cellH-4*scale,5,5)
        end
        local ch=line[col]
        if ch and ch~="" and ch~=" " then
          drawText(resolveLabel(ch),body,cx,cy+(cellH-body:getHeight())*.42,
            cellW,"center",
            (not onBottom and selectedRow==r-1 and selectedCol==col-1)
              and c.text or c.muted)
        end
      end
    end

    local bottomY=y+h-bottomArea
    local labels={state.lower and "UPPER" or "lower","DEL","END"}
    local target=type(state.bottomTarget)=="function" and state:bottomTarget() or 1
    local bw=(w-pad*2)/3
    for i,label in ipairs(labels) do
      local bx=x+pad+(i-1)*bw
      if onBottom and i==target then
        color(c.selected)
        G.rectangle("fill",bx+3*scale,bottomY+3*scale,bw-6*scale,
          bottomArea-10*scale,5,5)
      end
      drawText(label,small,bx,bottomY+(bottomArea-small:getHeight())*.45,
        bw,"center",onBottom and i==target and c.text or c.muted)
    end
  end

  local function drawOakShrink(state)
    local lines=state and state.shrinkText
    if type(lines)~="table" or #lines==0 then return end
    local c=theme()
    local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh)
    local body=fontFor(28*scale)
    local w=math.min(sw*.88,1180*scale)
    local h=math.max(145*scale,body:getHeight()*2+54*scale)
    local x=sx+(sw-w)/2
    local y=sy+sh-h-math.max(18*scale,sh*.03)
    panel(x,y,w,h,c,.98)
    for i=1,math.min(2,#lines) do
      drawText(lines[i],body,x+28*scale,
        y+20*scale+(i-1)*(body:getHeight()+8*scale),
        w-56*scale,"left",c.text)
    end
  end

  -- Preserve the native NamePick portrait/slide animation while suppressing
  -- only its white legacy list box when Modern MENU UI owns that surface.
  if okNamePick and NamePick and type(NamePick.drawPanel)=="function"
      and not NamePick.__kimModernNewGameDrawWrapped then
    local oldDrawPanel=NamePick.drawPanel
    NamePick.drawPanel=function(self,...)
      if menuEnabled() and hideOriginal() then
        if okChrome and Chrome and type(Chrome.clear)=="function" then
          Chrome.clear()
        end
        if type(self.drawPic)=="function" then self:drawPic() end
        return
      end
      return oldDrawPanel(self,...)
    end
    NamePick.__kimModernNewGameDrawWrapped=true
  end

  -- Oak's final shrink beat paints its last two lines directly inside
  -- OakSpeech instead of pushing a TextBox.  Temporarily suppress only that
  -- legacy text box; the Oak/player artwork and shrink animation remain native.
  if okOak and OakSpeech and type(OakSpeech.drawPanel)=="function"
      and not OakSpeech.__kimModernShrinkDrawWrapped then
    local oldOakDrawPanel=OakSpeech.drawPanel
    OakSpeech.drawPanel=function(self,...)
      if dialogueEnabled() and hideOriginal() and self.shrinkText then
        local saved=self.shrinkText
        self.shrinkText=nil
        local result={oldOakDrawPanel(self,...)}
        self.shrinkText=saved
        return unpackCompat(result)
      end
      return oldOakDrawPanel(self,...)
    end
    OakSpeech.__kimModernShrinkDrawWrapped=true
  end

  -- Battle-specific vanilla dialogue surfaces not represented by TextBox.
  local BATTLE_DIALOG_PHASE = {
    ["stats-box"]=true,
    ["ask-nickname"]=true,
    ["ask-forget"]=true,
    ["stop-learning"]=true,
    ["ask-shift"]=true,
    ["ask-next-mon"]=true,
  }

  local function battleChoiceIndex(state)
    local p=tostring(state.phase or "")
    if p=="ask-nickname" then return state.nicknameIndex or 1 end
    if p=="ask-shift" then return state.shiftIndex or 1 end
    if p=="ask-next-mon" then return state.nextMonIndex or 1 end
    return state.forgetChoice or 1
  end

  local function drawBattleSpecial(state)
    local c=theme()
    local sx,sy,sw,sh=playfield()
    local scale=uiScale(sw,sh)
    local body=fontFor(28*scale)
    local small=fontFor(18*scale)

    local w=math.min(sw*.88,1480*scale)
    local dh=math.max(145*scale,body:getHeight()*2+52*scale)
    local x=sx+(sw-w)/2
    local y=sy+sh-dh-20*scale
    panel(x,y,w,dh,c,.98)

    local lines={}
    if type(state.messageLines)=="function" then
      local ok,v=pcall(state.messageLines,state)
      if ok and type(v)=="table" then lines=v end
    end
    if #lines==0 and state.message then
      for line in tostring(state.message):gmatch("[^\n\r]+") do lines[#lines+1]=line end
    end
    for i,line in ipairs(lines) do
      if i>2 then break end
      drawText(line,body,x+28*scale,y+20*scale+(i-1)*(body:getHeight()+8*scale),
        w-56*scale,"left",c.text)
    end

    if tostring(state.phase)=="stats-box" and state.statsBoxMon then
      local mon=state.statsBoxMon
      local stats=mon.stats or {}
      local cardW=math.min(500*scale,sw*.32)
      local cardH=330*scale
      local cx=sx+sw-cardW-35*scale
      local cy=sy+28*scale
      panel(cx,cy,cardW,cardH,c,.99)
      drawText((mon.nickname or mon.name or mon.species or "POKéMON").."  STATS",
        body,cx+20*scale,cy+16*scale,cardW-40*scale,"left",c.text)
      local rows={
        {"ATTACK",stats.attack},{"DEFENSE",stats.defense},
        {"SPCL. ATK",stats.specialAttack or stats.special},
        {"SPCL. DEF",stats.specialDefense or stats.special},
        {"SPEED",stats.speed},
      }
      local yy=cy+70*scale
      for _,row in ipairs(rows) do
        drawText(row[1],small,cx+26*scale,yy,cardW*.62,"left",c.muted)
        drawText(tostring(row[2] or 0),body,cx+cardW*.62,yy-4*scale,
          cardW*.29,"right",c.text)
        yy=yy+48*scale
      end
    elseif tostring(state.phase):match("^ask") or tostring(state.phase)=="stop-learning" then
      local cw=260*scale
      local ch=112*scale
      local cx=x+w-cw-18*scale
      local cy=y-ch-10*scale
      panel(cx,cy,cw,ch,c,.99)
      local idx=battleChoiceIndex(state)
      for i,label in ipairs({"YES","NO"}) do
        local yy=cy+10*scale+(i-1)*46*scale
        if i==idx then
          color(c.selected); G.rectangle("fill",cx+8*scale,yy,cw-16*scale,42*scale,5,5)
        end
        drawText(label,body,cx+24*scale,yy+4*scale,cw-40*scale,"left",
          i==idx and c.text or c.muted)
      end
    end
  end

  -- Remember title/kind for generic script menus without changing their logic.
  if okScript and ScriptMenu and type(ScriptMenu.new)=="function"
      and not ScriptMenu.__kimModernDialogNewWrapped then
    local oldNew=ScriptMenu.new
    ScriptMenu.new=function(game,opts)
      local self=oldNew(game,opts)
      opts=opts or {}
      self._kimTitle=opts.title or opts.kind or "CHOOSE"
      return self
    end
    ScriptMenu.__kimModernDialogNewWrapped=true
  end

  -- Mart buy mode is natively opaque; KIM wants it over the overworld.
  if okMart and MartMenu and type(MartMenu.update)=="function"
      and not MartMenu.__kimModernDialogUpdateWrapped then
    local oldUpdate=MartMenu.update
    MartMenu.update=function(self,...)
      local result={oldUpdate(self,...)}
      if menuEnabled() and hideOriginal() then self.isOpaque=false end
      return unpackCompat(result)
    end
    local oldNew=MartMenu.new
    MartMenu.new=function(game,opts)
      local self=oldNew(game,opts)
      if menuEnabled() and hideOriginal() then self.isOpaque=false end
      return self
    end
    MartMenu.__kimModernDialogUpdateWrapped=true
  end

  local function isText(state)
    return type(state)=="table" and (state.isTextBox==true or getmetatable(state)==TextBox)
  end
  local function isChoice(state)
    return type(state)=="table" and getmetatable(state)==ChoiceBox
  end
  local function isScript(state)
    return okScript and type(state)=="table" and getmetatable(state)==ScriptMenu
  end
  local function isMart(state)
    return okMart and type(state)=="table" and getmetatable(state)==MartMenu
  end
  local function isBattleSpecial(state)
    return okBattle and type(state)=="table" and getmetatable(state)==BattleState
      and BATTLE_DIALOG_PHASE[tostring(state.phase or "")] == true
  end

  local function findTextBelow(game)
    local states=game and game.stack and game.stack.states
    if type(states)~="table" then return nil end
    for i=#states,1,-1 do
      if isText(states[i]) then return states[i] end
    end
    return nil
  end

  if mod.hooks and type(mod.hooks.wrap)=="function" then
    mod.hooks:wrap("screen.render_visible",function(nextFn,state)
      if hideOriginal() and (
          (dialogueEnabled() and
            (isText(state) or isChoice(state) or isGenderSelect(state)
              or isInitClock(state)))
          or (menuEnabled() and
            (isScript(state) or isMart(state) or isNamingScreen(state)))) then
        return false
      end
      return nextFn(state)
    end,45000)

    -- Battle level-up / YES-NO phases are drawn inside BattleState.drawBottom,
    -- so hide that whole native lower surface and redraw it in Modern UI.
    mod.hooks:wrap("battle.bottom_ui_visible",function(nextFn,state)
      if dialogueEnabled() and hideOriginal() and isBattleSpecial(state) then return false end
      return nextFn(state)
    end,45000)

    mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
      local result={pcall(nextFn,game,viewport)}
      local ok=table.remove(result,1)
      if not ok then error(result[1],0) end

      if not (dialogueEnabled() or menuEnabled()) then return unpackCompat(result) end

      local top=game and game.stack and type(game.stack.top)=="function"
        and game.stack:top() or nil

      G.push("all")
      G.origin()
      if dialogueEnabled() and isGenderSelect(top) then
        drawGenderSelect(top)
      elseif dialogueEnabled() and isInitClock(top) then
        drawInitClock(top)
      elseif menuEnabled() and isNamingScreen(top) then
        drawNamingScreen(top)
      elseif menuEnabled() and isNamePick(top) then
        drawNamePick(top)
      elseif dialogueEnabled() and isChoice(top) then
        local box=findTextBelow(game)
        if box then drawDialogBox(box,top) else drawBareChoice(top) end
      elseif dialogueEnabled() and isText(top) then
        drawDialogBox(top,nil)
      elseif menuEnabled() and isScript(top) then
        drawScriptMenu(top)
      elseif menuEnabled() and isMart(top) then
        drawMart(top)
      elseif dialogueEnabled() and isOakSpeech(top) and top.shrinkText then
        drawOakShrink(top)
      elseif dialogueEnabled() and isBattleSpecial(top) then
        drawBattleSpecial(top)
      end
      G.pop()

      return unpackCompat(result)
    end,45000)
  end

  mod.exports.gen2ModernDialogs={
    apiVersion=1,
    active=function() return dialogueEnabled() or menuEnabled() end,
  }
  return true
end
