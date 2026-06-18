-- tuff-nitro: persistent vehicle upgrade database (JSON or MySQL)
-- Structure: [plate] = { nitrous = {...}, exhaust = {...}, antilag2step = {...}, ... }

Database = Database or {}

local _cache = {}              -- in-memory map of plate => data table
local _autoSaveThread = nil    -- handle for autosave loop
local _resourceName = GetCurrentResourceName()

-- Helper: lower save type
local function saveType()
	local t = (Config and Config.Database and Config.Database.SaveType) or 'json'
	return string.lower(t)
end

function Database.UseMySQL()
	return saveType() == 'mysql'
end

-- OxMySQL accessor (safe)
local function ox()
	local ok, ref = pcall(function() return exports.oxmysql end)
	if ok then return ref end
	return nil
end

local function debugDB(...)
	if Shared and Shared.Debug and Shared.DebugFiles and Shared.DebugFiles['database'] then
		print('[tuff-nitro][db]', ...)
	end
end

-- Ensure schema exists (MySQL only)
local function ensureSchema()
	if not Database.UseMySQL() then return end
	local o = ox()
	if not o then
		debugDB('mysql selected but oxmysql export not found; will fallback to JSON operations')
		return
	end
	local sql = [[
		CREATE TABLE IF NOT EXISTS `tuff_nitro_installs` (
			`plate`      VARCHAR(64) NOT NULL,
			`data`       LONGTEXT    NOT NULL,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (`plate`)
		) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
	]]
	o:execute(sql, {})
	debugDB('Ensured table tuff_nitro_installs')
end

-- Load all existing installs into memory
function Database.LoadAll()
	if Database.UseMySQL() then
		local o = ox()
		if not o then
			debugDB('oxmysql missing; returning empty cache')
			return {}
		end
		local rows = o:fetchSync('SELECT `plate`, `data` FROM `tuff_nitro_installs`', {}) or {}
		local out = {}
		for _, row in ipairs(rows) do
			if row.plate and row.data then
				local ok, decoded = pcall(json.decode, row.data)
				if ok and type(decoded) == 'table' then
					out[row.plate] = decoded
				end
			end
		end
		debugDB('Loaded installs from DB count=' .. tostring(#rows))
		return out
	else
		local fileName = (Config and Config.Database and Config.Database.JSON and Config.Database.JSON.FileName) or 'datas.json'
		local raw = LoadResourceFile(_resourceName, fileName)
		if not raw or #raw == 0 then
			debugDB('No JSON file found, starting fresh: ' .. fileName)
			return {}
		end
		local ok, data = pcall(json.decode, raw)
		if ok and type(data) == 'table' then
			local c = 0; for _ in pairs(data) do c = c + 1 end
			debugDB('Loaded installs from JSON count=' .. tostring(c))
			return data
		end
		debugDB('Failed to decode JSON, starting empty cache')
		return {}
	end
end

-- Save full dataset (supports batching for large servers)
function Database.SaveFull(allData, opts)
	allData = allData or _cache
	if Database.UseMySQL() then
		local o = ox()
		if not o then return end
		local plates = {}
		for plate, _ in pairs(allData) do plates[#plates + 1] = plate end
		table.sort(plates)
		local optimized = opts and opts.auto and (Config and Config.Database and Config.Database.AutoSave and Config.Database.AutoSave.OptimizeFullSaves)
		if optimized then
			local batchSize = 200
			local pauseMs = 500
			for i = 1, #plates, batchSize do
				local jMax = math.min(i + batchSize - 1, #plates)
				for j = i, jMax do
					local plate = plates[j]
					local payload = json.encode(allData[plate] or {})
					o:execute('INSERT INTO `tuff_nitro_installs` (`plate`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data`=VALUES(`data`), `updated_at`=CURRENT_TIMESTAMP', { plate, payload })
				end
				debugDB(('AutoSave batch %d/%d'):format(jMax, #plates))
				if jMax < #plates then Wait(pauseMs) end
			end
			debugDB('AutoSave optimized snapshot complete plates=' .. tostring(#plates))
		else
			local count = 0
			for _, plate in ipairs(plates) do
				local payload = json.encode(allData[plate] or {})
				o:execute('INSERT INTO `tuff_nitro_installs` (`plate`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data`=VALUES(`data`), `updated_at`=CURRENT_TIMESTAMP', { plate, payload })
				count = count + 1
			end
			debugDB('Full save complete rows=' .. tostring(count))
		end
	else
		if Config and Config.DisableSave then return end
		local fileName = (Config and Config.Database and Config.Database.JSON and Config.Database.JSON.FileName) or 'datas.json'
	SaveResourceFile(_resourceName, fileName, json.encode(allData, { indent = true }), -1)
	local c = 0; for _ in pairs(allData) do c = c + 1 end
	debugDB('Saved JSON snapshot file=' .. fileName .. ' plates=' .. tostring(c))
	end
end

-- Upsert single plate (MySQL only, JSON updated in memory & saved on next full snapshot)
function Database.SaveVehicle(plate, data)
	if not plate then return end
	_cache[plate] = data or {}
	if Database.UseMySQL() then
		local o = ox(); if not o then return end
		local payload = json.encode(_cache[plate] or {})
		o:execute('INSERT INTO `tuff_nitro_installs` (`plate`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data`=VALUES(`data`), `updated_at`=CURRENT_TIMESTAMP', { plate, payload })
		debugDB('Upsert plate=' .. plate .. ' size=' .. tostring(#payload))
	end
end

function Database.DeleteVehicle(plate)
	if not plate then return end
	_cache[plate] = nil
	if Database.UseMySQL() then
		local o = ox(); if not o then return end
		o:execute('DELETE FROM `tuff_nitro_installs` WHERE `plate`=?', { plate })
		debugDB('Deleted plate=' .. plate)
	end
end

function Database.GetVehicleData(plate)
	return _cache[plate] or nil
end

-- Set and optionally persist (MySQL immediate if config SaveOnVehicleEdits true)
function Database.SetVehicleData(plate, data, opts)
	if not plate then return end
	_cache[plate] = data or {}
	if Database.UseMySQL() and Config and Config.Database and Config.Database.MySQL and Config.Database.MySQL.SaveOnVehicleEdits then
		Database.SaveVehicle(plate, data)
	end
end

function Database.GetInitialData()
	return _cache
end

local function startAutoSave()
	if not (Config and Config.Database and Config.Database.AutoSave and Config.Database.AutoSave.Enabled) then return end
	if _autoSaveThread then return end
	local intervalMin = Config.Database.AutoSave.Interval or 60
	_autoSaveThread = CreateThread(function()
		debugDB('AutoSave loop started interval=' .. tostring(intervalMin) .. 'm')
		while true do
			Wait(intervalMin * 60 * 1000)
			-- Skip if saving disabled globally
			if Config.DisableSave then
				debugDB('AutoSave skipped: saving disabled')
			else
				Database.SaveFull(_cache, { auto = true })
			end
		end
	end)
end

function Database.Init()
	if Config and Config.DisableSave then
		debugDB('Saving disabled by config; Init loads empty cache')
		_cache = {}
		return
	end
	ensureSchema()
	_cache = Database.LoadAll() or {}
	startAutoSave()
end

-- Resource stop hook for full snapshot (if enabled)
AddEventHandler('onResourceStop', function(res)
	if res ~= _resourceName then return end
	if Config and Config.Database and Config.Database.MySQL and Config.Database.MySQL.FullSaveOnStop then
		debugDB('Resource stopping: performing full save (mysql flag)')
		Database.SaveFull(_cache, { auto = false })
	elseif not Database.UseMySQL() and not Config.DisableSave then
		-- JSON always writes current snapshot to ensure persistence
		debugDB('Resource stopping: writing JSON snapshot')
		Database.SaveFull(_cache, { auto = false })
	else
		debugDB('Resource stopping: config bypassed full save')
	end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
	if Config and Config.Database and Config.Database.MySQL and Config.Database.MySQL.FullSaveOnStop then
		debugDB('Resource stopping: performing full save (mysql flag)')
		Database.SaveFull(_cache, { auto = false })
	elseif not Database.UseMySQL() and not Config.DisableSave then
		-- JSON always writes current snapshot to ensure persistence
		debugDB('Resource stopping: writing JSON snapshot')
		Database.SaveFull(_cache, { auto = false })
	else
		debugDB('Resource stopping: config bypassed full save')
	end
end)

