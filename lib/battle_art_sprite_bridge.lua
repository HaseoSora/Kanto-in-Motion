-- Kanto in Motion -> Battle Art 1.10+ sprite compatibility bridge.
-- Battle Art remains the 3D scene owner. When Battle Art's DUPLICATE FIX is
-- MODDED, this bridge supplies KIM's selected animated Pokemon pictures without
-- copying or changing any Battle Art code/assets.
return function(mod, battleRecord, renderPresentationFrame, currentFrame)
  local M = {}
  local BA_ID = "BATTLE_ART_VOXEL_FORK"
  local prepared = setmetatable({}, { __mode = "k" })
  local states = setmetatable({}, { __mode = "k" })
  local installedUpdate = nil
  local warnedOld = false

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
    local ok, ba = pcall(lib.require, "BattleArt")
    if not ok or type(ba) ~= "table" then return nil end
    return ba, exports
  end

  local function compatible(ba, exports)
    if not (ba and type(ba.prepareData) == "function"
        and type(ba.prefersModded) == "function") then return false end
    local version = type(exports) == "table" and tostring(exports.version or "") or ""
    local major, minor = version:match("^(%d+)%.(%d+)")
    major, minor = tonumber(major), tonumber(minor)
    if major and (major > 1 or (major == 1 and (minor or 0) >= 10)) then return true end
    -- Feature-test instead of hard-failing custom/future builds that expose the
    -- 1.10 MODDED ownership API without a conventional version string.
    return type(ba.ownsSpeciesArt) == "function" and type(ba.displayMode) == "function"
  end

  -- KIM is the Pokemon-picture owner whenever its battle sprite system is
  -- active inside Battle Art's 3D stage. A fresh Battle Art install defaults
  -- DUPLICATE FIX to BATTLE ART, while older layered test installs often had
  -- MODDED persisted already. Depending on that saved external preference made
  -- KIM's 3D sprite bridge, PLAYER PKMN SIZE and stable-frame anchor appear to
  -- work only on those layered installs.
  --
  -- Override only the live ownership decision; do NOT write Battle Art's
  -- option. As soon as KIM battle sprites or 3D-BTL are off, the original
  -- prefersModded() result is used again and the user's saved BA setting is
  -- untouched.
  local function installOwnershipHook()
    local ba, exports = runtime()
    if not compatible(ba, exports) then return false end
    if ba._kantoInMotionPrefersModdedHook then return true end

    local originalPrefersModded = ba.prefersModded
    local lib = type(exports) == "table" and exports.lib or nil
    local OverworldBattle
    if type(lib) == "table" and type(lib.require) == "function" then
      local okStage, stage = pcall(lib.require, "OverworldBattle")
      if okStage and type(stage) == "table" then OverworldBattle = stage end
    end

    local function kimOwns3DBattlers()
      if not (mod and mod.options) then return false end
      if mod.options:get("enabled") == false
          or mod.options:get("battleSprites") == false then
        return false
      end
      if not (OverworldBattle and type(OverworldBattle.enabled) == "function") then
        return false
      end
      local okEnabled, enabled = pcall(OverworldBattle.enabled)
      return okEnabled and enabled == true
    end

    ba.prefersModded = function(...)
      if kimOwns3DBattlers() then return true end
      return originalPrefersModded(...)
    end
    ba._kantoInMotionPrefersModdedHook = true
    ba._kantoInMotionOriginalPrefersModded = originalPrefersModded
    return true
  end

  -- Battle Art 1.10 decides whether a player BACK sprite is a world card by
  -- asking its own AnimatedBattleArt manager. KIM's animated backs are external
  -- to that manager, so BA misclassifies them as classic/pinned UI backs. That
  -- has three side effects at once: the player bypasses world-card scale,
  -- per-frame opaque metrics can move the pinned picture, and BattleCam marks
  -- the shot non-steerable (which disables mouse/right-stick orbit on PC).
  --
  -- A KIM-installed Pokemon back is already full-display battle art and belongs
  -- in the staged world. Override only that live classification; trainer backs,
  -- ROM fallback, and every non-KIM path retain Battle Art's original answer.
  local function installWorldBackClassificationHook()
    local ba, exports = runtime()
    if not compatible(ba, exports) then return false end
    local lib = type(exports) == "table" and exports.lib or nil
    if type(lib) ~= "table" or type(lib.require) ~= "function" then return false end
    local okStage, OverworldBattle = pcall(lib.require, "OverworldBattle")
    if not okStage or type(OverworldBattle) ~= "table"
        or type(OverworldBattle.backPinned) ~= "function" then return false end
    if OverworldBattle._kantoInMotionWorldBackClassificationHook then return true end

    local originalBackPinned = OverworldBattle.backPinned
    local function kimWorldBackActive()
      local battle = type(OverworldBattle.battle) == "function"
        and OverworldBattle.battle() or nil
      if not (battle and battle.player and not battle.showPlayerBack) then return false end
      local state = states[battle.player]
      if not (state and state.installed and battle.player.sprite == state.installed) then
        return false
      end
      if not (mod and mod.options) then return false end
      return mod.options:get("enabled") ~= false
        and mod.options:get("battleSprites") ~= false
    end

    local function backPinned(...)
      if kimWorldBackActive() then return false end
      return originalBackPinned(...)
    end
    OverworldBattle.backPinned = backPinned
    OverworldBattle._kantoInMotionWorldBackClassificationHook = backPinned
    OverworldBattle._kantoInMotionOriginalBackPinned = originalBackPinned
    return true
  end

  local function active()
    if not (mod and mod.options) then return false end
    if mod.options:get("enabled") == false or mod.options:get("battleSprites") == false then
      return false
    end
    local ba, exports = runtime()
    if not compatible(ba, exports) then
      if handle() and not warnedOld and mod.log and type(mod.log.warn) == "function" then
        warnedOld = true
        mod.log:warn("Battle Art sprite bridge needs Battle Art 1.10.0+; leaving Battle Art's Pokemon art unchanged")
      end
      return false
    end
    -- DUPLICATE FIX = MODDED only delegates Pokemon art while Battle Art is
    -- actually staging the fight. If 3D-BTL is OFF, KIM owns the complete 2D
    -- battle and this bridge must stay dormant.
    local lib = type(exports) == "table" and exports.lib or nil
    if type(lib) == "table" and type(lib.require) == "function" then
      local okStage, OverworldBattle = pcall(lib.require, "OverworldBattle")
      if okStage and type(OverworldBattle) == "table"
          and type(OverworldBattle.enabled) == "function" then
        local okEnabled, enabled = pcall(OverworldBattle.enabled)
        if okEnabled and not enabled then return false end
      end
    end
    local ok, modded = pcall(ba.prefersModded)
    return ok and modded == true, ba
  end

  local function preparedImage(source, ba)
    if not (source and ba) then return nil end
    local mode = ""
    if type(ba.displayMode) == "function" then
      local ok, got = pcall(ba.displayMode)
      if ok then mode = tostring(got or "") end
    end
    local byMode = prepared[source]
    if byMode and byMode[mode] then return byMode[mode] end
    if type(source.newImageData) ~= "function" then return nil end
    local okData, data = pcall(source.newImageData, source)
    if not okData or not data then return nil end

    -- KIM's stable animation frames are Canvases. On high-DPI Android/iOS a
    -- Canvas can carry physical pixels at the device DPI while still
    -- representing the same logical atlas cell. Battle Art deliberately uses
    -- dpiscale=1 for sprite readback for this exact reason. Normalize KIM's
    -- handoff before prepareData so a 98x83 Charizard cell cannot become a
    -- ~270x228 billboard texture merely because the phone is 2.75x DPI.
    local dpi = 1
    if type(source.getDPIScale) == "function" then
      local okDpi, gotDpi = pcall(source.getDPIScale, source)
      gotDpi = okDpi and tonumber(gotDpi) or nil
      if gotDpi and gotDpi > 1 then dpi = gotDpi end
    end
    if dpi > 1.001 and love and love.image and type(love.image.newImageData) == "function" then
      local pw, ph = data:getDimensions()
      local lw = math.max(1, math.floor(pw / dpi + 0.5))
      local lh = math.max(1, math.floor(ph / dpi + 0.5))
      if lw < pw or lh < ph then
        local okNorm, normalized = pcall(love.image.newImageData, lw, lh)
        if okNorm and normalized then
          for y = 0, lh - 1 do
            local sy = math.min(ph - 1, math.floor(y * ph / lh))
            for x = 0, lw - 1 do
              local sx = math.min(pw - 1, math.floor(x * pw / lw))
              normalized:setPixel(x, y, data:getPixel(sx, sy))
            end
          end
          data = normalized
        end
      end
    end

    local okImage, image = pcall(ba.prepareData, data, mode)
    if not okImage or not image then return nil end
    byMode = byMode or {}
    byMode[mode] = image
    prepared[source] = byMode
    return image
  end

  -- Battle Art normally derives the billboard centre/feet from each prepared
  -- image's opaque bounds. Animated KIM atlases use one fixed logical canvas,
  -- so doing that independently on every frame turns harmless wing/tail/body
  -- motion into whole-Pokemon side-to-side/up-down drift in 3D-BTL.
  --
  -- Battle Art 1.10 already exposes the same stable-anchor helper used by its
  -- own animated sprite provider. Anchor every KIM frame to the animation's
  -- neutral final frame while leaving the pixels inside the canvas untouched.
  -- This preserves authored animation but keeps the Pokemon's ground contact
  -- and billboard centre fixed.
  local function battleArtImage(source, ba, record, generation, species, side, variant)
    local image = preparedImage(source, ba)
    if not image then return nil end
    local frames = math.max(1, math.floor(tonumber(record and record.frames) or 1))
    if frames <= 1 or type(ba.shareFrameAnchor) ~= "function" then return image end

    local refSource = renderPresentationFrame(record, generation, species, frames,
      side, variant or "normal", true)
    local refImage = preparedImage(refSource, ba)
    if refImage then
      -- shareFrameAnchor validates equal logical frame dimensions itself and
      -- fails closed if a future provider returns incompatible frame sizes.
      pcall(ba.shareFrameAnchor, { image, refImage }, 2)
    end
    return image
  end

  local function speciesFor(ba, battler)
    if ba and type(ba.speciesFor) == "function" then
      local ok, value = pcall(ba.speciesFor, battler)
      if ok and value then return value end
    end
    return battler and battler.mon and battler.mon.species or nil
  end

  local function safeToShow(battle, battler, side)
    if not (battle and battler and battler.mon) or battler.fainted then return false end
    if side == "enemy" then
      return not battle.showEnemyTrainer and not battle.enemyHidden
        and not battle.enemySendingOut
    end
    return not battle.showPlayerBack and not battle.playerHidden
      and not battle.sendingOut and not battle.safari and not battle.demo
  end

  local function installSide(battle, battler, side, ba)
    if not safeToShow(battle, battler, side) then return false end
    local artSide = side == "enemy" and "front" or "back"
    if side == "player" and type(ba.playerSide) == "function" then
      local ok, got = pcall(ba.playerSide)
      if ok and got == "front" then artSide = "front" end
    end
    local species = speciesFor(ba, battler)
    if not species then return false end

    local record, generation, normalized, shiny = battleRecord(species, artSide, battler.mon)
    if not record then return false end

    local state = states[battler]
    local identity = table.concat({ tostring(species), artSide,
      tostring(generation), tostring(normalized), shiny and "shiny" or "normal" }, ":")
    if not state or state.identity ~= identity then
      state = { identity = identity, original = battler.sprite, installed = nil }
      states[battler] = state
    elseif battler.sprite ~= state.installed and battler.sprite ~= state.original then
      -- A move/Transform/other battle effect temporarily owns this sprite.
      -- Do not stomp it; resume when the engine restores the ordinary picture.
      return false
    end

    local frame = currentFrame(record)
    local source = renderPresentationFrame(record, generation, normalized, frame,
      artSide, shiny and "shiny" or "normal", true)
    local image = battleArtImage(source, ba, record, generation, normalized,
      artSide, shiny and "shiny" or "normal")
    if not image then return false end
    battler.sprite = image
    state.installed = image
    return true
  end

  local function apply(battle)
    local on, ba = active()
    if not on or type(battle) ~= "table" then return false end
    local any = false
    if battle.enemy then any = installSide(battle, battle.enemy, "enemy", ba) or any end
    if battle.player then any = installSide(battle, battle.player, "player", ba) or any end
    return any
  end

  -- Let PLAYER PKMN SIZE control Battle Art's WORLD card rather than
  -- resampling the sprite into its intermediate texture. Battle Art 1.10's
  -- presentationScale is explicitly applied about the reported foot anchor,
  -- so changing this value keeps the Pokemon planted while scaling cleanly.
  local function installPlayerScaleHook()
    local ba, exports = runtime()
    if not compatible(ba, exports) then return false end
    local lib = type(exports) == "table" and exports.lib or nil
    if type(lib) ~= "table" or type(lib.require) ~= "function" then return false end
    local okStage, OverworldBattle = pcall(lib.require, "OverworldBattle")
    if not okStage or type(OverworldBattle) ~= "table"
        or type(OverworldBattle.sideTexture) ~= "function" then return false end

    if OverworldBattle._kantoInMotionPlayerScaleHook then
      return true
    end
    local innerSideTexture = OverworldBattle.sideTexture
    local function sideTexture(battle, side)
      local tex = innerSideTexture(battle, side)
      if side == "player" and type(tex) == "table" and battle
          and not battle.showPlayerBack then
        local on = active()
        if on then
          local pct = tonumber(mod.options:get("battlePlayerSize")) or 125
          pct = math.max(50, math.min(200, pct))
          -- KIM's long-standing player-size default is 125%. Treat that
          -- existing default as the neutral Battle Art world-card size so
          -- installing this compatibility fix does not suddenly enlarge every
          -- current 3D battle. Values below/above 125 now shrink/grow the card
          -- predictably while the non-3D path keeps its established semantics.
          tex.presentationScale = (tonumber(tex.presentationScale) or 1) * pct / 125
        end
      end
      return tex
    end
    OverworldBattle.sideTexture = sideTexture
    OverworldBattle._kantoInMotionPlayerScaleHook = sideTexture
    return true
  end

  -- Freeze the exact world-card anchor chosen on the first KIM frame of each
  -- battler identity. This is intentionally applied at Battle Art's sideTexture
  -- handoff -- the last place before the 3D card matrix is built -- so later
  -- opaque-bounds analysis cannot turn wing/tail/body motion into whole-card
  -- drift. Transform/species/generation changes create a new state and thus a
  -- new anchor naturally.
  local function installStableWorldCardAnchorHook()
    local ba, exports = runtime()
    if not compatible(ba, exports) then return false end
    local lib = type(exports) == "table" and exports.lib or nil
    if type(lib) ~= "table" or type(lib.require) ~= "function" then return false end
    local okStage, OverworldBattle = pcall(lib.require, "OverworldBattle")
    if not okStage or type(OverworldBattle) ~= "table"
        or type(OverworldBattle.sideTexture) ~= "function" then return false end
    if OverworldBattle._kantoInMotionStableWorldCardAnchorHook then return true end

    local innerSideTexture = OverworldBattle.sideTexture
    local function sideTexture(battle, side)
      local tex = innerSideTexture(battle, side)
      if type(tex) ~= "table" or not battle then return tex end
      local battler = side == "enemy" and battle.enemy or battle.player
      local state = battler and states[battler] or nil
      if not (state and state.installed and battler.sprite == state.installed) then
        return tex
      end
      local ax, ay = tonumber(tex.ax), tonumber(tex.ay)
      if not (state.worldCardAx and state.worldCardAy) and ax and ay then
        state.worldCardAx, state.worldCardAy = ax, ay
      end
      if state.worldCardAx and state.worldCardAy then
        tex.ax, tex.ay = state.worldCardAx, state.worldCardAy
      end
      return tex
    end
    OverworldBattle.sideTexture = sideTexture
    OverworldBattle._kantoInMotionStableWorldCardAnchorHook = sideTexture
    return true
  end

  function M:install()
    installOwnershipHook()
    installWorldBackClassificationHook()
    installPlayerScaleHook()
    installStableWorldCardAnchorHook()
    local okState, BattleState = pcall(require, "src.battle.BattleState")
    if not okState or type(BattleState) ~= "table" or type(BattleState.update) ~= "function" then
      return false
    end
    if BattleState.update == installedUpdate then return true end
    local inner = BattleState.update
    local function update(self, dt, ...)
      local results = { inner(self, dt, ...) }
      apply(self)
      return unpack(results)
    end
    installedUpdate = update
    BattleState.update = update
    BattleState.kantoInMotionBattleArtSpriteBridge = true
    return true
  end

  function M:isActive()
    local on = active()
    return on and true or false
  end

  function M:apply(battle)
    return apply(battle)
  end

  M:install()
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function() M:install() end)
    mod.events:on("battle.started", function(payload)
      M:install()
      apply(payload and payload.battle)
    end)
  end

  if mod.exports then
    mod.exports.battleArtSpriteCompat = true
    mod.exports.battleArtSpriteCompatVersion = 3
  end
  return M
end
