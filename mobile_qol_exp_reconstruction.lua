-- Kanto in Motion - mobile Quality of Life EXP compatibility reconstruction.
--
-- This restores the already-approved v8.6.63 EXP geometry without altering
-- KIM's BattleState ownership or Battle Art's staged-scene handoff.
--
-- Battle Art 1.10.0 differs from the older custom/1.9.x path in one important
-- way: when 3D-BTL is OFF it clears battle.dramaticShapeShot before Quality of
-- Life runs its post-battle-draw overlay. Rather than restoring that field (and
-- thereby changing Modern UI/native-dialog ownership), this module redirects
-- only QOL's final EXP fill pixels onto KIM's already-existing flat battle
-- canvas. With 3D-BTL ON, only portrait EXP pixels are translated from Battle
-- Art's original HUD row to the exact KIM player HUD row. Landscape remains
-- untouched.
return function(mod, stageOnlyActive)
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
  local unpack = table.unpack or unpack

  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("battle.started", function(event)
      activeBattle = event and event.battle or nil
      burstRoute = nil
    end)
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

  local function route3DPortraitMain(battle, shot, nx, ny, nw, nh)
    if mobileTouchOrientation(battle.game) ~= "portrait" then return false end
    if type(g.getCanvas) ~= "function" or g.getCanvas() ~= shot.canvas then return false end

    local baScale = tonumber(shot.scale)
    local pw, ph = tonumber(shot.pw), tonumber(shot.ph)
    local ly = tonumber(shot.ly)
    if not (baScale and baScale > 0 and pw and ph and ly) then return false end

    local baseY = ly + 89 * baScale
    if not (math.abs(nh - 2 * baScale) < 0.51
        and math.abs(ny - baseY) < 0.51 and nx >= pw * 0.45) then
      return false
    end

    local px = nw / baScale
    if not (px > 0 and px <= 67.5) then return false end
    local bandY, _, hs = playerBandY(battle.game, pw, ph, ly)
    local targetW = px * hs
    local targetX = pw - 13 * hs - targetW
    local targetY = bandY + 41 * hs
    nativeRectangle("fill", targetX, targetY, targetW, 2 * hs)
    burstRoute = {
      kind = "3d", canvas = shot.canvas, hs = hs,
      baScale = baScale,
      sourceBaseX = pw - (13 + 67) * baScale,
      sourceBaseY = ly + 90 * baScale,
      targetBaseX = pw - (13 + 67) * hs,
      targetBaseY = targetY + hs,
    }
    return true
  end

  local function route3DPortraitBurst(nx, ny, nw, nh)
    local r = burstRoute
    if not (r and r.kind == "3d" and type(g.getCanvas) == "function"
        and g.getCanvas() == r.canvas
        and math.abs(nw - r.baScale) < 0.51
        and math.abs(nh - r.baScale) < 0.51) then return false end
    if nx < r.sourceBaseX - 32 * r.baScale
        or nx > r.sourceBaseX + 32 * r.baScale
        or ny < r.sourceBaseY - 32 * r.baScale
        or ny > r.sourceBaseY + 32 * r.baScale then return false end
    local ux = (nx - r.sourceBaseX) / r.baScale
    local uy = (ny - r.sourceBaseY) / r.baScale
    nativeRectangle("fill", r.targetBaseX + ux * r.hs,
      r.targetBaseY + uy * r.hs, r.hs, r.hs)
    return true
  end

  g.rectangle = function(mode, x, y, w, h, ...)
    local battle = activeBattle
    local nx, ny, nw, nh = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
    if battle and mode == "fill" and nx and ny and nw and nh then
      if active3D() then
        local shot = rawget(battle, "dramaticShapeShot")
        if type(shot) == "table" and shot.canvas and not shot.kantoInMotion2D then
          if route3DPortraitMain(battle, shot, nx, ny, nw, nh)
              or route3DPortraitBurst(nx, ny, nw, nh) then
            return
          end
        end
      else
        local flat = rawget(battle, "_kantoInMotionFlatShot")
        if type(flat) == "table" and flat.canvas
            and rawget(battle, "_kantoInMotionBattleLite") == true then
          if routeFlatMain(battle, flat, nx, ny, nw, nh)
              or routeFlatBurst(nx, ny, nw, nh) then
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
