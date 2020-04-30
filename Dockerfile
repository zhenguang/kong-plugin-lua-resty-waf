FROM kong:2.0.3-ubuntu
LABEL maintainer="Zhen Guang <zhenguang@gmail.com>"

RUN apt-get update && apt-get -y install lua5.1 gcc libpcre3-dev && rm -rf /var/lib/apt/lists/*
RUN luarocks install lrexlib-pcre PCRE_LIBDIR=/lib/x86_64-linux-gnu
RUN luarocks install kong-plugin-lua-resty-waf

# For Alpine (currently tested not working)
# RUN apk add pcre pcre-dev lua5.1 gcc g++
# RUN luarocks install lrexlib-pcre
# RUN luarocks install kong-plugin-lua-resty-waf

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["kong","docker-start"]