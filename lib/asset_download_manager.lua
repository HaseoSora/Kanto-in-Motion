-- Kanto in Motion HD Asset Manager (v45 ZIP installer + legacy migration)
-- Downloads the complete asset pack as one temporary GitHub Release ZIP,
-- then parses/extracts the ZIP directly instead of mounting it through PhysFS.
-- This avoids the mod-sandbox mount restriction and works with normal ZIP
-- STORE (method 0) and DEFLATE (method 8) entries. Portable mode keeps the
-- engine's asynchronous Fetch.download path, then reopens that launcher-owned
-- save-directory ZIP through Gen1Recomp's native file helper for extraction.
return function(mod)
  local IS_GEN3 = tonumber(mod.generation) == 3
  local SCREEN_ID = "animated_menu_pokemon:asset_manager"
  local REPO = "HaseoSora/Kanto-in-Motion-Assets"
  local ASSET_VERSION = "1.0.0"
  local CACHE_ROOT = "kim_assets/files/"
  local COMPLETE_KEY = "kim_assets/complete.txt"
  local PACK_META_KEY = "kim_assets/asset-pack.json"
  local PACK_INDEX_KEY = "kim_assets/installed-files.txt"
  local DEFER_KEY = "kim_assets/deferred.txt"
  local COMPLETE_VALUE = "zip:" .. ASSET_VERSION
  local LEGACY_COMPLETE_VALUE = "legacy:" .. ASSET_VERSION
  local LEGACY_EXPECTED_FILES = 768
  local LEGACY_ROOTS = {
    "assets/battle/hd-pokemon",
    "assets/battle/backgrounds/hd",
  }
  -- Asset pack v1.0.0 contains National Dex #001-386. Species in this
  -- set have separate male/female files instead of one default file.
  local PACK_POKEMON_MAX_DEX = 386
  local PACK_GENDER_VARIANTS = {
    [3]=true,[12]=true,[19]=true,[20]=true,[25]=true,[26]=true,[41]=true,[42]=true,
    [44]=true,[45]=true,[64]=true,[65]=true,[84]=true,[85]=true,[97]=true,[111]=true,
    [112]=true,[118]=true,[119]=true,[123]=true,[129]=true,[130]=true,[133]=true,[154]=true,
    [165]=true,[166]=true,[178]=true,[185]=true,[186]=true,[190]=true,[194]=true,[195]=true,
    [198]=true,[202]=true,[203]=true,[207]=true,[208]=true,[212]=true,[214]=true,[215]=true,
    [217]=true,[221]=true,[224]=true,[229]=true,[232]=true,[255]=true,[256]=true,[257]=true,
    [267]=true,[269]=true,[272]=true,[274]=true,[275]=true,[307]=true,[308]=true,[315]=true,
    [316]=true,[317]=true,[322]=true,[323]=true,[332]=true,[350]=true,[369]=true,
  }
  local TEMP_NAME = "kim_assets_v" .. ASSET_VERSION:gsub("[^%w]", "_") .. ".tmp.zip"
  local MOUNT_POINT = "kim_asset_pack_mount"
  local EXTRACT_BUDGET = 0.010 -- seconds of extraction work per update tick
  local MAX_CACHE_FILE = 64 * 1024 * 1024
  local DOWNLOAD_MAX_SECONDS = 15 * 60 -- large GitHub release; Fetch default (90s) is too short
  -- v3 temporarily staged portable downloads as ranged cache chunks. Keep
  -- these names only so v4 can clean up an interrupted v3 attempt. v4 itself
  -- uses Fetch.download's normal asynchronous save-directory file and opens it
  -- through SaveData.openNative once the transfer completes.
  local PORTABLE_CHUNK_SIZE = 32 * 1024 * 1024
  local PORTABLE_CHUNK_ROOT = "kim_assets/download-temp/"
  local PORTABLE_CHUNK_META_KEY = "kim_assets/download-temp.txt"

  local manager = {
    screenId = SCREEN_ID,
    state = "idle",
    error = nil,
    game = nil,
    opening = false,
    autoPromptArmed = false,
    revision = 0,
    imageCache = {},
    releaseHandle = nil,
    release = nil,
    downloadHandle = nil,
    downloadTotal = 0,
    downloadBytes = 0,
    tempName = TEMP_NAME,
    zipReader = nil,
    extractFiles = {},
    extractPos = 1,
    extractedCount = 0,
    extractedBytes = 0,
    extractTotalBytes = 0,
    packMetaRaw = nil,
    rawFs = nil,
    legacyFiles = {},
    legacyPos = 1,
    legacyCount = 0,
    legacyBytes = 0,
    legacyTotalBytes = 0,
    legacyScanned = false,
    legacyDetected = false,
    installSource = nil,
    deleteFiles = {},
    deletePos = 1,
    deletedCount = 0,
    portableMode = false,
    downloadMode = "raw",
    portableTempPath = nil,
    nativeFs = nil,
    portableChunkSize = PORTABLE_CHUNK_SIZE,
    portableChunkCount = 0,
    portableChunkIndex = 0,
    portableChunkStart = 0,
    portableChunkEnd = -1,
  }

  local function cacheAvailable()
    return mod.cache
      and type(mod.cache.read) == "function"
      and type(mod.cache.write) == "function"
      and type(mod.cache.info) == "function"
  end

  local function cacheKey(relative)
    return CACHE_ROOT .. tostring(relative or "")
  end

  -- Fetch.download writes into the engine's real LÖVE save directory. On a
  -- normal install SaveData.persistenceFs() gives us that engine-owned
  -- filesystem (including random-access File handles). In portable mode it
  -- intentionally gives us the io-backed portable facade instead, so v4
  -- resolves the real engine download path separately and opens it natively.
  local function resolveRawFilesystem()
    local okSave, SaveData = pcall(require, "src.core.SaveData")
    if not okSave or not SaveData or type(SaveData.persistenceFs) ~= "function" then
      return nil, "Gen1Recomp persistence filesystem is unavailable."
    end
    local okFs, fs = pcall(SaveData.persistenceFs)
    if not okFs or type(fs) ~= "table" then
      return nil, "Gen1Recomp raw filesystem is unavailable."
    end
    if type(fs.newFile) ~= "function" or type(fs.getInfo) ~= "function"
        or type(fs.remove) ~= "function" then
      return nil, "Gen1Recomp random-access download filesystem is unavailable."
    end
    return fs
  end

  local function portableModeActive()
    local okSave, SaveData = pcall(require, "src.core.SaveData")
    if not okSave or not SaveData or type(SaveData.isPortable) ~= "function" then
      return false
    end
    local okPortable, active = pcall(SaveData.isPortable)
    return okPortable and active == true
  end

  local function mobilePlatformActive()
    if not (love and love.system and type(love.system.getOS) == "function") then
      return false
    end
    local ok, name = pcall(love.system.getOS)
    return ok and (name == "Android" or name == "iOS")
  end

  -- Fetch.download is engine-owned and always writes its temporary file into
  -- LÖVE's real save directory. Portable mode and the Game3 mobile sandbox can
  -- both make the mod-visible filesystem differ from that worker-owned path,
  -- so ask an engine-owned path helper for the real directory and reopen the
  -- completed ZIP natively. ShaderFX.presetDir normally prefers the portable
  -- root; suppress only that preference for this synchronous path query, then
  -- restore it immediately. No persistence routing is changed.
  local function resolveEngineSaveDirectory()
    local okSave, SaveData = pcall(require, "src.core.SaveData")
    if not okSave or type(SaveData) ~= "table"
        or type(SaveData.openNative) ~= "function"
        or type(SaveData.statNative) ~= "function"
        or type(SaveData.removeNative) ~= "function" then
      return nil, nil, "Gen1Recomp native file helpers are unavailable."
    end
    local okShader, ShaderFX = pcall(require, "src.render.ShaderFX")
    if not okShader or type(ShaderFX) ~= "table" or type(ShaderFX.presetDir) ~= "function" then
      return nil, nil, "Gen1Recomp save-directory path helper is unavailable."
    end
    local originalPortable = SaveData.portableBaseDir
    if type(originalPortable) ~= "function" then
      return nil, nil, "Gen1Recomp portable path helper is unavailable."
    end

    local restoreOk = false
    local okDir, shaderDir
    local okSwap = pcall(function()
      SaveData.portableBaseDir = function() return nil end
      restoreOk = true
      okDir, shaderDir = pcall(ShaderFX.presetDir)
    end)
    SaveData.portableBaseDir = originalPortable
    if not okSwap or not restoreOk or not okDir or type(shaderDir) ~= "string" or shaderDir == "" then
      return nil, nil, "Could not resolve Gen1Recomp's real download directory."
    end
    if shaderDir:sub(-7) ~= "shaders" then
      return nil, nil, "Gen1Recomp returned an unexpected save-directory path."
    end
    local base = shaderDir:sub(1, -8)
    while base:sub(-1) == "/" or base:sub(-1) == "\\" do
      base = base:sub(1, -2)
    end
    if base == "" then return nil, nil, "Gen1Recomp save directory is empty." end
    local sep = base:find("\\", 1, true) and "\\" or "/"
    return base .. sep .. TEMP_NAME, SaveData
  end

  local function safeCacheInfo(key)
    if not cacheAvailable() then return nil end
    local ok, info = pcall(function() return mod.cache:info(key) end)
    if ok then return info end
    return nil
  end

  local function safeCacheRead(key)
    if not cacheAvailable() then return nil end
    local ok, bytes = pcall(function() return mod.cache:read(key) end)
    if ok and type(bytes) == "string" then return bytes end
    return nil
  end

  local function safeCacheWrite(key, bytes)
    if not cacheAvailable() then return false, "mod.cache is unavailable" end
    local ok, wrote, err = pcall(function() return mod.cache:write(key, bytes) end)
    if not ok then return false, tostring(wrote) end
    if wrote == false then return false, tostring(err or "cache write failed") end
    return true
  end

  local function safeCacheDelete(key)
    if not (mod.cache and type(mod.cache.delete) == "function") then
      return false, "mod.cache deletion is unavailable"
    end
    local ok, removed, err = pcall(function() return mod.cache:delete(key) end)
    if not ok then return false, tostring(removed) end
    if removed == false or removed == nil then
      -- Deleting a missing cache key is already the desired end state.
      if safeCacheInfo(key) == nil then return true end
      return false, tostring(err or "cache delete failed")
    end
    return true
  end

  local function safeModInfo(relative)
    if type(mod.info) ~= "function" then return nil end
    local ok, info = pcall(function() return mod:info(relative) end)
    if ok then return info end
    return nil
  end

  local function safeModList(relative)
    if type(mod.list) ~= "function" then return nil end
    local ok, names = pcall(function() return mod:list(relative) end)
    if ok and type(names) == "table" then return names end
    return nil
  end

  local function scanLegacyTree(relative, out)
    local info = safeModInfo(relative)
    if not info then return end
    if info.type == "file" then
      out[#out + 1] = { relative = relative, size = tonumber(info.size) or 0 }
      return
    end
    if info.type ~= "directory" then return end
    local names = safeModList(relative) or {}
    for _, name in ipairs(names) do
      local child = relative .. "/" .. tostring(name)
      scanLegacyTree(child, out)
    end
  end

  function manager:scanLegacy(force)
    if self.legacyScanned and not force then
      return self.legacyDetected, self.legacyFiles, self.legacyTotalBytes
    end
    local files = {}
    for _, root in ipairs(LEGACY_ROOTS) do scanLegacyTree(root, files) end
    table.sort(files, function(a, b) return a.relative < b.relative end)
    local total = 0
    for _, item in ipairs(files) do total = total + (tonumber(item.size) or 0) end
    self.legacyFiles = files
    self.legacyTotalBytes = total
    self.legacyScanned = true
    self.legacyDetected = #files >= LEGACY_EXPECTED_FILES
    return self.legacyDetected, files, total
  end

  function manager:hasLegacyAssets()
    local detected = self:scanLegacy(false)
    return detected == true
  end

  local function logInfo(fmt, ...)
    if mod.log and mod.log.info then pcall(mod.log.info, mod.log, fmt, ...) end
  end

  local function logError(fmt, ...)
    if mod.log and mod.log.error then pcall(mod.log.error, mod.log, fmt, ...) end
  end

  local function portableChunkKey(index)
    return PORTABLE_CHUNK_ROOT .. string.format("part-%04d.bin", tonumber(index) or 0)
  end

  local function readPortableChunkMeta()
    local raw = safeCacheRead(PORTABLE_CHUNK_META_KEY)
    if type(raw) ~= "string" then return nil end
    local total, chunkSize, count = raw:match("^(%d+)\n(%d+)\n(%d+)")
    total, chunkSize, count = tonumber(total), tonumber(chunkSize), tonumber(count)
    if not total or total <= 0 or not chunkSize or chunkSize <= 0 or not count or count <= 0 then
      return nil
    end
    return total, chunkSize, count
  end

  local function clearPortableDownloadParts()
    local _, _, storedCount = readPortableChunkMeta()
    local count = math.max(tonumber(manager.portableChunkCount) or 0, tonumber(storedCount) or 0)
    for i = 1, count do safeCacheDelete(portableChunkKey(i)) end
    safeCacheDelete(PORTABLE_CHUNK_META_KEY)
    manager.portableChunkCount = 0
    manager.portableChunkIndex = 0
    manager.portableChunkStart = 0
    manager.portableChunkEnd = -1
  end

  local function closeZipReader()
    local r = manager.zipReader
    if r and r.file and type(r.file.close) == "function" then
      pcall(function() r.file:close() end)
    end
    manager.zipReader = nil
  end

  local function removeTemp()
    local fs = manager.rawFs
    if fs and type(fs.remove) == "function" then
      pcall(fs.remove, manager.tempName)
    end
    if manager.nativeFs and manager.portableTempPath
        and type(manager.nativeFs.removeNative) == "function" then
      pcall(manager.nativeFs.removeNative, manager.portableTempPath)
    end
    -- Also retire any ranged-cache leftovers from the short-lived v3 test.
    clearPortableDownloadParts()
  end

  local function cleanupArchive()
    closeZipReader()
    removeTemp()
  end

  local function cancelNetworkJob()
    if not manager.downloadHandle then return end
    local okFetch, Fetch = pcall(require, "src.net.Fetch")
    if okFetch and Fetch then
      local job = manager.downloadHandle
      if type(Fetch.cancel) == "function" then pcall(Fetch.cancel, job) end
      if type(Fetch.release) == "function" then pcall(Fetch.release, job) end
    end
    manager.downloadHandle = nil
  end


  function manager:isComplete()
    if not cacheAvailable() then return false end
    local value = safeCacheRead(COMPLETE_KEY)
    return value == COMPLETE_VALUE or value == LEGACY_COMPLETE_VALUE
  end

  function manager:completionSource()
    local value = safeCacheRead(COMPLETE_KEY)
    if value == LEGACY_COMPLETE_VALUE then return "legacy" end
    if value == COMPLETE_VALUE then return "download" end
    return nil
  end

  function manager:isDeferred()
    return safeCacheRead(DEFER_KEY) == ASSET_VERSION
  end

  function manager:defer()
    if cacheAvailable() then safeCacheWrite(DEFER_KEY, ASSET_VERSION) end
  end

  function manager:clearDefer()
    safeCacheDelete(DEFER_KEY)
  end

  function manager:sourceRevision()
    return self.revision or 0
  end

  function manager:exists(relative)
    local info = safeCacheInfo(cacheKey(relative))
    return info ~= nil and (tonumber(info.size) or 0) > 0
  end

  function manager:image(relative)
    if type(relative) ~= "string" then return nil end
    local cached = self.imageCache[relative]
    if cached then return cached end
    local bytes = safeCacheRead(cacheKey(relative))
    if type(bytes) ~= "string" or #bytes == 0 then return nil end
    if not (love and love.filesystem and love.filesystem.newFileData
        and love.graphics and love.graphics.newImage) then
      return nil
    end
    local okData, fileData = pcall(love.filesystem.newFileData, bytes, relative)
    if not okData or not fileData then return nil end
    local okImage, image = pcall(love.graphics.newImage, fileData)
    if not okImage or not image then return nil end
    if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
    self.imageCache[relative] = image
    return image
  end

  function manager:statusLabel()
    if self:isComplete() then return "READY" end
    if self.state == "checking" then return "CHECKING" end
    if self.state == "downloading" then return "DOWNLOADING" end
    if self.state == "extracting" then return "INSTALLING" end
    if self.state == "migrating" then return "MIGRATING" end
    if self.state == "deleting" then return "DELETING" end
    if self.state == "confirm_delete" then return "MANAGE" end
    if self.state == "deleted" then return "DOWNLOAD" end
    if self.state == "delete_error" then return "ERROR" end
    if self.state == "error" then return "ERROR" end
    return "DOWNLOAD"
  end

  local function addDeleteRelative(out, seen, relative)
    if type(relative) ~= "string" then return end
    relative = relative:gsub("\\", "/"):gsub("^%./", "")
    if relative:sub(1, 7) ~= "assets/" or seen[relative] then return end
    seen[relative] = true
    out[#out + 1] = relative
  end

  -- Build a complete removal list without needing a cache-directory listing API.
  -- New installs persist the exact extracted file list. Existing v1.6.0/1.6.1
  -- installs predate that index, so fall back to KIM's generated Pokemon table
  -- plus the authored battle-background catalog.
  local function collectInstalledAssetPaths()
    local out, seen = {}, {}
    local rawIndex = safeCacheRead(PACK_INDEX_KEY)
    if type(rawIndex) == "string" then
      for relative in rawIndex:gmatch("[^\r\n]+") do
        addDeleteRelative(out, seen, relative)
      end
    end

    -- v1.0.0 pack fallback for installs created before installed-files.txt
    -- existed. Generate all Pokemon cache keys directly from the pack schema
    -- so even currently unused Gen 2/3 art is removed, not just files named in
    -- KIM's active generation table.
    local sides = { "front", "back" }
    local palettes = { "normal", "shiny" }
    for dex = 1, PACK_POKEMON_MAX_DEX do
      local base = string.format("%03d", dex)
      local names = PACK_GENDER_VARIANTS[dex]
        and { base .. "-m.png", base .. "-f.png" } or { base .. ".png" }
      for _, side in ipairs(sides) do
        for _, palette in ipairs(palettes) do
          for _, name in ipairs(names) do
            addDeleteRelative(out, seen,
              "assets/battle/hd-pokemon/" .. side .. "/" .. palette .. "/" .. name)
          end
        end
      end
    end

    local okBgRead, bgSource = pcall(function() return mod:read("data/hd_battle_backgrounds.lua") end)
    if okBgRead and type(bgSource) == "string" then
      local chunk = load(bgSource, "@" .. tostring(mod.path) .. "/data/hd_battle_backgrounds.lua")
      if chunk then
        local okBg, bg = pcall(chunk)
        if okBg and type(bg) == "table" and type(bg.previewCatalog) == "function"
            and type(bg.availablePeriods) == "function" and type(bg.previewBackdrop) == "function" then
          local okCatalog, catalog = pcall(bg.previewCatalog)
          if okCatalog and type(catalog) == "table" then
            for _, entry in ipairs(catalog) do
              local id = entry and entry.id
              local okPeriods, periods = pcall(bg.availablePeriods, id)
              if okPeriods and type(periods) == "table" then
                for _, period in ipairs(periods) do
                  local okBackdrop, backdrop = pcall(bg.previewBackdrop, id, period)
                  if okBackdrop and type(backdrop) == "table" and type(backdrop.file) == "string" then
                    addDeleteRelative(out, seen,
                      "assets/battle/backgrounds/hd/" .. backdrop.file .. ".png")
                  end
                end
              end
            end
          end
        end
      end
    end

    table.sort(out)
    return out
  end

  local function writeInstalledAssetIndex(files)
    local lines = {}
    for _, item in ipairs(files or {}) do
      local relative = type(item) == "table" and item.relative or item
      if type(relative) == "string" and relative:sub(1, 7) == "assets/" then
        lines[#lines + 1] = relative
      end
    end
    table.sort(lines)
    if #lines == 0 then return true end
    local ok, err = safeCacheWrite(PACK_INDEX_KEY, table.concat(lines, "\n") .. "\n")
    if not ok then
      logError("KIM could not save HD asset removal index: %s", tostring(err))
      return false, err
    end
    return true
  end

  local function finishDeletion()
    -- The completion marker was cleared when removal began. Keep the defer
    -- marker so an intentional removal does not immediately nag again on the
    -- next boot; ASSET MANAGER remains available for a manual re-download.
    local okMeta, metaErr = safeCacheDelete(PACK_META_KEY)
    if not okMeta then
      manager.state = "delete_error"
      manager.error = "Could not remove asset metadata: " .. tostring(metaErr)
      return
    end
    safeCacheDelete(PACK_INDEX_KEY)
    safeCacheWrite(DEFER_KEY, ASSET_VERSION)
    manager.imageCache = {}
    manager.installSource = nil
    manager.state = "deleted"
    manager.error = nil
    logInfo("Kanto in Motion removed %d cached HD assets; they can be downloaded again later", manager.deletedCount)
  end

  local function pumpDeletion()
    if manager.state ~= "deleting" then return end
    local started = love.timer and love.timer.getTime and love.timer.getTime() or nil
    local processed = 0
    while manager.deletePos <= #manager.deleteFiles do
      local relative = manager.deleteFiles[manager.deletePos]
      local key = cacheKey(relative)
      if safeCacheInfo(key) ~= nil then
        local okDelete, deleteErr = safeCacheDelete(key)
        if not okDelete then
          manager.state = "delete_error"
          manager.error = "Could not remove " .. relative .. ": " .. tostring(deleteErr)
          return
        end
      end
      manager.imageCache[relative] = nil
      manager.deletePos = manager.deletePos + 1
      manager.deletedCount = manager.deletedCount + 1
      processed = processed + 1
      if started and love.timer and love.timer.getTime then
        if love.timer.getTime() - started >= EXTRACT_BUDGET then break end
      elseif processed >= 8 then
        break
      end
    end
    if manager.deletePos > #manager.deleteFiles then finishDeletion() end
  end

  function manager:beginDelete()
    if not cacheAvailable() then
      self.state = "delete_error"
      self.error = "This Gen1Recomp build does not provide mod.cache."
      return false
    end
    cancelNetworkJob()
    self.releaseHandle = nil
    cleanupArchive()
    self.deleteFiles = collectInstalledAssetPaths()
    self.deletePos = 1
    self.deletedCount = 0
    self.error = nil
    -- Once removal begins, stop advertising the pack as complete even if a
    -- later file deletion fails. This prevents KIM from trusting a partial
    -- cache and makes the recovery path explicit.
    safeCacheWrite(DEFER_KEY, ASSET_VERSION)
    local okDone, doneErr = safeCacheDelete(COMPLETE_KEY)
    if not okDone then
      self.state = "delete_error"
      self.error = "Could not clear asset completion marker: " .. tostring(doneErr)
      return false
    end
    self.imageCache = {}
    self.revision = self.revision + 1
    self.state = "deleting"
    return true
  end

  local function finishLegacyMigration()
    writeInstalledAssetIndex(manager.legacyFiles)
    local meta = string.format('{"id":"kanto_in_motion_assets","version":"%s","source":"legacy-local","files":%d}',
      ASSET_VERSION, manager.legacyCount)
    local wroteMeta, metaErr = safeCacheWrite(PACK_META_KEY, meta)
    if not wroteMeta then
      manager.state = "error"
      manager.error = "Could not save migrated asset metadata: " .. tostring(metaErr)
      return
    end
    local wroteDone, doneErr = safeCacheWrite(COMPLETE_KEY, LEGACY_COMPLETE_VALUE)
    if not wroteDone then
      manager.state = "error"
      manager.error = "Could not save migration completion marker: " .. tostring(doneErr)
      return
    end
    manager:clearDefer()
    manager.state = "done"
    manager.error = nil
    manager.installSource = "legacy"
    manager.revision = manager.revision + 1
    logInfo("Kanto in Motion migrated %d legacy HD assets into persistent cache", manager.legacyCount)
  end

  local function pumpLegacyMigration()
    if manager.state ~= "migrating" then return end
    local started = love.timer and love.timer.getTime and love.timer.getTime() or nil
    local processed = 0
    while manager.legacyPos <= #manager.legacyFiles do
      local item = manager.legacyFiles[manager.legacyPos]
      local existing = safeCacheInfo(cacheKey(item.relative))
      local already = existing and (tonumber(existing.size) or -1) == (tonumber(item.size) or -2)
      if not already then
        local okRead, bytes, readErr = pcall(function() return mod:read(item.relative) end)
        if not okRead then
          manager.state = "error"
          manager.error = "Could not read existing asset " .. item.relative .. ": " .. tostring(bytes)
          return
        end
        if type(bytes) ~= "string" or #bytes == 0 then
          manager.state = "error"
          manager.error = "Could not read existing asset " .. item.relative .. ": " .. tostring(readErr or "empty file")
          return
        end
        local okWrite, writeErr = safeCacheWrite(cacheKey(item.relative), bytes)
        if not okWrite then
          manager.state = "error"
          manager.error = "Could not migrate " .. item.relative .. ": " .. tostring(writeErr)
          return
        end
        manager.imageCache[item.relative] = nil
      end
      manager.legacyPos = manager.legacyPos + 1
      manager.legacyCount = manager.legacyCount + 1
      manager.legacyBytes = manager.legacyBytes + (tonumber(item.size) or 0)
      processed = processed + 1
      if started and love.timer and love.timer.getTime then
        if love.timer.getTime() - started >= EXTRACT_BUDGET then break end
      elseif processed >= 2 then
        break
      end
    end
    if manager.legacyPos > #manager.legacyFiles then finishLegacyMigration() end
  end

  function manager:beginLegacyMigration()
    if self:isComplete() then return false end
    local detected, files, total = self:scanLegacy(true)
    if not detected then return false end
    self.legacyFiles = files or {}
    self.legacyPos = 1
    self.legacyCount = 0
    self.legacyBytes = 0
    self.legacyTotalBytes = tonumber(total) or 0
    self.installSource = "legacy"
    self.error = nil
    self:clearDefer()
    self.state = "migrating"
    logInfo("KIM found %d legacy HD assets; migrating locally without download", #self.legacyFiles)
    return true
  end

  local function setError(message)
    cleanupArchive()
    cancelNetworkJob()
    manager.releaseHandle = nil
    manager.state = "error"
    manager.error = tostring(message or "Unknown asset installer error")
    logError("KIM asset installer: %s", manager.error)
  end

  local function parsePackMeta(raw)
    if type(raw) ~= "string" then return nil, "asset-pack.json is unreadable" end
    local okJson, Json = pcall(require, "src.link.Json")
    if okJson and Json and type(Json.decode) == "function" then
      local okDecode, data, decodeErr = pcall(Json.decode, raw)
      if okDecode and type(data) == "table" then return data end
      if not okDecode then return nil, tostring(data) end
      return nil, tostring(decodeErr or "invalid asset-pack.json")
    end
    -- Tiny fallback parser so the pack can still validate if the engine JSON
    -- helper moves. Only the version is required for this metadata file.
    local version = raw:match('"version"%s*:%s*"([^"]+)"')
    if version then
      return { version = version, id = raw:match('"id"%s*:%s*"([^"]+)"') }
    end
    return nil, "asset-pack.json has no version"
  end

  local function le16(s, p)
    local a, b = s:byte(p, p + 1)
    if not b then return nil end
    return a + b * 256
  end

  local function le32(s, p)
    local a, b, c, d = s:byte(p, p + 3)
    if not d then return nil end
    return a + b * 256 + c * 65536 + d * 16777216
  end

  local function openPortableChunkReader()
    closeZipReader()
    local total = tonumber(manager.downloadTotal) or 0
    local chunkSize = tonumber(manager.portableChunkSize) or PORTABLE_CHUNK_SIZE
    local chunkCount = tonumber(manager.portableChunkCount) or 0
    if total <= 0 or chunkSize <= 0 or chunkCount <= 0 then
      local storedTotal, storedChunkSize, storedCount = readPortableChunkMeta()
      total = storedTotal or total
      chunkSize = storedChunkSize or chunkSize
      chunkCount = storedCount or chunkCount
    end
    if total < 22 or chunkSize <= 0 or chunkCount <= 0 then
      return nil, "portable asset ZIP staging metadata is missing"
    end
    local r = {
      size = total,
      chunkSize = chunkSize,
      chunkCount = chunkCount,
      cachedIndex = nil,
      cachedData = nil,
    }
    function r:chunk(index)
      if index < 1 or index > self.chunkCount then
        return nil, "portable ZIP chunk is outside the archive"
      end
      if self.cachedIndex == index and type(self.cachedData) == "string" then
        return self.cachedData
      end
      local data = safeCacheRead(portableChunkKey(index))
      if type(data) ~= "string" then
        return nil, "portable ZIP chunk " .. tostring(index) .. " is missing"
      end
      local offset = (index - 1) * self.chunkSize
      local expected = math.min(self.chunkSize, self.size - offset)
      if #data ~= expected then
        return nil, string.format("portable ZIP chunk %d is incomplete (%d/%d bytes)",
          index, #data, expected)
      end
      self.cachedIndex = index
      self.cachedData = data
      return data
    end
    function r:readAt(offset, count)
      offset, count = tonumber(offset), tonumber(count)
      if not offset or not count or offset < 0 or count < 0 or offset + count > self.size then
        return nil, "ZIP read is outside the archive"
      end
      if count == 0 then return "" end
      local remaining = count
      local cursor = offset
      local pieces = {}
      while remaining > 0 do
        local index = math.floor(cursor / self.chunkSize) + 1
        local data, chunkErr = self:chunk(index)
        if not data then return nil, chunkErr end
        local inChunk = cursor - (index - 1) * self.chunkSize
        local take = math.min(remaining, #data - inChunk)
        if take <= 0 then return nil, "portable ZIP chunk read made no progress" end
        pieces[#pieces + 1] = data:sub(inChunk + 1, inChunk + take)
        cursor = cursor + take
        remaining = remaining - take
      end
      return table.concat(pieces)
    end
    manager.zipReader = r
    return r
  end

  local function openZipReader()
    if manager.downloadMode == "cache_chunks" then
      return openPortableChunkReader()
    end
    if manager.downloadMode == "portable_native" then
      closeZipReader()
      local SaveData = manager.nativeFs
      local path = manager.portableTempPath
      if not (SaveData and path and type(SaveData.openNative) == "function") then
        return nil, "Gen1Recomp portable ZIP reader is unavailable."
      end
      local okOpenNative, f, openErr = pcall(SaveData.openNative, path, "rb")
      if not okOpenNative or not f then
        return nil, tostring(openErr or f or "could not open portable temporary ZIP")
      end
      local okSize, size = pcall(function() return f:seek("end", 0) end)
      if not okSize or not tonumber(size) or tonumber(size) < 22 then
        pcall(function() f:close() end)
        return nil, "downloaded portable file is too small to be a ZIP"
      end
      local r = { file = f, size = tonumber(size), native = true }
      function r:readAt(offset, count)
        if offset < 0 or count < 0 or offset + count > self.size then
          return nil, "ZIP read is outside the archive"
        end
        local okSeek, seeked = pcall(function() return self.file:seek("set", offset) end)
        if not okSeek or seeked == nil or seeked == false then return nil, "ZIP seek failed" end
        local okRead, data, readErr = pcall(function() return self.file:read(count) end)
        if not okRead or type(data) ~= "string" then
          return nil, tostring(readErr or data or "ZIP read failed")
        end
        if #data ~= count then return nil, "ZIP read was truncated" end
        return data
      end
      manager.zipReader = r
      return r
    end
    closeZipReader()
    local fs = manager.rawFs
    if not fs then return nil, "Gen1Recomp raw filesystem is unavailable." end
    local okNew, fileOrErr, makeErr = pcall(fs.newFile, manager.tempName)
    if not okNew or not fileOrErr then
      return nil, tostring(makeErr or fileOrErr or "could not open temporary ZIP")
    end
    local f = fileOrErr
    local okOpen, opened, openErr = pcall(function() return f:open("r") end)
    if not okOpen or opened == false then
      pcall(function() f:close() end)
      return nil, tostring(openErr or opened or "could not open temporary ZIP")
    end
    local okSize, size = pcall(function() return f:getSize() end)
    if not okSize or not tonumber(size) or tonumber(size) < 22 then
      pcall(function() f:close() end)
      return nil, "downloaded file is too small to be a ZIP"
    end
    local r = { file = f, size = tonumber(size) }
    function r:readAt(offset, count)
      if offset < 0 or count < 0 or offset + count > self.size then
        return nil, "ZIP read is outside the archive"
      end
      local okSeek, seeked = pcall(function() return self.file:seek(offset) end)
      if not okSeek or seeked == false then return nil, "ZIP seek failed" end
      local okRead, data, readErr = pcall(function() return self.file:read(count) end)
      if not okRead or type(data) ~= "string" then
        return nil, tostring(readErr or data or "ZIP read failed")
      end
      if #data ~= count then return nil, "ZIP read was truncated" end
      return data
    end
    manager.zipReader = r
    return r
  end

  local function scanZipDirectory(reader)
    local tailSize = math.min(reader.size, 22 + 65535 + 256)
    local tail, tailErr = reader:readAt(reader.size - tailSize, tailSize)
    if not tail then return nil, tailErr end
    local eocd = nil
    for i = #tail - 21, 1, -1 do
      if tail:sub(i, i + 3) == "PK\005\006" then eocd = i break end
    end
    if not eocd then return nil, "ZIP end record was not found" end
    local entries = le16(tail, eocd + 10)
    local cdSize = le32(tail, eocd + 12)
    local cdOffset = le32(tail, eocd + 16)
    if not entries or not cdSize or not cdOffset then return nil, "ZIP end record is truncated" end
    if entries == 0xFFFF or cdSize == 0xFFFFFFFF or cdOffset == 0xFFFFFFFF then
      return nil, "ZIP64 asset packs are not supported"
    end
    if cdOffset + cdSize > reader.size then return nil, "ZIP central directory is outside the archive" end
    local cd, cdErr = reader:readAt(cdOffset, cdSize)
    if not cd then return nil, cdErr end

    local out, pos = {}, 1
    for _ = 1, entries do
      if cd:sub(pos, pos + 3) ~= "PK\001\002" then
        return nil, "ZIP central directory entry is invalid"
      end
      local flags = le16(cd, pos + 8) or 0
      local method = le16(cd, pos + 10)
      local compSize = le32(cd, pos + 20)
      local uncompSize = le32(cd, pos + 24)
      local nameLen = le16(cd, pos + 28)
      local extraLen = le16(cd, pos + 30)
      local commentLen = le16(cd, pos + 32)
      local localOffset = le32(cd, pos + 42)
      if not (method and compSize and uncompSize and nameLen and extraLen and commentLen and localOffset) then
        return nil, "ZIP central directory is truncated"
      end
      local nameStart = pos + 46
      local name = cd:sub(nameStart, nameStart + nameLen - 1):gsub("\\", "/")
      if (flags % 2) == 1 then return nil, "Encrypted ZIP entries are not supported" end
      if name == "asset-pack.json" or (name:sub(1, 7) == "assets/" and name:sub(-1) ~= "/") then
        if method ~= 0 and method ~= 8 then
          return nil, "Unsupported ZIP compression method " .. tostring(method) .. " for " .. name
        end
        if uncompSize > MAX_CACHE_FILE then
          return nil, "Asset exceeds 64 MB cache limit: " .. name
        end
        out[#out + 1] = {
          relative = name,
          method = method,
          compressedSize = compSize,
          size = uncompSize,
          localOffset = localOffset,
        }
      end
      pos = nameStart + nameLen + extraLen + commentLen
    end
    return out
  end

  local function readZipEntry(reader, item)
    local hdr, hdrErr = reader:readAt(item.localOffset, 30)
    if not hdr then return nil, hdrErr end
    if hdr:sub(1, 4) ~= "PK\003\004" then return nil, "ZIP local header is invalid" end
    local method = le16(hdr, 9)
    local nameLen = le16(hdr, 27)
    local extraLen = le16(hdr, 29)
    if not method or not nameLen or not extraLen then return nil, "ZIP local header is truncated" end
    if method ~= item.method then return nil, "ZIP compression metadata mismatch" end
    local dataOffset = item.localOffset + 30 + nameLen + extraLen
    local packed, packedErr = reader:readAt(dataOffset, item.compressedSize)
    if not packed then return nil, packedErr end
    local bytes = packed
    if item.method == 8 then
      if not (love and love.data and type(love.data.decompress) == "function") then
        return nil, "LÖVE raw-DEFLATE support is unavailable"
      end
      local okInflate, inflated = pcall(love.data.decompress, "string", "deflate", packed)
      if not okInflate or type(inflated) ~= "string" then
        return nil, "DEFLATE decompression failed"
      end
      bytes = inflated
    end
    if #bytes ~= item.size then
      return nil, string.format("ZIP entry size mismatch (%d/%d)", #bytes, item.size)
    end
    return bytes
  end

  local function beginExtraction()
    local reader, openErr = openZipReader()
    if not reader then return setError("Downloaded asset ZIP could not be read: " .. tostring(openErr)) end
    local entries, scanErr = scanZipDirectory(reader)
    if not entries then return setError("Downloaded asset ZIP is invalid: " .. tostring(scanErr)) end

    local metaEntry, files = nil, {}
    for _, item in ipairs(entries) do
      if item.relative == "asset-pack.json" then
        metaEntry = item
      elseif item.relative:sub(1, 7) == "assets/" then
        files[#files + 1] = item
      end
    end
    if not metaEntry then return setError("Asset ZIP has no asset-pack.json at its root.") end
    if #files == 0 then return setError("Asset ZIP contains no asset files.") end

    local rawMeta, metaReadErr = readZipEntry(reader, metaEntry)
    if not rawMeta then return setError("Could not read asset-pack.json: " .. tostring(metaReadErr)) end
    local meta, metaErr = parsePackMeta(rawMeta)
    if not meta then return setError(metaErr) end
    if tostring(meta.version or "") ~= ASSET_VERSION then
      return setError("Asset pack version mismatch: " .. tostring(meta.version or "unknown"))
    end
    if meta.id ~= nil and tostring(meta.id) ~= "kanto_in_motion_assets" then
      return setError("This ZIP is not the Kanto in Motion asset pack.")
    end

    local total = 0
    for _, item in ipairs(files) do total = total + item.size end
    table.sort(files, function(a, b) return a.relative < b.relative end)

    manager.packMetaRaw = rawMeta
    manager.extractFiles = files
    manager.extractPos = 1
    manager.extractedCount = 0
    manager.extractedBytes = 0
    manager.extractTotalBytes = total
    manager.state = "extracting"
    manager.error = nil
    logInfo("KIM asset ZIP parsed directly: %d files", #files)
  end

  local function finishExtraction()
    writeInstalledAssetIndex(manager.extractFiles)
    local wroteMeta, metaErr = safeCacheWrite(PACK_META_KEY, manager.packMetaRaw or "")
    if not wroteMeta then return setError("Could not save asset-pack metadata: " .. tostring(metaErr)) end
    local wroteDone, doneErr = safeCacheWrite(COMPLETE_KEY, COMPLETE_VALUE)
    if not wroteDone then return setError("Could not save completion marker: " .. tostring(doneErr)) end
    manager:clearDefer()
    cleanupArchive()
    manager.state = "done"
    manager.error = nil
    manager.installSource = "download"
    manager.revision = manager.revision + 1
    logInfo("Kanto in Motion HD assets %s ready (%d files)", ASSET_VERSION, manager.extractedCount)
  end

  local function pumpExtraction()
    if manager.state ~= "extracting" then return end
    local reader = manager.zipReader
    if not reader then return setError("Temporary asset ZIP was closed during extraction.") end
    local started = love.timer and love.timer.getTime and love.timer.getTime() or nil
    local processed = 0
    while manager.extractPos <= #manager.extractFiles do
      local item = manager.extractFiles[manager.extractPos]
      local existing = safeCacheInfo(cacheKey(item.relative))
      local already = existing and (tonumber(existing.size) or -1) == item.size
      if not already then
        local bytes, readErr = readZipEntry(reader, item)
        if type(bytes) ~= "string" then
          return setError("Could not extract " .. item.relative .. ": " .. tostring(readErr or "read failed"))
        end
        local ok, writeErr = safeCacheWrite(cacheKey(item.relative), bytes)
        if not ok then
          return setError("Could not install " .. item.relative .. ": " .. tostring(writeErr))
        end
        manager.imageCache[item.relative] = nil
      end
      manager.extractPos = manager.extractPos + 1
      manager.extractedCount = manager.extractedCount + 1
      manager.extractedBytes = manager.extractedBytes + item.size
      processed = processed + 1

      if started and love.timer and love.timer.getTime then
        if love.timer.getTime() - started >= EXTRACT_BUDGET then break end
      elseif processed >= 2 then
        break
      end
    end
    if manager.extractPos > #manager.extractFiles then finishExtraction() end
  end

  local function startPortableChunkRequest(index)
    local okFetch, Fetch = pcall(require, "src.net.Fetch")
    if not okFetch or not Fetch or type(Fetch.request) ~= "function" then
      return setError("Gen1Recomp ranged downloader is unavailable.")
    end
    local total = tonumber(manager.downloadTotal) or 0
    local chunkSize = tonumber(manager.portableChunkSize) or PORTABLE_CHUNK_SIZE
    local first = (index - 1) * chunkSize
    local last = math.min(total - 1, first + chunkSize - 1)
    if total <= 0 or first < 0 or last < first then
      return setError("Portable asset download range is invalid.")
    end
    manager.portableChunkIndex = index
    manager.portableChunkStart = first
    manager.portableChunkEnd = last
    manager.downloadHandle = Fetch.request(manager.release.zip.url, {
      method = "GET",
      headers = { Range = string.format("bytes=%d-%d", first, last) },
      userAgent = "kanto-in-motion-assets",
      maxSeconds = DOWNLOAD_MAX_SECONDS,
    })
    if not manager.downloadHandle then
      return setError("Could not start portable ZIP download.")
    end
  end

  local function beginPortableDownload(release)
    local total = tonumber(release.zip.size) or 0
    if total <= 0 then
      return setError("GitHub did not report the asset ZIP size required for portable download.")
    end
    manager.downloadMode = "cache_chunks"
    manager.downloadTotal = total
    manager.downloadBytes = 0
    manager.portableChunkSize = PORTABLE_CHUNK_SIZE
    manager.portableChunkCount = math.ceil(total / PORTABLE_CHUNK_SIZE)
    manager.portableChunkIndex = 0
    local okMeta, metaErr = safeCacheWrite(PORTABLE_CHUNK_META_KEY,
      string.format("%d\n%d\n%d\n", total, PORTABLE_CHUNK_SIZE, manager.portableChunkCount))
    if not okMeta then
      return setError("Could not prepare portable ZIP staging: " .. tostring(metaErr))
    end
    manager.state = "downloading"
    logInfo("KIM portable asset download: %d bytes in %d cache chunks",
      total, manager.portableChunkCount)
    startPortableChunkRequest(1)
  end

  local function beginDownloadForRelease(release)
    if type(release) ~= "table" or not release.zip or not release.zip.url then
      return setError("GitHub release has no asset ZIP.")
    end
    removeTemp()
    manager.release = release
    manager.downloadTotal = tonumber(release.zip.size) or 0
    manager.downloadBytes = 0

    local okFetch, Fetch = pcall(require, "src.net.Fetch")
    if not okFetch or not Fetch or type(Fetch.download) ~= "function" then
      return setError("Gen1Recomp streaming downloader is unavailable.")
    end
    -- Keep the engine's binary-safe asynchronous file downloader everywhere.
    -- When start() resolved an engine-owned native handoff path (portable mode
    -- or FR/LG on Android/iOS), reopen that finished worker-owned ZIP by its
    -- real native path instead of asking the mod-visible filesystem to find it.
    -- Portable v4 originally introduced this path; Game3 mobile now uses the
    -- same handoff because its sandbox can expose a different save view.
    manager.downloadMode = (manager.nativeFs and manager.portableTempPath)
      and "portable_native" or "raw"
    manager.downloadHandle = Fetch.download(release.zip.url, manager.tempName, {
      size = manager.downloadTotal > 0 and manager.downloadTotal or nil,
      userAgent = "kanto-in-motion-assets",
      maxSeconds = DOWNLOAD_MAX_SECONDS,
    })
    if not manager.downloadHandle then
      return setError("Could not start ZIP download.")
    end
    manager.state = "downloading"
  end

  local function pumpReleaseCheck()
    if manager.state ~= "checking" then return end
    local okModUpdate, ModUpdate = pcall(require, "src.mods.ModUpdate")
    if not okModUpdate or not ModUpdate then return setError("Gen1Recomp release checker is unavailable.") end
    local done, releases, err = ModUpdate.pumpFetchReleases(manager.releaseHandle)
    if not done then return end
    manager.releaseHandle = nil
    if not releases then return setError(err or "Could not check asset release.") end
    local wanted = nil
    for _, rel in ipairs(releases) do
      if tostring(rel.version or "") == ASSET_VERSION and rel.zip and rel.zip.url then
        wanted = rel
        break
      end
    end
    if not wanted then return setError("Asset release v" .. ASSET_VERSION .. " was not found.") end
    beginDownloadForRelease(wanted)
  end

  local function pumpPortableDownload(Fetch)
    local st = Fetch.poll(manager.downloadHandle)
    if st.status == "pending" then return end

    local job = manager.downloadHandle
    manager.downloadHandle = nil
    Fetch.release(job)
    if st.status ~= "ok" then
      return setError(st.err or "Portable asset ZIP chunk download failed.")
    end

    local body = st.body
    local expected = manager.portableChunkEnd - manager.portableChunkStart + 1
    local code = tonumber(st.code)
    if code ~= 206 then
      -- A server that ignores Range can hand back the entire archive. Do not
      -- accept that into one cache write; the portable path is intentionally
      -- bounded to small pieces.
      return setError("Asset server did not honor portable ranged download (HTTP "
        .. tostring(code or "?") .. ").")
    end
    if type(body) ~= "string" or #body ~= expected then
      return setError(string.format("Portable asset ZIP chunk is incomplete (%d/%d bytes).",
        type(body) == "string" and #body or 0, expected))
    end

    local index = manager.portableChunkIndex
    local okWrite, writeErr = safeCacheWrite(portableChunkKey(index), body)
    if not okWrite then
      return setError("Could not stage portable ZIP chunk " .. tostring(index) .. ": " .. tostring(writeErr))
    end
    manager.downloadBytes = manager.portableChunkEnd + 1

    if index < manager.portableChunkCount then
      return startPortableChunkRequest(index + 1)
    end

    if manager.downloadBytes ~= manager.downloadTotal then
      return setError(string.format("Portable asset ZIP is incomplete (%d/%d bytes).",
        manager.downloadBytes, manager.downloadTotal))
    end
    beginExtraction()
  end

  local function pumpDownload()
    if manager.state ~= "downloading" then return end
    local okFetch, Fetch = pcall(require, "src.net.Fetch")
    if not okFetch or not Fetch then return setError("Gen1Recomp streaming downloader is unavailable.") end

    if manager.downloadMode == "cache_chunks" then
      return pumpPortableDownload(Fetch)
    end

    local fs = manager.rawFs
    if manager.downloadMode == "portable_native" and manager.nativeFs and manager.portableTempPath then
      local okInfo, info = pcall(manager.nativeFs.statNative, manager.portableTempPath)
      if okInfo and info and info.type == "file" then
        manager.downloadBytes = tonumber(info.size) or manager.downloadBytes
      end
    elseif fs then
      local okInfo, info = pcall(fs.getInfo, manager.tempName, "file")
      if okInfo and info then manager.downloadBytes = tonumber(info.size) or manager.downloadBytes end
    end

    local st = Fetch.poll(manager.downloadHandle)
    if st.status == "pending" then
      if manager.downloadTotal > 0 and tonumber(st.progress) and tonumber(st.progress) > 0 then
        manager.downloadBytes = math.max(manager.downloadBytes or 0, manager.downloadTotal * tonumber(st.progress))
      end
      return
    end

    local job = manager.downloadHandle
    manager.downloadHandle = nil
    Fetch.release(job)
    if st.status ~= "ok" then
      return setError(st.err or "Asset ZIP download failed.")
    end

    if manager.downloadMode == "portable_native" and manager.nativeFs and manager.portableTempPath then
      local okInfo, info = pcall(manager.nativeFs.statNative, manager.portableTempPath)
      if okInfo and info and info.type == "file" then
        manager.downloadBytes = tonumber(info.size) or manager.downloadBytes
      end
    elseif fs then
      local okInfo, info = pcall(fs.getInfo, manager.tempName, "file")
      if okInfo and info then manager.downloadBytes = tonumber(info.size) or manager.downloadBytes end
    end
    if (manager.downloadBytes or 0) <= 0 then
      return setError("Asset ZIP download finished but no file was written.")
    end
    if manager.downloadTotal > 0 and manager.downloadBytes ~= manager.downloadTotal then
      return setError(string.format("Asset ZIP is incomplete (%d/%d bytes).",
        manager.downloadBytes, manager.downloadTotal))
    end
    beginExtraction()
  end

  function manager:start()
    self.error = nil
    if not cacheAvailable() then
      self.state = "error"
      self.error = "This Gen1Recomp build does not provide mod.cache."
      return false
    end
    if self:beginLegacyMigration() then
      return true
    end
    self.portableMode = portableModeActive()
    local gen3MobileNative = IS_GEN3 and mobilePlatformActive()
    local useNativeHandoff = self.portableMode or gen3MobileNative
    self.downloadMode = useNativeHandoff and "portable_native" or "raw"
    self.rawFs = nil
    self.nativeFs = nil
    self.portableTempPath = nil
    if useNativeHandoff then
      local nativePath, SaveData, pathErr = resolveEngineSaveDirectory()
      if nativePath then
        self.portableTempPath = nativePath
        self.nativeFs = SaveData
        if self.portableMode then
          logInfo("KIM portable asset download: engine temp handoff ready")
        else
          logInfo("KIM FR/LG mobile asset download: engine temp handoff ready")
        end
      elseif self.portableMode then
        self.state = "error"
        self.error = pathErr or "Portable ZIP download path is unavailable on this Gen1Recomp build."
        return false
      else
        -- A few older mobile engine builds may not expose native helpers even
        -- though their persistence filesystem can still see the worker's save
        -- directory. Preserve v7's raw path as a compatibility fallback.
        local fs, fsErr = resolveRawFilesystem()
        if not fs then
          self.state = "error"
          self.error = pathErr or fsErr
            or "FR/LG mobile ZIP installation is unavailable on this Gen1Recomp build."
          return false
        end
        self.downloadMode = "raw"
        self.rawFs = fs
        logInfo("KIM FR/LG mobile asset download: native handoff unavailable; using raw fallback")
      end
    else
      local fs, fsErr = resolveRawFilesystem()
      if not fs then
        self.state = "error"
        self.error = fsErr or "ZIP installation is unavailable on this Gen1Recomp build."
        return false
      end
      self.rawFs = fs
    end
    local okModUpdate, ModUpdate = pcall(require, "src.mods.ModUpdate")
    if not okModUpdate or not ModUpdate or type(ModUpdate.beginFetchReleases) ~= "function" then
      self.state = "error"
      self.error = "Gen1Recomp's release downloader is unavailable."
      return false
    end

    cleanupArchive()
    self.release = nil
    self.downloadTotal = 0
    self.downloadBytes = 0
    self.extractFiles = {}
    self.extractPos = 1
    self.extractedCount = 0
    self.extractedBytes = 0
    self.extractTotalBytes = 0
    self:clearDefer()
    self.releaseHandle = ModUpdate.beginFetchReleases(REPO, nil, { force = true })
    self.state = "checking"
    return true
  end

  function manager:cancel()
    cancelNetworkJob()
    self.releaseHandle = nil
    cleanupArchive()
    self.state = "idle"
    self.error = nil
    self:defer()
  end

  function manager:update()
    if self.state == "checking" then pumpReleaseCheck()
    elseif self.state == "downloading" then pumpDownload()
    elseif self.state == "extracting" then pumpExtraction()
    elseif self.state == "migrating" then pumpLegacyMigration()
    elseif self.state == "deleting" then pumpDeletion()
    end
  end

  local function mb10(bytes)
    local n = (tonumber(bytes) or 0) / 1000000
    if n >= 100 then return tostring(math.floor(n + 0.5)) end
    return string.format("%.1f", n)
  end

  local function clipText(text, maxChars)
    text = tostring(text or "")
    maxChars = maxChars or 18
    if #text <= maxChars then return text end
    return text:sub(1, math.max(1, maxChars - 1)) .. "~"
  end

  if not IS_GEN3 then
    mod.content.screens:register(SCREEN_ID, {
      new = function(game)
        local self = { isOpaque = true, game = game }
        function self:update(dt)
          manager:update()
          local input = game and game.input
          if not input then return end
          if manager.state == "checking" or manager.state == "downloading" then
            if input:wasPressed("b") then manager:cancel(); game.stack:pop() end
            return
          end
          if manager.state == "extracting" or manager.state == "migrating" or manager.state == "deleting" then
            -- Do not interrupt installation/migration/removal midway. Cache work is
            -- incremental and a later run can safely recover from partial progress.
            return
          end
          if manager.state == "confirm_delete" then
            if input:wasPressed("a") then manager:beginDelete(); return end
            if input:wasPressed("b") then manager.state = "done"; return end
            return
          end
          if manager.state == "delete_error" then
            if input:wasPressed("a") then manager:beginDelete(); return end
            if input:wasPressed("b") then game.stack:pop(); return end
            return
          end
          if manager.state == "deleted" then
            if input:wasPressed("a") then manager:start(); return end
            if input:wasPressed("b") then game.stack:pop(); return end
            return
          end
          if manager.state == "error" then
            if input:wasPressed("a") then manager:start(); return end
            if input:wasPressed("b") then manager:defer(); game.stack:pop(); return end
            return
          end
          if manager.state == "done" or manager:isComplete() then
            if input:wasPressed("a") then game.stack:pop(); return end
            if input:wasPressed("b") then manager.state = "confirm_delete"; return end
            return
          end
          if input:wasPressed("a") then manager:start(); return end
          if input:wasPressed("b") then manager:defer(); game.stack:pop(); return end
        end
        function self:draw()
          local Font = mod.ui and mod.ui.Font
          if not Font then return end
          Font.drawBox(0, 0, 20, 18)
          Font.draw("KANTO IN MOTION", 8, 8)
          Font.draw("HD ASSET MANAGER", 8, 24)
          if manager.state == "checking" then
            Font.draw("CHECKING RELEASE...", 8, 52)
            Font.draw("B CANCEL", 8, 120)
          elseif manager.state == "downloading" then
            Font.draw("DOWNLOADING ZIP", 8, 48)
            if manager.downloadTotal > 0 then
              Font.draw(string.format("DATA %s/%s MB", mb10(manager.downloadBytes), mb10(manager.downloadTotal)), 8, 68)
            else
              Font.draw(string.format("DATA %s MB", mb10(manager.downloadBytes)), 8, 68)
            end
            Font.draw("ONE-TIME DOWNLOAD", 8, 92)
            Font.draw("B CANCEL", 8, 120)
          elseif manager.state == "extracting" then
            Font.draw("EXTRACTING...", 8, 48)
            Font.draw(string.format("FILES %d/%d", manager.extractedCount, #manager.extractFiles), 8, 68)
            if manager.extractTotalBytes > 0 then
              Font.draw(string.format("DATA %s/%s MB", mb10(manager.extractedBytes), mb10(manager.extractTotalBytes)), 8, 84)
            end
            Font.draw("PLEASE WAIT", 8, 116)
          elseif manager.state == "migrating" then
            Font.draw("MIGRATING LOCAL ASSETS", 8, 44)
            Font.draw("NO DOWNLOAD REQUIRED", 8, 58)
            Font.draw(string.format("FILES %d/%d", manager.legacyCount, #manager.legacyFiles), 8, 78)
            if manager.legacyTotalBytes > 0 then
              Font.draw(string.format("DATA %s/%s MB", mb10(manager.legacyBytes), mb10(manager.legacyTotalBytes)), 8, 94)
            end
            Font.draw("PLEASE WAIT", 8, 120)
          elseif manager.state == "deleting" then
            Font.draw("REMOVING HD ASSETS", 8, 48)
            Font.draw(string.format("FILES %d/%d", manager.deletedCount, #manager.deleteFiles), 8, 70)
            Font.draw("PLEASE WAIT", 8, 104)
          elseif manager.state == "confirm_delete" then
            Font.draw("REMOVE HD ASSETS?", 8, 48)
            Font.draw("FREES CACHE SPACE", 8, 66)
            Font.draw("CAN DOWNLOAD AGAIN", 8, 82)
            Font.draw("A REMOVE", 8, 108)
            Font.draw("B CANCEL", 88, 108)
          elseif manager.state == "delete_error" then
            Font.draw("REMOVE ERROR", 8, 48)
            local first = tostring(manager.error or "Unknown error"):gsub("\n", " ")
            local line1 = first:sub(1, 20)
            local line2 = first:sub(21, 40)
            local line3 = first:sub(41, 60)
            Font.draw(line1, 8, 64)
            if #line2 > 0 then Font.draw(line2, 8, 78) end
            if #line3 > 0 then Font.draw(line3, 8, 92) end
            Font.draw("A RETRY", 8, 112)
            Font.draw("B CANCEL", 88, 112)
          elseif manager.state == "deleted" then
            Font.draw("ASSETS REMOVED", 8, 52)
            Font.draw("HD CACHE CLEARED", 8, 68)
            Font.draw("RESTART TO APPLY", 8, 84)
            Font.draw("A DOWNLOAD AGAIN", 8, 102)
            Font.draw("B CLOSE", 8, 118)
          elseif manager.state == "error" then
            Font.draw("DOWNLOAD ERROR", 8, 48)
            local first = tostring(manager.error or "Unknown error"):gsub("\n", " ")
            local function chunks(text, width, limit)
              local out = {}
              while #text > 0 and #out < limit do
                if #text <= width then out[#out + 1] = text; break end
                local cut = text:sub(1, width)
                local at = cut:match("^.*()%s+")
                if at and at > 4 then cut = text:sub(1, at - 1); text = text:sub(at + 1)
                else text = text:sub(width + 1) end
                out[#out + 1] = cut
              end
              return out
            end
            for i, line in ipairs(chunks(first, 20, 3)) do Font.draw(line, 8, 60 + (i - 1) * 14) end
            Font.draw("A RETRY", 8, 108)
            Font.draw("B LATER", 88, 108)
          elseif manager.state == "done" or manager:isComplete() then
            Font.draw("ASSETS READY", 8, 52)
            local source = manager.installSource or manager:completionSource()
            if source == "legacy" then
              local count = manager.legacyCount > 0 and manager.legacyCount or LEGACY_EXPECTED_FILES
              Font.draw(string.format("%d FILES MIGRATED", count), 8, 70)
              Font.draw("NO DOWNLOAD NEEDED", 8, 86)
            else
              Font.draw(string.format("%d FILES INSTALLED", manager.extractedCount > 0 and manager.extractedCount or 0), 8, 70)
              Font.draw("TEMP ZIP DELETED", 8, 86)
            end
            Font.draw("A CONTINUE", 8, 104)
            Font.draw("B REMOVE", 88, 104)
          else
            Font.draw("HD POKEMON +", 8, 48)
            Font.draw("BATTLE BACKGROUNDS", 8, 64)
            Font.draw("DOWNLOAD ASSET ZIP", 8, 80)
            Font.draw("A DOWNLOAD", 8, 104)
            Font.draw("B USE VANILLA", 8, 120)
          end
        end
        return self
      end,
    })
  end


  -- FireRed/LeafGreen use Game3's separate 240x160 singleton UI stack. The
  -- normal mod.content.screens registry is intentionally unavailable there,
  -- so give the same asset manager a small native Game3 host instead of
  -- silently failing installation before gen3_frlg.lua can start.
  local gen3Stack, gen3Host
  if IS_GEN3 then
    local okStack, Stack = pcall(require, "src.ui.game3.stack")
    local okWindow, Window = pcall(require, "src.ui.game3.window")
    if okStack and type(Stack) == "table" and okWindow and type(Window) == "table" then
      gen3Stack = Stack
      local function closeGen3()
        Stack.pop(SCREEN_ID)
      end
      local function pressed(input, key)
        return input and type(input.wasPressed) == "function" and input:wasPressed(key)
      end
      local function handleInput(input)
        if manager.state == "checking" or manager.state == "downloading" then
          if pressed(input, "b") then manager:cancel(); closeGen3() end
          return
        end
        if manager.state == "extracting" or manager.state == "migrating"
            or manager.state == "deleting" then
          return
        end
        if manager.state == "confirm_delete" then
          if pressed(input, "a") then manager:beginDelete(); return end
          if pressed(input, "b") then manager.state = "done"; return end
          return
        end
        if manager.state == "delete_error" then
          if pressed(input, "a") then manager:beginDelete(); return end
          if pressed(input, "b") then closeGen3(); return end
          return
        end
        if manager.state == "deleted" then
          if pressed(input, "a") then manager:start(); return end
          if pressed(input, "b") then closeGen3(); return end
          return
        end
        if manager.state == "error" then
          if pressed(input, "a") then manager:start(); return end
          if pressed(input, "b") then manager:defer(); closeGen3(); return end
          return
        end
        if manager.state == "done" or manager:isComplete() then
          -- Game3's asset screen is an explicit maintenance menu. Make the
          -- destructive action match the on-screen prompt: A opens the
          -- confirmation, while B simply closes/returns to the Start menu.
          if pressed(input, "a") then manager.state = "confirm_delete"; return end
          if pressed(input, "b") then closeGen3(); return end
          return
        end
        if pressed(input, "a") then manager:start(); return end
        if pressed(input, "b") then manager:defer(); closeGen3(); return end
      end

      local function splitError(text, width, limit)
        text = tostring(text or "Unknown error"):gsub("\n", " ")
        local out = {}
        while #text > 0 and #out < (limit or 3) do
          if #text <= width then out[#out + 1] = text; break end
          local cut = text:sub(1, width)
          local at = cut:match("^.*()%s+")
          if at and at > 4 then
            out[#out + 1] = text:sub(1, at - 1)
            text = text:sub(at + 1)
          else
            out[#out + 1] = cut
            text = text:sub(width + 1)
          end
        end
        return out
      end

      local function line(text, y)
        Window.printPx(tostring(text or ""), 16, y, { maxWidth = 208 })
      end

      gen3Host = {}
      function gen3Host.update(_dt)
        manager:update()
      end
      function gen3Host.handleInput(input)
        handleInput(input)
      end
      function gen3Host.draw()
        local G = love and love.graphics
        if not G then return end
        G.setShader()
        G.setColor(1, 1, 1, 1)
        G.rectangle("fill", 0, 0, 240, 160)
        Window.stdFrame(Window.template(1, 1, 28, 18))
        line("KANTO IN MOTION", 14)
        line("HD ASSET MANAGER", 30)

        if manager.state == "checking" then
          line("CHECKING RELEASE...", 56)
          line("B CANCEL", 128)
        elseif manager.state == "downloading" then
          line("DOWNLOADING ZIP", 52)
          if manager.downloadTotal > 0 then
            line(string.format("DATA %s/%s MB", mb10(manager.downloadBytes), mb10(manager.downloadTotal)), 72)
          else
            line(string.format("DATA %s MB", mb10(manager.downloadBytes)), 72)
          end
          line("ONE-TIME DOWNLOAD", 92)
          line("B CANCEL", 128)
        elseif manager.state == "extracting" then
          line("EXTRACTING...", 52)
          line(string.format("FILES %d/%d", manager.extractedCount, #manager.extractFiles), 72)
          if manager.extractTotalBytes > 0 then
            line(string.format("DATA %s/%s MB", mb10(manager.extractedBytes), mb10(manager.extractTotalBytes)), 92)
          end
          line("PLEASE WAIT", 128)
        elseif manager.state == "migrating" then
          line("MIGRATING LOCAL ASSETS", 50)
          line(string.format("FILES %d/%d", manager.legacyCount, #manager.legacyFiles), 72)
          line("NO DOWNLOAD REQUIRED", 92)
          line("PLEASE WAIT", 128)
        elseif manager.state == "deleting" then
          line("REMOVING HD ASSETS", 54)
          line(string.format("FILES %d/%d", manager.deletedCount, #manager.deleteFiles), 76)
          line("PLEASE WAIT", 112)
        elseif manager.state == "confirm_delete" then
          line("REMOVE HD ASSETS?", 52)
          line("FREES CACHE SPACE", 72)
          line("CAN DOWNLOAD AGAIN", 92)
          line("A REMOVE   B CANCEL", 120)
        elseif manager.state == "delete_error" then
          line("REMOVE ERROR", 48)
          for i, value in ipairs(splitError(manager.error, 26, 3)) do line(value, 66 + (i - 1) * 16) end
          line("A RETRY   B CANCEL", 124)
        elseif manager.state == "deleted" then
          line("ASSETS REMOVED", 52)
          line("HD CACHE CLEARED", 72)
          line("RESTART TO APPLY", 92)
          line("A DOWNLOAD AGAIN", 112)
          line("B CLOSE", 130)
        elseif manager.state == "error" then
          line("DOWNLOAD ERROR", 46)
          for i, value in ipairs(splitError(manager.error, 26, 3)) do line(value, 64 + (i - 1) * 16) end
          line("A RETRY   B LATER", 124)
        elseif manager.state == "done" or manager:isComplete() then
          line("ASSETS READY", 52)
          local source = manager.installSource or manager:completionSource()
          if source == "legacy" then
            local count = manager.legacyCount > 0 and manager.legacyCount or LEGACY_EXPECTED_FILES
            line(string.format("%d FILES MIGRATED", count), 72)
          else
            line(string.format("%d FILES INSTALLED", manager.extractedCount > 0 and manager.extractedCount or 0), 72)
          end
          line("A REMOVE   B CLOSE", 112)
        else
          line("HD POKEMON +", 52)
          line("BATTLE BACKGROUNDS", 72)
          line("DOWNLOAD ASSET ZIP", 92)
          line("A DOWNLOAD", 112)
          line("B USE VANILLA", 130)
        end
        G.setColor(1, 1, 1, 1)
      end
    else
      logError("Game3 asset-manager UI unavailable")
    end
  end


  local function openManager(game)
    game = game or manager.game
    if not game or manager.opening then return end
    manager.game = game
    if not manager:isComplete() and manager.state == "idle" then
      manager:beginLegacyMigration()
    end
    manager.opening = true
    local ok, err
    if IS_GEN3 then
      ok, err = pcall(function()
        if not (gen3Stack and gen3Host) then
          error("Game3 asset-manager UI is unavailable")
        end
        gen3Stack.push(SCREEN_ID, gen3Host, { hideBelow = true, fullscreen = true })
      end)
    else
      ok, err = pcall(function() mod.ui.push(game, SCREEN_ID) end)
    end
    manager.opening = false
    if not ok then logError("could not open KIM asset manager: %s", tostring(err)) end
  end
  manager.open = openManager

  local legacyAtBoot = (not manager:isComplete()) and manager:hasLegacyAssets()
  manager.autoPromptArmed = not manager:isComplete() and (legacyAtBoot or not manager:isDeferred())
  mod.events:on("game.ready", function(ev)
    manager.game = ev and ev.game or nil
  end)

  if IS_GEN3 then
    -- Game3 does not expose mod.content.screens. Expose KIM ASSETS in the
    -- native Start menu only while the shared pack is missing/incomplete.
    -- Once the cache validates as complete, keep the normal Start menu clean.
    local function addGen3AssetItem(nextFn, game, items)
      local out = nextFn(game, items)
      if type(out) ~= "table" or manager:isComplete() then return out end
      for _, row in ipairs(out) do
        if type(row) == "table" and row.id == SCREEN_ID then return out end
      end
      local copy = {}
      local inserted = false
      for _, row in ipairs(out) do
        if not inserted and type(row) == "table"
            and (row.id == "option" or row.id == "exit") then
          copy[#copy + 1] = { id = SCREEN_ID, label = "KIM ASSETS" }
          inserted = true
        end
        copy[#copy + 1] = row
      end
      if not inserted then copy[#copy + 1] = { id = SCREEN_ID, label = "KIM ASSETS" } end
      return copy
    end
    mod.hooks:wrap("ui.start_menu.items", addGen3AssetItem)

    local okStart, StartMenu = pcall(require, "src.ui.game3.start_menu")
    if okStart and type(StartMenu) == "table" and type(StartMenu.confirm) == "function" then
      if not StartMenu.__kantoInMotionAssetManagerBridge then
        StartMenu.__kantoInMotionAssetManagerBridge = {
          confirm = StartMenu.confirm,
          open = nil,
        }
        StartMenu.confirm = function(...)
          local bridge = StartMenu.__kantoInMotionAssetManagerBridge
          local entry = StartMenu.ENTRIES and StartMenu.ENTRIES[StartMenu.cursor]
          if entry and entry.id == SCREEN_ID and type(bridge.open) == "function" then
            return bridge.open()
          end
          return bridge.confirm(...)
        end
      end
      StartMenu.__kantoInMotionAssetManagerBridge.open = function()
        local game = StartMenu._game
          or (StartMenu._session and StartMenu._session.game)
          or manager.game
        openManager(game)
      end
    else
      logError("could not install FR/LG KIM ASSETS Start-menu bridge")
    end
  else
    mod.events:on("screen.pushed", function()
      if not manager.autoPromptArmed or not manager.game or manager.opening then return end
      manager.autoPromptArmed = false
      openManager(manager.game)
    end)

    local function addAssetItem(nextFn, game, items)
      local out = nextFn(game, items)
      if type(out) ~= "table" or manager:isComplete() then return out end
      return mod.ui.insertBefore(out, "OPTION", {
        label = "KIM ASSETS",
        onSelect = function() openManager(game) end,
      })
    end
    mod.hooks:wrap("ui.title_menu.items", addAssetItem)
    mod.hooks:wrap("ui.start_menu.items", addAssetItem)
  end

  return manager
end
