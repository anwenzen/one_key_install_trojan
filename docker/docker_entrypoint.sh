#!/bin/sh

# if [[ "$MYPASSWD" == "123456" || "$MYPASSWD" == "MY_PASSWORD" ]]; then
#     echo please reset your password && exit 1
# fi

# if [[ "$MYDOMAIN" == "1.1.1.1.nip.io" || "$MYDOMAIN" == "MY_DOMAIN.COM" ]]; then
#     echo please reset your domain name && exit 1
# fi

# config
cat > /etc/caddy/Caddyfile <<EOF 
{
	order trojan before route
	servers :443 {
		listener_wrappers {
			trojan
		}
	}
	trojan {
		caddy
		no_proxy
		users ${MYPASSWD}
	}
}



${MYDOMAIN)  {
	encode gzip
	#tls The.Email@Example.com
	route {
		reverse_proxy /download* 172.18.0.2:9870 {
			header_up Host {host}
			header_up X-Real-IP {remote}
			header_up X-Forwarded-For {remote}
			header_up X-Forwarded-Proto {scheme}
		}

		trojan {
			connect_method
			websocket
		}

		file_server {
			root /var/website
			browse
		}
	}
	handle_errors {
		respond  "{http.error.status_code} {http.error.status_text}"
	}
}
EOF
# start
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile