return function(ctx)
  local Data = ctx.load("adapters.data")
  local Actions = {}

  function Actions.new(screenId)
    return { screenId = screenId, entries = {}, order = {} }
  end

  -- Action entries intentionally retain source callables and receivers. They
  -- live outside presenter models and are never called while a model is being
  -- extracted. A later input bridge can resolve one explicit action ID and
  -- hand control back to the official screen.
  function Actions.add(map, spec)
    if type(map) ~= "table" or type(spec) ~= "table" then return nil end
    local id = Data.id(spec.id)
    if not id or map.entries[id] ~= nil then return nil end

    local callback = spec.callback
    if callback ~= nil and type(callback) ~= "function" then return nil end
    local dispatch = spec.dispatch
      or (callback and "source_callback" or "source_input")
    if dispatch == "source_callback" and not callback then return nil end
    if dispatch == "source_input" and type(spec.input) ~= "string" then
      return nil
    end

    local metadata = {
      id = id,
      owner = "source",
      dispatch = dispatch,
      source = Data.text(spec.source, "source"),
      kind = Data.text(spec.kind, "action"),
      componentId = Data.id(spec.componentId),
      sourceIndex = Data.integer(spec.sourceIndex),
      input = Data.id(spec.input),
      enabled = spec.enabled ~= false,
      callStyle = callback and (spec.receiver ~= nil and "method" or "function")
        or nil,
      argumentCount = Data.integer(spec.argumentCount,
        type(spec.arguments) == "table" and #spec.arguments or 0),
    }
    local entry = {
      id = id,
      owner = "source",
      dispatch = dispatch,
      callback = callback,
      receiver = spec.receiver,
      arguments = type(spec.arguments) == "table" and spec.arguments or {},
      argumentCount = metadata.argumentCount,
      metadata = metadata,
    }
    map.entries[id] = entry
    map.order[#map.order + 1] = id
    return id
  end

  function Actions.describe(map)
    local output = {}
    for _, id in ipairs(type(map) == "table" and map.order or {}) do
      local entry = map.entries[id]
      if entry then output[#output + 1] = Data.copy(entry.metadata) end
    end
    return output
  end

  return Actions
end
