return function(ctx)
  local Data = ctx.load("adapters.data")
  local Adapter = ctx.load("adapters.pokedex")
  local Presenter = {}

  local function canonical(model)
    model.schema = "clean_ui.v3.presentation.v1"
    model.apiVersion = 3
    return model
  end

  local function row(source, right, label)
    return {
      id = source.id,
      sourceIndex = source.sourceIndex,
      label = label or source.label,
      right = right or source.right or source.value,
      disabled = source.disabled == true,
    }
  end

  local function sprite(art)
    if type(art) ~= "table" or type(art.sprite) ~= "string"
        or art.sprite == "" then return nil end
    local descriptor = { path = art.sprite, zoom = 1.5 }
    if type(art.palette) == "table" then
      descriptor.palette = Data.copy(art.palette)
    end
    return descriptor
  end

  local function richDetails(art, fields, title, typeBadges)
    return {
      title=title,
      sprite=sprite(art),
      fields=fields or {},
      typeBadges=typeBadges and Data.copy(typeBadges) or nil,
      -- The shared menu renderer already provides the stable right-hand
      -- preview rail. This marker documents that the rail is the Pokédex
      -- preview composition, rather than a generic key/value inspector.
      preview=true,
    }
  end

  local function dexNumber(value)
    value = tonumber(value) or 0
    return value > 0 and ("No.%03d"):format(value) or "No.---"
  end

  local function status(current)
    if current.caught then return "OWNED" end
    if current.seen then return "SEEN" end
    return "UNSEEN"
  end

  local function displayHeight(value)
    value = tonumber(value)
    if not value then return "?" end
    return ("%d'00\""):format(math.floor(value / 100))
  end

  local function displayWeight(value)
    value = tonumber(value)
    if not value then return "?" end
    return ("%.1f lbs."):format(value / 10)
  end

  local function wrapLines(lines, width)
    local output = {}
    for _, source in ipairs(lines or {}) do
      local text = tostring(source or "")
      while #text > width do
        local split = width
        for index = width, 1, -1 do
          if text:sub(index, index) == " " then
            split = index - 1
            break
          end
        end
        output[#output + 1] = text:sub(1, split)
        text = text:sub(split + 2)
      end
      output[#output + 1] = text
    end
    return output
  end

  local function entryDocument(current, selectedAction)
    local art = sprite(current.art)
    local activeTab = ({ [1] = 1, [2] = 2, [3] = 5, [4] = 6 })
      [selectedAction]
    local entryText = table.concat(current.pageLines or {}, " ")
    entryText = entryText:gsub("(%a)%- (%a)", "%1%2")
    local entryLines = { entryText }
    local identity = {}
    local kind = tostring(current.kind or "UNKNOWN")
    if not kind:match("POKÉMON$") then
      kind = kind .. " POKÉMON"
    end
    if art then
      identity[#identity + 1] = {
        type = "image", asset = art.path, id = "species-art",
      }
    end
    return {
      contentLayout = "grid",
      gridColumns = 2,
      gridRows = 2,
      header = {
        right = {
          type = "tabs",
          values = { "INFO", "AREA", "EVO", "MOVES", "CRY", "PRINT" },
          active = activeTab,
        },
      },
      regions = {
        {
          id = "identity", role = "content",
          gridRow = 1, gridColumn = 1, preferredWidth = 280,
          preferredHeight = 280,
          components = identity,
        },
        {
          id = "summary", role = "content",
          gridRow = 1, gridColumn = 2, preferredHeight = 240,
          transparent = true,
          components = {
            { type = "heading", text = current.name or "ENTRY" },
            { type = "label", text = kind },
            { type = "heading", text = dexNumber(current.dex) },
            { type = "badges", values = Data.copy(current.types or {}) },
            {
              type = "metadata",
              columns = 1,
              leaders = true,
              items = {
                { label = "HEIGHT",
                  value = current.caught and displayHeight(current.height) or "?" },
                { label = "WEIGHT",
                  value = current.caught and displayWeight(current.weight) or "?" },
                { label = "STATUS", value = status(current), tone = "accent" },
              },
            },
          },
        },
        {
          id = "entry", role = "content", frame = true,
          gridRow = 2, gridColumn = 1, gridColumnSpan = 2,
          components = {
            { type = "heading", text = "POKÉDEX ENTRY" },
            { type = "text", lines = entryLines, style = "body",
              wrap = true, truncate = false, marginLeft = 16,
              marginRight = 16 },
          },
        },
      },
      controls = "LEFT/RIGHT PAGE   A SELECT   B BACK",
      focus = {
        initial = tostring(selectedAction or 1),
        order = { "identity", "summary", "entry" },
      },
    }
  end

  local function listPresentation(model)
    local rows = {}
    for index, source in ipairs(model.rows or {}) do
      local number = source.dex and source.dex > 0
        and ("%03d"):format(source.dex) or "---"
      local marker = source.caught and "OWNED"
        or source.seen and "SEEN" or "UNSEEN"
      local name = tostring(source.label or "-----")
      local label = number .. "   " .. name
      rows[index] = row(source, marker, label)
    end
    local current = model.current or {}
    local listItems = {}
    for index, item in ipairs(rows) do
      listItems[index] = {
        label = item.label,
        value = item.right ~= "" and (string.rep(". ", 7) .. " "
          .. item.right)
          or item.right,
        selected = index == model.navigation.selectedIndex,
      }
    end
    local previewComponents = {}
    local currentArt = sprite(current.art)
    if currentArt then
      previewComponents[#previewComponents + 1] = {
        type = "image", asset = currentArt.path,
      }
    end
    previewComponents[#previewComponents + 1] = {
      type = "heading", text = current.name or "-----",
      align = "center",
    }
    previewComponents[#previewComponents + 1] = {
      type = "label", text = dexNumber(current.dex), align = "center",
    }
    previewComponents[#previewComponents + 1] = {
      type = "badges", values = Data.copy(current.types or {}),
      align = "center",
    }
    previewComponents[#previewComponents + 1] = {
      type = "label", text = status(current), align = "center",
    }
    return {
      rows = rows,
      selected = model.navigation.selectedIndex,
      scroll = model.navigation.scroll,
      details = richDetails(current.art, {
        { label = "NUMBER", value = dexNumber(current.dex) },
        { label = "STATUS", value = status(current), style = "accent" },
      }, current.name or "-----", current.types),
      description = ("SEEN %d  OWNED %d   A DATA   A OPTIONS   B BACK")
        :format(model.totals.seen or 0, model.totals.caught or 0),
      art = Data.copy(current.art),
      document = {
        header = {
          right = {
            type = "label",
            text = "MODE: " .. tostring(model.sortMode)
              .. "  ·  001–251",
          },
        },
        contentLayout = "columns",
        regions = {
          {
            id = "species-list", role = "content", frame = true,
            components = {
              { type = "label",
                text = "NO.   NAME                       STATUS" },
              {
                type = "list",
                items = listItems,
                scroll = model.navigation.scroll or 0,
              },
            },
          },
          {
            id = "scrollbar", role = "content", preferredWidth = 28,
            frame = true,
            components = {
              {
                type = "scrollbar",
                index = model.navigation.scroll or 0,
                visible = 7,
                total = #listItems,
              },
            },
          },
          {
            id = "preview", role = "content", preferredWidth = 240,
            frame = true,
            components = previewComponents,
          },
          {
            id = "progress", role = "content", dock = "bottom-right",
            frame = true,
            preferredHeight = 86,
            components = {
              { type = "metadata", items = {
                { label = "SEEN",
                  value = (". . . .  %d"):format(model.totals.seen or 0) },
                { label = "OWNED",
                  value = (". . . .  %d"):format(model.totals.caught or 0) },
              } },
            },
          },
        },
        controls = "UP/DOWN SPECIES   A DATA   SELECT OPTIONS   B BACK",
      },
    }
  end

  local function entryPresentation(model)
    local current = model.current
    if type(current) ~= "table" then return nil, "entry_unavailable" end
    local rows = {}
    local actionLabels = { PAGE = "INFO", AREA = "AREA", CRY = "CRY",
      PRNT = "PRNT" }
    if not model.entry.newEntry then
      for index, source in ipairs(model.entry.actions or {}) do
        rows[index] = row(source, nil, actionLabels[source.label]
          or source.label)
      end
    end
    local details = richDetails(current.art, {
      { label = "NUMBER", value = dexNumber(current.dex) },
      { label = "SPECIES", value = current.kind or "" },
      { label = "HEIGHT", value = current.caught and current.height or "?" },
      { label = "WEIGHT", value = current.caught and current.weight or "?" },
      { label = "STATUS", value = status(current), style = "accent" },
    }, current.name or "ENTRY", current.types)
    return {
      rows = rows,
      selected = model.entry.newEntry and nil or model.entry.selectedAction,
      scroll = 0,
      details = details,
      description = current.pageLines and #current.pageLines > 0
        and current.pageLines or (model.entry.newEntry
          and "A/B CONTINUE" or "LEFT/RIGHT ACTION   A CHOOSE   B LIST"),
      title = (current.name or "ENTRY") .. " / " .. dexNumber(current.dex),
      art = Data.copy(current.art),
      entry = Data.copy(current),
      document = entryDocument(current, model.entry.selectedAction),
    }
  end

  local function areaPresentation(model)
    local area = model.area
    if type(area) ~= "table" then return nil, "area_unavailable" end
    local rows = {}
    for index, nest in ipairs(area.nests or {}) do
      rows[index] = {
        id = nest.id,
        sourceIndex = index,
        label = nest.name,
        right = (area.region or ""):upper(),
        disabled = true,
      }
    end
    if #rows == 0 then
      rows[1] = {
        id = "area_unknown", sourceIndex = 1,
        label = "AREA UNKNOWN", disabled = true,
      }
    end
    local mapRows = {}
    for index, nest in ipairs(area.nests or {}) do
      mapRows[index] = {
        index = nest.index, x = nest.x, y = nest.y, name = nest.name,
        nest = true, selected = index == 1,
      }
    end
    return {
      rows = rows,
      selected = nil,
      scroll = 0,
      mapView = true,
      map = {
        rows = mapRows,
        current = mapRows[1],
      },
      details = richDetails(area.art, {
        { label = "POKEMON", value = area.name },
        { label = "REGION", value = (area.region or "johto"):upper(),
          style = "accent" },
        { label = "KNOWN NESTS", value = #area.nests },
      }, area.name or "AREA"),
      description = "LEFT/RIGHT REGION   A/B RETURN",
      title = (area.name or "POKEMON") .. "  /  HABITAT",
      art = Data.copy(area.art),
      area = Data.copy(area),
    }
  end

  local function optionPresentation(model)
    local rows = {}
    local selectedDescription
    for index, source in ipairs(model.options.rows or {}) do
      rows[index] = row(source, source.mode)
      if index == model.options.selectedIndex then
        selectedDescription = Data.copy(source.description)
      end
    end
    return {
      rows = rows,
      selected = model.options.selectedIndex,
      scroll = 0,
      details = {},
      description = selectedDescription or "A CHOOSE   B/SELECT BACK",
      title = "POKEDEX OPTIONS",
    }
  end

  local function searchPresentation(model)
    local rows = {}
    for index, source in ipairs(model.search.rows or {}) do
      rows[index] = row(source, source.value)
    end
    local description = model.search.message ~= ""
      and model.search.message
      or "LEFT/RIGHT TYPE   A CHOOSE   B/START BACK"
    return {
      rows = rows,
      selected = model.search.selectedIndex,
      scroll = 0,
      details = {
        { label = "RESULTS", value = model.search.resultCount or 0,
          style = model.search.resultsActive and "accent" or nil },
      },
      description = description,
      title = "POKEDEX SEARCH",
    }
  end

  local function unownPresentation(model)
    local rows = {}
    local selected
    for index, source in ipairs(model.unown.rows or {}) do
      rows[index] = row(source, source.word)
      if source.slot == model.unown.selectedSlot then selected = source end
    end
    return {
      rows = rows,
      selected = model.unown.selectedIndex,
      scroll = math.max(0, (model.unown.selectedIndex or 1) - 7),
      details = selected and richDetails(selected.art, {
        { label = "FORM", value = selected.label, style = "accent" },
        { label = "WORD", value = selected.word },
        { label = "CAUGHT ORDER", value = selected.sourceIndex },
      }, selected.label, nil) or {},
      description = "LEFT/RIGHT FORM   A/B OPTIONS",
      title = "UNOWN MODE",
      art = selected and Data.copy(selected.art) or nil,
    }
  end

  local CONVERT = {
    list = listPresentation,
    entry = entryPresentation,
    area = areaPresentation,
    option = optionPresentation,
    search = searchPresentation,
    unown = unownPresentation,
  }

  function Presenter.convert(model)
    if type(model) ~= "table" or model.screenId ~= "Gen2PokedexMenu" then
      return nil, "invalid_model"
    end
    local convert = CONVERT[model.view]
    if not convert then return nil, "unknown_view", model.view end
    local content, code = convert(model)
    if not content then return nil, code or "conversion_failed" end
    content.kind = content.document and "document" or "menu"
    content.preset = "L"
    content.opaque = true
    content.title = content.title or ("POKEDEX  /  " .. tostring(model.sortMode))
    content.sourceView = model.view
    content.sourceMode = model.sortMode
    return canonical(content)
  end

  function Presenter.prepare(_, state, context)
    local bundle, code, detail = Adapter.extract(state, context)
    if not bundle then return nil, code, detail end
    local model, convertCode, convertDetail = Presenter.convert(bundle.model)
    if not model then return nil, convertCode, convertDetail end
    return {
      complete = true,
      model = model,
      sourceModel = bundle.model,
      actions = bundle.actions,
    }
  end

  function Presenter.register(provider)
    if type(provider) ~= "table" then return nil, "invalid_provider" end
    local ok, code, detail = provider:registerModelAdapter(
      "Gen2PokedexMenu", Adapter)
    if not ok then return nil, code, detail end
    return provider:registerPresenter("Gen2PokedexMenu", Presenter)
  end

  return Presenter
end
