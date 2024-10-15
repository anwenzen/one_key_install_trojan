# mkdir -p /etc/caddy
# mkdir -p /var/website
# mkdir -p /usr/acme
# docker run -itd -p 6888:6888 -p 6888:6888/udp -p 16800:16800 -p 16800:16800/udp --restart always -e PUID=$UID -e PGID=$GID -e UMASK_SET=022 -e RPC_SECRET=Anwenzen -e RPC_PORT=16800 -e LISTEN_PORT=6888 -e DISK_CACHE=64M -e IPV6_MODE=true -e UPDATE_TRACKERS=true -e TZ=Asia/Shanghai -v /var/website:/downloads --name aria2 p3terx/aria2-pro:latest 
# docker run -itd --name caddy-trojan --restart always -p 80:80 -p 443:443 -p 443:443/udp -p 127.0.0.1:2019:2019 -v /etc/caddy/Caddyfile:/etc/caddy/Caddyfile -v /usr/acme:/data/caddy -v /var/website:/srv anwenzen/caddy-trojan