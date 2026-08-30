-- Kanto in Motion
-- Animated front-sprite provider for menus, Pokedex, evolutions, and title screens.
-- Public releases intentionally ship without Pokemon-derived sprite assets.
-- Animated assets are imported locally by the player with tools/import_assets.py.
return function(mod)
  local GameVersion = require("src.core.GameVersion")
  local IS_GEN2 = GameVersion.generation() == 2
  if not IS_GEN2 then
    local okProbe, BattleStateProbe = pcall(require, "src.battle.BattleState")
    IS_GEN2 = okProbe and type(BattleStateProbe) == "table"
      and rawget(BattleStateProbe, "newWild") == nil
  end
  local MOD_ID = "animated_menu_pokemon"

  -- Open compatibility registry. Third-party UI and battle mods can register
  -- ownership without Kanto in Motion knowing their mod ID ahead of time.
  -- Registrations are advisory and fail-open: a missing/errored callback never
  -- causes KIM to blank another mod's presentation.
  mod.exports = mod.exports or {}
  mod._kantoInMotionInterop = {
    apiVersion = 1,
    uiOwners = {},
    battleOwners = {},
  }

  function mod._kantoInMotionInterop:ownerAlive(owner)
    if type(owner) ~= "string" or owner == "" or owner == MOD_ID then return false end
    if type(mod.find) ~= "function" then return true end
    local ok, handle = pcall(mod.find, owner)
    return ok and handle ~= nil
  end

  function mod._kantoInMotionInterop:registerUi(spec)
    if type(spec) ~= "table" then return false, "UI compatibility spec must be a table" end
    local owner = spec.owner or spec.modId or spec.sourceModId
    if type(owner) ~= "string" or owner == "" or owner == MOD_ID then
      return false, "UI compatibility owner must be the source mod id"
    end
    if spec.active ~= nil and type(spec.active) ~= "function" and type(spec.active) ~= "boolean" then
      return false, "UI compatibility active must be a function or boolean"
    end
    if spec.match ~= nil and type(spec.match) ~= "function" then
      return false, "UI compatibility match must be a function"
    end
    if spec.kinds ~= nil and type(spec.kinds) ~= "table" and type(spec.kinds) ~= "string" then
      return false, "UI compatibility kinds must be a table or string"
    end
    spec.owner = owner
    spec.priority = tonumber(spec.priority) or 0
    self.uiOwners[owner] = spec
    return true
  end

  function mod._kantoInMotionInterop:registerBattle(spec)
    if type(spec) ~= "table" then return false, "battle compatibility spec must be a table" end
    local owner = spec.owner or spec.modId or spec.sourceModId
    if type(owner) ~= "string" or owner == "" or owner == MOD_ID then
      return false, "battle compatibility owner must be the source mod id"
    end
    if spec.active ~= nil and type(spec.active) ~= "function" and type(spec.active) ~= "boolean" then
      return false, "battle compatibility active must be a function or boolean"
    end
    if spec.match ~= nil and type(spec.match) ~= "function" then
      return false, "battle compatibility match must be a function"
    end
    local mode = tostring(spec.modernUi or spec.mode or "native"):lower()
    if mode == "off" or mode == "yield" then mode = "native" end
    if mode ~= "native" and mode ~= "lower" and mode ~= "full" then
      return false, "battle compatibility modernUi must be native, lower, or full"
    end
    if spec.suppressSurfaces ~= nil and type(spec.suppressSurfaces) ~= "table" then
      return false, "battle compatibility suppressSurfaces must be a table"
    end
    spec.owner = owner
    spec.modernUi = mode
    spec.sceneOwner = spec.sceneOwner ~= false
    spec.priority = tonumber(spec.priority) or 0
    self.battleOwners[owner] = spec
    return true
  end

  function mod._kantoInMotionInterop:unregister(owner)
    self.uiOwners[owner] = nil
    self.battleOwners[owner] = nil
    return true
  end

  function mod._kantoInMotionInterop:_active(spec, game, state, kind)
    if type(spec) ~= "table" then return false end
    if not self:ownerAlive(spec.owner) then return false end
    local probe = spec.match or spec.active
    if type(probe) == "function" then
      local ok, value = pcall(probe, game, state, kind)
      return ok and value == true
    end
    if type(probe) == "boolean" then return probe end
    return true
  end

  function mod._kantoInMotionInterop:_uiKindClaimed(spec, kind)
    local kinds = spec and spec.kinds
    if kinds == nil then return true end
    if type(kinds) == "string" then kinds = { [kinds] = true } end
    if type(kinds) ~= "table" then return false end
    local claimed = {}
    for key, value in pairs(kinds) do
      if type(key) == "number" then claimed[tostring(value):lower()] = true
      elseif value == true then claimed[tostring(key):lower()] = true end
    end
    local k = tostring(kind or ""):lower()
    if claimed.all or claimed["*"] or claimed[k] then return true end
    if claimed.battle and k == "battle" then return true end
    if claimed.dialogue and (k == "text" or k == "choice" or k == "quantity" or k == "save_panel") then
      return true
    end
    if claimed.pokemon and (k == "party" or k == "pokedex" or k == "summary"
        or k == "trainer_card" or k == "dex_entry" or k == "box_mon_list"
        or k == "box_root" or k == "gen3_box" or k == "evolution"
        or k == "levelup") then
      return true
    end
    if claimed.manager and (k == "mod_manager" or k == "mod_options") then return true end
    if claimed.title and (k == "title_continue" or k == "voxel_precache" or k == "voxel_cache_load") then
      return true
    end
    if claimed.menus and (k == "bag" or k == "options" or k == "move_learn"
        or k == "pic_box" or k == "naming" or k == "town_map"
        or k == "quarantine_report" or k == "rby_mmo_profile"
        or k == "rby_mmo_rank" or k == "rby_mmo_char_pick"
        or k == "shop_list" or k == "pc_list" or k == "list"
        or k == "menu" or k == "link") then
      return true
    end
    return false
  end

  function mod._kantoInMotionInterop:uiOwnerFor(game, state, kind)
    local best, bestPriority = nil, -math.huge
    for _, spec in pairs(self.uiOwners) do
      if self:_uiKindClaimed(spec, kind) and self:_active(spec, game, state, kind)
          and spec.priority >= bestPriority then
        best, bestPriority = spec, spec.priority
      end
    end
    return best
  end

  function mod._kantoInMotionInterop:battleOwnerFor(game, battle)
    local best, bestPriority = nil, -math.huge
    for _, spec in pairs(self.battleOwners) do
      if self:_active(spec, game, battle, "battle") and spec.priority >= bestPriority then
        best, bestPriority = spec, spec.priority
      end
    end
    return best
  end

  function mod._kantoInMotionInterop:hasBattleSceneOwner()
    for _, spec in pairs(self.battleOwners) do
      if spec.sceneOwner ~= false and self:ownerAlive(spec.owner) then return true end
    end
    return false
  end

  function mod._kantoInMotionInterop:blocksBattleFeature(feature)
    local optIn = feature == "sprites" and "allowKIMSprites"
      or feature == "animations" and "allowKIMAnimations" or nil
    for _, spec in pairs(self.battleOwners) do
      if spec.sceneOwner ~= false and self:ownerAlive(spec.owner)
          and (not optIn or spec[optIn] ~= true) then
        return true
      end
    end
    return false
  end

  function mod._kantoInMotionInterop:hasPokemonSpriteBridgeUi()
    for _, spec in pairs(self.uiOwners) do
      if spec.pokemonSpriteBridge == true and self:ownerAlive(spec.owner) then
        return true
      end
    end
    return false
  end

  mod.exports.kantoInMotionCompatibility = {
    apiVersion = 1,
    registerUiOwner = function(spec) return mod._kantoInMotionInterop:registerUi(spec) end,
    registerBattleOwner = function(spec) return mod._kantoInMotionInterop:registerBattle(spec) end,
    unregisterOwner = function(owner) return mod._kantoInMotionInterop:unregister(owner) end,
    modes = { "native", "lower", "full" },
  }
  -- Convenience aliases for small mods that do not need the namespaced table.
  mod.exports.registerUiCompatibility = mod.exports.kantoInMotionCompatibility.registerUiOwner
  mod.exports.registerBattleCompatibility = mod.exports.kantoInMotionCompatibility.registerBattleOwner
  local DATA_FILES = {
    gen2 = "data/animated_menu_sprites_gen2.lua",
    gen3 = "data/animated_menu_sprites_gen3.lua",
    gen4 = "data/animated_menu_sprites_gen4.lua",
    gen5 = "data/animated_menu_sprites_gen5.lua",
  }
  local SHINY_DATA_FILES = {
    gen2 = "data/animated_menu_sprites_gen2_shiny.lua",
    gen3 = "data/animated_menu_sprites_gen3_shiny.lua",
    gen4 = "data/animated_menu_sprites_gen4_shiny.lua",
    gen5 = "data/animated_menu_sprites_gen5_shiny.lua",
  }

  local optionSchema = {
    { key = "enabled", label = "MENU SPRITES", type = "toggle", default = true },
    { key = "generation", label = "SPRITE GEN", type = "choice",
      default = "gen5", choices = {
        { "GEN 2", "gen2" }, { "GEN 3", "gen3" },
        { "GEN 4", "gen4" }, { "GEN 5", "gen5" },
      } },
    { key = "animate", label = "ANIMATION", type = "toggle", default = true },
    { key = "titleScreen", label = "TITLE SCREEN", type = "toggle", default = true },
    { key = "titleTrainer", label = "TITLE TRAINER", type = "choice",
      default = "animated", choices = {
        { "ANIMATED", "animated" }, { "ORIGINAL GEN 1", "original" },
      }, description = "Choose Kanto in Motion's animated Red or Gen1Recomp's original title-screen trainer sprite." },
    { key = "titleCycleSpeed", label = "TITLE CYCLE SPEED", type = "choice",
      default = "slow", choices = {
        { "NORMAL", "normal" }, { "SLOW", "slow" }, { "SLOWER", "slower" },
      } },
  }

  -- Battle Lite is deliberately independent from Battle Art's voxel renderer.
  -- It reuses only animated 2D Pokemon art and the flat Gen 6 backdrop set.
  local battleOptionSchema = {
    { key = "battleSystem", label = "BATTLE SYSTEM", type = "toggle",
      default = true,
      description = "Master switch for Kanto in Motion battle presentation. OFF yields the battle scene to vanilla or another battle mod." },
    { key = "battleSprites", label = "BATTLE SPRITES", type = "toggle",
      default = true,
      description = "Animate battle Pokemon without enabling voxel rendering." },
    { key = "battleShinyOdds", label = "SHINY ODDS", type = "choice",
      default = "native", choices = {
        { "NATIVE 1/8192", "native" }, { "1/4096", "4096" },
        { "1/2048", "2048" }, { "1/1024", "1024" },
        { "1/512", "512" }, { "1/256", "256" },
        { "1/128", "128" }, { "1/64", "64" },
        { "1/32", "32" }, { "1/16", "16" },
        { "1/8", "8" }, { "1/4", "4" },
        { "1/2", "2" }, { "ALWAYS", "1" },
      }, description = "Wild shiny encounter odds. NATIVE leaves Gen 1 DVs untouched (the canonical Gen 2 shiny pattern occurs naturally at 1/8192). Other choices roll exact Kanto in Motion shiny odds when a wild Pokemon is created. Shiny DVs are stored on the Pokemon, so a caught shiny stays shiny." },
    { key = "battleAnimations", label = "MOVE ANIMATIONS", type = "toggle",
      default = true,
      description = "Use the integrated Kanto Rework / Pokemon Essentials animations for all 165 Gen 1 moves. OFF falls back to Gen1Recomp's native move animations." },
    { key = "battleFrontGeneration", label = "FRONT SET", type = "choice",
      default = "menu", choices = {
        { "SAME AS MENU", "menu" }, { "GEN 2", "gen2" },
        { "GEN 3", "gen3" }, { "GEN 4", "gen4" },
        { "GEN 5", "gen5" },
      }, description = "Animated opponent/front sprite collection." },
    { key = "battleBackGeneration", label = "BACK SET", type = "choice",
      default = "gen5", choices = {
        { "GEN 5", "gen5" }, { "GEN 3", "gen3" }, { "ROM", "rom" },
      }, description = "Player-side battle sprite. GEN 3/5 are animated; ROM keeps the game's original back sprite." },
    { key = "battleTrainerSprite", label = "PLAYER TRAINER", type = "choice",
      default = "rom", choices = {
        { "DEFAULT / ROM", "rom" }, { "PNG", "png" },
        { "GEN 1", "gen1" }, { "GEN 2", "gen2" },
        { "GEN 3", "gen3" }, { "GEN 4", "gen4" },
        { "GEN 5", "gen5" }, { "ASH", "ash" },
        { "GARY", "gary" }, { "RED", "red" },
        { "ASH FRONT", "ash_front" }, { "MISTY FRONT", "misty_front" },
        { "BROCK FRONT", "brock_front" }, { "BULMA FRONT", "bulma_front" },
        { "GARY FRONT", "gary_front" },
        { "BOY", "boy" }, { "LASS", "lass" }, { "HILBERT", "hilbert" },
      }, description = "Choose the player trainer shown during the battle intro/send-out. ANIMATION ON plays that trainer's five-frame intro atlas when available; ANIMATION OFF holds the same trainer on its first frame. PNG/BOY/LASS/HILBERT are static-only, and DEFAULT / ROM yields to the game or another trainer-sprite provider." },
    { key = "battlePlayerSize", label = "PLAYER PKMN SIZE", type = "choice",
      default = "125", choices = {
        { "50%", "50" }, { "55%", "55" }, { "60%", "60" }, { "65%", "65" },
        { "70%", "70" }, { "75%", "75" }, { "80%", "80" }, { "85%", "85" },
        { "90%", "90" }, { "95%", "95" }, { "100%", "100" }, { "105%", "105" },
        { "110%", "110" }, { "115%", "115" }, { "120%", "120" }, { "125%", "125" },
        { "130%", "130" }, { "135%", "135" }, { "140%", "140" }, { "145%", "145" },
        { "150%", "150" }, { "155%", "155" }, { "160%", "160" }, { "165%", "165" },
        { "170%", "170" }, { "175%", "175" }, { "180%", "180" }, { "185%", "185" },
        { "190%", "190" }, { "195%", "195" }, { "200%", "200" },
      }, description = "Scale only the player-side Pokemon about the engine's normal bottom-center battle anchor in 5% steps." },
    { key = "battleHudScale", label = "HUD SCALE", type = "choice",
      default = "og", choices = {
        { "OG", "og" }, { "SCALED", "scaled" },
      }, description = "Battle Art HUD SCALE. OG follows the normal window-fit scale; SCALED uses Battle Art's one-rung-smaller compact HUD." },
    { key = "battleTextScale", label = "BATTLE TEXT SIZE", type = "choice",
      default = "150", choices = {
        { "100%", "100" }, { "125%", "125" }, { "150%", "150" },
        { "175%", "175" }, { "200%", "200" }, { "225%", "225" },
        { "250%", "250" }, { "275%", "275" }, { "300%", "300" },
        { "325%", "325" }, { "350%", "350" }, { "375%", "375" },
        { "400%", "400" },
      }, description = "Scale only Modern UI's lower battle command, move and message text. Panel size and the Battle Art HP/status + Quality of Life EXP HUD are unaffected." },
    { key = "battleMoveLayout", label = "MOVE LAYOUT", type = "choice",
      default = "grid", choices = {
        { "GRID", "grid" }, { "VERTICAL", "vertical" },
      }, description = "GRID uses a 2x2 move grid. VERTICAL lists the four moves top-to-bottom." },
    { key = "battleMoveInfo", label = "MOVE INFO", type = "toggle",
      default = false,
      description = "Show the selected move's type, PP, power, and accuracy beside the move list. OFF is the default and gives move names the full panel width; ON uses the readable v8.6.36 info-column width." },
  }

  -- Battle Lite v1 is intentionally Gen1-only. Gen2 keeps Kanto in Motion's
  -- existing menu/Status compatibility unchanged until the separate Gen2
  -- battle port is ready.
  if IS_GEN2 then
    battleOptionSchema = {}
  else
    battleOptionSchema[#battleOptionSchema + 1] = {
      key = "battleArenaFill", label = "ARENA FILL", type = "choice",
      default = "krs", choices = {
        { "OFF", "off" }, { "WHITE", "white" }, { "KRS", "krs" }, { "GEN6", "gen6" },
      },
      description = "Battle arena source. KRS uses Kanto Rework Suite's authored 1920x950 location/time backgrounds and stance anchors; GEN6 keeps the previous Battle Lite arena set.",
    }
    local bgOffsetChoices = {}
    for px = 0, 400, 20 do
      bgOffsetChoices[#bgOffsetChoices + 1] = { tostring(px) .. " PX", tostring(px) }
    end
    battleOptionSchema[#battleOptionSchema + 1] = {
      key = "battleBgYOffset", label = "BG Y-OFFSET", type = "choice",
      default = "140", choices = bgOffsetChoices,
      description = "Battle Art BG Y-OFFSET. Chooses how far down into a GEN6 source image its top crop begins, from 0 to 400 source-image pixels.",
    }
    battleOptionSchema[#battleOptionSchema + 1] = {
      key = "battleHudColor", label = "HUD COLOR", type = "choice",
      default = "color", choices = {
        { "COLOR", "color" }, { "INVERTED", "inverted" },
      },
      description = "Battle Art-style HP/status glyph treatment. INVERTED uses light glyphs with a dark pixel shadow while preserving the green/yellow/red HP gauge colors.",
    }
  end

  -- This preference belongs to Gen1 only. It defaults ON for new users, but
  -- once a player turns it OFF the saved mod option is honored on later Gen1
  -- launches. Gen2 never defines this row and never consults its saved value.
  if not IS_GEN2 then
    table.insert(optionSchema, 2, {
      key = "integratedModernUi", label = "INTEGRATED MODERN UI",
      type = "toggle", default = true,
      description = "Gen1 only. Defaults ON and remembers your choice across launches. Gen2 always uses its own UI owner.",
    })
  end

  -- Modern UI re-defines this schema after it loads, so publish the complete
  -- option set even though the compact Kanto in Motion screen presents the
  -- battle rows in their own submenu.
  local combinedKantoOptionSchema = {}
  for _, row in ipairs(optionSchema) do
    combinedKantoOptionSchema[#combinedKantoOptionSchema + 1] = row
  end
  for _, row in ipairs(battleOptionSchema) do
    combinedKantoOptionSchema[#combinedKantoOptionSchema + 1] = row
  end
  mod._kantoInMotionOptionSchema = combinedKantoOptionSchema
  mod.options:define(combinedKantoOptionSchema)

  -- Modern UI ownership is generation-aware:
  --   Gen 1 -> saved Gen1 preference (default ON)
  --   Gen 2 -> always OFF (Clean UI or the native Gen2 UI owns it)
  local function integratedModernUiEnabled()
    if IS_GEN2 then return false end
    return mod.options:get("integratedModernUi") ~= false
  end

  local collections = {}
  local shinyCollections = {}
  local backCollections = {}
  local imageCache = {}
  local frameCache = {}
  local renderCache = {}

  local function loadTable(relative, quiet)
    local source, err = mod:read(relative)
    if not source then
      if not quiet then mod.log:error("cannot read %s: %s", relative, tostring(err)) end
      return {}
    end
    local chunk, compileErr = load(source, "@" .. mod.path .. "/" .. relative)
    if not chunk then
      mod.log:error("cannot compile %s: %s", relative, tostring(compileErr))
      return {}
    end
    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then
      mod.log:error("cannot load %s: %s", relative, tostring(data))
      return {}
    end
    return data
  end

  -- These files are generated locally by tools/import_assets.py.  Missing
  -- local collections are normal in the public asset-free package.
  for generation, relative in pairs(DATA_FILES) do
    collections[generation] = loadTable(relative, true)
  end
  for generation, relative in pairs(SHINY_DATA_FILES) do
    local collection = loadTable(relative, true)
    -- Also accept Battle Art's original metadata filenames when users copy
    -- the shiny metadata directly into Kanto in Motion instead of running
    -- tools/import_assets.py. The importer renames these to animated_menu_*,
    -- but the records themselves are compatible with the menu/title renderer.
    if next(collection) == nil then
      local battleRelative = relative:gsub("animated_menu_sprites_", "animated_battle_sprites_", 1)
      collection = loadTable(battleRelative, true)
    end
    shinyCollections[generation] = collection
  end
  -- Kanto in Motion's menu metadata already carries Gen 5 backs. Battle Art's
  -- extended Gen 3 backs live in a separate table, so bring in just that 2D
  -- data file rather than any voxel/runtime modules.
  backCollections.gen3 = loadTable("data/animated_battle_backs_gen3.lua", true)
  -- Generated from every compatible normal/shiny atlas pair bundled with this
  -- build. Values are source-frame Y corrections that remove only the
  -- difference in transparent bottom padding between the two color variants.
  -- This keeps naturally floating species at their authored height while
  -- preventing shiny atlases with larger transparent canvases from hovering.
  local shinyGroundOffsets = loadTable("data/shiny_ground_offsets.lua", true)
  -- Union alpha bounds for every compatible animated atlas. Non-Gen5 sets use
  -- these bounds to map their authored animation into the corresponding Gen5
  -- visual envelope. This keeps generation changes stylistic instead of also
  -- changing apparent Pokemon size/centering/ground contact.
  local spriteVisualBounds = loadTable("data/sprite_visual_bounds.lua", true)
  local titlePlayer = loadTable("data/title_player_red.lua", true)

  local function selectedGeneration()
    local value = mod.options:get("generation")
    return collections[value] and value or "gen5"
  end

  local SPECIES_KEY_ALIASES = {
    -- Gen 2's legacy internal constants keep punctuation placeholders that do
    -- not match Kanto in Motion's imported sprite-table keys. Accept both
    -- those engine IDs and display-name-normalized forms at the shared lookup
    -- seam so Dex/Summary/Evolution/battle consumers all resolve the same art.
    FARFETCH_D = "FARFETCHD",
    MR__MIME = "MR_MIME",
    MRMIME = "MR_MIME",
  }

  local function normalizedSpecies(species)
    if type(species) ~= "string" then return nil end
    local key = species:upper():gsub("[^A-Z0-9_]", "")
    return SPECIES_KEY_ALIASES[key] or key
  end

  local function localFrontRecord(species, generation)
    species = normalizedSpecies(species)
    generation = generation or selectedGeneration()
    local collection = collections[generation]
    local record = species and collection and collection[species]
    local front = type(record) == "table" and record.front or nil
    if type(front) ~= "table" or type(front.image) ~= "string" then return nil end
    return front, generation, species
  end

  local function localShinyFrontRecord(species, generation)
    species = normalizedSpecies(species)
    generation = generation or selectedGeneration()
    local collection = shinyCollections[generation]
    local record = species and collection and collection[species]
    local front = type(record) == "table" and record.front or nil
    if type(front) ~= "table" or type(front.image) ~= "string" then return nil end
    return front, generation, species
  end

  local function localBackRecord(species, generation)
    species = normalizedSpecies(species)
    generation = generation or "gen5"
    local collection = generation == "gen3" and backCollections.gen3
      or collections[generation]
    local record = species and collection and collection[species]
    local back = type(record) == "table" and record.back or nil
    if type(back) ~= "table" or type(back.image) ~= "string" then return nil end
    return back, generation, species
  end

  local function localShinyBackRecord(species, generation)
    species = normalizedSpecies(species)
    generation = generation or "gen5"
    local collection = shinyCollections[generation]
    local record = species and collection and collection[species]
    local back = type(record) == "table" and record.back or nil
    if type(back) ~= "table" or type(back.image) ~= "string" then return nil end
    return back, generation, species
  end

  local function visualBoundsFor(generation, variant, side, species)
    species = normalizedSpecies(species)
    local gen = spriteVisualBounds and spriteVisualBounds[generation]
    local variants = gen and gen[variant or "normal"]
    local view = variants and variants[side or "front"]
    local row = species and view and view[species]
    if type(row) ~= "table" then return nil end
    local x, y = tonumber(row[1]), tonumber(row[2])
    local w, h = tonumber(row[3]), tonumber(row[4])
    if not (x and y and w and h and w > 0 and h > 0) then return nil end
    return { x=x, y=y, w=w, h=h }
  end

  local function gen5ReferenceRecord(species, side)
    if side == "back" then
      local record = localBackRecord(species, "gen5")
      return record
    end
    local record = localFrontRecord(species, "gen5")
    return record
  end

  local function presentationSize(generation, species, side, fallback)
    if generation ~= "gen5" then
      local ref = gen5ReferenceRecord(species, side)
      if type(ref) == "table" then
        local w = math.max(1, math.floor(tonumber(ref.width) or 1))
        local h = math.max(1, math.floor(tonumber(ref.height) or 1))
        return w, h
      end
    end
    fallback = fallback or {}
    return math.max(1, math.floor(tonumber(fallback.width) or 1)),
      math.max(1, math.floor(tonumber(fallback.height) or 1))
  end

  local function battleFrontGeneration()
    local value = mod.options:get("battleFrontGeneration")
    if value == "menu" or value == nil then return selectedGeneration() end
    return collections[value] and value or selectedGeneration()
  end

  local function battleBackGeneration()
    local value = mod.options:get("battleBackGeneration")
    if value == "gen3" or value == "gen5" or value == "rom" then return value end
    return "gen5"
  end

  -- Battle Art 1.9.8 shiny detection. Gen 1 already stores the four DVs
  -- used by Gen 2 shininess, so battle art can route shiny atlases without
  -- depending on a separate shiny mod API. Keep an explicit mon.shiny flag as
  -- a compatibility fast path for engines/mods that publish it directly.
  local SHINY_ATTACK = {
    [2] = true, [3] = true, [6] = true, [7] = true,
    [10] = true, [11] = true, [14] = true, [15] = true,
  }
  local function isBattleShiny(mon)
    if type(mon) ~= "table" then return false end
    if mon.shiny == true then return true end
    local dvs = mon.dvs
    if type(dvs) ~= "table" then return false end
    local attack = tonumber(dvs.attack)
    local defense = tonumber(dvs.defense)
    local speed = tonumber(dvs.speed)
    local special = tonumber(dvs.special)
    if defense ~= 10 or speed ~= 10 or special ~= 10
        or SHINY_ATTACK[attack] ~= true then
      return false
    end
    -- Match Battle Art exactly when a mod also stores the derived HP DV.
    local hp = (attack % 2) * 8 + (defense % 2) * 4
      + (speed % 2) * 2 + (special % 2)
    return dvs.hp == nil or tonumber(dvs.hp) == hp
  end

  local function setShinyDvState(mon, shiny)
    if type(mon) ~= "table" then return false end
    mon.dvs = type(mon.dvs) == "table" and mon.dvs or {}
    local dvs = mon.dvs
    local attack = math.max(0, math.min(15, tonumber(dvs.attack) or math.random(0, 15)))
    if shiny then
      -- Gen 2 shininess requires attack bit 1 plus 10/10/10 for the other
      -- DVs. Preserve as much of the Pokemon's original Attack DV as possible.
      if attack % 4 < 2 then attack = attack + 2 end
      dvs.attack, dvs.defense, dvs.speed, dvs.special = attack, 10, 10, 10
    else
      -- Exact custom odds require a failed roll not to remain a naturally
      -- shiny 1/8192 DV combination. Toggle only Attack's shiny bit, leaving
      -- the other DVs and all ordinary encounters untouched.
      if isBattleShiny(mon) and attack % 4 >= 2 then
        attack = attack - 2
        dvs.attack = attack
      end
    end
    if dvs.hp ~= nil then
      local defense = tonumber(dvs.defense) or 0
      local speed = tonumber(dvs.speed) or 0
      local special = tonumber(dvs.special) or 0
      dvs.hp = (attack % 2) * 8 + (defense % 2) * 4
        + (speed % 2) * 2 + (special % 2)
    end
    mon.shiny = shiny and true or nil
    return true
  end

  local function rollWildShiny(mon)
    if type(mon) ~= "table" then return false end
    local odds = mod.options:get("battleShinyOdds")
    if odds == nil or odds == "native" then
      local shiny = isBattleShiny(mon)
      if shiny then mon.shiny = true end
      return shiny
    end
    local denominator = tonumber(odds) or 8192
    denominator = math.max(1, math.floor(denominator))
    local roll
    if love and love.math and type(love.math.random) == "function" then
      roll = love.math.random(denominator)
    else
      roll = math.random(denominator)
    end
    local shiny = roll == 1
    setShinyDvState(mon, shiny)
    return shiny
  end

  local function battleRecord(species, side, mon)
    if mod.options:get("battleSprites") == false then return nil end
    if side == "back" then
      local generation = battleBackGeneration()
      if generation == "rom" then return nil end
      if isBattleShiny(mon) then
        local shiny, actual, normalized = localShinyBackRecord(species, generation)
        if shiny then return shiny, actual, normalized, true end
      end
      local back, actual, normalized = localBackRecord(species, generation)
      if back then return back, actual, normalized, false end
      return nil
    end
    local generation = battleFrontGeneration()
    if isBattleShiny(mon) then
      local shiny, actual, normalized = localShinyFrontRecord(species, generation)
      if shiny then return shiny, actual, normalized, true end
    end
    local front, actual, normalized = localFrontRecord(species, generation)
    if front then return front, actual, normalized, false end
    return nil
  end

  local function shinyGroundOffset(generation, side, species, shiny)
    if shiny ~= true then return 0 end
    species = normalizedSpecies(species)
    if generation ~= "gen5" then
      -- A normalized non-Gen5 shiny is already mapped into the normal Gen5
      -- visual envelope, so applying the older source-padding correction again
      -- would double-shift it. Rare records that cannot be normalized keep the
      -- legacy correction as a safe fallback.
      local src = visualBoundsFor(generation, "shiny", side, species)
        or visualBoundsFor(generation, "normal", side, species)
      local ref = visualBoundsFor("gen5", "normal", side, species)
      local refRecord = gen5ReferenceRecord(species, side)
      if src and ref and type(refRecord) == "table" then return 0 end
    end
    local gen = generation and shinyGroundOffsets[generation]
    local view = gen and gen[side]
    return tonumber(species and view and view[species]) or 0
  end

  local function localHasSprite(species, generation)
    return localFrontRecord(species, generation) ~= nil
  end

  local function atlasImage(path)
    if imageCache[path] == false then return nil end
    if imageCache[path] then return imageCache[path] end
    if not (mod.assets and type(mod.assets.image) == "function") then
      imageCache[path] = false
      return nil
    end
    local ok, image = pcall(function() return mod.assets:image(path) end)
    if not ok or not image then
      imageCache[path] = false
      return nil
    end
    if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
    imageCache[path] = image
    return image
  end

  local function timingFor(front)
    local hit = frameCache[front]
    if hit then return hit end
    local frames = math.max(1, math.floor(tonumber(front.frames) or 1))
    local durations = type(front.durations) == "table" and front.durations or {}
    local cumulative, total = {}, 0
    for i = 1, frames do
      local d = tonumber(durations[i]) or 100
      if d < 1 then d = 1 end
      total = total + d
      cumulative[i] = total
    end
    hit = { frames = frames, cumulative = cumulative, total = math.max(total, 1) }
    frameCache[front] = hit
    return hit
  end

  local function currentFrame(front)
    local timing = timingFor(front)
    if not mod.options:get("animate") or timing.frames <= 1 then return 1 end
    local now = love.timer and love.timer.getTime and love.timer.getTime() or 0
    local t = (now * 1000) % timing.total
    for i = 1, timing.frames do
      if t < timing.cumulative[i] then return i end
    end
    return timing.frames
  end

  local function cacheEntry(front, generation, species)
    local width = math.max(1, math.floor(tonumber(front.width) or 1))
    local height = math.max(1, math.floor(tonumber(front.height) or 1))
    local columns = math.max(1, math.floor(tonumber(front.columns) or 1))
    local frames = math.max(1, math.floor(tonumber(front.frames) or 1))
    local key = table.concat({ generation, species, tostring(front.image or ""),
      tostring(width), tostring(height), tostring(columns), tostring(frames) }, ":")
    local hit = renderCache[key]
    if hit == false then return nil end
    if hit then return hit end
    local atlas = atlasImage(front.image)
    if not atlas or not love.graphics or not love.graphics.newCanvas
        or not love.graphics.newQuad then return nil end

    -- Validate every imported atlas, regardless of selected generation or
    -- color variant, before creating quads. Gen 2/3/5 alternate-color atlases
    -- are not guaranteed to share the normal sprite's frame grid. If metadata
    -- and PNG dimensions disagree, fail closed and let the caller fall back to
    -- the normal animated sprite (or the stock Gen1 title sprite) instead of
    -- displaying a quartered/cropped frame.
    local iw, ih = atlas:getDimensions()
    local expectedW = columns * width
    local expectedH = math.ceil(frames / columns) * height
    if iw ~= expectedW or ih ~= expectedH then
      renderCache[key] = false
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("ignoring incompatible animated atlas %s (%dx%d; expected %dx%d)",
          tostring(front.image), iw, ih, expectedW, expectedH)
      end
      return nil
    end

    local okCanvas, canvas = pcall(love.graphics.newCanvas, width, height)
    if not okCanvas or not canvas then return nil end
    if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
    hit = {
      atlas = atlas, canvas = canvas, width = width, height = height,
      columns = columns, imageWidth = iw, imageHeight = ih,
      quads = {}, stableFrames = {}, lastFrame = 0,
    }
    renderCache[key] = hit
    return hit
  end

  local function quadFor(entry, frame)
    local q = entry.quads[frame]
    if q then return q end
    local index = frame - 1
    local col = index % entry.columns
    local row = math.floor(index / entry.columns)
    local ok, quad = pcall(love.graphics.newQuad,
      col * entry.width, row * entry.height,
      entry.width, entry.height, entry.imageWidth, entry.imageHeight)
    if not ok then return nil end
    entry.quads[frame] = quad
    return quad
  end

  local function renderFrame(front, generation, species, forcedFrame)
    local entry = cacheEntry(front, generation, species)
    if not entry then return nil end
    local frame = tonumber(forcedFrame) or currentFrame(front)
    local frameCount = math.max(1, math.floor(tonumber(front.frames) or 1))
    frame = math.max(1, math.min(math.floor(frame), frameCount))
    if entry.lastFrame == frame then return entry.canvas end
    local quad = quadFor(entry, frame)
    if not quad then return nil end

    local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(entry.canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader()
    love.graphics.draw(entry.atlas, quad, 0, 0)
    if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
    love.graphics.pop()
    entry.lastFrame = frame
    return entry.canvas
  end

  -- Render a frame into a frame-specific Canvas. Unlike renderFrame(), this
  -- object never changes after creation. Third-party UI overhauls commonly
  -- cache resolved images and/or preprocess alpha bounds by image identity; a
  -- stable object per animation frame lets those caches coexist with animation
  -- instead of freezing on the first frame or reusing stale prepared pixels.
  local function renderStableFrame(front, generation, species, forcedFrame)
    local entry = cacheEntry(front, generation, species)
    if not entry then return nil end
    local frame = tonumber(forcedFrame) or currentFrame(front)
    local frameCount = math.max(1, math.floor(tonumber(front.frames) or 1))
    frame = math.max(1, math.min(math.floor(frame), frameCount))
    local cached = entry.stableFrames and entry.stableFrames[frame]
    if cached then return cached end
    local quad = quadFor(entry, frame)
    if not quad then return nil end
    local okCanvas, canvas = pcall(love.graphics.newCanvas, entry.width, entry.height)
    if not okCanvas or not canvas then return nil end
    if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
    local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader()
    love.graphics.draw(entry.atlas, quad, 0, 0)
    if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
    love.graphics.pop()
    entry.stableFrames = entry.stableFrames or {}
    entry.stableFrames[frame] = canvas
    return canvas
  end

  -- Non-Gen5 sprite sets use very different authored frame canvases (Gen2 is
  -- fixed 56x56, Gen4 is usually 80x80+, while Gen5 is tightly cropped). Map
  -- the selected generation's UNION visible bounds into the matching Gen5
  -- normal visual envelope. The union is fixed across every animation frame,
  -- so native bobbing/wing/tail motion is preserved without per-frame jitter.
  --
  -- Gen5 itself remains byte-for-byte on the long-tested raw path.
  local presentationRenderCache = {}
  local presentationStableCache = {}
  local function renderPresentationFrame(front, generation, species, forcedFrame,
      side, variant, stable)
    if generation == "gen5" then
      if stable then return renderStableFrame(front, generation, species, forcedFrame) end
      return renderFrame(front, generation, species, forcedFrame)
    end
    side = side or "front"
    variant = variant or "normal"
    local src = visualBoundsFor(generation, variant, side, species)
      or visualBoundsFor(generation, "normal", side, species)
    local ref = visualBoundsFor("gen5", "normal", side, species)
    local refRecord = gen5ReferenceRecord(species, side)
    if not (src and ref and type(refRecord) == "table") then
      if stable then return renderStableFrame(front, generation, species, forcedFrame) end
      return renderFrame(front, generation, species, forcedFrame)
    end

    local entry = cacheEntry(front, generation, species)
    if not entry then return nil end
    local frame = tonumber(forcedFrame) or currentFrame(front)
    local frameCount = math.max(1, math.floor(tonumber(front.frames) or 1))
    frame = math.max(1, math.min(math.floor(frame), frameCount))

    local outW = math.max(1, math.floor(tonumber(refRecord.width) or 1))
    local outH = math.max(1, math.floor(tonumber(refRecord.height) or 1))
    local key = table.concat({ generation, variant, side, species,
      tostring(outW), tostring(outH),
      tostring(src.x), tostring(src.y), tostring(src.w), tostring(src.h),
      tostring(ref.x), tostring(ref.y), tostring(ref.w), tostring(ref.h) }, ":")

    local slot
    if stable then
      presentationStableCache[key] = presentationStableCache[key] or {}
      slot = presentationStableCache[key][frame]
      if slot then return slot.canvas end
    else
      slot = presentationRenderCache[key]
      if slot and slot.lastFrame == frame then return slot.canvas end
    end

    if not slot then
      local okCanvas, canvas = pcall(love.graphics.newCanvas, outW, outH)
      if not okCanvas or not canvas then return nil end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
      slot = { canvas=canvas, lastFrame=0 }
      if stable then presentationStableCache[key][frame] = slot
      else presentationRenderCache[key] = slot end
    end

    local index = frame - 1
    local col = index % entry.columns
    local row = math.floor(index / entry.columns)
    local okQuad, quad = pcall(love.graphics.newQuad,
      col * entry.width + src.x, row * entry.height + src.y,
      src.w, src.h, entry.imageWidth, entry.imageHeight)
    if not okQuad or not quad then return nil end

    local scale = math.min(ref.w / math.max(1, src.w), ref.h / math.max(1, src.h))
    local dw, dh = src.w * scale, src.h * scale
    local dx = ref.x + (ref.w - dw) * 0.5
    local dy = ref.y + ref.h - dh

    local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(slot.canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    if entry.atlas.setFilter then pcall(entry.atlas.setFilter, entry.atlas, "nearest", "nearest") end
    love.graphics.draw(entry.atlas, quad, dx, dy, 0, scale, scale)
    if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
    love.graphics.pop()
    slot.lastFrame = frame
    return slot.canvas
  end

  local function getSprite(species, opts)
    if not mod.options:get("enabled") then return nil end
    local generation = opts and opts.generation or selectedGeneration()
    local mon = opts and opts.mon
    if isBattleShiny(mon) then
      local shiny, actualGeneration, normalized = localShinyFrontRecord(species, generation)
      if shiny then
        return renderPresentationFrame(shiny, actualGeneration, normalized,
          nil, "front", "shiny", false)
      end
    end
    local front, actualGeneration, normalized = localFrontRecord(species, generation)
    if not front then return nil end
    return renderPresentationFrame(front, actualGeneration, normalized,
      nil, "front", "normal", false)
  end

  -- Title-only alternate-color lookup. Battle Art ships separate shiny
  -- metadata because a shiny atlas is not guaranteed to use the same frame
  -- dimensions, columns, or frame count as the normal animation. Prefer that
  -- metadata whenever it was imported. For older local imports that contain
  -- only shiny PNGs, use the normal record only when the atlas dimensions
  -- exactly match the normal record's expected grid; otherwise fall back to
  -- the normal animated sprite instead of slicing the shiny image incorrectly.
  local shinyFrontCache = {}
  local function getTitleShinySprite(species, generation)
    if not mod.options:get("enabled") then return nil end
    generation = generation or selectedGeneration()

    local shinyFront, actualGeneration, normalized = localShinyFrontRecord(species, generation)
    if shinyFront then
      return renderPresentationFrame(shinyFront, actualGeneration, normalized,
        nil, "front", "shiny", false)
    end

    local front
    front, actualGeneration, normalized = localFrontRecord(species, generation)
    if not front or type(front.image) ~= "string" then return nil end

    local cacheKey = table.concat({ actualGeneration, normalized }, ":")
    local cached = shinyFrontCache[cacheKey]
    if cached == false then return nil end
    if not cached then
      local shinyPath, substitutions = front.image:gsub("/([^/]+)$", "/shiny/%1", 1)
      if substitutions ~= 1 or shinyPath == front.image then
        shinyFrontCache[cacheKey] = false
        return nil
      end
      local atlas = atlasImage(shinyPath)
      if not atlas then
        shinyFrontCache[cacheKey] = false
        return nil
      end

      local width = math.max(1, math.floor(tonumber(front.width) or 1))
      local height = math.max(1, math.floor(tonumber(front.height) or 1))
      local columns = math.max(1, math.floor(tonumber(front.columns) or 1))
      local frames = math.max(1, math.floor(tonumber(front.frames) or 1))
      local expectedW = columns * width
      local expectedH = math.ceil(frames / columns) * height
      local iw, ih = atlas:getDimensions()
      if iw ~= expectedW or ih ~= expectedH then
        shinyFrontCache[cacheKey] = false
        return nil
      end

      cached = {}
      for k, v in pairs(front) do cached[k] = v end
      cached.image = shinyPath
      shinyFrontCache[cacheKey] = cached
    end
    return renderPresentationFrame(cached, actualGeneration, normalized,
      nil, "front", "shiny", false)
  end

  local function getFrontRecord(species, generation)
    generation = generation or selectedGeneration()
    local front = localFrontRecord(species, generation)
    if not front then return nil end
    local width, height = presentationSize(generation, species, "front", front)
    return {
      width = width, height = height, columns = front.columns,
      frames = front.frames, durations = front.durations,
    }
  end

  -- Public export consumed by compatible UI mods such as Gen1 Modern UI.
  -- Kanto in Motion is the provider here; it does not depend on another mod.
  -- Preserve the early compatibility registration exports while adding the
  -- long-standing animated-sprite provider API.
  mod.exports.apiVersion = 1
  mod.exports.generations = { "gen2", "gen3", "gen4", "gen5" }
  mod.exports.defaultGeneration = "gen5"
  mod.exports.getGeneration = selectedGeneration
  mod.exports.getSourcePreference = function() return "local" end
  mod.exports.getActiveSource = function(species, generation)
    return localHasSprite(species, generation or selectedGeneration()) and "local" or "vanilla"
  end
  mod.exports.hasSprite = function(species, generation)
    return localHasSprite(species, generation or selectedGeneration())
  end
  mod.exports.getSprite = getSprite
  mod.exports.getFrontRecord = getFrontRecord

  -- The stock Gen 1 Summary and Pokedex layouts reserve roughly a 7x7-tile
  -- portrait box. Imported Gen 2-5 animation frames are tightly cropped and
  -- some (Charizard is a common example) are substantially larger than that.
  -- Downscale only frames that exceed the native box; smaller sprites retain
  -- their authored pixel size. The scratch Canvas is redrawn every call so a
  -- live animated source Canvas stays animated instead of freezing.
  local stockPortraitCache = setmetatable({}, { __mode = "k" })
  local function fitStockPortrait(image, maxW, maxH)
    if not image or type(image.getDimensions) ~= "function" then return image end
    maxW, maxH = tonumber(maxW) or 56, tonumber(maxH) or 56
    local w, h = image:getDimensions()
    if not w or not h or w <= 0 or h <= 0 then return image end
    if w <= maxW and h <= maxH then return image end
    if not (love.graphics and love.graphics.newCanvas) then return image end

    local slot = stockPortraitCache[image]
    if not slot or slot.w ~= maxW or slot.h ~= maxH then
      local okCanvas, canvas = pcall(love.graphics.newCanvas, maxW, maxH)
      if not okCanvas or not canvas then return image end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
      slot = { canvas = canvas, w = maxW, h = maxH }
      stockPortraitCache[image] = slot
    end

    local scale = math.min(maxW / w, maxH / h, 1)
    local dw, dh = w * scale, h * scale
    local dx, dy = (maxW - dw) * 0.5, maxH - dh
    local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(slot.canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
    love.graphics.draw(image, dx, dy, 0, scale, scale)
    if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
    love.graphics.pop()
    return slot.canvas
  end

  -- Battle Lite live sprite bridge. The path is constant for a species/side,
  -- while the cached drawable is a mutable Canvas whose pixels are refreshed
  -- from the selected animation frame. Gen 2's BattleState loads through
  -- Assets.image(), so it can cache this Canvas directly. Gen 1 loads battle
  -- art through ImageData and would freeze it; the narrow drawPicsLayer wrapper
  -- below swaps the Canvas in only for the source draw and restores the native
  -- battler immediately afterward.
  local BATTLE_BRIDGE_PREFIX = "__kanto_in_motion_battle__/"
  local battleProxyCache = {}

  local function battleSystemEnabled()
    return not IS_GEN2 and mod.options:get("battleSystem") ~= false
  end

  local function battleArtInstalled()
    if type(mod.find) ~= "function" then return false end
    local ok, handle = pcall(mod.find, "BATTLE_ART_VOXEL_FORK")
    return ok and handle ~= nil
  end

  -- Battle Lite yields its scene/sprite/HUD ownership whenever a cooperating
  -- external battle mod registers as a scene owner. Battle Art remains a
  -- built-in compatibility fallback for existing releases that predate this
  -- open registration API.
  local function externalBattleSceneOwnerRegistered()
    return battleArtInstalled()
      or (mod._kantoInMotionInterop
        and mod._kantoInMotionInterop:hasBattleSceneOwner())
  end

  local function externalBattleSpritesBlocked()
    return battleArtInstalled()
      or (mod._kantoInMotionInterop
        and mod._kantoInMotionInterop:blocksBattleFeature("sprites"))
  end

  -- Player battle-trainer selector. The setting chooses WHO the trainer is;
  -- the existing global ANIMATION toggle chooses whether a five-pose intro
  -- atlas plays. This keeps the trainer choice stable when animation is
  -- disabled instead of exposing separate static/animated trainer menus.
  -- Scene-owning battle mods still keep their own trainer renderer.
  local BATTLE_TRAINERS = {
    png={static="player.png"},
    gen1={animated="gen1player.png"}, gen2={animated="gen2player.png"},
    gen3={animated="gen3player.png"}, gen4={animated="gen4player.png"},
    gen5={animated="gen5player.png"}, ash={animated="ashplayer.png"},
    gary={animated="garyplayer.png"}, red={animated="redplayer.png"},
    ash_front={animated="ashfrontplayer.png"},
    misty_front={animated="mistyfrontplayer.png"},
    brock_front={animated="brockfrontplayer.png"},
    bulma_front={animated="bulmafrontplayer.png"},
    gary_front={animated="garyfrontplayer.png"},
    boy={static="boyplayer.png"}, lass={static="lassplayer.png"},
    hilbert={static="hilbertplayer.png"},
  }
  local function battleTrainerStaticPath(choice)
    local def=BATTLE_TRAINERS[choice]
    if not def or not (mod.assets and type(mod.assets.path)=="function") then return nil end
    if def.animated then
      return mod.assets:path("assets/battle/player-trainers-frames/"..def.animated)
    end
    return def.static and mod.assets:path("assets/battle/player-trainers/"..def.static) or nil
  end
  local function battleTrainerAnimatedPath(choice)
    local def=BATTLE_TRAINERS[choice]
    if not (def and def.animated and mod.assets and type(mod.assets.path)=="function") then return nil end
    return mod.assets:path("assets/battle/player-trainers-animated/"..def.animated)
  end

  -- Runtime-decoded trainer frames. Battle Art's authored player atlases are
  -- five equal horizontal cells (currently 5x80). Decode once per selected
  -- trainer and keep native pixels / nearest filtering.
  local battleTrainerFrameCache={}
  local function battleTrainerFrames(choice)
    local hit=battleTrainerFrameCache[choice]
    if hit~=nil then return hit or nil end
    local path=battleTrainerAnimatedPath(choice)
    if not path or not (love.image and love.image.newImageData
        and love.graphics and love.graphics.newImage) then
      battleTrainerFrameCache[choice]=false
      return nil
    end
    local frames
    local ok=pcall(function()
      local sheet=love.image.newImageData(path)
      if not sheet then return end
      local sw,sh=sheet:getDimensions()
      if sw<5 or sh<1 or sw%5~=0 then return end
      local fw=math.floor(sw/5)
      local made={}
      for i=0,4 do
        local cell=love.image.newImageData(fw,sh)
        cell:paste(sheet,0,0,i*fw,0,fw,sh)
        local img=love.graphics.newImage(cell)
        if img and type(img.setFilter)=="function" then img:setFilter("nearest","nearest") end
        made[#made+1]=img
      end
      if #made==5 then frames=made end
    end)
    battleTrainerFrameCache[choice]=(ok and frames) or false
    return (ok and frames) or nil
  end
  local function battleTrainerFrameForBattle(battle,choice)
    local frames=battleTrainerFrames(choice)
    if not frames then return nil end
    if mod.options:get("animate")==false then return frames[1] end
    local offset=0
    if battle and type(battle.picOffset)=="function" then
      local ok,got=pcall(battle.picOffset,battle,"back")
      if ok then offset=tonumber(got) or 0 end
    end
    local progress=math.max(0,math.min(72,-offset))
    if progress<=0 then return frames[1] end
    local moving=math.max(1,#frames-1)
    local index=math.min(#frames,2+math.floor(math.max(0,progress-1)*moving/72))
    return frames[index]
  end

  if mod.content and mod.content.battle_sprite_scales
      and type(mod.content.battle_sprite_scales.register)=="function" then
    for key in pairs(BATTLE_TRAINERS) do
      local path=battleTrainerStaticPath(key)
      if path then
        pcall(mod.content.battle_sprite_scales.register,
          mod.content.battle_sprite_scales,"kim_player_trainer_"..key,
          {path=path,scale=1})
      end
    end
  end
  if mod.hooks and type(mod.hooks.wrap)=="function" and not IS_GEN2 then
    mod.hooks:wrap("player.sprite",function(nextFn,path,ctx)
      local resolved=nextFn(path,ctx)
      if not (battleSystemEnabled() and not externalBattleSceneOwnerRegistered()) then
        return resolved
      end
      if type(ctx)~="table" or ctx.kind~="battle" or ctx.side~="back"
          or ctx.demo or ctx.oakDemo then return resolved end
      local choice=mod.options:get("battleTrainerSprite") or "rom"
      if choice=="rom" then return resolved end
      local custom=battleTrainerStaticPath(choice)
      if not custom then return resolved end
      ctx.trueColor=true
      return custom
    end,9000)
  end

  local function battleLiteOwnsSprites()
    return battleSystemEnabled() and mod.options:get("battleSprites") ~= false
      and not externalBattleSpritesBlocked()
  end

  -- Full-screen Battle Lite is composited at final window resolution. The
  -- engine's WIDE mode remains untouched because WIDE is still only a 304x144
  -- battle surface; forcing it was the reason v2 left a small arena in the
  -- middle of a 1920x1080 window.
  local function battleLiteFullScreenActive()
    if not (battleSystemEnabled() and not externalBattleSceneOwnerRegistered()) then return false end
    local fill = mod.options:get("battleArenaFill")
    return fill == "gen6" or fill == "white" or fill == "krs"
  end

  local function battleLiteHudActive()
    return battleSystemEnabled() and not externalBattleSceneOwnerRegistered()
  end

  local function battleBridgePath(species, side, mon)
    if not battleLiteOwnsSprites() then return nil end
    local record, generation, normalized, shiny = battleRecord(species, side, mon)
    if not record then return nil end
    return BATTLE_BRIDGE_PREFIX .. generation .. "/" .. side .. "/"
      .. (shiny and "shiny" or "normal") .. "/" .. normalized .. ".png"
  end

  local function decodeBattleBridgePath(path)
    if type(path) ~= "string" or path:sub(1, #BATTLE_BRIDGE_PREFIX) ~= BATTLE_BRIDGE_PREFIX then
      return nil
    end
    local tail = path:sub(#BATTLE_BRIDGE_PREFIX + 1)
    local generation, side, variant, species = tail:match(
      "^(gen[2-5])/(front|back)/([a-z]+)/([A-Z0-9_]+)%.png$")
    if not generation or (variant ~= "normal" and variant ~= "shiny") then return nil end
    local record
    if side == "back" then
      if variant == "shiny" then record = localShinyBackRecord(species, generation)
      else record = localBackRecord(species, generation) end
    else
      if variant == "shiny" then record = localShinyFrontRecord(species, generation)
      else record = localFrontRecord(species, generation) end
    end
    if not record then return nil end
    return record, generation, side, variant, species
  end

  local function drawBattleProxy(proxy)
    local record = proxy.record
    if not record then return nil end
    local source = renderPresentationFrame(record, proxy.generation, proxy.species,
      nil, proxy.side, proxy.variant or "normal", false)
    if not source then return nil end
    local sw, sh = source:getDimensions()
    -- Imported Battle Art frames are already display art. Fit them into the
    -- selected player slot and allow clean nearest-neighbour enlargement when
    -- PLAYER PKMN SIZE is above 100%; the engine's battle placement helpers
    -- keep the resulting image bottom-centred on the authored player anchor.
    local scale = math.min(proxy.width / math.max(1, sw),
      proxy.height / math.max(1, sh))
    local dw, dh = sw * scale, sh * scale
    local dx, dy = (proxy.width - dw) * 0.5, proxy.height - dh
    local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(proxy.canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(source, dx, dy, 0, scale, scale)
    if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
    love.graphics.pop()
    return proxy.canvas
  end

  local function battleProxy(record, generation, side, variant, species)
    if not (record and love.graphics and love.graphics.newCanvas) then return nil end
    -- Keep the replacement drawable at one stable authored slot size. The
    -- engine's resolveBattleScale seam below owns PLAYER PKMN SIZE directly;
    -- changing the Canvas dimensions here lets the engine's own placement
    -- compensation cancel part of the requested scale on some battle paths.
    local key = table.concat({ generation, side, variant or "normal", species }, ":")
    local proxy = battleProxyCache[key]
    local width = side == "back" and 48 or 56
    local height = side == "back" and 48 or 56
    if not proxy then
      local ok, canvas = pcall(love.graphics.newCanvas, width, height)
      if not ok or not canvas then return nil end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
      proxy = { canvas=canvas, width=width, height=height, record=record,
        generation=generation, side=side, variant=variant, species=species }
      battleProxyCache[key] = proxy
    else
      proxy.record = record
    end
    return drawBattleProxy(proxy)
  end

  local function resolveBattleBridge(path, mode)
    local record, generation, side, variant, species = decodeBattleBridgePath(path)
    if not record then return nil end
    if mode == "exists" then return true end
    local image = battleProxy(record, generation, side, variant, species)
    if not image then return nil end
    if mode == true then
      if type(image.newImageData) == "function" then
        local ok, data = pcall(image.newImageData, image)
        if ok then return data end
      end
      return nil
    end
    return image
  end

  -- Standard resolved-sprite bridge for stock and third-party UI overhauls.
  -- Some complete UI replacements do not consume mod.exports directly; they
  -- correctly ask Gen1Recomp's pokemon.sprite seam for the selected front art
  -- and then load that path through src.render.Assets. Return a private virtual
  -- frame path for non-battle presentation surfaces and teach Assets how to
  -- resolve that path to Kanto in Motion's live frame Canvas. This keeps the
  -- animation provider independent from the bundled Modern UI without taking
  -- ownership of battle sprites, camera, or attack presentation.
  local FRAME_BRIDGE_PREFIX = "__kanto_in_motion_frame__/"
  local FRAME_BRIDGE_KINDS = {
    summary = true, status = true, party = true, pc = true,
    dex = true, pokedex = true, evolution = true, starter = true,
    hof = true, trade = true, flow = true, photo = true,
    unown = true, contest = true,
  }

  local function bridgeFront(species, generation, mon)
    generation = generation or selectedGeneration()
    if isBattleShiny(mon) then
      local shiny, actualGeneration, normalized = localShinyFrontRecord(species, generation)
      if shiny then return shiny, actualGeneration, normalized, true end
    end
    local front, actualGeneration, normalized = localFrontRecord(species, generation)
    if front then return front, actualGeneration, normalized, false end
    return nil
  end

  local function bridgePath(species, generation, mon)
    local front, actualGeneration, normalized, shiny = bridgeFront(species, generation, mon)
    if not front then return nil end
    local frame = currentFrame(front)
    return FRAME_BRIDGE_PREFIX .. actualGeneration .. "/"
      .. (shiny and "shiny" or "normal") .. "/" .. normalized .. "/"
      .. tostring(frame) .. ".png"
  end

  local function decodeBridgePath(path)
    if type(path) ~= "string" or path:sub(1, #FRAME_BRIDGE_PREFIX) ~= FRAME_BRIDGE_PREFIX then
      return nil
    end
    local tail = path:sub(#FRAME_BRIDGE_PREFIX + 1)
    local generation, variant, species, frame = tail:match("^(gen[2-5])/([a-z]+)/([A-Z0-9_]+)/(%d+)%.png$")
    if not generation or (variant ~= "normal" and variant ~= "shiny") then return nil end
    local front
    if variant == "shiny" then
      front = localShinyFrontRecord(species, generation)
    else
      front = localFrontRecord(species, generation)
    end
    if not front then return nil end
    return front, generation, species, tonumber(frame), variant
  end


  -- Forward declaration: the stock Clean UI bridge below calls this
  -- before its implementation appears later in the file. Without this local
  -- declaration Lua resolves those calls as a global and the pcall-wrapped
  -- bridge install silently fails.
  local gen2CleanUiHandle

  -- Stock Gen2 Clean UI 0.4.1 compatibility without modifying that mod.
  --
  -- Clean UI intentionally accepts only assets/generated/*.png portrait paths
  -- and caches the loaded drawable by path.  Kanto in Motion therefore gives
  -- the live Gen2 Pokemon definitions a TEMPORARY generated-looking path only
  -- while Clean UI prepares its frame. A very narrow love.graphics.newImage
  -- bridge resolves only our reserved path prefix to a mutable Canvas. Clean
  -- UI caches that Canvas normally; Kanto in Motion updates its pixels each
  -- frame as the selected animation advances. The original Pokemon definitions
  -- are restored immediately after Clean UI finishes preparing, so battles,
  -- scripts and other UI mods never inherit the temporary path.
  local CLEAN_UI_LIVE_PREFIX = "assets/generated/kanto_in_motion_live/"
  local cleanUiProxies = {}
  local cleanUiVariantBySpecies = {}

  local function cleanUiLivePath(species, generation)
    species = normalizedSpecies(species)
    generation = generation or selectedGeneration()
    if not species or not localFrontRecord(species, generation) then return nil end
    return CLEAN_UI_LIVE_PREFIX .. generation .. "/" .. species .. ".png"
  end

  local function decodeCleanUiLivePath(path)
    if type(path) ~= "string" then return nil end

    -- Stock Gen2 Clean UI does not pass the generated descriptor path straight
    -- to love.graphics.newImage(). Its mod.assets:image() first expands that
    -- descriptor underneath Clean UI's own mod directory, so on Windows the
    -- renderer reaches us with something like:
    --
    --   .../gen2_clean_ui/assets/generated/kanto_in_motion_live/gen5/PIKACHU.png
    --
    -- The modified Clean UI test build intercepted the descriptor *before*
    -- that expansion, which is why animation worked there while stock Clean
    -- UI remained static. Match our reserved namespace anywhere in the final
    -- normalized path rather than requiring it at character one.
    local normalized = path:gsub("\\", "/")
    local at = normalized:find(CLEAN_UI_LIVE_PREFIX, 1, true)
    if not at then return nil end
    local tail = normalized:sub(at + #CLEAN_UI_LIVE_PREFIX)
    local generation, species = tail:match("^(gen[2-5])/([A-Z0-9_]+)%.png$")
    if not generation or not species then return nil end
    local normal = localFrontRecord(species, generation)
    if not normal then return nil end
    return generation, species
  end

  local function frontForCleanUi(generation, species)
    local wantShiny = cleanUiVariantBySpecies[species] == true
    if wantShiny then
      local shiny = localShinyFrontRecord(species, generation)
      if shiny then return shiny, true end
    end
    local front = localFrontRecord(species, generation)
    return front, false
  end

  local function proxySize(generation, species)
    local normal = localFrontRecord(species, generation)
    return presentationSize(generation, species, "front", normal)
  end

  local function drawCleanUiProxy(proxy)
    if not (proxy and love.graphics and love.graphics.setCanvas) then return nil end
    local front, shiny = frontForCleanUi(proxy.generation, proxy.species)
    if type(front) ~= "table" then return proxy.canvas end
    local source = renderPresentationFrame(front, proxy.generation, proxy.species,
      nil, "front", shiny and "shiny" or "normal", false)
    if not source then return proxy.canvas end
    local sw, sh = source:getDimensions()
    local dx = math.floor((proxy.width - sw) / 2)
    local dy = proxy.height - sh
    local previous = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(proxy.canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(source, dx, dy)
    if previous then love.graphics.setCanvas(previous) else love.graphics.setCanvas() end
    love.graphics.pop()
    return proxy.canvas
  end

  local function cleanUiProxy(path)
    local generation, species = decodeCleanUiLivePath(path)
    if not generation then return nil end
    local hit = cleanUiProxies[path]
    if not hit then
      if not (love.graphics and love.graphics.newCanvas) then return nil end
      local w, h = proxySize(generation, species)
      local ok, canvas = pcall(love.graphics.newCanvas, w, h)
      if not ok or not canvas then return nil end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
      hit = { canvas=canvas, width=w, height=h,
        generation=generation, species=species }
      cleanUiProxies[path] = hit
      if mod.log and type(mod.log.info) == "function"
          and not mod._kantoInMotionCleanUiProxyConfirmed then
        mod._kantoInMotionCleanUiProxyConfirmed = true
        mod.log:info("stock Gen2 Clean UI requested Kanto in Motion live portrait; animation proxy active")
      end
    end
    return drawCleanUiProxy(hit)
  end

  local function refreshCleanUiProxies()
    for _, proxy in pairs(cleanUiProxies) do drawCleanUiProxy(proxy) end
  end

  local function markVisibleShiny(game)
    cleanUiVariantBySpecies = {}
    local stack = game and game.stack
    local top = stack and type(stack.top) == "function" and stack:top() or nil
    if type(top) ~= "table" then return end
    local function mark(mon)
      if type(mon) == "table" and mon.species then
        cleanUiVariantBySpecies[normalizedSpecies(mon.species)] = isBattleShiny(mon)
      end
    end
    mark(rawget(top, "mon"))
    local party = rawget(top, "party")
    local index = tonumber(rawget(top, "index"))
    if type(party) == "table" and index then mark(rawget(party, index)) end
  end

  local function installStockGen2CleanUiBridge()
    if not IS_GEN2 or not gen2CleanUiHandle()
        or not (love and love.graphics and type(love.graphics.newImage) == "function") then
      return false
    end

    -- The graphics table itself is engine-owned and shared. Keep exactly one
    -- narrow wrapper across hot reloads; only its resolver closure is replaced.
    local g = love.graphics
    local bridge = rawget(g, "__kantoInMotionCleanUiImageBridge")
    if type(bridge) ~= "table" then
      bridge = { original = g.newImage }
      rawset(g, "__kantoInMotionCleanUiImageBridge", bridge)
      g.newImage = function(path, ...)
        local resolver = bridge.resolver
        if resolver then
          local ok, image = pcall(resolver, path)
          if ok and image then return image end
        end
        return bridge.original(path, ...)
      end
    end
    bridge.resolver = cleanUiProxy

    local function withCleanUiPokemonDefinitions(game, nextFn, ...)
      if mod.options:get("enabled") == false or not gen2CleanUiHandle() then
        return nextFn(...)
      end

      markVisibleShiny(game)
      refreshCleanUiProxies()

      local generation = selectedGeneration()
      local pokemon = game and game.data and game.data.pokemon
      if type(pokemon) ~= "table" then return nextFn(...) end

      local restore = {}
      for species, def in pairs(pokemon) do
        if type(def) == "table" then
          local path = cleanUiLivePath(species, generation)
          if path then
            restore[#restore + 1] = {
              def=def, spriteFront=rawget(def, "spriteFront"),
              trueColor=rawget(def, "trueColor"),
            }
            rawset(def, "spriteFront", path)
            rawset(def, "trueColor", true)
          end
        end
      end

      if #restore > 0 and mod.log and type(mod.log.info) == "function"
          and not mod._kantoInMotionCleanUiDefinitionsConfirmed then
        mod._kantoInMotionCleanUiDefinitionsConfirmed = true
        mod.log:info("stock Gen2 Clean UI prepare sees Kanto in Motion animated sprite descriptors")
      end

      local result = { pcall(nextFn, ...) }
      for i = #restore, 1, -1 do
        local row = restore[i]
        rawset(row.def, "spriteFront", row.spriteFront)
        rawset(row.def, "trueColor", row.trueColor)
      end
      local ok = table.remove(result, 1)
      if not ok then error(result[1], 0) end
      return unpack(result)
    end

    if mod.hooks and type(mod.hooks.wrap) == "function" then
      -- Newer/Gen1-style hosts prepare here.
      if not mod._kantoInMotionCleanUiPrepareHook then
        mod._kantoInMotionCleanUiPrepareHook = mod.hooks:wrap(
          "render.ui.prepare",
          function(nextFn, game, viewport)
            return withCleanUiPokemonDefinitions(game, nextFn, game, viewport)
          end, 95000)
      end

      -- Gen1Recomp 0.2.24's Gen2 Clean UI can prepare from its
      -- screen.render_visible fallback instead. KIM must be the outer wrapper
      -- (95000 > Clean UI's 90000) so the temporary definitions remain active
      -- while Clean UI snapshots and renders the model.
      if not mod._kantoInMotionCleanUiVisibleHook then
        mod._kantoInMotionCleanUiVisibleHook = mod.hooks:wrap(
          "screen.render_visible",
          function(nextFn, state)
            local game = type(state) == "table" and rawget(state, "game") or nil
            if not game then return nextFn(state) end
            return withCleanUiPokemonDefinitions(game, nextFn, state)
          end, 95000)
      end

      -- Clean UI intentionally caches source images by descriptor path. The
      -- cached object is our mutable Canvas, so refresh its pixels every frame
      -- immediately before Clean UI's lower-priority render.hud wrapper
      -- composites its already-built candidate.
      if not mod._kantoInMotionCleanUiHudHook then
        mod._kantoInMotionCleanUiHudHook = mod.hooks:wrap(
          "render.hud",
          function(nextFn, game, viewport)
            if mod.options:get("enabled") ~= false and gen2CleanUiHandle() then
              markVisibleShiny(game)
              refreshCleanUiProxies()
            end
            return nextFn(game, viewport)
          end, 95000)
      end
    end

    if mod.log and type(mod.log.info) == "function" then
      mod.log:info("stock Gen2 Clean UI animated portrait bridge enabled")
    end
    return true
  end

  local okAssets, Assets = pcall(require, "src.render.Assets")
  if okAssets and type(Assets) == "table" then
    -- Keep one engine-level wrapper across dev hot reloads; only the resolver
    -- closure is refreshed so stale Kanto in Motion state cannot accumulate.
    if not Assets.__kantoInMotionFrameBridge then
      Assets.__kantoInMotionFrameBridge = {
        image = Assets.image, imageData = Assets.imageData, exists = Assets.exists,
      }
      Assets.image = function(path)
        local resolver = Assets.__kantoInMotionFrameResolver
        if resolver then
          local image = resolver(path, false)
          if image then return image end
        end
        return Assets.__kantoInMotionFrameBridge.image(path)
      end
      Assets.imageData = function(path)
        local resolver = Assets.__kantoInMotionFrameResolver
        if resolver then
          local image = resolver(path, true)
          if image then return image end
        end
        return Assets.__kantoInMotionFrameBridge.imageData(path)
      end
      Assets.exists = function(path)
        local resolver = Assets.__kantoInMotionFrameResolver
        if resolver and resolver(path, "exists") then return true end
        return Assets.__kantoInMotionFrameBridge.exists(path)
      end
    end

    Assets.__kantoInMotionFrameResolver = function(path, mode)
      local battleImage = resolveBattleBridge(path, mode)
      if battleImage then return battleImage end
      local front, generation, species, frame, variant = decodeBridgePath(path)
      if not front then return nil end
      if mode == "exists" then return true end
      local image = renderPresentationFrame(front, generation, species, frame,
        "front", variant or "normal", true)
      if not image then return nil end
      if mode == true then
        if type(image.newImageData) == "function" then
          local ok, data = pcall(image.newImageData, image)
          if ok then return data end
        end
        return nil
      end
      return image
    end
  end

  local STOCK_DIRECT_IMAGE_KINDS = {
    summary = true, status = true, dex = true, pokedex = true,
  }

  gen2CleanUiHandle = function()
    if not IS_GEN2 or type(mod.find) ~= "function" then return nil end
    local ok, handle = pcall(mod.find, "gen2_clean_ui")
    if ok and type(handle) == "table" then return handle end
    return nil
  end

  local function knownExternalUiPresent()
    if gen2CleanUiHandle() then return true end
    if mod._kantoInMotionInterop
        and mod._kantoInMotionInterop:hasPokemonSpriteBridgeUi() then
      return true
    end
    if type(mod.find) ~= "function" then return false end
    for _, id in ipairs({ "gen3_battle_ui", "colosseum_ui_overhaul" }) do
      local ok, handle = pcall(mod.find, id)
      if ok and handle then return true end
    end
    return false
  end

  if mod.hooks and type(mod.hooks.wrap) == "function" then
    mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
      local resolved = next(path, ctx)
      local kind = type(ctx) == "table" and tostring(ctx.kind or ""):lower() or ""
      if type(ctx) == "table" and kind == "battle"
          and (ctx.side == "front" or ctx.side == "back")
          and battleLiteOwnsSprites() then
        -- Gen2's battle UI resolves through Assets.image() and can hold our
        -- mutable Canvas. Gen1's ImageData path freezes the drawable, so the
        -- Gen1 source draw is swapped directly below instead.
        if IS_GEN2 then
          local virtual = battleBridgePath(ctx.species, ctx.side, ctx.mon)
          if virtual then
            ctx.trueColor = true
            return virtual
          end
        end
        return resolved
      end
      if mod.options:get("enabled") == false or type(ctx) ~= "table"
          or ctx.side ~= "front" or not FRAME_BRIDGE_KINDS[kind] then
        return resolved
      end

      -- Stock Gen1Recomp's SummaryMenu and DexEntryMenu call
      -- love.graphics.newImage() directly on the path returned by
      -- pokemon.sprite.  Kanto in Motion's virtual frame paths are resolved by
      -- src.render.Assets and therefore cannot be opened by newImage().  When
      -- the stock UI owns these screens, leave their constructor path vanilla;
      -- patchVanillaScreens() below injects the live animated Canvas at draw
      -- time.  Known external UI overhauls use Assets and keep the bridge.
      if STOCK_DIRECT_IMAGE_KINDS[kind] and not knownExternalUiPresent() then
        return resolved
      end

      local virtual = bridgePath(ctx.species, selectedGeneration(), ctx.mon)
      if not virtual then return resolved end
      ctx.trueColor = true
      return virtual
    end, 650)
  end

  -- -----------------------------------------------------------------------
  -- Battle Lite runtime
  -- -----------------------------------------------------------------------
  -- When the fullscreen Battle Lite path owns a Gen1 battle, remember the
  -- BattleState draw for the matching render.compose call. Battle Art 1.9.8
  -- removes the stock 160x144 paper before it is composited; this pending
  -- token lets Kanto in Motion do the same at the renderer's explicit UI
  -- canvas seam without guessing at final-window rectangles afterward.
  -- Battle Art-style flat battle host. The Gen 6 plate is installed as the
  -- renderer world layer while the engine's own 160x144 battle canvas remains
  -- a transparent overlay. Pokemon, move effects, send-out/faint motion and
  -- the native battle menu therefore keep their original draw order/anchors.
  local setFlatBattleWorld = nil
  local drawDirectBattleSprites = nil
  -- Battle Art-style source ownership token. BattleState:draw marks the live
  -- top-level fullscreen battle; render.compose then removes the finished
  -- native 160x144 UI surface before the engine can scale/letterbox it over
  -- KIM's arena. render.hud clears the token after rebuilding the transparent
  -- native overlay pieces that we still want.
  local pendingFullscreenBattle = nil
  local forcedBattleLayoutPrevious = nil
  local forcedBattleLayoutActive = false

  -- Battle Art stages against the original 160x144 layout, never WIDE. WIDE
  -- moves the Pokemon/menu anchors onto a 304x144 surface and is exactly what
  -- produced the small centered battle seen in the earlier tests. Keep the
  -- user's previous value in memory and restore it when Kanto in Motion no
  -- longer owns a battle instead of permanently rewriting their preference.
  local function forceBattleLayoutOG(game)
    if not game then
      local okGame, Game = pcall(require, "src.core.Game")
      if okGame then game = Game end
    end
    local opts = game and game.save and game.save.options
    if not opts then return false end
    if not forcedBattleLayoutActive then
      forcedBattleLayoutPrevious = opts.battleLayout
      forcedBattleLayoutActive = true
    end
    opts.battleLayout = "og"
    return true
  end

  local function restoreBattleLayout(game)
    if not forcedBattleLayoutActive then return end
    if not game then
      local okGame, Game = pcall(require, "src.core.Game")
      if okGame then game = Game end
    end
    local opts = game and game.save and game.save.options
    if opts then opts.battleLayout = forcedBattleLayoutPrevious end
    forcedBattleLayoutPrevious = nil
    forcedBattleLayoutActive = false
  end

  -- Battle Art 1.9.8 suppresses only the opaque full-frame white fill emitted
  -- by BattleState:draw. Text boxes, flashes, move effects and every other
  -- rectangle pass through unchanged. This is the critical seam that lets the
  -- world/background show through without throwing away the UI canvas itself.
  local function withoutBattleBackgroundFill(battle, fn, ...)
    local g = love.graphics
    local rectangle = g.rectangle
    local clear = g.clear
    -- The active Gen1 battle UI canvas is the one KIM wants to remain
    -- transparent over the fullscreen KRS arena. Some battle-animation paths
    -- clear that canvas back to Gen1's white paper instead of drawing a white
    -- rectangle. At 1920x1080 the 160x144 surface is scaled 7x, producing the
    -- 1120x1008 white block visible in the user's capture. Restrict the clear
    -- shim to this exact canvas so KRBA/temp canvases keep their own clears.
    local sourceCanvas = g.getCanvas and g.getCanvas() or nil
    local fill = mod.options:get("battleArenaFill")
    local fullscreenPaperless = fill == "krs" or fill == "gen6"
    local function isWhiteClear(r, gr, b, a)
      if type(r) == "table" then
        local t = r
        r, gr, b, a = t[1] or t.r, t[2] or t.g, t[3] or t.b, t[4] or t.a
      end
      r, gr, b = tonumber(r), tonumber(gr), tonumber(b)
      if not (r and gr and b) then return false end
      a = tonumber(a)
      if a == nil then a = 1 end
      return r > 0.95 and gr > 0.95 and b > 0.95 and a > 0.05
    end
    if fullscreenPaperless and type(clear) == "function" then
      g.clear = function(r, gr, b, a, ...)
        local target = g.getCanvas and g.getCanvas() or nil
        if target == sourceCanvas and isWhiteClear(r, gr, b, a) then
          return clear(0, 0, 0, 0)
        end
        return clear(r, gr, b, a, ...)
      end
    end
    g.rectangle = function(mode, x, y, w, h, ...)
      if mode == "fill" and x == 0 and y == 0 and w == 160 and h == 144 then
        local r, gr, b, a = g.getColor()
        local fullWhite = r > 0.95 and gr > 0.95 and b > 0.95 and a > 0.05
        if fullWhite then
          if a > 0.99 then
            -- Native battle paper: the fullscreen KIM arena already owns the
            -- background, so keep the source layer transparent as before.
            local target = g.getCanvas and g.getCanvas() or nil
            if target ~= nil then clear(0, 0, 0, 0) end
            return
          end
          if fullscreenPaperless then return end
        end
      end
      return rectangle(mode, x, y, w, h, ...)
    end
    local result = { pcall(fn, battle, ...) }
    g.rectangle = rectangle
    g.clear = clear
    local ok = table.remove(result, 1)
    if not ok then error(result[1], 0) end
    return unpack(result)
  end

  -- Gen1 animated sprites are substituted only during drawPicsLayer so battle
  -- state, Transform, faint/send-out state and third-party mechanics retain
  -- the exact native battler tables. Battle Art wins outright when installed.
  if not IS_GEN2 then
    local okOW, OverworldController = pcall(require, "src.world.OverworldController")
    if okOW and type(OverworldController) == "table"
        and type(OverworldController.pushBattle) == "function"
        and not OverworldController._kantoInMotionBattleLayout then
      local nativePushBattle = OverworldController.pushBattle
      OverworldController._kantoInMotionBattleLayout = nativePushBattle
      OverworldController.pushBattle = function(self, battle, ...)
        if battleSystemEnabled() and not externalBattleSceneOwnerRegistered() then
          forceBattleLayoutOG(self and self.game)
        end
        return nativePushBattle(self, battle, ...)
      end
    end

    local okBattle, BattleState = pcall(require, "src.battle.BattleState")
    if okBattle and type(BattleState) == "table" then
      if type(BattleState.newWild) == "function"
          and not BattleState._kantoInMotionShinyOdds then
        local nativeNewWild = BattleState.newWild
        BattleState._kantoInMotionShinyOdds = nativeNewWild
        BattleState.newWild = function(game_, species, level, opts)
          local battle = nativeNewWild(game_, species, level, opts)
          local mon = battle and battle.enemy and battle.enemy.mon
          if mon then
            local consume = mod.exports and mod.exports._kantoInMotionConsumePreparedWildIdentity
            local prepared = type(consume) == "function" and consume(species, level) or nil
            if type(prepared) == "table" and type(prepared.dvs) == "table" then
              mon.dvs = type(mon.dvs) == "table" and mon.dvs or {}
              for key, value in pairs(prepared.dvs) do mon.dvs[key] = value end
              mon.shiny = prepared.shiny == true and true or nil
            else
              rollWildShiny(mon)
            end
          end
          return battle
        end
      end
      if type(BattleState.drawPicsLayer) == "function"
          and not BattleState._kantoInMotionBattlePics then
        local nativeDrawPicsLayer = BattleState.drawPicsLayer
        BattleState._kantoInMotionBattlePics = nativeDrawPicsLayer
        local transparentBattlePic = nil
        local function transparentPic()
          if transparentBattlePic then return transparentBattlePic end
          if not (love and love.graphics and type(love.graphics.newCanvas) == "function") then
            return nil
          end
          local ok, canvas = pcall(love.graphics.newCanvas, 1, 1, { dpiscale = 1 })
          if not ok or not canvas then return nil end
          if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
          local prev = love.graphics.getCanvas and love.graphics.getCanvas() or nil
          love.graphics.push("all")
          love.graphics.setCanvas(canvas)
          love.graphics.clear(0, 0, 0, 0)
          if prev then love.graphics.setCanvas(prev) else love.graphics.setCanvas() end
          love.graphics.pop()
          transparentBattlePic = canvas
          return canvas
        end
        BattleState.drawPicsLayer = function(self, ...)
          if not battleLiteOwnsSprites() then return nativeDrawPicsLayer(self, ...) end
          local oldEnemy = self.enemy and self.enemy.sprite
          local oldPlayer = self.player and self.player.sprite
          local changedEnemy, changedPlayer = false, false
          local direct = battleLiteFullScreenActive()

          if self.enemy and self.enemy.mon and not self.enemySendingOut then
            local record, generation, species, shiny = battleRecord(
              self.enemy.mon.species, "front", self.enemy.mon)
            if record then
              if direct and not self.showEnemyTrainer then
                local blank = transparentPic()
                if blank then self.enemy.sprite = blank; changedEnemy = true end
              else
                local image = battleProxy(record, generation, "front",
                  shiny and "shiny" or "normal", species)
                if image then self.enemy.sprite = image; changedEnemy = true end
              end
            end
          end
          -- While the native send-out state is active, leave player.sprite
          -- completely untouched. Gen1Recomp temporarily uses that native pics
          -- path for the thrown Pokeball/opening frames; replacing it with a
          -- Pokemon proxy is what made the split/open effect appear without the
          -- actual ball. Once sendingOut clears, resume the normal KIM proxy /
          -- transparent fullscreen substitution.
          if self.player and self.player.mon and not self.sendingOut then
            local record, generation, species, shiny = battleRecord(
              self.player.mon.species, "back", self.player.mon)
            if record then
              if direct and not self.showPlayerBack and not self.safari and not self.demo then
                local blank = transparentPic()
                if blank then self.player.sprite = blank; changedPlayer = true end
              else
                local image = battleProxy(record, generation, "back",
                  shiny and "shiny" or "normal", species)
                if image then self.player.sprite = image; changedPlayer = true end
              end
            end
          end
          local result = { pcall(nativeDrawPicsLayer, self, ...) }
          if changedEnemy and self.enemy then self.enemy.sprite = oldEnemy end
          if changedPlayer and self.player then self.player.sprite = oldPlayer end
          local ok = table.remove(result, 1)
          if not ok then error(result[1], 0) end
          return unpack(result)
        end
      end

      -- Battle Art snaps the ENTIRE 48-row HUD bands (not just HP boxes) to
      -- the window edges. Those bands also contain Pokeball Colorfix's party
      -- rows. Once KIM captures the band, suppress the source draw so a second
      -- zone-coloured copy cannot remain in the middle of the 160x144 overlay.
      if type(BattleState.drawHUDs) == "function"
          and not BattleState._kantoInMotionSourceHudBands then
        local nativeDrawHUDs = BattleState.drawHUDs
        BattleState._kantoInMotionSourceHudBands = nativeDrawHUDs
        BattleState.drawHUDs = function(self, ...)
          if battleLiteFullScreenActive() and not self._kantoInMotionHudCapture then
            return
          end
          return nativeDrawHUDs(self, ...)
        end
      end

      if type(BattleState.draw) == "function"
          and not BattleState._kantoInMotionBattleDraw then
        local nativeBattleDraw = BattleState.draw
        BattleState._kantoInMotionBattleDraw = nativeBattleDraw
        BattleState.draw = function(self, ...)
          local ownsFullscreen = battleLiteFullScreenActive()
          if not ownsFullscreen then
            if pendingFullscreenBattle == self then pendingFullscreenBattle = nil end
            self._kantoInMotionBattleLite = nil
            if self._kantoInMotionOwnsBattlePaper then
              self.letterboxWhite = nil
              self._kantoInMotionOwnsBattlePaper = nil
            end
            local shot = rawget(self, "dramaticShapeShot")
            if type(shot) == "table" and shot.kantoInMotion2D then
              self.dramaticShapeShot = nil
              self._kantoInMotionFlatShot = nil
            end
            return nativeBattleDraw(self, ...)
          end

          -- Publish ownership before render.zones/render.compose so the
          -- integrated Modern UI can modernize only KIM's lower battle panel
          -- without ever claiming another mod's battle scene. Mark only a
          -- genuinely top-level BattleState for source-canvas removal; child
          -- Bag/Party/etc. screens must keep their own UI canvas intact.
          self._kantoInMotionBattleLite = true
          local stack = self.game and self.game.stack
          local top = stack and type(stack.top) == "function" and stack:top() or nil
          if top == nil or top == self then pendingFullscreenBattle = self end

          -- Match Battle Art's BattleState ownership path, but replace its
          -- voxel BattleScene with one full-window Gen 6 image. beginFrame has
          -- already bound the UI canvas here, so clear that canvas to alpha,
          -- disable the white letterbox, and suppress only the source 160x144
          -- white background fill. The engine still draws Pokemon, attack
          -- effects and the lower battle UI normally into this transparent
          -- overlay.
          if type(setFlatBattleWorld) == "function" then
            pcall(setFlatBattleWorld, self.game, self)
          end
          self.letterboxWhite = false
          self._kantoInMotionOwnsBattlePaper = true
          love.graphics.clear(0, 0, 0, 0)

          -- v8.6.13: suppress the native Gen1 hit-flash on the ACTUAL KRS
          -- source-draw path. The earlier v8.6.12 guard lived in an older
          -- fullscreen redraw helper and was never reached by KRS battles.
          -- KRBA already renders its authored particles/BG/FG effects, so the
          -- native fx.flash becomes a second white flash after the 160x144
          -- source is composited over the final-resolution arena.
          local fx = self.fx
          local oldNativeFlash = nil
          local krbaSession = self.animPlayer and self.animPlayer._krs
          local fill = mod.options:get("battleArenaFill")
          local suppressNativeFlash = (fill == "krs" or fill == "gen6")
            and krbaSession ~= nil and type(fx) == "table"
            and (tonumber(fx.flash) or 0) > 0
          if suppressNativeFlash then
            oldNativeFlash = fx.flash
            fx.flash = 0
          end

          local result = { pcall(withoutBattleBackgroundFill,
            self, nativeBattleDraw, ...) }

          if oldNativeFlash ~= nil and type(fx) == "table" then
            fx.flash = oldNativeFlash
          end

          local ok = table.remove(result, 1)
          if not ok then error(result[1], 0) end
          return unpack(result)
        end
      end

      if type(BattleState.resolveBattleScale) == "function"
          and not BattleState._kantoInMotionBattleScale then
        local nativeResolveScale = BattleState.resolveBattleScale
        BattleState._kantoInMotionBattleScale = nativeResolveScale
        BattleState.resolveBattleScale = function(data, side, path, species)
          local base = nativeResolveScale(data, side, path, species)
          if not (battleSystemEnabled() and not externalBattleSceneOwnerRegistered() and species) then
            return base
          end

          -- Fullscreen animated Pokemon are now painted at native atlas
          -- resolution directly into the world canvas. Do not pre-shrink them
          -- here: doing so resamples once into the 160x144 UI and a second time
          -- when that UI reaches the window, which is what made v7.3 look
          -- extremely blocky. This seam remains only for the non-fullscreen
          -- fallback path.
          if battleLiteFullScreenActive() then return base end

          if side == "back" then
            local record = battleLiteOwnsSprites() and battleRecord(species, side, nil) or nil
            local authored = record and 1 or (tonumber(base) or 1)
            local pct = tonumber(mod.options:get("battlePlayerSize")) or 125
            pct = math.max(50, math.min(200, pct))
            return authored * pct / 100
          end
          return base
        end
      end

    end
  end

  -- Flat Gen 6 arena selection (Gen1 only). This is copied from Battle Art's
  -- Kanto routing data but contains no voxel, mesh, camera or world renderer.
  local gen6Config = not IS_GEN2 and loadTable("data/gen6_battle_backgrounds.lua", true) or {}
  local gen6ImageCache = {}
  local function gen6Period()
    local d = os.date("*t")
    local hours = (tonumber(d.hour) or 12) + (tonumber(d.min) or 0) / 60
    local t = ((hours - 6) * 50) % 1200
    local B, D, C = 75, 600, 1200
    local dial = {
      { 0, "dawn" }, { B, "day" },
      { D - 2 * B, "day" }, { D - B, "golden" }, { D, "dusk" },
      { D + B / 2, "violet" }, { D + B, "night" },
      { C - B, "night" }, { C - B / 2, "violet" }, { C, "dawn" },
    }
    local bestName, bestWeight = "dawn", -1
    for i = 1, #dial - 1 do
      local a, b = dial[i], dial[i + 1]
      if t >= a[1] and t < b[1] then
        if a[2] == b[2] then bestName = a[2] break end
        local u = (t - a[1]) / (b[1] - a[1])
        if 1-u >= u then bestName = a[2] else bestName = b[2] end
        break
      end
    end
    if bestName == "golden" then return "dusk" end
    if bestName == "violet" then return "night" end
    return bestName
  end

  local function gen6SetFor(game, battle)
    local map = game and game.overworld and game.overworld.map
    local id = map and map.id
    if not id then return nil end
    local encounter = gen6Config.encounters and gen6Config.encounters[id]
    local setName = encounter and battle and encounter[battle.oppClass]
      or (gen6Config.maps and gen6Config.maps[id])
    if not setName and map and map.def then
      local okMap, Map = pcall(require, "src.world.Map")
      if okMap and Map and type(Map.isOutdoor) == "function" then
        local okOutdoor, outdoor = pcall(Map.isOutdoor, map.def)
        if okOutdoor and outdoor then setName = "grassy" end
      end
    end
    return setName
  end

  local function gen6FileFor(game, battle)
    local setName = gen6SetFor(game, battle)
    local set = setName and gen6Config.sets and gen6Config.sets[setName]
    if type(set) == "string" then return set end
    if type(set) ~= "table" then return nil end
    local period = battle._kantoInMotionGen6Period
    if not period then
      period = gen6Period()
      battle._kantoInMotionGen6Period = period
    end
    return set[period] or set.day or set.dawn or set.dusk or set.night
  end

  local function gen6Image(game, battle)
    local file = gen6FileFor(game, battle)
    if not file then return nil end
    local path = "assets/battle/front-static/gen6/" .. file
    if gen6ImageCache[path] == false then return nil end
    if gen6ImageCache[path] then return gen6ImageCache[path] end
    local image = atlasImage(path)
    gen6ImageCache[path] = image or false
    return image
  end

  -- Mobile battle presentation policy. Kanto in Motion keeps its desktop
  -- presentation whenever the virtual controls are hidden. When Android/iOS
  -- TouchControls are actually visible, the base battle UI yields to the
  -- source/native presenter so the d-pad and A/B buttons never sit over a
  -- second full-screen command surface. Portrait additionally uses a contained
  -- arena stage below so the landscape battle art keeps its authored aspect.
  local function touchBattleOrientation(game)
    -- The mobile battle compositor is native-mobile only. Windows handhelds
    -- can expose TouchControls too, but must stay on the desktop battle path.
    local system = love and love.system
    if not system or type(system.getOS) ~= "function" then return nil end
    local okOs, hostOs = pcall(system.getOS)
    if not okOs or (hostOs ~= "Android" and hostOs ~= "iOS") then return nil end

    local touch = game and game.touchControls
    local stack = game and game.stack
    if not touch or (stack and type(stack.touchControlsHidden) == "function"
        and stack:touchControlsHidden()) then return nil end
    if type(touch.visible) ~= "function" then return nil end
    local okVisible, visible = pcall(touch.visible, touch)
    if not okVisible or not visible then return nil end
    local g = love and love.graphics
    local w, h = 0, 0
    if g and type(g.getPixelDimensions) == "function" then
      local ok, pw, ph = pcall(g.getPixelDimensions)
      if ok then w, h = tonumber(pw) or 0, tonumber(ph) or 0 end
    end
    if not (w > 0 and h > 0) and g and type(g.getDimensions) == "function" then
      local ok, uw, uh = pcall(g.getDimensions)
      if ok then w, h = tonumber(uw) or 0, tonumber(uh) or 0 end
    end
    if not (w > 0 and h > 0) then return "landscape" end
    return h > w and "portrait" or "landscape"
  end

  -- Mobile landscape keeps Gen1's native 48-row command/dialog strip at the
  -- bottom of the battle. OAM animation sprites (notably the player send-out
  -- POOF/Poke Ball opening) can extend a few pixels below logical row 96.
  -- KIM reconstructs that animation layer over the fullscreen arena, so those
  -- pixels would otherwise land on top of the preserved dialog frame. Clip
  -- only the native animation layer to the battlefield while the landscape
  -- touch presentation is active. The animation itself, trainer, HUD, dialog,
  -- Party and Bag paths are otherwise unchanged.
  do
    local okBattle, BattleState = pcall(require, "src.battle.BattleState")
    if okBattle and type(BattleState) == "table"
        and type(BattleState.drawAnimLayer) == "function"
        and not BattleState._kantoInMotionLandscapeAnimClip then
      local nativeDrawAnimLayer = BattleState.drawAnimLayer
      BattleState._kantoInMotionLandscapeAnimClip = nativeDrawAnimLayer
      BattleState.drawAnimLayer = function(self, ...)
        local g = love and love.graphics
        local clip = self and self._kantoInMotionBattleLite
          and touchBattleOrientation(self.game) == "landscape"
          and g and type(g.getScissor) == "function"
          and type(g.setScissor) == "function"
        if not clip then return nativeDrawAnimLayer(self, ...) end

        local oldX, oldY, oldW, oldH = g.getScissor()
        if type(g.intersectScissor) == "function" then
          g.intersectScissor(0, 0, 160, 96)
        else
          g.setScissor(0, 0, 160, 96)
        end
        local result = { pcall(nativeDrawAnimLayer, self, ...) }
        if oldX ~= nil then
          g.setScissor(oldX, oldY, oldW, oldH)
        else
          g.setScissor()
        end
        local ok = table.remove(result, 1)
        if not ok then error(result[1], 0) end
        return unpack(result)
      end
    end
  end

  -- Kanto Rework Suite canonical 1920x950 arenas. The router uses the live
  -- Gen1 map/terrain/time state and caches one choice per battle, matching KRS.
  local krsArenaRouter = not IS_GEN2 and loadTable("data/krs_battle_backgrounds.lua", true) or {}
  if type(krsArenaRouter.bindMod)=="function" then pcall(krsArenaRouter.bindMod, mod) end
  local krsArenaImageCache = {}
  local function krsArenaBackdrop(game,battle)
    if type(krsArenaRouter.resolve)~="function" then return nil end
    local ok,value=pcall(krsArenaRouter.resolve,game,battle)
    return ok and type(value)=="table" and value or nil
  end
  local function krsArenaImage(game,battle)
    local backdrop=krsArenaBackdrop(game,battle)
    local file=backdrop and backdrop.file
    if not file then return nil,backdrop end
    local path="assets/battle/backgrounds/krs/"..tostring(file)..".png"
    if krsArenaImageCache[path]==false then return nil,backdrop end
    if not krsArenaImageCache[path] then
      local image=atlasImage(path)
      krsArenaImageCache[path]=image or false
    end
    return krsArenaImageCache[path] or nil,backdrop
  end
  -- KRS backgrounds are authored at 1920x950 while common desktop play is
  -- 1920x1080 (and 4:3 is taller still relative to the source artwork).  The
  -- user-approved v8.6.4 enemy placement now looks correct, but the field
  -- itself still wants a hair more lift.  Nudge only the KRS scenery upward a
  -- little further while compensating the battler anchors so player/enemy stay
  -- at the accepted on-screen heights.
  local KRS_STAGE_LIFT_PX = 172
  local KRS_PLAYER_Y_COMPENSATE_PX = 60
  local KRS_ENEMY_EXTRA_LIFT_PX = 8
  -- KRS' enemy stance point was tuned at 16:9. On 4:3 the cover-scaled
  -- 1920x950 arena crops heavily at the sides, leaving larger enemy sprites
  -- uncomfortably close to the right edge. Preserve the accepted widescreen
  -- placement, then ease the enemy left only once the viewport becomes
  -- narrower than 3:2. At 4:3 (and narrower) the correction tops out at 72px.
  local KRS_ENEMY_NARROW_SHIFT_PX = 72
  -- SCREEN POS (CENTER / UPPER / TOP) shifts Gen1Recomp's native 160x144
  -- presentation upward inside unused vertical space. Renderer.worldOverride
  -- itself always fills the playfield, so a custom KRS/GEN6 scene has to apply
  -- that same physical-pixel lift to its contained content explicitly. This is
  -- active only while mobile touch controls are visible; desktop layouts keep
  -- their already-tuned placement.
  local function mobileScreenPositionLiftPx(game,vw,vh)
    if not touchBattleOrientation(game) then return 0 end
    local okSp,ScreenPosition=pcall(require,"src.core.ScreenPosition")
    if not okSp or not ScreenPosition or type(ScreenPosition.lift)~="function" then
      return 0
    end
    if type(ScreenPosition.skinActive)=="function" then
      local okSkin,skin=pcall(ScreenPosition.skinActive)
      if okSkin and skin then return 0 end
    end
    local s=math.max(1,math.floor(math.min((tonumber(vw) or 160)/160,
      (tonumber(vh) or 144)/144)))
    local dpiY=1
    if love and love.graphics and type(love.graphics.getDimensions)=="function"
        and type(love.graphics.getPixelDimensions)=="function" then
      local okU,_,uh=pcall(love.graphics.getDimensions)
      local okP,_,ph=pcall(love.graphics.getPixelDimensions)
      if okU and okP and tonumber(uh) and tonumber(ph) and uh>0 and ph>0 then
        dpiY=ph/uh
      end
    end
    local safe=0
    if type(ScreenPosition.safeTop)=="function" then
      local ok,value=pcall(ScreenPosition.safeTop)
      if ok then safe=(tonumber(value) or 0)*dpiY end
    end
    local ok,value=pcall(ScreenPosition.lift,vh,144*s,safe)
    return ok and math.max(0,tonumber(value) or 0) or 0
  end

  -- Physical-pixel rectangle occupied by the contained 1920x950 battlefield
  -- on a portrait touch layout. Every portrait-only screen-space element uses
  -- this same rectangle so the arena, trainer, HUD and native text can be
  -- stacked without overlapping the Pokemon.
  local function mobilePortraitStageRectPx(game,vw,vh)
    if touchBattleOrientation(game)~="portrait" then return nil end
    vw,vh=tonumber(vw) or 0,tonumber(vh) or 0
    if not (vw>0 and vh>0) then return nil end
    local aspect=1920/950
    local stageW=vw
    local stageH=stageW/aspect
    if stageH>vh then stageH=vh; stageW=stageH*aspect end
    local lift=mobileScreenPositionLiftPx(game,vw,vh)
    local x=(vw-stageW)*0.5
    local y=(vh-stageH)*0.5-lift
    return {x=x,y=y,width=stageW,height=stageH,bottom=y+stageH,lift=lift}
  end

  local function krsEnemyNarrowShift(vw,vh)
    vw, vh = tonumber(vw) or 0, tonumber(vh) or 0
    if not (vw>0 and vh>0) then return 0 end
    local aspect=vw/vh
    local startAspect=3/2
    local fullAspect=4/3
    if aspect>=startAspect then return 0 end
    if aspect<=fullAspect then return KRS_ENEMY_NARROW_SHIFT_PX end
    local t=(startAspect-aspect)/(startAspect-fullAspect)
    return KRS_ENEMY_NARROW_SHIFT_PX*math.max(0,math.min(1,t))
  end
  local function krsArenaTransform(vw,vh,contain)
    if contain then
      local scale=math.min(vw/1920,vh/950)
      if not (scale>0) then scale=1 end
      return {
        x=(vw-1920*scale)*0.5, y=(vh-950*scale)*0.5,
        r=0,sx=scale,sy=scale,ox=0,oy=0,kx=0,ky=0,scale=scale,
        contained=true,
      }
    end
    local scale=math.max(vw/1920,vh/950)
    return {x=(vw-1920*scale)*0.5,y=(vh-950*scale)*0.5-KRS_STAGE_LIFT_PX,r=0,sx=scale,sy=scale,ox=0,oy=0,kx=0,ky=0,scale=scale}
  end
  -- Generic fullscreen KRBA stage used by GEN6. KRBA's Essentials-wide
  -- renderer is authored against the same 1920x950 logical plane used by the
  -- KRS bridge. GEN6 does not have authored ground anchors, so keep that plane
  -- aspect-correct, center it in the viewport, and derive effect anchors from
  -- KIM's actual final-resolution battler positions below.
  local function gen6KrbaTransform(vw,vh)
    local scale=math.min(vw/1920,vh/950)
    if not (scale>0) then scale=1 end
    return {
      x=(vw-1920*scale)*0.5,
      y=(vh-950*scale)*0.5,
      r=0,sx=scale,sy=scale,ox=0,oy=0,kx=0,ky=0,scale=scale,
    }
  end

  local function krsArenaGroundGeometry(game,battle,vw,vh,pixelScale)
    local image,backdrop=krsArenaImage(game,battle)
    if not image then return nil,nil,nil end
    local anchors=type(krsArenaRouter.groundAnchors)=="function" and krsArenaRouter.groundAnchors(backdrop) or nil
    if type(anchors)~="table" then return nil,nil,nil end
    local portraitTouch=touchBattleOrientation(game)=="portrait"
    local t=krsArenaTransform(vw,vh,portraitTouch)
    if portraitTouch then
      t.y=t.y-mobileScreenPositionLiftPx(game,vw,vh)
    end
    -- The desktop compensation values were tuned in final pixels. Scale them
    -- down with a contained portrait stage instead of letting a 60px desktop
    -- nudge become a huge fraction of a phone-width battlefield.
    local compScale=portraitTouch and math.min(1,t.scale) or 1
    local enemyShift=portraitTouch and 0 or krsEnemyNarrowShift(vw,vh)
    return {
      pixelScale=pixelScale,
      playerX=t.x+(anchors.player.x or 630)*t.scale,
      playerY=t.y+(anchors.player.y or 704)*t.scale
        +KRS_PLAYER_Y_COMPENSATE_PX*compScale,
      enemyX=t.x+(anchors.enemy.x or 1400)*t.scale-enemyShift,
      enemyY=t.y+(anchors.enemy.y or 484)*t.scale
        -KRS_ENEMY_EXTRA_LIFT_PX*compScale,
      krs=true,krsScale=t.scale,krsTransform=t,krsBackdrop=backdrop,
      mobilePortrait=portraitTouch,
    },image,backdrop
  end
  local function activeKrbaSession()
    local fn=mod.exports and mod.exports._kantoInMotionKRBAActiveSession
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn)
    return ok and value or nil
  end

  local function drawCover(image, x, y, w, h, topOffset)
    if not image then return false end
    local iw, ih = image:getDimensions()
    if not iw or not ih or iw <= 0 or ih <= 0 then return false end
    local scale = math.max(w / iw, h / ih)
    local available = math.max(0, ih - h / scale)
    local requested = tonumber(topOffset) or 0
    -- Values from 0..1 are a fraction of the removable vertical area. This
    -- keeps the horizon/floor framing consistent across differently sized
    -- Gen 6 plates; larger values remain absolute source-pixel offsets.
    if requested >= 0 and requested <= 1 then requested = available * requested end
    local crop = math.max(0, math.min(available, requested))
    local dx = x + (w - iw * scale) / 2
    local dy = y - crop * scale
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, dx, dy, 0, scale, scale)
    return true
  end

  local function drawContain(image, x, y, w, h)
    if not image then return false end
    local iw, ih = image:getDimensions()
    if not iw or not ih or iw <= 0 or ih <= 0 then return false end
    local scale = math.min(w / iw, h / ih)
    if not (scale > 0) then return false end
    local dx = x + (w - iw * scale) * 0.5
    local dy = y + (h - ih * scale) * 0.5
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, dx, dy, 0, scale, scale)
    return true
  end

  -- Full-window 2D host used in place of Battle Art's voxel BattleScene.
  -- Renderer:setWorldOverride is the same compositor seam Battle Art uses for
  -- its staged arena; the only difference is that this canvas contains a flat
  -- Gen 6 plate instead of a voxel render.
  local flatBattleWorldCanvas = nil

  -- Quality of Life draws its EXP bar directly into dramaticShapeShot.canvas.
  -- KIM keeps QOL source-owned, then translates only the final EXP rectangles
  -- when KIM's player HUD band no longer shares shot.ly: Battle Art SCALED mode
  -- and Android/iOS portrait both do this. The correction is derived from the
  -- actual player-band Y, so ordinary landscape/desktop coordinates remain
  -- unchanged. The caught/Pokedex indicator continues to use the unmodified
  -- enemy-band origin.
  local qolXpCompat = { active = false }
  local function installQolXpRectangleCompat()
    local g = love and love.graphics
    if not (g and type(g.rectangle) == "function") or g._kantoInMotionQolXpCompat then
      return
    end
    local nativeRectangle = g.rectangle
    g._kantoInMotionQolXpCompat = nativeRectangle
    g.rectangle = function(mode, x, y, w, h, ...)
      local c = qolXpCompat
      if c.active and mode == "fill" and c.canvas
          and g.getCanvas and g.getCanvas() == c.canvas then
        local nx, ny, nw, nh = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
        if nx and ny and nw and nh and nx >= (c.minX or 0) then
          -- Main QOL EXP fill: exactly 2 logical pixels tall.
          if math.abs(ny - c.baseY) < 0.51
              and math.abs(nh - 2 * c.scale) < 0.51 then
            y = ny + c.shiftY
          -- Level-up burst particles are 1 logical pixel blocks expanded by
          -- the same scale. Shift those with the bar so the celebration stays
          -- attached to it in SCALED/portrait compatibility mode.
          elseif math.abs(nw - c.scale) < 0.51
              and math.abs(nh - c.scale) < 0.51
              and ny >= c.baseY - 24 * c.scale
              and ny <= c.baseY + 24 * c.scale then
            y = ny + c.shiftY
          end
        end
      end
      return nativeRectangle(mode, x, y, w, h, ...)
    end
  end
  installQolXpRectangleCompat()


  local function ensureBattleCanvas(canvas, w, h, filter)
    if canvas and canvas:getWidth() == w and canvas:getHeight() == h then return canvas end
    local ok, fresh = pcall(love.graphics.newCanvas, w, h, { dpiscale = 1 })
    if not ok or not fresh then return nil end
    if fresh.setFilter then pcall(fresh.setFilter, fresh, filter or "nearest", filter or "nearest") end
    return fresh
  end

  -- Renderer:setWorldOverride consumes a *physical-pixel* image. Desktop has
  -- historically hidden that contract because window units and framebuffer
  -- pixels are normally 1:1 there. Android/iOS high-DPI windows are not: a
  -- 1800px-wide phone can report only ~640 LOVE units. A dpiscale=1 canvas
  -- sized with love.graphics.getDimensions() therefore covers only ~1/DPI of
  -- the phone when Renderer:endFrame performs its documented 1/dpi blit.
  --
  -- Mirror Gen1Recomp 0.2.38 Renderer.displayMetrics here: start from the live
  -- framebuffer size and then honor Playfield's TouchSkin cutout. The returned
  -- width/height are the exact pixel dimensions worldOverride must own; x/y
  -- and dpi let screen-space consumers translate a world-canvas edge back to
  -- LOVE units when needed (the KRS footer handoff below).
  local function battleWorldMetrics()
    local g = love and love.graphics
    if not g then return nil end

    -- Renderer.displayMetrics starts from GameViewport, not directly from the
    -- OS window. This distinction matters on Android when SCREEN LOCATION or
    -- another layout provider captures/moves the game rectangle: the HUD was
    -- already drawing in GameViewport-local coordinates, while KIM's physical
    -- worldOverride was still being sized from the full phone framebuffer.
    -- Mirror the renderer contract exactly so arena, battlers and HUD all move
    -- as one presentation.
    local uw, uh, pw, ph
    local okViewport, GameViewport = pcall(require, "src.render.GameViewport")
    if okViewport and GameViewport then
      if type(GameViewport.dimensions) == "function" then
        local ok, w, h = pcall(GameViewport.dimensions)
        if ok then uw, uh = tonumber(w), tonumber(h) end
      end
      if type(GameViewport.pixelDimensions) == "function" then
        local ok, w, h = pcall(GameViewport.pixelDimensions)
        if ok then pw, ph = tonumber(w), tonumber(h) end
      end
    end
    if not (uw and uh and uw > 0 and uh > 0) and type(g.getDimensions) == "function" then
      local ok, w, h = pcall(g.getDimensions)
      if ok then uw, uh = tonumber(w), tonumber(h) end
    end
    uw, uh = math.max(1, uw or 1), math.max(1, uh or 1)
    if not (pw and ph and pw > 0 and ph > 0) and type(g.getPixelDimensions) == "function" then
      local ok, w, h = pcall(g.getPixelDimensions)
      if ok then pw, ph = tonumber(w), tonumber(h) end
    end
    pw, ph = math.max(1, math.floor((pw or uw) + 0.5)),
      math.max(1, math.floor((ph or uh) + 0.5))
    local dpiX = pw / uw
    local dpiY = ph / uh
    if not (dpiX > 1e-6) then dpiX = 1 end
    if not (dpiY > 1e-6) then dpiY = 1 end

    local vx, vy, vw, vh = 0, 0, pw, ph
    local okPlayfield, Playfield = pcall(require, "src.render.Playfield")
    if okPlayfield and Playfield and type(Playfield.cutout) == "function" then
      local ok, x, y, w, h = pcall(Playfield.cutout, pw, ph)
      if ok and tonumber(x) and tonumber(y) and tonumber(w) and tonumber(h)
          and w > 0 and h > 0 then
        vx, vy = math.floor(x + 0.5), math.floor(y + 0.5)
        vw, vh = math.max(1, math.floor(w + 0.5)), math.max(1, math.floor(h + 0.5))
      end
    end
    return {
      width = vw, height = vh, pixelWidth = pw, pixelHeight = ph,
      x = vx, y = vy, dpiX = dpiX, dpiY = dpiY,
      unitX = vx / dpiX, unitY = vy / dpiY,
      unitWidth = vw / dpiX, unitHeight = vh / dpiY,
    }
  end

  -- One geometry contract is shared by Kanto in Motion's snapped HP HUD and
  -- Battle-Art-aware third-party overlays. Quality of Life already consumes
  -- battle.dramaticShapeShot for its EXP bar and caught/Pokedex indicator, so
  -- publishing this table lets QOL follow KIM without changing QOL itself.
  -- `scale` intentionally follows the selected HUD scale here: OG uses the
  -- full integer window fit; SCALED uses the compact one-rung-smaller fit.
  local function battleHudGeometry(vw, vh, liftPx, game)
    local s = math.max(1, math.floor(math.min(vw / 160, vh / 144)))
    -- Mirror Battle Art 1.9.8 OverworldBattle.snapRects exactly:
    -- OG uses the window-fit rung; SCALED is one integer rung smaller.
    local hs = (mod.options:get("battleHudScale") == "scaled")
      and math.max(1, s - 1) or s
    local lx = math.floor((vw - 160 * s) * 0.5)
    local ly = math.floor((vh - 144 * s) * 0.5) - math.floor(tonumber(liftPx) or 0)
    local enemyRect = { 8, 0, 80, 32 }
    local playerRect = { 72, 56, 88, 40 }
    local playerBandTop = 48
    local enemyBandX = (2 - enemyRect[1]) * hs
    local playerBandX = vw - (playerRect[1] + playerRect[3]) * hs
    local playerBandY = ly + playerRect[2] * s
      - (playerRect[2] - playerBandTop) * hs
    local portraitStage=mobilePortraitStageRectPx(game,vw,vh)
    if portraitStage then
      -- Mobile portrait reference (Screenshot_20260829_173258.png): keep the
      -- player/Charizard HP band inside the lower-right of the contained
      -- battlefield rather than stacking it in the black space underneath.
      -- v8.6.30 got the dialog edge right but left this band too close to it.
      -- Lift the complete player band another 8 HUD rows while leaving the
      -- accepted dialog and battlefield geometry completely unchanged.
      playerBandY=math.floor(portraitStage.bottom-44*hs+0.5)
      playerBandY=math.max(0,math.min(vh-48*hs,playerBandY))
    end
    return {
      battleScale = s,
      hudScale = hs,
      lx = lx,
      ly = ly,
      enemyBandX = enemyBandX,
      playerBandX = playerBandX,
      enemyBandY = ly,
      playerBandY = playerBandY,
      portraitStage = portraitStage,
    }
  end

  -- Native-resolution fullscreen battlers. Battle Art avoids scaling a
  -- Pokemon down into the 160x144 UI and then scaling that UI back up; KIM now
  -- follows the same principle. One atlas frame is drawn directly onto the
  -- window-resolution world canvas with nearest filtering. At 1080p the
  -- Battle-Art-like stage rung is 6x and sprite pixels are displayed at 4x.
  local function directStageGeometry(vw, vh, game, battle)
    local fit = math.max(1, math.floor(math.min(vw / 160, vh / 144)))
    local stage = math.max(1, fit - 1)
    local lx = math.floor((vw - 160 * stage) * 0.5)
    local portraitTouch=touchBattleOrientation(game)=="portrait"
    local pixelScale = math.max(1, math.floor(stage * 2 / 3 + 0.5))
    if portraitTouch then
      -- 4x is the accepted 1920-wide battle-sprite rung. Scale that rung by
      -- contained stage width so portrait does not leave Pokemon three times
      -- larger than the newly width-fitted arena.
      pixelScale=math.max(1,math.floor(4*(vw/1920)+0.5))
    end
    if mod.options:get("battleArenaFill")=="krs" then
      local geo=krsArenaGroundGeometry(game,battle,vw,vh,pixelScale)
      if geo then return geo end
    end
    local geo = {
      scale = stage, pixelScale = pixelScale, lx = lx, ly = 0,
      playerX = lx + 26 * stage, playerY = 110 * stage,
      enemyX = lx + 124 * stage, enemyY = 65 * stage,
    }
    if mod.options:get("battleArenaFill")=="gen6" then
      local t=gen6KrbaTransform(vw,vh)
      if portraitTouch then
        t.y=t.y-mobileScreenPositionLiftPx(game,vw,vh)
        -- Preserve the accepted 1920x1080 GEN6 battler composition inside the
        -- contained KRBA plane. These local points are the desktop anchors
        -- expressed relative to that 1920x950 stage.
        geo.lx=t.x
        geo.playerX=t.x+636*t.scale
        geo.playerY=t.y+595*t.scale
        geo.enemyX=t.x+1224*t.scale
        geo.enemyY=t.y+325*t.scale
        geo.mobilePortrait=true
      end
      geo.kimWide=true
      geo.krbaScale=t.scale
      geo.krbaTransform=t
    end
    return geo
  end

  local function battlerGrow(battle, battler)
    if not (battle and battler and type(battle.growInScale) == "function") then
      return 1
    end
    local ok, grow = pcall(battle.growInScale, battle, battler)
    grow = ok and tonumber(grow) or nil
    if grow == nil then return 1 end
    return math.max(0, math.min(1, grow))
  end

  local function directSideMetrics(battle, side, geo)
    local battler = battle and battle[side]
    local mon = battler and battler.mon
    if not mon then return nil end
    local view = side == "enemy" and "front" or "back"
    local record, generation, species, shiny = battleRecord(mon.species, view, mon)
    if not record then return nil end
    local frame = renderPresentationFrame(record, generation, species,
      nil, view, shiny and "shiny" or "normal", false)
    if not frame then return nil end
    if frame.setFilter then pcall(frame.setFilter, frame, "nearest", "nearest") end

    local scale = geo.pixelScale * battlerGrow(battle, battler)
    if side == "player" then
      local pct = tonumber(mod.options:get("battlePlayerSize")) or 125
      pct = math.max(50, math.min(200, pct))
      scale = scale * pct / 100
    else
      scale = scale * 1.25
    end
    local w, h = frame:getDimensions()
    local ax = side == "enemy" and geo.enemyX or geo.playerX
    local ay = side == "enemy" and geo.enemyY or geo.playerY
    local groundPx = shinyGroundOffset(generation, view, species, shiny)
    local groundShift = groundPx * scale
    return {
      battler=battler, mon=mon, record=record, generation=generation,
      species=species, shiny=shiny, frame=frame, scale=scale, w=w, h=h,
      ax=ax, ay=ay, groundPx=groundPx, groundShift=groundShift,
      x=ax - w * scale * 0.5,
      y=ay - h * scale + groundShift,
      centerX=ax,
      centerY=ay - h * scale * 0.5 + groundShift,
    }
  end

  local function drawDirectSide(battle, side, geo)
    local battler = battle and battle[side]
    local mon = battler and battler.mon
    if not mon then return false end

    -- Match Gen1Recomp/Battle Art's native pics-layer visibility exactly for
    -- send-out and effect timing.
    local fxHidden = false
    if type(battle.fxHidden) == "function" then
      local ok, hidden = pcall(battle.fxHidden, battle, battler)
      fxHidden = ok and hidden == true
    end

    if side == "enemy" then
      if battle.showEnemyTrainer or battle.enemyHidden or battle.enemySendingOut
          or battler.fainted or fxHidden then
        return false
      end
    else
      if battle.showPlayerBack or battle.safari or battle.demo or battle.sendingOut
          or battler.fainted or fxHidden then
        return false
      end
    end

    local metrics = directSideMetrics(battle, side, geo)
    if not metrics then return false end
    local frame, scale = metrics.frame, metrics.scale
    if scale <= 0 then return true end
    local ax, ay = metrics.ax, metrics.ay
    local x = math.floor(metrics.x + 0.5)
    local y = math.floor(metrics.y + 0.5)
    local transform=nil
    if geo.krs or geo.kimWide then
      local sess=activeKrbaSession()
      if sess and type(sess.battlerTransformWide)=="function" then
        local ok,value=pcall(sess.battlerTransformWide,sess,side)
        if ok and type(value)=="table" then transform=value end
      end
    end
    if transform and transform.visible==false then return true end
    love.graphics.setShader()
    love.graphics.push("all")
    local alpha=transform and (tonumber(transform.opacity) or 1) or 1
    love.graphics.setColor(1,1,1,alpha)
    if transform then
      local k=geo.krsScale or geo.krbaScale or 1
      local dx=(tonumber(transform.dx) or 0)*k
      local dy=(tonumber(transform.dy) or 0)*k
      local sx=tonumber(transform.scaleX) or 1
      local sy=tonumber(transform.scaleY) or 1
      if transform.mirror then sx=-sx end
      love.graphics.translate(ax+dx,ay+dy)
      love.graphics.rotate(tonumber(transform.rotation) or 0)
      love.graphics.scale(sx,sy)
      love.graphics.translate(-ax,-ay)
    end
    love.graphics.draw(frame,x,y,0,scale,scale)
    love.graphics.pop()
    return true
  end

  drawDirectBattleSprites = function(battle, vw, vh)
    if not (battle and battleLiteOwnsSprites() and battleLiteFullScreenActive()) then
      return false
    end
    local geo = directStageGeometry(vw, vh, battle.game, battle)
    local enemy = drawDirectSide(battle, "enemy", geo)
    local player = drawDirectSide(battle, "player", geo)
    return enemy or player
  end

  -- Load the shiny encounter presenter outside this large setup closure's local
  -- namespace. Keeping its state/functions in a separate module avoids Lua's
  -- 200-local limit while still sharing KIM's live battler geometry.
  mod._kantoInMotionShinyEncounterFx = (assert(load(assert(
    mod:read("lib/shiny_encounter_fx.lua")),
    "@" .. mod.path .. "/lib/shiny_encounter_fx.lua")))()(
      mod, isBattleShiny, directStageGeometry, directSideMetrics)

  setFlatBattleWorld = function(game, battle)
    if not game then
      local okGame, Game = pcall(require, "src.core.Game")
      if okGame then game = Game end
    end
    if battleSystemEnabled() and not externalBattleSceneOwnerRegistered() then
      forceBattleLayoutOG(game)
    end
    if not (battleLiteFullScreenActive() and game and game.renderer
        and type(game.renderer.setWorldOverride) == "function") then return false end

    local fill = mod.options:get("battleArenaFill")
    local image,backdrop=nil,nil
    if fill=="krs" then image,backdrop=krsArenaImage(game,battle)
    elseif fill=="gen6" then image=gen6Image(game,battle) end
    if (fill=="krs" or fill=="gen6") and not image then return false end

    local worldMetrics = battleWorldMetrics()
    if not worldMetrics then return false end
    local vw, vh = worldMetrics.width, worldMetrics.height
    flatBattleWorldCanvas = ensureBattleCanvas(flatBattleWorldCanvas, vw, vh, "linear")
    if not flatBattleWorldCanvas then return false end

    local g = love.graphics
    local prev = g.getCanvas and g.getCanvas() or nil
    g.push("all")
    g.setCanvas(flatBattleWorldCanvas)
    g.origin()
    local wideTransform=nil
    if fill == "white" then
      g.clear(1, 1, 1, 1)
    else
      g.clear(0, 0, 0, 1)
      g.setShader()
      g.setColor(1, 1, 1, 1)
      local portraitTouch=touchBattleOrientation(game)=="portrait"
      if fill=="krs" then
        wideTransform=krsArenaTransform(vw,vh,portraitTouch)
        if portraitTouch then
          wideTransform.y=wideTransform.y-mobileScreenPositionLiftPx(game,vw,vh)
        end
        g.draw(image,wideTransform.x,wideTransform.y,0,wideTransform.scale,wideTransform.scale)
      else
        local yOffset = tonumber(mod.options:get("battleBgYOffset")) or 140
        local mobileLift=portraitTouch and mobileScreenPositionLiftPx(game,vw,vh) or 0
        if portraitTouch then
          drawContain(image,0,-mobileLift,vw,vh)
        else
          drawCover(image, 0, 0, vw, vh, yOffset)
        end
        wideTransform=gen6KrbaTransform(vw,vh)
        if portraitTouch then wideTransform.y=wideTransform.y-mobileLift end
      end
    end
    local krba=(fill=="krs" or fill=="gen6") and activeKrbaSession() or nil
    -- KIM-specific effect anchors. Essentials' canonical 512x384 battler
    -- centers do not line up vertically with the authored KRS ground anchors;
    -- mapping travelling effects across the full 950px stage puts impacts far
    -- above the enemy. Provide local-stage battler centers to the integrated
    -- KRBA player so selected moves can follow the same anchors as KIM's art.
    local krbaWideAnchors=nil
    if krba and wideTransform then
      local stageScale=tonumber(wideTransform.scale) or 1
      if not (stageScale>0) then stageScale=1 end
      local EFFECT_HALF_BOX=95
      if fill=="krs" and backdrop
          and type(krsArenaRouter.groundAnchors)=="function" then
        local a=krsArenaRouter.groundAnchors(backdrop)
        if type(a)=="table" and a.player and a.enemy then
          local portraitTouch=touchBattleOrientation(game)=="portrait"
          local compScale=portraitTouch and math.min(1,stageScale) or 1
          local enemyShift=portraitTouch and 0 or krsEnemyNarrowShift(vw,vh)
          krbaWideAnchors={
            player={
              x=tonumber(a.player.x) or 630,
              y=(tonumber(a.player.y) or 704)
                + (KRS_PLAYER_Y_COMPENSATE_PX*compScale)/stageScale - EFFECT_HALF_BOX,
            },
            enemy={
              x=(tonumber(a.enemy.x) or 1400)-enemyShift/stageScale,
              y=(tonumber(a.enemy.y) or 484)
                - (KRS_ENEMY_EXTRA_LIFT_PX*compScale)/stageScale - EFFECT_HALF_BOX,
            },
          }
        end
      elseif fill=="gen6" then
        local geo=directStageGeometry(vw,vh,game,battle)
        local tx,ty=wideTransform.x or 0,wideTransform.y or 0
        -- GEN6 has no authored stance metadata. Aim battler-centric KRBA cels
        -- at the actual final-resolution animated sprite centers instead of a
        -- fixed distance above the ground anchor. This automatically follows
        -- species height, shiny padding correction and PLAYER PKMN SIZE.
        local pm=directSideMetrics(battle,"player",geo)
        local em=directSideMetrics(battle,"enemy",geo)
        local pcx=pm and pm.centerX or (geo.playerX or 0)
        local pcy=pm and pm.centerY or ((geo.playerY or 0)-EFFECT_HALF_BOX*stageScale)
        local ecx=em and em.centerX or (geo.enemyX or 0)
        local ecy=em and em.centerY or ((geo.enemyY or 0)-EFFECT_HALF_BOX*stageScale)
        krbaWideAnchors={
          player={x=(pcx-tx)/stageScale,y=(pcy-ty)/stageScale},
          enemy={x=(ecx-tx)/stageScale,y=(ecy-ty)/stageScale},
        }
      end
    end
    if krba and wideTransform and type(krba.drawWideBack)=="function" then
      pcall(krba.drawWideBack,krba,wideTransform,krbaWideAnchors)
    end
    -- Paint imported animated battlers at the final window resolution. KRS
    -- arenas use each background's authored player/enemy ground-contact points.
    if type(drawDirectBattleSprites) == "function" then
      pcall(drawDirectBattleSprites, battle, vw, vh)
    end
    if battle and mod._kantoInMotionShinyEncounterFx
        and type(mod._kantoInMotionShinyEncounterFx.draw) == "function" then
      pcall(mod._kantoInMotionShinyEncounterFx.draw,
        mod._kantoInMotionShinyEncounterFx, battle, game, vw, vh)
    end
    if krba and wideTransform and type(krba.drawWideFront)=="function" then
      pcall(krba.drawWideFront,krba,wideTransform,krbaWideAnchors)
    end
    g.pop()
    if prev then g.setCanvas(prev) else g.setCanvas() end
    game.renderer:setWorldOverride(flatBattleWorldCanvas)

    if battle then
      -- Publish the actual lower edge of the transformed KRS artwork.  Modern
      -- UI consumes this only while KRS Battle Lite is active and paints its
      -- theme into any uncovered footer below that edge.  This prevents a
      -- black bar when the 1920x950 source is lifted on 16:9 / 4:3 displays.
      if fill == "krs" and wideTransform then
        local footerPx = math.max(0, math.min(vh,
          math.floor(wideTransform.y + 950 * wideTransform.scale + 0.5)))
        -- Modern UI draws in LOVE/window units, while the fullscreen KRS
        -- canvas above is deliberately physical-pixel sized. Convert the live
        -- arena edge back into the same screen-space coordinate system before
        -- publishing it; desktop dpi=1 remains byte-for-byte equivalent.
        battle._kantoInMotionKrsFooterTop = (worldMetrics.unitY or 0)
          + footerPx / (worldMetrics.dpiY or 1)
      else
        battle._kantoInMotionKrsFooterTop = nil
      end
      local hudLift=touchBattleOrientation(game) and mobileScreenPositionLiftPx(game,vw,vh) or 0
      local geo = battleHudGeometry(vw, vh, hudLift, game)
      -- Battle Art's public per-frame battle geometry contract. QOL already
      -- understands this exact shape and will draw its EXP/Pokedex overlays
      -- directly onto the fullscreen arena. Extra anchor/span fields also
      -- make this useful to other Battle-Art-aware battle add-ons (including
      -- ball/effect compatibility) without touching those mods.
      local shot = {
        canvas = flatBattleWorldCanvas,
        scale = geo.hudScale,
        battleScale = geo.battleScale,
        hudScale = geo.hudScale,
        pw = vw, ph = vh,
        lx = geo.lx, ly = geo.ly,
        player = { 26, 96 },
        enemy = { 124, 56 },
        playerSpan = 56,
        enemySpan = 56,
        tint = { 1, 1, 1, 1 },
        kantoInMotion2D = true,
      }
      battle.dramaticShapeShot = shot
      battle._kantoInMotionFlatShot = shot

      -- QOL EXP compatibility. Quality of Life uses dramaticShapeShot.ly as
      -- the shared origin for its player EXP bar. That is correct in ordinary
      -- landscape/desktop geometry, but KIM deliberately relocates the player
      -- HUD band inside the contained battlefield on mobile portrait. Anchor
      -- QOL's EXP primitives to the actual KIM player-band top plus the native
      -- Gen 1 EXP-row offset (89 - 48 = 41 HUD pixels). The same formula also
      -- exactly preserves the existing SCALED-mode correction in landscape.
      -- Only QOL's EXP fill/burst rectangles are translated; QOL itself, its
      -- saved options, and its caught/Pokedex indicator remain untouched.
      local qolBaseY = geo.ly + 89 * geo.hudScale
      local qolTargetY = geo.playerBandY + 41 * geo.hudScale
      local qolPortrait = geo.portraitStage ~= nil
      local qolScaled = mod.options:get("battleHudScale") == "scaled"
        and geo.battleScale > geo.hudScale
      qolXpCompat.active = qolPortrait or qolScaled
      qolXpCompat.canvas = flatBattleWorldCanvas
      qolXpCompat.scale = geo.hudScale
      qolXpCompat.baseY = qolBaseY
      qolXpCompat.shiftY = qolTargetY - qolBaseY
      qolXpCompat.minX = vw * 0.5
    end
    return true
  end

  -- Kanto in Motion owns the battlefield, animated battlers and Battle Art-style
  -- HP/status bands.  When the integrated Modern UI is enabled it owns only the
  -- LOWER battle information surface: command menu, move menu and battle
  -- messages.  HP/status/EXP overlays remain source/KIM-owned.  Keeping this
  -- decision here also gives the master BATTLE SYSTEM switch a true bypass for
  -- users who prefer vanilla or another battle presentation mod.
  local function battleModernUiActive(game,state)
    -- Mobile uses the same hybrid ownership as desktop: Modern UI owns the
    -- command/move/message surface while KIM keeps the Battle Art-style
    -- HP/status HUD. TouchControls are an input overlay, not a reason to
    -- fall back to the vanilla battle menus.
    if not integratedModernUiEnabled() then return false end
    if mod._kantoInMotionModernUiInstalled ~= true then return false end
    if not battleSystemEnabled() or externalBattleSceneOwnerRegistered() then return false end
    return mod.options:get("battleUiWip") ~= false
  end

  local function typedMoveColorsHandle()
    if type(mod.find) ~= "function" then return nil end
    local ok, handle = pcall(mod.find, "typed_move_colors")
    return ok and handle or nil
  end

  -- Typed Move Colors 0.4.x normally detaches its own 2x2 battle selector
  -- whenever it sees a custom/transparent battle surface. Kanto in Motion's
  -- Modern lower panel owns that exact phase, so let KIM own the cursor grid
  -- too while leaving Typed Move Colors fully active in menus and in battles
  -- where KIM is disabled. This patches only Typed's published process-stable
  -- BattleState helper table; no Typed Move Colors files/options are changed.
  local function installTypedBattleLiteInputCompat()
    if not typedMoveColorsHandle() then return false end
    local okState, BattleState = pcall(require, "src.battle.BattleState")
    if not okState or type(BattleState) ~= "table" then return false end
    local patch = rawget(BattleState, "_typedMoveColorsInputPatch")
    if type(patch) ~= "table" or type(patch.detached) ~= "function" then
      return false
    end
    if patch._kantoInMotionDetached then return true end
    local originalDetached = patch.detached
    patch._kantoInMotionDetached = originalDetached
    patch.detached = function(battle, ...)
      if battle and battleLiteFullScreenActive() and battleModernUiActive(battle and battle.game,battle) then
        return false
      end
      return originalDetached(battle, ...)
    end
    return true
  end

  local function withTypedBattlePresentationSuppressed(game, fn)
    pcall(installTypedBattleLiteInputCompat)
    if not typedMoveColorsHandle() or not battleModernUiActive(game) then
      return fn()
    end
    local loader = game and game.mods
    if not loader then return fn() end
    loader.modOptions = loader.modOptions or {}
    local bucket = loader.modOptions.typed_move_colors
    local created = false
    if type(bucket) ~= "table" then bucket = {}; loader.modOptions.typed_move_colors = bucket; created = true end
    local had = rawget(bucket, "battle_colors") ~= nil
    local old = rawget(bucket, "battle_colors")
    local snapshot = {}
    for k, v in pairs(bucket) do snapshot[k] = v end
    if snapshot.battle_colors == nil then snapshot.battle_colors = true end
    if snapshot.layout == nil then snapshot.layout = "wide" end
    if snapshot.effect_hints == nil then snapshot.effect_hints = true end
    if snapshot.strength == nil then snapshot.strength = "bold" end
    if snapshot.opacity == nil then snapshot.opacity = "100" end
    if snapshot.text_only == nil then snapshot.text_only = false end
    game._kantoInMotionTypedMoveColors = snapshot
    -- KIM suppresses Typed Move Colors' detached selector while Modern UI owns
    -- the lower battle panel, but retain Typed's own effectiveness helper so
    -- KIM can mirror the exact strong/weak/immune hint instead of maintaining
    -- a second type chart. The helper lives on Typed's process-stable
    -- BattleState patch table and honors its MOVE EFFECT option.
    local effectHelper = nil
    do
      local okState, BattleState = pcall(require, "src.battle.BattleState")
      local patch = okState and type(BattleState) == "table"
        and rawget(BattleState, "_typedMoveColorsInputPatch") or nil
      if type(patch) == "table" and type(patch.effectIndicator) == "function" then
        effectHelper = patch.effectIndicator
      end
    end
    game._kantoInMotionTypedMoveEffectIndicator = effectHelper
    bucket.battle_colors = false
    local result = { pcall(fn) }
    if had then bucket.battle_colors = old else bucket.battle_colors = nil end
    if created and next(bucket) == nil then loader.modOptions.typed_move_colors = nil end
    game._kantoInMotionTypedMoveColors = nil
    game._kantoInMotionTypedMoveEffectIndicator = nil
    local ok = table.remove(result, 1)
    if not ok then error(result[1], 0) end
    return unpack(result)
  end

  -- -----------------------------------------------------------------------
  -- Battle Art-style 2D battle compositor
  -- -----------------------------------------------------------------------
  -- The Gen 6 plate owns the full renderer world surface. The stock 160x144
  -- battle state is retained as a transparent overlay so its Pokemon, move
  -- animations and lower menu remain authoritative and correctly aligned.
  -- Only the status HUD is extracted and snapped to the window edges.
  local battleSceneCanvas = nil
  -- Mobile catch retargeting can move native Pokeball OAM well outside the
  -- stock 160x144 source rectangle. Keep a padded scratch surface available
  -- only for those catch frames so the translated ball cannot be clipped.
  local battleSceneExpandedCanvas = nil
  local battleTrainerCanvas = nil
  local battleHudCanvas = nil
  local battleTextCanvas = nil
  local battleHudQuads = nil
  local battleHudShader = nil
  local battleHudShadowShader = nil

  local function finalViewportSize(viewport)
    local vw = tonumber(viewport and viewport.width)
    local vh = tonumber(viewport and viewport.height)
    if not (vw and vh and vw > 0 and vh > 0) then
      if love and love.graphics and type(love.graphics.getDimensions) == "function" then
        vw, vh = love.graphics.getDimensions()
      end
    end
    return tonumber(vw) or 160, tonumber(vh) or 144
  end

  local function battleUiViewportRect(game, viewport)
    if touchBattleOrientation(game) then
      -- Renderer:endFrame already reports the exact Playfield rect in the
      -- current GameViewport's LOVE-unit coordinate space. Prefer it over a
      -- second reconstruction so TouchSkin viewport moves and render.viewport
      -- captures are reflected immediately.
      local x = tonumber(viewport and viewport.viewX)
      local y = tonumber(viewport and viewport.viewY)
      local w = tonumber(viewport and viewport.viewWidth)
      local h = tonumber(viewport and viewport.viewHeight)
      if x and y and w and h and w > 0 and h > 0 then
        return x, y, w, h
      end
      local metrics=battleWorldMetrics()
      if metrics then
        return metrics.unitX or 0, metrics.unitY or 0,
          math.max(1,metrics.unitWidth or 1),
          math.max(1,metrics.unitHeight or 1)
      end
    end
    local vw,vh=finalViewportSize(viewport)
    return 0,0,vw,vh
  end

  local function currentBattleState(game)
    local stack = game and game.stack
    local states = stack and stack.states
    if type(states) == "table" then
      for i = #states, 1, -1 do
        local state = states[i]
        if type(state) == "table"
            and type(state.drawPicsLayer) == "function"
            and type(state.drawHUDs) == "function"
            and (state.isBattle == true or state.isBattleState == true
              or (state.player ~= nil and state.enemy ~= nil)) then
          return state
        end
      end
    end
    local top = stack and type(stack.top) == "function" and stack:top() or nil
    if type(top) == "table" and type(top.drawPicsLayer) == "function"
        and type(top.drawHUDs) == "function" then
      return top
    end
    return nil
  end

  -- While an in-battle Party or Bag flow is on top of BattleState, that
  -- child screen owns the whole UI. The fullscreen battle compositor must not
  -- repaint its trainer, battle text strip, or snapped HP/status bands over
  -- the child menu. Descendants (choice/summary/etc.) remain covered because
  -- the Party/Bag root stays in the stack below them.
  local partyMenuClass
  do
    local ok, cls = pcall(require, "src.ui.PartyMenu")
    if ok and type(cls) == "table" then partyMenuClass = cls end
  end

  local function battleChildMenuOpen(game, battle)
    local stack = game and game.stack
    local states = stack and stack.states
    if type(states) ~= "table" or type(battle) ~= "table" then return false end
    local battleIndex
    for i = #states, 1, -1 do
      if states[i] == battle then battleIndex = i break end
    end
    if not battleIndex or battleIndex >= #states then return false end
    for i = battleIndex + 1, #states do
      local state = states[i]
      if type(state) == "table" then
        local kind = rawget(state, "kind")
        if kind == "bag" or rawget(state, "__usefulBagKind") == "bag" then
          return true, "bag"
        end
        if partyMenuClass and getmetatable(state) == partyMenuClass then
          return true, "party"
        end
      end
    end
    return false
  end

  local function sizedBattleCanvas(slot, width, height)
    width=math.max(1,math.floor((tonumber(width) or 160)+0.5))
    height=math.max(1,math.floor((tonumber(height) or 144)+0.5))
    if slot and slot.getWidth and slot:getWidth()==width
        and slot:getHeight()==height then return slot end
    if not (love and love.graphics and type(love.graphics.newCanvas)=="function") then
      return nil
    end
    local ok,canvas=pcall(love.graphics.newCanvas,width,height)
    if not ok or not canvas then return nil end
    if canvas.setFilter then pcall(canvas.setFilter,canvas,"nearest","nearest") end
    return canvas
  end

  local function logicalCanvas(slot)
    return sizedBattleCanvas(slot,160,144)
  end

  local function battleOffsets(battle)
    local fx = battle and battle.fx
    local sx = (fx and fx.shakeX) or 0
    local sy = (fx and fx.shakeY) or 0
    if sx == 0 and sy == 0 and fx and fx.shake and fx.shake > 0 then
      sx = (battle.frame or 0) % 4 < 2 and 2 or -2
    end
    local slide = (battle.introSlide or 0) * 2
    return slide, sx, sy
  end

  local function captureBattleScene(battle, suppressPlayerTrainer, padX, padY)
    padX=math.max(0,math.floor((tonumber(padX) or 0)+0.5))
    padY=math.max(0,math.floor((tonumber(padY) or 0)+0.5))
    local sceneCanvas
    if padX>0 or padY>0 then
      battleSceneExpandedCanvas=sizedBattleCanvas(battleSceneExpandedCanvas,
        160+padX*2,144+padY*2)
      sceneCanvas=battleSceneExpandedCanvas
    else
      battleSceneCanvas=logicalCanvas(battleSceneCanvas)
      sceneCanvas=battleSceneCanvas
    end
    if not sceneCanvas then return nil end
    local g = love.graphics
    local previousCanvas = g.getCanvas and g.getCanvas() or nil
    local slide, sx, sy = battleOffsets(battle)
    g.push("all")
    local ok, err = pcall(function()
      g.setCanvas(sceneCanvas)
      g.origin()
      g.clear(0, 0, 0, 0)
      g.setShader()
      g.setColor(1, 1, 1, 1)
      if padX>0 or padY>0 then g.translate(padX,padY) end
      -- KRBA / Pokemon Essentials compatibility. Its Ember animation is
      -- authored entirely with additive cels (and several other moves use
      -- additive/subtractive particles). KIM, like Battle Art, captures the
      -- battle effect layer into a transparent intermediate canvas before
      -- compositing it over the fullscreen arena. Add/subtract RGB can vanish
      -- or composite incorrectly through that transparent carrier. Battle Art
      -- solves the same regression by carrying those particles as straight
      -- alpha only while its staged surface is active. Mirror that behavior
      -- here, scoped only to an active KRBA Essentials session; restore LÖVE's
      -- real blend function immediately afterward so all normal rendering is
      -- unchanged.
      local krsSession = battle.animPlayer and battle.animPlayer._krs
      local realSetBlendMode = g.setBlendMode
      local blendShimInstalled = false
      if krsSession and type(realSetBlendMode) == "function" then
        local okShim = pcall(function()
          g.setBlendMode = function(mode, alphaMode)
            if mode == "add" or mode == "subtract" then
              return realSetBlendMode("alpha", alphaMode or "alphamultiply")
            end
            return realSetBlendMode(mode, alphaMode)
          end
        end)
        blendShimInstalled = okShim
      end

      local oldShowPlayerBack,oldSendingOut
      if suppressPlayerTrainer and battle.showPlayerBack then
        -- The player trainer is captured separately below. Hiding only
        -- showPlayerBack would make drawPicsLayer fall through to the player's
        -- Pokemon, so also gate that fallback for this one scratch draw.
        oldShowPlayerBack,oldSendingOut=battle.showPlayerBack,battle.sendingOut
        battle.showPlayerBack=false
        battle.sendingOut=true
      end
      local okLayers, layerErr = pcall(function()
        if type(battle.drawPicsLayer) == "function" then
          battle:drawPicsLayer(slide, sx, sy, nil, true)
        end
      end)
      if oldShowPlayerBack~=nil then
        battle.showPlayerBack=oldShowPlayerBack
        battle.sendingOut=oldSendingOut
      end
      if okLayers then
        okLayers,layerErr=pcall(function()
          if type(battle.drawAnimLayer) == "function" then
            local colorized = type(battle.colorMode) == "function"
              and battle:colorMode() or false
            battle:drawAnimLayer(colorized)
          end
        end)
      end
      if blendShimInstalled then g.setBlendMode = realSetBlendMode end
      if not okLayers then error(layerErr, 0) end
      -- battle.overlay is documented as draw-only.  Replaying the chain onto
      -- this scratch canvas preserves compatible sparkles/custom effects that
      -- would otherwise remain trapped under the full-window Gen 6 backdrop.
      local okRuntime, Runtime = pcall(require, "src.mods.Runtime")
      if okRuntime and Runtime and type(Runtime.wantsHook) == "function"
          and Runtime.wantsHook("battle.overlay")
          and type(Runtime.call) == "function" then
        Runtime.call("battle.overlay", function() end, battle)
      end
    end)
    g.pop()
    if previousCanvas then g.setCanvas(previousCanvas) else g.setCanvas() end
    if not ok then
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("Battle Lite scene capture failed: " .. tostring(err))
      end
      return nil
    end
    return sceneCanvas, slide, padX, padY
  end

  -- Capture the player trainer by itself. v8.6.27 reconstructed the complete
  -- native pics layer and could present the player trainer a second time when
  -- another compatible battle layer also retained it. Keeping the trainer in
  -- its own transparent capture gives KIM exactly one authoritative copy and
  -- also lets Gen1Recomp's public player.sprite hook select the portrait.
  local function captureBattleTrainer(battle)
    if not (battle and battle.showPlayerBack and battle.playerBackPic
        and type(battle.drawPicsLayer)=="function") then return nil end
    battleTrainerCanvas=logicalCanvas(battleTrainerCanvas)
    if not battleTrainerCanvas then return nil end
    local g=love.graphics
    local previousCanvas=g.getCanvas and g.getCanvas() or nil
    local slide,sx,sy=battleOffsets(battle)
    local choice=mod.options:get("battleTrainerSprite") or "rom"
    local customFrame=choice~="rom" and battleTrainerFrameForBattle(battle,choice) or nil
    g.push("all")
    local ok,err=pcall(function()
      g.setCanvas(battleTrainerCanvas)
      g.origin()
      g.clear(0,0,0,0)
      g.setShader()
      g.setColor(1,1,1,1)
      if customFrame then
        -- Battle Art's player-trainer atlases are authored as native logical
        -- battle pixels at scale 1. Match BattleState.backPlacement for a
        -- non-matted trainer pic: left slot x=8, feet at y=96, then compose
        -- the engine's intro slide/shake and SlideTrainerPicOffScreen offset.
        local off=0
        if type(battle.picOffset)=="function" then
          local gotOk,got=pcall(battle.picOffset,battle,"back")
          if gotOk then off=tonumber(got) or 0 end
        end
        local x=8+slide+sx+off
        local y=96-customFrame:getHeight()+sy
        g.draw(customFrame,x,y)
      else
        battle:drawPicsLayer(slide,sx,sy,"player",true)
      end
    end)
    g.pop()
    if previousCanvas then g.setCanvas(previousCanvas) else g.setCanvas() end
    if not ok then
      if mod.log and type(mod.log.warn)=="function" then
        mod.log:warn("Battle Lite trainer capture failed: "..tostring(err))
      end
      return nil
    end
    return battleTrainerCanvas
  end

  -- Rebuild only the transparent native battle pieces after render.compose
  -- removes Gen1Recomp's complete 160x144 UI canvas. This preserves trainer
  -- intro/send-out art and native fallback animation cels without ever
  -- reintroducing the white battle paper seen in the user's video. Settled
  -- Pokemon remain hidden by the drawPicsLayer bridge because KIM already
  -- renders the high-resolution battlers directly into the world canvas.
  local function drawNativeBattleOverlay(battle, viewport)
    local scene
    local ox,oy,vw,vh=battleUiViewportRect(battle and battle.game,viewport)
    local orient=touchBattleOrientation(battle and battle.game)
    local g=love.graphics
    local x,y,sx,sy
    local portraitStageBottom,portraitDpiY

    if orient=="portrait" then
      -- Trainer/send-out sprites live in the native transparent 160x144 pics
      -- layer. The arena itself is width-contained to a 1920x950 stage in
      -- portrait, so fitting that native layer to the whole tall phone view
      -- puts Red in the black space above the field. Fit the native overlay
      -- inside the SAME contained stage instead, on an integer physical-pixel
      -- rung so trainer pixels stay crisp.
      local aspect=1920/950
      local stageW=vw
      local stageH=stageW/aspect
      if stageH>vh then stageH=vh; stageW=stageH*aspect end
      local stageX=ox+(vw-stageW)*0.5
      local dpiX=tonumber(viewport and viewport.dpiX) or 1
      local dpiY=tonumber(viewport and viewport.dpiY) or 1
      if not (dpiX>1e-6) then dpiX=1 end
      if not (dpiY>1e-6) then dpiY=1 end
      local world=battleWorldMetrics()
      local liftPx=world and mobileScreenPositionLiftPx(battle and battle.game,
        world.width,world.height) or 0
      local stageY=oy+(vh-stageH)*0.5-liftPx/dpiY
      portraitStageBottom=stageY+stageH
      portraitDpiY=dpiY
      local pixelScale=math.max(1,math.floor(math.min(
        stageW*dpiX/160,stageH*dpiY/144)))
      sx,sy=pixelScale/dpiX,pixelScale/dpiY
      x=stageX+(stageW-160*sx)*0.5
      y=stageY+(stageH-144*sy)*0.5
    else
      local scale=math.max(1,math.floor(math.min(vw/160,vh/144)))
      x=math.floor(ox+(vw-160*scale)*0.5+0.5)
      local dpiY=tonumber(viewport and viewport.dpiY) or 1
      if not (dpiY>1e-6) then dpiY=1 end
      local world=battleWorldMetrics()
      local liftPx=world and mobileScreenPositionLiftPx(battle and battle.game,
        world.width,world.height) or 0
      y=math.floor(oy+vh*0.055-liftPx/dpiY+0.5)
      sx,sy=scale,scale
    end

    -- Pokeball catch animations are authored for the stock 160x144 enemy
    -- slot, while KIM's animated enemy is drawn directly at final resolution.
    -- Prepare a temporary native-pixel translation before capturing the anim
    -- layer so the toss keeps its original launch point but finishes on the
    -- actual KIM enemy battler. The module clears the shift immediately after
    -- the scratch capture; ordinary move animations never see it.
    if mod._kantoInMotionPokeballTargetFix
        and type(mod._kantoInMotionPokeballTargetFix.prepare)=="function" then
      pcall(mod._kantoInMotionPokeballTargetFix.prepare,
        mod._kantoInMotionPokeballTargetFix,battle,x,y,sx,sy)
    end

    -- On Android/iOS the fullscreen enemy can sit outside the stock 160x144
    -- overlay rectangle. v8.6.59 translated the native ball inside that exact
    -- 160x144 scratch canvas, so a valid mobile retarget could clip every ball
    -- frame before composition. Expand only this temporary capture by the full
    -- prepared catch offset, then subtract the padding when compositing. Other
    -- native scene pixels therefore stay at the exact same screen coordinates.
    local catchPadX,catchPadY=0,0
    local ballShift=battle and battle._kantoInMotionBallAnimShift
    if orient and type(ballShift)=="table" then
      catchPadX=math.min(512,math.ceil(math.abs(tonumber(ballShift.dx) or 0)+32))
      catchPadY=math.min(512,math.ceil(math.abs(tonumber(ballShift.dy) or 0)+32))
    end
    local scenePadX,scenePadY
    scene,_,scenePadX,scenePadY=captureBattleScene(
      battle,true,catchPadX,catchPadY)
    if mod._kantoInMotionPokeballTargetFix
        and type(mod._kantoInMotionPokeballTargetFix.finish)=="function" then
      pcall(mod._kantoInMotionPokeballTargetFix.finish,
        mod._kantoInMotionPokeballTargetFix,battle)
    end
    if not scene then return false end

    g.push("all")
    g.origin()
    g.setShader()
    g.setColor(1,1,1,1)
    local sceneX=x-(tonumber(scenePadX) or 0)*sx
    local sceneY=y-(tonumber(scenePadY) or 0)*sy
    g.draw(scene,sceneX,sceneY,0,sx,sy)
    local trainer=captureBattleTrainer(battle)
    if trainer then
      -- Anchor the trainer to the battle dialog that is actually visible.
      -- With mobile touch controls enabled v8.6.26 deliberately yields the
      -- lower UI to Gen1Recomp's native 48-row battle strip, so Modern UI is
      -- not an authoritative anchor here. In portrait KIM redraws that native
      -- strip at the contained battlefield edge; in landscape the preserved
      -- strip keeps Renderer:endFrame's native gameY/gameHeight placement.
      local dpiY=tonumber(viewport and viewport.dpiY) or portraitDpiY or 1
      if not (dpiY>1e-6) then dpiY=1 end
      local dialogTop
      if orient=="portrait" and portraitStageBottom then
        dialogTop=portraitStageBottom+3/dpiY
      else
        local gameY=tonumber(viewport and viewport.gameY)
        local gameH=tonumber(viewport and viewport.gameHeight)
        if gameY and gameH and gameH>0 then
          dialogTop=gameY+gameH*(96/144)
        else
          dialogTop=y+96*sy
        end
      end
      local _,_,shakeY=battleOffsets(battle)
      local trainerBottomLogical=96+(tonumber(shakeY) or 0)
      local trainerY=dialogTop-6/dpiY-trainerBottomLogical*sy
      -- Keep the accepted trainer/dialog Y and the smaller KIM trainer scale.
      -- Only align its X endpoint to the host/native trainer's horizontal
      -- position.  That larger native copy is scrubbed in render.compose; its
      -- placement is used here only as the X reference requested by the user.
      local trainerX=x-2*sx
      local renderer=battle and battle.game and battle.game.renderer
      if renderer and type(renderer.frameRects)=="function" then
        local okRects,rects=pcall(renderer.frameRects,renderer)
        if okRects and type(rects)=="table"
            and tonumber(rects.uox) and tonumber(rects.Ux) then
          local slideX,shakeX=battleOffsets(battle)
          local off=0
          if type(battle.picOffset)=="function" then
            local okOff,got=pcall(battle.picOffset,battle,"back")
            if okOff then off=tonumber(got) or 0 end
          end
          local logicalTrainerX=8+(tonumber(slideX) or 0)
            +(tonumber(shakeX) or 0)+off
          local nativeContentX=tonumber(rects.uox)
            +logicalTrainerX*tonumber(rects.Ux)
          trainerX=nativeContentX-logicalTrainerX*sx
        end
      end
      g.draw(trainer,trainerX,trainerY,0,sx,sy)
    end
    g.pop()
    return true
  end

  -- Capture only the native Gen 1 HUD glyph/tile layer.  drawHUDs itself never
  -- paints the white battle paper, so the resulting texture can sit directly
  -- over the photographic/painted Gen 6 arena with no opaque status boxes.
  local function captureBattleHud(battle, slide)
    battleHudCanvas = logicalCanvas(battleHudCanvas)
    if not battleHudCanvas then return nil end
    local g = love.graphics
    local previousCanvas = g.getCanvas and g.getCanvas() or nil
    local ownColorMode = rawget(battle, "colorMode")
    g.push("all")
    local ok, err = pcall(function()
      g.setCanvas(battleHudCanvas)
      g.origin()
      g.clear(0, 0, 0, 0)
      g.setShader()
      g.setColor(1, 1, 1, 1)
      -- Direct-colour HP fills are needed here because this scratch texture is
      -- not followed by the engine's zone recolour pass.
      battle.colorMode = function() return false end
      battle._kantoInMotionHudCapture = true
      battle:drawHUDs(slide or 0)
    end)
    g.pop()
    battle._kantoInMotionHudCapture = nil
    if ownColorMode ~= nil then battle.colorMode = ownColorMode
    else battle.colorMode = nil end
    if previousCanvas then g.setCanvas(previousCanvas) else g.setCanvas() end
    if not ok then
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("Battle Lite HUD capture failed: " .. tostring(err))
      end
      return nil
    end
    return battleHudCanvas
  end

  local BATTLE_HUD_SHADER = [[
    uniform float inverted;
    bool gaugePixel(vec4 p, vec2 tc) {
      vec2 px = tc * vec2(160.0, 144.0);
      bool gauge = (px.x >= 32.0 && px.x < 80.0
                    && px.y >= 16.0 && px.y < 24.0)
                || (px.x >= 96.0 && px.x < 144.0
                    && px.y >= 72.0 && px.y < 80.0);
      float hi = max(p.r, max(p.g, p.b));
      float lo = min(p.r, min(p.g, p.b));
      return gauge && (hi - lo) > 0.04 * p.a;
    }
    vec3 vividGauge(vec4 p) {
      if (p.g > p.r + 0.08 * p.a && p.g > p.b)
        return vec3(0.20, 0.92, 0.32) * p.a;
      if (p.r > p.g * 1.35)
        return vec3(1.00, 0.16, 0.10) * p.a;
      return vec3(1.00, 0.82, 0.05) * p.a;
    }
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
      vec4 p = Texel(tex, tc);
      float luma = dot(p.rgb, vec3(0.299, 0.587, 0.114));
      if (gaugePixel(p, tc)) {
        p.rgb = vividGauge(p);
      } else if (inverted > 0.5 && p.a > 0.0 && luma <= 0.35 * p.a) {
        p.rgb = vec3(p.a);
      }
      return p * color;
    }
  ]]

  local BATTLE_HUD_SHADOW = [[
    uniform float inverted;
    bool gaugePixel(vec4 p, vec2 tc) {
      vec2 px = tc * vec2(160.0, 144.0);
      bool gauge = (px.x >= 32.0 && px.x < 80.0
                    && px.y >= 16.0 && px.y < 24.0)
                || (px.x >= 96.0 && px.x < 144.0
                    && px.y >= 72.0 && px.y < 80.0);
      float hi = max(p.r, max(p.g, p.b));
      float lo = min(p.r, min(p.g, p.b));
      return gauge && (hi - lo) > 0.04 * p.a;
    }
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
      vec4 p = Texel(tex, tc);
      float luma = dot(p.rgb, vec3(0.299, 0.587, 0.114));
      float a = (p.a > 0.0 && luma <= 0.35 * p.a && !gaugePixel(p, tc))
        ? p.a * (inverted > 0.5 ? 0.72 : 0.38) : 0.0;
      vec3 shade = inverted > 0.5 ? vec3(0.0) : vec3(1.0);
      return vec4(shade, a) * color;
    }
  ]]

  local function getBattleHudShaders()
    if battleHudShader == nil and love and love.graphics
        and type(love.graphics.newShader) == "function" then
      local ok, shader = pcall(love.graphics.newShader, BATTLE_HUD_SHADER)
      battleHudShader = ok and shader or false
    end
    if battleHudShadowShader == nil and love and love.graphics
        and type(love.graphics.newShader) == "function" then
      local ok, shader = pcall(love.graphics.newShader, BATTLE_HUD_SHADOW)
      battleHudShadowShader = ok and shader or false
    end
    return battleHudShader ~= false and battleHudShader or nil,
      battleHudShadowShader ~= false and battleHudShadowShader or nil
  end

  local function hudQuads()
    if battleHudQuads then return battleHudQuads end
    if not (love and love.graphics and type(love.graphics.newQuad) == "function") then
      return nil
    end
    battleHudQuads = {
      enemy = love.graphics.newQuad(0, 0, 160, 48, 160, 144),
      player = love.graphics.newQuad(0, 48, 160, 48, 160, 144),
    }
    return battleHudQuads
  end

  local function drawBattleArtHud(battle, viewport, slide)
    local layer = captureBattleHud(battle, slide)
    local quads = layer and hudQuads() or nil
    if not (layer and quads) then return false end
    local ox,oy,vw,vh=battleUiViewportRect(battle and battle.game,viewport)

    -- Match Battle Art's physical-pixel HUD rung even on Android high-DPI
    -- windows. In v8.6.26 the arena used framebuffer pixels correctly, but the
    -- HUD SCALE option still derived its integer rung from LOVE logical units;
    -- SCALED therefore collapsed to 1x on phones. Compute the rung in physical
    -- pixels, then convert its positions/scales back to LOVE units for this
    -- screen-space render.hud pass. Desktop dpi=1 remains unchanged.
    local touch=touchBattleOrientation(battle and battle.game)
    local dpiX=tonumber(viewport and viewport.dpiX) or 1
    local dpiY=tonumber(viewport and viewport.dpiY) or 1
    if not (dpiX>1e-6) then dpiX=1 end
    if not (dpiY>1e-6) then dpiY=1 end
    local geo
    local hsX,hsY
    if touch then
      local metrics=battleWorldMetrics()
      local liftPx=metrics and mobileScreenPositionLiftPx(battle and battle.game,
        metrics.width,metrics.height) or 0
      geo=battleHudGeometry(vw*dpiX,vh*dpiY,liftPx,battle and battle.game)
      hsX,hsY=geo.hudScale/dpiX,geo.hudScale/dpiY
    else
      geo=battleHudGeometry(vw,vh)
      hsX,hsY=geo.hudScale,geo.hudScale
      dpiX,dpiY=1,1
    end

    -- Battle Art HUD bands, using the same physical geometry exported through
    -- dramaticShapeShot. QOL therefore stays attached in OG and SCALED modes.
    local enemyBandX = ox + geo.enemyBandX/dpiX
    local playerBandX = ox + geo.playerBandX/dpiX
    local enemyBandY = oy + geo.enemyBandY/dpiY
    local playerBandY = oy + geo.playerBandY/dpiY
    local inverted = (mod.options:get("battleArenaFill") ~= "white"
      and mod.options:get("battleHudColor") == "inverted") and 1 or 0
    local shader, shadow = getBattleHudShaders()
    local g = love.graphics
    g.push("all")
    g.origin()
    g.setColor(1, 1, 1, 1)
    if shadow then
      g.setShader(shadow)
      pcall(shadow.send, shadow, "inverted", inverted)
      g.draw(layer, quads.enemy, enemyBandX + hsX, enemyBandY + hsY, 0, hsX, hsY)
      g.draw(layer, quads.player, playerBandX + hsX, playerBandY + hsY, 0, hsX, hsY)
    end
    if shader then
      g.setShader(shader)
      pcall(shader.send, shader, "inverted", inverted)
    else
      g.setShader()
    end
    g.draw(layer, quads.enemy, enemyBandX, enemyBandY, 0, hsX, hsY)
    g.draw(layer, quads.player, playerBandX, playerBandY, 0, hsX, hsY)
    g.setShader()
    g.pop()
    return true
  end

  local function captureBattleText(battle)
    battleTextCanvas = logicalCanvas(battleTextCanvas)
    if not battleTextCanvas or type(battle.drawTextArea) ~= "function" then return nil end
    local g = love.graphics
    local previousCanvas = g.getCanvas and g.getCanvas() or nil
    local oldScrollPx = rawget(battle, "scrollPx")
    g.push("all")
    local ok, err = pcall(function()
      g.setCanvas(battleTextCanvas)
      g.origin()
      g.clear(0, 0, 0, 0)
      g.setShader()
      g.setColor(1, 1, 1, 1)
      battle:drawTextArea()
    end)
    g.pop()
    battle.scrollPx = oldScrollPx
    if previousCanvas then g.setCanvas(previousCanvas) else g.setCanvas() end
    if not ok then
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("Battle Lite text capture failed: " .. tostring(err))
      end
      return nil
    end
    return battleTextCanvas
  end

  -- Final-window rectangle occupied by the mobile battle command/dialog
  -- surface. Modern UI consumes this exact rectangle so switching from the
  -- native strip to Modern UI does not disturb the accepted mobile layout.
  local function mobileBattleDialogRect(battle, viewport)
    local orient=touchBattleOrientation(battle and battle.game)
    if not orient then return nil end
    local ox,oy,vw,vh=battleUiViewportRect(battle and battle.game,viewport)
    if orient=="portrait" then
      local dpiX=tonumber(viewport and viewport.dpiX) or 1
      local dpiY=tonumber(viewport and viewport.dpiY) or 1
      if not (dpiX>1e-6) then dpiX=1 end
      if not (dpiY>1e-6) then dpiY=1 end
      local world=battleWorldMetrics()
      if world then
        local liftPx=mobileScreenPositionLiftPx(battle and battle.game,
          world.width,world.height)
        local geo=battleHudGeometry(world.width,world.height,liftPx,
          battle and battle.game)
        local stage=geo.portraitStage or mobilePortraitStageRectPx(
          battle and battle.game,world.width,world.height)
        local desiredY=(stage and stage.bottom or 0)+3
        local scalePx=math.max(1,math.floor(world.width/160))
        local available=math.max(48,world.height-desiredY)
        scalePx=math.max(1,math.min(scalePx,math.floor(available/48)))
        local x=ox+(world.width-160*scalePx)*0.5/dpiX
        local y=oy+desiredY/dpiY
        return {x=x,y=y,w=160*scalePx/dpiX,h=48*scalePx/dpiY,
          orientation=orient}
      end
    end
    local scale=math.min(vw/160,vh/144)
    local x=math.floor(ox+(vw-160*scale)*0.5+0.5)
    local dpiY=tonumber(viewport and viewport.dpiY) or 1
    if not (dpiY>1e-6) then dpiY=1 end
    local world=battleWorldMetrics()
    local liftPx=world and mobileScreenPositionLiftPx(battle and battle.game,
      world.width,world.height) or 0
    local y=math.floor(oy+vh-48*scale-liftPx/dpiY+0.5)
    return {x=x,y=y,w=160*scale,h=48*scale,orientation=orient}
  end

  local function drawNativeBattleText(battle, viewport)
    local layer = captureBattleText(battle)
    if not layer then return false end
    local ox,oy,vw,vh=battleUiViewportRect(battle and battle.game,viewport)
    local orient=touchBattleOrientation(battle and battle.game)
    local x,y,sx,sy
    if orient=="portrait" then
      local dpiX=tonumber(viewport and viewport.dpiX) or 1
      local dpiY=tonumber(viewport and viewport.dpiY) or 1
      if not (dpiX>1e-6) then dpiX=1 end
      if not (dpiY>1e-6) then dpiY=1 end
      local world=battleWorldMetrics()
      if world then
        local liftPx=mobileScreenPositionLiftPx(battle and battle.game,
          world.width,world.height)
        local geo=battleHudGeometry(world.width,world.height,liftPx,
          battle and battle.game)
        local stage=geo.portraitStage or mobilePortraitStageRectPx(
          battle and battle.game,world.width,world.height)
        -- Match the portrait mock: the native command/dialog strip begins
        -- immediately below the contained battlefield. The player HUD now
        -- overlaps the field above, so it must no longer push the dialog down.
        local desiredY=(stage and stage.bottom or 0)+3
        local scalePx=math.max(1,math.floor(world.width/160))
        local available=math.max(48,world.height-desiredY)
        scalePx=math.max(1,math.min(scalePx,math.floor(available/48)))
        x=ox+(world.width-160*scalePx)*0.5/dpiX
        y=oy+desiredY/dpiY
        sx,sy=scalePx/dpiX,scalePx/dpiY
      end
    end
    if not x then
      local scale = math.min(vw / 160, vh / 144)
      x = math.floor(ox+(vw - 160 * scale) * 0.5 + 0.5)
      local liftUnits=0
      if orient then
        local dpiY=tonumber(viewport and viewport.dpiY) or 1
        if not (dpiY>1e-6) then dpiY=1 end
        local world=battleWorldMetrics()
        local liftPx=world and mobileScreenPositionLiftPx(battle and battle.game,
          world.width,world.height) or 0
        liftUnits=liftPx/dpiY
      end
      y = math.floor(oy+vh - 48 * scale-liftUnits + 0.5)
      sx,sy=scale,scale
    end
    local quad = love.graphics.newQuad(0, 96, 160, 48, 160, 144)
    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(layer, quad, x, y, 0, sx, sy)
    love.graphics.pop()
    return true
  end

  local function drawFullscreenBattleBase(game, battle, viewport)
    if not (battleLiteFullScreenActive() and battle and love and love.graphics) then
      return false, nil, nil
    end
    local image = gen6Image(game, battle)
    if not image then return false, nil, nil end
    local scene, slide = captureBattleScene(battle)
    if not scene then return false, nil, nil end
    local vw, vh = finalViewportSize(viewport)
    -- Keep the captured Gen 1 battler/effect layer on an integer pixel rung.
    -- This preserves nearest-neighbour sprite pixels and avoids the fractional
    -- resampling that made large animated atlases look clipped/unstable in v2.
    local sceneScale = math.max(1, math.floor(math.min(vw / 160, vh / 144)))
    local sceneX = math.floor((vw - 160 * sceneScale) * 0.5 + 0.5)
    -- Lift the source 160x144 composition slightly so the player feet at y=96
    -- sit near the lower third of a 16:9 battlefield rather than on the screen
    -- edge.  This keeps both full sprites visible while the Gen 6 plate itself
    -- continues all the way behind Modern UI to every window edge.
    local sceneY = math.floor(vh * 0.055 + 0.5)
    local function redraw()
      local g = love.graphics
      g.push("all")
      g.origin()
      g.setShader()
      g.setColor(1, 1, 1, 1)
      drawCover(image, 0, 0, vw, vh, 0.30)
      g.setColor(1, 1, 1, 1)
      g.draw(scene, sceneX, sceneY, 0, sceneScale, sceneScale)
      local fx = battle.fx
      local krbaSession = battle.animPlayer and battle.animPlayer._krs
      -- KIM previously expanded Gen1Recomp's tiny/native battle hit flash into
      -- an 85%-opaque white rectangle over the entire final-resolution arena.
      -- KRBA already owns the move's authored flashes/planes, so that extra
      -- fullscreen native flash becomes a duplicate and looks like a broken
      -- white-screen frame. Preserve the native flash only for fallback/native
      -- animations that are not currently being rendered by KRBA.
      if not krbaSession and fx and fx.flash and fx.flash > 0
          and (battle.frame or 0) % 4 < 2 then
        g.setColor(1, 1, 1, 0.85)
        g.rectangle("fill", 0, 0, vw, vh)
      end
      g.pop()
    end
    redraw()
    return true, slide, redraw
  end

  if mod.hooks and type(mod.hooks.wrap) == "function" then
    -- Battle Art 1.9.8 removes the stock battle paper BEFORE the renderer
    -- composites it: BattleState:draw marks the frame, then the renderer's UI
    -- canvas is made transparent while it is still an offscreen source. This
    -- is the important difference from v4, which tried to repaint over the
    -- already-finished centered composite in render.hud and therefore could
    -- not remove it.
    --
    -- Use a lower priority than the integrated Modern UI compose wrapper so
    -- Modern UI can inspect/capture the untouched native source first. On the
    -- unwind, this wrapper clears the exact ctx.uiCanvas that the engine would
    -- otherwise letterbox into the final window. The fullscreen Gen6 arena,
    -- animated battlers, Battle Art HUD and Modern commands are all redrawn
    -- later in render.hud from their own sources.
    -- v8.6.16 deliberately clears the finished native battle UI canvas here.
    -- KIM now owns the arena, high-resolution battlers and KRBA wide effects;
    -- the few native pieces we still need are reconstructed transparently in
    -- render.hud instead of compositing the complete 160x144 battle surface.
    mod.hooks:wrap("render.compose", function(nextFn, renderer, ctx)
      local result={pcall(nextFn,renderer,ctx)}
      local ok=table.remove(result,1)
      if not ok then error(result[1],0) end
      -- Prefer the BattleState marker published during its draw, but fall back
      -- to the live stack.  On mobile the native intro/dialogue layer can be
      -- composed while a transparent battle child is on top, which previously
      -- left the host's larger trainer + dialogue visible underneath KIM's
      -- reconstructed pair.  Party/Bag remain explicit full-screen owners and
      -- are never scrubbed here.
      local battle=pendingFullscreenBattle
      local composeGame=nil
      do
        local okGame,Game=pcall(require,"src.core.Game")
        if okGame then composeGame=Game end
      end
      if not battle and composeGame then battle=currentBattleState(composeGame) end
      local childMenuOpen=battle and composeGame
        and battleChildMenuOpen(composeGame,battle) or false
      if battle and not childMenuOpen and battleLiteFullScreenActive()
          and ctx and ctx.uiCanvas and love and love.graphics then
        -- Battle Art-style ownership: Modern UI has already had a chance to
        -- inspect/capture the untouched source (priority 100). Now remove the
        -- entire native battle canvas before Gen1Recomp can scale it over the
        -- fullscreen arena. Transparent trainer/native-effect pieces are
        -- reconstructed in render.hud from drawPicsLayer/drawAnimLayer only.
        love.graphics.push("all")
        love.graphics.setCanvas(ctx.uiCanvas)
        local touchOrient=touchBattleOrientation(battle.game)
        local modernLower=battleModernUiActive(battle.game,battle)
        if touchOrient~="portrait" and not modernLower then
          -- Native ownership fallback. When integrated Modern UI is OFF, keep
          -- Gen1Recomp's real bottom 48-row command/move/message strip alive on
          -- desktop and mobile landscape. KIM still removes the upper 96 rows
          -- because its fullscreen arena + Battle Art-style HP/status HUD own
          -- those surfaces. Portrait is redrawn separately at its safe Y.
          local cw,ch=ctx.uiCanvas:getDimensions()
          love.graphics.setBlendMode("replace","premultiplied")
          love.graphics.setColor(0,0,0,0)
          love.graphics.rectangle("fill",0,0,cw,ch*(96/144))
        else
          -- Modern UI owns the lower surface, or portrait needs its custom
          -- vertical stack. Remove the source strip and let the appropriate
          -- final-window presenter draw it later.
          love.graphics.clear(0,0,0,0)
        end
        love.graphics.pop()
      end
      return unpack(result)
    end, 50)

    -- Modern UI owns the lower command/message layer when selected.  The
    -- source text box is not needed in that mode and would otherwise update
    -- underneath the final-window compositor.
    mod.hooks:wrap("battle.bottom_ui_visible", function(nextFn, state)
      if battleLiteFullScreenActive() and battleModernUiActive(state and state.game,state) then
        if state then state._kantoInMotionBottomUiSuppressed = true end
        return false
      end
      if state then state._kantoInMotionBottomUiSuppressed = nil end
      return nextFn(state)
    end, 20000)

    -- The Battle Art-style HUD is Kanto in Motion's one HP/status renderer.
    -- Hide the source copy while Battle Lite owns battle presentation, but
    -- briefly fail open while captureBattleHud redraws those exact native
    -- glyphs into its transparent scratch texture.
    mod.hooks:wrap("battle.status_hud_visible", function(nextFn, state)
      if state and state._kantoInMotionHudCapture then return true end
      if battleLiteHudActive() then
        if state then state._kantoInMotionStatusHudSuppressed = true end
        return false
      end
      if state then state._kantoInMotionStatusHudSuppressed = nil end
      return nextFn(state)
    end, 20000)

    -- Final-window battle composition.  Draw the arena and source battle pixels
    -- first, let downstream Modern UI paint its command/move/message panels,
    -- then place the Battle-Art-style native Gen 1 HUD above everything.
    mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
      local battle = currentBattleState(game)
      local active = battle and battleLiteFullScreenActive() or false
      if not battle or not battleSystemEnabled() or externalBattleSceneOwnerRegistered() then
        restoreBattleLayout(game)
      elseif battleSystemEnabled() and not externalBattleSceneOwnerRegistered() then
        forceBattleLayoutOG(game)
      end
      if battle then battle._kantoInMotionBattleLite = active and true or nil end
      if game then game._kantoInMotionFullscreenBattle = active and true or nil end

      -- render.compose removed the complete native 160x144 battle surface.
      -- Put back only its transparent trainer/send-out/native-fallback pieces
      -- before downstream Modern UI paints the lower panel. KRBA itself is
      -- already drawn into the fullscreen world canvas for KRS and GEN6.
      -- Party/Bag child screens are full UI owners: never reconstruct battle
      -- furniture over them. This fixes the clipped/incomplete Pokemon menu
      -- and HP/status bands appearing on top of both Pokemon and Item screens.
      local childMenuOpen = active and battleChildMenuOpen(game, battle) or false
      if battle then
        battle._kantoInMotionMobileDialogRect = active
          and mobileBattleDialogRect(battle,viewport) or nil
        -- Publish the exact mobile portrait battlefield rectangle in LOVE/window
        -- units. Modern UI must use this instead of its own responsive arena
        -- estimate: Android KRS placement is authored in physical-pixel space
        -- after TouchSkin/Playfield cutouts and DPI conversion.
        battle._kantoInMotionMobileStageRect = nil
        if active and touchBattleOrientation(battle.game)=="portrait" then
          local world=battleWorldMetrics()
          local stage=world and mobilePortraitStageRectPx(
            battle.game,world.width,world.height) or nil
          if world and stage then
            local dx=tonumber(world.dpiX) or 1
            local dy=tonumber(world.dpiY) or 1
            if not (dx>1e-6) then dx=1 end
            if not (dy>1e-6) then dy=1 end
            battle._kantoInMotionMobileStageRect={
              x=(tonumber(world.unitX) or 0)+(tonumber(stage.x) or 0)/dx,
              y=(tonumber(world.unitY) or 0)+(tonumber(stage.y) or 0)/dy,
              w=(tonumber(stage.width) or 0)/dx,
              h=(tonumber(stage.height) or 0)/dy,
              bottom=(tonumber(world.unitY) or 0)+(tonumber(stage.bottom) or 0)/dy,
              orientation="portrait",
            }
          end
        end
      end
      if active and not childMenuOpen then
        pcall(drawNativeBattleOverlay,battle,viewport)
        if touchBattleOrientation(battle and battle.game)=="portrait"
            and not battleModernUiActive(game,battle) then
          -- Native fallback only. When Modern UI is active it owns this exact
          -- rectangle and the classic portrait command/dialog strip stays gone.
          pcall(drawNativeBattleText,battle,viewport)
        end
      end

      local result = { pcall(function()
        return withTypedBattlePresentationSuppressed(game,
          function() return nextFn(game, viewport) end)
      end) }

      if active and not childMenuOpen and battleLiteHudActive() then
        drawBattleArtHud(battle, viewport, select(1, battleOffsets(battle)))
      end

      if pendingFullscreenBattle == battle then pendingFullscreenBattle = nil end
      if game then game._kantoInMotionFullscreenBattle = nil end
      if battle then
        battle._kantoInMotionMobileDialogRect = nil
        battle._kantoInMotionMobileStageRect = nil
      end
      if battle and not active then battle._kantoInMotionBattleLite = nil end
      local ok = table.remove(result, 1)
      if not ok then error(result[1], 0) end
      return unpack(result)
    end, 20000)
  end


  -- Colosseum Inspired UI can expose a small portrait-provider contract.
  -- Prefer that contract when present because Colosseum deliberately owns its
  -- final portrait composition and may resolve Battle Art before the engine
  -- pokemon.sprite seam. Older/unpatched Colosseum builds still benefit from
  -- the standard bridge above whenever they use the normal resolved-sprite
  -- pipeline.
  local function installColosseumAnimationAdapter()
    local handle = mod.find and mod.find("colosseum_ui_overhaul") or nil
    local contract = handle and type(handle.exports) == "table"
      and handle.exports.portraitProvider or nil
    if not (type(contract) == "table"
        and tonumber(contract.apiVersion or 0) >= 1
        and type(contract.setProvider) == "function") then
      return false
    end

    local function provider(_, mon, kind)
      if mod.options:get("enabled") == false or type(mon) ~= "table" or not mon.species then
        return nil
      end
      kind = tostring(kind or ""):lower()
      if not FRAME_BRIDGE_KINDS[kind] then return nil end
      local front, generation, species, shiny = bridgeFront(
        mon.species, selectedGeneration(), mon)
      if not front then return nil end
      local image = renderPresentationFrame(front, generation, species, currentFrame(front),
        "front", shiny and "shiny" or "normal", true)
      if not image then return nil end
      return image, { trueColor = true, kantoInMotion = true }
    end

    local ok, accepted = pcall(contract.setProvider, provider)
    if not ok or accepted == false then return false end
    if mod.log and type(mod.log.info) == "function" then
      mod.log:info("Colosseum UI animated portrait provider connected")
    end
    return true
  end

  pcall(installColosseumAnimationAdapter)


  -- Vanilla Gen1Recomp Summary and Pokedex entry pages cache their image once
  -- when the screen opens. Refresh that image with our current animation frame
  -- immediately before the native draw. Gen1 Modern UI consumes getSprite()
  -- directly, so this path is only visible when the stock UI owns the screen.
  local function patchVanillaScreens()
    if IS_GEN2 then return end
    local okSummary, SummaryMenu = pcall(require, IS_GEN2 and "src.ui.gen2.SummaryMenu" or "src.ui.SummaryMenu")
    if okSummary and type(SummaryMenu) == "table" then
      -- Seed the stock status screen with an animated frame when it opens.
      -- This also prevents a blank portrait if another renderer calls the
      -- object before its first normal draw pass.
      if type(SummaryMenu.new) == "function" and not SummaryMenu._animatedMenuPokemonNew then
        local originalNew = SummaryMenu.new
        SummaryMenu._animatedMenuPokemonNew = originalNew
        SummaryMenu.new = function(game, mon, ...)
          local self = originalNew(game, mon, ...)
          local animated = mon and getSprite(mon.species, { kind = "summary", mon = mon })
          animated = animated and fitStockPortrait(animated, 56, 56) or nil
          if self and animated then
            self.sprite, self.spriteTrueColor = animated, true
          end
          return self
        end
      end

      if type(SummaryMenu.draw) == "function" and not SummaryMenu._animatedMenuPokemonDraw then
        local original = SummaryMenu.draw
        SummaryMenu._animatedMenuPokemonDraw = original
        SummaryMenu.draw = function(self, ...)
          local mon = self and self.mon
          local animated = mon and getSprite(mon.species, { kind = "summary", mon = mon })
          animated = animated and fitStockPortrait(animated, 56, 56) or nil
          if not animated then return original(self, ...) end
          local oldSprite, oldTrue = self.sprite, self.spriteTrueColor
          self.sprite, self.spriteTrueColor = animated, true
          local okDraw, drawErr = pcall(original, self, ...)
          self.sprite, self.spriteTrueColor = oldSprite, oldTrue
          if not okDraw then error(drawErr, 0) end
        end
      end
    end

    local okDex, DexEntryMenu = false, nil
    if not IS_GEN2 then okDex, DexEntryMenu = pcall(require, "src.ui.DexEntryMenu") end
    if okDex and type(DexEntryMenu) == "table" then
      if type(DexEntryMenu.new) == "function" and not DexEntryMenu._animatedMenuPokemonNew then
        local originalNew = DexEntryMenu.new
        DexEntryMenu._animatedMenuPokemonNew = originalNew
        DexEntryMenu.new = function(game, speciesOrOpts, ...)
          local self = originalNew(game, speciesOrOpts, ...)
          local species = self and self.def and self.def.id
          local animated = species and getSprite(species, { kind = "dex" })
          animated = animated and fitStockPortrait(animated, 56, 56) or nil
          if self and animated then
            self.sprite, self.spriteTrueColor = animated, true
          end
          return self
        end
      end

      -- Patch the shared static renderer rather than only DexEntryMenu:draw().
      -- The stock Pokedex and printer paths both use this function, so the
      -- animated portrait remains available anywhere the vanilla entry page is
      -- rendered while Modern UI is disabled.
      if type(DexEntryMenu.render) == "function" and not DexEntryMenu._animatedMenuPokemonRender then
        local originalRender = DexEntryMenu.render
        DexEntryMenu._animatedMenuPokemonRender = originalRender
        DexEntryMenu.render = function(game, def, sprite, forceOwned, trueColor, page, ...)
          local species = def and def.id
          local animated = species and getSprite(species, { kind = "dex" })
          animated = animated and fitStockPortrait(animated, 56, 56) or nil
          if animated then
            sprite, trueColor = animated, true
          end
          return originalRender(game, def, sprite, forceOwned, trueColor, page, ...)
        end
      end
    end
  end
  patchVanillaScreens()

  -- Gold/Crystal have parallel menu classes rather than the Gen 1 Summary /
  -- DexEntry / EvolutionState classes.  Patch the actual Gen 2 picture
  -- methods directly so the selected Kanto in Motion atlas remains live.
  local function patchGen2Screens()
    if not IS_GEN2 then return end
    if gen2CleanUiHandle() then
      pcall(installStockGen2CleanUiBridge)
      return
    end

    local function modernUiEnabled()
      return integratedModernUiEnabled()
    end

    local function fillPortraitBox(x, y, w, h)
      local G = love.graphics
      if modernUiEnabled() then
        G.setColor(0.095, 0.022, 0.036, 1)
      else
        G.setColor(1, 1, 1, 1)
      end
      G.rectangle("fill", x, y, w, h)
      G.setColor(1, 1, 1, 1)
    end

    local function drawCenteredPortrait(image, x, y, w, h)
      image = fitStockPortrait(image, w, h)
      if not image then return false end
      local iw, ih = image:getDimensions()
      fillPortraitBox(x, y, w, h)
      love.graphics.setShader()
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(image, x + math.floor((w - iw) / 2),
        y + math.max(0, h - ih))
      return true
    end

    -- Stats screen: Gen2 SummaryMenu.new takes an opts table; hooking drawPic
    -- avoids constructor/signature assumptions and updates every animation frame.
    local okSummary, SummaryMenu = pcall(require, "src.ui.gen2.SummaryMenu")
    if okSummary and type(SummaryMenu) == "table"
        and type(SummaryMenu.drawPic) == "function"
        and not SummaryMenu._kantoInMotionGen2DrawPic then
      local nativeDrawPic = SummaryMenu.drawPic
      SummaryMenu._kantoInMotionGen2DrawPic = nativeDrawPic
      SummaryMenu.drawPic = function(self, ...)
        if mod.options:get("enabled") ~= false then
          local mon = self and self.mon
          if mon and mon.isEgg ~= true and mon.species then
            local animated = getSprite(mon.species,
              { kind = "summary", mon = mon })
            animated = animated and fitStockPortrait(animated, 56, 56) or nil
            if animated then
              -- nil colours = true-colour art; no Gen 2 CGB palette remap.
              return self:drawPicBlock(animated, nil)
            end
          end
        end
        return nativeDrawPic(self, ...)
      end
    end

    -- #DEX main/entry picture. Gen 2 places the frontpic in a 7x7 tile block
    -- at the coordinates passed to drawPic(). Preserve the question mark for
    -- unseen species and replace only real seen Pokemon.
    local okDex, PokedexMenu = pcall(require, "src.ui.gen2.PokedexMenu")
    if okDex and type(PokedexMenu) == "table"
        and type(PokedexMenu.drawPic) == "function"
        and not PokedexMenu._kantoInMotionGen2DrawPic then
      local nativeDrawPic = PokedexMenu.drawPic
      PokedexMenu._kantoInMotionGen2DrawPic = nativeDrawPic
      PokedexMenu.drawPic = function(self, row, tx, ty, ownColors, ...)
        if mod.options:get("enabled") ~= false and row and row.seen
            and row.species then
          local animated = getSprite(row.species, { kind = "dex" })
          if animated and drawCenteredPortrait(animated, (tx or 0) * 8,
              (ty or 0) * 8, 56, 56) then
            return
          end
        end
        return nativeDrawPic(self, row, tx, ty, ownColors, ...)
      end
    end

    -- Evolution movie. Keep the native blackout/silhouette frames because
    -- they are a real part of Crystal/Gold's evolution effect; use Kanto in
    -- Motion art for the normal old/new reveal frames.
    local okEvolution, EvolutionAnim = pcall(require, "src.ui.gen2.EvolutionAnim")
    if okEvolution and type(EvolutionAnim) == "table"
        and type(EvolutionAnim.drawPic) == "function"
        and not EvolutionAnim._kantoInMotionGen2DrawPic then
      local nativeDrawPic = EvolutionAnim.drawPic
      EvolutionAnim._kantoInMotionGen2DrawPic = nativeDrawPic
      EvolutionAnim.drawPic = function(self, ...)
        if mod.options:get("enabled") ~= false and self and not self.blackout then
          local species = self.showNew and self.newSpecies or self.oldSpecies
          local animated = species and getSprite(species,
            { kind = "evolution", mon = self.mon })
          if animated and drawCenteredPortrait(animated, 7 * 8, 2 * 8,
              56, 56) then
            return
          end
        end
        return nativeDrawPic(self, ...)
      end
    end
  end
  patchGen2Screens()

  -- A standalone Animated Menu Pokemon build and older Kanto in Motion builds
  -- used the same generic SummaryMenu marker name. If one of those wrappers
  -- was installed first, the normal injection above can be skipped even though
  -- this mod owns the active sprite provider. Add a Kanto-specific final pass
  -- for the stock Gen 1 status page. It redraws only the portrait box after the
  -- native screen has finished, so the rest of the Gen 1 UI remains untouched.
  local function installStockSummaryPortraitPass()
    local okSummary, SummaryMenu = pcall(require, IS_GEN2 and "src.ui.gen2.SummaryMenu" or "src.ui.SummaryMenu")
    if not (okSummary and type(SummaryMenu) == "table"
        and type(SummaryMenu.draw) == "function") then return end
    if SummaryMenu._kantoInMotionStockPortraitDraw then return end

    local baseDraw = SummaryMenu.draw
    SummaryMenu._kantoInMotionStockPortraitDraw = baseDraw
    SummaryMenu.draw = function(self, ...)
      local okDraw, drawErr = pcall(baseDraw, self, ...)
      if not okDraw then error(drawErr, 0) end

      if integratedModernUiEnabled()
          or mod.options:get("enabled") == false
          or knownExternalUiPresent() then
        return
      end

      local mon = self and self.mon
      local animated = mon and getSprite(mon.species, { kind = "summary", mon = mon })
      animated = animated and fitStockPortrait(animated, 56, 56) or nil
      if not animated then return end

      local pw, ph = animated:getDimensions()
      local py = math.max(0, 56 - ph)
      love.graphics.push("all")
      love.graphics.setShader()
      -- Erase the native portrait (and any oversized portrait from an older
      -- wrapper) without touching the name column that begins at x=72.
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 0, 0, 72, 56)
      love.graphics.draw(animated, 8 + pw, py, 0, -1, 1)
      require("src.render.PaletteFX").markTrueColor(8, py, pw, ph)
      love.graphics.pop()
    end
  end
  if not IS_GEN2 then installStockSummaryPortraitPass() end

  -- Gen1Recomp's evolution movie caches the old and new front images once at
  -- EvolutionState.new(), then alternates those two images while the sequence
  -- accelerates. Replace those cached pictures only for the duration of draw
  -- so the engine keeps its original timing, cancellation, cry, palette and
  -- evolution logic while our selected animated collection supplies the art.
  local function patchEvolutionScreen()
    local okEvolution, EvolutionState = false, nil
    if not IS_GEN2 then okEvolution, EvolutionState = pcall(require, "src.ui.EvolutionState") end
    if not (okEvolution and type(EvolutionState) == "table") then return end

    if type(EvolutionState.new) == "function"
        and not EvolutionState._animatedMenuPokemonNew then
      local originalNew = EvolutionState.new
      EvolutionState._animatedMenuPokemonNew = originalNew
      EvolutionState.new = function(game, mon, newSpecies, onDone, via)
        local state = originalNew(game, mon, newSpecies, onDone, via)
        if state then
          -- Keep the pre-evolution species because Evolution.apply() mutates
          -- mon.species before the final draw of the completed sequence.
          state._animatedMenuOldSpecies = mon and mon.species or nil
          state._animatedMenuNewSpecies = newSpecies
        end
        return state
      end
    end

    if type(EvolutionState.draw) == "function"
        and not EvolutionState._animatedMenuPokemonDraw then
      local originalDraw = EvolutionState.draw
      EvolutionState._animatedMenuPokemonDraw = originalDraw
      EvolutionState.draw = function(self, ...)
        if not (self and mod.options:get("enabled")) then
          return originalDraw(self, ...)
        end

        local oldSpecies = self._animatedMenuOldSpecies
          or (self.mon and self.mon.species)
        local newSpecies = self._animatedMenuNewSpecies or self.newSpecies
        local oldAnimated = oldSpecies and getSprite(oldSpecies, {
          kind = "evolution", mon = self.mon,
        }) or nil
        local newAnimated = newSpecies and getSprite(newSpecies, {
          kind = "evolution", mon = self.mon,
        }) or nil

        if not oldAnimated and not newAnimated then
          return originalDraw(self, ...)
        end

        local oldSprite, oldTrue = self.oldSprite, self.oldSpriteTrueColor
        local newSprite, newTrue = self.newSprite, self.newSpriteTrueColor
        if oldAnimated then
          self.oldSprite, self.oldSpriteTrueColor = oldAnimated, true
        end
        if newAnimated then
          self.newSprite, self.newSpriteTrueColor = newAnimated, true
        end

        local okDraw, drawErr = pcall(originalDraw, self, ...)
        self.oldSprite, self.oldSpriteTrueColor = oldSprite, oldTrue
        self.newSprite, self.newSpriteTrueColor = newSprite, newTrue
        if not okDraw then error(drawErr, 0) end
      end
    end
  end
  patchEvolutionScreen()

  -- Title-screen integration. The title composition itself remains the stock
  -- 160x144 Gen1Recomp screen, but the animated Pokemon and Red are presented
  -- in render.hud at final window resolution. This avoids magnifying a tiny
  -- nearest-filtered title canvas into large square pixels on high-resolution
  -- displays such as the ROG Ally X.
  --
  -- Pokemon reuse this mod's selected Gen 2/3/4/5 animated front provider and
  -- continue advancing normally. Red uses the bundled GIF-derived atlas,
  -- begins its one-shot when the interactive title loop starts, then holds the
  -- final frame until the TitleState is destroyed.
  local function patchTitleScreen()
    local okTitle, TitleState = pcall(require, IS_GEN2 and "src.ui.gen2.TitleState" or "src.ui.TitleState")
    if not (okTitle and type(TitleState) == "table") then return end

    local titlePlayerAtlas, titlePlayerQuads
    local function titlePlayerImage()
      if mod.options:get("titleTrainer") == "original" then return nil end
      if titlePlayerAtlas == false then return nil end
      if titlePlayerAtlas then return titlePlayerAtlas end
      if type(titlePlayer) ~= "table" or type(titlePlayer.image) ~= "string" then
        titlePlayerAtlas = false
        return nil
      end
      titlePlayerAtlas = atlasImage(titlePlayer.image) or false
      return titlePlayerAtlas ~= false and titlePlayerAtlas or nil
    end


    local titleLogoImageCache
    local function titleLogoImage()
      if titleLogoImageCache == false then return nil end
      if titleLogoImageCache then return titleLogoImageCache end
      titleLogoImageCache = atlasImage("assets/title/gen1recomppp_logo.png") or false
      return titleLogoImageCache ~= false and titleLogoImageCache or nil
    end


    local titleLogoBalancedCanvasCache
    local function titleLogoBalancedCanvas()
      if titleLogoBalancedCanvasCache == false then return nil end
      if titleLogoBalancedCanvasCache then return titleLogoBalancedCanvasCache end
      local logo = titleLogoImage()
      if not logo or not (love.graphics and love.graphics.newCanvas) then
        titleLogoBalancedCanvasCache = false
        return nil
      end
      local lw, lh = logo:getDimensions()
      local upscale = 2
      local okCanvas, canvas = pcall(love.graphics.newCanvas, lw * upscale, lh * upscale)
      if not okCanvas or not canvas then
        titleLogoBalancedCanvasCache = false
        return nil
      end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "linear", "linear") end
      local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
      love.graphics.push("all")
      love.graphics.setCanvas(canvas)
      love.graphics.origin()
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setShader()
      if logo.setFilter then pcall(logo.setFilter, logo, "nearest", "nearest") end
      love.graphics.draw(logo, 0, 0, 0, upscale, upscale)
      if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
      love.graphics.pop()
      titleLogoBalancedCanvasCache = canvas
      return canvas
    end

    local function titlePlayerQuad(frame)
      local atlas = titlePlayerImage()
      if not atlas or not love.graphics.newQuad then return nil end
      titlePlayerQuads = titlePlayerQuads or {}
      if titlePlayerQuads[frame] then return titlePlayerQuads[frame] end
      local width = math.max(1, math.floor(tonumber(titlePlayer.width) or 40))
      local height = math.max(1, math.floor(tonumber(titlePlayer.height) or 56))
      local columns = math.max(1, math.floor(tonumber(titlePlayer.columns) or 1))
      local index = frame - 1
      local col, row = index % columns, math.floor(index / columns)
      local iw, ih = atlas:getDimensions()
      local okQuad, quad = pcall(love.graphics.newQuad, col * width, row * height,
        width, height, iw, ih)
      if not okQuad then return nil end
      titlePlayerQuads[frame] = quad
      return quad
    end

    local titlePlayerBalancedCanvases
    local function titlePlayerBalancedCanvas(frame)
      local atlas = titlePlayerImage()
      local quad = titlePlayerQuad(frame)
      if not atlas or not quad or not (love.graphics and love.graphics.newCanvas) then
        return nil
      end
      titlePlayerBalancedCanvases = titlePlayerBalancedCanvases or {}
      if titlePlayerBalancedCanvases[frame] then return titlePlayerBalancedCanvases[frame] end
      local width = math.max(1, math.floor(tonumber(titlePlayer.width) or 40))
      local height = math.max(1, math.floor(tonumber(titlePlayer.height) or 56))
      local upscale = 2
      local okCanvas, canvas = pcall(love.graphics.newCanvas, width * upscale, height * upscale)
      if not okCanvas or not canvas then return nil end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "linear", "linear") end
      local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
      love.graphics.push("all")
      love.graphics.setCanvas(canvas)
      love.graphics.origin()
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setShader()
      if atlas.setFilter then pcall(atlas.setFilter, atlas, "nearest", "nearest") end
      love.graphics.draw(atlas, quad, 0, 0, 0, upscale, upscale)
      if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
      love.graphics.pop()
      titlePlayerBalancedCanvases[frame] = canvas
      return canvas
    end

    local function titlePokemonBalancedCanvas(sprite)
      if not sprite or not (love.graphics and love.graphics.newCanvas) then return nil end
      local sw, sh = sprite:getDimensions()
      local fit = math.min(1, 56 / math.max(1, sw), 56 / math.max(1, sh))
      local dw, dh = sw * fit, sh * fit
      local dx, dy = (56 - dw) / 2, 56 - dh
      local upscale = 2
      local okCanvas, canvas = pcall(love.graphics.newCanvas, 56 * upscale, 56 * upscale)
      if not okCanvas or not canvas then return nil end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "linear", "linear") end
      local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
      love.graphics.push("all")
      love.graphics.setCanvas(canvas)
      love.graphics.origin()
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setShader()
      if sprite.setFilter then pcall(sprite.setFilter, sprite, "nearest", "nearest") end
      love.graphics.draw(sprite, dx * upscale, dy * upscale, 0, fit * upscale, fit * upscale)
      if sprite.setFilter then pcall(sprite.setFilter, sprite, "nearest", "nearest") end
      if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
      love.graphics.pop()
      return canvas
    end

    local TITLE_PLAYER_LOOP_DELAY_MS = 5000

    local function oneShotPlayerFrame(self)
      local frames = math.max(1, math.floor(tonumber(titlePlayer.frames) or 1))
      if not mod.options:get("animate") or frames <= 1 then return 1 end
      if not self or self.phase ~= "loop" then return 1 end
      local now = love.timer and love.timer.getTime and love.timer.getTime() or 0
      if self._animatedMenuTitlePlayerStart == nil then
        self._animatedMenuTitlePlayerStart = now
      end
      local elapsed = math.max(0, (now - self._animatedMenuTitlePlayerStart) * 1000)
      local durations = type(titlePlayer.durations) == "table" and titlePlayer.durations or {}

      local seq = {}
      for i = 1, frames do seq[#seq + 1] = i end
      for i = frames - 1, 1, -1 do seq[#seq + 1] = i end

      local seqTotal = 0
      for i = 1, #seq - 1 do
        local frame = seq[i]
        seqTotal = seqTotal + math.max(1, tonumber(durations[frame]) or 100)
      end
      local cycleTotal = math.max(1, seqTotal + TITLE_PLAYER_LOOP_DELAY_MS)
      local loopElapsed = elapsed % cycleTotal

      local total = 0
      for i = 1, #seq - 1 do
        local frame = seq[i]
        total = total + math.max(1, tonumber(durations[frame]) or 100)
        if loopElapsed < total then return frame end
      end
      return 1
    end

    local KANTO_TITLE_SPECIES = {
      "BULBASAUR", "IVYSAUR", "VENUSAUR", "CHARMANDER", "CHARMELEON", "CHARIZARD",
      "SQUIRTLE", "WARTORTLE", "BLASTOISE", "CATERPIE", "METAPOD", "BUTTERFREE",
      "WEEDLE", "KAKUNA", "BEEDRILL", "PIDGEY", "PIDGEOTTO", "PIDGEOT",
      "RATTATA", "RATICATE", "SPEAROW", "FEAROW", "EKANS", "ARBOK",
      "PIKACHU", "RAICHU", "SANDSHREW", "SANDSLASH", "NIDORAN_F", "NIDORINA",
      "NIDOQUEEN", "NIDORAN_M", "NIDORINO", "NIDOKING", "CLEFAIRY", "CLEFABLE",
      "VULPIX", "NINETALES", "JIGGLYPUFF", "WIGGLYTUFF", "ZUBAT", "GOLBAT",
      "ODDISH", "GLOOM", "VILEPLUME", "PARAS", "PARASECT", "VENONAT", "VENOMOTH",
      "DIGLETT", "DUGTRIO", "MEOWTH", "PERSIAN", "PSYDUCK", "GOLDUCK", "MANKEY",
      "PRIMEAPE", "GROWLITHE", "ARCANINE", "POLIWAG", "POLIWHIRL", "POLIWRATH",
      "ABRA", "KADABRA", "ALAKAZAM", "MACHOP", "MACHOKE", "MACHAMP",
      "BELLSPROUT", "WEEPINBELL", "VICTREEBEL", "TENTACOOL", "TENTACRUEL",
      "GEODUDE", "GRAVELER", "GOLEM", "PONYTA", "RAPIDASH", "SLOWPOKE", "SLOWBRO",
      "MAGNEMITE", "MAGNETON", "FARFETCHD", "DODUO", "DODRIO", "SEEL", "DEWGONG",
      "GRIMER", "MUK", "SHELLDER", "CLOYSTER", "GASTLY", "HAUNTER", "GENGAR",
      "ONIX", "DROWZEE", "HYPNO", "KRABBY", "KINGLER", "VOLTORB", "ELECTRODE",
      "EXEGGCUTE", "EXEGGUTOR", "CUBONE", "MAROWAK", "HITMONLEE", "HITMONCHAN",
      "LICKITUNG", "KOFFING", "WEEZING", "RHYHORN", "RHYDON", "CHANSEY", "TANGELA",
      "KANGASKHAN", "HORSEA", "SEADRA", "GOLDEEN", "SEAKING", "STARYU", "STARMIE",
      "MR_MIME", "SCYTHER", "JYNX", "ELECTABUZZ", "MAGMAR", "PINSIR", "TAUROS",
      "MAGIKARP", "GYARADOS", "LAPRAS", "DITTO", "EEVEE", "VAPOREON", "JOLTEON",
      "FLAREON", "PORYGON", "OMANYTE", "OMASTAR", "KABUTO", "KABUTOPS",
      "AERODACTYL", "SNORLAX", "ARTICUNO", "ZAPDOS", "MOLTRES", "DRATINI",
      "DRAGONAIR", "DRAGONITE", "MEWTWO", "MEW",
    }

    local function ensureFullKantoTitleCycle(state)
      if state._animatedMenuFullKantoCycle then return end

      local currentSpecies = state.cycleSpecies
        and state.cycleSpecies[state.cycleIndex or 1] or nil
      local list = {}
      local currentIndex = 1
      for i = 1, #KANTO_TITLE_SPECIES do
        list[i] = KANTO_TITLE_SPECIES[i]
        if KANTO_TITLE_SPECIES[i] == currentSpecies then currentIndex = i end
      end
      state.cycleSpecies = list
      state.cycleIndex = currentIndex
      state._animatedMenuFullKantoCycle = true
      state._animatedMenuKantoShuffleBag = nil
    end

    local function isLiveTitle(state)
      if not (state and getmetatable(state) == TitleState) then return false end
      if state.yellowLayout then return false end
      if not mod.options:get("enabled") or not mod.options:get("titleScreen") then
        return false
      end
      ensureFullKantoTitleCycle(state)
      return true
    end

    -- Gen1Recomp's stock Red/Blue title uses a small TitleMons list, which can
    -- make the same handful of Pokemon appear repeatedly. Use all 151 Kanto
    -- species in a shuffled bag instead: the order is random, but a species
    -- cannot repeat until the other 150 have been shown. The last species from
    -- the previous bag is also excluded from the first slot of the next bag.
    local function refillTitleShuffleBag(self)
      local count = #self.cycleSpecies
      local current = self.cycleIndex
      local bag = {}
      for i = 1, count do
        if i ~= current then bag[#bag + 1] = i end
      end
      local random = love.math and love.math.random or math.random
      for i = #bag, 2, -1 do
        local j = random(1, i)
        bag[i], bag[j] = bag[j], bag[i]
      end
      self._animatedMenuKantoShuffleBag = bag
      self._animatedMenuKantoShufflePos = 1
    end

    if type(TitleState.pickNewMon) == "function"
        and not TitleState._animatedMenuPokemonFullKantoPick then
      local originalPickNewMon = TitleState.pickNewMon
      TitleState._animatedMenuPokemonFullKantoPick = originalPickNewMon
      TitleState.pickNewMon = function(self, ...)
        if not isLiveTitle(self) then return originalPickNewMon(self, ...) end
        local count = #self.cycleSpecies
        if count < 2 then return end

        local bag = self._animatedMenuKantoShuffleBag
        local pos = tonumber(self._animatedMenuKantoShufflePos) or 1
        if type(bag) ~= "table" or pos > #bag then
          refillTitleShuffleBag(self)
          bag = self._animatedMenuKantoShuffleBag
          pos = self._animatedMenuKantoShufflePos or 1
        end
        if not bag or not bag[pos] then return end

        self.cycleIndex = bag[pos]
        self._animatedMenuKantoShufflePos = pos + 1
      end
    end

    local function titleCycleExtraFrames()
      local speed = mod.options:get("titleCycleSpeed")
      if speed == "slower" then return 120 end
      if speed == "slow" then return 60 end
      return 0
    end

    -- Delay only the stock title hold phase. Temporarily subtract the selected
    -- delay before calling updateCycle so NORMAL remains exactly stock while
    -- SLOW/SLOWER add 60/120 frames without duplicating HOLD_FRAMES here.
    if type(TitleState.updateCycle) == "function"
        and not TitleState._animatedMenuPokemonCycleSpeed then
      local originalUpdateCycle = TitleState.updateCycle
      TitleState._animatedMenuPokemonCycleSpeed = originalUpdateCycle
      TitleState.updateCycle = function(self, ...)
        local extra = isLiveTitle(self) and titleCycleExtraFrames() or 0
        if extra > 0 and self.scrollPhase == "hold" and type(self.timer) == "number" then
          local savedTimer = self.timer
          self.timer = math.max(0, savedTimer - extra)
          local result = originalUpdateCycle(self, ...)
          if self.scrollPhase == "hold" then self.timer = savedTimer end
          return result
        end
        return originalUpdateCycle(self, ...)
      end
    end

    local TITLE_ALT_COLOR_PERCENT = 27
    local TITLE_ALT_COLOR_REPEAT_PERCENT = 5

    local function titlePokemon(state)
      if not isLiveTitle(state) or state.scrollPhase == "ball" then return nil end
      local species = state.cycleSpecies and state.cycleSpecies[state.cycleIndex]
      if not species then return nil end

      -- Roll exactly once for each newly selected title Pokemon. Keeping the
      -- result on TitleState prevents the variant from changing between draw
      -- calls while that Pokemon is on screen.
      if state._animatedMenuTitleVariantIndex ~= state.cycleIndex
          or state._animatedMenuTitleVariantSpecies ~= species then
        local random = love.math and love.math.random or math.random
        state._animatedMenuTitleVariantIndex = state.cycleIndex
        state._animatedMenuTitleVariantSpecies = species

        -- Always present the first Pokemon of a fresh title-screen session in
        -- its normal colors. Starting with the second Pokemon, roll the normal
        -- title shiny chance once per newly selected species.
        if not state._animatedMenuTitleFirstPokemonShown then
          state._animatedMenuTitleFirstPokemonShown = true
          state._animatedMenuTitleAltColor = false
        else
          -- Keep the normal 27% chance, but heavily reduce the chance of a
          -- second shiny immediately following one that was actually shown.
          -- This still permits rare back-to-back shinies without allowing long
          -- streaks to occur nearly as often as independent 27% rolls do.
          local chance = state._animatedMenuTitlePreviousWasAltColor
            and TITLE_ALT_COLOR_REPEAT_PERCENT or TITLE_ALT_COLOR_PERCENT
          state._animatedMenuTitleAltColor = (random(1, 100) <= chance)
        end
      end

      local generation = selectedGeneration()
      if state._animatedMenuTitleAltColor then
        local shiny = getTitleShinySprite(species, generation)
        if shiny then
          state._animatedMenuTitlePreviousWasAltColor = true
          return shiny
        end
      end

      -- Track what was actually displayed rather than only the random roll, so
      -- a missing alternate-color asset cannot accidentally suppress the next
      -- Pokemon's normal chance.
      state._animatedMenuTitlePreviousWasAltColor = false

      -- Normal animated sprite is the first fallback. Returning nil if that is
      -- unavailable intentionally leaves TitleState's stock Gen1 sprite alone.
      return getSprite(species, { kind = "title", generation = generation })
    end

    -- Suppress only the two stock low-resolution title sprites while TitleState
    -- itself is the top screen. If a title menu is opened, leave the original
    -- sprites in the 160x144 background so our final-resolution HUD overlay
    -- never draws over the menu box.
    if type(TitleState.draw) == "function"
        and not TitleState._animatedMenuPokemonHdTitleDraw then
      local originalDraw = TitleState.draw
      TitleState._animatedMenuPokemonHdTitleDraw = originalDraw
      TitleState.draw = function(self, ...)
        local top = self.game and self.game.stack and self.game.stack:top()
        local useHd = top == self and isLiveTitle(self)
        if not useHd then return originalDraw(self, ...) end

        local suppressMon = titlePokemon(self) ~= nil
        local suppressPlayer = titlePlayerImage() ~= nil
        local oldPlayer, oldQuads, oldBall = self.player, self.playerQuads, self.ballQuad
        local ownCurrent = rawget(self, "currentSprite")
        if suppressMon then self.currentSprite = function() return nil end end
        if suppressPlayer then self.player, self.playerQuads, self.ballQuad = nil, nil, nil end

        local okDraw, drawErr = pcall(originalDraw, self, ...)

        -- Remove the stock Pokemon wordmark on the SOURCE title canvas while
        -- KIM's replacement logo is active. Earlier builds only painted over
        -- it later in render.hud; changing SCREEN LOCATION moved the native
        -- title but left KIM's overlay centred, exposing the original logo /
        -- intro art behind it. Blank the source band here so there is nothing
        -- underneath to reveal regardless of final screen placement.
        if okDraw and titleLogoImage() then
          love.graphics.push("all")
          love.graphics.setShader()
          love.graphics.setColor(1,1,1,1)
          love.graphics.rectangle("fill",0,0,160,60)
          love.graphics.pop()
        end

        if ownCurrent ~= nil then self.currentSprite = ownCurrent
        else self.currentSprite = nil end
        self.player, self.playerQuads, self.ballQuad = oldPlayer, oldQuads, oldBall
        if not okDraw then error(drawErr, 0) end
      end
    end

    local function drawBalancedCanvas(canvas, x, y, sx, sy)
      if not canvas then return false end
      local premultiplied = false
      if love.graphics.setBlendMode then
        premultiplied = pcall(love.graphics.setBlendMode, "alpha", "premultiplied")
      end
      love.graphics.draw(canvas, x, y, 0, sx, sy)
      if premultiplied and love.graphics.setBlendMode then
        pcall(love.graphics.setBlendMode, "alpha", "alphamultiply")
      end
      return true
    end

    -- Draw the animated title sprites directly at the completed window scale.
    -- Linear sampling now operates across the actual hundreds of screen pixels
    -- occupied by a sprite instead of across a 40/56px intermediate texture
    -- that the engine later nearest-upscales.
    mod.hooks:wrap("render.hud", function(next, game, viewport)
      next(game, viewport)
      local state = game and game.stack and game.stack:top()
      if not isLiveTitle(state) then return end

      -- Follow Gen1Recomp's ACTUAL title UI rect rather than independently
      -- re-centering KIM's HD overlays in the window. Renderer:frameRects()
      -- includes SCREEN LOCATION (CENTER/UPPER/TOP), TouchSkin cutouts,
      -- GameViewport captures and Android's per-axis DPI conversion. Using its
      -- uiFill rect keeps KIM's trainer, Pokemon and logo locked to the native
      -- title presentation when the user moves the game screen.
      local originX,originY,scaleX,scaleY
      local renderer=game and game.renderer
      if renderer and type(renderer.frameRects)=="function" then
        local ok,r=pcall(renderer.frameRects,renderer)
        if ok and type(r)=="table"
            and tonumber(r.uox) and tonumber(r.uoy)
            and tonumber(r.Ux) and tonumber(r.Uy)
            and r.Ux>0 and r.Uy>0 then
          originX,originY=r.uox,r.uoy
          scaleX,scaleY=r.Ux,r.Uy
        end
      end
      if not originX then
        local vw = tonumber(viewport and viewport.width)
        local vh = tonumber(viewport and viewport.height)
        if not (vw and vh and vw > 0 and vh > 0) then
          vw, vh = love.graphics.getDimensions()
        end
        local scale=math.min(vw/160,vh/144)
        originX=(vw-160*scale)*0.5
        originY=(vh-144*scale)*0.5
        scaleX,scaleY=scale,scale
      end

      love.graphics.push("all")
      love.graphics.origin()
      love.graphics.setShader()
      love.graphics.setColor(1, 1, 1, 1)

      local titleLogo = titleLogoImage()
      if titleLogo then
        -- Cover only the stock Pokemon wordmark area and leave the original
        -- "Red Version" subtitle visible underneath it.
        -- Use the title screen white background and cover a little more
        -- of the original Pokemon wordmark so no Gen 1 logo fragments remain,
        -- while still leaving the stock Red Version subtitle visible.
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill",
          originX,
          originY,
          160 * scaleX,
          60 * scaleY)
        love.graphics.setColor(1, 1, 1, 1)

        local lw, lh = titleLogo:getDimensions()
        local fit = math.min(140 / math.max(1, lw), 52 / math.max(1, lh))
        local dw, dh = lw * fit, lh * fit
        local lx = 80 - (dw / 2)
        -- Sit the custom logo just above the stock Red Version subtitle.
        local ly = 8 + (52 - dh) / 2
        local balancedLogo = titleLogoBalancedCanvas()
        if balancedLogo then
          -- Present the logo with the same balanced two-stage treatment used
          -- by Red and the cycling Pokemon: real low-resolution pixels first,
          -- then a lightly smoothed final upscale so it belongs to the same
          -- visual plane without becoming harsh or unreadable.
          drawBalancedCanvas(balancedLogo,
            originX + lx * scaleX,
            originY + ly * scaleY,
            0.5 * fit * scaleX, 0.5 * fit * scaleY)
        else
          if titleLogo.setFilter then pcall(titleLogo.setFilter, titleLogo, "nearest", "nearest") end
          love.graphics.draw(titleLogo,
            originX + lx * scaleX,
            originY + ly * scaleY,
            0, fit * scaleX, fit * scaleY)
        end
      end

      local sprite = titlePokemon(state)
      if sprite then
        local x = 40 + (state.monOffset or 0)
        local y = 80
        local balancedMon = titlePokemonBalancedCanvas(sprite)
        if balancedMon then
          -- Match the trainer's middle-ground filtering so both title actors
          -- sit on the same visual plane: each is rendered crisply into a 2x
          -- intermediate canvas and then smoothly scaled from there.
          drawBalancedCanvas(balancedMon,
            originX + x * scaleX,
            originY + y * scaleY,
            0.5 * scaleX, 0.5 * scaleY)
        else
          local sw, sh = sprite:getDimensions()
          local fit = math.min(1, 56 / math.max(1, sw), 56 / math.max(1, sh))
          local dw, dh = sw * fit, sh * fit
          local fx = 40 + (56 - dw) / 2 + (state.monOffset or 0)
          local fy = 136 - dh
          if sprite.setFilter then pcall(sprite.setFilter, sprite, "linear", "linear", 8) end
          love.graphics.draw(sprite,
            originX + fx * scaleX,
            originY + fy * scaleY,
            0, fit * scaleX, fit * scaleY)
          if sprite.setFilter then pcall(sprite.setFilter, sprite, "nearest", "nearest") end
        end
      end

      local frame = oneShotPlayerFrame(state)
      local balanced = titlePlayerBalancedCanvas(frame)
      if balanced then
        -- Balanced trainer presentation: render Red crisply into a 2x
        -- intermediate canvas, then let the final screen upscale smooth only
        -- that larger composite. This keeps him sharper than full linear
        -- filtering, but less harsh than pure nearest, so he sits better with
        -- the slightly softened HD Pokemon.
        drawBalancedCanvas(balanced,
          originX + 82 * scaleX,
          originY + 80 * scaleY,
          0.5 * scaleX, 0.5 * scaleY)
      else
        local atlas = titlePlayerImage()
        local quad = titlePlayerQuad(frame)
        if atlas and quad then
          if atlas.setFilter then pcall(atlas.setFilter, atlas, "linear", "linear", 8) end
          love.graphics.draw(atlas, quad,
            originX + 82 * scaleX,
            originY + 80 * scaleY,
            0, scaleX, scaleY)
          if atlas.setFilter then pcall(atlas.setFilter, atlas, "nearest", "nearest") end
        end
      end
      love.graphics.pop()
    end)
  end
  if not IS_GEN2 then patchTitleScreen() end

  local function setOption(game, key, value)
    local options = game and game.save and game.save.options
    if options then
      options.modOptions = options.modOptions or {}
      options.modOptions[MOD_ID] = options.modOptions[MOD_ID] or {}
      options.modOptions[MOD_ID][key] = value
    end
    local loader = game and game.mods
    if loader then
      loader.modOptions = loader.modOptions or {}
      loader.modOptions[MOD_ID] = loader.modOptions[MOD_ID] or {}
      loader.modOptions[MOD_ID][key] = value
      if loader.events then
        loader.events:emit("mod.options_changed", { mod = MOD_ID, key = key, value = value })
      end
    end
    if game and game.writeOptions then pcall(game.writeOptions, game) end
  end

  -- Shared only with the integrated KRBA bridge. When true, KRBA suppresses
  -- its duplicate 160x96 layer because setFlatBattleWorld has already drawn
  -- the same Essentials session around the KRS final-resolution battlers.
  mod.exports._kantoInMotionKrsWideActive=function(battle)
    local fill=mod.options:get("battleArenaFill")
    return not IS_GEN2 and battle~=nil and battleLiteFullScreenActive()
      and (fill=="krs" or fill=="gen6")
      and activeKrbaSession()~=nil
  end

  local function optionLabel(row)
    if row.type == "toggle" then return mod.options:get(row.key) and "ON" or "OFF" end
    local current = mod.options:get(row.key)
    for _, choice in ipairs(row.choices or {}) do
      if choice[2] == current then return choice[1] end
    end
    return "----"
  end

  local function stepOption(game, row, direction)
    if row.type == "toggle" then
      setOption(game, row.key, not mod.options:get(row.key))
      return
    end
    local choices = row.choices or {}
    if #choices == 0 then return end
    local current, index = mod.options:get(row.key), 1
    for i, choice in ipairs(choices) do
      if choice[2] == current then index = i break end
    end
    index = (index - 1 + (direction or 1)) % #choices + 1
    setOption(game, row.key, choices[index][2])
  end

  local SETTINGS_SCREEN = "animated_menu_pokemon:settings"
  local BATTLE_SETTINGS_SCREEN = "animated_menu_pokemon:battle_settings"
  local function buildItems()
    local items = {}
    for _, row in ipairs(optionSchema) do
      items[#items + 1] = {
        id = MOD_ID .. ":" .. row.key, label = row.label,
        right = optionLabel(row), option = row,
      }
      if row.key == "animate" and #battleOptionSchema > 0 then
        items[#items + 1] = {
          id = MOD_ID .. ":battle_open", label = "BATTLE",
          right = "OPEN", submenu = BATTLE_SETTINGS_SCREEN,
        }
      end
    end
    items[#items + 1] = { id = "cancel", label = "CANCEL", cancel = true }
    return items
  end

  local function buildBattleItems()
    local items = {}
    for _, row in ipairs(battleOptionSchema) do
      items[#items + 1] = {
        id = MOD_ID .. ":" .. row.key, label = row.label,
        right = optionLabel(row), option = row,
      }
    end
    items[#items + 1] = {
      id = MOD_ID .. ":battle_reset_defaults",
      label = "RESET TO DEFAULT", right = "RESET", resetBattleDefaults = true,
    }
    items[#items + 1] = { id = "cancel", label = "BACK", cancel = true }
    return items
  end

  local function newSettingsMenu(game)
    local menu
    local function refresh(preferredId)
      local oldIndex = menu and menu.index or 1
      local items = buildItems()
      if not menu then return items end
      menu.items = items
      local found
      if preferredId then
        for i, item in ipairs(items) do if item.id == preferredId then found = i break end end
      end
      menu.index = found or math.max(1, math.min(oldIndex, #items))
    end
    local function step(item, dir)
      if not (item and item.option) then return end
      stepOption(game, item.option, dir)
      refresh(item.id)
    end
    menu = mod.ui.ListMenu.new(game, "KANTO IN MOTION", {}, {
      wrap = true, keyRepeat = true,
      onChoose = function(item, m)
        if item and item.cancel then if m and m.close then m:close() end return end
        if item and item.submenu then mod.ui.push(game, item.submenu); return end
        step(item, 1)
      end,
    })
    refresh()
    local baseUpdate = menu.update
    menu.update = function(self, dt)
      local item = self.items and self.items[self.index]
      if item and item.option then
        local input = self.game and self.game.input
        if input and input:wasPressed("left") then step(item, -1); return end
        if input and input:wasPressed("right") then step(item, 1); return end
      end
      return baseUpdate(self, dt)
    end
    return menu
  end

  local function newBattleSettingsMenu(game)
    local menu
    local function resetBattleDefaults()
      for _, row in ipairs(battleOptionSchema) do
        if row.default ~= nil then
          setOption(game, row.key, row.default)
        end
      end
    end
    local function refresh(preferredId)
      local oldIndex = menu and menu.index or 1
      local items = buildBattleItems()
      if not menu then return items end
      menu.items = items
      local found
      if preferredId then
        for i, item in ipairs(items) do if item.id == preferredId then found = i break end end
      end
      menu.index = found or math.max(1, math.min(oldIndex, #items))
    end
    local function step(item, dir)
      if not (item and item.option) then return end
      stepOption(game, item.option, dir)
      refresh(item.id)
    end
    menu = mod.ui.ListMenu.new(game, "BATTLE", {}, {
      wrap = true, keyRepeat = true,
      onChoose = function(item, m)
        if item and item.cancel then if m and m.close then m:close() end return end
        if item and item.resetBattleDefaults then
          resetBattleDefaults()
          refresh(item.id)
          return
        end
        step(item, 1)
      end,
    })
    refresh()
    local baseUpdate = menu.update
    menu.update = function(self, dt)
      local item = self.items and self.items[self.index]
      if item and item.option then
        local input = self.game and self.game.input
        if input and input:wasPressed("left") then step(item, -1); return end
        if input and input:wasPressed("right") then step(item, 1); return end
      end
      return baseUpdate(self, dt)
    end
    return menu
  end

  local submenuReady = mod.content and mod.content.screens
    and mod.content.screens.register and mod.ui and mod.ui.ListMenu
    and mod.ui.ListMenu.new and mod.ui.push
  if submenuReady then
    mod.content.screens:register(SETTINGS_SCREEN, { new = function(game) return newSettingsMenu(game) end })
    mod.content.screens:register(BATTLE_SETTINGS_SCREEN, { new = function(game) return newBattleSettingsMenu(game) end })
  end

  local function insertOpenRow(out, row)
    if mod.ui and type(mod.ui.insertBefore) == "function" then
      local inserted = mod.ui.insertBefore(out, "MODS", row)
      if inserted then return inserted end
      inserted = mod.ui.insertBefore(out, "CANCEL", row)
      if inserted then return inserted end
    end
    out[#out + 1] = row
    return out
  end

  local function activeExternalUiOverhaul()
    -- Full third-party UI overhauls own the same presentation surfaces as the
    -- bundled Modern UI. They are optional dependencies so recognized builds
    -- load first and Kanto in Motion can yield presentation while keeping its
    -- independent animation provider active. Registered generic owners are
    -- also honored if they are already available during KIM bootstrap.
    if mod._kantoInMotionInterop then
      local registered = mod._kantoInMotionInterop:uiOwnerFor(nil, nil, "menu")
      if registered and (registered.kinds == nil
          or mod._kantoInMotionInterop:_uiKindClaimed(registered, "battle")) then
        return registered.owner
      end
    end
    if type(mod.find) == "function" then
      for _, id in ipairs({ "gen3_battle_ui", "colosseum_ui_overhaul" }) do
        local ok, handle = pcall(mod.find, id)
        if ok and handle then return id end
      end
    end
    return nil
  end

  local function installIntegratedModernUi()
    if IS_GEN2 then
      if gen2CleanUiHandle() then
        local okBridge, bridgeResult = pcall(installStockGen2CleanUiBridge)
        if not okBridge or bridgeResult ~= true then
          mod.log:warn("Gen2 Clean UI detected but animated portrait bridge did not install: %s",
            tostring(okBridge and bridgeResult or bridgeResult))
        end
        mod.log:info("Gen2 detected: bundled Modern UI automatically OFF; Gen2 Clean UI owns presentation while Kanto in Motion animations remain active")
      else
        mod.log:info("Gen2 detected: bundled Modern UI automatically OFF; native Gen2 UI remains presentation owner")
      end
      return
    end
    local externalUi = activeExternalUiOverhaul()
    if externalUi then
      mod.log:info("%s detected; bundled Gen1 Modern UI suppressed so the external UI can own presentation", externalUi)
      return
    end
    -- Always install the Gen1 presenter implementation, even when the saved
    -- preference is OFF. v8.6.56 made every presentation/input seam fail open
    -- while integratedModernUi is false, so the resident module is dormant and
    -- vanilla remains the owner. Keeping it resident is what allows phones (and
    -- cold-start desktop installs) to switch VANILLA -> MODERN live without a
    -- restart; the toggle now controls ownership rather than module lifetime.
    local modernUiStartsEnabled = integratedModernUiEnabled()
    local hostOs = ""
    local system = love and love.system
    if system and type(system.getOS) == "function" then
      local okOs, value = pcall(system.getOS)
      if okOs and value then hostOs = tostring(value) end
    end
    local modernUiFile
    if hostOs == "Android" or hostOs == "iOS" then
      modernUiFile = "lib/modern_ui_integrated_mobile.lua"
    else
      -- Windows (and other desktop hosts) deliberately use the desktop
      -- presenter implementation. This file never treats TouchControls as
      -- mobile battle chrome.
      modernUiFile = "lib/modern_ui_integrated_windows.lua"
    end
    local source, readErr = mod:read(modernUiFile)
    if not source then
      mod.log:error("cannot read integrated Modern UI (%s): %s", modernUiFile, tostring(readErr))
      return
    end
    local chunk, compileErr = load(source, "@" .. mod.path .. "/" .. modernUiFile)
    if not chunk then
      mod.log:error("cannot compile integrated Modern UI (%s): %s", modernUiFile, tostring(compileErr))
      return
    end
    local okModule, setup = pcall(chunk)
    if not okModule or type(setup) ~= "function" then
      mod.log:error("cannot load integrated Modern UI: %s", tostring(setup))
      return
    end
    local okInstall, installErr = pcall(setup, mod)
    if not okInstall then
      mod._kantoInMotionModernUiInstalled = nil
      mod.log:error("integrated Modern UI failed to install: %s", tostring(installErr))
    else
      mod._kantoInMotionModernUiInstalled = true
      if modernUiStartsEnabled then
        mod.log:info("Gen1 detected: integrated customized Modern UI 0.9.12 enabled via %s implementation", modernUiFile)
      else
        mod.log:info("Gen1 detected: integrated customized Modern UI 0.9.12 loaded dormant via %s implementation; vanilla owns presentation until the toggle is enabled", modernUiFile)
      end
    end
  end

  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    if submenuReady then
      return insertOpenRow(out, {
        id = "animated_menu_pokemon:settings_open",
        label = "KANTO IN MOTION",
        text = function() return "OPEN" end,
        value = function() return "OPEN" end,
        activate = function(g) mod.ui.push(g, SETTINGS_SCREEN) end,
      })
    end
    return out
  end)

  installIntegratedModernUi()
  if IS_GEN2 and gen2CleanUiHandle() then
    local okBridge, bridgeResult = pcall(installStockGen2CleanUiBridge)
    if not okBridge and mod.log and type(mod.log.warn) == "function" then
      mod.log:warn("late Gen2 Clean UI portrait bridge install failed: %s",
        tostring(bridgeResult))
    end
  end
  -- v8.6 integrated battle content. These installers deliberately run after
  -- KIM's host wrappers exist, so their stock fallback points at KIM's accepted
  -- v8.5 battle seams and the KRS-wide path can suppress only duplicate layers.
  if not IS_GEN2 then
    local okKrba,krbaInstaller=pcall(function()
      local src=assert(mod:read("lib/integrated_krba.lua"))
      local loader=loadstring or load
      return assert(loader(src,"@"..mod.path.."/lib/integrated_krba.lua"))()
    end)
    if okKrba and type(krbaInstaller)=="function" then
      local okRun,err=pcall(krbaInstaller,mod)
      if not okRun then mod.log:error("integrated KRBA failed: %s",tostring(err)) end
    else
      mod.log:error("cannot load integrated KRBA: %s",tostring(krbaInstaller))
    end

    local okBall,ballInstaller=pcall(function()
      local src=assert(mod:read("lib/integrated_pokeball_colorfix.lua"))
      local loader=loadstring or load
      return assert(loader(src,"@"..mod.path.."/lib/integrated_pokeball_colorfix.lua"))()
    end)
    if okBall and type(ballInstaller)=="function" then
      local okRun,err=pcall(ballInstaller,mod)
      if okRun then mod.exports.integratedPokeballColorfix=true
      else mod.log:error("integrated Pokeball Colorfix failed: %s",tostring(err)) end
    else
      mod.log:error("cannot load integrated Pokeball Colorfix: %s",tostring(ballInstaller))
    end

    -- Load after the colorfix so the target wrapper sits outside its
    -- drawAnimLayer/start wrappers and preserves the accepted ball palette.
    -- Reuse the existing locals here: main.lua is intentionally kept below
    -- Lua's active-local ceiling.
    okBall,ballInstaller=pcall(function()
      local src=assert(mod:read("lib/pokeball_target_fix.lua"))
      local loader=loadstring or load
      return assert(loader(src,"@"..mod.path.."/lib/pokeball_target_fix.lua"))()
    end)
    if okBall and type(ballInstaller)=="function" then
      okBall,ballInstaller=pcall(ballInstaller,mod,
        directStageGeometry,directSideMetrics,battleWorldMetrics)
      if okBall then
        mod._kantoInMotionPokeballTargetFix=ballInstaller
        mod.exports.integratedPokeballTargetFix=true
      else
        mod.log:error("integrated Pokeball target fix failed: %s",tostring(ballInstaller))
      end
    else
      mod.log:error("cannot load integrated Pokeball target fix: %s",tostring(ballInstaller))
    end

    -- Wilds of Kanto already ships shiny overworld art and a Battle Art-shaped
    -- persistent identity bridge. Provide that tiny bridge from KIM at runtime
    -- so visible overworld shinies use KIM's odds/DVs without modifying Wilds.
    okBall,ballInstaller=pcall(function()
      local src=assert(mod:read("lib/overworld_wild_shiny_bridge.lua"))
      local loader=loadstring or load
      return assert(loader(src,"@"..mod.path.."/lib/overworld_wild_shiny_bridge.lua"))()
    end)
    if okBall and type(ballInstaller)=="function" then
      okBall,ballInstaller=pcall(ballInstaller,mod)
      if okBall then
        mod._kantoInMotionOverworldWildShinyBridge=ballInstaller
      else
        mod.log:error("Wilds shiny compatibility bridge failed: %s",tostring(ballInstaller))
      end
    else
      mod.log:error("cannot load Wilds shiny compatibility bridge: %s",tostring(ballInstaller))
    end
  end

end
