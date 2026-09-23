-- Kanto in Motion -> HGSS Visual Overhaul battle hard block.
--
-- HGSS_SPRITES is intentionally left completely unmodified.
--
-- KIM loads before HGSS.  At KIM load time this module snapshots the battle
-- methods that already contain Gen1Recomp + KIM + any earlier Battle Art /
-- PotatoVoxel integration, but do not yet contain HGSS's Gen-1 battle hooks.
--
-- After all mods are loaded, HGSS's versions are captured as the alternate
-- path and a tiny dispatcher is installed:
--
--   KIM BATTLE SYSTEM ON  -> pre-HGSS battle method
--   KIM BATTLE SYSTEM OFF -> normal post-HGSS battle method
--
-- This blocks HGSS only from live battle presentation while preserving its
-- overworld, menu, icon and player-overworld systems.
return function(mod, battleSystemEnabled)
  local M = {}
  local HGSS_ID = "HGSS_SPRITES"
  local BA_ID = "BATTLE_ART_VOXEL_FORK"

  local okState, BattleState = pcall(require, "src.battle.BattleState")
  if not okState or type(BattleState) ~= "table" then
    return M
  end

  -- Capture KIM's complete battle chain BEFORE HGSS loads.
  local preHgss = {}
  for _, name in ipairs({
    "newTrainer",
    "newWild",
    "update",
    "picImage",
    "resolveBattleScale",
    "drawPicsLayer",
  }) do
    if type(BattleState[name]) == "function" then
      preHgss[name] = BattleState[name]
    end
  end

  local function findMod(id)
    if not (mod and type(mod.find) == "function") then return nil end
    local ok, hit = pcall(mod.find, mod, id)
    if not ok or not hit then ok, hit = pcall(mod.find, id) end
    return ok and hit or nil
  end

  local function hgssPresent()
    return findMod(HGSS_ID) ~= nil
  end

  local function blockHgssBattle()
    if not hgssPresent() then return false end
    if type(battleSystemEnabled) ~= "function" then return false end
    local ok, enabled = pcall(battleSystemEnabled)
    return ok and enabled == true
  end

  local function battleArt()
    local hit = findMod(BA_ID)
    local exports = hit and hit.exports
    local lib = type(exports) == "table" and exports.lib or nil
    if not (type(lib) == "table" and type(lib.require) == "function") then
      return nil
    end
    local ok, ba = pcall(lib.require, "BattleArt")
    return ok and type(ba) == "table" and ba or nil
  end

  -- Battle Art itself is already available to KIM before HGSS because KIM's
  -- Battle Art compatibility bridge is installed earlier in main.lua.
  local baAtKimLoad = battleArt()
  local preHgssApplyTrainers =
    baAtKimLoad and type(baAtKimLoad.applyTrainers) == "function"
      and baAtKimLoad.applyTrainers or nil

  local installed = false
  local dispatchers = {}
  local postHgss = {}
  local postHgssApplyTrainers = nil
  local applyTrainersDispatcher = nil

  local function install()
    if installed then return true end
    if not hgssPresent() then return false end

    -- At mods.loaded/game.ready, these are HGSS's wrapped methods.  Save them
    -- so turning KIM BATTLE SYSTEM OFF immediately restores HGSS behavior
    -- without changing either mod's files or options.
    for name, before in pairs(preHgss) do
      local after = BattleState[name]
      if type(after) == "function" then
        postHgss[name] = after
        local methodName = name
        local pre = before
        dispatchers[methodName] = function(...)
          if blockHgssBattle() then
            return pre(...)
          end
          return postHgss[methodName](...)
        end
        BattleState[methodName] = dispatchers[methodName]
      end
    end

    -- HGSS also injects enemy trainer art directly into Battle Art by
    -- wrapping BattleArt.applyTrainers.  Bypass that wrapper while KIM's
    -- BATTLE SYSTEM is ON, but preserve it when KIM is OFF.
    local ba = battleArt()
    if ba and preHgssApplyTrainers
        and type(ba.applyTrainers) == "function" then
      postHgssApplyTrainers = ba.applyTrainers
      applyTrainersDispatcher = function(...)
        if blockHgssBattle() then
          return preHgssApplyTrainers(...)
        end
        return postHgssApplyTrainers(...)
      end
      ba.applyTrainers = applyTrainersDispatcher
    end

    installed = true
    mod._kantoInMotionHgssBattleHardBlockInstalled = true
    return true
  end

  -- `mods.loaded` is the intended seam: HGSS priority 150 has finished
  -- installing its battle wrappers, while no gameplay battle has started yet.
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function()
      pcall(install)
    end)
    -- Defensive fallback for hosts that do not emit mods.loaded to every mod.
    mod.events:on("game.ready", function()
      if not installed then pcall(install) end
    end)
  end

  M.install = install
  M.active = blockHgssBattle
  M.installed = function() return installed end
  return M
end
