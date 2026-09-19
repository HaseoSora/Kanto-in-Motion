-- Kanto in Motion -> Battle Art 1.11 mobile STAGE-ONLY bridge.
-- Battle Art owns only the 3D world/camera/effects on Android/iOS while KIM's
-- battle system is enabled. KIM/Modern UI own the final 2D HUD and lower panel.
return function(mod, battleSystemEnabled, battleArtCompat)
  if not (mod and type(battleSystemEnabled)=="function"
      and type(battleArtCompat)=="table"
      and type(battleArtCompat.isActive)=="function") then
    return false
  end

  local function mobileHost()
    if type(mod._kantoInMotionNativeMobileHost)=="function" then
      local ok,value=pcall(mod._kantoInMotionNativeMobileHost)
      if ok then return value==true end
    end
    local system=love and love.system
    if system and type(system.getOS)=="function" then
      local ok,host=pcall(system.getOS)
      if ok then return host=="Android" or host=="iOS" end
    end
    return false
  end
  if not mobileHost() then return false end

  local function active()
    local okKim,kim=pcall(battleSystemEnabled)
    local okBa,ba=pcall(battleArtCompat.isActive,battleArtCompat)
    return okKim and kim==true and okBa and ba==true
  end

  local function runtime()
    if type(mod.find)~="function" then return nil end
    local ok,handle=pcall(mod.find,mod,"BATTLE_ART_VOXEL_FORK")
    if not ok or not handle then ok,handle=pcall(mod.find,"BATTLE_ART_VOXEL_FORK") end
    local exports=ok and handle and handle.exports or nil
    local lib=type(exports)=="table" and exports.lib or nil
    if not (type(lib)=="table" and type(lib.require)=="function") then return nil end
    local okO,OverworldBattle=pcall(lib.require,"OverworldBattle")
    return okO and type(OverworldBattle)=="table" and OverworldBattle or nil
  end

  local function patchRuntime()
    local OverworldBattle=runtime()
    if not OverworldBattle then return false end

    -- Match the user's original KIM 1.3.7 mobile ownership split:
    -- Battle Art owns the 3D scene, but KIM owns the final HP/status/EXP HUD.
    -- Suppress Battle Art's snapped HUD so its own COLOR/INVERTED setting can
    -- never become the visible authority.
    if type(OverworldBattle.snapHUDs)=="function"
        and not OverworldBattle._kantoInMotion111MobileStageOnlySnap then
      local original=OverworldBattle.snapHUDs
      OverworldBattle._kantoInMotion111MobileStageOnlySnap=original
      OverworldBattle.snapHUDs=function(...)
        if active() then return false end
        return original(...)
      end
    end

    -- Prevent Battle Art's own frosted command/dialog panels from occupying the
    -- same surface as KIM Modern UI.
    if type(OverworldBattle.drawHudPanels)=="function"
        and not OverworldBattle._kantoInMotion111MobileStageOnlyPanels then
      local original=OverworldBattle.drawHudPanels
      OverworldBattle._kantoInMotion111MobileStageOnlyPanels=original
      OverworldBattle.drawHudPanels=function(...)
        if active() then return end
        return original(...)
      end
    end
    return true
  end

  patchRuntime()
  if mod.events and type(mod.events.on)=="function" then
    mod.events:on("mods.loaded",function() pcall(patchRuntime) end)
    mod.events:on("battle.started",function() pcall(patchRuntime) end)
  end

  -- Do not claim the native HUD suppression surface here. Battle Art owns its
  -- HP/status HUD in the hybrid presentation; KIM Modern UI claims only the
  -- lower text/panel surfaces through the existing compatibility registry.

  local M={}
  function M:isActive() return active() end
  function M:refresh() return patchRuntime() end
  mod._kantoInMotionMobileBattleArtStageOnlyActive=function()
    return active()
  end
  return M
end
