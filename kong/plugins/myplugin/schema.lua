local typedefs = require "kong.db.schema.typedefs"

-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local schema = {
  name = plugin_name,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    { consumer = typedefs.no_consumer },  -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    { config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
          -- a standard defined field (typedef), with some customizations
          { error_response = {
              type = "string",
              required = false,
              default = '<html><body> Access Denied {{HOST}} {{CURRENT_DATE}} - IP: {{IP}} - ID: {{UNIQUE_ID}}</body><html>'            } 
          },
        },
      },
    },
  },
}

-- run_on_first typedef/field was removed in Kong 2.x
-- try to insert it, but simply ignore if it fails
pcall(function()
        table.insert(schema.fields, { run_on = typedefs.run_on_first })
      end)

return schema
