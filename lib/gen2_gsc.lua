-- Kanto in Motion - Gold / Silver / Crystal bridge
--
-- Gen 2 keeps Gen1Recomp's native G/S/C battle logic, battle HUD, trainers,
-- command menus, move animations, Summary UI and Pokedex UI. KIM replaces
-- only the Pokemon picture draw on the LIVE screen instance.
--
-- IMPORTANT: do not require src.ui.gen2.* directly from a mod. Gen1Recomp's
-- Gen 2 compatibility layer intentionally routes mod-facing engine internals
-- through its public facade / live state stack. screen.pushed gives KIM the
-- actual screen object Gold/Silver/Crystal is about to draw.
--
-- Battle backgrounds intentionally remain native in this Gen 2 pass.
return function(mod)
  local LEGACY_DATA = "data/hd_pokemon_sprites.lua"
  local NATIONAL_DATA = "data/hd_pokemon_national.lua"

  local schema = {
    { key = "menuIcons", label = "POKEMON ICONS", type = "toggle", default = true,
      description = "Use Kanto in Motion HD-derived Pokemon icons in Gold/Silver/Crystal native icon slots. OFF restores the game or another icon mod's icons." },
    { key = "animate", label = "ANIMATION", type = "toggle", default = true,
      description = "Animate Kanto in Motion Pokemon in supported Gold/Silver/Crystal presentation." },
    { key = "battleSprites", label = "BATTLE SPRITES", type = "toggle", default = true,
      description = "Use Kanto in Motion HD animated Pokemon in Gold/Silver/Crystal battles while keeping the native Gen 2 battle system, HUD, trainers and move animations." },
    { key = "battleShadowQuality", label = "PKMN SHADOWS", type = "choice",
      default = "medium", choices = {
        { "OFF", "off" }, { "LOW", "low" }, { "MEDIUM", "medium" },
        { "HIGH", "high" }, { "ULTRA", "ultra" },
      }, description = "Ground-contact shadow quality for Kanto in Motion HD battle Pokemon." },
    { key = "battleShadowOpacity", label = "SHADOW OPACITY", type = "choice",
      default = "100", choices = {
        { "50%", "50" }, { "60%", "60" }, { "70%", "70" },
        { "80%", "80" }, { "90%", "90" }, { "100%", "100" },
        { "110%", "110" }, { "120%", "120" }, { "130%", "130" },
        { "140%", "140" }, { "150%", "150" },
      }, description = "Adjust Kanto in Motion battle shadow darkness. 100% matches the Gen 1 reference." },
    { key = "menuSprites", label = "SUMMARY SPRITES", type = "toggle", default = true,
      description = "Use Kanto in Motion HD animated Pokemon on the Gold/Silver/Crystal Pokemon Summary screen." },
    { key = "pokedexSprites", label = "POKEDEX SPRITES", type = "toggle", default = true,
      description = "Use Kanto in Motion HD animated Pokemon in the Gold/Silver/Crystal Pokedex while keeping the native Gen 2 Pokedex UI." },
  }
  mod._kantoInMotionOptionSchema = schema
  mod.options:define(schema)

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

  -- Re-index the original #001-151 metadata by National Dex and then extend
  -- it with the already-imported National Dex metadata. Gen 2 consumes only
  -- #001-251.
  local byDex = {}
  for _, row in pairs(loadTable(LEGACY_DATA, true)) do
    if type(row) == "table" and tonumber(row.dex) then
      byDex[tonumber(row.dex)] = row
    end
  end
  for dex, row in pairs(loadTable(NATIONAL_DATA, true)) do
    dex = tonumber(dex)
    if dex and dex >= 1 and dex <= 251 and type(row) == "table" then
      byDex[dex] = row
    end
  end

  local atlasCache = {}
  local sourceCache = {}
  local timingCache = setmetatable({}, { __mode = "k" })

  local function atlas(path)
    if atlasCache[path] == false then return nil end
    if atlasCache[path] then return atlasCache[path] end
    if not (mod.assets and type(mod.assets.image) == "function") then
      atlasCache[path] = false
      return nil
    end
    local ok, image = pcall(function() return mod.assets:image(path) end)
    if not ok or not image then
      atlasCache[path] = false
      return nil
    end
    if image.setFilter then pcall(image.setFilter, image, "linear", "linear") end
    atlasCache[path] = image
    return image
  end

  local function timing(rec)
    local hit = timingCache[rec]
    if hit then return hit end
    local count = math.max(1, math.floor(tonumber(rec.frames) or 1))
    local durations = type(rec.durations) == "table" and rec.durations or {}
    local cumulative, total = {}, 0
    for i = 1, count do
      total = total + math.max(1, tonumber(durations[i]) or 100)
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
    local key = table.concat({
      tostring(rec.image), tostring(width), tostring(height),
      tostring(columns), tostring(count)
    }, ":")
    local hit = sourceCache[key]
    if hit == false then return nil end
    if hit then return hit end

    local image = atlas(rec.image)
    if not image then
      sourceCache[key] = false
      return nil
    end

    local iw, ih = image:getDimensions()
    local expectedW = columns * width
    local expectedH = math.ceil(count / columns) * height
    if iw ~= expectedW or ih ~= expectedH then
      sourceCache[key] = false
      if mod.log and mod.log.warn then
        mod.log:warn(
          "GSC HD atlas mismatch for %s: got %dx%d expected %dx%d",
          tostring(rec.image), iw, ih, expectedW, expectedH
        )
      end
      return nil
    end

    hit = {
      image = image,
      width = width,
      height = height,
      columns = columns,
      count = count,
      iw = iw,
      ih = ih,
      quads = {},
    }
    sourceCache[key] = hit
    return hit
  end

  local function sourceQuad(source, frame)
    if not source then return nil end
    frame = math.max(1, math.min(
      source.count or 1,
      math.floor(tonumber(frame) or 1)
    ))
    local quad = source.quads[frame]
    if quad then return quad end

    local index = frame - 1
    local col = index % source.columns
    local row = math.floor(index / source.columns)
    quad = love.graphics.newQuad(
      col * source.width,
      row * source.height,
      source.width,
      source.height,
      source.iw,
      source.ih
    )
    source.quads[frame] = quad
    return quad
  end

  local function chooseVariant(variants, gender)
    if type(variants) ~= "table" then return nil end
    if gender == "female" and type(variants.female) == "table" then
      return variants.female
    end
    if gender == "male" and type(variants.male) == "table" then
      return variants.male
    end
    return type(variants.default) == "table" and variants.default
      or type(variants.male) == "table" and variants.male
      or type(variants.female) == "table" and variants.female
      or nil
  end

  local function recordFor(species, side, shiny, gender)
    species = tonumber(species)
    if not species or species < 1 or species > 251 then return nil end

    -- Gen 2 Unown owns 26 letter-specific pictures. The current KIM National
    -- Dex pack has one generic #201 atlas, so leave Unown native rather than
    -- replacing every letter with the same form.
    if species == 201 then return nil end

    local row = byDex[species]
    local sideData = type(row) == "table" and row[side] or nil
    local colorData = type(sideData) == "table"
      and sideData[shiny and "shiny" or "normal"] or nil
    local rec = chooseVariant(colorData, gender)
    if type(rec) ~= "table" or type(rec.image) ~= "string" then return nil end
    return rec
  end

  local function drawRecordInBox(rec, boxX, boxY, boxW, boxH, opts)
    if not rec then return false end
    local source = sourceFor(rec)
    if not source then return false end
    local quad = sourceQuad(source, frameFor(rec))
    if not quad then return false end

    opts = opts or {}
    local preferred = tonumber(rec.displayScale) or 1
    local scale = math.min(
      preferred,
      boxW / math.max(1, source.width),
      boxH / math.max(1, source.height)
    )

    if tonumber(opts.scaleMul) then scale = scale * opts.scaleMul end

    local drawW = source.width * scale
    local drawH = source.height * scale
    local px = boxX + (boxW - drawW) * 0.5
    local py
    if opts.centerY then
      py = boxY + (boxH - drawH) * 0.5
    else
      py = boxY + boxH - drawH
    end

    if tonumber(opts.offsetX) then px = px + opts.offsetX end
    if tonumber(opts.offsetY) then py = py + opts.offsetY end

    local G = love.graphics
    G.setColor(1, 1, 1, tonumber(opts.alpha) or 1)
    if source.image.setFilter then
      pcall(source.image.setFilter, source.image, "linear", "linear")
    end
    G.draw(source.image, quad, px, py, 0, scale, scale)
    if source.image.setFilter then
      pcall(source.image.setFilter, source.image, "nearest", "nearest")
    end
    G.setColor(1, 1, 1, 1)
    return true
  end

  -- -----------------------------------------------------------------------
  -- LIVE SCREEN PATCHING
  -- -----------------------------------------------------------------------

  local PIC_RESIZE_TILES = {
    [0] = 6, [1] = 4, [2] = 2,
    [3] = 7, [4] = 5, [5] = 3,
  }

  local function patchBattleScreen(state)
    if state._kantoInMotionGen2BattlePatched then return true end
    if type(state.drawPic) ~= "function"
        or type(state.activeMon) ~= "function"
        or type(state.animPicState) ~= "function"
        or type(state.drawScene) ~= "function" then
      return false
    end

    local nativeDrawPic = state.drawPic
    state._kantoInMotionGen2BattlePatched = nativeDrawPic

    state.drawPic = function(self, mon, back)
      if mod.options:get("battleSprites") == false or not mon then
        return nativeDrawPic(self, mon, back)
      end

      -- Trainer pictures stay entirely native.
      if back and self.showPlayerTrainer then
        return nativeDrawPic(self, mon, back)
      end
      if (not back) and self.showEnemyTrainer then
        return nativeDrawPic(self, mon, back)
      end

      local side = back and "player" or "enemy"

      if type(self.picBoxCleared) == "function" and self:picBoxCleared(side) then
        return
      end

      local anim = type(self.animPicState) == "function"
        and self:animPicState(side) or nil

      if type(self.isUnderground) == "function"
          and self:isUnderground(side, mon)
          and not (self.vanishAnim and self.vanishAnim == self.anim) then
        return
      end

      -- Substitute dolls retain native G/S/C presentation.
      local over = anim and anim.pic
      local substitute = over ~= nil
        and over == "substitute"
        or (over == nil and mon.volatile
          and (tonumber(mon.volatile.substitute) or 0) > 0)
      if substitute then
        return nativeDrawPic(self, mon, back)
      end

      local rec = recordFor(
        mon.species,
        back and "back" or "front",
        mon.shiny == true,
        mon.gender
      )
      if not rec then return nativeDrawPic(self, mon, back) end

      -- Gen 2 native battle boxes:
      -- enemy front = 7x7 at (12,0)
      -- player back = 6x6 at (2,6)
      local boxX = back and 16 or 96
      local boxY = back and 48 or 0
      local boxTiles = back and 6 or 7
      local box = boxTiles * 8

      local resizeTiles = anim and anim.size and PIC_RESIZE_TILES[anim.size]
      local scaleMul = resizeTiles and (resizeTiles / boxTiles) or 1

      local slide = (anim and not self.liftedPass)
        and (tonumber(anim.slide) or 0) or 0
      local sunk = type(self.faintSink) == "function"
        and (tonumber(self:faintSink(side)) or 0) or 0

      -- Lifted-row animations are split into two native passes. Until we add
      -- an HD band clip, use the native picture for that one special effect
      -- rather than drawing the complete KIM card twice.
      if anim and anim.lifted then
        return nativeDrawPic(self, mon, back)
      end

      return drawRecordInBox(rec, boxX, boxY, box, box, {
        centerY = false,
        scaleMul = scaleMul,
        offsetX = slide,
        offsetY = sunk,
      })
    end

    if mod.log and mod.log.info then
      mod.log:info("GSC HD battle screen bridge attached")
    end
    return true
  end

  local function patchSummaryScreen(state)
    if state._kantoInMotionGen2SummaryPatched then return true end
    if type(state.drawPic) ~= "function"
        or type(state.drawPicBlock) ~= "function"
        or type(state.picPath) ~= "function"
        or type(state.drawUpperHalf) ~= "function" then
      return false
    end

    local nativeDrawPic = state.drawPic
    state._kantoInMotionGen2SummaryPatched = nativeDrawPic

    state.drawPic = function(self)
      if mod.options:get("menuSprites") == false then
        return nativeDrawPic(self)
      end

      local mon = self.mon
      if not mon then return nativeDrawPic(self) end

      local rec = recordFor(mon.species, "front", mon.shiny == true, mon.gender)
      if not rec then return nativeDrawPic(self) end

      -- Let the native Summary code paint its exact 7x7 palette/background
      -- block, but temporarily replace only the Pokemon drawable with a
      -- transparent image and suppress Crystal's native front-animation sheet.
      -- Then paint KIM directly in the same live 160x144 transform.
      local blank
      if love and love.graphics and love.graphics.newCanvas then
        blank = self._kantoInMotionBlankPic
        if not blank then
          blank = love.graphics.newCanvas(1, 1)
          if blank.setFilter then blank:setFilter("nearest", "nearest") end
          self._kantoInMotionBlankPic = blank
        end
      end
      if not blank then return nativeDrawPic(self) end

      local oldPicFor = self.picFor
      local oldPicAnimFrame = self.picAnimFrame
      self.picFor = function() return blank, true end
      self.picAnimFrame = function() return nil end
      local ok, err = pcall(nativeDrawPic, self)
      self.picFor = oldPicFor
      self.picAnimFrame = oldPicAnimFrame
      if not ok then error(err, 0) end

      return drawRecordInBox(rec, 0, 0, 56, 56, { centerY = true })
    end

    if mod.log and mod.log.info then
      mod.log:info("GSC HD Summary screen bridge attached")
    end
    return true
  end

  local function patchPokedexScreen(state)
    if state._kantoInMotionGen2DexPatched then return true end
    if type(state.drawPic) ~= "function"
        or type(state.current) ~= "function"
        or type(state.drawFootprint) ~= "function"
        or type(state.drawEntry) ~= "function" then
      return false
    end

    local nativeDrawPic = state.drawPic
    state._kantoInMotionGen2DexPatched = nativeDrawPic

    state.drawPic = function(self, row, tx, ty, ownColors)
      if mod.options:get("pokedexSprites") == false
          or not (row and row.seen and tonumber(row.species)) then
        return nativeDrawPic(self, row, tx, ty, ownColors)
      end

      local rec = recordFor(tonumber(row.species), "front", false, nil)
      if not rec then return nativeDrawPic(self, row, tx, ty, ownColors) end

      local blank
      if love and love.graphics and love.graphics.newCanvas then
        blank = self._kantoInMotionBlankPic
        if not blank then
          blank = love.graphics.newCanvas(1, 1)
          if blank.setFilter then blank:setFilter("nearest", "nearest") end
          self._kantoInMotionBlankPic = blank
        end
      end
      if not blank then return nativeDrawPic(self, row, tx, ty, ownColors) end

      -- Let the native function paint its exact palette/background square and
      -- nothing else by temporarily supplying a transparent front picture.
      local oldPicFor = self.picFor
      self.picFor = function() return blank, true end
      local ok, err = pcall(nativeDrawPic, self, row, tx, ty, ownColors)
      self.picFor = oldPicFor
      if not ok then error(err, 0) end

      return drawRecordInBox(
        rec,
        (tonumber(tx) or 0) * 8,
        (tonumber(ty) or 0) * 8,
        56, 56,
        { centerY = true }
      )
    end

    if mod.log and mod.log.info then
      mod.log:info("GSC HD Pokedex screen bridge attached")
    end
    return true
  end

  local function patchScreen(state)
    if type(state) ~= "table" then return false end

    -- Order matters: BattleState, SummaryMenu and PokedexMenu all have
    -- drawPic-like methods, so use strong screen-specific signatures.
    if patchBattleScreen(state) then return true end
    if patchSummaryScreen(state) then return true end
    if patchPokedexScreen(state) then return true end
    return false
  end

  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("screen.pushed", function(payload)
      local state = type(payload) == "table" and payload.state or nil
      local ok, err = pcall(patchScreen, state)
      if not ok and mod.log and mod.log.error then
        mod.log:error("GSC HD live-screen patch failed: %s", tostring(err))
      end
    end)

    -- game.ready occurs before the boot cinema is pushed on Game2, but also
    -- covers hot-reload/test harnesses that already have a state present.
    mod.events:on("game.ready", function(payload)
      local game = type(payload) == "table" and payload.game or mod.game
      local stack = game and game.stack
      local state = stack and type(stack.top) == "function" and stack:top() or nil
      if state then pcall(patchScreen, state) end
    end)
  end

  mod.exports = mod.exports or {}
  mod.exports.gen2GscBridge = true
  mod.exports.gen2MaxNationalDex = 251
  mod.exports.gen2BridgeStrategy = "live-screen"
end
