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
              default = '<html><head><style>.waf-overlay { display: -webkit-box; display: -webkit-flex; display: -ms-flexbox; display: flex; height: 90vh; max-height: 780px; padding-top: 100px; padding-bottom: 100px; -webkit-box-pack: center; -webkit-justify-content: center; -ms-flex-pack: center; justify-content: center; -webkit-box-align: center; -webkit-align-items: center; -ms-flex-align: center; align-items: center; grid-auto-columns: 1fr; grid-column-gap: 16px; grid-row-gap: 16px; -ms-grid-columns: 1fr 1fr; grid-template-columns: 1fr 1fr; -ms-grid-rows: auto auto; grid-template-rows: auto auto; background-color: transparent; color: #fff;}.centered-container { -webkit-box-flex: 0; -webkit-flex: 0 auto; -ms-flex: 0 auto; flex: 0 auto; border: 0px none transparent; border-radius: 0px; text-align: center;}.paragraph { padding: 2px 34px 42px 36px; font-family: Tahoma, Verdana, Segoe, sans-serif; color: rgba(0, 0, 0, 0.7); font-size: 14px; text-align: left;}.heading { padding: 20px 25px; background-color: #043558; font-family: Tahoma, Verdana, Segoe, sans-serif; color: #fff; font-size: 18px; font-weight: 400; text-align: left;}.div-block { background-color: #f0f2f5;}.bold-text { font-weight: 400;}.text-span { color: #004b80;}.ip-addr { color: #004b80;}.incident-id { color: #004b80;}.bold-text-2 { color: rgba(0, 0, 0, 0.7);}@media screen and (max-width: 767px) { .waf-overlay { padding: 40px 20px; }}@media screen and (max-width: 479px) { .centered-container { display: block; text-align: left; } .paragraph { padding-right: 0px; padding-left: 17px; font-size: 14px; } .heading { margin-top: auto; margin-bottom: auto; padding: 20px; direction: ltr; font-size: 16px; text-align: left; white-space: normal; } .div-block { padding: 20px; }}</style></head></head><body> <div id="hero-overlay" class="waf-overlay"> <div class="centered-container w-container"> <h3 class="heading">{{HOST}} - <strong class="bold-text">Access Denied</strong></h3> <div class="div-block"><p class="paragraph">This request was blocked by the security rules<br><br><strong class="bold-text-2">{{CURRENT_DATE}}</strong><br><br>Your IP <span class="ip-addr">{{IP}}</span> Incident ID: <span class="incident-id">{{UNIQUE_ID}}</span></p> </div> </div> </div></body></html>'            } 
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
