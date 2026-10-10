-- Kanto in Motion - Gen 3 expanded-species battle guard.
--
-- 1025Dex stores National #387-1025 in Game3 species slots dex + 64
-- (#451-1089). Those ids remain in a save after the provider mod is removed.
-- Without an expanded-dex provider, letting one of those records become an
-- active battler can reach missing species metadata/art and abort the battle.
--
-- This guard never deletes or rewrites the saved Pokemon.  When no provider is
-- active it masks those party slots only while Game3 builds its in-memory
-- battle-party copy.  The masked copy uses species 0 / HP 0, so the core
-- battle selector treats the slot as unavailable (the practical equivalent of
-- a fainted Pokemon) and chooses the next usable native Pokemon.  The source
-- save is restored immediately, and restored once more after battle writeback
-- so BattleBridge cannot persist the temporary mask.

return function(mod)
  if not mod then return false end

  local SLOT_FIRST = 451 -- National #387 + 64
  local SLOT_LAST  = 1089 -- National #1025 + 64

  local function findMod(id)
    if type(mod.find) ~= "function" then return nil end
    local ok, h = pcall(mod.find, mod, id)
    if not ok or not h then ok, h = pcall(mod.find, id) end
    return ok and h or nil
  end

  local function providerActive()
    -- Primary provider used by KIM today.
    local h = findMod("1025dex")
    if h then return true end

    -- The data-only compatibility provider uses the exact same save slots.
    -- If it is actively providing them, do not quarantine valid species data.
    h = findMod("national_dex_gen3")
    if h then
      local e = h.exports
      if e and type(e.isActive) == "function" then
        local ok, on = pcall(e.isActive)
        if ok then return on == true end
      end
      if e and type(e.provider) == "function" then
        local ok, who = pcall(e.provider)
        if ok and (who == "national_dex_gen3" or who == "1025dex") then return true end
      end
      -- Older builds may not export a probe. Presence is safer than treating
      -- a genuinely registered expanded species as invalid.
      return true
    end
    return false
  end

  local function speciesSlot(mon)
    if type(mon) ~= "table" then return nil end
    local raw = mon.species or mon.speciesId or mon.id
    local n = tonumber(raw)
    if not n then
      local okP, Pokemon = pcall(require, "src.core.game3.pokemon")
      if okP and Pokemon then
        if type(raw) == "string" and type(Pokemon.speciesFromName) == "function" then
          local ok, v = pcall(Pokemon.speciesFromName, raw)
          if ok then n = tonumber(v) end
        end
        if not n and type(Pokemon.speciesOf) == "function" then
          local ok, v = pcall(Pokemon.speciesOf, mon)
          if ok then n = tonumber(v) end
        end
      end
    end
    if n then return math.floor(n) end
    return nil
  end

  local function expandedMon(mon)
    local sp = speciesSlot(mon)
    return sp ~= nil and sp >= SLOT_FIRST and sp <= SLOT_LAST
  end

  local function deepCopy(v, seen)
    if type(v) ~= "table" then return v end
    seen = seen or {}
    if seen[v] then return seen[v] end
    local out = {}
    seen[v] = out
    for k, x in pairs(v) do out[deepCopy(k, seen)] = deepCopy(x, seen) end
    return out
  end

  local function restoreTable(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then return end
    for k in pairs(dst) do dst[k] = nil end
    for k, v in pairs(src) do dst[k] = deepCopy(v) end
  end

  local function usableNative(mon)
    if type(mon) ~= "table" or expandedMon(mon) then return false end
    local sp = speciesSlot(mon) or 0
    if sp == 0 or mon.isEgg == true then return false end
    return (tonumber(mon.hp) or 0) > 0
  end

  local function maskParty(party)
    if providerActive() or type(party) ~= "table" then return nil, 0 end
    local snap, usable = {}, 0
    for i, mon in ipairs(party) do
      if expandedMon(mon) then
        snap[i] = {
          slot = speciesSlot(mon),
          mon = mon,
          data = deepCopy(mon),
        }
        -- Species 0 keeps the battle/party renderer from querying metadata,
        -- icon, cry or battle art for a provider-owned species that no longer
        -- exists in the merged Game3 registry. HP 0 preserves fainted-style
        -- eligibility semantics as an additional guard.
        mon.species = 0
        if mon.speciesId ~= nil then mon.speciesId = 0 end
        mon.hp = 0
        mon.fainted = true
      elseif usableNative(mon) then
        usable = usable + 1
      end
    end
    if next(snap) == nil then return nil, usable end
    return snap, usable
  end

  local function restoreParty(party, snap)
    if type(party) ~= "table" or type(snap) ~= "table" then return end
    for i, row in pairs(snap) do
      local mon = party[i]
      -- Restore in place when possible so other engine references to the party
      -- Pokemon remain valid. If a caller replaced the slot entirely, only put
      -- the saved record back when the replacement is still our masked object.
      if mon == row.mon and type(mon) == "table" then
        restoreTable(mon, row.data)
      elseif type(mon) == "table" and speciesSlot(mon) == 0 then
        restoreTable(mon, row.data)
      elseif mon == nil then
        party[i] = deepCopy(row.data)
      end
    end
  end

  local pendingBySession = setmetatable({}, { __mode = "k" })
  local warnedNoUsable = false

  local function install()
    local okB, Bridge = pcall(require, "src.core.game3.battle_bridge")
    if not okB or type(Bridge) ~= "table" or type(Bridge.start) ~= "function" then return false end
    if Bridge._kim1025PartyGuard then return true end

    local originalStart = Bridge.start
    Bridge.start = function(ownerMod, game, foe, opts)
      opts = opts or {}
      if providerActive() then return originalStart(ownerMod, game, foe, opts) end

      local Runtime = package.loaded["src.core.game3.runtime"]
        or require("src.core.game3.runtime")
      local session = (opts.link and type(opts.session) == "table" and opts.session)
        or (Runtime.getSession and Runtime.getSession())
      local party = (opts.link and type(opts.linkParty) == "table" and opts.linkParty)
        or (session and session.party)

      local snap, usable = maskParty(party)
      if not snap then return originalStart(ownerMod, game, foe, opts) end

      -- A party made entirely of unavailable expanded species has no legal
      -- battler after quarantine. Do not let State.new fall back to slot 1,
      -- which would recreate the invalid species path we are guarding.
      if usable <= 0 then
        restoreParty(party, snap)
        if not warnedNoUsable and mod.log and type(mod.log.warn) == "function" then
          warnedNoUsable = true
          mod.log:warn("1025Dex is inactive and the party has no usable native Pokemon; battle start was blocked safely")
        end
        return nil, "no usable Pokemon while 1025Dex species are unavailable"
      end

      local ok, a, b, c = pcall(originalStart, ownerMod, game, foe, opts)
      -- The source save must look normal outside the battle. The in-memory
      -- battleParty was already copied synchronously inside BattleBridge.start.
      restoreParty(party, snap)

      if not ok then error(a, 0) end

      -- Link-party copies are not written back to the local save. Normal
      -- battles are, so remember the pristine records and restore them after
      -- BattleBridge performs its end-of-battle writeback. Only retain a
      -- snapshot when BattleBridge actually accepted the battle.
      if a and session and not (opts.link and type(opts.linkParty) == "table") then
        pendingBySession[session] = snap
      end
      return a, b, c
    end

    Bridge._kim1025PartyGuard = true
    return true
  end

  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("game.ready", function() pcall(install) end)
    mod.events:on("battle.ended", function()
      local Runtime = package.loaded["src.core.game3.runtime"]
      local session = Runtime and Runtime.getSession and Runtime.getSession()
      local snap = session and pendingBySession[session]
      if snap then
        restoreParty(session.party, snap)
        pendingBySession[session] = nil
      end
    end)
  end

  -- Hot-reload / resumed-session safety.
  pcall(install)

  mod._kantoInMotion1025DexPartyGuard = {
    active = function() return not providerActive() end,
    isExpanded = expandedMon,
  }

  return true
end
