FROM caddy:latest

COPY docker_entrypoint.sh /docker_entrypoint.sh
RUN chmod +x /docker_entrypoint.sh \
    && caddy add-package github.com/imgk/caddy-trojan
EXPOSE 80
EXPOSE 443

#ENTRYPOINT ["/docker_entrypoint.sh"]