FROM caddy:latest

COPY docker_entrypoint.sh /docker_entrypoint.sh
RUN chmod +x /docker_entrypoint.sh \
    && mkdir /var/website \
    && caddy add-package github.com/imgk/caddy-trojan
EXPOSE 80
EXPOSE 443
EXPOSE 443/udp

ENTRYPOINT ["/docker_entrypoint.sh"]