local _M = {}

local base    = require "kong.plugins.kong-plugin-lua-resty-waf.resty.waf.base"
local logger  = require "kong.plugins.kong-plugin-lua-resty-waf.resty.waf.log"
local storage = require "kong.plugins.kong-plugin-lua-resty-waf.resty.waf.storage"
local util    = require "kong.plugins.kong-plugin-lua-resty-waf.resty.waf.util"

_M.version = base.version

_M.alter_actions = {
	DENY   = true,
	DROP   = true,
}

_M.disruptive_lookup = {
	ACCEPT = function(waf, ctx)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Rule action was ACCEPT, so ending this phase with ngx.OK") end
		if waf._mode == "ACTIVE" then
			ctx.disruptive_action = "ACCEPT"
			ctx.disruptive = "true"
		end
	end,
	CHAIN = function(waf, ctx)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Chaining (pre-processed)") end
	end,
	DENY = function(waf, ctx)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Rule action was DENY, so telling nginx to quit") end
		if waf._mode == "ACTIVE" then
			-- ngx.exit(ctx.rule_status or waf._deny_status)
			ctx.disruptive_action = "DENY"
			ctx.disruptive = "true"
		end
	end,
	DROP = function(waf, ctx)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Rule action was DROP, ending eith ngx.HTTP_CLOSE") end
		if waf._mode == "ACTIVE" then
			-- ngx.exit(ngx.HTTP_CLOSE)
			ctx.disruptive_action = "DROP"
			ctx.disruptive = "true"
		end
	end,
	IGNORE = function(waf)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Ignoring rule for now") end
	end,
	SCORE = function(waf, ctx)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Score isn't a thing anymore, see TX.anomaly_score") end
	end,
}

_M.nondisruptive_lookup = {
	deletevar = function(waf, data, ctx, collections)
		storage.delete_var(waf, ctx, data)
	end,
	expirevar = function(waf, data, ctx, collections)
		local time = util.parse_dynamic_value(waf, data.time, collections)

		storage.expire_var(waf, ctx, data, time)
	end,
	initcol = function(waf, data, ctx, collections)
		local col    = data.col
		local value  = data.value
		local parsed = util.parse_dynamic_value(waf, value, collections)

		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Initializing " .. col .. " as " .. parsed) end

		storage.initialize(waf, ctx.storage, parsed)
		ctx.col_lookup[col] = parsed
		collections[col]    = ctx.storage[parsed]
	end,
	setvar = function(waf, data, ctx, collections)
		data.key    = util.parse_dynamic_value(waf, data.key, collections)
		local value = util.parse_dynamic_value(waf, data.value, collections)

		storage.set_var(waf, ctx, data, value)
	end,
	sleep = function(waf, time)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Sleeping for " .. time) end

		ngx.sleep(time)
	end,
	status = function(waf, status, ctx)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Overriding status from " .. waf._deny_status .. " to " .. status) end

		ctx.rule_status = status
	end,
	rule_remove_id = function(waf, rule)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Runtime ignoring rule " .. rule) end

		waf._ignore_rule[rule] = true
	end,
	rule_remove_by_meta = function(waf, data, ctx)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Runtime ignoring rules by meta") end

		-- this lookup table holds
		local meta_rules = waf._meta_exception.meta_ids[ctx.id]

		if not meta_rules then return end

		for i, id in ipairs(meta_rules) do
			if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Runtime ignoring rule " .. id) end
			waf._ignore_rule[id] = true
		end
	end,
	mode_update = function(waf, mode)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Overriding mode from " .. waf._mode .. " to " .. mode) end

		waf._mode = mode
	end,
}

return _M
