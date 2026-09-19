-- Kanto in Motion -> Battle Art 1.11+ compatibility bridge.
--
-- KIM no longer ships Battle Art's generation sprite assets. When Battle Art
-- owns a live 3D-BTL stage, this bridge leaves its arena/camera/HUD/effects in
-- charge while feeding KIM's new HD animated Pokemon and KRBA move effects into Battle Art's MODDED
-- sprite path. Nothing is copied into or modified inside Battle Art.
return function(mod, battleRecord, renderPresentationFrame, currentFrame)
  local M = {}
  local BA_ID = "BATTLE_ART_VOXEL_FORK"
  local prepared = setmetatable({}, { __mode = "k" })
  local battlerState = setmetatable({}, { __mode = "k" })
  local hookedBa, hookedStage = nil, nil
  local originalPrefersModded, originalViewGet, originalPlacementGet = nil, nil, nil
  local originalTextures = nil
  local originalVoxelDraw, hookedVoxel = nil, nil
  local kimCardCanvases = setmetatable({}, { __mode = "k" })
  local function mobileHost()
    -- Use KIM's host detector instead of caching love.system at module load.
    -- This is the same path already proven by the mobile UI/Potato branches.
    if type(mod._kantoInMotionNativeMobileHost) == "function" then
      local ok, value = pcall(mod._kantoInMotionNativeMobileHost)
      if ok then return value == true end
    end
    local system = love and love.system
    if system and type(system.getOS) == "function" then
      local ok, host = pcall(system.getOS)
      if ok then return host == "Android" or host == "iOS" end
    end
    return false
  end
  local installedUpdate = nil

  local function handle()
    if not (mod and type(mod.find) == "function") then return nil end
    local ok, hit = pcall(mod.find, mod, BA_ID)
    if not ok or not hit then ok, hit = pcall(mod.find, BA_ID) end
    return ok and hit or nil
  end

  local function runtime()
    local hit = handle()
    local exports = hit and hit.exports
    local lib = type(exports) == "table" and exports.lib or nil
    if type(lib) ~= "table" or type(lib.require) ~= "function" then return nil end
    local okBa, ba = pcall(lib.require, "BattleArt")
    local okStage, stage = pcall(lib.require, "OverworldBattle")
    if not okBa or type(ba) ~= "table" or not okStage or type(stage) ~= "table" then
      return nil
    end
    return ba, stage, exports
  end

  local function stageEnabled(stage, exports)
    local public = type(exports) == "table" and exports.battleStage or nil
    if type(public) == "table" and type(public.enabled) == "function" then
      local ok, value = pcall(public.enabled)
      if ok then return value == true end
    end
    if stage and type(stage.enabled) == "function" then
      local ok, value = pcall(stage.enabled)
      return ok and value == true
    end
    return false
  end

  local function kimEnabled(stage, exports)
    if not (mod and mod.options) then return false end
    if mod.options:get("enabled") == false or mod.options:get("battleSprites") == false then
      return false
    end
    return stageEnabled(stage, exports)
  end

  local function registerInterop()
    local ba, stage, exports = runtime()
    if not (ba and stage) or not mod._kantoInMotionInterop then return false end
    mod._kantoInMotionInterop:registerBattle({
      owner = BA_ID,
      priority = 110,
      sceneOwner = true,
      modernUi = "lower",
      suppressSurfaces = { text = true, panels = true },
      allowKIMSprites = true,
      allowKIMAnimations = true,
      active = function()
        local _, liveStage, liveExports = runtime()
        return liveStage and stageEnabled(liveStage, liveExports) or false
      end,
    })
    return true
  end

  local function displayMode(ba)
    if ba and type(ba.displayMode) == "function" then
      local ok, value = pcall(ba.displayMode)
      if ok then return tostring(value or "gbc") end
    end
    return "gbc"
  end

  local function preparedImage(source, ba, artSide)
    if not (source and ba and type(ba.prepareData) == "function") then return nil end
    local mode = displayMode(ba)
    local prepareKey = mode
    if mobileHost() and artSide == "back" then
      prepareKey = mode .. ":kim-mobile-back-80"
    elseif mobileHost() and artSide == "front" then
      prepareKey = mode .. ":kim-mobile-front-95"
    end
    local byMode = prepared[source]
    local cached = byMode and byMode[prepareKey] or nil
    if cached then
      local registered = true
      if type(ba.isExternal) == "function" then
        local ok, external = pcall(ba.isExternal, cached)
        registered = ok and external == true
      end
      if registered and type(ba.metrics) == "function" then
        local ok, metric = pcall(ba.metrics, cached)
        registered = ok and type(metric) == "table"
      end
      if registered then return cached end
      byMode[prepareKey] = nil
    end
    if type(source.newImageData) ~= "function" then return nil end

    local data = nil
    if mobileHost() and (artSide == "back" or artSide == "front")
        and love and love.graphics
        and type(love.graphics.newCanvas) == "function"
        and type(source.getDimensions) == "function" then
      -- presentationScale is not honored consistently by Battle Art 1.11's
      -- Android world-card path. Shrink the actual prepared KIM texture before
      -- Battle Art measures it. v26 proved this works for the player/back card;
      -- v29 keeps the confirmed-good player/back at 80% and raises only enemy/front to 95%.
      local okSize, sw, sh = pcall(source.getDimensions, source)
      if okSize and tonumber(sw) and tonumber(sh) and sw > 1 and sh > 1 then
        -- Mobile Battle Art calibration:
        --   back/player = 80%  (confirmed good in v28)
        --   front/enemy = 95%  (v28's 80% was too small)
        local factor = artSide == "front" and 0.95 or 0.80
        local tw = math.max(1, math.floor(sw * factor + 0.5))
        local th = math.max(1, math.floor(sh * factor + 0.5))
        local g = love.graphics
        local okCanvas, canvas = pcall(g.newCanvas, tw, th, { dpiscale = 1 })
        if not okCanvas or not canvas then
          okCanvas, canvas = pcall(g.newCanvas, tw, th)
        end
        if okCanvas and canvas then
          local previous = type(g.getCanvas) == "function" and g.getCanvas() or nil
          local pushed = pcall(g.push, "all")
          if not pushed then pcall(g.push) end
          local okDraw = pcall(function()
            g.setCanvas(canvas)
            if g.origin then g.origin() end
            g.clear(0, 0, 0, 0)
            if g.setShader then g.setShader() end
            if g.setBlendMode then g.setBlendMode("alpha") end
            g.setColor(1, 1, 1, 1)
            if source.setFilter then pcall(source.setFilter, source, "linear", "linear", 8) end
            g.draw(source, 0, 0, 0, factor, factor)
            if source.setFilter then pcall(source.setFilter, source, "nearest", "nearest") end
          end)
          if previous then pcall(g.setCanvas, previous) else pcall(g.setCanvas) end
          pcall(g.pop)
          if okDraw and type(canvas.newImageData) == "function" then
            local okRead, readData = pcall(canvas.newImageData, canvas)
            if okRead then data = readData end
          end
        end
      end
    end

    if not data then
      local okData, sourceData = pcall(source.newImageData, source)
      if not okData or not sourceData then return nil end
      data = sourceData
    end

    local okMade, made = pcall(ba.prepareData, data, mode)
    if not okMade or not made then return nil end
    byMode = byMode or {}
    byMode[prepareKey] = made
    prepared[source] = byMode
    return made
  end

  local function stablePrepared(record, generation, species, side, variant, frame, ba)
    local source = renderPresentationFrame(record, generation, species, frame,
      side, variant, true)
    local image = preparedImage(source, ba, side)
    if not image then return nil end

    -- Use the final authored frame as the neutral footprint, matching KIM's
    -- accepted test-build stable-anchor behavior. Keep each frame's pixels,
    -- but stop wings/tails from moving the entire 3D billboard around.
    local frames = math.max(1, math.floor(tonumber(record and record.frames) or 1))
    if frames > 1 and type(ba.shareFrameAnchor) == "function" then
      local referenceSource = renderPresentationFrame(record, generation, species,
        frames, side, variant, true)
      local reference = preparedImage(referenceSource, ba, side)
      if reference and reference ~= image then
        pcall(ba.shareFrameAnchor, { image, reference }, 2)
        if type(ba.metrics) == "function" then
          local metric, refMetric = ba.metrics(image), ba.metrics(reference)
          if type(metric) == "table" and type(refMetric) == "table"
              and tonumber(refMetric.x0) then
            metric.x0 = refMetric.x0
          end
        end
      end
    end
    return image
  end

  local function sideVisible(battle, side)
    if type(battle) ~= "table" then return false end
    if side == "enemy" then
      return battle.enemy and battle.enemy.mon and not battle.showEnemyTrainer
        and not battle.enemyHidden and not battle.enemySendingOut
    end
    return battle.player and battle.player.mon and not battle.showPlayerBack
      and not battle.playerHidden and not battle.sendingOut
      and not battle.safari and not battle.demo
  end

  local function restoreSide(battler)
    local state = battler and battlerState[battler]
    if not state then return end
    if battler.sprite == state.installed then battler.sprite = state.original end
    battlerState[battler] = nil
  end

  local function installSide(battle, side, ba)
    local battler = side == "enemy" and battle.enemy or battle.player
    if not sideVisible(battle, side) then restoreSide(battler); return false end
    local mon = battler and battler.mon
    local artSide = side == "enemy" and "front" or "back"
    local record, generation, species, shiny = battleRecord(mon.species, artSide, mon)
    if not record then restoreSide(battler); return false end
    local variant = shiny and "shiny" or "normal"
    local frame = currentFrame(record)
    local image = stablePrepared(record, generation, species, artSide, variant, frame, ba)
    if not image then return false end

    local identity = table.concat({ tostring(species), artSide, variant,
      tostring(generation) }, ":")
    local state = battlerState[battler]
    if not state or state.identity ~= identity then
      restoreSide(battler)
      state = { identity = identity, original = battler.sprite, installed = nil }
      battlerState[battler] = state
    elseif battler.sprite ~= state.installed and battler.sprite ~= state.original then
      -- Transform or another live battle effect temporarily owns the picture.
      return false
    end
    battler.sprite = image
    state.installed = image
    return true
  end

  local function apply(battle)
    local ba, stage, exports = runtime()
    if not (ba and stage and kimEnabled(stage, exports)) or type(battle) ~= "table" then
      if type(battle) == "table" then
        restoreSide(battle.enemy); restoreSide(battle.player)
      end
      return false
    end
    local any = false
    if battle.enemy then any = installSide(battle, "enemy", ba) or any end
    if battle.player then any = installSide(battle, "player", ba) or any end
    return any
  end

  local function scaleFor(battle, side)
    if not sideVisible(battle, side) then return nil end
    local battler = side == "enemy" and battle.enemy or battle.player
    local mon = battler and battler.mon
    if not mon then return nil end
    local artSide = side == "enemy" and "front" or "back"
    local record = battleRecord(mon.species, artSide, mon)
    if not record then return nil end

    -- KIM's displayScale already normalizes the physically-60%-sized HD frame
    -- back into roughly the old Battle Art/Gen5 card envelope. Do NOT carry
    -- KIM's extra 2D 1.15x player rebaseline into the 3D world: perspective
    -- magnifies the near/player card and that was the source of the oversized
    -- Meowth/Charizard presentation.
    local scale = tonumber(record.displayScale) or 1

    -- Author calibration and user adjustment are deliberately separate.
    --
    -- The preferred Battle Art presentation was calibrated while the old
    -- 3D PKMN SIZE control was set to 75%. Bake that value into KIM itself so
    -- the menu can now use a true neutral 100%.
    --
    --   100% = KIM's preferred calibrated size
    --    75% = 25% smaller than the preferred size
    --   125% = 25% larger than the preferred size
    local kimBattleArtBaseline = 0.75
    local stagePct = tonumber(mod.options:get("battle3dPokemonSize")) or 100
    stagePct = math.max(50, math.min(125, stagePct))
    scale = scale * kimBattleArtBaseline * stagePct / 100

    if side == "enemy" then
      -- The 1.25 front-side correction is part of the accepted desktop
      -- presentation. On mobile the actual front texture is now physically
      -- prepared at 60%, and retaining 1.25 makes the opponent much too large.
      -- Keep desktop exactly as before; mobile uses the neutral front factor.
      if not mobileHost() then scale = scale * 1.25 end
    else
      local pct = tonumber(mod.options:get("battlePlayerSize")) or 100
      pct = math.max(50, math.min(200, pct))

      -- Author calibration is separate from user controls.
      --
      -- Desktop Battle Art's near/player card reads larger than the authored
      -- pair because of perspective. Keep 3D PKMN SIZE=100% as the neutral
      -- scene-wide user setting, but bake a PC-only 0.80 player baseline into
      -- KIM before PLAYER PKMN SIZE is applied.
      --
      -- Mobile already has its independently confirmed physical back-card
      -- preparation and must not receive this desktop correction.
      if not mobileHost() then scale = scale * 0.80 end

      -- PLAYER PKMN SIZE remains a user fine-tune on top of KIM's calibrated
      -- player baseline.
      scale = scale * pct / 100
    end

    -- Mobile player/back size is handled by physically preparing that KIM
    -- card at 60% in preparedImage(). Keep presentationScale identical to the
    -- desktop rules so Battle Art cannot ignore or double-apply a mobile-only
    -- metadata multiplier.

    return scale
  end

  local function hookRuntime()
    local ba, stage, exports = runtime()
    if not (ba and stage) then return false end
    registerInterop()
    if hookedBa == ba and hookedStage == stage then return true end
    hookedBa, hookedStage = ba, stage

    -- KIM now supplies the Pokemon artwork. Force only the live ownership
    -- decision, not Battle Art's saved DUPLICATE FIX value.
    originalPrefersModded = ba.prefersModded
    if type(originalPrefersModded) == "function" then
      ba.prefersModded = function(...)
        if kimEnabled(stage, exports) then return true end
        return originalPrefersModded(...)
      end
    end

    -- KIM's player sprite is a back view and belongs in the 3D world. These
    -- are transient reads only; Battle Art's saved PLAYER/BACK PLACEMENT
    -- choices are left untouched and resume as soon as KIM sprites are off.
    originalViewGet = ba.viewSetting and ba.viewSetting.get or nil
    if ba.viewSetting and type(originalViewGet) == "function" then
      ba.viewSetting.get = function(self, ...)
        if kimEnabled(stage, exports) then return "back" end
        return originalViewGet(self, ...)
      end
    end
    originalPlacementGet = ba.backPlacementSetting and ba.backPlacementSetting.get or nil
    if ba.backPlacementSetting and type(originalPlacementGet) == "function" then
      ba.backPlacementSetting.get = function(self, ...)
        if kimEnabled(stage, exports) then return "world" end
        return originalPlacementGet(self, ...)
      end
    end

    -- Battle Art's world-card matrix scales from texture dimensions. Apply
    -- KIM's per-species displayScale metadata there so the physically 60%
    -- sprite sheets retain the exact tested relative sizing. PLAYER PKMN SIZE
    -- remains live on top of that baseline.
    if type(stage.textures) == "function" then
      originalTextures = stage.textures
      stage.textures = function(battle, ...)
        local out = originalTextures(battle, ...)
        if type(out) == "table" and kimEnabled(stage, exports) then
          for _, side in ipairs({ "enemy", "player" }) do
            local tex = out[side]
            local scale = tex and scaleFor(battle, side) or nil
            if tex and scale then
              -- sideTexture normally publishes 1 here for Pokemon. Keep a
              -- stable base so repeated textures() reads cannot multiply KIM's
              -- scale into the same table more than once.
              if tex._kantoInMotionBasePresentationScale == nil then
                tex._kantoInMotionBasePresentationScale =
                  tonumber(tex.presentationScale) or 1
              end
              tex.presentationScale =
                tex._kantoInMotionBasePresentationScale * scale

              -- Android/iOS: the near/player world card is still left-heavy
              -- after the scale correction. Shift ONLY that card within its
              -- world cell by moving its reported texture anchor left; the
              -- visible billboard therefore moves right. Keep the original ax
              -- once so repeated textures() reads never compound the offset.
              if side == "player" and mobileHost() then
                if tex._kantoInMotionBaseAx == nil then
                  tex._kantoInMotionBaseAx = tonumber(tex.ax) or 80
                end
                tex.ax = tex._kantoInMotionBaseAx - 20
              elseif tex._kantoInMotionBaseAx ~= nil then
                tex.ax = tex._kantoInMotionBaseAx
              end

              -- Remember the actual side canvas carrying KIM's HD Pokemon.
              -- The 3D color pass uses this exact canvas as the billboard
              -- texture, which gives us a narrow way to disable only the
              -- erroneous self/receiver shadow on KIM cards while still
              -- leaving the same alpha silhouette in Battle Art's caster pass.
              if tex.canvas then kimCardCanvases[tex.canvas] = true end
            end
          end
        end
        return out
      end
      stage._kantoInMotionHdSpriteScale = stage.textures
    end

    -- Battle Art 1.11's SHADED card path uses the same upright Pokemon card
    -- as both a shadow caster and a shadow-map receiver. With high-resolution
    -- alpha cards this can project the card's own silhouette/PCF pattern back
    -- across its face (the diagonal/diamond striping seen on Meowth).
    --
    -- Keep the good half of the 3D system: KIM Pokemon still CAST their real,
    -- alpha-shaped Battle Art shadow onto terrain, but the visible KIM card
    -- does not RECEIVE the scene shadow map. Diffuse/world lighting, clock
    -- tint, depth, camera placement and all non-KIM geometry are untouched.
    --
    -- Voxel3D.draw has a separate `sunModel` used only for the shadow lookup,
    -- so putting that lookup far outside the sun frustum yields full sunlight
    -- for the card without changing its visible model matrix. The caster pass
    -- is ShadowMap.draw and therefore remains completely intact.
    local lib = type(exports) == "table" and exports.lib or nil
    if type(lib) == "table" and type(lib.require) == "function" then
      local okVoxel, voxel = pcall(lib.require, "Voxel3D")
      local okMat4, Mat4 = pcall(lib.require, "Mat4")
      if okVoxel and type(voxel) == "table" and type(voxel.draw) == "function"
          and okMat4 and type(Mat4) == "table"
          and type(Mat4.translate) == "function"
          and hookedVoxel ~= voxel then
        hookedVoxel = voxel
        originalVoxelDraw = voxel.draw
        local shadowLookupOutsideFrustum = Mat4.translate(1000000, 0, 1000000)
        voxel.draw = function(mesh, texture, model, pull, sunModel)
          if texture and kimCardCanvases[texture]
              and kimEnabled(stage, exports) then
            return originalVoxelDraw(mesh, texture, model, pull,
              shadowLookupOutsideFrustum)
          end
          return originalVoxelDraw(mesh, texture, model, pull, sunModel)
        end
        voxel._kantoInMotionHdCardShadowReceiverFix = true
      end
    end
    return true
  end

  function M:install()
    hookRuntime()
    registerInterop()
    local okState, BattleState = pcall(require, "src.battle.BattleState")
    if okState and type(BattleState) == "table" and type(BattleState.update) == "function"
        and not BattleState._kantoInMotionBattleArt111Update then
      local inner = BattleState.update
      installedUpdate = function(self, dt, ...)
        local results = { inner(self, dt, ...) }
        hookRuntime()
        apply(self)
        return unpack(results)
      end
      BattleState._kantoInMotionBattleArt111Update = inner
      BattleState.update = installedUpdate
    end
    return true
  end

  function M:isActive()
    local _, stage, exports = runtime()
    return stage and kimEnabled(stage, exports) or false
  end

  function M:apply(battle) return apply(battle) end

  M:install()
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function() M:install() end)
    mod.events:on("battle.started", function(payload)
      M:install(); if payload and payload.battle then apply(payload.battle) end
    end)
  end

  mod.exports.battleArtCompatibility = true
  mod.exports.battleArtCompatibilityVersion = 11
  mod.exports.battleArtCompatibilityMode = "hd_modded_world_cards"
  return M
end
