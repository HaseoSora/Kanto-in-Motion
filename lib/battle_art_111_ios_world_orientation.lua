-- Kanto in Motion -> Battle Art 1.11 iOS world-canvas orientation bridge.
--
-- Battle Art 1.11 already documents the affected LÖVE 12 Apple/Metal
-- Canvas-to-Canvas orientation behavior. Its Gen 1 path normally relies on
-- Renderer:endFrame to own the final correction, while Battle Art Gen 2's
-- newer WorldCanvasOrientation bridge pre-flips ONLY the finished world image
-- before UI composition.
--
-- KIM's mobile stage-only composition changes that final presentation boundary:
-- the Battle Art world can arrive upside-down while KIM's HUD, Modern lower UI,
-- and TouchControls remain correctly oriented. Mirror Battle Art Gen 2's proven
-- fix at the final Gen 1 worldOverride boundary, scoped strictly to:
--   * KIM battle system ON
--   * Battle Art stage active
--   * Battle Art's own Voxel3D.metalRenderer() detector true
--   * the current worldOverride being exactly Battle Art's live shot canvas
--
-- No Battle Art setting/file is modified. Android and desktop never enter this
-- path. UI/touch canvases are composed after the world and are not flipped.
return function(mod, battleSystemEnabled, battleArtCompat)
  if not (mod and type(battleSystemEnabled) == "function"
      and type(battleArtCompat) == "table"
      and type(battleArtCompat.isActive) == "function") then
    return false
  end

  local target, targetW, targetH = nil, 0, 0

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
    if not okO or type(OverworldBattle) ~= "table"
        or not okV or type(Voxel3D) ~= "table" then
      return nil
    end
    return OverworldBattle, Voxel3D
  end

  local function active()
    local okKim, kim = pcall(battleSystemEnabled)
    if not (okKim and kim == true) then return false end
    local okBa, ba = pcall(battleArtCompat.isActive, battleArtCompat)
    if not (okBa and ba == true) then return false end
    local _, Voxel3D = runtime()
    if not (Voxel3D and type(Voxel3D.metalRenderer) == "function") then
      return false
    end
    local okMetal, metal = pcall(Voxel3D.metalRenderer)
    return okMetal and metal == true
  end

  local function ensureTarget(w, h)
    if target and targetW == w and targetH == h then return target end
    local g = love and love.graphics
    if not (g and type(g.newCanvas) == "function") then return nil end
    local ok, made = pcall(g.newCanvas, w, h, { dpiscale = 1 })
    if not ok or not made then ok, made = pcall(g.newCanvas, w, h) end
    if not (ok and made) then return nil end
    if made.setFilter then pcall(made.setFilter, made, "nearest", "nearest") end
    if target and target.release then pcall(target.release, target) end
    target, targetW, targetH = made, w, h
    return target
  end

  -- This is the same world-only pre-flip Battle Art Gen 2 2.1.x uses on the
  -- affected Apple renderer: draw the finished world into another Canvas with
  -- a negative Y scale. KIM's final HUD/Modern UI/TouchControls are separate
  -- surfaces and therefore remain top-down.
  local function present(canvas)
    if not (canvas and type(canvas.getDimensions) == "function") then
      return canvas
    end
    local okSize, w, h = pcall(canvas.getDimensions, canvas)
    if not (okSize and tonumber(w) and tonumber(h) and w > 0 and h > 0) then
      return canvas
    end
    local out = ensureTarget(w, h)
    if not out or out == canvas then return canvas end

    local g = love and love.graphics
    if not g then return canvas end
    local baseDepth = type(mod._kantoInMotionGraphicsDepth) == "function"
      and mod._kantoInMotionGraphicsDepth() or nil
    local pushed = false
    if type(g.push) == "function" then
      pushed = pcall(g.push, "all")
      if not pushed then pushed = pcall(g.push) end
    end
    -- Never mutate the caller's Canvas/transform if LOVE cannot give this
    -- tiny compatibility copy its own balanced graphics-state scope.
    if not pushed then return canvas end

    local okDraw = pcall(function()
      g.setCanvas(out)
      if g.origin then g.origin() end
      if g.setShader then g.setShader() end
      if g.setScissor then g.setScissor() end
      if g.setDepthMode then g.setDepthMode() end
      if g.setStencilTest then g.setStencilTest() end
      if g.setColorMask then g.setColorMask(true, true, true, true) end
      if g.setBlendMode then g.setBlendMode("replace", "premultiplied") end
      if g.setColor then g.setColor(1, 1, 1, 1) end
      g.clear(0, 0, 0, 0)
      g.draw(canvas, 0, h, 0, 1, -1)
    end)

    if pushed and type(g.pop) == "function" then pcall(g.pop) end
    if baseDepth ~= nil and type(mod._kantoInMotionRestoreGraphicsDepth) == "function" then
      mod._kantoInMotionRestoreGraphicsDepth(baseDepth)
    end
    return okDraw and out or canvas
  end

  local function install()
    local OverworldBattle = runtime()
    if not OverworldBattle then return false end
    local okR, Renderer = pcall(require, "src.render.Renderer")
    if not okR or type(Renderer) ~= "table"
        or type(Renderer.endFrame) ~= "function" then
      return false
    end
    if Renderer._kantoInMotionBattleArtIosWorldOrientationV9 then return true end

    local inner = Renderer.endFrame
    Renderer._kantoInMotionBattleArtIosWorldOrientationV9 = inner
    function Renderer:endFrame(zones, worldZones)
      if active() then
        local okShot, shot = pcall(OverworldBattle.shot)
        local source = self.worldOverride
        if okShot and type(shot) == "table" and shot.canvas
            and source == shot.canvas then
          local corrected = present(source)
          if corrected and corrected ~= source then
            self.worldOverride = corrected
          end
        end
      end
      return inner(self, zones, worldZones)
    end
    return true
  end

  install()
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function() pcall(install) end)
  end

  local M = {}
  function M:isActive() return active() end
  function M:refresh() return install() end
  return M
end
