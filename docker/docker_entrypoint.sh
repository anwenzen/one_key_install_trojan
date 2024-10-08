#!/bin/sh

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
	log {
		format console {
			time_local
			time_format wall
		}
	}
}



${MYDOMAIN)  {
	encode gzip
	tls ${MYEMAIL}
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