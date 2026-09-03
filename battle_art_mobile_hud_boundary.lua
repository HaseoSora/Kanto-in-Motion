-- Kanto in Motion - mobile Battle Art stage-only render.hud handoff guard.
--
-- Gen1Recomp 0.2.45 frame order:
--   Renderer:endFrame -> render.hud -> GameViewport.finish -> TouchControls:draw
--
-- On Android/iOS Battle Art 1.10 can arrive at render.hud with outstanding
-- LOVE graphics states. A nested HUD draw can also strand a state when its
-- protected draw fails. Guard BOTH sides of render.hud: normalize entry for
-- Modern UI/KIM, then normalize exit before GameViewport.finish and the next
-- Battle Art frame. No love.graphics function is replaced or monkeypatched.
return function(mod, stageOnlyActive)
  if not (love and love.graphics and type(stageOnlyActive) == "function") then
    return false
  end

  local system = love.system
  if not (system and type(system.getOS) == "function") then return false end
  local okOs, host = pcall(system.getOS)
  if not okOs or (host ~= "Android" and host ~= "iOS") then return false end

  local g = love.graphics
  if type(g.getStackDepth) ~= "function" or type(g.pop) ~= "function" then
    if mod and mod.log and type(mod.log.warn) == "function" then
      mod.log:warn("mobile Battle Art HUD handoff guard unavailable: LOVE getStackDepth missing")
    end
    return false
  end

  local okVp, GameViewport = pcall(require, "src.render.GameViewport")
  if not okVp or type(GameViewport) ~= "table" or type(GameViewport.setTarget) ~= "function" then
    if mod and mod.log and type(mod.log.warn) == "function" then
      mod.log:warn("mobile Battle Art HUD handoff guard unavailable: GameViewport target API missing")
    end
    return false
  end

  if mod._kantoInMotionBattleArtMobileHudBoundaryInstalled then return true end
  mod._kantoInMotionBattleArtMobileHudBoundaryInstalled = true

  -- Reinstall the already-approved v8.6.63 QOL EXP geometry through a narrow
  -- mobile-only bridge. Unlike the abandoned v27 experiment, this helper never
  -- wraps BattleState.draw and never restores dramaticShapeShot; Modern UI and
  -- native-dialog ownership therefore remain exactly as in the working v25
  -- presentation.
  local okXp, xpInstaller = pcall(function()
    local src = assert(mod:read("lib/mobile_qol_exp_reconstruction.lua"))
    local loader = loadstring or load
    return assert(loader(src, "@" .. mod.path .. "/lib/mobile_qol_exp_reconstruction.lua"))()
  end)
  if okXp and type(xpInstaller) == "function" then
    local okRun, result = pcall(xpInstaller, mod, stageOnlyActive)
    if not okRun and mod and mod.log and type(mod.log.warn) == "function" then
      mod.log:warn("mobile QOL EXP reconstruction failed: %s", tostring(result))
    end
  elseif not okXp and mod and mod.log and type(mod.log.warn) == "function" then
    mod.log:warn("mobile QOL EXP reconstruction unavailable: %s", tostring(xpInstaller))
  end

  local unpack = table.unpack or unpack
  local warnedEntryLeak = false
  local warnedExitLeak = false
  local warnedReset = false

  local function restoreHudBoundary()
    local okDepth, depth = pcall(g.getStackDepth)
    depth = okDepth and tonumber(depth) or 0
    local repaired = 0

    -- render.hud is a top-level engine boundary. Its expected stack depth is 0.
    -- Re-read the actual depth after every pop so a failed pop cannot make our
    -- accounting drift from LOVE's real stack.
    for _ = 1, 128 do
      if not depth or depth <= 0 then break end
      local okPop = pcall(g.pop)
      if not okPop then break end
      repaired = repaired + 1
      local okNext, nextDepth = pcall(g.getStackDepth)
      depth = okNext and tonumber(nextDepth) or nil
    end

    -- Renderer:endFrame selected this target immediately before render.hud.
    -- Reassert it after stack unwinding because a popped state can expose an
    -- older Battle Art scratch canvas. Never clear: the finished 3D scene is
    -- already in the viewport and the 2D UI must simply draw over it.
    local okTarget = pcall(GameViewport.setTarget)

    -- Neutral screen-space state expected by render.hud. These setters affect
    -- future draws only and are protected for LOVE-version portability.
    if type(g.origin) == "function" then pcall(g.origin) end
    if type(g.setScissor) == "function" then pcall(g.setScissor) end
    if type(g.setShader) == "function" then pcall(g.setShader) end
    if type(g.setDepthMode) == "function" then pcall(g.setDepthMode) end
    if type(g.setStencilTest) == "function" then pcall(g.setStencilTest) end
    if type(g.setColorMask) == "function" then
      pcall(g.setColorMask, true, true, true, true)
    end
    if type(g.setBlendMode) == "function" then pcall(g.setBlendMode, "alpha") end
    if type(g.setColor) == "function" then pcall(g.setColor, 1, 1, 1, 1) end

    return repaired, okTarget
  end

  mod.hooks:wrap("render.hud", function(next, game, viewport)
    local okStage, activeStage = pcall(stageOnlyActive)
    if not (okStage and activeStage) then
      return next(game, viewport)
    end

    local entryRepaired, entryTarget = restoreHudBoundary()
    if entryRepaired > 0 and not warnedEntryLeak and mod and mod.log
        and type(mod.log.warn) == "function" then
      warnedEntryLeak = true
      mod.log:warn(
        "mobile Battle Art entered render.hud with %d leaked graphics state(s); repaired before UI",
        entryRepaired)
    end
    if not entryTarget and not warnedReset and mod and mod.log
        and type(mod.log.warn) == "function" then
      warnedReset = true
      mod.log:warn("mobile Battle Art HUD handoff could not rebind GameViewport target")
    end

    local result = { pcall(next, game, viewport) }

    -- Do this even when downstream HUD code errors. Otherwise its stranded
    -- push/canvas can survive into GameViewport.finish, TouchControls and then
    -- Battle Art's NEXT frame, where it can corrupt staged textures.
    local exitRepaired, exitTarget = restoreHudBoundary()
    if exitRepaired > 0 and not warnedExitLeak and mod and mod.log
        and type(mod.log.warn) == "function" then
      warnedExitLeak = true
      mod.log:warn(
        "mobile Battle Art render.hud left %d graphics state(s); repaired before GameViewport.finish",
        exitRepaired)
    end
    if not exitTarget and not warnedReset and mod and mod.log
        and type(mod.log.warn) == "function" then
      warnedReset = true
      mod.log:warn("mobile Battle Art HUD handoff could not rebind GameViewport target")
    end

    local ok = table.remove(result, 1)
    if not ok then error(result[1], 0) end
    return unpack(result)
  end, 100000)

  return true
end
