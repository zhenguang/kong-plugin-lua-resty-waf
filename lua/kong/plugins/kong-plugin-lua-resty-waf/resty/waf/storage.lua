local _M = {}

local base   = require "kong.plugins.kong-plugin-lua-resty-waf.resty.waf.base"
local cjson  = require "cjson"
local logger = require "kong.plugins.kong-plugin-lua-resty-waf.resty.waf.log"
local util   = require "kong.plugins.kong-plugin-lua-resty-waf.resty.waf.util"

_M.version = base.version

local string_upper = string.upper

local _valid_backends = { dict = true, memcached = true, redis = true }

function _M.initialize(waf, storage, col)
	local backend = waf._storage_backend
	if not util.table_has_key(backend, _valid_backends) then
		logger.fatal_fail(backend .. " is not a valid persistent storage backend")
	end

	local backend_m = require("kong.plugins.kong-plugin-lua-resty-waf.resty.waf.storage." .. backend)

	if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Initializing storage type " .. backend) end

	backend_m.initialize(waf, storage, col)
end

function _M.set_var(waf, ctx, element, value)
	local col = ctx.col_lookup[string_upper(element.col)]
	if not col then
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', element.col .. " not initialized") end
		return
	end

	local key     = element.key
	local inc     = element.inc
	local storage = ctx.storage

	if inc then
		local existing = storage[col][key]

		if existing and type(existing) ~= "number" then
			logger.fatal_fail("Cannot increment a value that was not previously a number")
		elseif not existing then
			if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Incrementing a non-existing value") end
			existing = 0
		end

		if type(value) == "number" then
			value = value + existing
		else
			if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Failed to increment a non-number, falling back to existing value") end
			value = existing
		end
	end

	if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Setting " .. col .. ":" .. key .. " to " .. value) end

	-- save data to in-memory table
	-- data not in the TX col will be persisted at the end of the phase
	storage[col][key]         = value
	storage[col]["__altered"] = true

	-- track which keys to write to redis
	if waf._storage_backend == 'redis' then
		waf._storage_redis_setkey[key] = value
		waf._storage_redis_setkey_t    = true
	end
end

function _M.expire_var(waf, ctx, element, value)
	local col = ctx.col_lookup[string_upper(element.col)]
	if not col then
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', element.col .. " not initialized") end
		return
	end

	local key     = element.key
	local storage = ctx.storage
	local expire  = ngx.now() + value

	if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Expiring " .. element.col .. ":" .. element.key .. " in " .. value) end

	storage[col]["__expire_" .. key] = expire
	storage[col]["__altered"]        = true

	-- track which keys to write to redis
	if waf._storage_backend == 'redis' then
		waf._storage_redis_setkey['__expire_' .. key] = expire
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', cjson.encode(waf._storage_redis_setkey)) end
	end
end

function _M.delete_var(waf, ctx, element)
	local col = ctx.col_lookup[string_upper(element.col)]
	if not col then
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', element.col .. " not initialized") end
		return
	end

	local key     = element.key
	local storage = ctx.storage

	if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Deleting " .. col .. ":" .. key) end

	if storage[col][key] then
		storage[col][key]         = nil
		storage[col]["__altered"] = true

		-- redis cant expire specific keys in a hash so we track them for hdel when persisting
		if waf._storage_backend == 'redis' then
			waf._storage_redis_delkey_n = waf._storage_redis_delkey_n + 1
			waf._storage_redis_delkey[waf._storage_redis_delkey_n] = key
		end
	else
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', key .. " was not found in " .. col) end
	end
end

function _M.persist(waf, storage)
	local backend   = waf._storage_backend
	if not util.table_has_key(backend, _valid_backends) then
		logger.fatal_fail(backend .. " is not a valid persistent storage backend")
	end

	local backend_m = require("kong.plugins.kong-plugin-lua-resty-waf.resty.waf.storage." .. backend)

	if not util.table_has_key(backend, _valid_backends) then
		logger.fatal_fail(backend .. " is not a valid persistent storage backend")
	end

	if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', 'Persisting storage type ' .. backend) end

	for col in pairs(storage) do
		if col ~= 'TX' then
			if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', 'Examining ' .. col) end

			if storage[col]["__altered"] then
				storage[col]["__altered"] = nil -- dont need to persist this flag
				backend_m.persist(waf, col, storage[col])
			else
				if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Not persisting a collection that wasn't altered") end
			end
		end
	end
end

_M.col_prefix = 'lua_resty_waf_'

return _M
