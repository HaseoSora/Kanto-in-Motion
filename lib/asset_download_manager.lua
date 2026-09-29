-- Kanto in Motion HD Asset Manager (v45 ZIP installer + legacy migration)
-- Downloads the complete asset pack as one temporary GitHub Release ZIP,
-- then parses/extracts the ZIP directly instead of mounting it through PhysFS.
-- This avoids the mod-sandbox mount restriction and works with normal ZIP
-- STORE (method 0) and DEFLATE (method 8) entries.
return function(mod)
  local SCREEN_ID = "animated_menu_pokemon:asset_manager"
  local REPO = "HaseoSora/Kanto-in-Motion-Assets"
  local ASSET_VERSION = "1.0.0"
  local CACHE_ROOT = "kim_assets/files/"
  local COMPLETE_KEY = "kim_assets/complete.txt"
  local PACK_META_KEY = "kim_assets/asset-pack.json"
  local DEFER_KEY = "kim_assets/deferred.txt"
  local COMPLETE_VALUE = "zip:" .. ASSET_VERSION
  local LEGACY_COMPLETE_VALUE = "legacy:" .. ASSET_VERSION
  local LEGACY_EXPECTED_FILES = 768
  local LEGACY_ROOTS = {
    "assets/battle/hd-pokemon",
    "assets/battle/backgrounds/hd",
  }
  local TEMP_NAME = "kim_assets_v" .. ASSET_VERSION:gsub("[^%w]", "_") .. ".tmp.zip"
  local MOUNT_POINT = "kim_asset_pack_mount"
  local EXTRACT_BUDGET = 0.010 -- seconds of extraction work per update tick
  local MAX_CACHE_FILE = 64 * 1024 * 1024
  local DOWNLOAD_MAX_SECONDS = 15 * 60 -- large GitHub release; Fetch default (90s) is too short

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

  -- Fetch.download writes a save-directory-relative file. On normal desktop
  -- and mobile installs SaveData.persistenceFs() is the engine-owned LOVE
  -- filesystem, which gives us streaming File handles. Portable mode uses a
  -- small io-backed save facade with no random-access File API; keep that case
  -- explicit instead of accidentally reading a different path.
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
      return nil, "ZIP install needs Gen1Recomp's random-access save filesystem (portable mode is not supported yet)."
    end
    return fs
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
    if not (mod.cache and type(mod.cache.delete) == "function") then return end
    pcall(function() mod.cache:delete(key) end)
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
    if self.state == "error" then return "ERROR" end
    return "DOWNLOAD"
  end

  local function finishLegacyMigration()
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

  local function openZipReader()
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

  local function beginDownloadForRelease(release)
    if type(release) ~= "table" or not release.zip or not release.zip.url then
      return setError("GitHub release has no asset ZIP.")
    end
    local okFetch, Fetch = pcall(require, "src.net.Fetch")
    if not okFetch or not Fetch or type(Fetch.download) ~= "function" then
      return setError("Gen1Recomp streaming downloader is unavailable.")
    end
    removeTemp()
    manager.release = release
    manager.downloadTotal = tonumber(release.zip.size) or 0
    manager.downloadBytes = 0
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

  local function pumpDownload()
    if manager.state ~= "downloading" then return end
    local okFetch, Fetch = pcall(require, "src.net.Fetch")
    if not okFetch or not Fetch then return setError("Gen1Recomp streaming downloader is unavailable.") end

    local fs = manager.rawFs
    if fs then
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

    if fs then
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
    local fs, fsErr = resolveRawFilesystem()
    if not fs then
      self.state = "error"
      self.error = fsErr or "ZIP installation is unavailable on this Gen1Recomp build."
      return false
    end
    self.rawFs = fs
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
        if manager.state == "extracting" or manager.state == "migrating" then
          -- Do not interrupt installation/migration midway. Cache writes are
          -- incremental and a later run can safely skip files already copied.
          return
        end
        if manager.state == "error" then
          if input:wasPressed("a") then manager:start(); return end
          if input:wasPressed("b") then manager:defer(); game.stack:pop(); return end
          return
        end
        if manager.state == "done" or manager:isComplete() then
          if input:wasPressed("a") or input:wasPressed("b") then game.stack:pop() end
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
          Font.draw("A CONTINUE", 8, 112)
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

  local function openManager(game)
    if not game or manager.opening then return end
    if not manager:isComplete() and manager.state == "idle" then
      manager:beginLegacyMigration()
    end
    manager.opening = true
    local ok, err = pcall(function() mod.ui.push(game, SCREEN_ID) end)
    manager.opening = false
    if not ok then logError("could not open KIM asset manager: %s", tostring(err)) end
  end
  manager.open = openManager

  local legacyAtBoot = (not manager:isComplete()) and manager:hasLegacyAssets()
  manager.autoPromptArmed = not manager:isComplete() and (legacyAtBoot or not manager:isDeferred())
  mod.events:on("game.ready", function(ev)
    manager.game = ev and ev.game or nil
  end)
  mod.events:on("screen.pushed", function()
    if not manager.autoPromptArmed or not manager.game or manager.opening then return end
    manager.autoPromptArmed = false
    openManager(manager.game)
  end)

  local function addAssetItem(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" or manager:isComplete() then return out end
    return mod.ui.insertBefore(out, "OPTION", {
      label = "KIM ASSETS",
      onSelect = function() openManager(game) end,
    })
  end
  mod.hooks:wrap("ui.title_menu.items", addAssetItem)
  mod.hooks:wrap("ui.start_menu.items", addAssetItem)

  return manager
end
