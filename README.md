Kong plugin for lua-resty-waf
====================
I've use kong-plugin default templating and start porting lua-resty-waf code into the plugin template, i've yet rename it to kong-lua-resty-waf project

#### My personal development notes
https://gist.github.com/zhenguang/df3715a59b743d522484f4c788d3f144

## Todo
- Create docker image for compiling lua-resty-waf dependency binary
  - Move dependency to to correct folder
  - sed rename ***resty.logger.socket*** to **example**: ***kong.plugins.myplugin.resty.logger.socket***
- Fork [lua-resty-waf](https://github.com/p0pr0ck5/lua-resty-waf) to update with custom code to fit lua-resty-waf


## Thanks
[Kong/kong-plugin](https://github.com/Kong/kong-plugin)

[p0pr0ck5/lua-resty-waf](https://github.com/p0pr0ck5/lua-resty-waf)

[SpiderLabs/owasp-modsecurity-crs](https://github.com/SpiderLabs/owasp-modsecurity-crs)

[titansec/OpenWAF](https://github.com/titansec/OpenWAF)