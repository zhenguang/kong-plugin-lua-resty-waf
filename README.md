Kong plugin for lua-resty-waf
====================
Ported p0pr0ck5/lua-resty-waf to Kong
- Added WAF error page
- Updated SQLi rules from SpiderLabs/owasp-modsecurity-crs

## Install
Install libpcre dependency
- apt-get install libpcre++-dev
- luarocks install lrexlib-PCRE
- luarocks install kong-plugin-lua-resty-waf

## Thanks
[Kong/kong-plugin](https://github.com/Kong/kong-plugin)

[p0pr0ck5/lua-resty-waf](https://github.com/p0pr0ck5/lua-resty-waf)

[SpiderLabs/owasp-modsecurity-crs](https://github.com/SpiderLabs/owasp-modsecurity-crs)

[titansec/OpenWAF](https://github.com/titansec/OpenWAF)