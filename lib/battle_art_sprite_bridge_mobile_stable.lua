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

  -- Gen1Recomp 0.2.56 changed the final renderer/presentation pipeline. Keep a
  -- KIM-owned identity/metric side channel on Battle Art itself so a KIM frame
  -- remains recognisable even if another provider hands Battle Art the source
  -- Canvas instead of the prepared Image, or Battle Art rebuilds its private
  -- weak registries between update and draw. This does not alter Battle Art
  -- ownership for any non-KIM image.
  local function installIdentityFallback(ba)
    if type(ba) ~= "table" then return nil, nil end
    local owned = rawget(ba, "_kantoInMotionExternalImages")
    if type(owned) ~= "table" then
      owned = setmetatable({}, { __mode = "k" })
      ba._kantoInMotionExternalImages = owned
    end
    local fallbackMetrics = rawget(ba, "_kantoInMotionExternalMetrics")
    if type(fallbackMetrics) ~= "table" then
      fallbackMetrics = setmetatable({}, { __mode = "k" })
      ba._kantoInMotionExternalMetrics = fallbackMetrics
    end

    if not ba._kantoInMotionExternalIdentityHook then
      local innerExternal = ba.isExternal
      local innerMetrics = ba.metrics
      if type(innerExternal) == "function" then
        ba.isExternal = function(img, ...)
          local map = rawget(ba, "_kantoInMotionExternalImages")
          if type(map) == "table" and img and map[img] then return true end
          return innerExternal(img, ...)
        end
      end
      if type(innerMetrics) == "function" then
        ba.metrics = function(img, ...)
          local metric = innerMetrics(img, ...)
          if metric ~= nil then return metric end
          local map = rawget(ba, "_kantoInMotionExternalMetrics")
          return type(map) == "table" and img and map[img] or nil
        end
      end
      ba._kantoInMotionExternalIdentityHook = true
    end
    return owned, fallbackMetrics
  end

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
    local ok, modded = pcall(ba.prefersModded)
    return ok and modded == true, ba
  end

  local function preparedImage(source, ba)
    if not (source and ba) then return nil end
    installIdentityFallback(ba)
    local mode = ""
    if type(ba.displayMode) == "function" then
      local ok, got = pcall(ba.displayMode)
      if ok then mode = tostring(got or "") end
    end
    local byMode = prepared[source]
    local cached = byMode and byMode[mode] or nil
    if cached then
      -- Battle Art invalidates its own weak external/metric registries whenever
      -- the render pipeline is rebuilt. KIM's frame cache lives independently,
      -- so an Image can still be alive here after Battle Art has forgotten that
      -- it is authored external art. Reusing that stale Image makes Battle Art
      -- treat it like a ROM picture (filling transparent holes) and also drops
      -- the opaque-bound metrics that keep padded shiny frames on the ground.
      -- Re-prepare only when that registration has actually been lost.
      local registered = true
      if type(ba.isExternal) == "function" then
        local okExternal, external = pcall(ba.isExternal, cached)
        registered = okExternal and external == true
      end
      if registered and type(ba.metrics) == "function" then
        local okMetric, metric = pcall(ba.metrics, cached)
        registered = okMetric and type(metric) == "table"
      end
      if registered then
        local owned, fallbackMetrics = installIdentityFallback(ba)
        local metric = type(ba.metrics) == "function" and ba.metrics(cached) or nil
        if type(owned) == "table" then owned[cached], owned[source] = true, true end
        if type(fallbackMetrics) == "table" and type(metric) == "table" then
          fallbackMetrics[cached], fallbackMetrics[source] = metric, metric
        end
        return cached
      end

      -- A lost Battle Art registration means its placement registry was reset
      -- too. Forget any world-card anchor captured from the stale metric set so
      -- the freshly prepared image establishes the correct feet/centre again.
      for _, state in pairs(states) do
        if type(state) == "table" then
          state.worldCardAx, state.worldCardAy = nil, nil
        end
      end
      byMode[mode] = nil
    end
    if type(source.newImageData) ~= "function" then return nil end
    local okData, data = pcall(source.newImageData, source)
    if not okData or not data then return nil end
    local okImage, image = pcall(ba.prepareData, data, mode)
    if not okImage or not image then return nil end

    -- Register BOTH objects. Under normal Battle Art 1.10 operation the
    -- prepared Image is what reaches sideTexture. If a post-update sprite
    -- provider restores KIM's stable source Canvas before draw, treating that
    -- Canvas as the same authored external frame prevents BattlePics from
    -- filling its transparent holes with battle paper and preserves the same
    -- opaque-bounds anchor.
    local owned, fallbackMetrics = installIdentityFallback(ba)
    local metric = type(ba.metrics) == "function" and ba.metrics(image) or nil
    if type(owned) == "table" then
      owned[image] = true
      owned[source] = true
    end
    if type(fallbackMetrics) == "table" and type(metric) == "table" then
      fallbackMetrics[image] = metric
      fallbackMetrics[source] = metric
    end

    byMode = byMode or {}
    byMode[mode] = image
    prepared[source] = byMode
    return image
  end

  -- MODDED ownership is still supported when the user explicitly selects it,
  -- but unlike the v3-v6 experiments KIM never forces that ownership on a clean
  -- Battle Art install. When MODDED is selected, pin every KIM frame to the
  -- neutral final frame using Battle Art's own metric helper. This changes only
  -- placement metadata; the authored pixels continue to animate normally.
  local function battleArtImage(source, ba, record, generation, species, side, variant)
    local image = preparedImage(source, ba)
    if not image then return nil end
    local frames = math.max(1, math.floor(tonumber(record and record.frames) or 1))
    if frames <= 1 or type(ba.shareFrameAnchor) ~= "function" then return image end

    local referenceSource = renderPresentationFrame(record, generation, species, frames,
      side, variant or "normal", true)
    local referenceImage = preparedImage(referenceSource, ba)
    if referenceImage then
      pcall(ba.shareFrameAnchor, { image, referenceImage }, 2)
      -- Pinned backs also clamp their opaque left edge against the classic UI
      -- canvas. Keep that one clamp coordinate stable too, otherwise a flapping
      -- wing can move the whole picture even after centre/feet are shared.
      if type(ba.metrics) == "function" then
        local metric = ba.metrics(image)
        local referenceMetric = ba.metrics(referenceImage)
        if type(metric) == "table" and type(referenceMetric) == "table"
            and tonumber(referenceMetric.x0) then
          metric.x0 = referenceMetric.x0
        end
      end
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

  function M:install()
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
    mod.exports.battleArtSpriteCompatVersion = 4
  end
  return M
end
