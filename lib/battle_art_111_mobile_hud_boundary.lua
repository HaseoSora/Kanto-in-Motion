-- Kanto in Motion -> Battle Art 1.11 mobile HUD boundary guard.
--
-- Android/iOS final order:
--   Renderer:endFrame -> render.hud -> GameViewport.finish -> TouchControls:draw
--
-- Battle Art's 3D stage can arrive at render.hud with outstanding graphics
-- states, or a protected nested HUD draw can leave a push alive. TouchControls
-- then hits LOVE's maximum stack depth after enough frames. Normalize BOTH
-- sides of render.hud while Battle Art's 3D stage is active.
--
-- No Battle Art file is modified and no love.graphics function is replaced.
return function(mod, battleSystemEnabled, battleArtCompat)
  if not (mod and love and love.graphics
      and type(battleSystemEnabled)=="function") then return false end

  local system=love.system
  if not (system and type(system.getOS)=="function") then return false end
  local okOs,host=pcall(system.getOS)
  if not okOs or (host~="Android" and host~="iOS") then return false end

  local g=love.graphics
  if type(g.getStackDepth)~="function" or type(g.pop)~="function" then
    return false
  end

  local okVp,GameViewport=pcall(require,"src.render.GameViewport")
  if not okVp or type(GameViewport)~="table"
      or type(GameViewport.setTarget)~="function" then
    return false
  end

  if mod._kantoInMotionBattleArt111MobileHudBoundary then return true end
  mod._kantoInMotionBattleArt111MobileHudBoundary=true

  local function active()
    local okKim,kim=pcall(battleSystemEnabled)
    if not (okKim and kim) then return false end
    local compat=battleArtCompat or mod._kantoInMotionBattleArtCompat
    if not (compat and type(compat.isActive)=="function") then return false end
    local okBa,value=pcall(compat.isActive,compat)
    return okBa and value==true
  end

  local function restoreBoundary()
    local repaired=0
    for _=1,128 do
      local okDepth,depth=pcall(g.getStackDepth)
      depth=okDepth and tonumber(depth) or nil
      if not depth or depth<=0 then break end
      if not pcall(g.pop) then break end
      repaired=repaired+1
    end

    -- Renderer:endFrame selected the viewport target immediately before
    -- render.hud. Rebind it after unwinding because a popped Battle Art state
    -- can expose an older scratch canvas.
    pcall(GameViewport.setTarget)

    if type(g.origin)=="function" then pcall(g.origin) end
    if type(g.setScissor)=="function" then pcall(g.setScissor) end
    if type(g.setShader)=="function" then pcall(g.setShader) end
    if type(g.setDepthMode)=="function" then pcall(g.setDepthMode) end
    if type(g.setStencilTest)=="function" then pcall(g.setStencilTest) end
    if type(g.setColorMask)=="function" then
      pcall(g.setColorMask,true,true,true,true)
    end
    if type(g.setBlendMode)=="function" then pcall(g.setBlendMode,"alpha") end
    if type(g.setColor)=="function" then pcall(g.setColor,1,1,1,1) end
    return repaired
  end

  local warnedEntry=false
  local warnedExit=false
  local unpackFn=table.unpack or unpack

  mod.hooks:wrap("render.hud",function(nextFn,game,viewport)
    if not active() then return nextFn(game,viewport) end

    local entry=restoreBoundary()
    if entry>0 and not warnedEntry and mod.log
        and type(mod.log.warn)=="function" then
      warnedEntry=true
      mod.log:warn(
        "Battle Art mobile entered render.hud with %d leaked graphics state(s); repaired",
        entry)
    end

    local result={pcall(nextFn,game,viewport)}

    -- Always repair on exit, including when downstream HUD composition throws.
    -- TouchControls immediately follows this boundary on mobile.
    local exitCount=restoreBoundary()
    if exitCount>0 and not warnedExit and mod.log
        and type(mod.log.warn)=="function" then
      warnedExit=true
      mod.log:warn(
        "Battle Art mobile render.hud left %d graphics state(s); repaired before TouchControls",
        exitCount)
    end

    local ok=table.remove(result,1)
    if not ok then error(result[1],0) end
    return unpackFn(result)
  end,100000)

  return true
end
