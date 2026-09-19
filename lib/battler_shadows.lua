-- Kanto in Motion animated-battler ground shadows.
--
-- This first test implementation owns only KIM's direct 2D animated battler
-- presentation. The renderer passes the already-resolved species/frame scale
-- and ground anchor, so shadows automatically follow HD test sprites, player
-- size, HD arena placement, player-size changes, and send-out grow-in.
--
-- Quality is intentionally real workload scaling rather than a cosmetic label:
-- LOW draws 1 ellipse; MEDIUM 3; HIGH 6; ULTRA 10 feather layers.
-- v2 calibrates 100% opacity to the old v1 150% look and adds a small
-- species-footprint correction for Rattata.
return function(mod)
  local M = {}

  local PROFILES = {
    low    = { layers = 1,  opacity = 0.195, feather = 0.00, size = 0.92 },
    medium = { layers = 3,  opacity = 0.240, feather = 0.18, size = 0.96 },
    high   = { layers = 6,  opacity = 0.300, feather = 0.28, size = 1.00 },
    ultra  = { layers = 10, opacity = 0.360, feather = 0.38, size = 1.04 },
  }

  -- A few source animations have silhouettes whose visible body footprint is
  -- wider than the generic frame-derived contact shadow suggests. Keep these
  -- corrections data-driven so they can be tuned without disturbing the
  -- global shadow formula. Values scale both shadow radii.
  local SPECIES_SIZE = {
    RATTATA = 1.25,
  }

  local function quality()
    if not (mod and mod.options) then return "off" end
    local q = tostring(mod.options:get("battleShadowQuality") or "medium"):lower()
    if q == "off" then return "off" end
    if not PROFILES[q] then q = "medium" end
    return q
  end

  local function opacityMultiplier()
    if not (mod and mod.options) then return 1 end
    local value = tonumber(mod.options:get("battleShadowOpacity")) or 100
    return math.max(0.25, math.min(2.0, value / 100))
  end

  function M:enabled()
    return quality() ~= "off"
      and mod and mod.options and mod.options:get("battleSprites") ~= false
  end

  -- metrics is directSideMetrics() from main.lua. It publishes the exact final
  -- frame size/scale and ground shift used by the Pokemon draw itself.
  function M:drawDirect(metrics, side, transformAlpha)
    if not self:enabled() or type(metrics) ~= "table" then return false end
    local g = love and love.graphics
    if not (g and type(g.ellipse) == "function" and type(g.setColor) == "function") then
      return false
    end

    local q = quality()
    local profile = PROFILES[q]
    if not profile then return false end

    local scale = tonumber(metrics.scale) or 0
    local sw = math.abs((tonumber(metrics.w) or 0) * scale)
    local sh = math.abs((tonumber(metrics.h) or 0) * scale)
    if sw <= 0 or sh <= 0 then return false end

    -- Use both dimensions so wide wings/tails do not create gigantic shadows,
    -- while squat Pokemon still receive enough contact width to feel planted.
    local diameter = math.min(sw * 0.52, sh * 0.72)
    diameter = math.max(10, diameter) * (tonumber(profile.size) or 1)
    local species = tostring(metrics.species or ""):upper()
    diameter = diameter * (tonumber(SPECIES_SIZE[species]) or 1)
    local rx = diameter * 0.5
    local ry = math.max(2, rx * (side == "player" and 0.22 or 0.20))

    -- directSideMetrics ax/ay is the authored ground anchor. shinyGroundOffset
    -- shifts the actual feet, so apply the same shift to the shadow centre.
    local cx = tonumber(metrics.ax) or tonumber(metrics.centerX) or 0
    local cy = (tonumber(metrics.ay) or 0) + (tonumber(metrics.groundShift) or 0)
    -- Tuck the ellipse slightly behind the feet/body rather than centring it on
    -- the exact anchor line. This reads as contact shadow instead of a halo.
    cy = cy - ry * 0.18

    local externalAlpha = tonumber(transformAlpha) or 1
    externalAlpha = math.max(0, math.min(1, externalAlpha))
    local baseAlpha = (tonumber(profile.opacity) or 0.16)
      * opacityMultiplier() * externalAlpha
    baseAlpha = math.max(0, math.min(0.55, baseAlpha))
    if baseAlpha <= 0 then return false end

    local layers = math.max(1, math.floor(tonumber(profile.layers) or 1))
    local feather = math.max(0, tonumber(profile.feather) or 0)

    -- Paint broad/transparent first and dense/contact last. All layers overlap
    -- at the centre; per-layer alpha is normalized so higher quality becomes
    -- smoother rather than simply much darker.
    if layers == 1 then
      g.setColor(0, 0, 0, baseAlpha)
      g.ellipse("fill", cx, cy, rx, ry)
      return true
    end

    local perLayer = baseAlpha / layers
    for i = layers, 1, -1 do
      local t = (i - 1) / (layers - 1) -- 1 outer -> 0 inner
      local spread = 1 + feather * t
      local weight = 0.60 + 0.80 * (1 - t)
      g.setColor(0, 0, 0, math.min(0.30, perLayer * weight))
      g.ellipse("fill", cx, cy, rx * spread, ry * spread)
    end
    return true
  end

  return M
end
