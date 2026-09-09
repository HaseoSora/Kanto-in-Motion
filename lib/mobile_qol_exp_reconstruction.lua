-- Kanto in Motion - mobile Quality of Life battle-overlay reconstruction.
--
-- This restores the already-approved v8.6.63 EXP geometry without altering
-- KIM's BattleState ownership or Battle Art's staged-scene handoff.
--
-- Battle Art 1.10.0 differs from the older custom/1.9.x path in one important
-- way: when 3D-BTL is OFF it clears battle.dramaticShapeShot before Quality of
-- Life runs its post-battle-draw overlay. Rather than restoring that field (and
-- thereby changing Modern UI/native-dialog ownership), this module redirects
-- only QOL's final EXP fill pixels onto KIM's already-existing flat battle
-- canvas. With 3D-BTL ON, portrait EXP pixels are translated to the exact KIM
-- player HUD row, while the already-caught icon is rebased/scaled to KIM's
-- enemy HUD in both portrait and landscape.
return function(mod, stageOnlyActive, battleHudGeometry)
  if not (love and love.graphics and type(stageOnlyActive) == "function") then
    return false
  end

  local system = love.system
  if not (system and type(system.getOS) == "function") then return false end
  local okOs, host = pcall(system.getOS)
  if not okOs or (host ~= "Android" and host ~= "iOS") then return false end

  if mod._kantoInMotionMobileQolExpReconstructionInstalled then return true end
  mod._kantoInMotionMobileQolExpReconstructionInstalled = true

  local g = love.graphics
  if type(g.rectangle) ~= "function" then return false end

  local activeBattle = nil
  local burstRoute = nil
  local postBattleDraw = false
  local unpack = table.unpack or unpack

  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("battle.started", function(event)
      activeBattle = event and event.battle or nil
      burstRoute = nil
      postBattleDraw = false
    end)
  end

  -- Quality of Life wraps each battle instance and runs its overlays AFTER the
  -- underlying BattleState:draw() returns.  Keep a frame-local marker around
  -- that exact boundary instead of relying only on the battle.started event.
  -- This makes the rectangle redirect deterministic on Android/iOS regardless
  -- of mod load/event ordering: ordinary battle rendering sees false, then QOL
  -- EXP/caught primitives see true immediately after the native/KIM draw.
  local okBattleState, BattleState = pcall(require, "src.battle.BattleState")
  if okBattleState and type(BattleState) == "table"
      and type(BattleState.draw) == "function"
      and not BattleState._kantoInMotionMobileQolPostDrawBoundary then
    local originalBattleDraw = BattleState.draw
    BattleState._kantoInMotionMobileQolPostDrawBoundary = originalBattleDraw
    BattleState.draw = function(self, ...)
      activeBattle = self
      burstRoute = nil
      postBattleDraw = false
      local result = { pcall(originalBattleDraw, self, ...) }
      postBattleDraw = true
      local ok = table.remove(result, 1)
      if not ok then error(result[1], 0) end
      return unpack(result)
    end
  end

  local qolHandle = nil
  local function qolOption(game, key)
    if not qolHandle and type(mod.find) == "function" then
      local ok, handle = pcall(mod.find, "quality_of_life")
      if ok then qolHandle = handle end
    end
    local exports = qolHandle and type(qolHandle.exports) == "table"
      and qolHandle.exports or nil
    if exports and type(exports.optionValue) == "function" then
      local ok, value = pcall(exports.optionValue, game, key)
      if ok then return value end
    end
    return nil
  end

  local function battleShake(battle)
    local fx = battle and battle.fx
    local sx = fx and tonumber(fx.shakeX) or 0
    local sy = fx and tonumber(fx.shakeY) or 0
    if sx == 0 and sy == 0 and fx and (tonumber(fx.shake) or 0) > 0 then
      sx = ((tonumber(battle.frame) or 0) % 4 < 2) and 2 or -2
    end
    return sx or 0, sy or 0, fx and (tonumber(fx.hudShakeX) or 0) or 0
  end

  local function enemyNameX(battle)
    local name = battle and battle.enemy and battle.enemy.name or ""
    local glyphs = #tostring(name)
    local Font = mod and mod.ui and mod.ui.Font
    if Font and type(Font.split) == "function" then
      local ok, parts = pcall(Font.split, tostring(name))
      if ok and type(parts) == "table" then glyphs = #parts end
    end
    return 8 + (glyphs <= 2 and 16 or glyphs <= 4 and 8 or 0)
  end

  local function mobileTouchOrientation(game)
    local touch = game and game.touchControls
    local stack = game and game.stack
    if not touch or (stack and type(stack.touchControlsHidden) == "function"
        and stack:touchControlsHidden()) then return nil end
    if type(touch.visible) ~= "function" then return nil end
    local okVisible, visible = pcall(touch.visible, touch)
    if not okVisible or not visible then return nil end

    local w, h = 0, 0
    if type(g.getPixelDimensions) == "function" then
      local ok, pw, ph = pcall(g.getPixelDimensions)
      if ok then w, h = tonumber(pw) or 0, tonumber(ph) or 0 end
    end
    if not (w > 0 and h > 0) and type(g.getDimensions) == "function" then
      local ok, uw, uh = pcall(g.getDimensions)
      if ok then w, h = tonumber(uw) or 0, tonumber(uh) or 0 end
    end
    if not (w > 0 and h > 0) then return "landscape" end
    return h > w and "portrait" or "landscape"
  end

  -- Exact SCREEN POS lift contract from the confirmed v8.6.63 mobile layout.
  local function screenLiftPx(game, vw, vh)
    if not mobileTouchOrientation(game) then return 0 end
    local okSp, ScreenPosition = pcall(require, "src.core.ScreenPosition")
    if not okSp or not ScreenPosition or type(ScreenPosition.lift) ~= "function" then
      return 0
    end
    if type(ScreenPosition.skinActive) == "function" then
      local okSkin, skin = pcall(ScreenPosition.skinActive)
      if okSkin and skin then return 0 end
    end
    local s = math.max(1, math.floor(math.min(
      (tonumber(vw) or 160) / 160, (tonumber(vh) or 144) / 144)))
    local dpiY = 1
    if type(g.getDimensions) == "function" and type(g.getPixelDimensions) == "function" then
      local okU, _, uh = pcall(g.getDimensions)
      local okP, _, ph = pcall(g.getPixelDimensions)
      if okU and okP and tonumber(uh) and tonumber(ph) and uh > 0 and ph > 0 then
        dpiY = ph / uh
      end
    end
    local safe = 0
    if type(ScreenPosition.safeTop) == "function" then
      local ok, value = pcall(ScreenPosition.safeTop)
      if ok then safe = (tonumber(value) or 0) * dpiY end
    end
    local ok, value = pcall(ScreenPosition.lift, vh, 144 * s, safe)
    return ok and math.max(0, tonumber(value) or 0) or 0
  end

  local function hudScales(pw, ph)
    local s = math.max(1, math.floor(math.min((tonumber(pw) or 160) / 160,
      (tonumber(ph) or 144) / 144)))
    local hs = s
    local okMode, mode = pcall(function() return mod.options:get("battleHudScale") end)
    if okMode and mode == "scaled" then hs = math.max(1, s - 1) end
    local okSize, size = pcall(function() return mod.options:get("battleHudSize") end)
    local factor = okSize and (tonumber(size) or 100) / 100 or 1
    factor = math.max(0.60, math.min(1.00, factor))
    hs = hs * factor
    return s, hs
  end

  -- Exact player-band Y formula used by the confirmed v8.6.63 KIM HUD.
  local function playerBandY(game, pw, ph, ly)
    local s, hs = hudScales(pw, ph)
    if mobileTouchOrientation(game) == "portrait" then
      local aspect = 1920 / 950
      local stageW = pw
      local stageH = stageW / aspect
      if stageH > ph then stageH = ph; stageW = stageH * aspect end
      local lift = screenLiftPx(game, pw, ph)
      local stageBottom = (ph - stageH) * 0.5 - lift + stageH
      local y = math.floor(stageBottom - 44 * hs + 0.5)
      y = math.max(0, math.min(ph - 48 * hs, y))
      return y, s, hs
    end
    return (tonumber(ly) or 0) + 56 * s - 8 * hs, s, hs
  end

  -- Use KIM's live HUD geometry whenever the caller can provide it.  The
  -- duplicated v8.6.63 formula above remains as a fail-open fallback for older
  -- trees, but HUD SIZE now changes the final band placement as well as its
  -- scale.  Sharing the exact geometry function prevents the QOL overlay from
  -- drifting away from the resized portrait player HUD.
  local function targetGeometry(battle, shot)
    local pw, ph = tonumber(shot and shot.pw), tonumber(shot and shot.ph)
    local ly = tonumber(shot and shot.ly) or 0
    if not (pw and ph and pw > 0 and ph > 0) then return nil end

    if type(battleHudGeometry) == "function" then
      local lift = screenLiftPx(battle and battle.game, pw, ph)
      local ok, geo = pcall(battleHudGeometry, pw, ph, lift,
        battle and battle.game or nil)
      if ok and type(geo) == "table"
          and tonumber(geo.hudScale) and tonumber(geo.hudScale) > 0 then
        return geo, pw, ph
      end
    end

    local bandY, _, hs = playerBandY(battle and battle.game, pw, ph, ly)
    return {
      hudScale = hs,
      playerBandY = bandY,
      enemyBandX = -6 * hs,
      enemyBandY = ly,
    }, pw, ph
  end

  local function active3D()
    local ok, active = pcall(stageOnlyActive)
    return ok and active == true
  end

  local function withCanvas(canvas, fn)
    if not canvas or type(g.setCanvas) ~= "function" then return false end
    local pushed = false
    if type(g.push) == "function" and type(g.pop) == "function" then
      local okPush = pcall(g.push, "all")
      pushed = okPush == true
    end
    local ok, err = pcall(function()
      g.setCanvas(canvas)
      if type(g.origin) == "function" then g.origin() end
      if type(g.setScissor) == "function" then g.setScissor() end
      fn()
    end)
    if pushed then pcall(g.pop) end
    if not ok and mod.log and type(mod.log.warn) == "function" then
      mod.log:warn("mobile QOL EXP redirect draw failed: %s", tostring(err))
    end
    return ok
  end

  local nativeRectangle = g.rectangle
  g._kantoInMotionMobileQolExpReconstruction = nativeRectangle

  local function routeFlatMain(battle, flat, nx, ny, nw, nh)
    local pw, ph = tonumber(flat.pw), tonumber(flat.ph)
    local ly = tonumber(flat.ly) or 0
    if not (pw and ph and pw > 0 and ph > 0) then return false end

    -- QOL may fall back to either its 160x144 row (Y=89) or its wide row
    -- (Y=91) after Battle Art 1.10 clears dramaticShapeShot. Recognize only
    -- those exact 2px fills; everything else remains source-owned.
    local sourceKind, progressPixels
    if math.abs(nh - 2) < 0.51 and math.abs(ny - 89) <= 4
        and nx >= 75 and nx <= 160 and nw > 0 and nw <= 67 then
      sourceKind = "native"
      progressPixels = nw
    elseif math.abs(nh - 2) < 0.51 and math.abs(ny - 91) <= 4
        and nx >= 180 and nx <= 330 and nw > 0 and nw <= 80 then
      sourceKind = "wide"
      progressPixels = nw * 67 / 80
    else
      return false
    end

    local bandY, _, hs = playerBandY(battle.game, pw, ph, ly)
    local px = math.max(0, math.min(67, progressPixels))
    local targetW = px * hs
    local targetX = pw - (13 * hs) - targetW
    local targetY = bandY + 41 * hs

    local ok = withCanvas(flat.canvas, function()
      nativeRectangle("fill", targetX, targetY, targetW, 2 * hs)
    end)
    if ok then
      burstRoute = {
        kind = "flat", canvas = flat.canvas, hs = hs,
        baseX = pw - (13 + 67) * hs,
        baseY = targetY + hs,
        sourceKind = sourceKind,
      }
    end
    return ok
  end

  local function routeFlatBurst(nx, ny, nw, nh)
    local r = burstRoute
    if not (r and r.kind == "flat" and math.abs(nw - 1) < 0.51
        and math.abs(nh - 1) < 0.51) then return false end

    local sx0, sy0
    if r.sourceKind == "wide" then
      -- Wide QOL burst is rooted at X=288,Y=92, but its one-pixel tile dots
      -- still use ordinary source pixels. Map that local burst shape onto the
      -- same KIM EXP origin used by the historical voxel path.
      sx0, sy0 = 288, 92
    else
      sx0, sy0 = 80, 90
    end
    if nx < sx0 - 32 or nx > sx0 + 32 or ny < sy0 - 32 or ny > sy0 + 32 then
      return false
    end
    local tx = r.baseX + (nx - sx0) * r.hs
    local ty = r.baseY + (ny - sy0) * r.hs
    return withCanvas(r.canvas, function()
      nativeRectangle("fill", tx, ty, r.hs, r.hs)
    end)
  end

  local function route3DMain(battle, shot, nx, ny, nw, nh)
    local baScale = tonumber(shot.scale)
    local pw, ph = tonumber(shot.pw), tonumber(shot.ph)
    local ly = tonumber(shot.ly)
    if not (baScale and baScale > 0 and pw and ph and ly) then return false end

    local baseY = ly + 89 * baScale
    if not (math.abs(nh - 2 * baScale) < 0.51
        and math.abs(ny - baseY) < 0.51 and nx >= pw * 0.35) then
      return false
    end

    local px = nw / baScale
    if not (px > 0 and px <= 67.5) then return false end
    local geo, targetPw = targetGeometry(battle, shot)
    if not geo then return false end
    local hs = tonumber(geo.hudScale)
    local bandY = tonumber(geo.playerBandY)
    if not (hs and hs > 0 and bandY and targetPw) then return false end

    local targetW = px * hs
    local targetX = targetPw - (13 + px) * hs
    local targetY = bandY + 41 * hs
    local ok = withCanvas(shot.canvas, function()
      nativeRectangle("fill", targetX, targetY, targetW, 2 * hs)
    end)
    if ok then
      burstRoute = {
        kind = "3d", canvas = shot.canvas, hs = hs,
        baScale = baScale,
        sourceBaseX = pw - (13 + 67) * baScale,
        sourceBaseY = ly + 90 * baScale,
        targetBaseX = targetPw - (13 + 67) * hs,
        targetBaseY = targetY + hs,
      }
    end
    return ok
  end

  local function route3DBurst(nx, ny, nw, nh)
    local r = burstRoute
    if not (r and r.kind == "3d"
        and math.abs(nw - r.baScale) < 0.51
        and math.abs(nh - r.baScale) < 0.51) then return false end
    if nx < r.sourceBaseX - 32 * r.baScale
        or nx > r.sourceBaseX + 32 * r.baScale
        or ny < r.sourceBaseY - 32 * r.baScale
        or ny > r.sourceBaseY + 32 * r.baScale then return false end
    local ux = (nx - r.sourceBaseX) / r.baScale
    local uy = (ny - r.sourceBaseY) / r.baScale
    return withCanvas(r.canvas, function()
      nativeRectangle("fill", r.targetBaseX + ux * r.hs,
        r.targetBaseY + uy * r.hs, r.hs, r.hs)
    end)
  end

  -- Rebase QOL's voxel-path caught ball into the same enemy HUD band KIM
  -- renders in render.hud.  QOL's source scale remains Battle Art's stage
  -- scale; the destination uses KIM's independently configurable HUD SIZE.
  local function route3DCaughtPixel(battle, shot, nx, ny, nw, nh)
    if not battle or battle.kind ~= "wild" then return false end
    local mode = qolOption(battle.game, "qol_caught_indicator")
    if mode ~= "gen2" and mode ~= "red" and mode ~= "grey" then return false end

    local baScale = tonumber(shot.scale)
    local sourceLy = tonumber(shot.ly)
    if not (baScale and baScale > 0 and sourceLy) then return false end
    if math.abs(nw - baScale) >= 0.51 or math.abs(nh - baScale) >= 0.51 then
      return false
    end

    local sourceAnchorX = (enemyNameX(battle) - 9) * baScale
    local sourceAnchorY = sourceLy + 7 * baScale
    if mode == "gen2" then
      sourceAnchorX = sourceAnchorX + 2 * baScale
      sourceAnchorY = sourceAnchorY + 2 * baScale
    else
      sourceAnchorX = sourceAnchorX + baScale
      sourceAnchorY = sourceAnchorY + baScale
    end

    local side = mode == "gen2" and 6 or 7
    local ux = (nx - sourceAnchorX) / baScale
    local uy = (ny - sourceAnchorY) / baScale
    if ux < -0.01 or ux > side - 1 + 0.01
        or uy < -0.01 or uy > side - 1 + 0.01 then return false end

    local geo = targetGeometry(battle, shot)
    if not geo then return false end
    local hs = tonumber(geo.hudScale)
    local enemyX = tonumber(geo.enemyBandX)
    local enemyY = tonumber(geo.enemyBandY)
    if not (hs and hs > 0 and enemyX and enemyY) then return false end

    local targetAnchor = mode == "gen2" and 9 or 8
    return withCanvas(shot.canvas, function()
      nativeRectangle("fill", enemyX + (targetAnchor + ux) * hs,
        enemyY + (targetAnchor + uy) * hs, hs, hs)
    end)
  end

  -- With 3D-BTL OFF, Battle Art 1.10 clears dramaticShapeShot before QOL's
  -- overlay runs, so QOL falls back to its ordinary 160x144/wide coordinates.
  -- Those pixels land on KIM's hidden source layer. Redirect only the caught
  -- ball's post-draw 1x1 pixels onto KIM's fullscreen flat canvas and scale
  -- them with the live enemy HUD. This covers both portrait and landscape.
  local function routeFlatCaughtPixel(battle, flat, nx, ny, nw, nh)
    if not battle or battle.kind ~= "wild" then return false end
    if math.abs(nw - 1) >= 0.51 or math.abs(nh - 1) >= 0.51 then return false end
    local mode = qolOption(battle.game, "qol_caught_indicator")
    if mode ~= "gen2" and mode ~= "red" and mode ~= "grey" then return false end

    local wide = false
    if type(battle.wideLayout) == "function" then
      local ok, value = pcall(battle.wideLayout, battle)
      wide = ok and value == true
    end
    local sx, sy, hudShake = battleShake(battle)
    local sourceAnchorX, sourceAnchorY
    if wide then
      sourceAnchorX, sourceAnchorY = 112 + sx, 7 + sy
      if mode == "gen2" then
        sourceAnchorX, sourceAnchorY = sourceAnchorX + 1, sourceAnchorY + 2
      else
        sourceAnchorX, sourceAnchorY = sourceAnchorX + 1, sourceAnchorY + 1
      end
    else
      sourceAnchorX, sourceAnchorY = 7 + sx + hudShake, 7 + sy
      if mode == "gen2" then
        sourceAnchorX, sourceAnchorY = sourceAnchorX + 2, sourceAnchorY + 2
      else
        sourceAnchorX, sourceAnchorY = sourceAnchorX + 1, sourceAnchorY + 1
      end
    end

    local side = mode == "gen2" and 6 or 7
    local ux, uy = nx - sourceAnchorX, ny - sourceAnchorY
    if ux < -0.01 or ux > side - 1 + 0.01
        or uy < -0.01 or uy > side - 1 + 0.01 then return false end

    local geo = targetGeometry(battle, flat)
    if not geo then return false end
    local hs = tonumber(geo.hudScale)
    local enemyX = tonumber(geo.enemyBandX)
    local enemyY = tonumber(geo.enemyBandY)
    if not (hs and hs > 0 and enemyX and enemyY) then return false end
    local targetAnchor = mode == "gen2" and 9 or 8
    return withCanvas(flat.canvas, function()
      nativeRectangle("fill", enemyX + (targetAnchor + ux) * hs,
        enemyY + (targetAnchor + uy) * hs, hs, hs)
    end)
  end

  g.rectangle = function(mode, x, y, w, h, ...)
    local battle = activeBattle
    local nx, ny, nw, nh = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
    -- Only redirect rectangles emitted after the underlying BattleState draw.
    -- That is QOL's overlay window; it avoids ever mistaking native/KRBA battle
    -- pixels for EXP/caught primitives.
    if postBattleDraw and battle and mode == "fill" and nx and ny and nw and nh then
      if active3D() then
        local shot = rawget(battle, "dramaticShapeShot")
        if type(shot) == "table" and shot.canvas and not shot.kantoInMotion2D then
          if route3DMain(battle, shot, nx, ny, nw, nh)
              or route3DBurst(nx, ny, nw, nh)
              or route3DCaughtPixel(battle, shot, nx, ny, nw, nh) then
            return
          end
        end
      else
        local flat = rawget(battle, "_kantoInMotionFlatShot")
        if type(flat) == "table" and flat.canvas
            and rawget(battle, "_kantoInMotionBattleLite") == true then
          if routeFlatMain(battle, flat, nx, ny, nw, nh)
              or routeFlatBurst(nx, ny, nw, nh)
              or routeFlatCaughtPixel(battle, flat, nx, ny, nw, nh) then
            return
          end
        end
      end
    end
    burstRoute = nil
    return nativeRectangle(mode, x, y, w, h, ...)
  end

  return true
end
