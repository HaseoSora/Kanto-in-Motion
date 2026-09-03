-- Kanto in Motion -> Battle Art 1.10 mobile STAGE-ONLY bridge.
--
-- Battle Art remains completely unmodified on disk. On Android/iOS, while
-- KIM's battle system and Battle Art 3D-BTL are both enabled, this runtime
-- bridge disables Battle Art's snapped/native HUD furniture and lets KIM own
-- all 2D HUD pixels. Battle Art continues to own only the voxel world/camera,
-- lighting, shadows and projected battlers/effects.
return function(mod, battleSystemEnabled, battleArt3DBattleEnabled)
  if not (mod and type(battleSystemEnabled) == "function"
      and type(battleArt3DBattleEnabled) == "function") then
    return false
  end

  local system = love and love.system
  if not (system and type(system.getOS) == "function") then return false end
  local okOs, host = pcall(system.getOS)
  if not okOs or (host ~= "Android" and host ~= "iOS") then return false end

  local function active()
    local okK, kim = pcall(battleSystemEnabled)
    local okB, ba = pcall(battleArt3DBattleEnabled)
    return okK and kim and okB and ba
  end

  local function battleArtRuntime()
    if type(mod.find) ~= "function" then return nil end
    local ok, handle = pcall(mod.find, "BATTLE_ART_VOXEL_FORK")
    if not ok or not handle then return nil end
    local exports = type(handle.exports) == "table" and handle.exports or nil
    local lib = exports and exports.lib or nil
    if not (type(lib) == "table" and type(lib.require) == "function") then
      return nil
    end
    local okO, OverworldBattle = pcall(lib.require, "OverworldBattle")
    if not okO or type(OverworldBattle) ~= "table" then return nil end
    local AnimatedBattleArt = nil
    local okA, animated = pcall(lib.require, "AnimatedBattleArt")
    if okA and type(animated) == "table" then AnimatedBattleArt = animated end
    return OverworldBattle, AnimatedBattleArt
  end

  local function patchRuntime()
    local OverworldBattle, AnimatedBattleArt = battleArtRuntime()
    if not OverworldBattle then return false end

    -- Battle Art already skips snapHUDs on iOS because its scratch
    -- Canvas-to-Canvas HUD blit is not safe there. Android KIM uses the same
    -- conservative rule: no snapped Battle Art HUD at all. Returning false is
    -- Battle Art's documented fallback signal and leaves the 3D shot intact.
    if type(OverworldBattle.snapHUDs) == "function"
        and not OverworldBattle._kantoInMotionMobileStageOnlySnap then
      local original = OverworldBattle.snapHUDs
      OverworldBattle._kantoInMotionMobileStageOnlySnap = original
      OverworldBattle.snapHUDs = function(...)
        if active() then return false end
        return original(...)
      end
    end

    -- Battle Art 1.10's Gen 5 back metadata predates its stable-frame anchor
    -- flag for several species. On mobile, let Battle Art remain the normal
    -- Pokemon-art owner and simply opt its selected animated player back into
    -- the anchor mechanism it already uses for stable animated sets. This is
    -- deliberately data-only: no camera, backPinned, placement or ownership
    -- decision is changed. It also runs before Battle Art decodes the atlas, so
    -- every prepared frame receives one shared centre/ground contact.
    if AnimatedBattleArt and type(AnimatedBattleArt.update) == "function"
        and type(AnimatedBattleArt.definitionFor) == "function"
        and not AnimatedBattleArt._kantoInMotionMobileStableAnchor then
      local originalUpdate = AnimatedBattleArt.update
      AnimatedBattleArt._kantoInMotionMobileStableAnchor = originalUpdate
      AnimatedBattleArt.update = function(battle, dt, ...)
        if active() and type(battle) == "table" and battle.player then
          local okDef, def = pcall(AnimatedBattleArt.definitionFor,
                                   battle.player, "back")
          if okDef and type(def) == "table" then
            def.stableAnchor = true
          end
        end
        return originalUpdate(battle, dt, ...)
      end
    end

    -- Do not let Battle Art place frosted HUD/text panels into the native
    -- 160x144 battle canvas on the KIM mobile stage. Modern UI (when enabled)
    -- owns the lower surface, and KIM's own final HUD owns HP/status/party balls.
    if type(OverworldBattle.drawHudPanels) == "function"
        and not OverworldBattle._kantoInMotionMobileStageOnlyPanels then
      local original = OverworldBattle.drawHudPanels
      OverworldBattle._kantoInMotionMobileStageOnlyPanels = original
      OverworldBattle.drawHudPanels = function(...)
        if active() then return end
        return original(...)
      end
    end
    return true
  end

  patchRuntime()
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function() pcall(patchRuntime) end)
  end

  -- Claim only Battle Art's HUD surface. Text/panels remain governed by the
  -- existing Modern UI compatibility contract so INTEGRATED MODERN UI = OFF
  -- can still expose the vanilla lower battle UI. During KIM's private HUD
  -- capture, fail open so KIM can call the engine's original drawHUDs and then
  -- composite it at final mobile resolution.
  if mod.hooks and type(mod.hooks.wrap) == "function"
      and not mod._kantoInMotionBattleArtMobileStageOnlySuppressHook then
    mod._kantoInMotionBattleArtMobileStageOnlySuppressHook = true
    mod.hooks:wrap("battle.presentation.suppress_native.v1",
      function(next, request)
        -- KIM's private scratch HUD capture must fail open before any lower-
        -- priority presentation owner can claim the source HUD. captureBattleHud
        -- also removes dramaticShapeShot temporarily so Battle Art delegates
        -- directly to Gen1Recomp's original drawHUDs instead of its legacy claim.
        if active() and type(request) == "table" and request.surface == "hud" then
          local battle = request.battle
          if type(battle) == "table" and battle._kantoInMotionHudCapture then
            return false
          end
        end
        local claimed = next(request)
        if claimed == true then return true end
        if not active() or type(request) ~= "table" then return false end
        if request.surface ~= "hud" then return false end
        return true
      end, 20000)
  end

  local M = {}
  function M:isActive() return active() end
  function M:refresh() return patchRuntime() end
  if mod.exports then
    mod.exports.battleArtMobileStageOnly = true
    mod.exports.battleArtMobileStageOnlyVersion = 4
  end
  return M
end
