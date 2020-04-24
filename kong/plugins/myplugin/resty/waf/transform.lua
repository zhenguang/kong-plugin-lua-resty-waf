local _M = {}

local base   = require "kong.plugins.myplugin.resty.waf.base"
local hdec   = require "kong.plugins.myplugin.resty.htmlentities"
local ffi    = require "ffi"
local logger = require "kong.plugins.myplugin.resty.waf.log"
local util   = require "kong.plugins.myplugin.resty.waf.util"

local ffi_cpy    = ffi.copy
local ffi_new    = ffi.new
local ffi_str    = ffi.string
local c_buf_type = ffi.typeof("char[?]")

local string_char   = string.char
local string_find   = string.find
local string_gmatch = string.gmatch
local string_gsub   = string.gsub
local string_len    = string.len
local string_lower  = string.lower
local string_match  = string.match
local string_sub    = string.sub

ffi.cdef[[
int js_decode(unsigned char *input, long int input_len);
int css_decode(unsigned char *input, long int input_len);
]]

_M.version = base.version

hdec.new() -- load the module on require

local loadlib = function()
	local so_name = 'libdecode.so'
	local cpath = package.cpath

    for k, v in string.gmatch(string.sub(debug.getinfo(1).source, 2, string.len("/transform.lua") * -1), "[^;]+") do
        local so_path = string_match(k, "(.*/)")
        if so_path then
            -- "so_path" could be nil. e.g, the dir path component is "."
            so_path = so_path .. so_name

            -- Don't get me wrong, the only way to know if a file exist is
            -- trying to open it.
            local f = io.open(so_path)
            if f ~= nil then
                io.close(f)
                return ffi.load(so_path)
            end
        end
    end
end
local decode_lib = loadlib()

local function decode_buf_helper(value, len)
	local buf = ffi_new(c_buf_type, len)
	ffi_cpy(buf, value)
	return buf
end

_M.lookup = {
	base64_decode = function(waf, value)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Decoding from base64: " .. tostring(value)) end
		local t_val = ngx.decode_base64(tostring(value))
		if t_val then
			if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Decode successful, decoded value is " .. t_val) end
			return t_val
		else
			if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Decode unsuccessful, returning original value " .. value) end
			return value
		end
	end,
	base64_encode = function(waf, value)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Encoding to base64: " .. tostring(value)) end
		local t_val = ngx.encode_base64(value)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "Encoded value is " .. t_val) end
		return t_val
	end,
	css_decode = function(waf, value)
		if not value then return end

		local len = #value
		local buf = decode_buf_helper(value, len)

		local n = decode_lib.css_decode(buf, len)

		return (ffi_str(buf, n))
	end,
	cmd_line = function(waf, value)
		local str = tostring(value)
		str = ngx.re.gsub(str, [=[[\\'"^]]=], '',  waf._pcre_flags)
		str = ngx.re.gsub(str, [=[\s+/]=],    '/', waf._pcre_flags)
		str = ngx.re.gsub(str, [=[\s+[(]]=],  '(', waf._pcre_flags)
		str = ngx.re.gsub(str, [=[[,;]]=],    ' ', waf._pcre_flags)
		str = ngx.re.gsub(str, [=[\s+]=],     ' ', waf._pcre_flags)
		return string_lower(str)
	end,
	compress_whitespace = function(waf, value)
		return ngx.re.gsub(value, [=[\s+]=], ' ', waf._pcre_flags)
	end,
	hex_decode = function(waf, value)
		return util.hex_decode(value)
	end,
	hex_encode = function(waf, value)
		return util.hex_encode(value)
	end,
	html_decode = function(waf, value)
		local str = hdec.decode(value)
		if waf._debug == true then ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', "html decoded value is " .. str) end
		return str
	end,
	js_decode = function(waf, value)
		if not value then return end

		local len = #value
		local buf = decode_buf_helper(value, len)

		local n = decode_lib.js_decode(buf, len)

		return (ffi_str(buf, n))
	end,
	length = function(waf, value)
		return string_len(tostring(value))
	end,
	lowercase = function(waf, value)
		return string_lower(tostring(value))
	end,
	md5 = function(waf, value)
		return ngx.md5_bin(value)
	end,
	normalise_path = function(waf, value)
		while (ngx.re.match(value, [=[[^/][^/]*/\.\./|/\./|/{2,}]=], waf._pcre_flags)) do
			value = ngx.re.gsub(value, [=[[^/][^/]*/\.\./|/\./|/{2,}]=], '/', waf._pcre_flags)
		end
		return value
	end,
	normalise_path_win = function(waf, value)
		value = string_gsub(value, [[\]], [[/]])
		return _M.lookup['normalise_path'](waf, value)
	end,
	remove_comments = function(waf, value)
		return ngx.re.gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], '', waf._pcre_flags)
	end,
	remove_comments_char = function(waf, value)
		return ngx.re.gsub(value, [=[\/\*|\*\/|--|#]=], '', waf._pcre_flags)
	end,
	remove_nulls = function(waf, value)
		return ngx.re.gsub(value, [[\0]], '', waf._pcre_flags)
	end,
	remove_whitespace = function(waf, value)
		return ngx.re.gsub(value, [=[\s+]=], '', waf._pcre_flags)
	end,
	replace_comments = function(waf, value)
		return ngx.re.gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], ' ', waf._pcre_flags)
	end,
	replace_nulls = function(waf, value)
		return ngx.re.gsub(value, [[\0]], ' ', waf._pcre_flags)
	end,
	sha1 = function(waf, value)
		return ngx.sha1_bin(value)
	end,
	sql_hex_decode = function(waf, value)
		if string_find(value, '0x', 1, true) then
			value = string_sub(value, 3)
			return util.hex_decode(value)
		else
			return value
		end
	end,
	trim = function(waf, value)
		return ngx.re.gsub(value, [=[^\s*|\s+$]=], '')
	end,
	trim_left = function(waf, value)
		return ngx.re.sub(value, [=[^\s+]=], '')
	end,
	trim_right = function(waf, value)
		return ngx.re.sub(value, [=[\s+$]=], '')
	end,
	uri_decode = function(waf, value)
		return ngx.unescape_uri(value)
	end,
}

return _M
