-- Kanto in Motion - desktop Battle Art HUD geometry/opacity bridge.
--
-- Android/iOS already use KIM's stage-only HUD renderer. Windows desktop keeps
-- Battle Art's native snapped HUD, so KIM's HUD SIZE / HUD OPACITY settings
-- need to be applied at Battle Art's own public runtime seams instead of
-- drawing a second HUD on top of the voxel scene.
return function(mod, battleSystemEnabled, battleArt3DEnabled, isMobileHost)
  if type(isMobileHost) == "function" and isMobileHost() then return false end
  if not (love and love.graphics and mod) then return false end

  local function kimOwns3D()
    if type(battleSystemEnabled) == "function" then
      local ok, value = pcall(battleSystemEnabled)
      if not ok or value ~= true then return false end
    end
    if type(battleArt3DEnabled) == "function" then
      local ok, value = pcall(battleArt3DEnabled)
      if not ok or value ~= true then return false end
    end
    return true
  end

  local handle = nil
  if type(mod.find) == "function" then
    local ok, hit = pcall(mod.find, mod, "BATTLE_ART_VOXEL_FORK")
    if not ok or not hit then ok, hit = pcall(mod.find, "BATTLE_ART_VOXEL_FORK") end
    if ok then handle = hit end
  end
  local exports = handle and type(handle.exports) == "table" and handle.exports or nil
  local lib = exports and exports.lib or nil
  if not (type(lib) == "table" and type(lib.require) == "function") then return false end

  local okStage, OverworldBattle = pcall(lib.require, "OverworldBattle")
  if not okStage or type(OverworldBattle) ~= "table"
      or type(OverworldBattle.snapRects) ~= "function" then
    return false
  end

  -- One installation only. The marker stores Battle Art's untouched function
  -- so other KIM compatibility code can tell that snapRects already includes
  -- KIM's fine HUD-size factor and must not multiply it a second time.
  if not OverworldBattle._kantoInMotionHudGeometryBridge then
    local originalSnapRects = OverworldBattle.snapRects
    OverworldBattle._kantoInMotionHudGeometryBridge = originalSnapRects

    OverworldBattle.snapRects = function(shot)
      if not kimOwns3D() or type(shot) ~= "table" then
        return originalSnapRects(shot)
      end

      local s = tonumber(shot.scale)
      local pw = tonumber(shot.pw)
      local ly = tonumber(shot.ly)
      local rectDef = OverworldBattle.HUD_RECT
      local bandDef = OverworldBattle.HUD_BAND
      local e = type(rectDef) == "table" and rectDef.enemy or nil
      local p = type(rectDef) == "table" and rectDef.player or nil
      local playerBand = type(bandDef) == "table" and bandDef.player or nil
      if not (s and s > 0 and pw and ly and type(e) == "table"
          and type(p) == "table" and type(playerBand) == "table") then
        return originalSnapRects(shot)
      end

      local okMode, mode = pcall(function() return mod.options:get("battleHudScale") end)
      mode = okMode and mode or "og"
      local baseHs = mode == "scaled" and math.max(1, s - 1) or s

      local okSize, size = pcall(function() return mod.options:get("battleHudSize") end)
      local factor = okSize and (tonumber(size) or 100) / 100 or 1
      factor = math.max(0.60, math.min(1.00, factor))
      local hs = baseHs * factor

      -- Rebuild Battle Art's own snap geometry with the KIM-selected scale.
      -- Enemy remains left-anchored and player remains right-anchored. Player
      -- Y uses Battle Art's native 48-row band rule so EXP overlays can share
      -- the exact same +41 HUD-pixel row at every size.
      local ex = (2 - e[1]) * hs
      local px = pw - (p[1] + p[3]) * hs
      local rects = {
        enemy = { ex + e[1] * hs, ly + e[2] * s, e[3] * hs, e[4] * hs },
        player = { px + p[1] * hs, ly + p[2] * s,
                   p[3] * hs, p[4] * hs },
      }
      local placement = {
        enemy = { x = ex, y = ly, scale = hs },
        player = {
          x = px,
          y = ly + p[2] * s - (p[2] - playerBand[2]) * hs,
          scale = hs,
        },
      }
      return rects, placement
    end
  end

  -- Battle Art bakes the native HUD into a 160x144 texture before snapping it
  -- to the world canvas. Fade that texture, rather than the whole scene, so
  -- HUD OPACITY affects HP/status text, bars and party-ball pixels without
  -- dimming the voxel arena or the Modern UI lower panel.
  if type(OverworldBattle.hudTexture) == "function"
      and not OverworldBattle._kantoInMotionHudOpacityBridge then
    local originalHudTexture = OverworldBattle.hudTexture
    OverworldBattle._kantoInMotionHudOpacityBridge = originalHudTexture
    local faded = nil

    OverworldBattle.hudTexture = function(...)
      local layer = originalHudTexture(...)
      if not layer or not kimOwns3D() then return layer end

      local okOpacity, opacity = pcall(function()
        return mod.options:get("battleHudOpacity")
      end)
      local alpha = okOpacity and (tonumber(opacity) or 100) / 100 or 1
      alpha = math.max(0.25, math.min(1.00, alpha))
      if alpha >= 0.999 then return layer end

      local g = love.graphics
      if type(g.newCanvas) ~= "function" or type(g.draw) ~= "function"
          or type(layer.getDimensions) ~= "function" then
        return layer
      end
      local okDim, w, h = pcall(layer.getDimensions, layer)
      if not okDim or not (tonumber(w) and tonumber(h) and w > 0 and h > 0) then
        return layer
      end
      if not faded or faded:getWidth() ~= w or faded:getHeight() ~= h then
        local okCanvas, canvas = pcall(g.newCanvas, w, h)
        if not okCanvas or not canvas then return layer end
        faded = canvas
        if type(faded.setFilter) == "function" then
          pcall(faded.setFilter, faded, "nearest", "nearest")
        end
      end

      local pushed = false
      if type(g.push) == "function" and type(g.pop) == "function" then
        pushed = pcall(g.push, "all") == true
      end
      local okDraw = pcall(function()
        g.setCanvas(faded)
        if type(g.origin) == "function" then g.origin() end
        if type(g.clear) == "function" then g.clear(0, 0, 0, 0) end
        if type(g.setShader) == "function" then g.setShader() end
        if type(g.setScissor) == "function" then g.setScissor() end
        if type(g.setBlendMode) == "function" then g.setBlendMode("alpha") end
        g.setColor(1, 1, 1, alpha)
        g.draw(layer, 0, 0)
      end)
      if pushed then pcall(g.pop) end
      if not okDraw then return layer end
      return faded
    end
  end

  return true
end
