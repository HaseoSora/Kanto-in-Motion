-- Kanto in Motion -> Battle Art 1.10+ sprite compatibility bridge.
--
-- Gen1Recomp 0.2.56 exposed a hard difference between Battle Art's native
-- AnimatedBattleArt path and KIM's older external-image/world-card bridge:
-- with KIM BATTLE SPRITES disabled the exact same Gen 5 atlas renders with
-- correct alpha/placement, while enabling the external bridge can make keyed
-- regions opaque and can change the player card's scale/metric ownership.
--
-- Do not rebuild the same PNG through a second capture path. While KIM owns
-- BATTLE SPRITES inside a 3D-BTL scene, route KIM's generation choices through
-- Battle Art's own AnimatedBattleArt decoder/prepareData/world-card path. KIM
-- and Battle Art ship byte-identical Gen 5 atlas/data files in the current
-- stack, so this preserves the selected artwork while using the renderer path
-- already proven correct on 0.2.56. Outside that exact condition Battle Art's
-- saved settings and normal ownership are untouched.
return function(mod, battleRecord, renderPresentationFrame, currentFrame,
    renderPresentationData)
  local M = {}
  local BA_ID = "BATTLE_ART_VOXEL_FORK"
  local warnedOld = false

  local hookedBa = nil
  local hookedStage = nil
  local hookedAnimated = nil
  local originalPrefersModded = nil
  local originalBattleArtGet = nil
  local originalFrontGet = nil
  local originalBackGet = nil
  local originalViewGet = nil
  local originalAnimatedUpdate = nil
  local originalSideTexture = nil
  local lastNativeDelegateActive = nil

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
    local okAnimated, animated = pcall(lib.require, "AnimatedBattleArt")
    if not okBa or type(ba) ~= "table" then return nil end
    if not okStage or type(stage) ~= "table" then stage = nil end
    if not okAnimated or type(animated) ~= "table" then animated = nil end
    return ba, exports, stage, animated
  end

  local function compatible(ba, exports, stage, animated)
    if not (ba and stage and animated
        and type(ba.prefersModded) == "function"
        and type(ba.ownsSpeciesArt) == "function"
        and type(stage.enabled) == "function"
        and type(animated.update) == "function") then
      return false
    end
    local version = type(exports) == "table" and tostring(exports.version or "") or ""
    local major, minor = version:match("^(%d+)%.(%d+)")
    major, minor = tonumber(major), tonumber(minor)
    if major and (major > 1 or (major == 1 and (minor or 0) >= 10)) then
      return true
    end
    return type(ba.frontAnimationSetting) == "table"
       and type(ba.backAnimationSetting) == "table"
       and type(ba.setting) == "table"
  end

  local function kimEnabled(stage)
    if not (mod and mod.options and stage) then return false end
    if mod.options:get("enabled") == false
        or mod.options:get("battleSystem") == false
        or mod.options:get("battleSprites") == false then
      return false
    end
    local ok, value = pcall(stage.enabled)
    return ok and value == true
  end

  local function frontGeneration()
    local value = mod and mod.options and mod.options:get("battleFrontGeneration") or nil
    if value == nil or value == "menu" then
      value = mod and mod.options and mod.options:get("generation") or nil
    end
    if value == "gen2" or value == "gen3" or value == "gen4" or value == "gen5" then
      return value
    end
    return "gen5"
  end

  local function backGeneration()
    local value = mod and mod.options and mod.options:get("battleBackGeneration") or nil
    -- AnimatedBattleArt deliberately treats an unknown generation as no
    -- replacement. Using the literal "rom" therefore preserves KIM's ROM
    -- choice while the opponent can still use an animated front collection.
    if value == "rom" then return "rom" end
    if value == "gen3" or value == "gen5" then return value end
    return "gen5"
  end

  local function restoreStable(def, had, value)
    if type(def) ~= "table" then return end
    if had then def.stableAnchor = value else def.stableAnchor = nil end
  end

  local function installNativeDelegate()
    local ba, exports, stage, animated = runtime()
    if not compatible(ba, exports, stage, animated) then
      if handle() and not warnedOld and mod.log and type(mod.log.warn) == "function" then
        warnedOld = true
        mod.log:warn("Battle Art native sprite handoff needs Battle Art 1.10.0+; leaving Battle Art unchanged")
      end
      return false
    end

    if hookedBa == ba and hookedStage == stage and hookedAnimated == animated then
      return true
    end

    -- A rebuilt Battle Art module means its old tables/functions are no longer
    -- live. Install onto the new module objects rather than stacking wrappers.
    hookedBa, hookedStage, hookedAnimated = ba, stage, animated

    originalPrefersModded = ba.prefersModded
    originalBattleArtGet = ba.setting and ba.setting.get or nil
    originalFrontGet = ba.frontAnimationSetting and ba.frontAnimationSetting.get or nil
    originalBackGet = ba.backAnimationSetting and ba.backAnimationSetting.get or nil
    originalViewGet = ba.viewSetting and ba.viewSetting.get or nil

    if type(originalPrefersModded) == "function" then
      ba.prefersModded = function(...)
        if kimEnabled(stage) then return false end
        return originalPrefersModded(...)
      end
    end

    if ba.setting and type(originalBattleArtGet) == "function" then
      ba.setting.get = function(self, ...)
        if kimEnabled(stage) then return "animated" end
        return originalBattleArtGet(self, ...)
      end
    end

    if ba.frontAnimationSetting and type(originalFrontGet) == "function" then
      ba.frontAnimationSetting.get = function(self, ...)
        if kimEnabled(stage) then return frontGeneration() end
        return originalFrontGet(self, ...)
      end
    end

    if ba.backAnimationSetting and type(originalBackGet) == "function" then
      ba.backAnimationSetting.get = function(self, ...)
        if kimEnabled(stage) then return backGeneration() end
        return originalBackGet(self, ...)
      end
    end

    -- KIM's player battle art is a back sprite when enabled. This also lets
    -- Battle Art's own hasWorldBack()/backPinned() decision own the plane,
    -- instead of classifying a KIM-prepared Image through a parallel hook.
    if ba.viewSetting and type(originalViewGet) == "function" then
      ba.viewSetting.get = function(self, ...)
        if kimEnabled(stage) then return "back" end
        return originalViewGet(self, ...)
      end
    end

    originalAnimatedUpdate = animated.update
    animated.update = function(battle, dt, ...)
      local active = kimEnabled(stage)

      -- If the user flips BATTLE SPRITES while a fight is live, throw away the
      -- manager's cached frame ownership at the boundary so OFF returns to the
      -- exact Battle Art configuration it had before KIM delegated to it.
      if lastNativeDelegateActive ~= nil and lastNativeDelegateActive ~= active then
        if type(animated.finish) == "function" then pcall(animated.finish, battle) end
        if type(animated.invalidate) == "function" then pcall(animated.invalidate) end
      end
      lastNativeDelegateActive = active

      if not active or type(battle) ~= "table"
          or type(animated.definitionFor) ~= "function" then
        return originalAnimatedUpdate(battle, dt, ...)
      end

      -- KIM's established 3D-BTL behavior anchors every animation to a stable
      -- logical footprint. Set the flag only while the native decoder builds
      -- the selected front/back frame sets, then restore Battle Art's data
      -- descriptors immediately. The resulting prepared Images stay entirely
      -- inside Battle Art's own alpha/metric registry.
      local enemyDef = battle.enemy and animated.definitionFor(battle.enemy, "front") or nil
      local playerDef = battle.player and animated.definitionFor(battle.player, "back") or nil
      local enemyHad = type(enemyDef) == "table" and enemyDef.stableAnchor ~= nil or false
      local playerHad = type(playerDef) == "table" and playerDef.stableAnchor ~= nil or false
      local enemyStable = type(enemyDef) == "table" and enemyDef.stableAnchor or nil
      local playerStable = type(playerDef) == "table" and playerDef.stableAnchor or nil
      if type(enemyDef) == "table" then enemyDef.stableAnchor = true end
      if type(playerDef) == "table" then playerDef.stableAnchor = true end

      local results = { pcall(originalAnimatedUpdate, battle, dt, ...) }

      restoreStable(enemyDef, enemyHad, enemyStable)
      if playerDef ~= enemyDef then restoreStable(playerDef, playerHad, playerStable) end

      if not results[1] then error(results[2], 0) end
      table.remove(results, 1)
      return unpack(results)
    end

    -- PLAYER PKMN SIZE remains a KIM control, but apply it only after Battle
    -- Art has produced its known-good native world card. No sprite/canvas is
    -- resampled and the foot anchor is unchanged.
    if type(stage.sideTexture) == "function" then
      originalSideTexture = stage.sideTexture
      stage.sideTexture = function(battle, side)
        local tex = originalSideTexture(battle, side)
        if side == "player" and type(tex) == "table" and battle
            and not battle.showPlayerBack and kimEnabled(stage)
            and backGeneration() ~= "rom" then
          local pct = tonumber(mod.options:get("battlePlayerSize")) or 125
          pct = math.max(50, math.min(200, pct))
          tex.presentationScale = (tonumber(tex.presentationScale) or 1) * pct / 100
        end
        return tex
      end
      stage._kantoInMotionNativeSpriteScaleHook = stage.sideTexture
    end

    ba._kantoInMotionNativeSpriteDelegate = true
    return true
  end

  function M:install()
    return installNativeDelegate()
  end

  function M:isActive()
    local _, _, stage = runtime()
    return stage and kimEnabled(stage) or false
  end

  -- Kept for the existing main.lua contract. Native AnimatedBattleArt runs
  -- from Battle Art's own OverworldBattle update, so no per-battler KIM image
  -- assignment is needed here.
  function M:apply(_battle)
    return false
  end

  M:install()
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function() M:install() end)
    mod.events:on("battle.started", function() M:install() end)
  end

  if mod.exports then
    mod.exports.battleArtSpriteCompat = true
    mod.exports.battleArtSpriteCompatVersion = 8
    mod.exports.battleArtSpriteCompatMode = "native_animated_delegate"
  end
  return M
end
