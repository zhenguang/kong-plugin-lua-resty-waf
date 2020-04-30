Kong plugin for lua-resty-waf
====================
Ported p0pr0ck5/lua-resty-waf to Kong
- Added WAF error page
- Updated SQLi rules from SpiderLabs/owasp-modsecurity-crs

## Docker build for Ubuntu 2.0.3-ubuntu
Currently this plugin only work on ubuntu due to the pre-compiled .so binary
```
$ git clone https://github.com/zhenguang/kong-plugin-lua-resty-waf.git
$ docker build --tag kong:2.0.3-ubuntu-waf .
```

To run docker with the kong lua-resty-waf plugin

```
# Follow the tutorial till the last steps
# https://docs.konghq.com/install/docker/ 

$ docker run -d --name kong \
     --network=kong-net \
     -e "KONG_DATABASE=postgres" \
     -e "KONG_PG_HOST=kong-database" \
     -e "KONG_PG_PASSWORD=kong" \
     -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
     -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
     -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
     -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
     -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
     -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
     -e "KONG_PLUGINS=bundled,kong-plugin-lua-resty-waf" \
     -e "KONG_LOG_LEVEL=debug" \
     -p 8000:8000 \
     -p 8443:8443 \
     -p 127.0.0.1:8001:8001 \
     -p 127.0.0.1:8444:8444 \
     kong:2.0.3-ubuntu-waf
```

## Installation
Install for Kong/kong-vagrant dependency
```
$ apt-get install libpcre++-dev
$ luarocks install lrexlib-PCRE
$ luarocks install kong-plugin-lua-resty-waf
```

## Testing waf using wallarm/gotestwaf
```
$ docker run -v /tmp:/tmp/report gotestwaf --url=http://172.0.0.1:8000/
WAF pre-check: OK. Blocking status code: 403
Checking http://192.168.1.78:8000/
Loading testcases: 
false-pos	texts
owasp	ldap-injection
owasp	mail-injection
owasp	nosql-injection
owasp	path-traversal
owasp	shell-injection
owasp	sql-injection
owasp	ss-include
owasp	sst-injection
owasp	xml-injection
owasp	xss-scripting
owasp-api	graphql
owasp-api	rest
owasp-api	soap
................................
false-pos	texts	2/2	(1.00)
owasp	ldap-injection	6/8	(0.75)
owasp	mail-injection	0/12	(0.00)
owasp	nosql-injection	9/18	(0.50)
owasp	xml-injection	0/12	(0.00)
owasp	sst-injection	5/20	(0.25)
owasp	xss-scripting	14/28	(0.50)
owasp	path-traversal	12/24	(0.50)
owasp	shell-injection	6/8	(0.75)
owasp	sql-injection	13/32	(0.41)
owasp	ss-include	5/20	(0.25)
owasp-api	graphql	0/1	(0.00)
owasp-api	rest	2/2	(1.00)
owasp-api	soap	2/2	(1.00)

WAF score: 49.33%
113 bypasses in 189 tests / 14 test cases

PDF report is ready: /tmp/report/waf-test-report2020-April-30.pdf
```

## References and thanks
- [Kong/kong-plugin](https://github.com/Kong/kong-plugin)
- [p0pr0ck5/lua-resty-waf](https://github.com/p0pr0ck5/lua-resty-waf)
- [SpiderLabs/owasp-modsecurity-crs](https://github.com/SpiderLabs/owasp-modsecurity-crs)
- [wallarm/gotestwaf](https://github.com/wallarm/gotestwaf)
- [titansec/OpenWAF](https://github.com/titansec/OpenWAF)