-- tuff-nitro: Discord webhook routing for server owners
-- Loaded before server/main.lua (see fxmanifest.lua)

ServerWebhook = ServerWebhook or {}

local function whDebug(...)
	if Shared and Shared.Debug and Shared.DebugFiles and (Shared.DebugFiles['serverMain'] or Shared.DebugFiles['main']) then
		print('[tuff-nitro][webhook]', ...)
	end
end

-- Configuration lives here by request (do not require edits to shared/main.lua)
-- IMPORTANT: Each action has its own URL (no single URL for all actions).
ServerWebhook.Config = ServerWebhook.Config or {
	Enabled = false,

	-- Optional webhook message author
	Username = 'tuff-nitro',
	AvatarUrl = nil,

	-- Optional content prefix (e.g. @here / @role). Leave nil/false to disable.
	Content = nil,

	-- Per-action routing (set URL per process)
	Routes = {
		nitrous_installed = {
			Enabled = true,
			Url = '',
		},
		nitrous_removed = {
			Enabled = true,
			Url = '',
		},
		nitrous_edited = {
			Enabled = true,
			Url = '',
		},
	},

	-- Flood protection (per-plate+action)
	RateLimitMs = 1500,

	-- Embed cosmetics (Discord will ignore invalid values)
	Embed = {
		FooterText = 'tuff-nitro',
		FooterIconUrl = nil,
	},
}

local _lastSend = {} -- [action:plate] = lastGameTimer

local function _safeString(v)
	if v == nil then return nil end
	if type(v) == 'string' then return v end
	return tostring(v)
end

local function _getIdentifiers(src)
	local out = {}
	if not src or src == 0 then return out end
	local ids = GetPlayerIdentifiers(src)
	for _, id in ipairs(ids or {}) do
		local t, val = id:match('^(%w+):(.+)$')
		if t and val then out[t] = val end
	end
	out.name = GetPlayerName(src)
	return out
end

local function _iso8601()
	-- UTC ISO-8601 timestamp
	return os.date('!%Y-%m-%dT%H:%M:%SZ')
end

local function _deepCopy(tbl, seen)
	if type(tbl) ~= 'table' then return tbl end
	seen = seen or {}
	if seen[tbl] then return seen[tbl] end
	local copy = {}
	seen[tbl] = copy
	for k, v in pairs(tbl) do
		copy[_deepCopy(k, seen)] = _deepCopy(v, seen)
	end
	return copy
end

local function _jsonTrunc(value, maxLen)
	maxLen = maxLen or 900
	if value == nil then return 'null' end
	local ok, encoded = pcall(json.encode, value)
	if not ok then
		return _safeString(value) or 'unserializable'
	end
	if #encoded > maxLen then
		return encoded:sub(1, maxLen) .. '…'
	end
	return encoded
end

local function _actionColor(action)
	-- Discord embed integer colors
	if action == 'nitrous_installed' then return 5763719 end -- green-ish
	if action == 'nitrous_removed' then return 15548997 end -- red-ish
	return 16763904                                       -- amber
end

function ServerWebhook.GetRoute(action)
	local cfg = ServerWebhook.Config
	if not cfg or cfg.Enabled ~= true then return nil end
	local route = cfg.Routes and cfg.Routes[action]
	if not route or route.Enabled ~= true then return nil end
	if type(route.Url) ~= 'string' or route.Url == '' then return nil end
	return route
end

local function _rateLimited(action, plate)
	local cfg = ServerWebhook.Config
	local key = tostring(action) .. ':' .. tostring(plate or 'unknown')
	local now = GetGameTimer()
	local last = _lastSend[key] or 0
	if cfg and cfg.RateLimitMs and (now - last) < cfg.RateLimitMs then
		return true
	end
	_lastSend[key] = now
	return false
end

function ServerWebhook.Send(action, context)
	local route = ServerWebhook.GetRoute(action)
	if not route then return false, 'route_disabled_or_missing_url' end

	context = context or {}
	local plate = context.plate or context.Plate or 'unknown'
	if _rateLimited(action, plate) then
		return false, 'rate_limited'
	end

	local cfg = ServerWebhook.Config
	local src = context.source
	local identifiers = _getIdentifiers(src)

	local fields = {
		{ name = 'Action', value = ('`%s`'):format(action),          inline = true },
		{ name = 'Plate',  value = ('`%s`'):format(tostring(plate)), inline = true },
	}

	if context.vehicleModel then
		table.insert(fields,
			{ name = 'Vehicle Model', value = ('`%s`'):format(tostring(context.vehicleModel)), inline = true })
	end
	if context.netId then
		table.insert(fields, { name = 'Net ID', value = ('`%s`'):format(tostring(context.netId)), inline = true })
	end
	if context.locationIndex then
		table.insert(fields,
			{ name = 'Location', value = ('`%s`'):format(tostring(context.locationIndex)), inline = true })
	end

	if src and src ~= 0 then
		table.insert(fields,
			{ name = 'Player', value = ('`%s` (%s)'):format(identifiers.name or 'unknown', tostring(src)), inline = false })
		if Framework and Framework.GetPlayerInGameName then
			local firstname, lastname = Framework.GetPlayerInGameName(src)
			if firstname and lastname then
				table.insert(fields,
					{ name = 'In-Game Name', value = ('`%s %s`'):format(tostring(firstname), tostring(lastname)), inline = true })
			end
		end
		if Framework and Framework.GetPlayerIdentifier then
			table.insert(fields,
				{ name = 'Framework ID', value = ('`%s`'):format(tostring(Framework.GetPlayerIdentifier(src) or 'unknown')), inline = true })
		end
		if Framework and Framework.GetPlayerJob then
			local job, grade = Framework.GetPlayerJob(src)
			table.insert(fields,
				{ name = 'Job', value = ('`%s` (grade %s)'):format(tostring(job or 'unknown'), tostring(grade or 0)), inline = true })
		end
		if identifiers.license then
			table.insert(fields,
				{ name = 'License', value = ('`%s`'):format(tostring(identifiers.license)), inline = false })
		end
		if identifiers.discord then
			table.insert(fields,
				{ name = 'Discord', value = ('`%s`'):format(tostring(identifiers.discord)), inline = true })
		end
		if identifiers.steam then
			table.insert(fields, { name = 'Steam', value = ('`%s`'):format(tostring(identifiers.steam)), inline = true })
		end
	end

	-- Optional details/diff
	if context.summary then
		table.insert(fields, { name = 'Summary', value = _safeString(context.summary) or 'n/a', inline = false })
	end
	if context.before ~= nil then
		table.insert(fields,
			{ name = 'Before', value = ('```json\n%s\n```'):format(_jsonTrunc(context.before, 900)), inline = false })
	end
	if context.after ~= nil then
		table.insert(fields,
			{ name = 'After', value = ('```json\n%s\n```'):format(_jsonTrunc(context.after, 900)), inline = false })
	end

	local embed = {
		title = context.title or 'Nitrous Update',
		color = _actionColor(action),
		timestamp = _iso8601(),
		fields = fields,
		footer = {
			text = (cfg.Embed and cfg.Embed.FooterText) or 'tuff-nitro',
			icon_url = cfg.Embed and cfg.Embed.FooterIconUrl or nil,
		},
	}

	local payload = {
		username = cfg.Username,
		avatar_url = cfg.AvatarUrl,
		content = cfg.Content,
		embeds = { embed },
	}

	PerformHttpRequest(route.Url, function(code, _body, _headers)
		if code and code >= 200 and code < 300 then
			whDebug(('sent %s webhook for plate=%s'):format(action, tostring(plate)))
		else
			whDebug(('FAILED webhook action=%s plate=%s status=%s'):format(action, tostring(plate), tostring(code)))
		end
	end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })

	return true
end

-- Helpers to classify nitrous actions based on before/after state
function ServerWebhook.ClassifyNitrousChange(beforeState, afterState)
	local beforeId = type(beforeState) == 'table' and beforeState.id or nil
	local afterId = type(afterState) == 'table' and afterState.id or nil

	if beforeId == nil and afterId ~= nil then
		return 'nitrous_installed'
	end
	if beforeId ~= nil and afterId == nil then
		return 'nitrous_removed'
	end
	return 'nitrous_edited'
end

function ServerWebhook.DeepCopy(tbl)
	return _deepCopy(tbl)
end
