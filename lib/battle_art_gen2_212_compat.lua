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
  local edgeHud3dActive = false
  local edgeHudCaptureSide = nil
  local edgeHudCapturedTileHud = nil
  local edgeHudCaughtWasDrawn = false
  local edgeHudOriginalCaught = nil
  local edgeHudCaptureCanvases = {}
  local edgeHudCaptureReady = { enemy = false, player = false }
  local edgeHudQuads = nil

  -- QOL 1.3.0 Gen2 replaces the native caught tile with 7x7 RED/GREY
  -- pixels drawn at absolute (8,8) in battle.overlay.  The native draw is
  -- already suppressed by QOL's dexCaught wrapper, so the replacement must
  -- be painted into the exact enemy HUD capture that KIM repositions.
  local QOL_BALL = {
    "ooxxxoo", "oxdddxo", "xdldddx", "xdddddx",
    "xlllllx", "oxlllxo", "ooxxxoo",
  }
  local QOL_RED = {
    {255,255,255}, {255,132,132}, {148,58,58}, {0,0,0},
  }
  local QOL_GREY = {
    {255,255,255}, {170,170,170}, {85,85,85}, {0,0,0},
  }
  local function qolCaughtMode(battle)
    local game = battle and battle.game
    local options = game and game.save and game.save.options
    local values = options and options.modOptions
      and options.modOptions.quality_of_life
    local mode = values and values.qol_caught_indicator
    if mode == nil and mod and type(mod.find) == "function" then
      local ok, handle = pcall(mod.find, mod, "quality_of_life")
      if not ok or not handle then ok, handle = pcall(mod.find, "quality_of_life") end
      if ok and handle and handle.options and type(handle.options.get) == "function" then
        local okMode, fallback = pcall(handle.options.get, handle.options,
          "qol_caught_indicator")
        if okMode then mode = fallback end
      end
    end
    return mode == "red" and "red" or mode == "grey" and "grey" or nil
  end
  local function needsQolCapturedCaught(battle)
    local mode = qolCaughtMode(battle)
    if not mode then return nil end
    if not (battle and battle.battle and battle.battle.wild
        and battle.showEnemyHud and not battle:hudCleared("enemy")) then
      return nil
    end
    local okEnemy, enemy = pcall(battle.activeMon, battle, "enemy")
    if not okEnemy or not enemy then return nil end
    local okHud, BattleState = pcall(require, "src.ui.gen2.BattleState")
    local vanillaCaught = okHud and BattleState
      and rawget(BattleState, "__qolDexCaughtVanilla")
    if type(vanillaCaught) ~= "function" then return nil end
    local okCaught, caught = pcall(vanillaCaught, battle, enemy)
    return okCaught and caught and mode or nil
  end
  local function paintQolCapturedCaught(battle)
    local mode = needsQolCapturedCaught(battle)
    if not mode then return end
    local okPal, Palette = pcall(require, "src.render.GbcPalette")
    if not okPal or type(Palette.color) ~= "function" then return end
    local source = mode == "red" and QOL_RED or QOL_GREY
    local colors = { x = Palette.color(source, 4),
      d = Palette.color(source, 3), l = Palette.color(source, 2) }
    local g = love.graphics
    if type(g.setShader) == "function" then g.setShader() end
    for ry, row in ipairs(QOL_BALL) do
      for rx = 1, #row do
        local color = colors[row:sub(rx, rx)]
        if color then
          g.setColor(color[1] / 255, color[2] / 255, color[3] / 255, 1)
          g.rectangle("fill", 8 + rx - 1, 8 + ry - 1, 1, 1)
        end
      end
    end
  end

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
    local priorSide = edgeHudCaptureSide
    edgeHudCaptureSide = side
    edgeHudCapturedTileHud = nil
    edgeHudCaughtWasDrawn = false
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
      if side == "enemy" then
        -- Battle Art's native HUD compositor can bypass drawCaughtIcon,
        -- even when Gen2's own unmodified indicator is selected. Recreate
        -- that tile ON the captured enemy canvas, never on its centered pass.
        -- The existing native draw takes precedence when it ran normally.
        if not edgeHudCaughtWasDrawn and edgeHudCapturedTileHud
            and type(edgeHudOriginalCaught) == "function"
            and not qolCaughtMode(battle) then
          local caught = battle.caughtMark == true
          if not caught and type(battle.dexCaught) == "function"
              and type(battle.activeMon) == "function" then
            local okEnemy, mon = pcall(battle.activeMon, battle, "enemy")
            if okEnemy and mon then
              local okCaught, known = pcall(battle.dexCaught, battle, mon)
              caught = okCaught and known == true
            end
          end
          if caught and battle.battle and battle.battle.wild then
            local mon
            if type(battle.activeMon) == "function" then
              local okMon, got = pcall(battle.activeMon, battle, "enemy")
              if okMon then mon = got end
            end
            pcall(edgeHudOriginalCaught, edgeHudCapturedTileHud, 1, 1,
              mon and mon.hp, mon and (mon.maxHp or mon.maxHP))
          end
        end
        paintQolCapturedCaught(battle)
      end
    end)
    if previous then g.setCanvas(previous) else g.setCanvas() end
    if pushed and type(g.pop) == "function" then pcall(g.pop) end
    edgeHudCaptureSide = priorSide
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
    -- Desktop KIM-owned edge HUD: use the same visible-pixel inset as Gen 1
    -- WIDE, instead of the Battle Art band origin that clips the left edge.
    local desktopEnemyBandX = tonumber(bandX.enemy) or 0
    local okGeo, geo = pcall(battleHudGeometry, tonumber(shot.pw) or winW,
      tonumber(shot.ph) or winH, 0, nil)
    if okGeo and type(geo) == "table" and tonumber(geo.enemyBandX) then
      desktopEnemyBandX = tonumber(geo.enemyBandX)
    end

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
          desktopEnemyBandX * outX, ly * outY, 0,
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

      -- Suppress QOL's original RED/GREY raster only in its battle.overlay
      -- pass.  Without this its 7x7 icon remains at the centered 160x144
      -- battle origin even though our captured copy moves with the enemy HUD.
      if mod.hooks and type(mod.hooks.wrap) == "function"
          and not mod._kimGen2QolCaughtOverlayFilter then
        mod._kimGen2QolCaughtOverlayFilter = true
        mod.hooks:wrap("battle.overlay", function(next, battle)
          if not (type(mod._kantoInMotionBattleArt3DBattleEnabled) == "function"
                  and mod._kantoInMotionBattleArt3DBattleEnabled() == true)
              or not qolCaughtMode(battle) or not (love and love.graphics) then
            return next(battle)
          end
          local g = love.graphics
          local originalRectangle = g.rectangle
          g.rectangle = function(shape, x, y, w, h, ...)
            local nx, ny, nw, nh = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
            if shape == "fill" and nx and ny and nw and nh
                and nw == 1 and nh == 1 and nx >= 8 and nx <= 14
                and ny >= 8 and ny <= 14 then
              return
            end
            return originalRectangle(shape, x, y, w, h, ...)
          end
          local results = { pcall(next, battle) }
          g.rectangle = originalRectangle
          if not results[1] then error(results[2], 0) end
          return unpackCompat(results, 2, #results)
        end, 1000)
      end

      -- Gen2 caught icons are native 8x8 tile draws. Battle Art sometimes
      -- makes a second native HUD pass at the centered viewport while KIM
      -- replays the main HP bands at the screen edges. Keep the caught mark
      -- exclusively in the captured enemy band, so it follows the enemy name
      -- and border rather than floating near the middle of the playfield.
      local okCaughtHud, CaughtHud = pcall(require, "src.ui.gen2.BattleHud")
      if okCaughtHud and type(CaughtHud) == "table"
          and type(CaughtHud.drawCaughtIcon) == "function"
          and not CaughtHud._kimBattleArtEdgeCaughtInstalled then
        CaughtHud._kimBattleArtEdgeCaughtInstalled = true
        local drawCaughtSource = CaughtHud.drawCaughtIcon
        edgeHudOriginalCaught = drawCaughtSource
        CaughtHud.drawCaughtIcon = function(hud, tx, ty, hp, maxHp)
          if edgeHudCaptureState and edgeHudCaptureSide == "enemy" then
            edgeHudCaughtWasDrawn = true
            -- Keep the caught mark at its native enemy-HUD-local tile (1,1).
            -- The entire enemy band is already moved to the widescreen edge
            -- by drawCapturedEdgeHud; applying another horizontal shift here
            -- placed the mark far from the name on desktop.
            return drawCaughtSource(hud, 1, 1, hp, maxHp)
          end
          -- Do not emit a detached caught marker into Battle Art's centered
          -- native battle canvas. Preserve native paths when there is no
          -- active Battle Art widescreen shot.
          local stageActive = type(mod._kantoInMotionBattleArt3DBattleEnabled) == "function"
            and mod._kantoInMotionBattleArt3DBattleEnabled() == true
          if stageActive and (currentShot() or edgeHud3dActive) then return true end
          return drawCaughtSource(hud, tx, ty, hp, maxHp)
        end
      end

      -- The Gen 2 caught mark is tile $5d of ExpBarGFX. Some desktop
      -- Battle Art passes call BattleHud:drawTile directly before the native
      -- HUD reaches drawEnemyHud, bypassing drawCaughtIcon interception.
      -- Filter only that caught-mark tile during the 3D scene's native pass;
      -- the offscreen edge HUD capture keeps its copy.
      if okCaughtHud and type(CaughtHud) == "table"
          and type(CaughtHud.drawTile) == "function"
          and not CaughtHud._kimBattleArtEdgeCaughtTileInstalled then
        CaughtHud._kimBattleArtEdgeCaughtTileInstalled = true
        local sourceDrawTile = CaughtHud.drawTile
        CaughtHud.drawTile = function(hud, sheet, first, tile, ...)
          if edgeHudCaptureSide == "enemy" then
            edgeHudCapturedTileHud = hud
          end
          local stageActive = type(mod._kantoInMotionBattleArt3DBattleEnabled) == "function"
            and mod._kantoInMotionBattleArt3DBattleEnabled() == true
          if stageActive and sheet == "expBar" and tonumber(tile) == 0x5d
              and edgeHudCaptureSide ~= "enemy"
              and (currentShot() or currentRender or edgeHud3dActive) then
            return true
          end
          return sourceDrawTile(hud, sheet, first, tile, ...)
        end
      end

      BattleState.drawEnemyHud = function(self, ...)
        local stageActive = type(mod._kantoInMotionBattleArt3DBattleEnabled) == "function"
          and mod._kantoInMotionBattleArt3DBattleEnabled() == true
        if not stageActive then
          return originalDrawEnemyHud(self, ...)
        end
        -- Battle Art calls the native HUD both for the 3D scene and for the
        -- final screen-edge band. The caught mark belongs ONLY in the latter.
        -- The old BattleHud.drawCaughtIcon hook could miss the former because
        -- Battle Art can retain its own renderer references and a screenshot
        -- is not necessarily available yet during the native pass.
        if edgeHudCaptureState == self then
          return captureNativeHud("enemy", self, originalDrawEnemyHud, ...)
        end
        -- The native battle pass can run BEFORE OverworldBattle.shot() is
        -- populated on desktop. A shot-dependent test allowed its caught tile
        -- to leak into the original 160x144 viewport. The Battle Art Gen2
        -- widescreen adapter owns this path: only the explicit offscreen
        -- capture above may draw the caught mark. Its captured 8x8 tile is
        -- then replayed at the relocated enemy HUD edge.
        local savedCaught = self.caughtMark
        if not savedCaught then
          return originalDrawEnemyHud(self, ...)
        end
        -- Suppress only the original caught tile during the centered pass;
        -- preserve native enemy name, gender, HP and frame drawing.
        self.caughtMark = false
        local results = { pcall(originalDrawEnemyHud, self, ...) }
        self.caughtMark = savedCaught
        if not results[1] then error(results[2], 0) end
        return unpackCompat(results, 2, #results)
      end
      BattleState.drawPlayerHud = function(self, ...)
        return captureNativeHud("player", self, originalDrawPlayerHud, ...)
      end

      BattleState.drawWidescreen = function(self, winW, winH, ...)
        -- Native WideBattle owns both HUDs while Gen 2 Battle Art is OFF.
        -- A stale/staged shot may still exist in the Battle Art module; it
        -- must not trigger KIM's second edge-HUD compositing pass.
        local stageActive = type(mod._kantoInMotionBattleArt3DBattleEnabled) == "function"
          and mod._kantoInMotionBattleArt3DBattleEnabled() == true
        if not stageActive then
          edgeHud3dActive = false
          return originalDrawWidescreen(self, winW, winH, ...)
        end
        local shot = currentShot()
        edgeHud3dActive = shot ~= nil
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
