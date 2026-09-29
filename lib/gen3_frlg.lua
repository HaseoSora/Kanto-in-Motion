-- Kanto in Motion - FireRed / LeafGreen bridge
--
-- Gen 3 deliberately keeps Gen1Recomp's native FRLG UI, battle HUD, command
-- menus and move-animation engine. KIM supplies animated Pokemon art through
-- src.core.game3.pokemon for menus and redraws battle battlers at final window
-- resolution so the HD source is not crushed through FRLG's native 64x64 slot.
-- The Gen 1 Modern UI / BattleState stack is never loaded on this generation.
return function(mod)
  local MOD_ID = "animated_menu_pokemon"
  local LEGACY_DATA = "data/hd_pokemon_sprites.lua"
  local NATIONAL_DATA = "data/hd_pokemon_national.lua"

  local schema = {
    { key = "enabled", label = "MENU SPRITES", type = "toggle", default = true,
      description = "Use Kanto in Motion animated Pokemon on supported FireRed/LeafGreen Pokemon presentation screens." },
    { key = "menuIcons", label = "POKEMON ICONS", type = "toggle", default = true,
      description = "Use Kanto in Motion HD-derived Pokemon icons in FireRed/LeafGreen party, box, Pokedex and other native icon slots. OFF restores the game's native icons." },
    { key = "animate", label = "ANIMATION", type = "toggle", default = true,
      description = "Animate Kanto in Motion Pokemon. OFF holds the first frame." },
    { key = "battleSprites", label = "BATTLE SPRITES", type = "toggle", default = true,
      description = "Use Kanto in Motion animated Pokemon in FireRed/LeafGreen battles while keeping the native FRLG battle UI and move animations." },
    { key = "battleShadowQuality", label = "PKMN SHADOWS", type = "choice",
      default = "medium", choices = {
        { "OFF", "off" }, { "LOW", "low" }, { "MEDIUM", "medium" },
        { "HIGH", "high" }, { "ULTRA", "ultra" },
      }, description = "Ground-contact shadow quality for Kanto in Motion HD battle Pokemon. Uses the same shadow system as Red/Blue/Yellow." },
    { key = "battleShadowOpacity", label = "SHADOW OPACITY", type = "choice",
      default = "100", choices = {
        { "50%", "50" }, { "60%", "60" }, { "70%", "70" },
        { "80%", "80" }, { "90%", "90" }, { "100%", "100" },
        { "110%", "110" }, { "120%", "120" }, { "130%", "130" },
        { "140%", "140" }, { "150%", "150" },
      }, description = "Adjust Kanto in Motion battle shadow darkness without changing Pokemon size or position. 100% matches the Gen 1 calibrated reference." },
    { key = "hdBattleBackgrounds", label = "HD BATTLE BACKGROUNDS", type = "toggle", default = true,
      description = "Use Kanto in Motion's location-aware HD Kanto battle backgrounds in FireRed/LeafGreen. FRLG keeps its native battler positions so the native HUD and move animations stay aligned. OFF restores the native FRLG battle background." },
  }
  mod._kantoInMotionOptionSchema = schema
  mod.options:define(schema)

  local battlerShadows
  do
    local source, err = mod:read("lib/battler_shadows.lua")
    if source then
      local chunk, compileErr = load(source, "@" .. mod.path .. "/lib/battler_shadows.lua")
      if chunk then
        local okFactory, factory = pcall(chunk)
        if okFactory and type(factory) == "function" then
          local okRenderer, renderer = pcall(factory, mod)
          if okRenderer and type(renderer) == "table" then battlerShadows = renderer end
        elseif mod.log and mod.log.error then
          mod.log:error("cannot load FRLG Pokemon shadows: %s", tostring(factory))
        end
      elseif mod.log and mod.log.error then
        mod.log:error("cannot compile FRLG Pokemon shadows: %s", tostring(compileErr))
      end
    elseif mod.log and mod.log.error then
      mod.log:error("cannot read FRLG Pokemon shadows: %s", tostring(err))
    end
  end

  local function loadTable(relative, quiet)
    local source, err = mod:read(relative)
    if not source then
      if not quiet and mod.log and mod.log.error then
        mod.log:error("cannot read %s: %s", relative, tostring(err))
      end
      return {}
    end
    local chunk, compileErr = load(source, "@" .. mod.path .. "/" .. relative)
    if not chunk then
      if mod.log and mod.log.error then
        mod.log:error("cannot compile %s: %s", relative, tostring(compileErr))
      end
      return {}
    end
    local ok, value = pcall(chunk)
    if not ok or type(value) ~= "table" then
      if mod.log and mod.log.error then
        mod.log:error("cannot load %s: %s", relative, tostring(value))
      end
      return {}
    end
    return value
  end

  -- Reuse KIM's existing Red/Kanto HD background router for FRLG.  The
  -- bridge below normalizes FireRed/LeafGreen Kanto map ids back to the Red
  -- names that router already knows.  Sevii Islands use KIM's generic grass
  -- family by default, with explicit cave routing for cave/tunnel/interior maps.
  local hdArenaRouter = loadTable("data/hd_battle_backgrounds.lua", true)
  if type(hdArenaRouter.bindMod) == "function" then
    pcall(hdArenaRouter.bindMod, mod)
  end

  -- v1.4.x's original table is species-name keyed.  Re-index it by National
  -- Dex so the same #001-151 assets can be used by Game3.  The supplemental
  -- file is already National-Dex keyed for #152-386.
  local byDex = {}
  for _, row in pairs(loadTable(LEGACY_DATA, true)) do
    if type(row) == "table" and tonumber(row.dex) then
      byDex[tonumber(row.dex)] = row
    end
  end
  for dex, row in pairs(loadTable(NATIONAL_DATA, true)) do
    dex = tonumber(dex)
    if dex and type(row) == "table" then byDex[dex] = row end
  end

  local okP, Pokemon = pcall(require, "src.core.game3.pokemon")
  if not okP or type(Pokemon) ~= "table" then
    if mod.log and mod.log.error then
      mod.log:error("FireRed/LeafGreen Pokemon module unavailable: %s", tostring(Pokemon))
    end
    return
  end

  local atlasCache = {}
  local renderCache = {}
  local timingCache = setmetatable({}, { __mode = "k" })
  local proxyCache = {}

  local function battleActive()
    local Battle = package.loaded["src.core.game3.battle.init"]
      or package.loaded["src.core.game3.battle"]
    if not Battle then
      local ok, value = pcall(require, "src.core.game3.battle.init")
      if ok then Battle = value end
    end
    if Battle and type(Battle.isActive) == "function" then
      local ok, value = pcall(Battle.isActive)
      if ok then return value == true end
    end
    return false
  end

  local function enabledForCurrentSurface(side)
    if side == "back" then return mod.options:get("battleSprites") ~= false end
    if battleActive() then return mod.options:get("battleSprites") ~= false end
    return mod.options:get("enabled") ~= false
  end

  local function nationalDex(species)
    species = tonumber(species)
    if not species then return nil end
    local ok, dex = pcall(Pokemon.national, species)
    if ok and tonumber(dex) then return tonumber(dex) end
    -- Internal ids 1-251 are identical to National Dex in FRLG.  Unown's
    -- generated B-Z/?/! pseudo species deliberately do not fall through here.
    if species >= 1 and species <= 251 then return species end
    return nil
  end

  local function personalityForBack(picSpecies)
    local Battle = package.loaded["src.core.game3.battle.init"]
      or package.loaded["src.core.game3.battle"]
    local st = Battle and ((Battle.getState and Battle.getState()) or Battle._st)
    if type(st) ~= "table" then return nil end
    local candidates = {}
    if st.player then candidates[#candidates + 1] = st.player end
    if type(st.battlers) == "table" then
      for id = 0, 3 do
        local b = st.battlers[id]
        if b and (id % 2 == 0) then candidates[#candidates + 1] = b end
      end
    end
    for _, battler in ipairs(candidates) do
      local mon = battler and battler.mon
      if mon then
        local sp = Pokemon.speciesOf and Pokemon.speciesOf(mon) or mon.species
        local personality = tonumber(mon.personality)
        local shown = Pokemon.picSpecies and Pokemon.picSpecies(sp, personality) or sp
        if tonumber(shown) == tonumber(picSpecies) then return personality end
      end
    end
    return nil
  end

  local function chooseVariant(variants, species, personality)
    if type(variants) ~= "table" then return nil end
    local gender
    if type(Pokemon.gender) == "function" and personality ~= nil then
      local ok, value = pcall(Pokemon.gender, species, personality)
      if ok then
        if value == "F" or value == "female" then gender = "female"
        elseif value == "M" or value == "male" then gender = "male" end
      end
    end
    if gender and type(variants[gender]) == "table" then return variants[gender] end
    return type(variants.default) == "table" and variants.default
      or type(variants.male) == "table" and variants.male
      or type(variants.female) == "table" and variants.female
      or nil
  end

  local function recordFor(species, side, shiny, personality, form)
    if not enabledForCurrentSurface(side) then return nil end
    -- FRLG has native special presentation for Castform's weather forms.
    -- Until KIM has form-specific HD assets, fail open instead of showing the
    -- wrong base form.  The same rule preserves Unown letter forms and
    -- personality-generated Spinda spots.
    if tonumber(form or 0) ~= 0 then return nil end
    local dex = nationalDex(species)
    if not dex or dex < 1 or dex > 386 then return nil end
    if dex == 327 then return nil end -- Spinda personality spots
    if dex == 386 then return nil end -- FR/LG use version-dependent Deoxys forms
    local row = byDex[dex]
    local sideData = type(row) == "table" and row[side] or nil
    local colorData = type(sideData) == "table"
      and sideData[shiny and "shiny" or "normal"] or nil
    local rec = chooseVariant(colorData, species, personality)
    if type(rec) ~= "table" or type(rec.image) ~= "string" then return nil end
    return rec, dex
  end

  local atlasMissRevision = {}
  local function assetProviderRevision()
    if mod._kimAssetProvider and type(mod._kimAssetProvider.revision) == "function" then
      local ok, value = pcall(mod._kimAssetProvider.revision)
      if ok then return tonumber(value) or 0 end
    end
    return 0
  end
  local function atlas(path)
    local revision = assetProviderRevision()
    if atlasCache[path] == false then
      if atlasMissRevision[path] == revision then return nil end
      atlasCache[path] = nil
    end
    if atlasCache[path] then return atlasCache[path] end
    if not (mod._kimAssetProvider and type(mod._kimAssetProvider.image) == "function") then
      atlasCache[path] = false
      atlasMissRevision[path] = revision
      return nil
    end
    local ok, image = pcall(function() return mod._kimAssetProvider.image(path) end)
    if not ok or not image then
      atlasCache[path] = false
      atlasMissRevision[path] = revision
      return nil
    end
    if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
    atlasCache[path] = image
    atlasMissRevision[path] = nil
    return image
  end

  local function timing(rec)
    local hit = timingCache[rec]
    if hit then return hit end
    local count = math.max(1, math.floor(tonumber(rec.frames) or 1))
    local src = type(rec.durations) == "table" and rec.durations or {}
    local cumulative, total = {}, 0
    for i = 1, count do
      local d = math.max(1, tonumber(src[i]) or 100)
      total = total + d
      cumulative[i] = total
    end
    hit = { count = count, cumulative = cumulative, total = math.max(1, total) }
    timingCache[rec] = hit
    return hit
  end

  local function frameFor(rec)
    local t = timing(rec)
    if mod.options:get("animate") == false or t.count <= 1 then return 1 end
    local now = love and love.timer and love.timer.getTime and love.timer.getTime() or 0
    local ms = (now * 1000) % t.total
    for i = 1, t.count do
      if ms < t.cumulative[i] then return i end
    end
    return t.count
  end

  local function sourceFor(rec)
    if not (love and love.graphics and love.graphics.newQuad) then return nil end
    local width = math.max(1, math.floor(tonumber(rec.width) or 1))
    local height = math.max(1, math.floor(tonumber(rec.height) or 1))
    local columns = math.max(1, math.floor(tonumber(rec.columns) or 1))
    local count = math.max(1, math.floor(tonumber(rec.frames) or 1))
    local key = table.concat({ tostring(rec.image), tostring(width), tostring(height),
      tostring(columns), tostring(count) }, ":")
    local source = renderCache[key]
    if source == false then return nil end
    if not source then
      local image = atlas(rec.image)
      if not image then renderCache[key] = false return nil end
      local iw, ih = image:getDimensions()
      local expectedW = columns * width
      local expectedH = math.ceil(count / columns) * height
      if iw ~= expectedW or ih ~= expectedH then
        renderCache[key] = false
        if mod.log and mod.log.warn then
          mod.log:warn("FRLG HD atlas mismatch for %s: got %dx%d expected %dx%d",
            tostring(rec.image), iw, ih, expectedW, expectedH)
        end
        return nil
      end
      source = { image = image, iw = iw, ih = ih, width = width, height = height,
        columns = columns, count = count, quads = {} }
      renderCache[key] = source
    end
    return source
  end

  local function sourceQuad(source, frame)
    if not source then return nil end
    frame = math.max(1, math.min(source.count or 1, math.floor(tonumber(frame) or 1)))
    local quad = source.quads[frame]
    if quad then return quad end
    local idx = frame - 1
    local col, row = idx % source.columns, math.floor(idx / source.columns)
    local ok, value = pcall(love.graphics.newQuad,
      col * source.width, row * source.height, source.width, source.height,
      source.iw, source.ih)
    if not ok then return nil end
    source.quads[frame] = value
    return value
  end

  local transparentBattleEntry
  local function battlePlaceholder()
    if transparentBattleEntry then return transparentBattleEntry end
    if not (love and love.graphics and love.graphics.newCanvas) then return nil end
    local ok, canvas = pcall(love.graphics.newCanvas, 64, 64)
    if not ok or not canvas then return nil end
    if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
    local previous = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
    if previous then love.graphics.setCanvas(previous) else love.graphics.setCanvas() end
    love.graphics.pop()
    transparentBattleEntry = { image = canvas, w = 64, h = 64, kim = true, kimBattlePlaceholder = true }
    return transparentBattleEntry
  end

  local function renderEntry(rec, dex, side, shiny, species, personality)
    if not (love and love.graphics and love.graphics.newCanvas and love.graphics.newQuad) then
      return nil
    end

    -- Verify the authored HD asset before replacing FRLG's native picture.
    -- v1.5.x ships National-Dex metadata for #152-386 even when an install
    -- only has the original #001-151 asset pack.  Returning a transparent
    -- placeholder before this check made Johto/Hoenn Pokemon disappear.
    local source = sourceFor(rec)
    if not source then return nil end

    -- Battles are redrawn from the original HD frame at final window
    -- resolution in render.hud.  Give FRLG a transparent 64x64 placeholder
    -- only after the real HD source is known to exist.
    if battleActive() then return battlePlaceholder() end
    local count = source.count or math.max(1, math.floor(tonumber(rec.frames) or 1))
    local frame = frameFor(rec)
    frame = math.max(1, math.min(count, math.floor(frame)))
    local proxyKey = table.concat({ tostring(dex), side, shiny and "s" or "n",
      tostring(species or 0), tostring(personality or 0), tostring(rec.image) }, ":")
    local proxy = proxyCache[proxyKey]
    if not proxy then
      local okCanvas, canvas = pcall(love.graphics.newCanvas, 64, 64)
      if not okCanvas or not canvas then return nil end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
      proxy = { canvas = canvas, lastFrame = 0,
        entry = { image = canvas, w = 64, h = 64, kim = true, nationalDex = dex } }
      proxyCache[proxyKey] = proxy
    end
    if proxy.lastFrame == frame then return proxy.entry end

    local quad = sourceQuad(source, frame)
    if not quad then return nil end

    -- Keep FRLG's native 64x64 sprite contract for this first compatibility
    -- pass.  KIM's imported displayScale supplies species-relative sizing;
    -- then cap the result to the native box.  This lets all native battle
    -- offsets, move animation transforms, healthboxes and menus keep working.
    local scale = tonumber(rec.displayScale)
    if not scale or scale <= 0 then scale = side == "back" and 0.315 or 0.33 end
    local maxW, maxH = 62, 62
    scale = math.min(scale, maxW / source.width, maxH / source.height)
    local drawW, drawH = source.width * scale, source.height * scale
    local x = (64 - drawW) * 0.5
    local y = 64 - drawH

    local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(proxy.canvas)
    love.graphics.origin()
    love.graphics.setScissor()
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.draw(source.image, quad, x, y, 0, scale, scale)
    if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
    love.graphics.pop()
    proxy.lastFrame = frame
    return proxy.entry
  end

  -- Gen1Recomp 0.3.19 finishes its Gen3Compat sprite wrapping AFTER mod entry
  -- chunks have run (Game3:_loadMods -> Loader:load -> Gen3Compat.applyMerged).
  -- Therefore KIM must become the outer/final provider at game.ready rather
  -- than wrapping Pokemon.frontPic/backPic here during the entry chunk.
  local upstreamFront
  local upstreamBack
  local frontWrapper
  local backWrapper
  local providerInstalled = false
  local routeLogged = { front = false, back = false }

  local function logFirstRoute(side, dex)
    if routeLogged[side] then return end
    routeLogged[side] = true
    if mod.log and mod.log.info then
      mod.log:info("FRLG KIM %s battler provider active (National Dex #%03d)",
        tostring(side), tonumber(dex) or 0)
    end
  end

  frontWrapper = function(species, form, shiny, personality)
    if battleActive() and mod.options:get("battleSprites") == false then
      if type(upstreamFront) == "function" then
        return upstreamFront(species, form, shiny, personality)
      end
      return nil
    end
    local rec, dex = recordFor(species, "front", shiny == true, personality, form)
    if rec then
      local entry = renderEntry(rec, dex, "front", shiny == true, species, personality)
      if entry then
        logFirstRoute("front", dex)
        return entry
      end
    end
    if type(upstreamFront) == "function" then
      return upstreamFront(species, form, shiny, personality)
    end
    return nil
  end

  backWrapper = function(species, form, shiny)
    if battleActive() and mod.options:get("battleSprites") == false then
      if type(upstreamBack) == "function" then
        return upstreamBack(species, form, shiny)
      end
      return nil
    end
    local personality = personalityForBack(species)
    local rec, dex = recordFor(species, "back", shiny == true, personality, form)
    if rec then
      local entry = renderEntry(rec, dex, "back", shiny == true, species, personality)
      if entry then
        logFirstRoute("back", dex)
        return entry
      end
    end
    if type(upstreamBack) == "function" then
      return upstreamBack(species, form, shiny)
    end
    return nil
  end

  local function installProvider(reason)
    -- Capture the chain that exists AFTER Gen3Compat has finished installing.
    -- Never capture our own wrapper, which would recurse.
    if type(Pokemon.frontPic) == "function" and Pokemon.frontPic ~= frontWrapper then
      upstreamFront = Pokemon.frontPic
    end
    if type(Pokemon.backPic) == "function" and Pokemon.backPic ~= backWrapper then
      upstreamBack = Pokemon.backPic
    end

    if type(upstreamFront) == "function" then
      Pokemon.frontPic = frontWrapper
      Pokemon.frontSprite = frontWrapper
    end
    if type(upstreamBack) == "function" then
      Pokemon.backPic = backWrapper
    end

    providerInstalled = (Pokemon.frontPic == frontWrapper)
      and (Pokemon.backPic == backWrapper)

    if mod.log and mod.log.info then
      mod.log:info("FRLG KIM Pokemon provider %s at %s",
        providerInstalled and "installed" or "not installed",
        tostring(reason or "unknown"))
    end
    return providerInstalled
  end

  -- Game3 emits game.ready only after Gen3Compat.applyMerged() has completed,
  -- making this the correct point to take final ownership of the picture seam.
  mod.events:on("game.ready", function()
    installProvider("game.ready")

    -- Pokemon.install()/reload can rebuild Gen 3 species data. Register after
    -- Gen3Compat's own reload callback so KIM is reasserted last.
    if type(Pokemon.onReload) == "function"
        and not mod._kantoInMotionFrlgReloadHookInstalled then
      mod._kantoInMotionFrlgReloadHookInstalled = true
      Pokemon.onReload(function()
        installProvider("pokemon.reload")
      end, "kanto-in-motion-frlg")
    end
  end)

  -- Extra safety for a resumed/hot-reloaded session where game.ready may have
  -- already occurred before this module was reconstructed.
  if mod.game then
    pcall(installProvider, "live-game")
  end

  -- Final-resolution FRLG battle battlers ---------------------------------
  --
  -- FRLG's native battle UI is 240x160 and intentionally pixel-scaled by the
  -- renderer.  Drawing KIM into a 64x64 native battler slot destroys most of
  -- the detail before that final upscale.  Instead the provider above leaves a
  -- transparent 64x64 placeholder during battle and this render.hud pass draws
  -- the selected KIM frame directly in the completed window coordinate space.
  -- Native FRLG background, move engine, healthboxes and command UI remain the
  -- owners of the rest of the battle.
  local okBattle, Battle = pcall(require, "src.core.game3.battle.init")
  local okUi, BattleUi = pcall(require, "src.core.game3.battle.ui")
  local okChrome, BattleChrome = pcall(require, "src.ui.game3.battle_chrome")
  local okAnim, BattleAnim = pcall(require, "src.core.game3.battle.anim")
  local okState, BattleState = pcall(require, "src.core.game3.battle.state")
  local okPicSizes, PicSizes = pcall(require, "src.core.game3.battle.anim_port.g1_pic_sizes")
  local okDisplay, Display = pcall(require, "src.core.game3.display")
  local okRenderer, Renderer = pcall(require, "src.render.Renderer")
  local okBg, BattleBg = pcall(require, "src.core.game3.battle.bg")
  local okMap, Game3Map = pcall(require, "src.core.game3.map")
  local okRuntime, Game3Runtime = pcall(require, "src.core.game3.runtime")

  -- Game3's preferred plane presenter uses the shared Renderer placement.
  -- On Android/iOS portrait that presenter intentionally reserves a large
  -- lower touch-control deck, while Game3's own Display.fit() places the
  -- 240x160 FR/LG frame in the upper deck.  KIM's final-resolution FR/LG
  -- battle pass is authored against Display.fit(), so allowing both paths to
  -- present the battle produces a second native HUD/menu lower on the screen
  -- (and a small doubled panel edge in landscape).  During FR/LG battles on
  -- native mobile only, use Game3's built-in flat presenter instead.  It is
  -- the engine's existing fallback compositor and already blits the complete
  -- 240x160 frame through Display.fit(), which gives KIM and the native HUD a
  -- single authoritative rectangle. Desktop keeps the proven plane path.
  local function nativeMobileHost()
    local system = love and love.system
    if not system or type(system.getOS) ~= "function" then return false end
    local ok, host = pcall(system.getOS)
    return ok and (host == "Android" or host == "iOS")
  end

  -- Game3's Display.fit() deliberately uses an upper portrait deck, while
  -- the shared Renderer honors SCREEN POS (CENTER / UPPER / TOP). KIM's
  -- final-resolution FRLG menu icons and preview sprites are replayed from
  -- render.hud using Display.fit(), so on mobile portrait they must use the
  -- same vertical placement as the native Renderer-owned menu surface.
  --
  -- v7 keeps Display's native scale/X calculation but replaces only portrait
  -- Y placement on Android/iOS when no touch skin owns the viewport:
  --   CENTER -> full safe-area center
  --   UPPER  -> quarter-slack placement
  --   TOP    -> safe-area top
  -- The same fitted rectangle is then used by presentFlat during battle,
  -- keeping the v6 single-HUD fix while restoring the user's SCREEN POS.
  local okScreenPosition, ScreenPosition = pcall(require, "src.core.ScreenPosition")
  local okSafeArea, SafeArea = pcall(require, "src.core.SafeArea")

  if okDisplay and Display and type(Display.fit) == "function"
      and not Display._kantoInMotionFrlgMobileScreenPosFit then
    local nativeFit = Display.fit
    Display._kantoInMotionFrlgMobileScreenPosFit = nativeFit

    Display.fit = function(winW, winH)
      local scaleX, ox, oy, pw, ph, scaleY = nativeFit(winW, winH)

      if not nativeMobileHost() then
        return scaleX, ox, oy, pw, ph, scaleY
      end

      local gw, gh = 0, 0
      if love and love.graphics and love.graphics.getDimensions then
        gw, gh = love.graphics.getDimensions()
      end
      winW = tonumber(winW) or (gw > 0 and gw or 240)
      winH = tonumber(winH) or (gh > 0 and gh or 160)

      local safeX, safeY, safeW, safeH = 0, 0, winW, winH
      if okSafeArea and SafeArea and type(SafeArea.windowRect) == "function"
          and gw > 0 and gh > 0
          and math.abs(winW - gw) < 0.5 and math.abs(winH - gh) < 0.5 then
        local ok, sx, sy, sw, sh = pcall(SafeArea.windowRect)
        if ok and tonumber(sw) and tonumber(sh) and sw > 0 and sh > 0 then
          safeX, safeY, safeW, safeH = sx, sy, sw, sh
        end
      end

      if safeH <= safeW then
        return scaleX, ox, oy, pw, ph, scaleY
      end

      if okScreenPosition and ScreenPosition
          and type(ScreenPosition.skinActive) == "function" then
        local ok, active = pcall(ScreenPosition.skinActive, winW, winH)
        if ok and active then
          return scaleX, ox, oy, pw, ph, scaleY
        end
      end

      local mode = okScreenPosition and ScreenPosition
        and tostring(ScreenPosition.mode or "center") or "center"
      if mode ~= "center" and mode ~= "upper" and mode ~= "top" then
        mode = "center"
      end

      local slack = math.max(0, safeH - ph)
      if mode == "center" then
        oy = safeY + slack * 0.5
      elseif mode == "upper" then
        oy = safeY + slack * 0.25
      else
        oy = safeY
      end

      -- Match Display.fit's framebuffer-pixel snapping so native FRLG and
      -- KIM overlays cannot drift by a subpixel on high-DPI mobile displays.
      local dpiY = 1
      if gw > 0 and gh > 0 and love and love.graphics
          and love.graphics.getPixelDimensions then
        local _, fh = love.graphics.getPixelDimensions()
        if fh and fh > 0 then dpiY = fh / gh end
      elseif love and love.graphics and love.graphics.getDPIScale then
        local d = tonumber(love.graphics.getDPIScale())
        if d and d > 1e-6 then dpiY = d end
      end
      if dpiY < 1e-6 then dpiY = 1 end
      oy = math.floor(oy * dpiY + 1e-9) / dpiY

      return scaleX, ox, oy, pw, ph, scaleY
    end
  end

  if okDisplay and Display and type(Display.present) == "function"
      and type(Display.presentFlat) == "function"
      and not Display._kantoInMotionFrlgMobileBattlePresent then
    local nativePresent = Display.present
    Display._kantoInMotionFrlgMobileBattlePresent = nativePresent
    Display.present = function(game, winW, winH)
      local active = false
      if nativeMobileHost() and okBattle and Battle and type(Battle.isActive) == "function" then
        local ok, value = pcall(Battle.isActive)
        active = ok and value == true
      end
      local kimBattle = mod.options:get("battleSprites") ~= false
        or mod.options:get("hdBattleBackgrounds") ~= false
      if active and kimBattle then
        -- presentFlat is a first-party Game3 path, not a reconstructed KIM
        -- surface.  It keeps native attacks/UI/OAM intact while preventing the
        -- generic Renderer from presenting the same battle a second time.
        return Display.presentFlat(game, winW, winH)
      end
      return nativePresent(game, winW, winH)
    end
  end

  local hdBgImageCache = {}

  local FRLG_CANONICAL_MAP = {
    PALLET_TOWN_PROFESSOR_OAKS_LAB = "OAKS_LAB",
    VIRIDIAN_CITY_GYM = "VIRIDIAN_GYM",
    PEWTER_CITY_GYM = "PEWTER_GYM",
    CERULEAN_CITY_GYM = "CERULEAN_GYM",
    VERMILION_CITY_GYM = "VERMILION_GYM",
    CELADON_CITY_GYM = "CELADON_GYM",
    FUCHSIA_CITY_GYM = "FUCHSIA_GYM",
    SAFFRON_CITY_GYM = "SAFFRON_GYM",
    SAFFRON_CITY_DOJO = "FIGHTING_DOJO",
    CINNABAR_ISLAND_GYM = "CINNABAR_GYM",
    POKEMON_LEAGUE_LORELEIS_ROOM = "LORELEIS_ROOM",
    POKEMON_LEAGUE_BRUNOS_ROOM = "BRUNOS_ROOM",
    POKEMON_LEAGUE_AGATHAS_ROOM = "AGATHAS_ROOM",
    POKEMON_LEAGUE_LANCES_ROOM = "LANCES_ROOM",
    POKEMON_LEAGUE_CHAMPIONS_ROOM = "CHAMPIONS_ROOM",
    CELADON_CITY_GAME_CORNER = "GAME_CORNER",
  }

  local function upperPretName(value)
    local s = tostring(value or "")
    s = s:gsub("^FR_", "")
    s = s:gsub("Route(%d+)", "Route_%1")
    s = s:gsub("(%l)(%u)", "%1_%2")
    s = s:gsub("-", "_"):upper():gsub("_+", "_")
    if s:sub(1, 7) == "SSANNE_" then s = "SS_ANNE_" .. s:sub(8) end
    return FRLG_CANONICAL_MAP[s] or s
  end

  local function currentFrlgMap(game)
    local mapId = okMap and Game3Map and Game3Map.current or nil
    if not mapId and okRuntime and Game3Runtime and type(Game3Runtime.getSession) == "function" then
      local ok, session = pcall(Game3Runtime.getSession)
      if ok and session then mapId = session.map end
    end
    if not mapId and game and game.session then mapId = game.session.map end
    if type(mapId) ~= "string" then return nil, nil end
    local def = game and game.data and game.data.maps and game.data.maps[mapId] or nil
    local sevii = mapId:sub(1, 6) == "SEVII_"
    local pret = def and def.pretName or mapId
    return mapId, {
      def = def,
      sevii = sevii,
      canonical = sevii and "SEVII_ISLANDS" or upperPretName(pret),
    }
  end

  local function frlgTerrainFlags(st)
    local terrain = st and tonumber(st.terrain) or nil
    if terrain == nil and okBg and BattleBg and type(BattleBg.terrainId) == "function" then
      local ok, value = pcall(BattleBg.terrainId)
      if ok then terrain = tonumber(value) end
    end
    local T = okBg and BattleBg and BattleBg.TERRAIN or {}
    local water = terrain == T.WATER or terrain == T.POND or terrain == T.UNDERWATER
    local grass = terrain == T.GRASS or terrain == T.LONG_GRASS
    local cave = terrain == T.CAVE or terrain == T.MOUNTAIN
    return water, grass, cave
  end

  local function frlgBackdrop(game, st)
    if mod.options:get("hdBattleBackgrounds") == false then return nil end
    if type(hdArenaRouter.resolve) ~= "function" then return nil end
    local mapId, info = currentFrlgMap(game)
    if not (mapId and info and info.canonical ~= "") then return nil end
    local water, grass, cave = frlgTerrainFlags(st)
    local kind = info.def and tostring(info.def.kind or "") or ""

    -- The Sevii Islands do not exist in Pokemon Red, so there is no authored
    -- Red location equivalent to reuse.  Outdoors/default Sevii battles use
    -- KIM's generic grass family.  Cave-like Sevii maps explicitly use the
    -- generic cave family so they do not inherit grass just because the island
    -- itself has no Pokemon Red equivalent.
    local function seviiCaveMap(id)
      id = tostring(id or ""):upper()
      if id == "" then return false end

      -- Direct cave/tunnel/hole naming.
      if id:find("CAVE", 1, true)
          or id:find("TUNNEL", 1, true)
          or id:find("DOTTED_HOLE", 1, true) then
        return true
      end

      -- Mt. Ember's interior routes.  Exterior and summit remain grass.
      if id:find("MT_EMBER_RUBY_PATH", 1, true)
          or id:find("MT_EMBER_SUMMIT_PATH", 1, true) then
        return true
      end

      -- Tanoby interior puzzle/chamber areas.
      if id:find("TANOBY_RUINS_", 1, true)
          and id:find("CHAMBER", 1, true) then
        return true
      end
      if id:find("TANOBY_KEY", 1, true) then
        return true
      end

      -- Navel Rock interior floors/paths.  Keep the named exterior/summit/base
      -- endpoints on grass unless the native terrain itself reports cave.
      if id:find("NAVEL_ROCK_", 1, true)
          and (id:find("_PATH_", 1, true)
            or id:match("_%d+F$")
            or id:match("_B%d+F$")) then
        return true
      end

      return false
    end

    if info.sevii then
      local useCave = cave or seviiCaveMap(mapId)
      water = false
      grass = not useCave
      cave = useCave
      kind = useCave and "cave" or "route"
    end

    local tileset = cave and "CAVERN"
      or ((kind == "indoor" or kind == "building") and "INTERIOR"
      or "OVERWORLD")
    local fakeMap = {
      id = info.canonical,
      def = { tileset = tileset },
    }
    function fakeMap:isWaterCell() return water end
    function fakeMap:isGrassCell() return grass end
    local fakeGame = {
      overworld = {
        map = fakeMap,
        player = { cellX = 0, cellY = 0, surfing = water },
      },
    }
    local ok, backdrop = pcall(hdArenaRouter.resolve, fakeGame, st)
    if not ok or type(backdrop) ~= "table" or not backdrop.file then return nil end
    backdrop.frlgMapId = mapId
    backdrop.frlgCanonical = info.canonical
    backdrop.frlgSevii = info.sevii == true
    return backdrop
  end

  local function frlgBackdropImage(game, st)
    local backdrop = frlgBackdrop(game, st)
    if not backdrop then return nil, nil end
    local path = "assets/battle/backgrounds/hd/" .. tostring(backdrop.file) .. ".png"
    local image = hdBgImageCache[path]
    if not image then
      image = atlas(path)
      if image then hdBgImageCache[path] = image end
    end
    return image or nil, backdrop
  end

  -- FRLG keeps its native battler slots so the native HUD and attack targets
  -- remain correct.  Instead of moving the Pokemon or locally warping pieces
  -- of the HD image, transform the ENTIRE background with one affine fit.
  --
  -- Two authored KIM ground-contact anchors define the transform:
  --   KIM player platform -> FRLG native player slot
  --   KIM enemy platform  -> FRLG native enemy slot
  --
  -- Only global X scale, Y scale, X translation and Y translation are used.
  -- There is no mesh deformation, pinching, rotation or local stretching, so
  -- the battle platforms remain flat parts of the original artwork.
  local FRLG_PLATFORM_PLAYER = { x = 72,  y = 112 }
  local FRLG_PLATFORM_ENEMY  = { x = 176, y = 72  }

  -- Visual framing trim for FR/LG.  Pokémon remain on their native battle
  -- coordinates; only the globally transformed HD background is lowered.
  -- Four native pixels was enough to bring more of the intended lower field
  -- into view without materially separating the broad platform art from feet.
  local FRLG_BACKGROUND_Y_NUDGE = 4

  local function frlgHdGeometry(backdrop)
    if not backdrop or type(hdArenaRouter.groundAnchors) ~= "function" then return nil end
    local ok, anchors = pcall(hdArenaRouter.groundAnchors, backdrop)
    if not ok or type(anchors) ~= "table" then return nil end
    return {
      player = {
        x = tonumber(anchors.player and anchors.player.x) or 630,
        y = tonumber(anchors.player and anchors.player.y) or 704,
      },
      enemy = {
        x = tonumber(anchors.enemy and anchors.enemy.x) or 1400,
        y = tonumber(anchors.enemy and anchors.enemy.y) or 484,
      },
      profile = tostring(anchors.profile or "fallback"),
    }
  end

  local function frlgGlobalBackgroundTransform(image, geo)
    if not (image and geo) then return nil end
    local okDims, w, h = pcall(function() return image:getWidth(), image:getHeight() end)
    if not okDims or not w or not h or w <= 0 or h <= 0 then return nil end

    -- Anchor metadata is authored against canonical 1920x950 KIM backgrounds.
    -- Scale the metadata into the actual image's pixel dimensions first.
    local px = geo.player.x * (w / 1920)
    local py = geo.player.y * (h / 950)
    local ex = geo.enemy.x  * (w / 1920)
    local ey = geo.enemy.y  * (h / 950)

    local dx = ex - px
    local dy = ey - py

    -- Degenerate metadata should never break a battle.  In that unlikely case,
    -- fall back to a direct native-frame fit.
    if math.abs(dx) < 1e-6 or math.abs(dy) < 1e-6 then
      return {
        sx = 240 / w,
        sy = 160 / h,
        tx = 0,
        ty = 0,
      }
    end

    -- Solve independent X/Y affine axes from the two platform control points:
    -- target = source * scale + translation
    local sx = (FRLG_PLATFORM_ENEMY.x - FRLG_PLATFORM_PLAYER.x) / dx
    local sy = (FRLG_PLATFORM_ENEMY.y - FRLG_PLATFORM_PLAYER.y) / dy
    local tx = FRLG_PLATFORM_PLAYER.x - px * sx
    local ty = FRLG_PLATFORM_PLAYER.y - py * sy + FRLG_BACKGROUND_Y_NUDGE

    return {
      sx = sx,
      sy = sy,
      tx = tx,
      ty = ty,
    }
  end

  local function drawFrlgHdBackground(image, originX, originY, ux, uy, geo)
    if not (image and geo and love and love.graphics) then return false end

    local t = frlgGlobalBackgroundTransform(image, geo)
    if not t then return false end

    if image.setFilter then pcall(image.setFilter, image, "linear", "linear") end
    love.graphics.setColor(1, 1, 1, 1)

    -- Apply one global transform to the complete image.  The Game3 viewport
    -- scissor clips the small overscan produced by the exact two-anchor fit.
    love.graphics.draw(
      image,
      originX + t.tx * ux,
      originY + t.ty * uy,
      0,
      t.sx * ux,
      t.sy * uy
    )

    if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
    return true
  end

  -- Game3 renders the FRLG battle into the singleton Renderer.canvas.
  -- With KIM's HD background active, BattleBg.draw punches only the terrain
  -- transparent while the trainer, particles, balls, healthboxes, party bars
  -- and native panel remain in this canvas.  Re-blitting this exact canvas over
  -- KIM's final-resolution background + Pokemon restores those native layers.
  local function drawNativeForegroundLayer(originX, originY, ux, uy)
    -- The mobile single-presentation path above renders through Display's
    -- mirrored 240x160 canvas rather than Renderer.canvas.  Prefer that live
    -- frame on Android/iOS; desktop keeps the already-confirmed Renderer
    -- foreground source.
    local canvas
    if nativeMobileHost() and okDisplay and Display then
      if type(Display.ensureCanvas) == "function" then
        local ok, value = pcall(Display.ensureCanvas, "main")
        if ok then canvas = value end
      end
      if not canvas then canvas = Display._canvas end
    end
    if not canvas then canvas = okRenderer and Renderer and Renderer.canvas or nil end
    if not canvas then return false end
    local ok, cw, ch = pcall(function() return canvas:getWidth(), canvas:getHeight() end)
    if not ok or cw ~= 240 or ch ~= 160 then return false end
    if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, originX, originY, 0, ux, uy)
    return true
  end

  local function withNativeViewport(originX, originY, ux, uy, fn)
    if type(fn) ~= "function" then return end
    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")
    love.graphics.translate(originX, originY)
    love.graphics.scale(ux, uy)
    fn()
    love.graphics.pop()
  end

  -- FRLG's menu chrome is authored as a split command layout.  With KIM's HD
  -- field underneath it, the right side can visually lose the continuous
  -- message-box backing.  Draw the normal 240px-wide message panel first, then
  -- let Renderer.canvas place the native menu/move panel over it.
  local function drawFullWidthPanelBacking(originX, originY, ux, uy)
    if not (okChrome and BattleChrome and type(BattleChrome.drawPanel) == "function") then
      return false
    end
    withNativeViewport(originX, originY, ux, uy, function()
      BattleChrome.drawPanel("none")
    end)
    return true
  end

  local function battlerAt(st, id)
    if not st then return nil end
    if id == 0 then return st.player end
    if id == 1 then return st.enemy end
    return type(st.battlers) == "table" and st.battlers[id] or nil
  end

  local function battlerSpecies(battler)
    if not battler then return nil end
    local sp = battler.species
    if not sp and battler.mon and type(Pokemon.speciesOf) == "function" then
      local ok, value = pcall(Pokemon.speciesOf, battler.mon)
      if ok then sp = value end
    elseif not sp and battler.mon then
      sp = battler.mon.species or battler.mon.speciesId
    end
    local pres = okAnim and BattleAnim.present and BattleAnim.present(battler.id)
    local tf = battler.expTransform
    if tf then
      local transformed = pres and pres.transformSpecies
      if not transformed and not (pres and pres.pendingTransform) then transformed = tf.species end
      if transformed then sp = transformed end
    end
    return tonumber(sp)
  end

  local function logicalBase(st, id)
    if okAnim and type(BattleAnim.coords) == "function" then
      local ok, base = pcall(BattleAnim.coords, st, id)
      if ok and type(base) == "table" and tonumber(base.x) and tonumber(base.y) then
        return base
      end
    end
    if id % 2 == 0 then return { x = 72, y = 80 } end
    return { x = 176, y = 40 }
  end

  local function battlerRecord(st, id)
    local b = battlerAt(st, id)
    if not b then return nil end
    local key = id
    local pres = okAnim and type(BattleAnim.present) == "function" and BattleAnim.present(key) or nil
    if pres and (pres.visible == false or pres.blinkHidden or pres.battlerInvisible or pres.invisible or pres.substitute) then
      return nil
    end
    if okUi and type(BattleUi.targetHidden) == "function" then
      local ok, hidden = pcall(BattleUi.targetHidden, id)
      if ok and hidden then return nil end
    end
    if okAnim and type(BattleAnim.shownBattler) == "function" then
      local ok, shown = pcall(BattleAnim.shownBattler, key, b)
      if ok and shown then b = shown end
    end

    local sp = battlerSpecies(b)
    if not sp then return nil end
    local mon = b.mon
    local personality = mon and tonumber(mon.personality) or nil
    local picSp = sp
    if type(Pokemon.picSpecies) == "function" then
      local ok, value = pcall(Pokemon.picSpecies, sp, personality)
      if ok and tonumber(value) then picSp = tonumber(value) end
    end
    local shiny = false
    if mon and type(Pokemon.isShiny) == "function" then
      local ok, value = pcall(Pokemon.isShiny, mon)
      if ok then shiny = value == true end
    end
    local side = (id % 2 == 0) and "back" or "front"
    local rec, dex = recordFor(picSp, side, shiny, personality, 0)
    if not rec then return nil end
    return {
      battler = b, pres = pres, species = sp, picSpecies = picSp,
      personality = personality, shiny = shiny, side = side,
      rec = rec, dex = dex,
    }
  end

  local function frameMetrics(game, viewport)
    -- Game3:_drawHud() already gives render.hud the exact rectangle produced
    -- by src.core.game3.display.Display.fit().  That is the authoritative
    -- transform for FRLG's native 240x160 frame and must take precedence over
    -- Renderer:frameRects(), whose UI geometry belongs to the general renderer
    -- and can differ from Game3's owned 3:2 presentation.
    local gx = tonumber(viewport and viewport.gameX)
    local gy = tonumber(viewport and viewport.gameY)
    local gw = tonumber(viewport and viewport.gameWidth)
    local gh = tonumber(viewport and viewport.gameHeight)
    if gx and gy and gw and gh and gw > 0 and gh > 0 then
      return gx, gy, gw / 240, gh / 160, 240, 160
    end

    -- Fallback for unusual hosts which do not provide Game3's fitted rectangle.
    local renderer = game and game.renderer
    if renderer and type(renderer.frameRects) == "function" then
      local ok, r = pcall(renderer.frameRects, renderer)
      if ok and type(r) == "table" and tonumber(r.uox) and tonumber(r.uoy)
          and tonumber(r.Ux) and tonumber(r.Uy) and r.Ux > 0 and r.Uy > 0 then
        return r.uox, r.uoy, r.Ux, r.Uy, tonumber(r.uiw) or 240, tonumber(r.uih) or 160
      end
    end

    local vw = tonumber(viewport and viewport.width)
    local vh = tonumber(viewport and viewport.height)
    if not (vw and vh and vw > 0 and vh > 0) then
      vw, vh = love.graphics.getDimensions()
    end
    local s = math.min(vw / 240, vh / 160)
    return (vw - 240 * s) * 0.5, (vh - 160 * s) * 0.5, s, s, 240, 160
  end


  -- Normal FRLG menu planes are presented by Renderer:endFrame(), not by
  -- Display.fit(). On mobile, TouchSkin/Playfield can shift that Renderer
  -- rectangle independently from Game3:_drawHud()'s Display.fit() viewport.
  -- Use the native Renderer UI rectangle for HD Summary/Pokedex/MonPic
  -- overlays, while battles continue to use frameMetrics()/Display.fit().
  local function menuFrameMetrics(game, viewport)
    if nativeMobileHost() then
      local battleActive = false
      if okBattle and Battle and type(Battle.isActive) == "function" then
        local okActive, active = pcall(Battle.isActive)
        battleActive = okActive and active == true
      end

      if not battleActive then
        local renderer = game and game.renderer
        if not renderer then
          local okRenderer, Renderer = pcall(require, "src.render.Renderer")
          if okRenderer then renderer = Renderer end
        end
        if renderer and type(renderer.frameRects) == "function" then
          local okRect, r = pcall(renderer.frameRects, renderer)
          if okRect and type(r) == "table"
              and tonumber(r.uox) and tonumber(r.uoy)
              and tonumber(r.Ux) and tonumber(r.Uy)
              and r.Ux > 0 and r.Uy > 0 then
            return r.uox, r.uoy, r.Ux, r.Uy,
              tonumber(r.uiw) or 240, tonumber(r.uih) or 160
          end
        end
      end
    end
    return frameMetrics(game, viewport)
  end

  -- FRLG's original battler metadata includes each species' visible picture
  -- width/height.  KIM's Gen 1 displayScale values were calibrated against a
  -- different arena, so use the FRLG dimensions as an upper bound instead of
  -- letting a small species (for example Pidgey) become oversized.  A 1.20x
  -- allowance keeps the HD art a little fuller than the original GBA sprite
  -- while preserving FRLG's relative species sizing.
  -- Small FR/LG-only visual trims for HD source art whose occupied silhouette
  -- differs noticeably from the original GBA sprite despite sharing similar
  -- coordinate metadata.  Keep this intentionally sparse and test-driven.
  local FRLG_FRONT_SCALE_TWEAK = {
    [16] = 0.90, -- Pidgey: v4 was still a little too large; Rattata stays 1.00.
  }

  local function frlgScaleCap(info, source)
    if not okPicSizes or type(PicSizes) ~= "table" then return nil end
    local sideTable = info.side == "back" and PicSizes.back or PicSizes.front
    if type(sideTable) ~= "table" then return nil end
    local sp = tonumber(info.picSpecies) or tonumber(info.species)
    local packed = sp and tonumber(sideTable[sp]) or nil
    if not packed or packed <= 0 then return nil end
    local nativeW = math.floor(packed / 256)
    local nativeH = packed % 256
    if nativeW <= 0 or nativeH <= 0 then return nil end
    local allowance = 1.20
    return math.min((nativeW * allowance) / source.width,
      (nativeH * allowance) / source.height)
  end

  local function drawHdBattler(info, st, id, ox, oy, ux, uy, hdGeo)
    local rec = info.rec
    local source = sourceFor(rec)
    if not source then return end
    local frame = frameFor(rec)
    local quad = sourceQuad(source, frame)
    if not quad then return end

    local base = logicalBase(st, id)
    local pres = info.pres
    local x = tonumber(base.x) or ((id % 2 == 0) and 72 or 176)
    local baseY = tonumber(base.y) or ((id % 2 == 0) and 80 or 40)
    local groundY = baseY + 32

    -- FireRed/LeafGreen's HP boxes and move-animation targets are authored
    -- around the native battler slots. Keep those same coordinates even when
    -- KIM's HD background is enabled; otherwise the cards move away from the
    -- positions targeted by FRLG's attacks and can sit under the native HUD.
    if info.side == "back" and okUi and type(BattleUi.battlerSpriteCenter) == "function" then
      local ok, nativeX, nativeY = pcall(BattleUi.battlerSpriteCenter,
        id, info.picSpecies or info.species, base, 0, false)
      if ok and tonumber(nativeY) then
        x = tonumber(nativeX) or x
        groundY = tonumber(nativeY) + 32
      end
    end

    if pres then
      x = x + (tonumber(pres.ox) or 0)
      groundY = groundY + (tonumber(pres.oy) or 0)
    end

    local shadowX, shadowGroundY = x, groundY

    -- Do NOT inherit FRLG's command-menu idle bounce.  That bounce was
    -- authored for the original 64x64 GBA sprite and looks exaggerated on
    -- KIM's animated HD cards.  Real move/send-out/faint transforms still
    -- reach us through the Anim `present` offsets above.

    local baseScale = tonumber(rec.displayScale)
    if not baseScale or baseScale <= 0 then baseScale = (info.side == "back") and 0.315 or 0.33 end
    local nativeCap = frlgScaleCap(info, source)
    if nativeCap and nativeCap > 0 then baseScale = math.min(baseScale, nativeCap) end
    if info.side == "front" then
      baseScale = baseScale * (FRLG_FRONT_SCALE_TWEAK[tonumber(info.dex)] or 1)
    end
    local animScale = pres and (tonumber(pres.scale) or 1) or 1
    local sxExtra = pres and (tonumber(pres.sx) or 1) or 1
    local syExtra = pres and (tonumber(pres.sy) or 1) or 1
    local hFlip = pres and pres.hFlip == true
    local rot = pres and (tonumber(pres.rotation) or 0) or 0
    local alpha = pres and (tonumber(pres.alpha) or 1) or 1
    local darken = pres and (tonumber(pres.darken) or 0) or 0
    local flash = pres and (tonumber(pres.flash) or 0) or 0

    if battlerShadows and type(battlerShadows.drawDirect) == "function" then
      love.graphics.setShader()
      love.graphics.setBlendMode("alpha")
      love.graphics.setColor(1, 1, 1, 1)
      pcall(battlerShadows.drawDirect, battlerShadows, {
        w = source.width,
        h = source.height,
        scaleX = baseScale * ux * animScale * math.abs(sxExtra),
        scaleY = baseScale * uy * animScale * math.abs(syExtra),
        ax = ox + shadowX * ux,
        ay = oy + shadowGroundY * uy,
        groundShift = 0,
        species = info.dex or info.species,
        dex = info.dex,
      }, info.side == "back" and "player" or "enemy", alpha)
    end

    local shade = 1 - darken * (1 - 8 / 255)
    if flash > 0 then
      love.graphics.setColor(1, 1, 1, alpha * (0.4 + 0.6 * ((flash % 2 == 0) and 1 or 0.3)))
    else
      love.graphics.setColor(shade, shade, shade, alpha)
    end

    if source.image.setFilter then pcall(source.image.setFilter, source.image, "linear", "linear") end
    local drawSx = baseScale * ux * animScale * sxExtra * (hFlip and -1 or 1)
    local drawSy = baseScale * uy * animScale * syExtra
    love.graphics.draw(source.image, quad,
      ox + x * ux, oy + groundY * uy,
      rot, drawSx, drawSy,
      source.width * 0.5, source.height)
    if source.image.setFilter then pcall(source.image.setFilter, source.image, "nearest", "nearest") end
  end

  -- KIM's HD battlers are composited after the native 240x160 battle surface
  -- so they retain full resolution.  To reproduce FRLG's native draw order
  -- exactly, let the player art continue through the whole 160px playfield,
  -- then re-blit the already-finished native panel (y=112..159) from Game3's
  -- mirrored frame over the HD battlers.  This is not a reconstructed border:
  -- it is the exact panel FRLG already rendered for this frame.
  local FRLG_FIELD_CLIP_Y = 160
  local nativePanelQuad

  local function drawFinishedNativePanel(originX, originY, ux, uy)
    if not (okDisplay and Display and love and love.graphics) then return end
    local canvas
    if type(Display.ensureCanvas) == "function" then
      local ok, value = pcall(Display.ensureCanvas, "main")
      if ok then canvas = value end
    end
    if not canvas then canvas = Display._canvas end
    if not canvas then return end

    local okDims, cw, ch = pcall(function()
      return canvas:getWidth(), canvas:getHeight()
    end)
    if not okDims or cw ~= 240 or ch ~= 160 then return end

    if not nativePanelQuad then
      local ok, q = pcall(love.graphics.newQuad, 0, 112, 240, 48, 240, 160)
      if not ok or not q then return end
      nativePanelQuad = q
    end

    if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
    love.graphics.setColor(1, 1, 1, 1)
    -- originX/originY/ux/uy are derived directly from Game3's Display.fit()
    -- rectangle, so this copy uses the exact same aspect ratio/letterbox transform
    -- as the native FRLG 240x160 frame.
    love.graphics.draw(canvas, nativePanelQuad,
      originX, originY + 112 * uy,
      0, ux, uy)
  end


  -- -----------------------------------------------------------------------
  -- Final-resolution FRLG Summary / Pokédex / script-picture previews
  -- -----------------------------------------------------------------------
  --
  -- These surfaces draw their Pokemon INSIDE Game3's native 240x160 canvas.
  -- Passing KIM through that path rasterizes the art to 64x64 before the final
  -- window upscale.  Hook the exact native draw functions instead: blank only
  -- their 64x64 Pokemon picture, record what/where they drew, then render the
  -- original KIM atlas frame from render.hud after Display.fit().

  local pendingHdPreview = nil

  local POKEDEX_CATEGORY_COORDS = {
    [1] = {
      { pic = { x = 88, y = 24 } },
    },
    [2] = {
      { pic = { x = 24, y = 24 } },
      { pic = { x = 144, y = 72 } },
    },
    [3] = {
      { pic = { x = 8, y = 16 } },
      { pic = { x = 88, y = 72 } },
      { pic = { x = 168, y = 24 } },
    },
    [4] = {
      { pic = { x = 0, y = 16 } },
      { pic = { x = 56, y = 80 } },
      { pic = { x = 120, y = 80 } },
      { pic = { x = 176, y = 16 } },
    },
  }

  local function previewRec(species, shiny, personality)
    return recordFor(species, "front", shiny == true, personality, 0)
  end

  local function addPreviewEntry(entries, rec, x, y, w, h, flip)
    if type(rec) ~= "table" then return end
    entries[#entries + 1] = {
      rec = rec,
      x = tonumber(x) or 0,
      y = tonumber(y) or 0,
      w = tonumber(w) or 64,
      h = tonumber(h) or 64,
      flip = flip == true,
    }
  end

  local function summaryPreviewState(SummaryMenu)
    if not (SummaryMenu and SummaryMenu.open) then return nil end
    local page = tonumber(SummaryMenu._page) or 0
    local slide = SummaryMenu._slide
    if page < 0 or page > 2 or (slide and slide.active) then return nil end

    local party = SummaryMenu._party
    local mon = party and party[tonumber(SummaryMenu._cursor) or 1]
    if not mon or (Pokemon.isEgg and Pokemon.isEgg(mon)) then return nil end

    local personality = tonumber(mon.personality) or 0
    local species = Pokemon.monPicSpecies and Pokemon.monPicSpecies(mon)
      or Pokemon.speciesOf(mon)
    local shiny = Pokemon.isShiny and Pokemon.isShiny(mon) or false
    local rec = previewRec(species, shiny, personality)
    if not rec then return nil end

    local sprites = type(SummaryMenu.leftPaneSprites) == "function"
      and SummaryMenu.leftPaneSprites(page, SummaryMenu._mode) or nil
    local pic = sprites and sprites.pic
    if not pic then return nil end

    local bounce = SummaryMenu._bounce or {}
    local flip = true
    local okChrome, SummaryChrome = pcall(require, "src.ui.game3.summary_chrome")
    if okChrome and SummaryChrome and type(SummaryChrome.manifest) == "function" then
      local okM, manifest = pcall(SummaryChrome.manifest)
      local internalSpecies = tonumber(Pokemon.speciesOf(mon))
      if okM and manifest and manifest.noFlip
          and manifest.noFlip[internalSpecies or -1] then
        flip = false
      end
    end

    local entries = {}
    addPreviewEntry(
      entries, rec,
      (tonumber(pic.x) or 60) - 32,
      (tonumber(pic.y) or 65) - 32 + (tonumber(bounce.dy) or 0),
      64, 64, flip
    )
    return #entries > 0 and { kind = "summary", entries = entries } or nil
  end

  local function dexPreviewRec(Pokedex, species)
    local okDex, Dex = pcall(require, "src.core.game3.dex")
    if not okDex or not Dex then return nil end
    local personality = type(Dex.defaultPersonality) == "function"
      and Dex.defaultPersonality(Pokedex._dex, species) or 0
    personality = tonumber(personality) or 0
    local shiny = type(Pokemon.isShiny) == "function"
      and Pokemon.isShiny({ personality = personality, otId = 8, otSecretId = 0 })
      or false
    local picSpecies = type(Pokemon.picSpecies) == "function"
      and Pokemon.picSpecies(species, personality) or species
    return previewRec(picSpecies, shiny, personality)
  end

  local function pokedexPreviewState(Pokedex)
    if not (Pokedex and Pokedex.open) then return nil end
    local entries = {}

    if Pokedex.screen == "data" or Pokedex.screen == "registration" then
      if tonumber(Pokedex.dataPage or 1) == 2 then return nil end
      local species = Pokedex._regSpecies or Pokedex.selectedSpecies
      local rec = species and dexPreviewRec(Pokedex, species) or nil
      if rec then addPreviewEntry(entries, rec, 152, 24, 64, 64, false) end
      return #entries > 0 and { kind = "pokedex", entries = entries } or nil
    end

    if Pokedex.screen ~= "category_grid" then return nil end

    local okDex, Dex = pcall(require, "src.core.game3.dex")
    local okData, PokedexData = pcall(require, "src.core.game3.pokedex_data")
    if not okDex or not Dex or not okData or not PokedexData
        or type(PokedexData.getUnlockedCategoryPages) ~= "function" then
      return nil
    end

    local pages = PokedexData.getUnlockedCategoryPages(
      Pokedex.currentCategory, Pokedex._dex
    )
    local page = pages and pages[tonumber(Pokedex.categoryPage) or 1]
    local mons = page and page.mons or {}
    local layout = POKEDEX_CATEGORY_COORDS[#mons]
    if not layout then return nil end

    for i, species in ipairs(mons) do
      local pos = layout[i] and layout[i].pic
      local seen = type(Dex.isSeen) == "function"
        and Dex.isSeen(Pokedex._dex, species)
      if pos and seen then
        local rec = dexPreviewRec(Pokedex, species)
        if rec then addPreviewEntry(entries, rec, pos.x, pos.y, 64, 64, false) end
      end
    end

    return #entries > 0 and { kind = "pokedex", entries = entries } or nil
  end

  local function monPicPreviewState(MonPic)
    if not (MonPic and MonPic.active) then return nil end
    local species = tonumber(MonPic.species)
    if not species or species <= 0 then return nil end

    local personality = 0x8000
    local picSpecies = type(Pokemon.picSpecies) == "function"
      and Pokemon.picSpecies(species, personality) or species
    local rec = previewRec(picSpecies, false, personality)
    if not rec then return nil end

    local tx = tonumber(MonPic.left) or 10
    local ty = tonumber(MonPic.top) or 3
    local entries = {}
    addPreviewEntry(entries, rec, tx * 8 + 8, ty * 8 + 8, 64, 64, false)
    return #entries > 0 and { kind = "mon_pic", entries = entries } or nil
  end

  local function drawHdPreviewEntry(entry, originX, originY, ux, uy)
    local rec = entry and entry.rec
    if not rec then return false end
    local source = sourceFor(rec)
    if not source then return false end
    local quad = sourceQuad(source, frameFor(rec))
    if not quad then return false end

    local boxW = tonumber(entry.w) or 64
    local boxH = tonumber(entry.h) or 64
    local scale = tonumber(rec.displayScale)
    if not scale or scale <= 0 then scale = 0.33 end
    scale = math.min(
      scale,
      math.max(1, boxW - 2) / source.width,
      math.max(1, boxH - 2) / source.height
    )

    local drawW = source.width * scale
    local drawH = source.height * scale
    local dx = (tonumber(entry.x) or 0) + (boxW - drawW) * 0.5

    -- These FRLG preview boxes are display windows, not ground-contact battle
    -- slots.  Center the HD art vertically instead of bottom-aligning it.
    local dy = (tonumber(entry.y) or 0) + (boxH - drawH) * 0.5

    love.graphics.push("all")
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")
    love.graphics.setScissor(
      originX + (tonumber(entry.x) or 0) * ux,
      originY + (tonumber(entry.y) or 0) * uy,
      boxW * ux,
      boxH * uy
    )
    love.graphics.setColor(1, 1, 1, 1)
    if source.image.setFilter then
      pcall(source.image.setFilter, source.image, "linear", "linear")
    end

    if entry.flip then
      love.graphics.draw(
        source.image, quad,
        originX + (dx + drawW) * ux,
        originY + dy * uy,
        0, -scale * ux, scale * uy
      )
    else
      love.graphics.draw(
        source.image, quad,
        originX + dx * ux,
        originY + dy * uy,
        0, scale * ux, scale * uy
      )
    end

    if source.image.setFilter then
      pcall(source.image.setFilter, source.image, "nearest", "nearest")
    end
    love.graphics.setScissor()
    love.graphics.pop()
    return true
  end

  local function installHdPreviewDrawBridges()
    local blank = battlePlaceholder()
    if not blank or not blank.image then return false end

    local okSummary, SummaryMenu = pcall(require, "src.ui.game3.summary_menu")
    if okSummary and SummaryMenu and type(SummaryMenu.draw) == "function"
        and not SummaryMenu._kantoInMotionHdPreviewDraw then
      local nativeDraw = SummaryMenu.draw
      SummaryMenu._kantoInMotionHdPreviewDraw = nativeDraw
      SummaryMenu.draw = function(...)
        local state = summaryPreviewState(SummaryMenu)
        local nativeMonFrontPic = Pokemon.monFrontPic
        if state and type(nativeMonFrontPic) == "function" then
          Pokemon.monFrontPic = function() return blank end
        end

        local ok, err = pcall(nativeDraw, ...)
        Pokemon.monFrontPic = nativeMonFrontPic
        if state then pendingHdPreview = state end
        if not ok then error(err, 0) end
      end
    end

    local okDexUi, Pokedex = pcall(require, "src.ui.game3.pokedex")
    if okDexUi and Pokedex and type(Pokedex.draw) == "function"
        and not Pokedex._kantoInMotionHdPreviewDraw then
      local nativeDraw = Pokedex.draw
      Pokedex._kantoInMotionHdPreviewDraw = nativeDraw
      Pokedex.draw = function(...)
        local state = pokedexPreviewState(Pokedex)
        local nativeDexFrontPic = Pokemon.dexFrontPic
        if state and type(nativeDexFrontPic) == "function" then
          Pokemon.dexFrontPic = function() return blank end
        end

        local ok, err = pcall(nativeDraw, ...)
        Pokemon.dexFrontPic = nativeDexFrontPic
        if state then pendingHdPreview = state end
        if not ok then error(err, 0) end
      end
    end

    local okMonPic, MonPic = pcall(require, "src.ui.game3.mon_pic")
    if okMonPic and MonPic and type(MonPic.draw) == "function"
        and not MonPic._kantoInMotionHdPreviewDraw then
      local nativeDraw = MonPic.draw
      MonPic._kantoInMotionHdPreviewDraw = nativeDraw
      MonPic.draw = function(...)
        local state = monPicPreviewState(MonPic)
        local oldImg, oldW, oldH = MonPic._img, MonPic._w, MonPic._h

        if state then
          MonPic._img = blank.image
          MonPic._w, MonPic._h = 64, 64
        end

        local ok, err = pcall(nativeDraw, ...)
        MonPic._img, MonPic._w, MonPic._h = oldImg, oldW, oldH
        if state then pendingHdPreview = state end
        if not ok then error(err, 0) end
      end
    end

    return true
  end

  pcall(installHdPreviewDrawBridges)
  mod.events:on("game.ready", function()
    pcall(installHdPreviewDrawBridges)
  end)

  if mod.hooks and type(mod.hooks.wrap) == "function" then
    mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
      nextFn(game, viewport)

      local state = pendingHdPreview
      pendingHdPreview = nil
      if not state or type(state.entries) ~= "table" then return end

      local originX, originY, ux, uy = menuFrameMetrics(game, viewport)
      for _, entry in ipairs(state.entries) do
        drawHdPreviewEntry(entry, originX, originY, ux, uy)
      end
    end, 9700)
  end

  -- Suppress only FRLG's native terrain layer while an authored KIM HD
  -- background is actually available.  Every native element drawn after the
  -- terrain call (trainers, particles, HP boxes, menus, text, etc.) stays in
  -- Game3's 240x160 canvas and is composited back over the HD scene below.
  if okBg and type(BattleBg) == "table" and type(BattleBg.draw) == "function"
      and not BattleBg._kantoInMotionFrlgHdBackground then
    local nativeBattleBgDraw = BattleBg.draw
    BattleBg._kantoInMotionFrlgHdBackground = nativeBattleBgDraw
    BattleBg.draw = function(...)
      local st = okBattle and Battle and ((Battle.getState and Battle.getState()) or Battle._st) or nil
      local image = st and select(1, frlgBackdropImage(mod.game, st)) or nil
      if image then
        love.graphics.push("all")
        love.graphics.setShader()
        love.graphics.setBlendMode("replace")
        love.graphics.setColor(0, 0, 0, 0)
        love.graphics.rectangle("fill", 0, 0, 240, 160)
        love.graphics.pop()
        return true
      end
      return nativeBattleBgDraw(...)
    end
  end

  if okBattle and type(Battle) == "table" and mod.hooks and type(mod.hooks.wrap) == "function" then
    mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
      nextFn(game, viewport)
      if pendingHdPreview then return end
      if type(Battle.isActive) ~= "function" or not Battle.isActive() then return end
      local st = type(Battle.getState) == "function" and Battle.getState() or Battle._st
      if type(st) ~= "table" then return end

      local wantSprites = mod.options:get("battleSprites") ~= false
      local bgImage, bgBackdrop = frlgBackdropImage(game, st)
      local wantBackground = bgImage ~= nil
      if not wantSprites and not wantBackground then return end

      local originX, originY, ux, uy, uiw = frameMetrics(game, viewport)
      -- hdGeo contains the authored KIM player/enemy platform anchors used
      -- to solve one global FRLG background transform.
      local hdGeo = wantBackground and frlgHdGeometry(bgBackdrop) or nil
      love.graphics.push("all")
      love.graphics.origin()
      love.graphics.setShader()
      love.graphics.setBlendMode("alpha")

      if wantBackground and hdGeo then
        love.graphics.setScissor(originX, originY, 240 * ux, 160 * uy)
        drawFrlgHdBackground(bgImage, originX, originY, ux, uy, hdGeo)
        love.graphics.setScissor()
      end

      -- Let the HD battlers occupy the full native playfield.  The completed
      -- FRLG panel is restored over y=112..159 after the HD draw, reproducing
      -- the same visual occlusion as the native 64x64 battler path.
      love.graphics.setScissor(originX, originY, uiw * ux, FRLG_FIELD_CLIP_Y * uy)

      if wantSprites then
        if not st.double then
          -- Enemy first, then FRLG's mid-field particle band, then player,
          -- then the true foreground particle band.  On the native-background
          -- path this restores attacks above the HD cards instead of leaving
          -- them trapped underneath the final-resolution Pokemon.
          if not (st.absent and st.absent[1]) then
            local enemyInfo = battlerRecord(st, 1)
            if enemyInfo then drawHdBattler(enemyInfo, st, 1, originX, originY, ux, uy, nil) end
          end
          if not wantBackground and okAnim and type(BattleAnim.drawParticles) == "function" then
            withNativeViewport(originX, originY, ux, uy, function()
              BattleAnim.drawParticles(101, 199)
            end)
          end

          if not (st.absent and st.absent[0]) then
            local playerInfo = battlerRecord(st, 0)
            if playerInfo then drawHdBattler(playerInfo, st, 0, originX, originY, ux, uy, nil) end
          end
          if not wantBackground and okAnim and type(BattleAnim.drawParticles) == "function" then
            withNativeViewport(originX, originY, ux, uy, function()
              BattleAnim.drawParticles(201, 999)
            end)
          end
        else
          local order
          if okAnim and type(BattleAnim.monDrawOrder) == "function" then
            local ok, value = pcall(BattleAnim.monDrawOrder, st)
            if ok and type(value) == "table" then order = value end
          end
          order = order or { 1, 3, 2, 0 }
          for _, id in ipairs(order) do
            if not (st.absent and st.absent[id]) then
              local info = battlerRecord(st, id)
              if info then drawHdBattler(info, st, id, originX, originY, ux, uy, nil) end
            end
          end
          if not wantBackground and okAnim and type(BattleAnim.drawParticles) == "function" then
            withNativeViewport(originX, originY, ux, uy, function()
              BattleAnim.drawParticles(201, 999)
            end)
          end
        end
      end

      love.graphics.setScissor()

      if wantBackground then
        -- Put FRLG's normal full-width message panel behind the split action
        -- menu first.  The exact native foreground canvas is then restored on
        -- top, so Fight/Bag/Pokémon/Run and move-menu chrome stay source-owned.
        drawFullWidthPanelBacking(originX, originY, ux, uy)

        -- The native terrain was made transparent inside Renderer.canvas, so
        -- this restores the exact FRLG trainer/VFX/HUD/UI layer over KIM.
        drawNativeForegroundLayer(originX, originY, ux, uy)
      elseif wantSprites then
        -- Native background/HUD are already visible below the HD cards.  Only
        -- the bottom panel must be re-applied to preserve the confirmed v10
        -- player-behind-dialog layering.
        drawFinishedNativePanel(originX, originY, ux, uy)
      end

      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.pop()
    end, 9500)
  end

  -- Install the shared #001-386 HD menu-icon provider after the FRLG
  -- compatibility layer has finished wrapping src.core.game3.pokemon.
  do
    local okIcons, iconInstaller = pcall(function()
      local src = assert(mod:read("lib/menu_icons.lua"))
      local loader = loadstring or load
      return assert(loader(src, "@" .. mod.path .. "/lib/menu_icons.lua"))()
    end)
    if okIcons and type(iconInstaller) == "function" then
      okIcons, iconInstaller = pcall(iconInstaller, mod)
    end
    if okIcons and iconInstaller then
      mod._kantoInMotionMenuIcons = true
    elseif not okIcons and mod.log and mod.log.error then
      mod.log:error("FRLG HD menu icon bridge failed: %s", tostring(iconInstaller))
    end
  end

  -- Small public surface for future FRLG UI/battle integrations.  Numeric Dex
  -- ids are intentional: Game3 internal ids diverge from National Dex after
  -- Celebi, while the supplied KIM asset packs remain National-Dex numbered.
  mod.exports = mod.exports or {}
  mod.exports.apiVersion = 1
  mod.exports.generations = { "hd" }
  mod.exports.defaultGeneration = "hd"
  mod.exports.gen3NativeUi = true
  mod.exports.frlgHdBackgrounds = true
  mod.exports.currentFrlgBackdrop = function()
    local st = okBattle and Battle and ((Battle.getState and Battle.getState()) or Battle._st) or nil
    return st and frlgBackdrop(mod.game, st) or nil
  end
  mod.exports.maxNationalDex = 386
  mod.exports.frlgProviderInstalled = function()
    return providerInstalled == true
  end
  mod.exports.hasNationalSprite = function(dex)
    return type(byDex[tonumber(dex)]) == "table"
  end
  mod.exports.getNationalDex = function(gen3Species)
    return nationalDex(gen3Species)
  end

  if mod.log and mod.log.info then
    local count = 0
    for dex = 1, 386 do if byDex[dex] then count = count + 1 end end
    mod.log:info("FRLG bridge active with %d National Dex HD sprite records; native FRLG UI retained", count)
  end
end
