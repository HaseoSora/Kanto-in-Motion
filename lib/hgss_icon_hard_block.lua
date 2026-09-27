-- Kanto in Motion -> HGSS_SPRITES Pokemon icon ownership dispatcher.
--
-- HGSS loads after KIM (priority 150 vs 105) and replaces Gen 1/2 Party/PC
-- drawing methods with its own icon-grid implementation.  Capture KIM's
-- methods before HGSS loads, capture HGSS's methods after all mods load, then
-- dispatch live from the POKEMON ICONS option:
--
--   POKEMON ICONS ON  -> KIM/native methods + KIM icon provider
--   POKEMON ICONS OFF -> normal post-HGSS behavior
--
-- HGSS itself is never modified; overworld/player/trainer systems remain its
-- own regardless of this switch.
return function(mod, iconsEnabled)
  local M = {}
  local HGSS_ID = "HGSS_SPRITES"
  local generation = tonumber(mod.generation) or 1

  local function findMod(id)
    if not (mod and type(mod.find) == "function") then return nil end
    local ok, hit = pcall(mod.find, mod, id)
    if not ok or not hit then ok, hit = pcall(mod.find, id) end
    return ok and hit or nil
  end

  local function hgssPresent() return findMod(HGSS_ID) ~= nil end
  local function kimOwnsIcons()
    if not hgssPresent() then return false end
    if type(iconsEnabled) ~= "function" then return false end
    local ok, value = pcall(iconsEnabled)
    return ok and value == true
  end

  local targets = {}
  local function addTarget(moduleName, names)
    local ok, object = pcall(require, moduleName)
    if not ok or type(object) ~= "table" then return end
    local before = {}
    for _, name in ipairs(names) do
      if type(object[name]) == "function" then before[name] = object[name] end
    end
    if next(before) then
      targets[#targets + 1] = { object = object, before = before, names = names,
        moduleName = moduleName, after = {}, dispatchers = {} }
    end
  end

  if generation == 1 then
    addTarget("src.ui.PartyMenu", { "drawIcon", "draw", "gridNavigation" })
    addTarget("src.ui.ListMenu", { "new", "draw" })
  elseif generation == 2 then
    addTarget("src.ui.gen2.PartyMenu", { "drawIcon", "drawPanel", "update" })
    addTarget("src.ui.gen2.BoxMenu", { "drawPanel", "ensureVisible" })
  else
    return M
  end

  local installed = false
  local function install()
    if installed then return true end
    if not hgssPresent() then return false end
    for _, target in ipairs(targets) do
      local owner = target
      for name, before in pairs(owner.before) do
        local after = owner.object[name]
        if type(after) == "function" then
          owner.after[name] = after
          local methodName = name
          local pre = before
          owner.dispatchers[methodName] = function(...)
            if kimOwnsIcons() then return pre(...) end
            return owner.after[methodName](...)
          end
          owner.object[methodName] = owner.dispatchers[methodName]
        end
      end
    end
    installed = true
    mod._kantoInMotionHgssIconHardBlockInstalled = true
    return true
  end

  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function() pcall(install) end)
    mod.events:on("game.ready", function() if not installed then pcall(install) end end)
  end

  M.install = install
  M.active = kimOwnsIcons
  M.installed = function() return installed end
  return M
end
