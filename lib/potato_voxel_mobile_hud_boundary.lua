-- Kanto in Motion - mobile PotatoVoxel render.hud balance guard.
--
-- Important: unlike Battle Art, PotatoVoxel's render.hud entry can still be
-- inside Gen1Recomp's active GameViewport graphics state.  Resetting that entry
-- state to depth zero breaks the trainer/source HUD/Modern UI composition.
--
-- Instead, leave the ENTRY state completely untouched, remember its exact LOVE
-- stack depth, run the normal KIM + Modern UI HUD chain, then remove only pushes
-- that were added and not removed DURING that HUD chain.  This keeps the real
-- viewport/canvas/transform intact while preventing one leaked push per frame
-- from accumulating until TouchControls:draw() hits LOVE's stack limit.
return function(mod, potatoKimHudActive)
  if not (mod and mod.hooks and type(mod.hooks.wrap) == "function"
      and type(potatoKimHudActive) == "function") then
    return false
  end

  local system = love and love.system
  if not (system and type(system.getOS) == "function") then return false end
  local okOs, host = pcall(system.getOS)
  if not okOs or (host ~= "Android" and host ~= "iOS") then return false end

  local g = love and love.graphics
  if not (g and type(g.getStackDepth) == "function"
      and type(g.pop) == "function") then
    if mod.log and type(mod.log.warn) == "function" then
      mod.log:warn("mobile PotatoVoxel HUD balance guard unavailable: LOVE getStackDepth missing")
    end
    return false
  end

  if mod._kantoInMotionPotatoMobileHudBoundaryInstalled then return true end
  mod._kantoInMotionPotatoMobileHudBoundaryInstalled = true

  local unpackFn = table.unpack or unpack
  local warned = false

  local function active()
    local ok, value = pcall(potatoKimHudActive, nil)
    return ok and value == true
  end

  mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
    if not active() then
      return nextFn(game, viewport)
    end

    -- Do NOT pop/reset/rebind anything here.  This is the state Gen1Recomp and
    -- Potato handed to render.hud and the downstream KIM/Modern presenters need
    -- that exact canvas/transform to place the trainer, HP bands and lower UI.
    local okDepth, baseDepth = pcall(g.getStackDepth)
    baseDepth = okDepth and tonumber(baseDepth) or nil

    local result = { pcall(nextFn, game, viewport) }

    -- Remove only states leaked by this render.hud pass. Never pop below the
    -- entry depth: doing so destroys GameViewport ownership and was the cause
    -- of the broken v81 mobile composition.
    local repaired = 0
    if baseDepth ~= nil then
      for _ = 1, 128 do
        local okNow, depth = pcall(g.getStackDepth)
        depth = okNow and tonumber(depth) or nil
        if not depth or depth <= baseDepth then break end
        if not pcall(g.pop) then break end
        repaired = repaired + 1
      end
    end

    if repaired > 0 and not warned and mod.log
        and type(mod.log.warn) == "function" then
      warned = true
      mod.log:warn(
        "mobile PotatoVoxel render.hud leaked %d graphics state(s); balanced before TouchControls",
        repaired)
    end

    local ok = table.remove(result, 1)
    if not ok then error(result[1], 0) end
    return unpackFn(result)
  end, 110000)

  return true
end
