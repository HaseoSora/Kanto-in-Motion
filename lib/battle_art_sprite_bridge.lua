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
  local originalTextures = nil
  local originalResolveBattleScale = nil
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

  local function stageActive(stage)
    if not stage or type(stage.enabled) ~= "function" then return false end
    local ok, value = pcall(stage.enabled)
    return ok and value == true
  end

  local function kimEnabled(stage)
    if not (mod and mod.options and stage) then return false end
    -- BATTLE SPRITES is an independent feature lane. Battle Art may own the
    -- 3D arena while KIM's full BATTLE SYSTEM / MODERN BATTLE UI are OFF; in
    -- that case KIM still supplies its selected sprite generations and player
    -- size exactly like the cooperative PotatoVoxel path.
    if mod.options:get("enabled") == false
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

    -- PLAYER PKMN SIZE remains a KIM control. Battle Art has TWO player-back
    -- presentation paths: a world billboard and an OG-UI pinned back. v74
    -- changed sideTexture metadata, but the authoritative world render receives
    -- the table returned by OverworldBattle.textures(); scaling there survives
    -- every later capture/provider wrapper. 100% is native 1.00x.
    if type(stage.textures) == "function" then
      originalTextures = stage.textures
      stage.textures = function(battle, ...)
        local out = originalTextures(battle, ...)
        if type(out) == "table" and type(out.player) == "table"
            and battle and not battle.showPlayerBack and kimEnabled(stage)
            and backGeneration() ~= "rom" then
          local pinned = false
          if type(stage.backPinned) == "function" then
            local okPinned, value = pcall(stage.backPinned)
            pinned = okPinned and value == true
          end
          if not pinned then
            local pct = tonumber(mod.options:get("battlePlayerSize")) or 125
            pct = math.max(50, math.min(200, pct))
            out.player.presentationScale = pct / 100
          end
        end
        return out
      end
      stage._kantoInMotionNativeSpriteScaleTexturesV75 = stage.textures
    end

    -- Keep the earlier sideTexture seam as a fallback for Battle Art revisions
    -- that consume a side card directly instead of through textures().
    if type(stage.sideTexture) == "function" then
      originalSideTexture = stage.sideTexture
      stage.sideTexture = function(battle, side)
        local tex = originalSideTexture(battle, side)
        if side == "player" and type(tex) == "table" and battle
            and not battle.showPlayerBack and kimEnabled(stage)
            and backGeneration() ~= "rom" then
          local pct = tonumber(mod.options:get("battlePlayerSize")) or 125
          pct = math.max(50, math.min(200, pct))
          tex.presentationScale = pct / 100
        end
        return tex
      end
      stage._kantoInMotionNativeSpriteScaleHook = stage.sideTexture
    end

    -- If Battle Art pins a supplied back sprite to the classic 2D slot, there
    -- is no player world texture to scale. Apply the same percentage at the
    -- engine's back-pic scale seam, but only while that exact pinned path is
    -- live. This leaves Battle Art's texture capture (forced 1x), trainers and
    -- ROM fallback untouched.
    do
      local okState, BattleState = pcall(require, "src.battle.BattleState")
      if okState and type(BattleState) == "table"
          and type(BattleState.resolveBattleScale) == "function"
          and not BattleState._kantoInMotionBattleArtPlayerScaleV75 then
        originalResolveBattleScale = BattleState.resolveBattleScale
        BattleState._kantoInMotionBattleArtPlayerScaleV75 = originalResolveBattleScale
        BattleState.resolveBattleScale = function(data, side, path, species)
          local base = originalResolveBattleScale(data, side, path, species)
          if side == "back" and backGeneration() ~= "rom" and kimEnabled(stage) then
            local live = type(stage.battle) == "function" and stage.battle() or nil
            local pinned = false
            if live and type(stage.backPinned) == "function" then
              local okPinned, value = pcall(stage.backPinned)
              pinned = okPinned and value == true
            end
            if live and pinned and not live.showPlayerBack and live.player then
              local pct = tonumber(mod.options:get("battlePlayerSize")) or 125
              pct = math.max(50, math.min(200, pct))
              return pct / 100
            end
          end
          return base
        end
      end
    end

    -- Quality of Life's caught indicator still uses the historical Dramatic
    -- Shape coordinates (shot.scale / shot.ly). Current Battle Art snaps the
    -- enemy HUD band to a separate edge position and can use a smaller HUD
    -- scale, so with KIM BATTLE SYSTEM OFF the icon is left near the screen's
    -- upper-left instead of beside the enemy name/level. Rebase only QOL's
    -- one-pixel ball primitives from the old shot coordinates into Battle
    -- Art's public snapped enemy-band transform. QOL itself remains untouched.
    do
      local g = love and love.graphics
      if g and type(g.rectangle) == "function" and type(g.getCanvas) == "function"
          and not g._kantoInMotionBattleArtCaughtV75 then
        local innerRectangle = g.rectangle
        local qolHandle = nil
        local function qolOption(game, key)
          if not qolHandle and type(mod.find) == "function" then
            local ok, handle = pcall(mod.find, mod, "quality_of_life")
            if not ok or not handle then ok, handle = pcall(mod.find, "quality_of_life") end
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
        g._kantoInMotionBattleArtCaughtV75 = innerRectangle
        g.rectangle = function(mode, x, y, w, h, ...)
          if mode == "fill" and mod.options:get("battleSystem") == false
              and stageActive(stage) then
            local battle = type(stage.battle) == "function" and stage.battle() or nil
            local shot = battle and rawget(battle, "dramaticShapeShot") or nil
            if not shot and type(stage.shot) == "function" then
              local okShot, value = pcall(stage.shot)
              if okShot then shot = value end
            end
            local nx, ny, nw, nh = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
            local sc = shot and tonumber(shot.scale) or nil
            local ly = shot and tonumber(shot.ly) or nil
            if battle and battle.kind == "wild" and type(shot) == "table"
                and shot.canvas and g.getCanvas() == shot.canvas
                and nx and ny and nw and nh and sc and sc > 0 and ly
                and math.abs(nw - sc) < 0.51 and math.abs(nh - sc) < 0.51 then
              local caughtMode = qolOption(battle.game, "qol_caught_indicator")
              if (caughtMode == "gen2" or caughtMode == "red" or caughtMode == "grey")
                  and type(stage.snapRects) == "function" then
                local sourceAnchorX = (enemyNameX(battle) - 9) * sc
                local sourceAnchorY = ly + 7 * sc
                if caughtMode == "gen2" then
                  sourceAnchorX = sourceAnchorX + 2 * sc
                  sourceAnchorY = sourceAnchorY + 2 * sc
                else
                  sourceAnchorX = sourceAnchorX + sc
                  sourceAnchorY = sourceAnchorY + sc
                end
                local side = caughtMode == "gen2" and 6 or 7
                local ux = (nx - sourceAnchorX) / sc
                local uy = (ny - sourceAnchorY) / sc
                if ux >= -0.01 and ux <= side - 1 + 0.01
                    and uy >= -0.01 and uy <= side - 1 + 0.01 then
                  local okRects, _, placement = pcall(stage.snapRects, shot)
                  local at = okRects and type(placement) == "table" and placement.enemy or nil
                  local hs = type(at) == "table" and tonumber(at.scale) or nil
                  if hs and hs > 0 and tonumber(at.x) and tonumber(at.y) then
                    local targetAnchor = caughtMode == "gen2" and 9 or 8
                    x = tonumber(at.x) + (targetAnchor + ux) * hs
                    y = tonumber(at.y) + (targetAnchor + uy) * hs
                    w, h = hs, hs
                  end
                end
              end
            end
          end
          return innerRectangle(mode, x, y, w, h, ...)
        end
      end
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
    mod.exports.battleArtSpriteCompatVersion = 9
    mod.exports.battleArtSpriteCompatMode = "native_animated_delegate"
  end
  return M
end
