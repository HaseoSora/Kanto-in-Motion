-- Kanto in Motion - Pokeball catch-animation target retargeting.
--
-- KIM's Battle Lite draws animated Pokemon directly in final-resolution world
-- space while Gen1Recomp's native Pokeball OAM animation still lives in the
-- old 160x144 battle coordinates. Once that native layer is composited over a
-- wide/fullscreen arena, the vanilla ball endpoint can be far away from the
-- actual enemy sprite.
--
-- This module keeps the original toss arc start, then progressively retargets
-- the native animation so its endpoint lands on the real KIM enemy battler
-- center. The same full offset is retained for the POOF/HIDEPIC/SHAKE/
-- SHOWPIC chain and for the caught resting ball, preserving the native relative
-- movement after impact instead of teleporting each sub-animation separately.
return function(mod, directStageGeometry, directSideMetrics, battleWorldMetrics)
  local M = {}
  local BattleState = require("src.battle.BattleState")
  local AnimPlayer = require("src.battle.AnimPlayer")
  local unpackValues = table.unpack or unpack

  local TOSS = {
    TOSS_ANIM = true,
    GREATTOSS_ANIM = true,
    ULTRATOSS_ANIM = true,
  }
  local CATCH_CHAIN_FOLLOW = {
    POOF_ANIM = true,
    HIDEPIC_ANIM = true,
    SHAKE_ANIM = true,
    SHOWPIC_ANIM = true,
  }
  local TARGETED = {
    TOSS_ANIM = true,
    GREATTOSS_ANIM = true,
    ULTRATOSS_ANIM = true,
    POOF_ANIM = true,
    HIDEPIC_ANIM = true,
    SHAKE_ANIM = true,
    SHOWPIC_ANIM = true,
  }

  -- Record which AnimPlayer program is part of a catch chain. POOF_ANIM is
  -- also used for normal player send-out, so the preceding toss is essential:
  -- without this latch a later send-out poof could inherit catch positioning.
  if not AnimPlayer._kimBallTargetOriginalStart then
    AnimPlayer._kimBallTargetOriginalStart = AnimPlayer.start
  end
  local originalStart = AnimPlayer._kimBallTargetOriginalStart

  function AnimPlayer:start(moveId, attackerIsPlayer, opts)
    if TOSS[moveId] then
      self._kimBallCaptureChain = true
      self._kimBallFullDx = nil
      self._kimBallFullDy = nil
    elseif self._kimBallCaptureChain and CATCH_CHAIN_FOLLOW[moveId] then
      -- Continue the active catch chain with the endpoint found during toss.
    else
      self._kimBallCaptureChain = false
      self._kimBallFullDx = nil
      self._kimBallFullDy = nil
    end
    self._kimBallMoveId = moveId
    return originalStart(self, moveId, attackerIsPlayer, opts)
  end

  -- Apply only the prepared logical-pixel translation to the native animation
  -- layer. All ordinary move animations and send-out poofs pass through with
  -- no transform at all.
  if not BattleState._kimBallTargetOriginalDrawAnimLayer then
    BattleState._kimBallTargetOriginalDrawAnimLayer = BattleState.drawAnimLayer
  end
  local originalDrawAnimLayer = BattleState._kimBallTargetOriginalDrawAnimLayer

  function BattleState:drawAnimLayer(colorized)
    local shift = rawget(self, "_kantoInMotionBallAnimShift")
    if not (shift and love and love.graphics
        and type(love.graphics.push) == "function"
        and type(love.graphics.translate) == "function") then
      return originalDrawAnimLayer(self, colorized)
    end

    local dx = (tonumber(shift.dx) or 0) * (tonumber(shift.factor) or 1)
    local dy = (tonumber(shift.dy) or 0) * (tonumber(shift.factor) or 1)
    if math.abs(dx) < 1e-6 and math.abs(dy) < 1e-6 then
      return originalDrawAnimLayer(self, colorized)
    end

    local g = love.graphics
    g.push("all")
    g.translate(dx, dy)
    local result = { pcall(originalDrawAnimLayer, self, colorized) }
    g.pop()
    local ok = table.remove(result, 1)
    if not ok then error(result[1], 0) end
    return unpackValues(result)
  end

  local function visibleBallCenter(steps)
    if type(steps) ~= "table" then return nil end
    -- The toss ball uses OBJ palette f0/f0x. Scan backward so clear/timing
    -- tail steps do not hide the actual final visible endpoint.
    for i = #steps, 1, -1 do
      local sprites = steps[i] and steps[i].sprites
      if type(sprites) == "table" then
        local minX, minY, maxX, maxY
        for j = 1, #sprites do
          local s = sprites[j]
          if type(s) == "table" and (s.obp == "f0" or s.obp == "f0x") then
            local ox, oy = tonumber(s.x), tonumber(s.y)
            if ox and oy and ox > 0 and ox < 168 and oy > 0 and oy < 160 then
              -- AnimPlayer draws an OAM tile at (x-8,y-16), size 8x8.
              local left, top = ox - 8, oy - 16
              local right, bottom = left + 8, top + 8
              minX = minX and math.min(minX, left) or left
              minY = minY and math.min(minY, top) or top
              maxX = maxX and math.max(maxX, right) or right
              maxY = maxY and math.max(maxY, bottom) or bottom
            end
          end
        end
        if minX then return (minX + maxX) * 0.5, (minY + maxY) * 0.5 end
      end
    end
    return nil
  end

  local function tossProgress(ap)
    local steps = ap and ap.steps
    if type(steps) ~= "table" or #steps == 0 then return 1 end
    local total = 0
    for i = 1, #steps do
      total = total + math.max(0, tonumber(steps[i] and steps[i].dur) or 0)
    end
    if total <= 1 then return 1 end
    local p = (tonumber(ap.elapsed) or 0) / (total - 1)
    if p < 0 then return 0 end
    if p > 1 then return 1 end
    return p
  end

  local function desiredNativeTarget(battle, overlayX, overlayY, overlayScaleX, overlayScaleY)
    if type(directStageGeometry) ~= "function"
        or type(directSideMetrics) ~= "function"
        or type(battleWorldMetrics) ~= "function" then return nil end
    local world = battleWorldMetrics()
    if not (world and tonumber(world.width) and tonumber(world.height)) then return nil end
    local geo = directStageGeometry(world.width, world.height, battle.game, battle)
    local metrics = geo and directSideMetrics(battle, "enemy", geo) or nil
    if not metrics then return nil end

    local dpiX = tonumber(world.dpiX) or 1
    local dpiY = tonumber(world.dpiY) or 1
    if not (dpiX > 1e-6) then dpiX = 1 end
    if not (dpiY > 1e-6) then dpiY = 1 end
    local sx = tonumber(overlayScaleX) or 1
    local sy = tonumber(overlayScaleY) or 1
    if math.abs(sx) < 1e-6 or math.abs(sy) < 1e-6 then return nil end

    -- directSideMetrics.center* is the actual final-resolution animated Pokemon
    -- center, including generation-specific shiny padding and user sprite size.
    -- Convert that physical playfield point to the LOVE/window coordinates
    -- used by render.hud, then back into this native 160x144 overlay's pixels.
    local screenX = (tonumber(world.unitX) or 0) + (tonumber(metrics.centerX) or 0) / dpiX
    local screenY = (tonumber(world.unitY) or 0) + (tonumber(metrics.centerY) or 0) / dpiY
    return (screenX - (tonumber(overlayX) or 0)) / sx,
      (screenY - (tonumber(overlayY) or 0)) / sy
  end

  function M:prepare(battle, overlayX, overlayY, overlayScaleX, overlayScaleY)
    if type(battle) ~= "table" then return false end
    battle._kantoInMotionBallAnimShift = nil

    -- Catching is only valid in wild/Safari/old-man battle paths. Leave the
    -- trainer BLOCKBALL animation and every ordinary battle animation native.
    if battle.kind ~= "wild" then return false end
    local ap = battle.animPlayer
    local moveId = ap and ap._kimBallMoveId
    if not (ap and ap._kimBallCaptureChain and TARGETED[moveId]) then return false end

    if TOSS[moveId] then
      local nativeX, nativeY = visibleBallCenter(ap.steps)
      local targetX, targetY = desiredNativeTarget(
        battle, overlayX, overlayY, overlayScaleX, overlayScaleY)
      if nativeX and targetX then
        ap._kimBallFullDx = targetX - nativeX
        ap._kimBallFullDy = targetY - nativeY
      end
    end

    local dx, dy = tonumber(ap._kimBallFullDx), tonumber(ap._kimBallFullDy)
    if not (dx and dy) then return false end
    battle._kantoInMotionBallAnimShift = {
      dx = dx,
      dy = dy,
      -- Preserve the original throw origin. Only the toss interpolates from
      -- zero to the corrected endpoint; the remaining catch-chain pieces use
      -- the complete offset so their native relative motion stays intact.
      factor = TOSS[moveId] and tossProgress(ap) or 1,
    }
    return true
  end

  function M:finish(battle)
    if type(battle) == "table" then battle._kantoInMotionBallAnimShift = nil end
  end

  return M
end
