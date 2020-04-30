package = "kong-plugin-lua-resty-waf"  -- TODO: rename, must match the info in the filename of this rockspec!
                                  -- as a convention; stick to the prefix: `kong-plugin-`
version = "0.1.0-1"               -- TODO: renumber, must match the info in the filename of this rockspec!
-- The version '0.1.0' is the source code version, the trailing '1' is the version of this rockspec.
-- whenever the source version changes, the rockspec should be reset to 1. The rockspec version is only
-- updated (incremented) when this file changes, but the source remains the same.

-- TODO: This is the name to set in the Kong configuration `plugins` setting.
-- Here we extract it from the package name.
local pluginName = "kong-plugin-lua-resty-waf"  -- "myplugin"

supported_platforms = {"linux"}
source = {
  url = "git://github.com/zhenguang/kong-plugin-lua-resty-waf",
  tag = "0.1.0"
}

description = {
  summary = "Porting p0pr0ck5/lua-resty-waf to Kong",
  homepage = "https://github.com/zhenguang/kong-plugin-lua-resty-waf",
  license = "GNU General Public License"
}

dependencies = {
   "lrexlib-pcre",
}

build = {
  type = "builtin",
  modules = {
    -- TODO: add any additional files that the plugin consists of
    ["kong.plugins."..pluginName..".handler"] = "lua/kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "lua/kong/plugins/"..pluginName.."/schema.lua",
  },
  copy_directories = { 
      ["lua.kong.plugins."..pluginName..".resty"] = "lua/kong/plugins/kong-plugin-lua-resty-waf/resty/"
  },
}
