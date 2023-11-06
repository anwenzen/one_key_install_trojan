#! /bin/bash
red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'


update(){
sudo apt-get -y update
sudo apt-get -y install unzip wget curl git
sudo apt-get install  -y language-pack-zh-hans
sudo apt-get install -y language-pack-zh-hant
}

install_go(){
this_path=$(pwd)
### install golang
echo -e "${cyan}************* install golang *************${none}"
wget https://go.dev/dl/go1.18.2.linux-amd64.tar.gz -O ${this_path}/go1.18.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo rm -rf ${this_path}/go
tar -zxf ${this_path}/go1.18.2.linux-amd64.tar.gz -C /usr/local
echo -e "add ${green}'/usr/local/go/bin'${none} in your PATH${none}"
echo -e "add ${green}'GOPATH=/usr/local/go'${none} in your profile($this_path/.bashrc)${none}"
export PATH=$PATH:/usr/local/go/bin
echo -e "${cyan}************* install golang finish *************"
}

install_xcaddy(){
### install xcaddy
echo -e "${cyan}************* install xcaddy *************${none}"
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest;
if [ ! -e '/usr/local/bin' ]; then
    sudo mkdir '/usr/local/bin'
fi
sudo mv ${this_path}/go/bin/xcaddy /usr/local/bin/xcaddy
echo -e "${cyan}************* install xcaddy finish *************${none}"
}

build_caddy(){
### build caddy
echo -e "${cyan}************* building caddy *************${none}"

sudo rm -rf /usr/local/bin/caddy
xcaddy build --output /usr/local/bin/caddy --with github.com/imgk/caddy-trojan
echo -e "${cyan}************* build caddy finish *************${none}"
}


###  create Caddyfile
TargetDir="/etc/caddy"
if [ ! -e "${TargetDir}" ]; then
    sudo mkdir "${TargetDir}"
fi

create_caddyfile(){
cd "${TargetDir}" || exit
passwd=$(cat /dev/urandom | head -1 | md5sum | head -c 32)

echo -ne "${yellow}Enter your domain:${none}"
read domain

echo -ne "${yellow}Enter your email:${none}"
read email

cat > "${TargetDir}/Caddyfile" <<EOF
{
  servers {
    listener_wrappers {
      trojan
    }
  }
  trojan {
    caddy
    no_proxy
    users ${passwd}
  }
}

${domain}  {
  encode gzip
  tls ${email}
  route {
      reverse_proxy /download* 127.0.0.1:9870 {
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

caddy fmt ${TargetDir}/Caddyfile | caddy adapt > ${TargetDir}/caddy.json
#sudo rm -rf ${TargetDir}/Caddyfile
}

create_website(){
  sudo rm -rf /var/website
  git clone https://github.com/anwenzen/anwenzen.github.io.git /var/website
}

config_file_init(){
  sed -i "s/{MYDOMAIN}/${domain}" "${pwd}/config/Caddyfile"
  sed -i "s/{MYEMAIL}/${email}" "${pwd}/config/Caddyfile"
  sed -i "s/{MYPASSWD}/${passwd}" "${pwd}/config/Caddyfile"

  sed -i "s/{MYDOMAIN}/${domain}" "${pwd}/config/clash.yaml"
  sed -i "s/{MYEMAIL}/${email}" "${pwd}/config/clash.yaml"
  sed -i "s/{MYPASSWD}/${passwd}" "${pwd}/config/clash.yaml"

  sed -i "s/{MYDOMAIN}/${domain}" "${pwd}/config/clash-premium.yaml"
  sed -i "s/{MYEMAIL}/${email}" "${pwd}/config/clash-premium.yaml"
  sed -i "s/{MYPASSWD}/${passwd}" "${pwd}/config/clash-premium.yaml"

  sed -i "s/{MYDOMAIN}/${domain}" "${pwd}/config/hysteria2.yaml"
  sed -i "s/{MYEMAIL}/${email}" "${pwd}/config/hysteria2.yaml"
  sed -i "s/{MYPASSWD}/${passwd}" "${pwd}/config/hysteria2.yaml"

  sed -i "s/{MYDOMAIN}/${domain}" "${pwd}/config/QuantumultX.yaml"
  sed -i "s/{MYEMAIL}/${email}" "${pwd}/config/QuantumultX.yaml"
  sed -i "s/{MYPASSWD}/${passwd}" "${pwd}/config/QuantumultX.yaml"

  sudo mv "${pwd}/config" /var/website/config
}

run(){
  caddy stop
  caddy start --config  ${TargetDir}/caddy.json
  echo -e "${yellow}stop: caddy stop${none}"
  echo -e "${yellow}start: caddy start --config  ${TargetDir}/caddy.json${none}"
  echo -e ""
  echo -e "${cyan}************* finished *************${none}"
  echo -e ""
  echo -e "${yellow}domain: ${none}${green}${domain}${none}"
  echo -e "${yellow}passwd: ${none}${green}${passwd}${none}"
  echo -e "${yellow}port: ${none}${green}443${none}"
  echo -e "${yellow}sni: ${none}${green}${domain}${none}"
  echo -e "${yellow}your subscription url: ${none}${green}${domain}/v2/clash_utf8.conf${none}"
}


echo -ne "${cyan}switch one u want to do:${none}\n"
echo -ne "${cyan}1.install chinese toolkit, etc.${none}\n"
echo -ne "${cyan}2.instll golang env${none}\n"
echo -ne "${cyan}3.build and install caddy${none}\n"
echo -ne "${cyan}4.install website file${none}\n"
echo -ne "${cyan}5.init config file in website${none}\n"
echo -ne "${cyan}6.run caddy\n>> ${none}"
read  step
case "$step" in
  0)  update
      install_go
      install_xcaddy
      build_caddy
      create_website
      config_file_init
      run
      ;;
  1)  update
      ;;
  2)  install_go
      ;;
  3)  install_xcaddy
      build_caddy
      ;;
  4)  create_website
      ;;
  5)  config_file_init
      ;;
  6)  run
      ;;
esac