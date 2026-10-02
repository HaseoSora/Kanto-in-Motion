-- Kanto in Motion -> Battle Art 1.11 iOS world-canvas orientation bridge.
--
-- Battle Art 1.11 documents a LÖVE 12 Apple/Metal Canvas-to-Canvas orientation
-- issue. KIM's mobile stage-only presentation leaves Battle Art's finished 3D
-- world on the engine worldOverride while KIM/Modern UI draw afterward.
--
-- v1 used an endFrame wrapper and also depended on KIM's Battle Art sprite
-- compatibility reporting active. That was too narrow: Battle Art can own a
-- live 3D stage even when KIM's battle-sprite provider is not the active part
-- of the stack, and endFrame can be wrapped again by other presentation code.
-- On affected iPhones that meant the correction simply never ran.
--
-- This bridge now mirrors Battle Art Gen2 2.1.x at the actual handoff seam:
-- intercept Renderer:setWorldOverride while Battle Art has a live shot, copy
-- ONLY that finished world canvas through Battle Art's own PixelCanvas helper
-- with a vertical pre-flip, then hand the corrected canvas to the engine.
-- HUDs, Modern UI and TouchControls are composed later and remain upright.
return function(mod, battleSystemEnabled, _battleArtCompat)
  if not (mod and type(battleSystemEnabled) == "function") then return false end

  local target, targetW, targetH = nil, 0, 0
  local lastSource, lastTarget = nil, nil
  local logged = false

  local function runtime()
    if type(mod.find) ~= "function" then return nil end
    local ok, handle = pcall(mod.find, mod, "BATTLE_ART_VOXEL_FORK")
    if not ok or not handle then
      ok, handle = pcall(mod.find, "BATTLE_ART_VOXEL_FORK")
    end
    local exports = ok and handle and handle.exports or nil
    local lib = type(exports) == "table" and exports.lib or nil
    if not (type(lib) == "table" and type(lib.require) == "function") then
      return nil
    end
    local okO, OverworldBattle = pcall(lib.require, "OverworldBattle")
    local okV, Voxel3D = pcall(lib.require, "Voxel3D")
    local okP, PixelCanvas = pcall(lib.require, "PixelCanvas")
    if not okO or type(OverworldBattle) ~= "table"
        or not okV or type(Voxel3D) ~= "table"
        or not okP or type(PixelCanvas) ~= "table" then
      return nil
    end
    return OverworldBattle, Voxel3D, PixelCanvas
  end

  local function love12Plus()
    if not (love and type(love.getVersion) == "function") then return false end
    local ok, major = pcall(love.getVersion)
    return ok and type(major) == "number" and major >= 12
  end

  local function affectedApple(Voxel3D)
    if not love12Plus() then return false end
    if Voxel3D and type(Voxel3D.metalRenderer) == "function" then
      local ok, value = pcall(Voxel3D.metalRenderer)
      if ok and value == true then return true end
    end
    -- Fallback for an iOS port whose renderer string differs from the one
    -- Battle Art's detector knows about. This branch is still LÖVE 12+ only.
    local system = love and love.system
    if system and type(system.getOS) == "function" then
      local ok, host = pcall(system.getOS)
      if ok and host == "iOS" then return true end
    end
    return false
  end

  local function liveShot()
    local okKim, kim = pcall(battleSystemEnabled)
    if not (okKim and kim == true) then return nil end
    local OverworldBattle, Voxel3D, PixelCanvas = runtime()
    if not (OverworldBattle and affectedApple(Voxel3D)) then return nil end
    if type(OverworldBattle.shot) ~= "function" then return nil end
    local okShot, shot = pcall(OverworldBattle.shot)
    if not (okShot and type(shot) == "table" and shot.canvas) then return nil end
    return shot, PixelCanvas
  end

  local function ensureTarget(PixelCanvas, w, h)
    if target and targetW == w and targetH == h then return target end
    if not (PixelCanvas and type(PixelCanvas.new) == "function") then return nil end
    local ok, made = PixelCanvas.new(w, h)
    if not (ok and made) then return nil end
    if made.setFilter then pcall(made.setFilter, made, "nearest", "nearest") end
    if target and target.release then pcall(target.release, target) end
    target, targetW, targetH = made, w, h
    lastSource, lastTarget = nil, nil
    return target
  end

  -- Exact world-only pre-flip used by Battle Art Gen2's
  -- WorldCanvasOrientation.present(). Keep this deliberately simple: restore
  -- only the state that routine restores and do not wrap the whole operation
  -- in graphics.push("all"), so iOS sees the same Canvas path Battle Art has
  -- already validated for its Gen2 renderer.
  local function present(canvas, PixelCanvas)
    if not (canvas and type(canvas.getDimensions) == "function") then
      return canvas
    end
    if canvas == lastTarget then return canvas end
    if canvas == lastSource and lastTarget then return lastTarget end

    local okSize, w, h = pcall(canvas.getDimensions, canvas)
    if not (okSize and tonumber(w) and tonumber(h) and w > 0 and h > 0) then
      return canvas
    end
    local out = ensureTarget(PixelCanvas, w, h)
    if not out or out == canvas then return canvas end

    local g = love and love.graphics
    if not g then return canvas end
    local prevCanvas = g.getCanvas and g.getCanvas() or nil
    local prevBlend, prevAlpha = "alpha", "alphamultiply"
    if g.getBlendMode then
      local okBlend, a, b = pcall(g.getBlendMode)
      if okBlend then prevBlend, prevAlpha = a or prevBlend, b or prevAlpha end
    end

    local drew = pcall(function()
      g.setCanvas(out)
      if g.setShader then g.setShader() end
      g.setBlendMode("replace", "premultiplied")
      g.setColor(1, 1, 1, 1)
      g.clear(0, 0, 0, 0)
      g.draw(canvas, 0, h, 0, 1, -1)
    end)

    if prevCanvas then g.setCanvas(prevCanvas) else g.setCanvas() end
    if g.setShader then g.setShader() end
    if g.setBlendMode then pcall(g.setBlendMode, prevBlend, prevAlpha) end
    if g.setColor then g.setColor(1, 1, 1, 1) end

    if drew then
      lastSource, lastTarget = canvas, out
      if not logged and mod.log and type(mod.log.info) == "function" then
        logged = true
        mod.log:info("Battle Art iOS world orientation corrected at worldOverride handoff")
      end
      return out
    end
    return canvas
  end

  local function install()
    local okR, Renderer = pcall(require, "src.render.Renderer")
    if not okR or type(Renderer) ~= "table"
        or type(Renderer.setWorldOverride) ~= "function" then
      return false
    end
    if Renderer._kantoInMotionBattleArtIosWorldOrientationV10 then return true end

    local inner = Renderer.setWorldOverride
    Renderer._kantoInMotionBattleArtIosWorldOrientationV10 = inner
    function Renderer:setWorldOverride(canvas)
      local shot, PixelCanvas = liveShot()
      if shot and PixelCanvas and canvas then
        -- When Battle Art has a live native shot it owns the battle world
        -- override. Prefer the exact identity match, but do not depend on it:
        -- presentation wrappers are allowed to hand an equivalent Canvas down
        -- the chain. Stadium-hosted battles make OverworldBattle.shot() nil,
        -- so this cannot catch an unrelated provider's world image.
        if canvas == shot.canvas or type(canvas.getDimensions) == "function" then
          canvas = present(canvas, PixelCanvas)
        end
      end
      return inner(self, canvas)
    end
    return true
  end

  install()
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function() pcall(install) end)
    mod.events:on("battle.started", function() pcall(install) end)
  end

  local M = {}
  function M:isActive()
    local shot = liveShot()
    return shot ~= nil
  end
  function M:refresh() return install() end
  return M
end
