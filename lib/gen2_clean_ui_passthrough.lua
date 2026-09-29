-- Kanto in Motion v1.5.2 - Gen2 Clean UI presentation hard block
--
-- gen2_clean_ui owns a 90000-priority presentation runtime. KIM v1.5.2
-- vendors the exact Pokédex adapter/presenter it needs, so while KIM is active
-- the external Clean UI should not repaint the same Gen 2 source screens.
--
-- Registering a transparent API-v2 surface with native.policy="preserve"
-- makes Clean UI leave source rendering intact. KIM can then:
--   MODERN UI ON  -> hide source + draw KIM overlay
--   MODERN UI OFF -> leave source visible (true vanilla G/S/C)
return function(mod)
  if type(mod.find) ~= "function" then return false end

  local installed = false

  local function register()
    local okFind, handle = pcall(mod.find, "gen2_clean_ui")
    if not okFind or type(handle) ~= "table" then return false end
    local exports = handle.exports or {}
    local api = exports.modernUi or exports.gen2ModernUi
    if type(api) ~= "table" or type(api.registerAdapter) ~= "function" then
      return false
    end

    local spec = {
      owner = "animated_menu_pokemon",
      version = tostring(mod.version or "1.5.2"),
      contract = {
        apiVersion = 2,
        surfaces = {
          kim_gen2_native_passthrough = {
            -- Gen2 Clean UI is a Gen-2-only product. Capture ordinary source
            -- states but leave its own optional gallery/shell state alone.
            match = function(state)
              return type(state) == "table"
                and rawget(state, "cleanUiShell") == nil
            end,
            model = function()
              return { owner = "kanto_in_motion", passthrough = true }
            end,
            layout = {
              width = 1, height = 1,
              fit = "contain", scaleMode = "smooth-fit",
            },
            native = { policy = "preserve", scope = "uiCanvas" },
            render = function()
              -- Clean UI requires an explicit true from custom surfaces.
              -- The private canvas is cleared to transparent by its runtime.
              return true
            end,
            input = {
              pointer = function()
                -- Do not consume touch/mouse input; source/KIM owns it.
                return false
              end,
            },
          },
        },
      },
    }

    local ok, result = pcall(api.registerAdapter, spec)
    installed = ok and result ~= false
    if installed and mod.log and type(mod.log.info) == "function" then
      mod.log:info("Gen2 Clean UI presentation hard block installed; KIM owns Gen2 menu presentation")
    end
    return installed
  end

  register()

  -- Optional dependencies are not guaranteed to initialize before KIM.
  if not installed and mod.events and type(mod.events.on) == "function" then
    mod.events:on("mods.loaded", function()
      if not installed then register() end
    end, 200000)
  end

  return true
end
