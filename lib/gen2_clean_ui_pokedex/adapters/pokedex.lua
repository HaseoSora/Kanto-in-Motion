return function(ctx)
  local Data = ctx.load("adapters.data")
  local Actions = ctx.load("adapters.actions")
  local Pokedex = {}
  local typeCache = {}

  local MODES = { "NEW", "OLD", "A-Z" }
  local ENTRY_ACTIONS = { "PAGE", "AREA", "CRY", "PRNT" }
  local SEARCH_TYPES = {
    "NORMAL", "FIGHTING", "FLYING", "POISON", "GROUND", "ROCK", "BUG",
    "GHOST", "STEEL", "FIRE", "WATER", "GRASS", "ELECTRIC", "PSYCHIC",
    "ICE", "DRAGON", "DARK",
  }
  local OPTION_MODES = {
    { id = "new", label = "NEW POKEDEX MODE", mode = "NEW",
      description = { "Pokemon are listed by", "evolution type." } },
    { id = "old", label = "OLD POKEDEX MODE", mode = "OLD",
      description = { "Pokemon are listed by", "official type." } },
    { id = "a_z", label = "A TO Z MODE", mode = "A-Z",
      description = { "Pokemon are listed", "alphabetically." } },
    { id = "unown", label = "UNOWN MODE", mode = "UNOWN", unown = true,
      description = { "Unown are listed", "in catching order." } },
  }
  local UNOWN_WORDS = {
    "ANGRY", "BEAR", "CHASE", "DIRECT", "ENGAGE", "FIND", "GIVE", "HELP",
    "INCREASE", "JOIN", "KEEP", "LAUGH", "MAKE", "NUZZLE", "OBSERVE",
    "PERFORM", "QUICKEN", "REASSURE", "SEARCH", "TELL", "UNDO", "VANISH",
    "WANT", "XXXXX", "YIELD", "ZOOM",
  }
  local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

  local function sourceInput(actions, id, kind, componentId, input, sourceIndex)
    return Actions.add(actions, {
      id = id, source = "screen.update", kind = kind,
      componentId = componentId, sourceIndex = sourceIndex,
      dispatch = "source_input", input = input,
    })
  end

  local function nested(source, key)
    local value = type(source) == "table" and rawget(source, key) or nil
    return type(value) == "table" and value or nil
  end

  local function dexEntry(state, species)
    local entries = nested(rawget(state, "dex"), "entries")
    local value = entries and rawget(entries, species) or nil
    return type(value) == "table" and value or nil
  end

  local function pokemonEntry(state, species)
    local pokemon = rawget(state, "pokemon")
    local value = type(pokemon) == "table" and rawget(pokemon, species) or nil
    if type(value) ~= "table" then
      local game = rawget(state, "game")
      local data = type(game) == "table" and rawget(game, "data") or nil
      pokemon = type(data) == "table" and rawget(data, "pokemon") or nil
      value = type(pokemon) == "table" and rawget(pokemon, species) or nil
    end
    return type(value) == "table" and value or nil
  end

  local function moveDefinition(state, move)
    local moves = rawget(state, "moves")
    local value = type(moves) == "table" and rawget(moves, move) or nil
    if type(value) ~= "table" then
      local game = rawget(state, "game")
      local data = type(game) == "table" and rawget(game, "data") or nil
      moves = type(data) == "table" and rawget(data, "moves") or nil
      value = type(moves) == "table" and rawget(moves, move) or nil
    end
    return type(value) == "table" and value or nil
  end

  local function evolutionRequirement(row)
    if type(row) ~= "table" then return "" end
    local method = Data.text(rawget(row, "method"), "")
    local level = rawget(row, "level")
    local item = Data.text(rawget(row, "item"), "")
    local time = Data.text(rawget(row, "time"), "")
    local comparison = Data.text(rawget(row, "comparison"), "")
    if level ~= nil then return "LEVEL " .. tostring(level) end
    if item ~= "" then return item:gsub("_", " ") end
    if time ~= "" then return time:gsub("_", " ") end
    if comparison ~= "" then return comparison:gsub("_", " ") end
    return method:gsub("_", " ")
  end

  local function referenceSnapshot(state, species)
    local definition = pokemonEntry(state, species)
    if not definition then return nil end
    local evolutions, levelMoves, machines = {}, {}, {}
    for _, row in ipairs(rawget(definition, "evolutions") or {}) do
      if type(row) == "table" then
        evolutions[#evolutions + 1] = {
          into = Data.id(rawget(row, "into")),
          requirement = evolutionRequirement(row),
          method = Data.id(rawget(row, "method")),
          level = Data.integer(rawget(row, "level"), 0),
          item = Data.id(rawget(row, "item")),
          time = Data.id(rawget(row, "time")),
          comparison = Data.id(rawget(row, "comparison")),
        }
      end
    end
    for _, row in ipairs(rawget(definition, "levelMoves") or {}) do
      if type(row) == "table" then
        local move = Data.id(rawget(row, "move"))
        local moveRow = moveDefinition(state, move)
        levelMoves[#levelMoves + 1] = {
          level = Data.integer(rawget(row, "level"), 0),
          move = move,
          name = Data.text(moveRow and rawget(moveRow, "name"), move),
          type = Data.text(moveRow and rawget(moveRow, "type"), ""),
          power = Data.integer(moveRow and rawget(moveRow, "power"), 0),
          accuracy = Data.integer(moveRow and rawget(moveRow, "accuracy"), 0),
          description = Data.text(moveRow and rawget(moveRow, "description"), ""),
        }
      end
    end
    for _, move in ipairs(rawget(definition, "tmhm") or {}) do
      local moveId = Data.id(move)
      local moveRow = moveDefinition(state, moveId)
      machines[#machines + 1] = {
        move = moveId,
        name = Data.text(moveRow and rawget(moveRow, "name"), moveId),
        type = Data.text(moveRow and rawget(moveRow, "type"), ""),
        power = Data.integer(moveRow and rawget(moveRow, "power"), 0),
        accuracy = Data.integer(moveRow and rawget(moveRow, "accuracy"), 0),
        description = Data.text(moveRow and rawget(moveRow, "description"), ""),
      }
    end
    return {
      evolutions = evolutions,
      levelMoves = levelMoves,
      tmhm = machines,
    }
  end

  local function monName(state, species)
    local definition = pokemonEntry(state, species)
    return Data.text(definition and rawget(definition, "name") or nil,
      Data.text(species, "UNKNOWN"))
  end

  local function artSnapshot(state, species)
    local definition = pokemonEntry(state, species)
    local palettes = rawget(state, "palettes")
    local pokemonPalettes = type(palettes) == "table"
      and rawget(palettes, "pokemon") or nil
    local paletteEntry = type(pokemonPalettes) == "table"
      and rawget(pokemonPalettes, species) or nil
    local pair = type(paletteEntry) == "table"
      and rawget(paletteEntry, "normal") or nil
    local palette
    if type(pair) == "table" and type(rawget(pair, 1)) == "table"
        and type(rawget(pair, 2)) == "table" then
      palette = {
        { 255, 255, 255 }, Data.copy(rawget(pair, 1)),
        Data.copy(rawget(pair, 2)), { 0, 0, 0 },
      }
    end
    return {
      species = Data.id(species),
      sprite = Data.text(definition and rawget(definition, "spriteFront") or nil,
        ""),
      paletteKey = Data.id(species),
      palette = palette,
    }
  end

  local function sourceRow(state, index)
    local rows = rawget(state, "rows")
    local value = type(rows) == "table" and rawget(rows, index) or nil
    return type(value) == "table" and value or nil
  end

  local function rowSnapshot(state, source, sourceIndex, actions)
    source = type(source) == "table" and source or {}
    local species = Data.id(rawget(source, "species"),
      "species_" .. sourceIndex)
    local seen = rawget(source, "seen") == true
    local caught = rawget(source, "caught") == true
    return {
      id = species,
      species = species,
      sourceIndex = sourceIndex,
      dex = Data.integer(rawget(source, "dex"), 0),
      name = monName(state, species),
      label = seen and monName(state, species) or "-----",
      seen = seen,
      caught = caught,
      disabled = not seen,
      art = artSnapshot(state, species),
      actionId = sourceInput(actions, "entry." .. sourceIndex .. ".open",
        "open", species, "a", sourceIndex),
    }
  end

  local function listRows(state, actions)
    local rows = rawget(state, "rows")
    local output = {}
    for sourceIndex = 1, #(type(rows) == "table" and rows or {}) do
      output[sourceIndex] = rowSnapshot(state, rawget(rows, sourceIndex),
        sourceIndex, actions)
    end
    return output
  end

  local function splitEntryText(value)
    local text = Data.text(value, "")
    if text == "" then return {} end
    local output, at = {}, 1
    while #output < 16 do
      local first, last = text:find("<NEXT>", at, true)
      if not first then
        output[#output + 1] = text:sub(at)
        break
      end
      output[#output + 1] = text:sub(at, first - 1)
      at = last + 1
    end
    return output
  end

  local function displayType(value)
    value = Data.text(value, "")
    return value == "PSYCHIC_TYPE" and "PSYCHIC" or value
  end

  local effectiveAreaRegion
  local screenData
  local activeSave

  local function currentSnapshot(state, current)
    if type(current) ~= "table" then return nil end
    local species = Data.id(rawget(current, "species"))
    local entry = dexEntry(state, species)
    local page = Data.integer(rawget(state, "page"), 1)
    local definition = pokemonEntry(state, species)
    local rawTypes = definition and rawget(definition, "types") or nil
    if type(rawTypes) ~= "table" then
      rawTypes = rawget(current, "types")
    end
    local firstPage = splitEntryText(entry and rawget(entry, "text"))
    local secondPage = splitEntryText(entry and rawget(entry, "text2"))
    local entryLines = Data.copy(page == 2 and secondPage or firstPage)
    local types, seenTypes = {}, {}
    for index = 1, 2 do
      local typeName = type(rawTypes) == "table"
        and displayType(rawget(rawTypes, index)) or ""
      if typeName ~= "" and not seenTypes[typeName] then
        types[#types + 1] = typeName
        seenTypes[typeName] = true
      end
    end
    if #types > 0 then
      typeCache[species] = Data.copy(types)
    elseif type(typeCache[species]) == "table" then
      types = Data.copy(typeCache[species])
    end
    local caughtCount = 0
    for _, row in ipairs(rawget(state, "rows") or {}) do
      if type(row) == "table" and rawget(row, "caught") == true then
        caughtCount = caughtCount + 1
      end
    end
    return {
      species = species,
      name = monName(state, species),
      dex = Data.integer(entry and rawget(entry, "dex") or rawget(current, "dex"), 0),
      kind = Data.text(entry and rawget(entry, "kind"), ""),
      height = Data.scalar(entry and rawget(entry, "height")),
      weight = Data.scalar(entry and rawget(entry, "weight")),
      seen = rawget(current, "seen") == true,
      caught = rawget(current, "caught") == true,
      caughtCount = caughtCount,
      region = effectiveAreaRegion(state, screenData(state), activeSave(state))
        :upper(),
      page = page,
      pages = { firstPage, secondPage },
      pageLines = entryLines,
      types = types,
      art = artSnapshot(state, species),
      reference = referenceSnapshot(state, species),
    }
  end

  local function totals(rows)
    local seen, caught = 0, 0
    for _, row in ipairs(rows) do
      if row.seen then seen = seen + 1 end
      if row.caught then caught = caught + 1 end
    end
    return seen, caught
  end

  local function regionOf(landmark)
    if type(landmark) ~= "number" or landmark <= 0 or landmark >= 0x5e then
      return nil
    end
    return landmark < 0x2e and "johto" or "kanto"
  end

  screenData = function(state)
    local data = rawget(state, "data")
    if type(data) == "table" then return data end
    local game = rawget(state, "game")
    data = type(game) == "table" and rawget(game, "data") or nil
    return type(data) == "table" and data or {}
  end

  activeSave = function(state)
    local game = rawget(state, "game")
    local save = type(game) == "table" and rawget(game, "save") or nil
    if type(save) == "table" then return save end
    save = rawget(state, "save")
    return type(save) == "table" and save or {}
  end

  effectiveAreaRegion = function(state, data, save)
    local requested = rawget(state, "areaRegion")
    if requested == "johto" or requested == "kanto" then return requested end
    local position = nested(save, "position")
    local mapId = position and rawget(position, "map") or nil
    local maps = nested(data, "gen2Maps")
    local map = maps and rawget(maps, mapId) or nil
    return regionOf(type(map) == "table" and rawget(map, "landmark") or nil)
      or "johto"
  end

  local function encounterHasSpecies(entry, species)
    local slots = nested(entry, "slots")
    if not slots then return false end
    local key, list = next(slots, nil)
    local visited = 0
    while key ~= nil and visited < 64 do
      if type(list) == "table" then
        for index = 1, math.min(#list, 256) do
          local slot = rawget(list, index)
          if type(slot) == "table" and rawget(slot, "species") == species then
            return true
          end
        end
      end
      visited = visited + 1
      key, list = next(slots, key)
    end
    return false
  end

  local function landmarkRecord(data, index)
    local registry = nested(data, "gen2Landmarks") or nested(data, "landmarks")
    local records = registry and nested(registry, "landmarks") or nil
    if not records then return nil, nil end
    local order = nested(registry, "order")
    local preferred = order and rawget(order, index + 1) or nil
    local record = preferred ~= nil and rawget(records, preferred) or nil
    if type(record) == "table" then return preferred, record end

    local bestId, bestRecord
    local id, candidate = next(records, nil)
    local visited = 0
    while id ~= nil and visited < 4096 do
      if type(candidate) == "table" and rawget(candidate, "index") == index then
        local textId = Data.id(id)
        if textId and (bestId == nil or textId < bestId) then
          bestId, bestRecord = textId, candidate
        end
      end
      visited = visited + 1
      id, candidate = next(records, id)
    end
    return bestId, bestRecord
  end

  local function nestIndices(data, save, species, region)
    local indices, present = {}, {}
    local function add(index)
      if type(index) ~= "number" or present[index]
          or regionOf(index) ~= region then return end
      present[index] = true
      indices[#indices + 1] = index
    end
    local maps = nested(data, "gen2Maps")
    local encounters = nested(data, "gen2Encounters")
    for _, groupName in ipairs({ "grass", "water" }) do
      local group = encounters and nested(encounters, groupName) or nil
      if group then
        local mapId, entry = next(group, nil)
        local visited = 0
        while mapId ~= nil and visited < 4096 do
          if encounterHasSpecies(entry, species) then
            local map = maps and rawget(maps, mapId) or nil
            if type(map) == "table" then add(rawget(map, "landmark")) end
          end
          visited = visited + 1
          mapId, entry = next(group, mapId)
        end
      end
    end
    local roamers = rawget(save, "roamers")
    for index = 1, #(type(roamers) == "table" and roamers or {}) do
      local slot = rawget(roamers, index)
      if type(slot) == "table" and rawget(slot, "species") == species
          and rawget(slot, "map") ~= nil then
        local map = maps and rawget(maps, rawget(slot, "map")) or nil
        if type(map) == "table" then add(rawget(map, "landmark")) end
      end
    end
    table.sort(indices)
    return indices
  end

  local function areaSnapshot(state, current, actions)
    if type(current) ~= "table" then return nil end
    local species = Data.id(rawget(current, "species"))
    local data, save = screenData(state), activeSave(state)
    local region = effectiveAreaRegion(state, data, save)
    local nests = {}
    for _, index in ipairs(nestIndices(data, save, species, region)) do
      local id, record = landmarkRecord(data, index)
      local name = Data.text(record and rawget(record, "name"), id or "UNKNOWN")
      nests[#nests + 1] = {
        index = index,
        id = Data.id(id, "landmark_" .. index),
        name = name:gsub("\n", " "),
        x = Data.scalar(record and rawget(record, "x")),
        y = Data.scalar(record and rawget(record, "y")),
      }
    end
    return {
      species = species,
      name = monName(state, species),
      region = region,
      requestedRegion = Data.id(rawget(state, "areaRegion")),
      nests = nests,
      unknown = #nests == 0,
      art = artSnapshot(state, species),
      actions = {
        previousRegion = sourceInput(actions, "area.previous_region", "adjust",
          "area", "left"),
        nextRegion = sourceInput(actions, "area.next_region", "adjust",
          "area", "right"),
        accept = sourceInput(actions, "area.accept", "close", "area", "a"),
        back = sourceInput(actions, "area.back", "close", "area", "b"),
      },
    }
  end

  local function optionRows(state, actions)
    local save = activeSave(state)
    local flags = nested(save, "engineFlags")
    local unlocked = flags and (rawget(flags, 12) == true
      or rawget(flags, "ENGINE_UNOWN_DEX") == true)
    local selected = Data.integer(rawget(state, "optionIndex"), 1)
    local output = {}
    for _, option in ipairs(OPTION_MODES) do
      if not option.unown or unlocked then
        local sourceIndex = #output + 1
        output[sourceIndex] = {
          id = option.id, sourceIndex = sourceIndex, label = option.label,
          mode = option.mode, description = Data.copy(option.description),
          selected = sourceIndex == selected,
          actionId = sourceInput(actions, "option." .. sourceIndex .. ".choose",
            "choose", option.id, "a", sourceIndex),
        }
      end
    end
    return output
  end

  local function searchTypeName(value)
    local index = Data.integer(value, 0)
    if index == 0 then return "-----" end
    return SEARCH_TYPES[index] or "-----"
  end

  local function searchRows(state, actions)
    local selected = Data.integer(rawget(state, "searchIndex"), 1)
    local types = rawget(state, "searchType")
    local rows = {
      { id = "type_1", label = "TYPE 1", value = searchTypeName(
        type(types) == "table" and rawget(types, 1) or 0) },
      { id = "type_2", label = "TYPE 2", value = searchTypeName(
        type(types) == "table" and rawget(types, 2) or 0) },
      { id = "begin", label = "BEGIN SEARCH" },
      { id = "cancel", label = "CANCEL" },
    }
    for index, row in ipairs(rows) do
      row.sourceIndex = index
      row.selected = index == selected
      row.actionId = sourceInput(actions, "search." .. index .. ".choose",
        "choose", row.id, "a", index)
    end
    return rows
  end

  local function unownSnapshot(state, actions)
    local save = activeSave(state)
    local source = rawget(save, "unownDex")
    local selectedSlot = Data.integer(rawget(state, "unownIndex"), 0)
    local rows = {}
    for index = 1, math.min(#(type(source) == "table" and source or {}), 26) do
      local letterIndex = Data.integer(rawget(source, index))
      if letterIndex and letterIndex >= 1 and letterIndex <= 26 then
        rows[#rows + 1] = {
          id = "unown_" .. letterIndex,
          sourceIndex = index,
          slot = index - 1,
          letterIndex = letterIndex,
          label = ALPHABET:sub(letterIndex, letterIndex),
          word = UNOWN_WORDS[letterIndex],
          selected = index - 1 == selectedSlot,
          art = { species = "UNOWN", form = ALPHABET:sub(letterIndex, letterIndex),
            paletteKey = "UNOWN" },
        }
      end
    end
    return {
      selectedSlot = selectedSlot,
      selectedIndex = selectedSlot + 1,
      rows = rows,
      actions = {
        previous = sourceInput(actions, "unown.previous", "navigate", "unown",
          "left"),
        next = sourceInput(actions, "unown.next", "navigate", "unown", "right"),
        accept = sourceInput(actions, "unown.accept", "close", "unown", "a"),
        back = sourceInput(actions, "unown.back", "close", "unown", "b"),
      },
    }
  end

  function Pokedex.extract(state)
    if type(state) ~= "table" then return nil, "state_type", "table" end
    local rows = rawget(state, "rows")
    if type(rows) ~= "table" then return nil, "rows_type", "table" end
    local actions = Actions.new("Gen2PokedexMenu")
    local selectedIndex = Data.integer(rawget(state, "index"), 1)
    local currentSource = sourceRow(state, selectedIndex)
    local copiedRows = listRows(state, actions)
    local seen, caught = totals(copiedRows)
    local entryActions = {}
    for index, label in ipairs(ENTRY_ACTIONS) do
      entryActions[index] = {
        id = label:lower(), label = label, sourceIndex = index,
        selected = index == Data.integer(rawget(state, "entryAction"), 1),
        actionId = sourceInput(actions, "entry_action." .. index, "action",
          label:lower(), "a", index),
      }
    end

    local model = {
      schema = "clean_ui.presenter_model.v1",
      screenId = "Gen2PokedexMenu",
      family = "pokedex",
      preset = "L",
      title = "POKEDEX",
      view = Data.text(rawget(state, "view"), "list"),
      sortMode = MODES[Data.integer(rawget(state, "modeIndex"), 1)] or "NEW",
      navigation = {
        selectedIndex = selectedIndex,
        selectedId = type(currentSource) == "table"
          and Data.id(rawget(currentSource, "species")) or nil,
        scroll = Data.integer(rawget(state, "scroll"), 0),
        itemCount = #rows,
      },
      rows = copiedRows,
      totals = { seen = seen, caught = caught },
      current = currentSnapshot(state, currentSource),
      entry = {
        page = Data.integer(rawget(state, "page"), 1),
        selectedAction = Data.integer(rawget(state, "entryAction"), 1),
        actions = entryActions,
        newEntry = rawget(state, "newEntry") == true,
      },
      area = areaSnapshot(state, currentSource, actions),
      options = {
        selectedIndex = Data.integer(rawget(state, "optionIndex"), 1),
        rows = optionRows(state, actions),
      },
      search = {
        selectedIndex = Data.integer(rawget(state, "searchIndex"), 1),
        rows = searchRows(state, actions),
        message = Data.text(rawget(state, "searchMessage"), ""),
        resultCount = #(type(rawget(state, "searchResults")) == "table"
          and rawget(state, "searchResults") or {}),
        resultsActive = rawget(state, "searchResults") ~= nil,
      },
      unown = unownSnapshot(state, actions),
      controls = {
        back = sourceInput(actions, "pokedex.back", "close", "pokedex", "b"),
        options = sourceInput(actions, "pokedex.options", "open", "options",
          "select"),
        search = sourceInput(actions, "pokedex.search", "open", "search",
          "start"),
        previousAction = sourceInput(actions, "entry_action.previous", "navigate",
          "entry_actions", "left"),
        nextAction = sourceInput(actions, "entry_action.next", "navigate",
          "entry_actions", "right"),
      },
    }
    model.actionDescriptors = Actions.describe(actions)
    return { model = model, actions = actions }
  end

  Pokedex.MODES = MODES
  Pokedex.ENTRY_ACTIONS = ENTRY_ACTIONS
  Pokedex.SEARCH_TYPES = SEARCH_TYPES
  return Pokedex
end
