-- Kanto in Motion - one-shot shiny send-out / encounter sparkle + audio.
--
-- The effect is side-aware. Enemy and player battlers each own their own
-- appearance latch and active animation, so a shiny opponent and a shiny
-- player Pokemon can both sparkle on the send-out where they become visible.
-- Keeping this outside main.lua also avoids pushing the main setup closure
-- over Lua's 200-local limit.
return function(mod, isBattleShiny, directStageGeometry, directSideMetrics)
  local M = {}

  local CFG = {
    image = "assets/effects/shiny_sparkle.png",
    sound = "assets/sfx/shiny.wav",
    frameWidth = 89,
    frameHeight = 75,
    columns = 6,
    frames = 35,
    -- shiny.wav: 33,880 PCM frames at 44,100 Hz = 0.768253968... sec.
    -- Every populated atlas frame gets an equal slice of that exact duration.
    audioDuration = 33880 / 44100,
  }
  CFG.frameDuration = CFG.audioDuration / CFG.frames

  local imageCache = nil
  local quadCache = nil
  local soundCache = nil

  local function now()
    if love and love.timer and type(love.timer.getTime) == "function" then
      local ok, value = pcall(love.timer.getTime)
      if ok and tonumber(value) then return tonumber(value) end
    end
    return os.clock()
  end

  local function imageAsset()
    if imageCache ~= nil then return imageCache or nil end
    if not (love and love.graphics and type(love.graphics.newImage) == "function") then
      imageCache = false
      return nil
    end
    local ok, image = pcall(love.graphics.newImage, mod.assets:path(CFG.image))
    if ok and image then
      if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
      imageCache = image
    else
      imageCache = false
      if mod.log and mod.log.warn then
        mod.log:warn("shiny encounter image unavailable: %s", tostring(CFG.image))
      end
    end
    return imageCache or nil
  end

  local function quads()
    if quadCache ~= nil then return quadCache or nil end
    local image = imageAsset()
    if not image then
      quadCache = false
      return nil
    end
    local iw, ih = image:getWidth(), image:getHeight()
    local out = {}
    for i = 0, CFG.frames - 1 do
      local x = (i % CFG.columns) * CFG.frameWidth
      local y = math.floor(i / CFG.columns) * CFG.frameHeight
      if x + CFG.frameWidth <= iw and y + CFG.frameHeight <= ih then
        out[#out + 1] = love.graphics.newQuad(
          x, y, CFG.frameWidth, CFG.frameHeight, iw, ih)
      end
    end
    quadCache = #out > 0 and out or false
    return quadCache or nil
  end

  local function playSound()
    if not (love and love.audio and type(love.audio.newSource) == "function") then return nil end
    if soundCache == nil then
      local ok, source = pcall(love.audio.newSource, mod.assets:path(CFG.sound), "static")
      soundCache = ok and source or false
      if not ok and mod.log and mod.log.warn then
        mod.log:warn("shiny encounter audio unavailable: %s", tostring(CFG.sound))
      end
    end
    local base = soundCache or nil
    if not base then return nil end
    local playable = base
    if type(base.clone) == "function" then
      local ok, cloned = pcall(base.clone, base)
      if ok and cloned then playable = cloned end
    end
    if playable.stop then pcall(playable.stop, playable) end
    if playable.setVolume then pcall(playable.setVolume, playable, 1) end
    if playable.setPitch then pcall(playable.setPitch, playable, 1) end
    if love.audio and type(love.audio.play) == "function" then
      pcall(love.audio.play, playable)
    elseif playable.play then
      pcall(playable.play, playable)
    end
    return playable
  end

  local function stateFor(battle)
    if type(battle) ~= "table" then return nil end
    local state = battle._kantoInMotionShinyEncounterState
    if type(state) ~= "table" then
      state = {
        enemy = { mon = nil, wasVisible = false, playedThisAppearance = false, fx = nil },
        player = { mon = nil, wasVisible = false, playedThisAppearance = false, fx = nil },
      }
      battle._kantoInMotionShinyEncounterState = state
    end
    return state
  end

  local function sideVisible(battle, side, battler)
    if not (battle and battler and battler.mon) then return false end
    if battler.fainted then return false end

    local fxHidden = false
    if type(battle.fxHidden) == "function" then
      local ok, hidden = pcall(battle.fxHidden, battle, battler)
      fxHidden = ok and hidden == true
    end
    if fxHidden then return false end

    if side == "enemy" then
      return not (battle.showEnemyTrainer or battle.enemyHidden or battle.enemySendingOut)
    end
    return not (battle.showPlayerBack or battle.safari or battle.demo or battle.sendingOut)
  end

  local function updateActive(slot)
    local fx = slot and slot.fx
    if type(fx) ~= "table" then return nil end
    local elapsed = math.max(0, now() - (tonumber(fx.startedAt) or 0))
    local frame = math.floor(elapsed / (tonumber(fx.frameDuration) or CFG.frameDuration))
    if frame >= (tonumber(fx.frames) or CFG.frames) then
      slot.fx = nil
      return nil
    end
    fx.frame = frame
    return fx
  end

  local function beginFx(slot)
    local image = imageAsset()
    local atlasQuads = quads()
    if not (image and atlasQuads and #atlasQuads > 0) then return nil end
    local fx = {
      image = image,
      quads = atlasQuads,
      startedAt = now(),
      frame = 0,
      frameDuration = CFG.frameDuration,
      frames = math.min(CFG.frames, #atlasQuads),
      frameWidth = CFG.frameWidth,
      frameHeight = CFG.frameHeight,
      sound = playSound(),
    }
    slot.fx = fx
    return fx
  end

  local function updateSide(battle, side)
    local state = stateFor(battle)
    local slot = state and state[side]
    if not slot then return nil end
    local battler = battle[side]
    local mon = battler and battler.mon or nil

    -- A different battler means a new appearance. This also lets a shiny
    -- switch-in sparkle even if the battle began with a non-shiny Pokemon.
    if mon ~= slot.mon then
      slot.mon = mon
      slot.wasVisible = false
      slot.playedThisAppearance = false
      slot.fx = nil
    end

    -- Re-arm only for a real trainer/send-out transition. Temporary battle
    -- effects (Dig/Fly/hide-pic, a failed catch breakout, etc.) can also make
    -- a battler invisible; those must NOT cause the shiny cue to replay.
    local sendOutTransition = side == "enemy"
      and (battle.showEnemyTrainer or battle.enemySendingOut)
      or (side == "player" and (battle.showPlayerBack or battle.sendingOut))
    if sendOutTransition then
      slot.wasVisible = false
      slot.playedThisAppearance = false
      slot.fx = nil
      return nil
    end

    local visible = sideVisible(battle, side, battler)
    if not visible then
      slot.wasVisible = false
      slot.fx = nil
      return nil
    end

    local fx = updateActive(slot)
    if not slot.wasVisible then
      slot.wasVisible = true
      if mon and not slot.playedThisAppearance
          and type(isBattleShiny) == "function" and isBattleShiny(mon) then
        slot.playedThisAppearance = true
        fx = beginFx(slot)
      end
    end
    return fx
  end

  local function drawSide(battle, side, fx, geo)
    if not fx then return false end
    local metrics = geo and directSideMetrics(battle, side, geo) or nil
    if not metrics then return false end
    local quad = fx.quads[(tonumber(fx.frame) or 0) + 1]
    if not quad then return false end

    local effectScale = math.max(1, (tonumber(geo.pixelScale) or 1) * 0.95)
    if geo.mobilePortrait then effectScale = effectScale * 0.85 end
    local drawX = math.floor((tonumber(metrics.centerX) or 0)
      - (tonumber(fx.frameWidth) or CFG.frameWidth) * effectScale * 0.5 + 0.5)
    local drawY = math.floor((tonumber(metrics.y) or 0)
      - (tonumber(fx.frameHeight) or CFG.frameHeight) * effectScale * 0.15 + 0.5)

    love.graphics.push("all")
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(fx.image, quad, drawX, drawY, 0, effectScale, effectScale)
    love.graphics.pop()
    return true
  end

  function M:draw(battle, game, vw, vh)
    if type(battle) ~= "table" then return false end
    if type(directStageGeometry) ~= "function" or type(directSideMetrics) ~= "function" then
      return false
    end

    -- Update both sides before drawing either one. Enemy and player intro
    -- timing is normally staggered, but if both become visible on the same
    -- frame they remain independent and each can play its own one-shot cue.
    local enemyFx = updateSide(battle, "enemy")
    local playerFx = updateSide(battle, "player")
    if not (enemyFx or playerFx) then return false end

    local geo = directStageGeometry(vw, vh, game, battle)
    if not geo then return false end
    local drew = false
    if enemyFx then drew = drawSide(battle, "enemy", enemyFx, geo) or drew end
    if playerFx then drew = drawSide(battle, "player", playerFx, geo) or drew end
    return drew
  end

  return M
end
