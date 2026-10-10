-- Kanto in Motion - Gen 3 Modern Pokemon Summary v55
--
-- Presentation-only replacement for FR/LG/E Summary screens. Game3 continues
-- to own all Summary state/input/page switching/move swapping/contest toggles.
return function(mod)
  local unpack = table.unpack or unpack
  if not (love and love.graphics and mod and mod.hooks and type(mod.hooks.wrap)=="function") then
    return false
  end

  local G=love.graphics
  local Style=mod._kantoInMotionGen3Ui
  local okSummary,Summary=pcall(require,"src.ui.game3.summary_menu")
  local okPokemon,Pokemon=pcall(require,"src.core.game3.pokemon")
  local okData,SummaryData=pcall(require,"src.core.game3.summary_data")
  local okTypes,Types=pcall(require,"src.core.game3.battle.types")
  local okStack,Stack=pcall(require,"src.ui.game3.stack")
  local okRse,RseSummary=pcall(require,"src.ui.game3.rse.summary_menu")
  local okBattleChrome,BattleChrome=pcall(require,"src.ui.game3.battle_chrome")
  if not (okSummary and type(Summary)=="table" and okPokemon and type(Pokemon)=="table") then return false end

  local FALLBACK={
    surface={0.075,0.105,0.17,1}, raised={0.12,0.17,0.27,1},
    selected={0.18,0.43,0.72,1}, accent={0.48,0.86,1,1},
    frame={0.48,0.86,1,1}, frameShadow={0.01,0.02,0.04,0.42},
    text={0.96,0.98,1,1}, muted={0.74,0.82,0.92,1}, divider={0.38,0.50,0.68,0.94},
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
    c=c or {1,1,1,1}; G.setColor(c[1] or 1,c[2] or 1,c[3] or 1,a==nil and (c[4] or 1) or a)
  end
  local function font(px)
    if Style and Style.font then return Style.font(px) end
    px=math.max(9,math.floor((tonumber(px) or 12)+0.5))
    if fonts[px] then return fonts[px] end
    local ok,f=pcall(G.newFont,px)
    if ok and f then
      if type(f.setFilter)=="function" then pcall(f.setFilter,f,"nearest","nearest") end
      fonts[px]=f; return f
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
    local suf="..."; local target=math.max(0,maxW-f:getWidth(suf))
    while #v>0 and f:getWidth(v)>target do v=v:sub(1,#v-1) end
    return v..suf
  end
  local function playfield(viewport)
    local x=tonumber(viewport and viewport.gameX) or 0
    local y=tonumber(viewport and viewport.gameY) or 0
    local w=tonumber(viewport and viewport.gameWidth)
    local h=tonumber(viewport and viewport.gameHeight)
    if w and h and w>0 and h>0 then return x,y,w,h end
    local ww,wh=G.getDimensions(); local s=math.min(ww/240,wh/160)
    return (ww-240*s)*0.5,(wh-160*s)*0.5,240*s,160*s
  end
  local function card(x,y,w,h,fill,line,r)
    r=r or math.max(4,math.min(w,h)*0.04)
    local pa=Style and Style.panelOpacity and Style.panelOpacity(1) or 1
    color(fill,math.min(1,(fill and fill[4] or 1)*pa),false); G.rectangle("fill",x,y,w,h,r,r)
    if line then color(line,nil,true); G.setLineWidth(math.max(1,math.min(w,h)*0.008)); G.rectangle("line",x+.5,y+.5,math.max(0,w-1),math.max(0,h-1),r,r) end
  end
  local function chevron(cx,cy,size,dir,c)
    size=math.max(4,tonumber(size) or 8)
    color(c); G.setLineWidth(math.max(1,size*.14))
    if dir=="left" then G.line(cx+size*.28,cy-size*.38,cx-size*.24,cy,cx+size*.28,cy+size*.38)
    elseif dir=="right" then G.line(cx-size*.28,cy-size*.38,cx+size*.24,cy,cx-size*.28,cy+size*.38)
    elseif dir=="up" then G.line(cx-size*.38,cy+size*.24,cx,cy-size*.24,cx+size*.38,cy+size*.24)
    else G.line(cx-size*.38,cy-size*.24,cx,cy+size*.24,cx+size*.38,cy-size*.24) end
  end
  -- The configured UI fonts do not consistently contain the Unicode male/female
  -- glyphs. Draw the symbols as vector UI marks instead of falling back to M/F.
  local function genderSymbol(cx,cy,size,g,c)
    size=math.max(7,tonumber(size) or 10)
    color(c); G.setLineWidth(math.max(1,size*.12))
    local r=size*.22
    if g=="M" then
      local ox,oy=cx-size*.10,cy+size*.08
      G.circle("line",ox,oy,r)
      local ex,ey=cx+size*.34,cy-size*.34
      G.line(ox+r*.72,oy-r*.72,ex,ey)
      G.line(ex-size*.18,ey,ex,ey,ex,ey+size*.18)
    elseif g=="F" then
      local ox,oy=cx,cy-size*.12
      G.circle("line",ox,oy,r)
      local stemTop=oy+r
      local stemBottom=cy+size*.34
      G.line(ox,stemTop,ox,stemBottom)
      G.line(ox-size*.18,cy+size*.16,ox+size*.18,cy+size*.16)
    end
  end
  local function isEmeraldUi()
    if okBattleChrome and BattleChrome and type(BattleChrome.isRse)=="function" then
      local ok,v=pcall(BattleChrome.isRse); if ok then return v==true end
    end
    return false
  end
  local function modernWindow(viewport,c)
    local sx,sy,sw,sh=playfield(viewport)
    local roomy=sw>=720 and sh>=460
    local userScale=uiScaleFactor()
    local w=math.min(sw*.97,sw*(roomy and 0.82 or 0.95)*userScale)
    local h=math.min(sh*.97,sh*(roomy and 0.88 or 0.94)*userScale)
    if Style and Style.layoutStyle and Style.layoutStyle()=="full" then w=sw*.94; h=sh*.92 end
    local x=sx+(sw-w)*0.5; local y=sy+(sh-h)*0.5
    -- Keep the live field/battle backdrop unobscured. A playfield-sized scrim
    -- becomes a visible translucent rectangle on widescreen output.
    local r=math.max(7,math.min(w,h)*0.018)
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
  local function setFloating(on)
    if not (okStack and Stack and type(Stack._layers)=="table") then return end
    for i=#Stack._layers,1,-1 do
      local layer=Stack._layers[i]
      if layer and layer.id=="summary" then
        if on then
          if layer._kimGen3SummaryOriginal==nil then
            layer._kimGen3SummaryOriginal={hideBelow=layer.hideBelow,drawUnder=layer.drawUnder,fullscreen=layer.fullscreen}
          end
          layer.hideBelow=false; layer.drawUnder=true; layer.fullscreen=false
        elseif layer._kimGen3SummaryOriginal then
          local o=layer._kimGen3SummaryOriginal
          layer.hideBelow=o.hideBelow; layer.drawUnder=o.drawUnder; layer.fullscreen=o.fullscreen
          layer._kimGen3SummaryOriginal=nil
        end
        return
      end
    end
  end

  local function isOpen()
    if type(Summary.isOpen)=="function" then local ok,v=pcall(Summary.isOpen); return ok and v==true end
    return Summary.open==true
  end
  local function currentMon()
    local p=Summary._party; local i=tonumber(Summary._cursor) or 1
    return type(p)=="table" and p[i] or nil
  end
  local function monName(mon)
    if type(Pokemon.displayName)=="function" then local ok,v=pcall(Pokemon.displayName,mon); if ok and v then return tostring(v) end end
    return tostring(mon and (mon.nickname or mon.name or mon.species) or "POKéMON")
  end
  local function species(mon)
    if type(Pokemon.speciesOf)=="function" then local ok,v=pcall(Pokemon.speciesOf,mon); if ok then return v end end
    return mon and tonumber(mon.species or mon.speciesId)
  end
  local function speciesName(mon)
    local sp=species(mon)
    if sp and type(Pokemon.name)=="function" then local ok,v=pcall(Pokemon.name,sp); if ok and v then return tostring(v) end end
    return monName(mon)
  end
  local function isEgg(mon)
    return type(Pokemon.isEgg)=="function" and Pokemon.isEgg(mon) or (mon and mon.isEgg==true)
  end
  local function shiny(mon)
    if okData and SummaryData and type(SummaryData.isShiny)=="function" then local ok,v=pcall(SummaryData.isShiny,mon); return ok and v==true end
    return mon and mon.isShiny==true
  end
  local function typeName(id)
    if okTypes and Types and type(Types.name)=="function" then local ok,v=pcall(Types.name,id); if ok and v then return tostring(v) end end
    return tostring(id or "---")
  end
  local function monTypes(mon)
    local sp=species(mon)
    local t={}
    if sp and type(Pokemon.types)=="function" then local ok,v=pcall(Pokemon.types,sp); if ok and type(v)=="table" then t=v end end
    return tonumber(mon and mon.type1) or tonumber(t[1]) or 0,tonumber(mon and mon.type2) or tonumber(t[2])
  end
  local function statusName(mon)
    if not (okData and SummaryData and type(SummaryData.statusAilment)=="function") then return nil end
    local ok,n=pcall(SummaryData.statusAilment,mon); if not ok then return nil end
    return ({[1]="PSN",[2]="PAR",[3]="SLP",[4]="FRZ",[5]="BRN",[6]="PKRS",[7]="FNT"})[n]
  end

  local function drawHdPreview(mon,x,y,w,h)
    local provider=mod._kantoInMotionGen3HdAnimatedPreviewDraw
    if type(provider)=="function" then
      local ok,drawn=pcall(provider,mon,x,y,w,h)
      if ok and drawn then return true end
    end
    if type(Pokemon.monFrontPic)=="function" then
      local ok,p=pcall(Pokemon.monFrontPic,mon)
      if ok and type(p)=="table" and p.image then
        local iw,ih=p.w or p.image:getWidth(),p.h or p.image:getHeight()
        local sc=math.min(w/math.max(1,iw),h/math.max(1,ih),2.0)
        color({1,1,1,1}); G.draw(p.image,x+w*.5,y+h*.5,0,sc,sc,iw*.5,ih*.5)
        return true
      end
    end
    return false
  end

  local function hpColor(hp,maxHp)
    local f=(tonumber(hp) or 0)/math.max(1,tonumber(maxHp) or 1)
    if f<=.20 then return {0.93,.20,.18,1} elseif f<=.50 then return {.96,.70,.16,1} end
    return {.16,.78,.38,1}
  end
  local function bar(x,y,w,h,frac,fill,c)
    frac=math.max(0,math.min(1,tonumber(frac) or 0)); color(c.raised); G.rectangle("fill",x,y,w,h,h*.5,h*.5)
    color(fill); G.rectangle("fill",x+1,y+1,math.max(0,(w-2)*frac),math.max(1,h-2),h*.45,h*.45)
  end

  local function resolveMoveId(e)
    local raw=type(e)=="table" and (e.id or e.move or e.moveId or e.num or e.name or e[1]) or e
    local n=tonumber(raw); if n then return n end
    if type(raw)=="string" and type(Pokemon.battleMoveId)=="function" then local ok,v=pcall(Pokemon.battleMoveId,raw); if ok then return v end end
    if type(raw)=="string" then
      local okC,C=pcall(require,"src.core.game3.constants")
      if okC and C and C.of then local okT,t=pcall(C.of,Summary._playerState); if okT and t and t.id then local okI,v=pcall(t.id,t,"moves",raw); if okI then return v end end end
    end
    return nil
  end
  local function moveRows(mon)
    local out={}; local raw=mon and mon.moves or {}; local pp=mon and mon.pp or {}
    for i=1,4 do
      local e=raw[i]; local id=resolveMoveId(e)
      if id and id>0 then
        local def=type(Pokemon.battleMove)=="function" and Pokemon.battleMove(id) or nil
        local cur=type(e)=="table" and tonumber(e.pp) or tonumber(pp[i])
        local max=tonumber(mon.maxPp and mon.maxPp[i]) or tonumber(def and def.pp) or cur or 0
        local name=type(Pokemon.moveName)=="function" and Pokemon.moveName(id) or tostring(id)
        out[i]={id=id,name=name or tostring(id),pp=cur or max,maxPp=max,def=def}
      end
    end
    if (Summary._mode=="select_move" or Summary._moveToLearn) and Summary._moveToLearn then
      local id=resolveMoveId(Summary._moveToLearn)
      if id then
        local def=type(Pokemon.battleMove)=="function" and Pokemon.battleMove(id) or nil
        local max=tonumber(def and def.pp) or 0
        out[5]={id=id,name=(Pokemon.moveName and Pokemon.moveName(id)) or tostring(id),pp=max,maxPp=max,def=def,new=true}
      end
    end
    return out
  end
  local function moveDescription(row)
    if not row then return "" end
    if okData and SummaryData and type(SummaryData.moveDescription)=="function" then
      local ok,v=pcall(SummaryData.moveDescription,row.id,row.name); if ok and v then return tostring(v) end
    end
    return ""
  end
  local function ability(mon)
    local id=tonumber(mon and (mon.abilityId or mon.ability))
    local name=type(mon and mon.ability)=="string" and mon.ability or mon and mon.abilityName
    if (not id or id<=0) and type(Pokemon.abilityId)=="function" then local ok,v=pcall(Pokemon.abilityId,species(mon),mon and mon.personality or 0); if ok then id=v end end
    if (not name or name=="") and id and type(Pokemon.abilityName)=="function" then local ok,v=pcall(Pokemon.abilityName,id); if ok then name=v end end
    local desc=""
    if id and okData and SummaryData and type(SummaryData.abilityDescription)=="function" then local ok,v=pcall(SummaryData.abilityDescription,id,name); if ok and v then desc=tostring(v) end end
    return tostring(name or "---"),desc
  end
  local function contestMode()
    return okRse and RseSummary and type(RseSummary._st)=="table" and RseSummary._st.contest==true
  end

  local function drawTabs(x,y,w,h,c,f,page,contest)
    local labs={"INFO","SKILLS",contest and "CONTEST MOVES" or "BATTLE MOVES"}
    local active=(page==Summary.PAGE_INFO and 1) or (page==Summary.PAGE_SKILLS and 2) or 3
    local gap=w*.012; local tw=(w-gap*2)/3
    for i,lab in ipairs(labs) do
      local bx=x+(i-1)*(tw+gap)
      if i==active then card(bx,y,tw,h,c.selected,c.accent,3) else card(bx,y,tw,h,c.raised,c.divider,3) end
      text(lab,f,bx,y+(h-f:getHeight())*.5,tw,"center",i==active and c.text or c.muted)
    end
  end

  local function drawInfo(mon,c,fonts,rx,ry,rw,rh,s)
    local body,small=fonts.body,fonts.small
    local sp=species(mon); local dex=nil
    if type(Summary.dexNumber)=="function" then local ok,v=pcall(Summary.dexNumber,sp,Summary._playerState); if ok then dex=v end end
    local t1,t2=monTypes(mon)
    local natureName="---"
    if okData and SummaryData and type(SummaryData.nature)=="function" then local ok,_,n=pcall(SummaryData.nature,mon); if ok and n then natureName=tostring(n) end end
    local held="NONE"
    if type(Summary.heldItemText)=="function" then local ok,v=pcall(Summary.heldItemText,mon); if ok and v then held=tostring(v) end end
    local ot=tostring(mon.otName or mon.ot or mon.originalTrainer or "---")
    local id=tonumber(mon.otId or mon.trainerId) or 0
    local rows={
      {"DEX NO.",dex and string.format("%03d",dex) or "---"},
      {"SPECIES",speciesName(mon)},
      {"TYPE",typeName(t1)..((t2 and t2~=t1) and (" / "..typeName(t2)) or "")},
      {"OT",ot},
      {"ID NO.",string.format("%05d",id%65536)},
      {"ITEM",held},
      {"NATURE",natureName},
    }
    local rowH=rh*.10
    for i,r in ipairs(rows) do
      local yy=ry+(i-1)*rowH
      text(r[1],small,rx,yy,rw*.34,"left",c.muted)
      text(fit(r[2],body,rw*.62),body,rx+rw*.36,yy-1*s,rw*.64,"left",c.text)
    end
    local memo=""
    if okData and SummaryData and type(SummaryData.formatTrainerMemo)=="function" then
      local ok,v=pcall(SummaryData.formatTrainerMemo,mon,Summary._playerState,{enemyParty=Summary._enemyParty,owner=Summary._owner})
      if ok and type(v)=="table" then memo=table.concat(v," ") end
    end
    if memo~="" then
      local my=ry+rowH*7.25
      color(c.divider,.55); G.rectangle("fill",rx,my-3*s,rw,math.max(1,s))
      text(memo,small,rx,my+3*s,rw,"left",c.muted)
    end
  end

  local function drawSkills(mon,c,fonts,rx,ry,rw,rh,s)
    local body,small=fonts.body,fonts.small
    local hp=tonumber(mon.hp or mon.currentHp) or 0
    local maxHp=tonumber(mon.maxHp or mon.maxhp or (mon.stats and mon.stats.hp)) or 1
    text("HP",small,rx,ry,rw*.2,"left",c.muted)
    text(string.format("%d / %d",hp,maxHp),body,rx+rw*.25,ry-1*s,rw*.75,"right",c.text)
    bar(rx,ry+body:getHeight()+2*s,rw,math.max(4,2.5*s),hp/math.max(1,maxHp),hpColor(hp,maxHp),c)
    local st=mon.stats or {}
    local vals={
      {"ATTACK",mon.attack or mon.atk or st.attack or st.atk or 0},
      {"DEFENSE",mon.defense or mon.def or st.defense or st.def or 0},
      {"SP. ATK",mon.spAtk or mon.spatk or mon.spa or st.spAtk or st.spa or 0},
      {"SP. DEF",mon.spDef or mon.spdef or mon.spd or st.spDef or st.spd or 0},
      {"SPEED",mon.speed or mon.spe or st.speed or st.spe or 0},
    }
    local yy=ry+rh*.18; local rowH=rh*.095
    for _,r in ipairs(vals) do
      text(r[1],small,rx,yy,rw*.55,"left",c.muted)
      text(tostring(tonumber(r[2]) or 0),body,rx+rw*.55,yy-1*s,rw*.45,"right",c.text)
      yy=yy+rowH
    end
    local prog={totalExp=tonumber(mon.exp) or 0,expNeeded=0,progressPercent=0}
    if okData and SummaryData and type(SummaryData.expProgress)=="function" then
      local growth=type(Pokemon.growthRate)=="function" and Pokemon.growthRate(species(mon)) or nil
      local ok,v=pcall(SummaryData.expProgress,mon,growth); if ok and type(v)=="table" then prog=v end
    end
    -- Pull the EXP block upward so the progress bar has its own breathing
    -- room above the Ability row at larger UI/font scales.
    yy=ry+rh*.64
    text("EXP. POINTS",small,rx,yy,rw*.55,"left",c.muted); text(tostring(prog.totalExp or 0),body,rx+rw*.55,yy-1*s,rw*.45,"right",c.text)
    yy=yy+rowH
    text("NEXT LV.",small,rx,yy,rw*.55,"left",c.muted); text(tostring(prog.expNeeded or 0),body,rx+rw*.55,yy-1*s,rw*.45,"right",c.text)
    bar(rx,yy+body:getHeight()+2*s,rw,math.max(4,2.4*s),prog.progressPercent or 0,c.accent,c)
    local an,ad=ability(mon)
    yy=ry+rh*.88
    text("ABILITY",small,rx,yy,rw*.25,"left",c.muted); text(fit(an,body,rw*.70),body,rx+rw*.28,yy-1*s,rw*.72,"left",c.text)
    if ad~="" then text(ad,small,rx,yy+body:getHeight()+2*s,rw,"left",c.muted) end
  end

  local function drawMoves(mon,c,fonts,rx,ry,rw,rh,s,detail,contest)
    local body,small=fonts.body,fonts.small
    local moves=moveRows(mon); local cur=tonumber(Summary._moveCursor) or 1
    local swap=tonumber(Summary._swapSlot)
    local count=(Summary._mode=="select_move" and moves[5]) and 5 or 4
    local listH=detail and rh*.60 or rh*.82
    local rowH=listH/math.max(4,count)
    for i=1,count do
      local mv=moves[i]; local yy=ry+(i-1)*rowH
      local selected=detail and i==cur; local marked=swap and i==swap
      if selected or marked then
        color(selected and c.selected or c.raised,.98); G.rectangle("fill",rx,yy,rw,rowH*.90,4*s,4*s)
        if selected then color(c.accent); G.rectangle("fill",rx,yy,math.max(2,1.5*s),rowH*.90) end
      end
      if mv then
        local tid=mv.def and tonumber(mv.def.type) or 0
        text(typeName(tid),small,rx+5*s,yy+rowH*.16,rw*.23,"left",c.accent)
        text(fit(mv.name,body,rw*.48),body,rx+rw*.25,yy+rowH*.10,rw*.48,"left",c.text)
        text(string.format("%d/%d",mv.pp or 0,mv.maxPp or 0),small,rx+rw*.76,yy+rowH*.20,rw*.21,"right",c.muted)
      else
        text("---",body,rx+rw*.25,yy+rowH*.10,rw*.48,"left",c.muted)
      end
    end
    if detail then
      local mv=moves[cur]
      local dy=ry+listH+5*s
      color(c.divider,.6); G.rectangle("fill",rx,dy-4*s,rw,math.max(1,s))
      if mv then
        local def=mv.def or {}; local power=tonumber(def.power) or 0; local acc=tonumber(def.accuracy) or 0
        local summary=contest and "CONTEST MOVE" or string.format("TYPE %s    POW %s    ACC %s",typeName(tonumber(def.type) or 0),power>1 and power or "---",acc>0 and acc or "---")
        text(summary,small,rx,dy,rw,"left",c.accent)
        text(moveDescription(mv),small,rx,dy+small:getHeight()+4*s,rw,"left",c.muted)
      elseif cur==5 then
        text("CANCEL",body,rx,dy,rw,"center",c.muted)
      end
    end
  end

  local function drawSummary(viewport,c)
    if not isOpen() then return false end
    setFloating(true)
    local mon=currentMon(); if not mon then return false end
    local x,y,w,h=modernWindow(viewport,c); local s=math.min(w/240,h/160)
    local pad=math.max(8*s,w*.018); local header=math.max(31*s,h*.16); local footer=math.max(19*s,h*.12)
    local titleF, bodyF, smallF = font(9.6*s), font(7.8*s), font(5.7*s)
    local fontsT={title=titleF,body=bodyF,small=smallF}
    local page=tonumber(Summary._page) or Summary.PAGE_INFO
    local egg=(page==Summary.PAGE_EGG) or isEgg(mon)
    local detail=(page==Summary.PAGE_MOVES_INFO) or Summary._mode=="select_move"
    local contest=contestMode()

    local titleY=y+pad*.38
    text(egg and "EGG SUMMARY" or "POKéMON SUMMARY",titleF,x+pad,titleY,w*.58,"left",c.text)
    local party=Summary._party or {}; local idx=tonumber(Summary._cursor) or 1
    text(string.format("%d / %d",idx,math.max(1,#party)),smallF,x+w*.72,titleY+math.max(0,(titleF:getHeight()-smallF:getHeight())*.38),w*.22,"right",c.muted)
    local tabH=math.max(10*s,header*.31)
    local tabY=y+header-tabH-pad*.16
    drawTabs(x+pad,tabY,w-pad*2,tabH,c,smallF,page,contest)

    local cy=y+header; local ch=h-header-footer
    local leftW=w*.36; local split=x+leftW
    color(c.divider,.62); G.rectangle("fill",split,cy,math.max(1,s),ch)
    local lx=x+pad; local lw=leftW-pad*2
    local rx=split+pad; local rw=w-leftW-pad*2

    local prevH=ch*.44
    if not egg then drawHdPreview(mon,lx,cy+pad*.30,lw,prevH) end
    local nameY=cy+prevH+pad*.25
    text(fit(monName(mon),bodyF,lw),bodyF,lx,nameY,lw,"center",c.text)
    if not egg then
      local g=""; if okData and SummaryData and type(SummaryData.gender)=="function" then local ok,v=pcall(SummaryData.gender,mon); if ok then g=tostring(v or "") end end
      if g ~= "M" and g ~= "F" and type(mod._kantoInMotion1025DexGender) == "function" then
        local ok,v=pcall(mod._kantoInMotion1025DexGender,mon); if ok and (v=="M" or v=="F") then g=v end
      end
      local level="Lv "..tostring(tonumber(mon.level) or 1)
      local gy=nameY+bodyF:getHeight()+2*s
      local hasGender=(g=="M" or g=="F")
      local symbolSize=smallF:getHeight()*.72
      local gap=hasGender and 3*s or 0
      local symbolW=hasGender and symbolSize*.72 or 0
      local total=smallF:getWidth(level)+gap+symbolW
      local gx=lx+(lw-total)*.5
      text(level,smallF,gx,gy,nil,nil,c.muted)
      if hasGender then
        local gc=(g=="M") and {0.28,0.66,1,1} or {1,0.40,0.66,1}
        genderSymbol(gx+smallF:getWidth(level)+gap+symbolW*.5,gy+smallF:getHeight()*.50,symbolSize,g,gc)
      end
      if shiny(mon) then text("★ SHINY",smallF,lx,nameY+bodyF:getHeight()+smallF:getHeight()+5*s,lw,"center",c.accent) end
      local st=statusName(mon); if st then text(st,smallF,lx,cy+ch-smallF:getHeight()-pad*.35,lw,"center",c.accent) end
    else
      local hatch="It looks like this EGG will take some time to hatch."
      if okData and SummaryData and type(SummaryData.eggHatchText)=="function" then local ok,v=pcall(SummaryData.eggHatchText,mon); if ok and v then hatch=tostring(v) end end
      text(hatch,smallF,lx,nameY+bodyF:getHeight()+5*s,lw,"center",c.muted)
    end

    if egg then
      text("EGG",bodyF,rx,cy+pad,rw,"left",c.text)
      text("No battle stats are available yet.",smallF,rx,cy+pad+bodyF:getHeight()+6*s,rw,"left",c.muted)
    elseif page==Summary.PAGE_INFO then drawInfo(mon,c,fontsT,rx,cy+pad,rw,ch-pad*2,s)
    elseif page==Summary.PAGE_SKILLS then drawSkills(mon,c,fontsT,rx,cy+pad,rw,ch-pad*2,s)
    else drawMoves(mon,c,fontsT,rx,cy+pad,rw,ch-pad*2,s,detail,contest) end

    local fy=y+h-footer; color(c.divider,.55); G.rectangle("fill",x,fy,w,math.max(1,s))
    local fcy=fy+footer*.5
    -- Compact navigation marks: keep opposite directions visually separate,
    -- especially the stacked up/down pair.
    local icon=math.max(5*s,smallF:getHeight()*.38)
    local tx=x+pad
    local ty=fcy-smallF:getHeight()*.5
    local function label(v,col)
      text(v,smallF,tx,ty,nil,nil,col or c.muted); tx=tx+smallF:getWidth(v)+5*s
    end
    local function lrLabel(v)
      chevron(tx+icon*.34,fcy,icon*.82,"left",c.muted); tx=tx+icon*.78
      chevron(tx+icon*.34,fcy,icon*.82,"right",c.muted); tx=tx+icon*.78+3*s
      label(v)
    end
    local function udLabel(v)
      chevron(tx+icon*.34,fcy-icon*.36,icon*.62,"up",c.muted)
      chevron(tx+icon*.34,fcy+icon*.36,icon*.62,"down",c.muted)
      tx=tx+icon*.78+3*s; label(v)
    end
    if detail then
      label(Summary._swapSlot and "A SWAP    B CANCEL" or "A SWITCH    B BACK")
    elseif page==Summary.PAGE_MOVES then
      if isEmeraldUi() then
        if contest then
          chevron(tx+icon*.42,fcy,icon,"left",c.muted); tx=tx+icon*.95+3*s; label("BATTLE MOVES")
          label("A INFO    B BACK")
        else
          label("A INFO    B BACK")
          chevron(tx+icon*.42,fcy,icon,"right",c.muted); tx=tx+icon*.95+3*s; label("CONTEST MOVES")
        end
      else
        label("A INFO    B BACK")
      end
    else
      lrLabel("PAGE")
      udLabel("POKéMON")
      if page==Summary.PAGE_INFO then label("A/B BACK") end
    end
    return true
  end

  -- Hide both the FRLG base renderer and Emerald's RSE skin while KIM owns the
  -- Summary presentation. Input/update methods stay untouched.
  if not Summary.__kimGen3ModernSummaryV55 then
    local upstream=Summary.draw
    if type(upstream)=="function" then
      Summary.draw=function(...)
        if enabled() and (not Style or not Style.hideOriginal or Style.hideOriginal()) and isOpen() then return end
        return upstream(...)
      end
    end
    local upstreamOpen=Summary.openMenu
    if type(upstreamOpen)=="function" then
      Summary.openMenu=function(...)
        local out={upstreamOpen(...)}
        if enabled() then setFloating(true) end
        return unpack(out)
      end
    end
    Summary.__kimGen3ModernSummaryV55=true
  end
  if okRse and type(RseSummary)=="table" and not RseSummary.__kimGen3ModernSummaryV55 then
    local upstream=RseSummary.draw
    if type(upstream)=="function" then
      RseSummary.draw=function(...)
        if enabled() and (not Style or not Style.hideOriginal or Style.hideOriginal()) and isOpen() then return end
        return upstream(...)
      end
    end
    RseSummary.__kimGen3ModernSummaryV55=true
  end

  mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
    nextFn(game,viewport)
    if not enabled() then setFloating(false); return end
    if not isOpen() then return end
    local c=theme()
    G.push("all"); G.origin(); G.setShader(); G.setBlendMode("alpha")
    drawSummary(viewport,c)
    G.setColor(1,1,1,1); G.pop()
  end,11100)

  mod.exports=mod.exports or {}; mod.exports.gen3ModernSummaryUi=true
  return true
end
