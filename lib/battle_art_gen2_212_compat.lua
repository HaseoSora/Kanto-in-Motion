-- Kanto in Motion -> Battle Art Voxel Gen2 2.1.x compatibility bridge.
--
-- v13 fixed the HD-card path by supersampling the exact Gen2 drawPic result
-- before Battle Art maps it onto a 3D billboard. v19 keeps the accepted v16
-- foot-anchored shadow path and fixes the HP/status HUD at the render seam Gen2
-- Battle Art actually uses: BattleState:drawWidescreen(). The native Gen2 enemy
-- and player HUD calls are captured while Battle Art's own Chrome styling is
-- active, removed from the centered panel, then composited at the world edges:
--   * Battle Art's alpha-shaped Pokemon caster is suppressed ONLY for KIM's
--     supersampled Pokemon cards.
--   * those visible KIM cards do not sample the scene shadow map, preventing
--     the same self/receiver striping that Gen1 Battle Art once showed.
--   * KIM's own PKMN SHADOWS quality/opacity system renders a layered contact
--     ellipse horizontally on the 3D arena floor, following live Gen2 size and
--     horizontal battle motion.
--
-- Battle Art still owns the arena, camera, card geometry, trainers,
-- substitutes, fainting, move effects and every non-Pokemon world shadow.
-- Battle Art files are never modified.
return function(mod, battleHudGeometry, battleUiViewportRect, battleWorldMetrics, touchBattleOrientation)
  if not mod then return false end

  local FACTOR = 4
  local unpackCompat = table.unpack or unpack
  local GB_W, GB_H = 160, 144
  local WORLD_PER_GB_PX = 16 / 56
  -- KIM's direct shadow radii are authored in final GB/screen-space. A floor
  -- decal sees an additional perspective squash along camera depth, so the
  -- Battle Art world version needs its own presentation calibration instead
  -- of treating screen-space ry as a raw world-space depth radius.
  local WORLD_SHADOW_WIDTH_GAIN = 1.28
  local WORLD_SHADOW_DEPTH_GAIN = 2.25
  local WORLD_SHADOW_MIN_DEPTH_FROM_WIDTH = 0.44
  local WORLD_SHADOW_ALPHA_GAIN = 2.00
  local WORLD_SHADOW_FOOT_EPS = 0.02
  local PLAYER_SLOT_X, ENEMY_SLOT_X = 40, 124
  local installed = false
  local canvases = {}
  local kimCardCanvases = setmetatable({}, { __mode = "k" })
  local currentRender = nil
  local shadowPlane = nil
  local shadowMask = nil
  local edgeHudOverworldBattle = nil
  local edgeHudCaptureState = nil
  local edgeHudCaptureCanvases = {}
  local edgeHudCaptureReady = { enemy = false, player = false }
  local edgeHudQuads = nil

  -- Gen2 Battle Art does not run the Gen1 drawHUDs/snapHUDs path. Its adapter
  -- replaces BattleState:drawWidescreen() and calls the native Gen2
  -- drawEnemyHud()/drawPlayerHud() from inside Battle Art's styled compositor.
  -- Capture those exact calls there: this preserves native G/S/C timing, party
  -- balls, caught icon, EXP bar and Battle Art's current HUD ink treatment.
  local function currentShot()
    local O = edgeHudOverworldBattle
    if not (O and type(O.shot) == "function") then return nil end
    local ok, shot = pcall(O.shot)
    if ok and type(shot) == "table" and shot.canvas then return shot end
    return nil
  end

  local function edgeHudCanvas(side)
    local c = edgeHudCaptureCanvases[side]
    if c and type(c.getDimensions) == "function" then
      local ok, w, h = pcall(c.getDimensions, c)
      if ok and w == GB_W and h == GB_H then return c end
    end
    local g = love and love.graphics
    if not (g and type(g.newCanvas) == "function") then return nil end
    local ok, made = pcall(g.newCanvas, GB_W, GB_H, { dpiscale = 1 })
    if not ok or not made then ok, made = pcall(g.newCanvas, GB_W, GB_H) end
    if not (ok and made) then return nil end
    if made.setFilter then pcall(made.setFilter, made, "nearest", "nearest") end
    if c and c.release then pcall(c.release, c) end
    edgeHudCaptureCanvases[side] = made
    return made
  end

  local function captureNativeHud(side, battle, drawFn, ...)
    local args = { n = select("#", ...), ... }
    if edgeHudCaptureState ~= battle then
      return drawFn(battle, unpackCompat(args, 1, args.n))
    end
    local canvas = edgeHudCanvas(side)
    local g = love and love.graphics
    if not (canvas and g and type(g.setCanvas) == "function") then
      return drawFn(battle, ...)
    end

    local previous = g.getCanvas and g.getCanvas() or nil
    local pushed = type(g.push) == "function" and pcall(g.push, "all") or false
    local ok, err = pcall(function()
      g.setCanvas(canvas)
      if g.origin then g.origin() end
      if g.setShader then g.setShader() end
      if g.setScissor then g.setScissor() end
      if g.setStencilTest then g.setStencilTest() end
      if g.setColorMask then g.setColorMask(true, true, true, true) end
      if g.setBlendMode then g.setBlendMode("alpha") end
      g.setColor(1, 1, 1, 1)
      g.clear(0, 0, 0, 0)
      drawFn(battle, unpackCompat(args, 1, args.n))
    end)
    if previous then g.setCanvas(previous) else g.setCanvas() end
    if pushed and type(g.pop) == "function" then pcall(g.pop) end
    if not ok then error(err, 0) end
    edgeHudCaptureReady[side] = true
  end

  local function hudQuads()
    if edgeHudQuads then return edgeHudQuads end
    local g = love and love.graphics
    if not (g and type(g.newQuad) == "function") then return nil end
    edgeHudQuads = {
      enemy = g.newQuad(0, 0, GB_W, 48, GB_W, GB_H),
      player = g.newQuad(0, 48, GB_W, 48, GB_W, GB_H),
    }
    return edgeHudQuads
  end

  local function drawCapturedEdgeHud(shot, winW, winH)
    local O = edgeHudOverworldBattle
    local g = love and love.graphics
    if not (O and shot and shot.canvas and g and type(g.draw) == "function"
        and type(O.snapRects) == "function") then return false end
    local okRects, _, bandX = pcall(O.snapRects, shot)
    if not okRects or type(bandX) ~= "table" then return false end
    local quads = hudQuads()
    if not quads then return false end

    local pw, ph = tonumber(shot.pw), tonumber(shot.ph)
    if (not pw or not ph) and type(shot.canvas.getDimensions) == "function" then
      local okD, cw, ch = pcall(shot.canvas.getDimensions, shot.canvas)
      if okD then pw, ph = cw, ch end
    end
    pw, ph = pw or tonumber(winW), ph or tonumber(winH)
    if not (pw and ph and pw > 0 and ph > 0) then return false end
    winW, winH = tonumber(winW) or pw, tonumber(winH) or ph
    local outX, outY = winW / pw, winH / ph
    local battleScale = tonumber(shot.scale) or 1
    local ly = tonumber(shot.ly) or 0

    local pushed = type(g.push) == "function" and pcall(g.push, "all") or false
    local ok, err = pcall(function()
      if g.origin then g.origin() end
      if g.setShader then g.setShader() end
      if g.setScissor then g.setScissor() end
      if g.setStencilTest then g.setStencilTest() end
      if g.setColorMask then g.setColorMask(true, true, true, true) end
      if g.setBlendMode then g.setBlendMode("alpha") end
      g.setColor(1, 1, 1, 1)
      if edgeHudCaptureReady.enemy and edgeHudCaptureCanvases.enemy then
        g.draw(edgeHudCaptureCanvases.enemy, quads.enemy,
          (tonumber(bandX.enemy) or 0) * outX, ly * outY, 0,
          battleScale * outX, battleScale * outY)
      end
      if edgeHudCaptureReady.player and edgeHudCaptureCanvases.player then
        g.draw(edgeHudCaptureCanvases.player, quads.player,
          (tonumber(bandX.player) or 0) * outX,
          (ly + 48 * battleScale) * outY, 0,
          battleScale * outX, battleScale * outY)
      end
    end)
    if pushed and type(g.pop) == "function" then pcall(g.pop) end
    if not ok then error(err, 0) end
    return true
  end

  local function findBattleArt()
    if type(mod.find) ~= "function" then return nil end
    local ok, handle = pcall(mod.find, mod, "BATTLE_ART_VOXEL_GEN2")
    if not ok or not handle then
      ok, handle = pcall(mod.find, "BATTLE_ART_VOXEL_GEN2")
    end
    return ok and handle or nil
  end

  local function runtime()
    local handle = findBattleArt()
    local exports = handle and handle.exports
    local lib = type(exports) == "table" and exports.lib or nil
    if not (type(lib) == "table" and type(lib.require) == "function") then
      return nil
    end
    local okO, OverworldBattle = pcall(lib.require, "OverworldBattle")
    if not okO or type(OverworldBattle) ~= "table" then return nil end
    return OverworldBattle, lib
  end

  local function canvasFor(side)
    local w, h = GB_W * FACTOR, GB_H * FACTOR
    local c = canvases[side]
    if c and type(c.getDimensions) == "function" then
      local ok, cw, ch = pcall(c.getDimensions, c)
      if ok and cw == w and ch == h then return c end
    end
    local g = love and love.graphics
    if not (g and type(g.newCanvas) == "function") then return nil end
    local ok, made = pcall(g.newCanvas, w, h, { dpiscale = 1 })
    if not ok or not made then ok, made = pcall(g.newCanvas, w, h) end
    if not (ok and made) then return nil end
    if made.setFilter then pcall(made.setFilter, made, "nearest", "nearest") end
    if c and c.release then pcall(c.release, c) end
    canvases[side] = made
    return made
  end

  local function activeMon(battle, side)
    if not battle then return nil end
    if type(battle.activeMon) == "function" then
      local ok, mon = pcall(battle.activeMon, battle, side)
      if ok then return mon end
    end
    local model = battle.battle
    if type(model) == "table" then return model[side] end
    return battle[side]
  end

  local function isSubstitute(battle, mon, side)
    local anim
    if battle and type(battle.animPicState) == "function" then
      local ok, got = pcall(battle.animPicState, battle, side)
      if ok then anim = got end
    end
    local over = anim and anim.pic
    if over ~= nil then return over == "substitute" end
    local volatile = mon and mon.volatile
    return type(volatile) == "table"
      and (tonumber(volatile.substitute) or 0) > 0
  end

  local function battleSpritesEnabled()
    if not (mod.options and type(mod.options.get) == "function") then return true end
    local ok, enabled = pcall(mod.options.get, mod.options, "battleSprites")
    return not ok or enabled ~= false
  end

  local function capture(battle, side, base)
    -- The original Battle Art capture remains authoritative for metadata and
    -- all special ownership. Only replace actual Pokemon cards.
    if type(base) ~= "table" or base.trainer then return base end
    if not battleSpritesEnabled() then return base end
    if type(battle.drawPic) ~= "function" then return base end

    local mon = activeMon(battle, side)
    if not mon or isSubstitute(battle, mon, side) then return base end

    local canvas = canvasFor(side)
    if not canvas then return base end

    -- Battle Art's own Gen2 path turns faint cropping into a world-space sink
    -- so the complete card can descend through the ground. Mirror that rule;
    -- the sink value already returned by the original capture is preserved.
    local savedFaintSlide
    if battle.faintSlide and battle.faintSlide.side == side then
      savedFaintSlide = battle.faintSlide
      battle.faintSlide = nil
    end

    local g = love and love.graphics
    if not g then
      if savedFaintSlide then battle.faintSlide = savedFaintSlide end
      return base
    end

    local oldSetScissor = g.setScissor
    local oldIntersectScissor = g.intersectScissor
    local oldGetScissor = g.getScissor

    -- LÖVE scissors live in physical Canvas coordinates and do not inherit the
    -- graphics transform. KIM's Gen2 lifted-band code specifies logical GB
    -- coordinates, so scale those scissors alongside the 4x draw transform.
    local function scaleScissor(fn)
      return function(x, y, w, h)
        if x == nil then return fn() end
        return fn((tonumber(x) or 0) * FACTOR,
          (tonumber(y) or 0) * FACTOR,
          (tonumber(w) or 0) * FACTOR,
          (tonumber(h) or 0) * FACTOR)
      end
    end

    local pushed = false
    if type(g.push) == "function" then
      pushed = pcall(g.push, "all")
      if not pushed then pushed = pcall(g.push) end
    end
    if not pushed then
      if savedFaintSlide then battle.faintSlide = savedFaintSlide end
      return base
    end

    local previousCapture = mod._kantoInMotionGen2BattleArtCapture
    mod._kantoInMotionGen2BattleArtCapture = true

    local ok, err = pcall(function()
      g.setCanvas(canvas)
      if g.origin then g.origin() end
      if g.setShader then g.setShader() end
      if g.setStencilTest then g.setStencilTest() end
      if g.setColorMask then g.setColorMask(true, true, true, true) end
      g.setScissor()
      g.setBlendMode("alpha")
      g.setColor(1, 1, 1, 1)
      g.clear(0, 0, 0, 0)

      g.setScissor = scaleScissor(oldSetScissor)
      if type(oldIntersectScissor) == "function" then
        g.intersectScissor = scaleScissor(oldIntersectScissor)
      end
      if type(oldGetScissor) == "function" then
        g.getScissor = function()
          local x, y, w, h = oldGetScissor()
          if x == nil then return nil end
          return x / FACTOR, y / FACTOR, w / FACTOR, h / FACTOR
        end
      end

      g.scale(FACTOR, FACTOR)
      battle:drawPic(mon, side == "player")
    end)

    g.setScissor = oldSetScissor
    g.intersectScissor = oldIntersectScissor
    g.getScissor = oldGetScissor
    mod._kantoInMotionGen2BattleArtCapture = previousCapture
    if pushed and type(g.pop) == "function" then pcall(g.pop) end
    if savedFaintSlide then battle.faintSlide = savedFaintSlide end

    if not ok then
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("Battle Art Gen2 HD card capture failed (%s): %s",
          tostring(side), tostring(err))
      end
      return base
    end

    local out = {}
    for k, v in pairs(base) do out[k] = v end
    out.canvas = canvas
    out.kimHdSupersampled = true
    out.kimHdFactor = FACTOR
    kimCardCanvases[canvas] = side
    return out
  end

  local function shadowMetrics(side)
    local all = mod._kantoInMotionGen2BattleArtShadowMetrics
    return type(all) == "table" and all[side] or nil
  end

  local function shadowSystem()
    local shadows = mod._kantoInMotionBattlerShadows
    if type(shadows) ~= "table" then return nil end
    if type(shadows.paramsFor) ~= "function" then return nil end
    return shadows
  end

  local function ensureShadowPlane(Voxel3D)
    if shadowPlane then return shadowPlane end
    if not (Voxel3D and type(Voxel3D.newMesh) == "function") then return nil end
    local verts = {
      { -0.5, 0, -0.5, 0, 0, 1 },
      {  0.5, 0, -0.5, 1, 0, 1 },
      {  0.5, 0,  0.5, 1, 1, 1 },
      { -0.5, 0,  0.5, 0, 1, 1 },
    }
    local map = { 1, 2, 3, 1, 3, 4 }
    local ok, mesh = pcall(Voxel3D.newMesh, verts, map)
    if ok and mesh then shadowPlane = mesh end
    return shadowPlane
  end

  local function ensureShadowMask()
    if shadowMask then return shadowMask end
    local g = love and love.graphics
    if not (g and type(g.newCanvas) == "function") then return nil end
    local ok, c = pcall(g.newCanvas, 64, 64, { dpiscale = 1 })
    if not ok or not c then ok, c = pcall(g.newCanvas, 64, 64) end
    if not (ok and c) then return nil end
    local pushed = false
    if type(g.push) == "function" then
      pushed = pcall(g.push, "all")
      if not pushed then pushed = pcall(g.push) end
    end
    if not pushed then
      if c.release then pcall(c.release, c) end
      return nil
    end
    local drew = pcall(function()
      g.setCanvas(c)
      if g.origin then g.origin() end
      if g.setShader then g.setShader() end
      if g.setScissor then g.setScissor() end
      if g.setBlendMode then g.setBlendMode("alpha") end
      g.clear(0, 0, 0, 0)
      g.setColor(1, 1, 1, 1)
      g.ellipse("fill", 32, 32, 29, 29)
    end)
    if type(g.pop) == "function" then pcall(g.pop) end
    if not drew then
      if c.release then pcall(c.release, c) end
      return nil
    end
    if c.setFilter then pcall(c.setFilter, c, "linear", "linear") end
    shadowMask = c
    return shadowMask
  end

  local function kimShadowOwned(side)
    return shadowSystem() ~= nil and shadowMetrics(side) ~= nil
  end

  local function drawWorldShadow(side, Voxel3D, Mat4, BattleBillboard,
                                 originalVoxelDraw, noShadowLookup)
    local ctx = currentRender
    if not (ctx and side and not ctx.shadowDrawn[side]) then return end
    ctx.shadowDrawn[side] = true

    local shadows = shadowSystem()
    local metrics = shadowMetrics(side)
    if not (shadows and metrics) then return end
    local okP, params = pcall(shadows.paramsFor, shadows, metrics, side, 1)
    if not okP or type(params) ~= "table" then return end

    local mesh = ensureShadowPlane(Voxel3D)
    local mask = ensureShadowMask()
    if not (mesh and mask and type(ctx.arena) == "table") then return end

    local cell = side == "player" and ctx.arena.player or ctx.arena.enemy
    if type(cell) ~= "table" then return end
    local x, z = tonumber(cell[1]), tonumber(cell[2])
    if not (x and z) then return end

    -- Gen2's HD metrics publish the actual visual centre after native slide /
    -- SCX movement. Carry horizontal movement onto the floor along the same
    -- camera-facing card axis; vertical move animation never lifts the shadow.
    local authoredX = side == "player" and PLAYER_SLOT_X or ENEMY_SLOT_X
    local dx = ((tonumber(params.cx) or authoredX) - authoredX) * WORLD_PER_GB_PX
    if dx ~= 0 and BattleBillboard
        and type(BattleBillboard.yawToward) == "function" then
      local okY, yaw = pcall(BattleBillboard.yawToward, x, z, Voxel3D.eye)
      if okY and type(yaw) == "number" then
        x = x + math.cos(yaw) * dx
        z = z - math.sin(yaw) * dx
      end
    end

    -- BattleScene.groundY is the shared BATTLE FLOOR used by the Pokemon
    -- card itself. It already includes Battle Art's one-world-pixel clearance
    -- over the terrain. v15 incorrectly dropped the contact shadow back to the
    -- terrain surface, so perspective separated the shadow from the card's feet
    -- and made the Pokemon read as floating. Keep the decal on the SAME battle
    -- floor as the battler root, with only a tiny downward epsilon to preserve
    -- depth ordering.
    local y = (tonumber(ctx.groundY) or 0) - WORLD_SHADOW_FOOT_EPS
    local rx = tonumber(params.rx) or 0
    local ry = tonumber(params.ry) or 0
    if rx <= 0 or ry <= 0 then return end

    -- The direct KIM ellipse is already flattened for a 2D screen. On a 3D
    -- floor that depth axis is foreshortened a second time by the camera, which
    -- is why v14 appeared as a tiny/thin mark under low-bodied Pokemon. Expand
    -- the floor depth before projection while keeping the same KIM footprint
    -- inputs and user quality/opacity settings.
    local worldRx = rx * WORLD_PER_GB_PX * WORLD_SHADOW_WIDTH_GAIN
    local depthPx = math.max(ry * WORLD_SHADOW_DEPTH_GAIN,
      rx * WORLD_SHADOW_MIN_DEPTH_FROM_WIDTH)
    local worldRz = depthPx * WORLD_PER_GB_PX

    local layers = math.max(1, math.floor(tonumber(params.layers) or 1))
    local feather = math.max(0, tonumber(params.feather) or 0)
    -- A translucent decal in the lit 3D world reads substantially lighter than
    -- the same alpha on KIM's direct 2D battle surface. Calibrate only the
    -- Battle Art floor presentation; SHADOW OPACITY remains the source value.
    local baseAlpha = math.max(0, math.min(0.72,
      (tonumber(params.alpha) or 0) * WORLD_SHADOW_ALPHA_GAIN))
    if baseAlpha <= 0 then return end

    -- Face the ellipse's major axis the same way as the Pokemon billboard.
    -- Keep its CENTER on the battler root. v15 also pushed the decal backward
    -- in local Z to mimic the flat 2D tuck; in perspective that became a visible
    -- world-space offset. The 3D path now uses the actual foot/root position.
    local yaw = 0
    if BattleBillboard and type(BattleBillboard.yawToward) == "function" then
      local okY, got = pcall(BattleBillboard.yawToward, x, z, Voxel3D.eye)
      if okY and type(got) == "number" then yaw = got end
    end
    local function shadowModel(spread)
      local base = Mat4.mul(Mat4.translate(x, y, z), Mat4.rotateY(yaw))
      return Mat4.mul(base, Mat4.scale(worldRx * 2 * spread, 1,
        worldRz * 2 * spread))
    end

    if type(Voxel3D.beginShadows) == "function" then Voxel3D.beginShadows() end
    local g = love and love.graphics
    if g and type(g.setColor) == "function" then
      if layers == 1 then
        g.setColor(0, 0, 0, baseAlpha)
        originalVoxelDraw(mesh, mask, shadowModel(1), 0, noShadowLookup)
      else
        local perLayer = baseAlpha / layers
        for i = layers, 1, -1 do
          local t = (i - 1) / (layers - 1)
          local spread = 1 + feather * t
          local weight = 0.60 + 0.80 * (1 - t)
          g.setColor(0, 0, 0, math.min(0.34, perLayer * weight))
          originalVoxelDraw(mesh, mask, shadowModel(spread), 0, noShadowLookup)
        end
      end
    end
    if type(Voxel3D.endShadows) == "function" then Voxel3D.endShadows() end
  end

  local function install()
    if installed then return true end
    local OverworldBattle, lib = runtime()
    if not (OverworldBattle and type(OverworldBattle.sideTexture) == "function") then
      return false
    end
    if OverworldBattle._kantoInMotionGen2HdCardsV19 then
      installed = true
      return true
    end

    local inner = OverworldBattle.sideTexture
    OverworldBattle._kantoInMotionGen2HdCardsV19 = inner
    OverworldBattle.sideTexture = function(battle, side)
      local base = inner(battle, side)
      return capture(battle, side, base)
    end

    -- Gen2 Battle Art's active presentation seam is drawWidescreen(), not the
    -- Gen1 drawHUDs/snapHUDs path. Wrap the already-installed Battle Art Gen2
    -- adapter, capture the two native HUD functions while its Chrome styling is
    -- live, then replay those pixels at the same edge geometry Battle Art uses
    -- for Gen1. The centered copy disappears because the intercepted HUD calls
    -- never draw into the native 160x144 panel during this pass.
    edgeHudOverworldBattle = OverworldBattle
    local okBattleState, BattleState = pcall(require, "src.battle.BattleState")
    if okBattleState and type(BattleState) == "table"
        and BattleState.battleArtGen2WidescreenAdapter == true
        and type(BattleState.drawWidescreen) == "function"
        and type(BattleState.drawEnemyHud) == "function"
        and type(BattleState.drawPlayerHud) == "function"
        and type(OverworldBattle.snapRects) == "function"
        and not BattleState._kantoInMotionGen2BattleArtEdgeHudV19 then
      local originalDrawWidescreen = BattleState.drawWidescreen
      local originalDrawEnemyHud = BattleState.drawEnemyHud
      local originalDrawPlayerHud = BattleState.drawPlayerHud
      BattleState._kantoInMotionGen2BattleArtEdgeHudV19 = originalDrawWidescreen
      BattleState._kantoInMotionGen2BattleArtEnemyHudV19 = originalDrawEnemyHud
      BattleState._kantoInMotionGen2BattleArtPlayerHudV19 = originalDrawPlayerHud

      BattleState.drawEnemyHud = function(self, ...)
        return captureNativeHud("enemy", self, originalDrawEnemyHud, ...)
      end
      BattleState.drawPlayerHud = function(self, ...)
        return captureNativeHud("player", self, originalDrawPlayerHud, ...)
      end

      BattleState.drawWidescreen = function(self, winW, winH, ...)
        local shot = currentShot()
        if not shot then return originalDrawWidescreen(self, winW, winH, ...) end
        edgeHudCaptureReady.enemy, edgeHudCaptureReady.player = false, false
        local previous = edgeHudCaptureState
        edgeHudCaptureState = self
        local ok, result = pcall(originalDrawWidescreen, self, winW, winH, ...)
        edgeHudCaptureState = previous
        if not ok then error(result, 0) end
        drawCapturedEdgeHud(shot, winW, winH)
        return result
      end
    end

    -- Shadow compatibility is installed through Battle Art's public module
    -- table at runtime. No third-party file is rewritten.
    if type(lib) == "table" and type(lib.require) == "function" then
      local okScene, BattleScene = pcall(lib.require, "BattleScene")
      local okVoxel, Voxel3D = pcall(lib.require, "Voxel3D")
      local okShadow, ShadowMap = pcall(lib.require, "ShadowMap")
      local okMat, Mat4 = pcall(lib.require, "Mat4")
      local okBill, BattleBillboard = pcall(lib.require, "BattleBillboard")
      if okScene and type(BattleScene) == "table"
          and type(BattleScene.render) == "function"
          and okVoxel and type(Voxel3D) == "table"
          and type(Voxel3D.draw) == "function"
          and okShadow and type(ShadowMap) == "table"
          and type(ShadowMap.draw) == "function"
          and okMat and type(Mat4) == "table"
          and type(Mat4.translate) == "function"
          and type(Mat4.scale) == "function"
          and type(Mat4.rotateY) == "function"
          and type(Mat4.mul) == "function"
          and okBill and type(BattleBillboard) == "table" then

        local originalRender = BattleScene.render
        local originalVoxelDraw = Voxel3D.draw
        local originalShadowDraw = ShadowMap.draw
        local noShadowLookup = Mat4.translate(1000000, 0, 1000000)

        BattleScene.render = function(state, arena, textures, token, battle,
                                     animTex, animAnchors, externalCamera,
                                     externalModelShadow, drawActors)
          local previous = currentRender
          local groundY = nil
          local host = type(arena) == "table" and (arena.map or (state and state.map))
          if host and type(BattleScene.groundY) == "function" then
            local okG, got = pcall(BattleScene.groundY, host, arena)
            if okG then groundY = got end
          end
          currentRender = {
            arena = arena,
            textures = textures,
            token = token,
            groundY = groundY,
            shadowDrawn = {},
          }
          local okR, result = pcall(originalRender, state, arena, textures,
            token, battle, animTex, animAnchors, externalCamera,
            externalModelShadow, drawActors)
          currentRender = previous
          if not okR then error(result, 0) end
          return result
        end
        BattleScene._kantoInMotionGen2ShadowContextV16 = originalRender

        -- KIM cards no longer cast Battle Art's silhouette shadow into the sun
        -- map. KIM's own contact ellipse below becomes authoritative instead.
        ShadowMap.draw = function(mesh, texture, model, ...)
          local side = texture and kimCardCanvases[texture] or nil
          if currentRender and side and kimShadowOwned(side) then return end
          return originalShadowDraw(mesh, texture, model, ...)
        end
        ShadowMap._kantoInMotionGen2CardCasterV16 = originalShadowDraw

        -- Draw the KIM contact shadow immediately before the corresponding
        -- Pokemon card. Then keep that card out of the shadow-map receiver
        -- lookup, matching KIM's proven Gen1 Battle Art self-shadow fix.
        Voxel3D.draw = function(mesh, texture, model, pull, sunModel)
          local side = texture and kimCardCanvases[texture] or nil
          if currentRender and side and kimShadowOwned(side) then
            drawWorldShadow(side, Voxel3D, Mat4, BattleBillboard,
              originalVoxelDraw, noShadowLookup)
            return originalVoxelDraw(mesh, texture, model, pull,
              noShadowLookup)
          end
          return originalVoxelDraw(mesh, texture, model, pull, sunModel)
        end
        Voxel3D._kantoInMotionGen2HdCardShadowV16 = originalVoxelDraw
      end
    end

    installed = true
    if mod.log and type(mod.log.info) == "function" then
      mod.log:info("Battle Art Gen2 compatibility enabled (4x HD cards + foot-anchored KIM shadows + widescreen-native edge HUD v19)")
    end
    return true
  end

  install()
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function() pcall(install) end)
  end

  local api = {}
  function api:isInstalled() return installed end
  function api:refresh() return install() end
  function api:factor() return FACTOR end
  return api
end
