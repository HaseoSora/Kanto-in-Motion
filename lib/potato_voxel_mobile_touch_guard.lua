-- Kanto in Motion - PotatoVoxel mobile TouchControls boundary guard.
--
-- Gen1Recomp draws TouchControls only after GameViewport.finish(). At that
-- point LOVE's graphics stack is expected to be depth zero. PotatoVoxel + KIM
-- can occasionally leave a staged push behind while KIM owns the HUD/UI; that
-- leaked state must not be repaired inside render.hud because the HUD/trainer/
-- Modern UI still need the live GameViewport canvas and transform there.
return function(mod, potatoKimHudActive)
  if not (mod and type(potatoKimHudActive) == "function") then return false end

  local system = love and love.system
  if not (system and type(system.getOS) == "function") then return false end
  local okOs, host = pcall(system.getOS)
  if not okOs or (host ~= "Android" and host ~= "iOS") then return false end

  local g = love and love.graphics
  if not (g and type(g.getStackDepth) == "function" and type(g.pop) == "function") then
    return false
  end

  local okTouch, TouchControls = pcall(require, "src.core.TouchControls")
  if not (okTouch and type(TouchControls) == "table"
      and type(TouchControls.draw) == "function") then
    return false
  end
  if TouchControls._kantoInMotionPotatoTouchGuardV83 then return true end

  local originalDraw = TouchControls.draw
  TouchControls._kantoInMotionPotatoTouchGuardV83 = originalDraw
  local warned = false

  local function active()
    local ok, value = pcall(potatoKimHudActive, nil)
    return ok and value == true
  end

  TouchControls.draw = function(self, ...)
    if active() then
      local repaired = 0
      for _ = 1, 128 do
        local okDepth, depth = pcall(g.getStackDepth)
        depth = okDepth and tonumber(depth) or nil
        if not depth or depth <= 0 then break end
        if not pcall(g.pop) then break end
        repaired = repaired + 1
      end
      if repaired > 0 and not warned and mod.log
          and type(mod.log.warn) == "function" then
        warned = true
        mod.log:warn(
          "mobile PotatoVoxel left %d graphics state(s) after GameViewport.finish; repaired before TouchControls",
          repaired)
      end
    end
    return originalDraw(self, ...)
  end

  return true
end
