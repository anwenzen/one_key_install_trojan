FROM alpine:latest
COPY ./caddy /usr/bin/caddy
ADD https://raw.githubusercontent.com/caddyserver/dist/master/config/Caddyfile /etc/caddy/Caddyfile
ADD https://raw.githubusercontent.com/caddyserver/dist/master/welcome/index.html /usr/share/caddy/index.html

ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data
ENV TZ Asia/Shanghai
RUN apk add tzdata \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && apk del tzdata
VOLUME /config
VOLUME /data

EXPOSE 80
EXPOSE 80/udp
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

WORKDIR /srv
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]