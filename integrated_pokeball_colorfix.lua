-- Pokeball Colorfix
--
-- Makes the thrown Poke Ball render in its own colors. Two things are wrong
-- in the stock engine, and they have to be fixed together.
--
-- 1. The WIDE battle layout never colorizes the OAM animation layer at all.
--    BattleState:draw hands off to WideBattle.draw, whose drawAnimationLayer
--    calls battle:drawAnimLayer(FALSE) -- no color function, so
--    AnimPlayer:drawSprites skips the shade-remap shader and blits raw DMG
--    grays. The OG layout passes true on the same call. WideBattle.zones()
--    also returns colors = false over the whole surface, so nothing
--    downstream colors it either. That is why the ball is the ONE gray thing
--    in an otherwise colored wide battle.
--
-- 2. The ball has no palette of its own. BattleState:animSpriteColors resolves
--    every anim sprite against zoneColorsAt() -- the SGB zone palette under
--    that screen cell. Mid-arc the ball is over the enemy mon's zone, so it
--    wears the ENEMY SPECIES' colors. On hardware this never showed, because
--    the ball's OAM slot ($f0) maps to shades 0 and 3 -- the near-white and
--    near-black anchors -- so it read as a white ball with a black outline
--    whatever palette was underneath. Colorizing it without fixing this just
--    exposes the borrowed hue: the ball comes out the color of the Pokemon
--    you are throwing it at (blue at a Tentacool, and so on).
--
--    So the ball gets a FIXED palette here instead of a sampled one.
--
-- ------- why a two-tone ball is possible at all
--
-- The tile is 2bpp: color 0 transparent, plus colors 1/2/3. The shade maps
-- in BattleState tell you what each one is:
--
--     f0  = { 0, 3, 3 }   color 1 -> lightest, colors 2 and 3 -> darkest
--     f0x = { 3, 0, 3 }   color 1 -> darkest,  color 2 -> lightest
--
-- f0x is DoBallTossSpecialEffects' Master/Ultra flicker, which XORs rOBP0
-- with %00111100 -- "complementing colors 1 and 2". Color 2 flipping to the
-- LIGHT shade under f0x is the proof that color 2 is its own visible region
-- of the sprite, distinct from the color-3 outline. On the Game Boy that
-- region just renders dark, which is what gives the classic dark-topped
-- ball. It is the top half. So:
--
--     color 1 -> body      (white)
--     color 2 -> top half  (the ball's identity color)
--     color 3 -> outline and band (near-black)
--
-- Change BALLS below to taste -- values are plain 0-255 RGB.
--
-- ------- 3. the party ball rows (the "how many left" icons)
--
-- Those are a different mechanism again: BattleState:drawBallRow blits an
-- 8x8 quad out of assets/generated/battle/balls.png (4 tiles: healthy,
-- statused, fainted, empty slot) with a plain love.graphics.draw -- no
-- shader, and via a HARDCODED path rather than Assets.resolve. That last
-- detail matters: it means neither an assets_transforms recipe nor an
-- overrides/ folder can reach this image, because both are resolved through
-- Assets and this call bypasses it. So the row is recolored here instead.
--
-- The importer writes that PNG with decode2bpp(transparent = true), so its
-- pixels are exactly: GB shade 0 -> transparent, 1 -> 2/3 gray, 2 -> 1/3
-- gray, 3 -> black. Same three visible regions as the toss ball, so it gets
-- the same treatment: light -> white body, mid -> red top, black -> outline.
--
-- Per TILE, though, not per strip. The four tiles are SetupPokeballs' four
-- states (ball / status ball / fainted ball / empty), which is the whole
-- point of the row -- a healthy ball and a fainted one must not read alike.
-- Healthy keeps the red top, statused goes amber, fainted is desaturated,
-- and the empty socket is left exactly as the engine drew it.
--
-- WIDE LAYOUT ONLY, deliberately. In the OG layout drawHUDs renders onto
-- bgCanvas and the zone pass runs over it, and that shader keys off the RED
-- channel with the same 0.83/0.5/0.17 thresholds -- so a baked-in red
-- (r = 0.85) would read as "lightest" and come back out white. The OG layout
-- is left on vanilla behavior, where the zone pass colors the row as the
-- engine intends.

-- ------- 4. the Pokemon Center healing machine
--
-- A third mechanism. OverworldController's fxHeal() blits two 8x8 quads out
-- of Game.data.field.overworldFx.healMachine.path -- the monitor at y 0 and
-- the ball at y 8 -- with NO shader at all, so the raw DMG grays land on
-- screen. (The one time a shader IS bound is the jingle's blink beat, and
-- that explicitly sends PaletteFX.GRAYS, so even the flash is grayscale by
-- design.) The overworld's per-tile colorization never touches it either,
-- because the overlay draws after that pass.
--
-- fxHeal is a local inside a draw method, so it cannot be wrapped. The way
-- in is that it caches the image on the state and only loads it when
-- healMachineImg is nil -- so seeding that field with a recolored image
-- makes fxHeal use ours and never load the vanilla one. OverworldState:enter
-- is the seam: the module returns OverworldState, enter is an ordinary
-- method on it, and it runs on every map entry, so a seed that failed once
-- (data not ready yet) is simply retried on the next map.
--
-- Only the ball tile (y 8..15) is recolored; the monitor keeps its own art.
-- During the blink beat the balls still flash gray, since that shader runs
-- over whatever pixels it is given -- which reads as the machine flashing.

return function(mod)
  local BattleState = require("src.battle.BattleState")
  local AnimPlayer  = require("src.battle.AnimPlayer")

  -- body, top half, outline
  local BALLS = {
    POKE_BALL   = { { 248, 248, 248 }, { 216,  40,  40 }, { 24, 24, 24 } },
    GREAT_BALL  = { { 248, 248, 248 }, {  48,  96, 216 }, { 24, 24, 24 } },
    ULTRA_BALL  = { { 248, 248, 248 }, { 232, 184,  32 }, { 24, 24, 24 } },
    MASTER_BALL = { { 248, 248, 248 }, { 160,  80, 200 }, { 24, 24, 24 } },
    SAFARI_BALL = { { 248, 248, 248 }, {  64, 168,  80 }, { 24, 24, 24 } },
  }

  -- ------- part 1: let the wide layout colorize the anim layer
  --
  -- Guarded on colorMode(), the same test the OG layout uses to choose
  -- between the shader path and the flat fallback. That fallback also calls
  -- drawAnimLayer(false) and has no working shader, so forcing color
  -- unconditionally would break it.
  if not BattleState._ballColorFixOriginalDraw then
    BattleState._ballColorFixOriginalDraw = BattleState.drawAnimLayer
  end
  local originalDraw = BattleState._ballColorFixOriginalDraw

  function BattleState:drawAnimLayer(colorized)
    if not colorized and self.wideLayout and self:wideLayout()
       and self:colorMode() then
      colorized = true
    end
    return originalDraw(self, colorized)
  end

  -- ------- part 2a: know when a ball is on screen, and which one
  --
  -- ballChain queues TOSS -> POOF -> HIDEPIC -> SHAKE, and only the toss row
  -- carries the ball id (animNext("SHAKE_ANIM", true, shakes) passes none).
  -- So the id is remembered until the next toss rather than read per-anim,
  -- and the flag tracks the rows the ball is actually visible in. After a
  -- capture the chain ends and BattleState keeps drawing lockedBall with
  -- animPlaying false -- the flag is still set from SHAKE_ANIM, which is
  -- what keeps the resting ball colored through the caught text.
  local BALL_VISIBLE = {
    TOSS_ANIM = true, GREATTOSS_ANIM = true, ULTRATOSS_ANIM = true,
    SHAKE_ANIM = true,
  }

  if not AnimPlayer._ballColorFixOriginalStart then
    AnimPlayer._ballColorFixOriginalStart = AnimPlayer.start
  end
  local originalStart = AnimPlayer._ballColorFixOriginalStart

  function AnimPlayer:start(moveId, attackerIsPlayer, opts)
    if opts and opts.ball then self._bcfBall = opts.ball end
    self._bcfVisible = BALL_VISIBLE[moveId] or false
    return originalStart(self, moveId, attackerIsPlayer, opts)
  end

  -- ------- part 2b: hand the ball its own colors
  if not BattleState._ballColorFixOriginalColors then
    BattleState._ballColorFixOriginalColors = BattleState.animSpriteColors
  end
  local originalColors = BattleState._ballColorFixOriginalColors

  local function norm(c) return { c[1] / 255, c[2] / 255, c[3] / 255 } end

  function BattleState:animSpriteColors(s, px, py)
    local obp = s and s.obp
    local ap = self.animPlayer
    if not (ap and ap._bcfVisible and (obp == "f0" or obp == "f0x")) then
      -- every other sprite keeps the engine's zone-sampled colors
      return originalColors(self, s, px, py)
    end
    local pal = BALLS[ap._bcfBall or "POKE_BALL"] or BALLS.POKE_BALL
    local body, top, edge = pal[1], pal[2], pal[3]
    if obp == "f0x" then
      -- the hardware flicker complements colors 1 and 2; swapping keeps the
      -- Master/Ultra toss visibly strobing instead of going flat
      body, top = top, body
    end
    return { norm(body), norm(top), norm(edge) }
  end

  -- ------- part 3: the party ball rows
  --
  -- The four tiles are SetupPokeballs' states, and the row exists to READ as
  -- those states -- so each gets its own palette rather than one palette
  -- across the strip. Painting a fainted ball the same red as a healthy one
  -- would fight the only job the row has.
  --
  -- Slots are body / accent / outline, matching the toss ball. They map to
  -- the shade buckets the importer produced: 2/3 gray -> body, 1/3 gray ->
  -- accent, black -> outline. Bucket 1 is GB shade 0, already transparent.
  -- A nil entry leaves that tile exactly as the engine drew it.
  local ICONS = {
    [0] = { { 248, 248, 248 }, { 216,  40,  40 }, { 24, 24, 24 } }, -- healthy
    [1] = { { 248, 248, 248 }, { 232, 184,  32 }, { 24, 24, 24 } }, -- statused
    [2] = { { 152, 152, 152 }, {  92,  92,  92 }, { 24, 24, 24 } }, -- fainted
    [3] = nil,                                                      -- empty slot
  }

  -- ------- the VoxelMod battle-art fork's "ink flip"
  --
  -- absol89/DramaticShapeVoxelMod (the fork with 3D battles; confirmed
  -- against release 1.8.9) bakes the party HUD into an offscreen texture
  -- through this same drawHUDs -> drawBallRow chain, then runs a shader over
  -- the WHOLE bake that forces near-black pixels to white whenever the
  -- backdrop behind the panel reads dark -- so text stays legible over a
  -- cave floor or a night sky (lib/BattleHud.lua):
  --
  --   luma = dot(p.rgb, vec3(0.299, 0.587, 0.114))
  --   if (p.a > 0.0 && luma <= 0.35 * p.a) p.rgb = vec3(p.a)  -- -> white
  --
  -- The shader carves out one hardcoded exemption for the HP bar's fill
  -- cells. Nothing exempts the ball row -- it is not aware this mod exists.
  --
  -- ICONS' outline (24,24,24) has luma 0.094, nowhere near clear of 0.35: it
  -- gets flipped to white every time the backdrop is dark, which is what
  -- erases the ball's border. Healthy's red top (216,40,40) is luma 0.363 --
  -- 0.013 above the cutoff, a margin thin enough that any blending between
  -- the red and the (about to be white) outline pixel beside it, from
  -- whatever filtering the bake goes through, plausibly drags it under too.
  -- That reads as "the ball is grey and white."
  --
  -- ICONS_DRAMATIC gives every colour real headroom above 0.35 instead --
  -- outline lifted off near-black, healthy's red lightened toward coral --
  -- so nothing in the icon can be classified as ink, however dark the
  -- backdrop or however the bake gets filtered. Body colours (white,
  -- fainted-gray) were already luma 0.60+ and needed no change; statused's
  -- amber (0.710) likewise. Used only when self.dramaticShapeShot is set --
  -- see below.
  local ICONS_DRAMATIC = {
    [0] = { { 248, 248, 248 }, { 232,  92,  84 }, { 128, 128, 128 } }, -- healthy
    [1] = { { 248, 248, 248 }, { 232, 184,  32 }, { 128, 128, 128 } }, -- statused
    [2] = { { 152, 152, 152 }, { 135, 135, 135 }, { 128, 128, 128 } }, -- fainted
    [3] = nil,                                                         -- empty slot
  }

  local BALLS_PNG = "assets/generated/battle/balls.png"
  local icons          -- nil = not built, false = unavailable
  local iconsDramatic  -- same, for the ink-safe palette

  local function buildIcons(palette)
    local ok, data = pcall(love.image.newImageData, BALLS_PNG)
    if not ok or not data then return false end
    local w, h = data:getDimensions()
    local out = love.image.newImageData(w, h)
    out:paste(data, 0, 0, 0, 0, w, h)
    out:mapPixel(function(x, _, r, g, b, a)
      if a == 0 then return r, g, b, a end
      local pal = palette[math.floor(x / 8)]
      if not pal then return r, g, b, a end
      local c
      if r > 0.83 then c = nil
      elseif r > 0.5 then c = pal[1]
      elseif r > 0.17 then c = pal[2]
      else c = pal[3] end
      if not c then return r, g, b, a end
      return c[1] / 255, c[2] / 255, c[3] / 255, a
    end)
    local ok2, img = pcall(love.graphics.newImage, out)
    if not ok2 or not img then return false end
    local set = { img = img }
    for i = 0, 3 do
      set[i] = love.graphics.newQuad(i * 8, 0, 8, 8, img:getDimensions())
    end
    return set
  end

  if not BattleState._ballColorFixOriginalRow then
    BattleState._ballColorFixOriginalRow = BattleState.drawBallRow
  end
  local originalRow = BattleState._ballColorFixOriginalRow

  -- ------- why dramaticShapeShot is checked BEFORE wideLayout, not instead of
  --
  -- The 1.0.1 fix (an ink-safe palette gated the same way as the normal one,
  -- behind wideLayout()) did nothing: a diagnostic build confirmed the row
  -- was hitting the plain wideLayout()==false bailout, never reaching either
  -- palette at all.
  --
  -- The fork does not lie about that check -- it rewrites the truth. Its own
  -- source (lib/OverworldBattle.lua, OverworldBattle.forceOG):
  --
  --   if not opts or opts.battleLayout ~= "wide" then return false end
  --   opts.battleLayout = "og"
  --   if g.writeOptions then pcall(g.writeOptions, g) end
  --
  -- with the comment above it explaining why: "the OPTIONS menu takes the
  -- row off the list and pins the value while 3D-BTL is on ... a player is
  -- never offered a switch that gets reverted under them." So the moment
  -- 3D battle-art is turned on, battleLayout is permanently written to "og"
  -- on disk -- not a per-frame illusion, a real saved preference change --
  -- and wideLayout() answers false everywhere, forever, until 3D-BTL is
  -- turned back off.
  --
  -- That defeats the ORIGINAL reason this mod avoids OG at all: in real OG
  -- rendering, drawHUDs draws onto a canvas the zone-pass shader then
  -- remaps by red channel, and a baked-in red comes back white (see "Why
  -- the party rows are WIDE-layout only" in the README). But inside the
  -- fork's own HUD bake that shader never runs -- colorMode is forced false
  -- and nothing zone-passes the result -- so the danger the wideLayout
  -- gate exists to avoid simply is not present here. Checking
  -- dramaticShapeShot FIRST, and using it to color regardless of what
  -- battleLayout currently (truthfully, but irrelevantly) claims, is what
  -- fixes it: the wideLayout gate still protects real OG rendering below,
  -- for a battle that falls back to vanilla because no 3D arena was found
  -- for that map -- battleLayout stays "og" in that case too, and there the
  -- zone-pass danger is real again.
  function BattleState:drawBallRow(party, x, y, dx)
    -- Kanto in Motion captures the native HUD into a transparent scratch
    -- texture with colorMode forced OFF, then composites that HUD at final
    -- window resolution.  In that capture there is no later SGB zone pass,
    -- so falling through to the stock balls.png draw leaves the party row
    -- grayscale. Draw the true-color row directly while KIM owns that capture.
    --
    -- This is deliberately separate from Battle Art's dramaticShapeShot path:
    -- Battle Art keeps its ink-safe palette while 3D-BTL is active; KIM's 2D
    -- HUD uses the normal Pokeball Colorfix palette when 3D-BTL is disabled.
    if self._kantoInMotionHudCapture then
      if icons == nil then icons = buildIcons(ICONS) end
      if icons then
        local target = self._kantoInMotionPartyBallCanvas
        local g = love.graphics
        local previousCanvas = target and g.getCanvas and g.getCanvas() or nil
        if target then g.setCanvas(target) end
        for i = 1, 6 do
          local mon = party[i]
          local tile = not mon and 3 or mon.hp <= 0 and 2 or mon.status and 1 or 0
          g.draw(icons.img, icons[tile], x + (i - 1) * dx, y)
        end
        if target then
          if previousCanvas then g.setCanvas(previousCanvas) else g.setCanvas() end
        end
        return
      end
      return originalRow(self, party, x, y, dx)
    end

    if self.dramaticShapeShot then
      if iconsDramatic == nil then iconsDramatic = buildIcons(ICONS_DRAMATIC) end
      if iconsDramatic then
        for i = 1, 6 do
          local mon = party[i]
          local tile = not mon and 3 or mon.hp <= 0 and 2 or mon.status and 1 or 0
          love.graphics.draw(iconsDramatic.img, iconsDramatic[tile],
                             x + (i - 1) * dx, y)
        end
        return
      end
      return originalRow(self, party, x, y, dx)
    end
    if not (self.wideLayout and self:wideLayout()) then
      -- OG layout: defer past the zone pass rather than bail (see part 3b)
      if self:colorMode() then
        if icons == nil then icons = buildIcons(ICONS) end
        if icons then
          local pending = self._bcfPendingRows
          if not pending then pending = {}; self._bcfPendingRows = pending end
          pending[#pending + 1] = { party = party, x = x, y = y, dx = dx }
          return
        end
      end
      return originalRow(self, party, x, y, dx)
    end
    if icons == nil then icons = buildIcons(ICONS) end
    if not icons then return originalRow(self, party, x, y, dx) end
    -- the engine's own slot mapping: empty / fainted / statused / healthy
    for i = 1, 6 do
      local mon = party[i]
      local tile = not mon and 3 or mon.hp <= 0 and 2 or mon.status and 1 or 0
      love.graphics.draw(icons.img, icons[tile], x + (i - 1) * dx, y)
    end
  end

  -- ------- part 3b: the OG layout's party rows, drawn past the zone pass
  --
  -- In OG the row was green, not grey, and that was faithful: BATTLE_ZONES
  -- gives the whole HUD block -- name, level, HP bar AND the ball row -- one
  -- shared SGB zone, whose palette comes from sgbBattlePals()'s bar(), i.e.
  -- the HP BAR's palette (GREENBAR at full health). Real Super Game Boy
  -- Pokemon coloured that block exactly this way.
  --
  -- The mod used to just step aside for OG, because baking colour into the
  -- canvas is genuinely unsafe there: the zone shader keys off the RED
  -- channel, so a baked red comes back out white. Deferring sidesteps that
  -- entirely instead of fighting it. BattleState:draw's colorized path is:
  --
  --   setCanvas(bgCanvas); drawHUDs(); setCanvas(prev)
  --   drawZonePass(bgCanvas, sx, sy)   <- the greening happens here
  --   drawPicsLayer(...)               <- drawn after: keeps its own colours
  --   drawAnimLayer(true)              <- drawn after: keeps its own colours
  --
  -- so the engine already has a place where true colour survives, and the
  -- mon pics and the thrown ball both live there. The row is only green
  -- because it is baked in one step too early. So in OG the row is recorded
  -- rather than drawn (above), and replayed here immediately after the zone
  -- pass -- still before drawPicsLayer, so a pic that overlaps the row draws
  -- over it exactly as it did before.
  --
  -- The (sx, sy) shake offset is applied to match: the party rows are BG
  -- tiles, and drawZonePass blits the canvas at (sx, sy) when the window is
  -- shaking, so the row has to travel with it.
  --
  -- NOT tried: PaletteFX.markTrueColor(). It only appends to trueColorRects,
  -- which is consumed by Renderer's FRAME-level pass -- BattleState's own
  -- drawZonePass is a separate hardcoded BATTLE_ZONES loop that never
  -- consults it, so a mark would have been silently ignored here.
  --
  -- Deferring is gated on colorMode() because that is exactly the condition
  -- under which the zone pass runs: the flat fallback (no shader support)
  -- draws the HUD straight to the target and never calls drawZonePass, so a
  -- deferred row would have nothing to replay it and would simply vanish.
  -- There the mod still steps aside to vanilla.
  if not BattleState._ballColorFixOriginalZonePass then
    BattleState._ballColorFixOriginalZonePass = BattleState.drawZonePass
  end
  local originalZonePass = BattleState._ballColorFixOriginalZonePass

  function BattleState:drawZonePass(src, sx, sy)
    originalZonePass(self, src, sx, sy)
    local pending = self._bcfPendingRows
    if not (pending and pending[1]) then return end
    if icons then
      -- pcall: a throw inside a wrapped draw method is NOT fenced by the
      -- engine and would take the whole frame down
      local ok = pcall(function()
        love.graphics.setColor(1, 1, 1, 1)
        for _, row in ipairs(pending) do
          for i = 1, 6 do
            local mon = row.party[i]
            local tile = not mon and 3 or mon.hp <= 0 and 2
                         or mon.status and 1 or 0
            love.graphics.draw(icons.img, icons[tile],
                               row.x + (i - 1) * row.dx + (sx or 0),
                               row.y + (sy or 0))
          end
        end
      end)
      if not ok then love.graphics.setColor(1, 1, 1, 1) end
    end
    for i = #pending, 1, -1 do pending[i] = nil end
  end

  -- Cleared at the top of every HUD pass so a frame that records rows but
  -- never reaches the zone pass (a mod replacing BattleState:draw outright)
  -- drops them instead of accumulating them forever.
  if not BattleState._ballColorFixOriginalHUDs then
    BattleState._ballColorFixOriginalHUDs = BattleState.drawHUDs
  end
  local originalHUDs = BattleState._ballColorFixOriginalHUDs

  function BattleState:drawHUDs(slide)
    local pending = self._bcfPendingRows
    if pending then
      for i = #pending, 1, -1 do pending[i] = nil end
    end
    return originalHUDs(self, slide)
  end

  -- ------- part 4: the Pokemon Center healing machine
  --
  -- body / accent / outline again, so the machine's balls match the ones
  -- thrown in battle.
  local HEAL = { { 248, 248, 248 }, { 216, 40, 40 }, { 24, 24, 24 } }

  local function seedHealImage(state)
    if state.healMachineImg ~= nil then return end
    local Game = require("src.core.Game")
    local fx = Game and Game.data and Game.data.field
               and Game.data.field.overworldFx
    local def = fx and fx.healMachine
    if not (def and def.path) then return end
    local ok, data = pcall(love.image.newImageData, def.path)
    if not ok or not data then return end
    local w, h = data:getDimensions()
    local out = love.image.newImageData(w, h)
    out:paste(data, 0, 0, 0, 0, w, h)
    out:mapPixel(function(_, y, r, g, b, a)
      -- quad 1 (y 0..7) is the monitor; only the ball quad is recolored
      if a == 0 or y < 8 or y >= 16 then return r, g, b, a end
      local c
      if r > 0.83 then c = nil
      elseif r > 0.5 then c = HEAL[1]
      elseif r > 0.17 then c = HEAL[2]
      else c = HEAL[3] end
      if not c then return r, g, b, a end
      return c[1] / 255, c[2] / 255, c[3] / 255, a
    end)
    local ok2, img = pcall(love.graphics.newImage, out)
    if ok2 and img then state.healMachineImg = img end
  end

  local Overworld = require("src.world.OverworldController")

  if not Overworld._ballColorFixOriginalEnter then
    Overworld._ballColorFixOriginalEnter = Overworld.enter
  end
  local originalEnter = Overworld._ballColorFixOriginalEnter

  -- Seeded BEFORE the original runs so the return values pass through
  -- untouched; enter never writes healMachineImg itself, and a pcall keeps a
  -- failed seed from taking the map load down with it.
  function Overworld:enter(...)
    pcall(seedHealImage, self)
    return originalEnter(self, ...)
  end
end
