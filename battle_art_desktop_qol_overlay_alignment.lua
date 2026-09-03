-- Kanto in Motion - desktop Battle Art / Quality of Life overlay alignment.
--
-- Quality of Life draws its XP fill and caught-Pokedex icon directly into
-- Battle Art's dramaticShapeShot canvas.  Battle Art 1.10 can expose shot
-- geometry in a different coordinate space from the final framebuffer on
-- high-DPI Windows desktops, while KIM intentionally renders its snapped HUD
-- from the real final-size viewport.  The result is exactly the failure this
-- bridge targets: QOL's XP bar appears under/near the enemy HUD and the caught
-- icon is detached from KIM's enemy band.
--
-- Keep both third-party mods source-owned.  We only intercept the tiny final
-- rectangle primitives QOL emits onto the live 3D shot and remap those pixels
-- onto the same geometry KIM uses for its final HP/status HUD.  Mobile keeps
-- its independently tested reconstruction path and never installs this file.
return function(mod, battleArt3DEnabled, isMobileHost, battleHudGeometry,
    modernUiEnabled)
  if type(isMobileHost) == "function" and isMobileHost() then return false end
  if not (love and love.graphics) then return false end
  if type(battleHudGeometry) ~= "function" then return false end

  local g = love.graphics
  if type(g.rectangle) ~= "function" or type(g.getCanvas) ~= "function" then
    return false
  end
  if g._kantoInMotionDesktopQolOverlayAlignment then return true end

  local activeBattle = nil
  local burstRoute = nil
  local innerRectangle = g.rectangle
  local EPS = 0.75

  local function stageActive()
    if type(battleArt3DEnabled) ~= "function" then return true end
    local ok, value = pcall(battleArt3DEnabled)
    return ok and value == true
  end

  local function modernLowerPanelActive()
    if type(modernUiEnabled) ~= "function" then return true end
    local ok, value = pcall(modernUiEnabled)
    return ok and value == true
  end

  local function currentBattle()
    if activeBattle then return activeBattle end
    local okGame, Game = pcall(require, "src.core.Game")
    if not okGame or type(Game) ~= "table" then return nil end
    local stack = Game.stack
    local top = stack and type(stack.top) == "function" and stack:top() or nil
    if type(top) == "table" and type(rawget(top, "dramaticShapeShot")) == "table" then
      return top
    end
    return nil
  end

  local function shotCanvasSize(shot)
    local canvas = shot and shot.canvas
    if not canvas then return nil end
    local w, h
    if type(canvas.getDimensions) == "function" then
      local ok, cw, ch = pcall(canvas.getDimensions, canvas)
      if ok then w, h = tonumber(cw), tonumber(ch) end
    end
    if not (w and h and w > 0 and h > 0)
        and type(g.getPixelDimensions) == "function" then
      local ok, pw, ph = pcall(g.getPixelDimensions)
      if ok then w, h = tonumber(pw), tonumber(ph) end
    end
    if not (w and h and w > 0 and h > 0) then return nil end
    return w, h
  end

  local function targetGeometry(battle, shot)
    local pw, ph = shotCanvasSize(shot)
    if not pw then return nil end
    local ok, geo = pcall(battleHudGeometry, pw, ph, 0,
      battle and battle.game or nil)
    if not ok or type(geo) ~= "table" then return nil end
    local hs = tonumber(geo.hudScale)
    if not (hs and hs > 0) then return nil end
    return geo, pw, ph, hs
  end

  -- Keep desktop QOL EXP on the same native Gen 1 row used by the accepted
  -- mobile Battle Art reference: inside the lower part of the player HUD,
  -- immediately above its bottom white rule.  The player HUD quad begins at
  -- source row 48 and QOL's EXP row is source row 89, hence +41 HUD pixels.
  -- This is band-relative so OG/SCALED HUD modes both stay attached.

  -- QOL's voxel XP path emits one 2*shot.scale-high fill at
  --   shot.pw - (13 + progress) * shot.scale,
  --   shot.ly + 89 * shot.scale.
  -- Do not trust shot.pw/ly as final-screen geometry here; use them only to
  -- recognize the source primitive.  Destination geometry comes from KIM.
  local function routeXpMain(battle, shot, nx, ny, nw, nh)
    local baScale = tonumber(shot.scale)
    local sourcePw = tonumber(shot.pw)
    local sourceLy = tonumber(shot.ly)
    if not (baScale and baScale > 0 and sourcePw and sourceLy) then return false end
    if g.getCanvas() ~= shot.canvas then return false end

    if math.abs(nh - 2 * baScale) > EPS then return false end
    if math.abs(ny - (sourceLy + 89 * baScale)) > EPS then return false end

    local progress = nw / baScale
    if not (progress > 0 and progress <= 67.5) then return false end

    -- Confirm the right-anchored QOL formula.  Menu clipping can trim the
    -- left side, so allow nx to move right but never left of its source bar.
    local sourceX = sourcePw - (13 + progress) * baScale
    if nx < sourceX - EPS or nx > sourcePw - 13 * baScale + EPS then
      return false
    end

    local geo, pw, _, hs = targetGeometry(battle, shot)
    if not geo then return false end
    local playerBandY = tonumber(geo.playerBandY)
    if not playerBandY then return false end
    local targetW = progress * hs
    local targetX = pw - 13 * hs - targetW
    local targetY = playerBandY + 41 * hs

    innerRectangle("fill", targetX, targetY, targetW, 2 * hs)
    burstRoute = {
      shot = shot,
      baScale = baScale,
      hs = hs,
      sourceBaseX = sourcePw - (13 + 67) * baScale,
      sourceBaseY = sourceLy + 90 * baScale,
      targetBaseX = pw - (13 + 67) * hs,
      targetBaseY = targetY + hs,
    }
    return true
  end

  local function routeXpBurst(shot, nx, ny, nw, nh)
    local r = burstRoute
    if not (r and r.shot == shot and g.getCanvas() == shot.canvas) then return false end
    if math.abs(nw - r.baScale) > EPS or math.abs(nh - r.baScale) > EPS then
      return false
    end
    if nx < r.sourceBaseX - 32 * r.baScale
        or nx > r.sourceBaseX + 32 * r.baScale
        or ny < r.sourceBaseY - 32 * r.baScale
        or ny > r.sourceBaseY + 32 * r.baScale then
      return false
    end
    local ux = (nx - r.sourceBaseX) / r.baScale
    local uy = (ny - r.sourceBaseY) / r.baScale
    innerRectangle("fill", r.targetBaseX + ux * r.hs,
      r.targetBaseY + uy * r.hs, r.hs, r.hs)
    return true
  end

  -- QOL's caught indicator is a 6x6 or 7x7 cluster of shot.scale-square
  -- rectangles in the snapped enemy HUD.  Its voxel path assumes Battle Art's
  -- enemy band starts at -8*scale.  KIM's final band uses its own snap origin;
  -- preserve the icon's native HUD-local coordinate and rebase it there.
  local function routeCaughtPixel(battle, shot, nx, ny, nw, nh)
    if battle.kind ~= "wild" or g.getCanvas() ~= shot.canvas then return false end
    local baScale = tonumber(shot.scale)
    local sourceLy = tonumber(shot.ly)
    if not (baScale and baScale > 0 and sourceLy) then return false end
    if math.abs(nw - baScale) > EPS or math.abs(nh - baScale) > EPS then
      return false
    end

    -- All QOL caught-indicator modes live in this very small source window.
    -- The bounds include short-name centering and the RED/GREY +1px offset,
    -- while excluding the enemy HP gauge and ordinary battle FX.
    local sourceLocalX = nx / baScale
    local sourceLocalY = (ny - sourceLy) / baScale
    if sourceLocalX < -3 or sourceLocalX > 36
        or sourceLocalY < 6 or sourceLocalY > 18 then
      return false
    end

    local geo, _, _, hs = targetGeometry(battle, shot)
    if not geo then return false end
    local enemyBandX = tonumber(geo.enemyBandX)
    local enemyBandY = tonumber(geo.enemyBandY)
    if not (enemyBandX and enemyBandY) then return false end

    -- Recover the native HUD-space pixel from Battle Art's historical snapped
    -- enemy-band origin (-8*scale), then place the same pixel inside KIM's
    -- actual enemy band.  This automatically preserves every QOL icon style.
    local nativeX = sourceLocalX + 8
    local nativeY = sourceLocalY
    innerRectangle("fill", enemyBandX + nativeX * hs,
      enemyBandY + nativeY * hs, hs, hs)
    return true
  end

  g._kantoInMotionDesktopQolOverlayAlignment = innerRectangle
  g.rectangle = function(mode, x, y, w, h, ...)
    local battle = currentBattle()
    local nx, ny, nw, nh = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
    if battle and stageActive() and mode == "fill"
        and nx and ny and nw and nh then
      local shot = rawget(battle, "dramaticShapeShot")
      if type(shot) == "table" and shot.canvas and not shot.kantoInMotion2D then
        if routeXpMain(battle, shot, nx, ny, nw, nh)
            or routeXpBurst(shot, nx, ny, nw, nh)
            or routeCaughtPixel(battle, shot, nx, ny, nw, nh) then
          return
        end
      end
    end
    burstRoute = nil
    return innerRectangle(mode, x, y, w, h, ...)
  end

  if mod and mod.events and type(mod.events.on) == "function" then
    mod.events:on("battle.started", function(event)
      activeBattle = event and event.battle or nil
      burstRoute = nil
    end)
    mod.events:on("battle.ended", function(event)
      if not event or event.battle == activeBattle then activeBattle = nil end
      burstRoute = nil
    end)
  end

  return true
end
