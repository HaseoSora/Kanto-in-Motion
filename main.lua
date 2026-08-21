-- Kanto in Motion
-- Animated front-sprite provider for menus, Pokedex, evolutions, and title screens.
-- Public releases intentionally ship without Pokemon-derived sprite assets.
-- Animated assets are imported locally by the player with tools/import_assets.py.
return function(mod)
  local MOD_ID = "animated_menu_pokemon"
  local DATA_FILES = {
    gen2 = "data/animated_menu_sprites_gen2.lua",
    gen3 = "data/animated_menu_sprites_gen3.lua",
    gen4 = "data/animated_menu_sprites_gen4.lua",
    gen5 = "data/animated_menu_sprites_gen5.lua",
  }

  local optionSchema = {
    { key = "enabled", label = "MENU SPRITES", type = "toggle", default = true },
    { key = "integratedModernUi", label = "INTEGRATED MODERN UI", type = "toggle", default = true,
      description = "Use Kanto in Motion's bundled Gen1 Modern UI. Turn OFF when another full UI overhaul owns the interface. Requires a restart." },
    { key = "generation", label = "SPRITE GEN", type = "choice",
      default = "gen5", choices = {
        { "GEN 2", "gen2" }, { "GEN 3", "gen3" },
        { "GEN 4", "gen4" }, { "GEN 5", "gen5" },
      } },
    { key = "animate", label = "ANIMATION", type = "toggle", default = true },
    { key = "titleScreen", label = "TITLE SCREEN", type = "toggle", default = true },
    { key = "titleCycleSpeed", label = "TITLE CYCLE SPEED", type = "choice",
      default = "slow", choices = {
        { "NORMAL", "normal" }, { "SLOW", "slow" }, { "SLOWER", "slower" },
      } },
  }
  mod._kantoInMotionOptionSchema = optionSchema
  mod.options:define(optionSchema)

  local collections = {}
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
  local titlePlayer = loadTable("data/title_player_red.lua", true)

  local function selectedGeneration()
    local value = mod.options:get("generation")
    return collections[value] and value or "gen5"
  end

  local function normalizedSpecies(species)
    if type(species) ~= "string" then return nil end
    return species:upper():gsub("[^A-Z0-9_]", "")
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
    local key = table.concat({ generation, species, tostring(width), tostring(height) }, ":")
    local hit = renderCache[key]
    if hit then return hit end
    local atlas = atlasImage(front.image)
    if not atlas or not love.graphics or not love.graphics.newCanvas
        or not love.graphics.newQuad then return nil end
    local okCanvas, canvas = pcall(love.graphics.newCanvas, width, height)
    if not okCanvas or not canvas then return nil end
    if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
    local iw, ih = atlas:getDimensions()
    hit = {
      atlas = atlas, canvas = canvas, width = width, height = height,
      columns = columns, imageWidth = iw, imageHeight = ih,
      quads = {}, lastFrame = 0,
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

  local function renderFrame(front, generation, species)
    local entry = cacheEntry(front, generation, species)
    if not entry then return nil end
    local frame = currentFrame(front)
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

  local function getSprite(species, opts)
    if not mod.options:get("enabled") then return nil end
    local generation = opts and opts.generation or selectedGeneration()
    local front, actualGeneration, normalized = localFrontRecord(species, generation)
    if not front then return nil end
    return renderFrame(front, actualGeneration, normalized)
  end

  local function getFrontRecord(species, generation)
    generation = generation or selectedGeneration()
    local front = localFrontRecord(species, generation)
    if not front then return nil end
    return {
      width = front.width, height = front.height, columns = front.columns,
      frames = front.frames, durations = front.durations,
    }
  end

  -- Public export consumed by compatible UI mods such as Gen1 Modern UI.
  -- Kanto in Motion is the provider here; it does not depend on another mod.
  mod.exports = {
    apiVersion = 1,
    generations = { "gen2", "gen3", "gen4", "gen5" },
    defaultGeneration = "gen5",
    getGeneration = selectedGeneration,
    getSourcePreference = function() return "local" end,
    getActiveSource = function(species, generation)
      return localHasSprite(species, generation or selectedGeneration()) and "local" or "vanilla"
    end,
    hasSprite = function(species, generation)
      return localHasSprite(species, generation or selectedGeneration())
    end,
    getSprite = getSprite,
    getFrontRecord = getFrontRecord,
  }


  -- Vanilla Gen1Recomp Summary and Pokedex entry pages cache their image once
  -- when the screen opens. Refresh that image with our current animation frame
  -- immediately before the native draw. Gen1 Modern UI consumes getSprite()
  -- directly, so this path is only visible when the stock UI owns the screen.
  local function patchVanillaScreens()
    local okSummary, SummaryMenu = pcall(require, "src.ui.SummaryMenu")
    if okSummary and type(SummaryMenu) == "table" and type(SummaryMenu.draw) == "function"
        and not SummaryMenu._animatedMenuPokemonDraw then
      local original = SummaryMenu.draw
      SummaryMenu._animatedMenuPokemonDraw = original
      SummaryMenu.draw = function(self, ...)
        local mon = self and self.mon
        local animated = mon and getSprite(mon.species, { kind = "summary", mon = mon })
        if not animated then return original(self, ...) end
        local oldSprite, oldTrue = self.sprite, self.spriteTrueColor
        self.sprite, self.spriteTrueColor = animated, true
        local okDraw, drawErr = pcall(original, self, ...)
        self.sprite, self.spriteTrueColor = oldSprite, oldTrue
        if not okDraw then error(drawErr, 0) end
      end
    end

    local okDex, DexEntryMenu = pcall(require, "src.ui.DexEntryMenu")
    if okDex and type(DexEntryMenu) == "table" and type(DexEntryMenu.draw) == "function"
        and not DexEntryMenu._animatedMenuPokemonDraw then
      local original = DexEntryMenu.draw
      DexEntryMenu._animatedMenuPokemonDraw = original
      DexEntryMenu.draw = function(self, ...)
        local species = self and self.def and self.def.id
        local animated = species and getSprite(species, { kind = "dex" })
        if not animated then return original(self, ...) end
        local oldSprite, oldTrue = self.sprite, self.spriteTrueColor
        self.sprite, self.spriteTrueColor = animated, true
        local okDraw, drawErr = pcall(original, self, ...)
        self.sprite, self.spriteTrueColor = oldSprite, oldTrue
        if not okDraw then error(drawErr, 0) end
      end
    end
  end
  patchVanillaScreens()

  -- Gen1Recomp's evolution movie caches the old and new front images once at
  -- EvolutionState.new(), then alternates those two images while the sequence
  -- accelerates. Replace those cached pictures only for the duration of draw
  -- so the engine keeps its original timing, cancellation, cry, palette and
  -- evolution logic while our selected animated collection supplies the art.
  local function patchEvolutionScreen()
    local okEvolution, EvolutionState = pcall(require, "src.ui.EvolutionState")
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
    local okTitle, TitleState = pcall(require, "src.ui.TitleState")
    if not (okTitle and type(TitleState) == "table") then return end

    local titlePlayerAtlas, titlePlayerQuads
    local function titlePlayerImage()
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
    -- make it feel like the same handful of Pokemon keep repeating. Replace
    -- that with all 151 Kanto species, but keep the choice RANDOM. To avoid the
    -- appearance of repetition, exclude the current Pokemon and a rolling set
    -- of recently shown species whenever possible.
    local TITLE_RANDOM_HISTORY = 24

    if type(TitleState.pickNewMon) == "function"
        and not TitleState._animatedMenuPokemonFullKantoPick then
      local originalPickNewMon = TitleState.pickNewMon
      TitleState._animatedMenuPokemonFullKantoPick = originalPickNewMon
      TitleState.pickNewMon = function(self, ...)
        if not isLiveTitle(self) then return originalPickNewMon(self, ...) end
        local count = #self.cycleSpecies
        if count < 2 then return end

        local random = love.math and love.math.random or math.random
        local recent = self._animatedMenuTitleRecentMons
        if type(recent) ~= "table" then recent = {} end

        local blocked = { [self.cycleIndex] = true }
        for i = 1, #recent do blocked[recent[i]] = true end

        local candidates = {}
        for i = 1, count do
          if not blocked[i] then candidates[#candidates + 1] = i end
        end

        if #candidates == 0 then
          for i = 1, count do
            if i ~= self.cycleIndex then candidates[#candidates + 1] = i end
          end
        end
        if #candidates == 0 then return end

        local nextIndex = candidates[random(1, #candidates)]
        self.cycleIndex = nextIndex

        recent[#recent + 1] = nextIndex
        while #recent > TITLE_RANDOM_HISTORY do table.remove(recent, 1) end
        self._animatedMenuTitleRecentMons = recent
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

    local function titlePokemon(state)
      if not isLiveTitle(state) or state.scrollPhase == "ball" then return nil end
      local species = state.cycleSpecies and state.cycleSpecies[state.cycleIndex]
      return species and getSprite(species, {
        kind = "title", generation = selectedGeneration(),
      }) or nil
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

      local vw = tonumber(viewport and viewport.width)
      local vh = tonumber(viewport and viewport.height)
      if not (vw and vh and vw > 0 and vh > 0) then
        vw, vh = love.graphics.getDimensions()
      end
      local screenScale = math.min(vw / 160, vh / 144)
      local originX = math.floor((vw - 160 * screenScale) / 2)
      local originY = math.floor((vh - 144 * screenScale) / 2)

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
          160 * screenScale,
          60 * screenScale)
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
            originX + lx * screenScale,
            originY + ly * screenScale,
            0.5 * fit * screenScale, 0.5 * fit * screenScale)
        else
          if titleLogo.setFilter then pcall(titleLogo.setFilter, titleLogo, "nearest", "nearest") end
          love.graphics.draw(titleLogo,
            originX + lx * screenScale,
            originY + ly * screenScale,
            0, fit * screenScale, fit * screenScale)
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
            originX + x * screenScale,
            originY + y * screenScale,
            0.5 * screenScale, 0.5 * screenScale)
        else
          local sw, sh = sprite:getDimensions()
          local fit = math.min(1, 56 / math.max(1, sw), 56 / math.max(1, sh))
          local dw, dh = sw * fit, sh * fit
          local fx = 40 + (56 - dw) / 2 + (state.monOffset or 0)
          local fy = 136 - dh
          if sprite.setFilter then pcall(sprite.setFilter, sprite, "linear", "linear", 8) end
          love.graphics.draw(sprite,
            originX + fx * screenScale,
            originY + fy * screenScale,
            0, fit * screenScale, fit * screenScale)
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
          originX + 82 * screenScale,
          originY + 80 * screenScale,
          0.5 * screenScale, 0.5 * screenScale)
      else
        local atlas = titlePlayerImage()
        local quad = titlePlayerQuad(frame)
        if atlas and quad then
          if atlas.setFilter then pcall(atlas.setFilter, atlas, "linear", "linear", 8) end
          love.graphics.draw(atlas, quad,
            originX + 82 * screenScale,
            originY + 80 * screenScale,
            0, screenScale, screenScale)
          if atlas.setFilter then pcall(atlas.setFilter, atlas, "nearest", "nearest") end
        end
      end
      love.graphics.pop()
    end)
  end
  patchTitleScreen()

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
  local function buildItems()
    local items = {}
    for _, row in ipairs(optionSchema) do
      items[#items + 1] = {
        id = MOD_ID .. ":" .. row.key, label = row.label,
        right = optionLabel(row), option = row,
      }
    end
    items[#items + 1] = { id = "cancel", label = "CANCEL", cancel = true }
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
    -- gen3_battle_ui documents complete ownership of the same presentation
    -- surfaces as the bundled Modern UI.  It is listed as an optional
    -- dependency so, when installed, it loads before Kanto in Motion and can
    -- be discovered here through the public mod.find API.
    if type(mod.find) == "function" then
      local ok, handle = pcall(mod.find, "gen3_battle_ui")
      if ok and handle then return "gen3_battle_ui" end
    end
    return nil
  end

  local function installIntegratedModernUi()
    local externalUi = activeExternalUiOverhaul()
    if externalUi then
      mod.log:info("%s detected; bundled Gen1 Modern UI suppressed so the external UI can own presentation", externalUi)
      return
    end
    if mod.options:get("integratedModernUi") == false then
      mod.log:info("integrated Gen1 Modern UI disabled by Kanto in Motion option; animation/title features remain active")
      return
    end

    local source, readErr = mod:read("lib/modern_ui_integrated.lua")
    if not source then
      mod.log:error("cannot read integrated Modern UI: %s", tostring(readErr))
      return
    end
    local chunk, compileErr = load(source, "@" .. mod.path .. "/lib/modern_ui_integrated.lua")
    if not chunk then
      mod.log:error("cannot compile integrated Modern UI: %s", tostring(compileErr))
      return
    end
    local okModule, setup = pcall(chunk)
    if not okModule or type(setup) ~= "function" then
      mod.log:error("cannot load integrated Modern UI: %s", tostring(setup))
      return
    end
    local okInstall, installErr = pcall(setup, mod)
    if not okInstall then
      mod.log:error("integrated Modern UI failed to install: %s", tostring(installErr))
    else
      mod.log:info("integrated customized Gen1 Modern UI 0.9.12 enabled")
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
end
