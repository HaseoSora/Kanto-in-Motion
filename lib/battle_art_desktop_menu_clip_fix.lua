-- Kanto in Motion desktop Battle Art / Gen1Recomp 0.2.45 move-menu clip fix.
--
-- Gen1Recomp 0.2.45 faithfully clips the classic player back pic to Y=64
-- during moveSelect (Y=56 during mimicSelect), because those BG rows are
-- replaced by the original TYPE/PP / Mimic menu on Game Boy. When KIM Modern
-- UI owns the lower battle menu, that original menu is suppressed/replaced by
-- a separate fullscreen panel, so keeping the native pic-row clip only chops
-- the player sprite for no visual reason.
--
-- Battle Art may leave a BACK SPRITES player on the original 2D pic layer
-- while the arena/enemy are staged in 3D. This wrapper tells the engine to
-- skip only that obsolete move-menu clip while KIM Modern UI owns the lower
-- UI. It does not move/scale a battler, change Battle Art, or run on mobile.
return function(mod, modernUiEnabled, battleArt3DEnabled, isMobileHost)
  if type(isMobileHost) == "function" and isMobileHost() then return false end

  local installedWrapper

  local function shouldSkip(self, skipMenuClip)
    if skipMenuClip or type(self) ~= "table" then return false end
    if self.phase ~= "moveSelect" and self.phase ~= "mimicSelect" then
      return false
    end
    -- dramaticShapeShot is Battle Art's live 3D battle handoff. Requiring it
    -- prevents this compatibility rule from changing ordinary Gen1 battles.
    if type(rawget(self, "dramaticShapeShot")) ~= "table" then return false end
    if type(modernUiEnabled) == "function" then
      local ok, enabled = pcall(modernUiEnabled)
      if not ok or not enabled then return false end
    end
    if type(battleArt3DEnabled) == "function" then
      local ok, enabled = pcall(battleArt3DEnabled)
      if not ok or not enabled then return false end
    end
    return true
  end

  local function install()
    local okState, BattleState = pcall(require, "src.battle.BattleState")
    if not okState or type(BattleState) ~= "table"
        or type(BattleState.drawPicsLayer) ~= "function" then
      return false
    end
    if BattleState.drawPicsLayer == installedWrapper then return true end

    local inner = BattleState.drawPicsLayer
    local function drawPicsLayer(self, slide, sx, sy, onlySide, skipMenuClip, ...)
      if shouldSkip(self, skipMenuClip) then skipMenuClip = true end
      return inner(self, slide, sx, sy, onlySide, skipMenuClip, ...)
    end
    installedWrapper = drawPicsLayer
    BattleState.drawPicsLayer = drawPicsLayer
    BattleState.kantoInMotionDesktopBattleArtMenuClipFix = true
    return true
  end

  install()
  if mod and mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", install)
  end
  return { install = install }
end
