return function()
  local Data = {}

  local DEFAULT_MAX_DEPTH = 6
  local DEFAULT_MAX_ENTRIES = 256
  local TOKEN_TEXT = {
    ["<PO><KE>"] = "POKé",
    ["<PK><MN>"] = "POKéMON",
  }

  local function finite(value)
    return type(value) == "number"
      and value == value
      and value ~= math.huge
      and value ~= -math.huge
  end

  local function primitive(value)
    local kind = type(value)
    if kind == "string" or kind == "boolean" then return value end
    if kind == "number" and finite(value) then return value end
    return nil
  end

  function Data.scalar(value, fallback)
    local copied = primitive(value)
    if copied ~= nil then return copied end
    return fallback
  end

  function Data.integer(value, fallback)
    if finite(value) and value == math.floor(value) then return value end
    return fallback
  end

  function Data.text(value, fallback)
    local kind = type(value)
    local text
    if kind == "string" then
      text = value
    elseif kind == "number" and finite(value) then
      text = tostring(value)
    elseif kind == "boolean" then
      text = value and "ON" or "OFF"
    end
    if text == nil then return fallback or "" end
    for token, replacement in pairs(TOKEN_TEXT) do
      text = text:gsub(token, replacement)
    end
    text = text:gsub("%s+$", "")
    if text == "" then return fallback or "" end
    return text
  end

  function Data.id(value, fallback)
    local kind = type(value)
    if kind == "string" and value ~= "" then return value end
    if kind == "number" and finite(value) then return tostring(value) end
    return fallback
  end

  -- Copy only data values into a plain, acyclic table. raw next() avoids
  -- executing __pairs on a source-owned object. Unsupported values, cycles,
  -- and content beyond the explicit bounds are omitted.
  function Data.copy(value, options)
    options = options or {}
    local maxDepth = options.maxDepth or DEFAULT_MAX_DEPTH
    local maxEntries = options.maxEntries or DEFAULT_MAX_ENTRIES
    local active = {}

    local function clone(current, depth)
      local scalar = primitive(current)
      if scalar ~= nil then return scalar end
      if type(current) ~= "table" or depth > maxDepth or active[current] then
        return nil
      end

      active[current] = true
      local output = {}
      local copied = 0
      local key, item = next(current, nil)
      while key ~= nil and copied < maxEntries do
        local safeKey = primitive(key)
        if safeKey ~= nil then
          local safeValue = clone(item, depth + 1)
          if safeValue ~= nil then
            output[safeKey] = safeValue
            copied = copied + 1
          end
        end
        key, item = next(current, key)
      end
      active[current] = nil
      return output
    end

    return clone(value, 1)
  end

  function Data.array(value, limit)
    local output = {}
    if type(value) ~= "table" then return output end
    local count = math.min(#value, limit or DEFAULT_MAX_ENTRIES)
    for index = 1, count do
      local copied = Data.copy(rawget(value, index))
      if copied ~= nil then output[#output + 1] = copied end
    end
    return output
  end

  function Data.countTruthy(value, limit)
    if type(value) ~= "table" then return 0 end
    local count, visited = 0, 0
    local key, item = next(value, nil)
    while key ~= nil and visited < (limit or 4096) do
      if item then count = count + 1 end
      visited = visited + 1
      key, item = next(value, key)
    end
    return count
  end

  function Data.isFunctionFree(value)
    local active = {}
    local function visit(current)
      local kind = type(current)
      if kind == "function" or kind == "thread" or kind == "userdata" then
        return false
      end
      if kind ~= "table" then return true end
      if active[current] then return false end
      active[current] = true
      local key, item = next(current, nil)
      while key ~= nil do
        if not visit(key) or not visit(item) then
          active[current] = nil
          return false
        end
        key, item = next(current, key)
      end
      active[current] = nil
      return getmetatable(current) == nil
    end
    return visit(value)
  end

  return Data
end
