-- Kanto in Motion -> Wilds of Kanto persistent shiny identity bridge.
--
-- Wilds already contains its own normal + shiny overworld sprite assets. KIM
-- never copies or edits those assets. Instead it supplies shiny identity at
-- runtime through Wilds' exported logic/render objects, then carries the same
-- DVs into battle through KIM's existing BattleState.newWild wrapper.
--
-- The earlier v8.6.64 compatibility attempt proxied mod.find on the public
-- Wilds handle. Gen1Recomp does not guarantee that handle is the same object as
-- Wilds' private mod context used by battle_art_shiny_bridge.lua, so the proxy
-- could be installed without ever reaching the actual spawn roll. This module
-- keeps that proxy only as a harmless best-effort compatibility path, but the
-- authoritative integration is now the exported SpawnLogic/SpawnRender pair.
return function(mod)
  local M = {}
  local BATTLE_ART_ID = "BATTLE_ART_VOXEL_FORK"
  local WILDS_ID = "overworld_wild_spawns"
  local SHINY_ATTACK = {
    [2] = true, [3] = true, [6] = true, [7] = true,
    [10] = true, [11] = true, [14] = true, [15] = true,
  }

  local pending = {}
  local pendingOrder = {}
  local nextToken = 0
  local installedWilds = nil
  local scanComplete = false

  local function rand(n)
    n = math.max(1, math.floor(tonumber(n) or 1))
    if love and love.math and type(love.math.random) == "function" then
      return love.math.random(n)
    end
    return math.random(n)
  end

  local function dv0to15()
    return rand(16) - 1
  end

  local function cloneDvs(dvs)
    if type(dvs) ~= "table" then return nil end
    local out = {}
    for k, v in pairs(dvs) do out[k] = v end
    return out
  end

  local function derivedHp(dvs)
    if type(dvs) ~= "table" then return nil end
    local a = tonumber(dvs.attack)
    local d = tonumber(dvs.defense)
    local s = tonumber(dvs.speed)
    local p = tonumber(dvs.special)
    if not (a and d and s and p) then return nil end
    return (a % 2) * 8 + (d % 2) * 4 + (s % 2) * 2 + (p % 2)
  end

  local function isShinyDvs(dvs)
    if type(dvs) ~= "table" then return false end
    local a = tonumber(dvs.attack)
    local d = tonumber(dvs.defense)
    local s = tonumber(dvs.speed)
    local p = tonumber(dvs.special)
    if d ~= 10 or s ~= 10 or p ~= 10 or SHINY_ATTACK[a] ~= true then
      return false
    end
    local hp = derivedHp(dvs)
    return dvs.hp == nil or tonumber(dvs.hp) == hp
  end

  local function forceShiny(dvs)
    local a = math.max(0, math.min(15, tonumber(dvs.attack) or dv0to15()))
    if a % 4 < 2 then a = a + 2 end
    dvs.attack = a
    dvs.defense = 10
    dvs.speed = 10
    dvs.special = 10
    dvs.hp = derivedHp(dvs)
  end

  local function forceNonShiny(dvs)
    if isShinyDvs(dvs) then
      local a = tonumber(dvs.attack) or 0
      if a % 4 >= 2 then a = a - 2 end
      dvs.attack = a
    end
    dvs.hp = derivedHp(dvs)
  end

  local function rollWildDVs()
    local dvs = {
      attack = dv0to15(),
      defense = dv0to15(),
      speed = dv0to15(),
      special = dv0to15(),
    }
    dvs.hp = derivedHp(dvs)

    local odds = mod.options and mod.options:get("battleShinyOdds") or "native"
    local shiny
    if odds == nil or odds == "native" then
      shiny = isShinyDvs(dvs)
    else
      local denominator = math.max(1, math.floor(tonumber(odds) or 8192))
      shiny = rand(denominator) == 1
      if shiny then forceShiny(dvs) else forceNonShiny(dvs) end
    end
    return dvs, shiny == true
  end

  local function normalizeSpecies(value)
    if value == nil then return nil end
    return tostring(value):lower():gsub("[^%w]", "")
  end

  local function prepareWildIdentity(species, level, dvs)
    if type(dvs) ~= "table" then return nil end
    nextToken = nextToken + 1
    local token = "kim_wild_shiny_" .. tostring(nextToken)
    local copy = cloneDvs(dvs)
    pending[token] = {
      token = token,
      species = species,
      speciesKey = normalizeSpecies(species),
      level = tonumber(level),
      dvs = copy,
      shiny = isShinyDvs(copy),
    }
    pendingOrder[#pendingOrder + 1] = token
    return token
  end

  local function cancelPreparedWildIdentity(token)
    if token == nil or pending[token] == nil then return false end
    pending[token] = nil
    return true
  end

  local function consumePreparedWildIdentity(species, level)
    local speciesKey = normalizeSpecies(species)
    local numericLevel = tonumber(level)
    local fallbackIndex, fallbackRecord

    for i = 1, #pendingOrder do
      local token = pendingOrder[i]
      local record = pending[token]
      if record then
        fallbackIndex, fallbackRecord = fallbackIndex or i, fallbackRecord or record
        local speciesMatches = speciesKey == nil or record.speciesKey == nil
          or speciesKey == record.speciesKey
        local levelMatches = numericLevel == nil or record.level == nil
          or numericLevel == record.level
        if speciesMatches and levelMatches then
          pending[token] = nil
          table.remove(pendingOrder, i)
          return record
        end
      end
    end

    local liveCount = 0
    for _, token in ipairs(pendingOrder) do
      if pending[token] then liveCount = liveCount + 1 end
    end
    if liveCount == 1 and fallbackRecord and fallbackIndex then
      pending[fallbackRecord.token] = nil
      table.remove(pendingOrder, fallbackIndex)
      return fallbackRecord
    end
    return nil
  end

  local bridgeApi = {
    api = 1,
    rollWildDVs = rollWildDVs,
    prepareWildIdentity = prepareWildIdentity,
    cancelPreparedWildIdentity = cancelPreparedWildIdentity,
  }
  local proxyHandle = {
    id = BATTLE_ART_ID,
    name = "Kanto in Motion shiny compatibility proxy",
    exports = { shinyBridge = bridgeApi },
    _kantoInMotionShinyProxy = true,
  }

  mod.exports._kantoInMotionConsumePreparedWildIdentity = consumePreparedWildIdentity
  mod.exports.overworldWildShinyBridge = {
    api = 2,
    active = function()
      return installedWilds ~= nil
    end,
  }

  local function findMod(id)
    if type(mod.find) ~= "function" then return nil end
    local ok, hit = pcall(mod.find, id)
    if ok and hit ~= nil then return hit end
    ok, hit = pcall(mod.find, mod, id)
    if ok then return hit end
    return nil
  end

  local function realBattleArtInstalled()
    local hit = findMod(BATTLE_ART_ID)
    return hit ~= nil and hit ~= proxyHandle
      and hit._kantoInMotionShinyProxy ~= true
  end

  -- Best-effort compatibility for Wilds versions whose internal mod context is
  -- the same object returned by mod.find. The direct exported-object path below
  -- does not depend on this succeeding.
  local function installFindProxy(wilds)
    if type(wilds) ~= "table" or type(wilds.find) ~= "function" then
      return false
    end
    if wilds._kantoInMotionShinyFindProxy == true then return true end
    local originalFind = wilds.find
    local function wrappedFind(a, b, ...)
      local id = b ~= nil and b or a
      if id == BATTLE_ART_ID then
        local ok, hit
        if b ~= nil then ok, hit = pcall(originalFind, a, b, ...)
        else ok, hit = pcall(originalFind, a, ...) end
        if ok and hit ~= nil then return hit end
        return proxyHandle
      end
      if b ~= nil then return originalFind(a, b, ...) end
      return originalFind(a, ...)
    end
    local ok = pcall(function()
      wilds._kantoInMotionOriginalFind = originalFind
      wilds.find = wrappedFind
      wilds._kantoInMotionShinyFindProxy = true
    end)
    return ok == true
  end

  local function enableWildsShinyRuntime(wilds)
    local exports = wilds and wilds.exports
    local lib = exports and exports.lib
    local requireFn = lib and lib.require
    if type(requireFn) ~= "function" then return false end
    local ok, animated = pcall(requireFn, "animated_sprites")
    if not ok or type(animated) ~= "table" then
      ok, animated = pcall(requireFn, lib, "animated_sprites")
    end
    if not ok or type(animated) ~= "table" then return false end
    animated.RUNTIME_SHINY_SUPPORT = "AVAILABLE"
    return true
  end

  local function ensureRecordIdentity(record)
    if type(record) ~= "table" then return false end
    if realBattleArtInstalled() then return false end

    local changed = false
    if type(record.dvs) ~= "table" then
      local dvs, shiny = rollWildDVs()
      record.dvs = dvs
      record.shiny = shiny == true
      changed = true
    else
      local shiny = record.shiny == true or isShinyDvs(record.dvs)
      if record.shiny ~= shiny then changed = true end
      record.shiny = shiny
    end
    record._kantoInMotionShinyIdentity = true
    return changed
  end

  local function syncEntity(record, entity, wilds, game, forceRefresh)
    if type(record) ~= "table" or type(entity) ~= "table" then return false end
    local oldShiny = entity.shiny == true or entity.isShiny == true
    entity.dvs = record.dvs
    entity.shiny = record.shiny == true
    entity.isShiny = entity.shiny
    entity.pokepcShiny = entity.shiny or nil
    entity._kantoInMotionShinyIdentity = true
    local visualChanged = oldShiny ~= entity.shiny

    if (visualChanged or forceRefresh) and wilds and wilds.exports
        and type(wilds.exports.refreshEntitySprite) == "function"
        and entity.hiddenEncounter ~= true and entity.visibleSprite ~= false then
      pcall(wilds.exports.refreshEntitySprite, entity, {
        game = game,
        reason = "kanto_in_motion_shiny_identity",
        forcePresentationRefresh = true,
      })
    end
    return visualChanged
  end

  local function scanExisting(wilds, game)
    local exports = wilds and wilds.exports
    local logic = exports and exports.logic
    if type(logic) ~= "table" or type(logic.spawns) ~= "table" then return 0 end
    local changed = 0
    for id, record in pairs(logic.spawns) do
      if type(record) == "table" then
        local firstPass = record._kantoInMotionShinyIdentity ~= true
        local identityChanged = ensureRecordIdentity(record)
        local entity = type(logic.entities) == "table" and logic.entities[id] or nil
        if entity and syncEntity(record, entity, wilds, game,
            firstPass and (identityChanged or record.shiny == true)) then
          changed = changed + 1
        end
      end
    end
    return changed
  end

  -- Supply identity before Wilds constructs its entity, so the very first
  -- rendered frame resolves the correct normal/shiny atlas. This wraps only the
  -- live exported SpawnRender object; no Wilds file is edited.
  local function installMakeEntityWrap(wilds)
    local exports = wilds and wilds.exports
    local render = exports and exports.render
    if type(render) ~= "table" or type(render.makeEntity) ~= "function" then
      return false
    end
    if render._kantoInMotionShinyMakeEntityWrap then return true end
    local inner = render.makeEntity
    local function wrapped(selfRef, game, record, ...)
      ensureRecordIdentity(record)
      local entity = inner(selfRef, game, record, ...)
      if entity and type(record) == "table" then
        syncEntity(record, entity, wilds, game, false)
      end
      return entity
    end
    render._kantoInMotionShinyMakeEntityInner = inner
    render._kantoInMotionShinyMakeEntityWrap = wrapped
    render.makeEntity = wrapped
    return true
  end

  -- Wilds starts both ordinary contact battles and Safari battles through this
  -- exported SpawnLogic instance. Queue the already-visible spawn's DVs before
  -- the engine constructs BattleState, then KIM's native wrapper consumes them.
  local function installBattleWrap(wilds)
    local exports = wilds and wilds.exports
    local logic = exports and exports.logic
    if type(logic) ~= "table" or type(logic._startBattle) ~= "function" then
      return false
    end
    if logic._kantoInMotionShinyBattleWrap then return true end
    local inner = logic._startBattle
    local function wrapped(selfRef, record, ...)
      ensureRecordIdentity(record)
      local token = type(record) == "table"
        and prepareWildIdentity(record.species, record.level, record.dvs) or nil
      local result = { pcall(inner, selfRef, record, ...) }
      local ok = table.remove(result, 1)
      if not ok then
        cancelPreparedWildIdentity(token)
        error(result[1], 0)
      end
      if result[1] == false then cancelPreparedWildIdentity(token) end
      return unpack(result)
    end
    logic._kantoInMotionShinyBattleInner = inner
    logic._kantoInMotionShinyBattleWrap = wrapped
    logic._startBattle = wrapped
    return true
  end

  local function ensureInstalled(game)
    if realBattleArtInstalled() then return false, "Battle Art owns shiny identity" end
    local wilds = findMod(WILDS_ID)
    if type(wilds) ~= "table" or type(wilds.exports) ~= "table" then
      return false, "Wilds of Kanto not loaded"
    end

    -- Do not proxy Wilds' internal mod.find here. The direct exported-object
    -- path is authoritative and avoids duplicate prepare tokens if Wilds and
    -- KIM happen to share the same public handle object.
    local runtimeOk = enableWildsShinyRuntime(wilds)
    local entityOk = installMakeEntityWrap(wilds)
    local battleOk = installBattleWrap(wilds)
    scanExisting(wilds, game)

    if runtimeOk and entityOk then
      if installedWilds ~= wilds and mod.log and type(mod.log.info) == "function" then
        mod.log:info("Wilds shiny compatibility active: KIM assigns persistent DVs and Wilds renders its own shiny overworld sprites")
      end
      installedWilds = wilds
      scanComplete = true
      return true
    end
    return false, "Wilds runtime exports not ready"
  end

  -- Load order is intentionally not assumed. KIM can initialize before Wilds,
  -- so retry after all mods are live. The scan also upgrades any entities that
  -- were spawned during the small window before this hook first ran.
  if mod.hooks and type(mod.hooks.wrap) == "function" then
    mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
      pcall(ensureInstalled, game)
      return nextFn(game, viewport)
    end, -25000)
  end

  -- Try immediately as well for load orders where Wilds is already available.
  pcall(ensureInstalled, nil)

  M.api = bridgeApi
  M.consumePreparedWildIdentity = consumePreparedWildIdentity
  M.ensureInstalled = ensureInstalled
  M.installed = function() return installedWilds ~= nil and scanComplete end
  return M
end
