# one key install trojan(easy 4 step)
## Requirements
### 1.Domain
### 2.Resolve the domain name to your host（DNS）
### 3.Ubuntu or like ubuntu system

## install
### 1. by terminal
    ```shell
    chmod +x ./one_instance.sh && ./one_instance.sh
    ```
### 2. by docker compose
    ```shell
        chmod +x ./.init.sh && ./.init.sh && docker-compose -f ./docker-compose.yml up
    ```
## thanks: [caddy](https://github.com/caddyserver/caddy),  [caddy-trojan](https://github.com/imgk/caddy-trojan), [clash-rules](https://github.com/Loyalsoldier/clash-rules)

