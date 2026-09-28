-- Kanto in Motion - shared Pokemon menu icon bridge (National Dex #001-386)
--
-- v3 keeps Gen 1's confirmed-good path intact, but changes Gen 2 and Gen 3
-- presentation so the supplied HD icon artwork is sampled at FINAL WINDOW
-- resolution instead of being crushed into a 16x16 / 32x32 native canvas and
-- then nearest-neighbour magnified with the rest of the game.
--
-- Asset presentations:
--   normal/   : 32x64 two-frame sheet used by KIM Modern UI / Gen 1
--   native16/ : 16x32 fallback/native sheet (Gen 1; retained for compatibility)
--   native32/ : 32x64 fallback/native FRLG sheet (never the final v3 picture)
--   hd/normal/: original HD Rescaled Icon PNG, one image per National Dex id
--
-- Gen 2 party icons are suppressed only on the 160x144 source surface and
-- replayed from hd/normal in render.hud.  Gen 3 records KIM icon draw calls on
-- Game3's 240x160 surface and replays those same positions at final resolution.
-- This keeps native UI geometry/animation while avoiding the pixelated upscale.
return function(mod)
  local generation = tonumber(mod.generation) or 1

  local ROOTS = {
    modern = { normal = "assets/menu_icons/normal/", shiny = "assets/menu_icons/shiny/", size = 32 },
    native16 = { normal = "assets/menu_icons/native16/normal/", shiny = "assets/menu_icons/native16/shiny/", size = 16 },
    native32 = { normal = "assets/menu_icons/native32/normal/", shiny = "assets/menu_icons/native32/shiny/", size = 32 },
  }
  local HD_ROOT = {
    normal = "assets/menu_icons/hd/normal/",
    shiny = "assets/menu_icons/hd/shiny/",
  }
  local TRANSPARENT16 = "assets/menu_icons/transparent16.png"

  local function enabled()
    return not (mod.options and type(mod.options.get) == "function"
      and mod.options:get("menuIcons") == false)
  end

  local function validDex(dex)
    dex = tonumber(dex)
    return dex and dex >= 1 and dex <= 386 and math.floor(dex) == dex
  end

  local function padDex(dex)
    return string.format("%03d", math.floor(tonumber(dex) or 0))
  end

  local function monIsEgg(mon)
    if type(mon) ~= "table" then return false end
    return mon.isEgg == true or mon.egg == true or mon.species == "EGG"
  end

  local function monIsShiny(mon)
    if type(mon) ~= "table" then return false end
    if mon.shiny == true or mon.isShiny == true or mon.is_shiny == true then return true end
    local dvs = mon.dvs or mon.DVs or mon.dv
    if type(dvs) == "table" then
      local okStats, Stats = pcall(require, "src.pokemon.Stats")
      if okStats and type(Stats) == "table" and type(Stats.isShiny) == "function" then
        local ok, value = pcall(Stats.isShiny, dvs)
        if ok and value == true then return true end
      end
    end
    return false
  end

  local function nationalDexFor(game, mon, species)
    if monIsEgg(mon) then return nil end
    species = species or (type(mon) == "table" and mon.species or nil)
    local data = game and game.data
    local def = data and data.pokemon and species ~= nil and data.pokemon[species] or nil
    local dex = type(mon) == "table" and tonumber(mon.nationalDex or mon.dex or mon.speciesId) or nil
    dex = dex or (type(def) == "table" and tonumber(def.nationalDex or def.dex))
    if not dex and type(species) == "number" then dex = tonumber(species) end
    if validDex(dex) then return dex end
    return nil
  end

  local function absolute(rel)
    if not rel then return nil end
    if mod.assets and type(mod.assets.path) == "function" then
      local ok, path = pcall(mod.assets.path, mod.assets, rel)
      if ok and path then return path end
    end
    return rel
  end

  ---------------------------------------------------------------------------
  -- Native / Modern two-frame sheets

  local imageCache, quadCache, missing = {}, {}, {}

  local function relPath(dex, shiny, presentation)
    local root = ROOTS[presentation]
    if not root or not validDex(dex) then return nil end
    local base = shiny and root.shiny or root.normal
    return base .. padDex(dex) .. ".png"
  end

  local function loadSheet(rel, frameSize)
    if not rel or missing[rel] then return nil end
    local cached = imageCache[rel]
    if cached ~= nil then return cached or nil, quadCache[rel] end
    local ok, image = pcall(function()
      if mod.assets and type(mod.assets.image) == "function" then
        return mod.assets:image(rel)
      end
      return love.graphics.newImage(absolute(rel))
    end)
    if not ok or not image then
      imageCache[rel] = false
      missing[rel] = true
      return nil
    end
    if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
    local iw, ih = image:getDimensions()
    frameSize = tonumber(frameSize) or iw
    if iw < frameSize or ih < frameSize then
      imageCache[rel] = false
      missing[rel] = true
      return nil
    end
    local q0 = love.graphics.newQuad(0, 0, frameSize, frameSize, iw, ih)
    local q1 = ih >= frameSize * 2
      and love.graphics.newQuad(0, frameSize, frameSize, frameSize, iw, ih) or q0
    imageCache[rel] = image
    quadCache[rel] = { [0] = q0, [1] = q1 }
    return image, quadCache[rel]
  end

  local function iconForDex(dex, shiny, presentation)
    local root = ROOTS[presentation]
    if not root then return nil end
    local rel = relPath(dex, shiny == true, presentation)
    local image, quads = loadSheet(rel, root.size)
    if not image and shiny then
      rel = relPath(dex, false, presentation)
      image, quads = loadSheet(rel, root.size)
    end
    if not image then return nil end
    return image, quads, rel, root.size
  end

  local function iconForMon(game, mon, presentation)
    local dex = nationalDexFor(game, mon)
    if not dex then return nil end
    local image, quads, rel, size = iconForDex(dex, monIsShiny(mon), presentation)
    return image, quads, rel, size, dex
  end

  ---------------------------------------------------------------------------
  -- Original-resolution icon art used by Gen 2 / Gen 3 final-window replay

  local hdCache, hdMissing = {}, {}

  local function hdRel(dex, shiny)
    if not validDex(dex) then return nil end
    return (shiny and HD_ROOT.shiny or HD_ROOT.normal) .. padDex(dex) .. ".png"
  end

  local function loadHd(rel)
    if not rel or hdMissing[rel] then return nil end
    local cached = hdCache[rel]
    if cached ~= nil then return cached or nil end
    local ok, image = pcall(function()
      if mod.assets and type(mod.assets.image) == "function" then
        return mod.assets:image(rel)
      end
      return love.graphics.newImage(absolute(rel))
    end)
    if not ok or not image then
      hdCache[rel] = false
      hdMissing[rel] = true
      return nil
    end
    -- Linear filtering is intentional HERE.  These images are drawn directly
    -- to the final window rather than into the pixel-art source canvas.
    if image.setFilter then pcall(image.setFilter, image, "linear", "linear") end
    hdCache[rel] = image
    return image
  end

  local function hdForDex(dex, shiny)
    local rel = hdRel(dex, shiny == true)
    local image = loadHd(rel)
    if not image and shiny then
      rel = hdRel(dex, false)
      image = loadHd(rel)
    end
    if not image then return nil end
    return image, rel
  end

  local function hdForMon(game, mon)
    local dex = nationalDexFor(game, mon)
    if not dex then return nil end
    local image, rel = hdForDex(dex, monIsShiny(mon))
    return image, rel, dex
  end

  ---------------------------------------------------------------------------

  local okPalette, PaletteFX = pcall(require, "src.render.PaletteFX")
  local function markTrueColor(x, y, w, h)
    if okPalette and PaletteFX and type(PaletteFX.markTrueColor) == "function" then
      pcall(PaletteFX.markTrueColor, x, y, w, h)
    end
  end

  local function frameFor(mon, selected, counter, forceAlt, hpSpeed, clock)
    if mod.options and type(mod.options.get) == "function"
        and mod.options:get("animate") == false then return 0 end
    if forceAlt then return 1 end
    if selected and hpSpeed then
      local hp = tonumber(mon and mon.hp) or 0
      local maxHp = tonumber(mon and (mon.maxHp or mon.maxhp))
        or (mon and mon.stats and tonumber(mon.stats.hp)) or 1
      local px = math.floor(hp * 48 / math.max(1, maxHp))
      local speed = px >= 27 and 5 or px >= 10 and 16 or 32
      return math.floor((tonumber(counter) or 0) / speed) % 2
    end
    if clock ~= nil then return math.floor((tonumber(clock) or 0) / 16) % 2 end
    local now = love and love.timer and love.timer.getTime and love.timer.getTime() or 0
    return math.floor(now * 2) % 2
  end

  local function drawNative(game, mon, x, y, presentation, opts)
    if not enabled() then return false end
    local image, quads, _, size = iconForMon(game, mon, presentation)
    if not image or not quads then return false end
    opts = opts or {}
    local frame = frameFor(mon, opts.selected, opts.counter, opts.forceAlt,
      opts.hpSpeed, opts.clock)
    local quad = quads[frame] or quads[0]
    if not quad then return false end
    markTrueColor(x, y, size, size)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, quad, x, y)
    return true
  end

  -- Final-window Modern UI bypass. HGSS_SPRITES may replace the native icon
  -- registry after KIM loads; Modern UI therefore asks KIM directly while
  -- POKEMON ICONS is ON.
  mod._kantoInMotionMenuIconForModernUi = function(game, mon)
    if not enabled() then return nil end
    local _, _, rel, size = iconForMon(game, mon, "modern")
    if not rel then return nil end
    return absolute(rel), size or 32, 2
  end

  -- Final-window Gen 2 Modern UI can use the untouched HD Rescaled Icon PNG
  -- directly instead of first shrinking it through the 16x16 native canvas.
  mod._kantoInMotionHdMenuIconForModernUi = function(game, mon)
    if not enabled() then return nil end
    local image, rel, dex = hdForMon(game, mon)
    if not image or not rel then return nil end
    return absolute(rel), dex
  end

  ---------------------------------------------------------------------------
  -- Gen 1 / Gen 2 pokemon.icon seam

  if generation ~= 3 and mod.hooks and type(mod.hooks.wrap) == "function" then
    mod.hooks:wrap("pokemon.icon", function(nextFn, vanillaPath, ctx)
      if not enabled() then return nextFn(vanillaPath, ctx) end
      ctx = ctx or {}
      local mon = ctx.mon
      local pseudoGame = { data = ctx.data }
      local dex = nationalDexFor(pseudoGame, mon, ctx.species)
      if not dex then return nextFn(vanillaPath, ctx) end

      if generation == 2 then
        -- Gen 2's source party pass still needs to run because it paints the
        -- held-item/mail replacement tile.  Hand it a fully transparent
        -- 16x32 icon sheet; v3 replays only the Pokemon body in render.hud.
        ctx.trueColor = true
        return absolute(TRANSPARENT16), true
      end

      local _, _, rel = iconForDex(dex, monIsShiny(mon), "native16")
      if not rel then return nextFn(vanillaPath, ctx) end
      ctx.trueColor = true
      return absolute(rel), true
    end)
  end

  ---------------------------------------------------------------------------
  -- Gen 1: confirmed-good v2 path remains unchanged.

  if generation == 1 then
    local okParty, PartyMenu = pcall(require, "src.ui.PartyMenu")
    if okParty and type(PartyMenu) == "table" and type(PartyMenu.drawIcon) == "function"
        and not PartyMenu.__kimMenuIconsV3 then
      local upstreamDrawIcon = PartyMenu.drawIcon
      PartyMenu.drawIcon = function(game, mon, x, y, selected, counter, forceAlt, obp)
        if drawNative(game, mon, x, y, "native16", {
          selected = selected, counter = counter, forceAlt = forceAlt, hpSpeed = true,
        }) then return true end
        return upstreamDrawIcon(game, mon, x, y, selected, counter, forceAlt, obp)
      end
      PartyMenu.__kimMenuIconsV3 = true
    end

  ---------------------------------------------------------------------------
  -- Gen 2: preserve native coordinates/layout, suppress the low-resolution
  -- Pokemon body, and redraw the original icon directly in final window space.

  elseif generation == 2 then
    local gen2Draws = {}
    local okParty, PartyMenu = pcall(require, "src.ui.gen2.PartyMenu")
    if okParty and type(PartyMenu) == "table" and type(PartyMenu.drawIcon) == "function"
        and not PartyMenu.__kimMenuIconsV3 then
      local upstreamDrawIcon = PartyMenu.drawIcon
      local upstreamDrawPanel = PartyMenu.drawPanel

      if type(upstreamDrawPanel) == "function" then
        PartyMenu.drawPanel = function(self, ...)
          gen2Draws = {}
          return upstreamDrawPanel(self, ...)
        end
      end

      PartyMenu.drawIcon = function(self, mon, x, y, ...)
        if enabled() then
          local image, _, dex = hdForMon(self and self.game, mon)
          if image then
            gen2Draws[#gen2Draws + 1] = {
              image = image, dex = dex,
              x = tonumber(x) or 0, y = tonumber(y) or 0,
              clock = self and self.clock,
            }
          end
        end
        -- With icons ON pokemon.icon resolves to transparent16.png, so this
        -- keeps Gold/Crystal's item/mail replacement tile without painting a
        -- low-res Pokemon underneath the final-window replay.
        return upstreamDrawIcon(self, mon, x, y, ...)
      end
      PartyMenu.__kimMenuIconsV3 = true
    end

    if mod.hooks and type(mod.hooks.wrap) == "function" then
      mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
        nextFn(game, viewport)
        if not enabled() or #gen2Draws == 0 then
          gen2Draws = {}
          return
        end
        local top = game and game.stack and game.stack:top()
        if top and top.screenId and top.screenId ~= "Gen2PartyMenu" then
          gen2Draws = {}
          return
        end

        local gx = tonumber(viewport and viewport.gameX) or 0
        local gy = tonumber(viewport and viewport.gameY) or 0
        local sx = tonumber(viewport and viewport.gameWidth)
        local sy = tonumber(viewport and viewport.gameHeight)
        sx = sx and sx / 160 or tonumber(viewport and viewport.scale) or 1
        sy = sy and sy / 144 or tonumber(viewport and viewport.scale) or sx

        local draws = gen2Draws
        gen2Draws = {}
        local G = love.graphics
        G.push("all")
        G.origin()
        G.setShader()
        G.setColor(1, 1, 1, 1)
        for _, call in ipairs(draws) do
          local image = call.image
          if image then
            local iw, ih = image:getDimensions()
            -- 17 logical pixels reproduces v2's apparent 13px Cyndaquil body
            -- while sampling the original 36/40px source directly to screen.
            local target = 17
            local fit = target / math.max(1, iw, ih)
            local dw, dh = iw * fit, ih * fit
            local frame = frameFor(nil, false, nil, false, false, call.clock)
            local lx = call.x + (16 - dw) * 0.5
            local ly = call.y + (16 - dh) * 0.5 + frame
            G.draw(image, gx + lx * sx, gy + ly * sy, 0, fit * sx, fit * sy)
          end
        end
        G.pop()
      end)
    end

  ---------------------------------------------------------------------------
  -- Gen 3: record KIM icon draws on the 240x160 Game3 source surface and
  -- replay the original-resolution artwork after Display.fit().  This catches
  -- party OAM, PC boxes, Pokedex, Summary and other normal Pokemon.icon users
  -- without rewriting each screen's geometry.

  else
    local okPokemon, Pokemon = pcall(require, "src.core.game3.pokemon")
    if not okPokemon or type(Pokemon) ~= "table" then return false end
    if Pokemon._kantoInMotionMenuIconsV3Installed then return true end

    local upstreamIcon = Pokemon.icon
    local upstreamMonIcon = Pokemon.monIcon
    local upstreamDexIcon = Pokemon.dexIcon
    local nativeImageMeta = setmetatable({}, { __mode = "k" })
    local recorded = {}

    local function game3Dex(species)
      species = tonumber(species)
      if not species then return nil end
      if type(Pokemon.national) == "function" then
        local ok, dex = pcall(Pokemon.national, species)
        if ok and validDex(dex) then return tonumber(dex) end
      end
      if validDex(species) then return species end
      return nil
    end

    local function entryForDex(dex, shiny)
      if not enabled() then return nil end
      local image, quads = iconForDex(dex, shiny, "native32")
      if not image or not quads then return nil end
      nativeImageMeta[image] = { dex = dex, shiny = shiny == true }
      return {
        image = image, w = 32, h = 32, sheetH = 64,
        frames = 2, quads = quads, trueColor = true,
        _kantoInMotionMenuIcon = true,
      }
    end

    Pokemon.icon = function(species)
      if enabled() then
        local dex = game3Dex(species)
        local entry = dex and entryForDex(dex, false) or nil
        if entry then return entry end
      end
      return type(upstreamIcon) == "function" and upstreamIcon(species) or nil
    end

    Pokemon.monIcon = function(mon)
      if enabled() and type(mon) == "table"
          and not (type(Pokemon.isEgg) == "function" and Pokemon.isEgg(mon)) then
        local species
        if type(Pokemon.monPicSpecies) == "function" then
          local ok, value = pcall(Pokemon.monPicSpecies, mon)
          if ok then species = value end
        end
        if not species and type(Pokemon.speciesOf) == "function" then
          local ok, value = pcall(Pokemon.speciesOf, mon)
          if ok then species = value end
        end
        species = species or mon.species
        local dex = game3Dex(species)
        local shiny = false
        if type(Pokemon.isShiny) == "function" then
          local ok, value = pcall(Pokemon.isShiny, mon)
          shiny = ok and value == true
        end
        local entry = dex and entryForDex(dex, shiny) or nil
        if entry then return entry end
      end
      return type(upstreamMonIcon) == "function" and upstreamMonIcon(mon) or nil
    end

    if type(upstreamDexIcon) == "function" then
      Pokemon.dexIcon = function(species, personality)
        if enabled() then
          local shown = species
          if type(Pokemon.picSpecies) == "function" then
            local ok, value = pcall(Pokemon.picSpecies, species, personality)
            if ok then shown = value end
          end
          local dex = game3Dex(shown)
          local entry = dex and entryForDex(dex, false) or nil
          if entry then return entry end
        end
        return upstreamDexIcon(species, personality)
      end
    end

    local function isQuad(value)
      if value == nil then return false end
      local ok, yes = pcall(function()
        return type(value.typeOf) == "function" and value:typeOf("Quad")
      end)
      return ok and yes == true
    end

    local function game3SourceCanvas()
      if not (love and love.graphics and love.graphics.getCanvas) then return false end
      local canvas = love.graphics.getCanvas()
      if type(canvas) == "table" and type(canvas.getDimensions) ~= "function" then
        canvas = canvas[1] or canvas.canvas
      end
      if not canvas then return false end
      local ok, w, h = pcall(function() return canvas:getDimensions() end)
      return ok and tonumber(w) == 240 and tonumber(h) == 160
    end

    local bridge = {}
    bridge.replaying = false
    bridge.intercept = function(drawable, ...)
      if bridge.replaying or not enabled() or not game3SourceCanvas() then return false end
      local meta = nativeImageMeta[drawable]
      if not meta then return false end
      recorded[#recorded + 1] = { meta = meta, args = { ... } }
      return true
    end

    -- One guarded global seam is considerably less invasive than replacing
    -- every FRLG party/box/dex/summary screen.  It only handles Image objects
    -- registered above AND only while the active target canvas is 240x160.
    local G = love and love.graphics
    if G and type(G.draw) == "function" then
      G.__kimMenuIconV3Bridge = bridge
      if not G.__kimMenuIconV3Wrapped then
        local rawDraw = G.draw
        G.__kimMenuIconV3RawDraw = rawDraw
        G.draw = function(drawable, ...)
          local active = G.__kimMenuIconV3Bridge
          if active and type(active.intercept) == "function" then
            local ok, handled = pcall(active.intercept, drawable, ...)
            if ok and handled then return end
          end
          return rawDraw(drawable, ...)
        end
        G.__kimMenuIconV3Wrapped = true
      end
    end

    local function parseDraw(args)
      local i = 1
      if isQuad(args[1]) then i = 2 end
      local x = tonumber(args[i]) or 0
      local y = tonumber(args[i + 1]) or 0
      local r = tonumber(args[i + 2]) or 0
      local sx = tonumber(args[i + 3]) or 1
      local sy = tonumber(args[i + 4]) or sx
      local ox = tonumber(args[i + 5]) or 0
      local oy = tonumber(args[i + 6]) or 0
      return x, y, r, sx, sy, ox, oy
    end

    local function currentGame3ScreenId()
      local Stack = package.loaded["src.ui.game3.stack"]
      if not Stack then
        local ok, value = pcall(require, "src.ui.game3.stack")
        if ok then Stack = value end
      end
      local top = Stack and type(Stack.top) == "function" and Stack.top() or nil
      return top and top.id or nil
    end

    if mod.hooks and type(mod.hooks.wrap) == "function" then
      mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
        nextFn(game, viewport)

        local calls = recorded
        recorded = {}
        if not enabled() or #calls == 0 then return end

        local gx = tonumber(viewport and viewport.gameX) or 0
        local gy = tonumber(viewport and viewport.gameY) or 0
        local vx = tonumber(viewport and viewport.gameWidth)
        local vy = tonumber(viewport and viewport.gameHeight)
        local scaleX = vx and vx / 240 or tonumber(viewport and viewport.scale) or 1
        local scaleY = vy and vy / 160 or tonumber(viewport and viewport.scale) or scaleX
        local screenId = currentGame3ScreenId()

        -- Game3:_drawHud() reports Display.fit(), but normal FRLG menus are
        -- actually presented by Renderer:endFrame().  Touch/mobile playfield
        -- cutouts can move the Renderer-owned frame independently in one axis:
        -- portrait mainly changes Y, landscape mainly changes X.  Replaying an
        -- HD icon through Display.fit() therefore makes it look too low in
        -- portrait and too far right in landscape even though its native OAM
        -- coordinate is correct.
        --
        -- Use Renderer:frameRects() for non-battle mobile menus so the HD body
        -- lands on the exact rectangle that presented the native 240x160 UI.
        -- During an active battle, v6 intentionally uses Display.presentFlat()
        -- and Display.fit(), so keep the viewport metrics in that case.
        local mobileMenu = false
        if love and love.system and love.system.getOS then
          local host = love.system.getOS()
          mobileMenu = host == "Android" or host == "iOS"
        end
        if mobileMenu then
          local battleActive = false
          local okBattle, Battle = pcall(require, "src.core.game3.battle")
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
              local okRect, rect = pcall(renderer.frameRects, renderer)
              if okRect and type(rect) == "table"
                  and tonumber(rect.uox) and tonumber(rect.uoy)
                  and tonumber(rect.Ux) and tonumber(rect.Uy)
                  and rect.Ux > 0 and rect.Uy > 0 then
                gx, gy = rect.uox, rect.uoy
                scaleX, scaleY = rect.Ux, rect.Uy
              end
            end
          end
        end

        bridge.replaying = true
        G.push("all")
        G.origin()
        G.setShader()
        G.setColor(1, 1, 1, 1)

        local function drawFinalIcon(meta, cx, cy, r, dsx, dsy)
          local image = meta and hdForDex(meta.dex, meta.shiny)
          if not image then return false end
          local iw, ih = image:getDimensions()
          local target = 24
          local fit = target / math.max(1, iw, ih)
          local signX = (tonumber(dsx) or 1) < 0 and -1 or 1
          local signY = (tonumber(dsy) or 1) < 0 and -1 or 1
          local drawSx = fit * math.abs(tonumber(dsx) or 1) * scaleX * signX
          local drawSy = fit * math.abs(tonumber(dsy) or 1) * scaleY * signY
          G.draw(image,
            gx + cx * scaleX,
            gy + cy * scaleY,
            tonumber(r) or 0, drawSx, drawSy, iw * 0.5, ih * 0.5)
          return true
        end

        local drewPartyFromOam = false
        if screenId == "party" then
          -- PartyMenu's OAM sprites already contain the authoritative FRLG
          -- icon centres.  On mobile the UI plane can carry an extra
          -- presentation transform; the raw love.graphics.draw coordinates
          -- intercepted below are pre-transform and therefore drift on replay.
          -- Reading OAM directly keeps portrait/landscape placement identical
          -- to the native slot geometry while retaining the selected bounce.
          local okParty, PartyMenu = pcall(require, "src.ui.game3.party_menu")
          local okOam, Oam = pcall(require, "src.core.game3.oam")
          if okParty and PartyMenu and okOam and Oam
              and type(Oam.get) == "function"
              and type(PartyMenu._oam) == "table" then
            for _, slot in pairs(PartyMenu._oam) do
              local sprite = slot and slot.mon and Oam.get(slot.mon) or nil
              if sprite and sprite.inUse and not sprite.invisible then
                local meta = nativeImageMeta[sprite.image]
                if meta then
                  local cx = (tonumber(sprite.x) or 0) + (tonumber(sprite.x2) or 0)
                  local cy = (tonumber(sprite.y) or 0) + (tonumber(sprite.y2) or 0)
                  -- Preserve the already-approved FRLG visual inset.
                  cx = cx + (cx < 64 and 4 or 2)
                  if drawFinalIcon(meta, cx, cy, 0, 1, 1) then
                    drewPartyFromOam = true
                  end
                end
              end
            end
          end
        end

        if not drewPartyFromOam then
          for _, call in ipairs(calls) do
            local meta = call.meta
            if meta then
              local x, y, r, dsx, dsy, ox, oy = parseDraw(call.args)

              -- Generic non-party surfaces retain the confirmed v7 replay path.
              local px = (16 - ox) * dsx
              local py = (16 - oy) * dsy
              local cr, sr = math.cos(r), math.sin(r)
              local cx = x + px * cr - py * sr
              local cy = y + px * sr + py * cr

              drawFinalIcon(meta, cx, cy, r, dsx, dsy)
            end
          end
        end

        G.pop()
        bridge.replaying = false
      end)
    end

    Pokemon._kantoInMotionMenuIconsV3Installed = true
  end

  if mod.log and mod.log.info then
    mod.log:info("Pokemon menu icons v9 FRLG mobile Renderer-aligned HD path active for Gen %d (#001-386)", generation)
  end
  return true
end
