#!/bin/sh

# to init for docker-compose install

config_file_init(){
  sed -i "s/{MYDOMAIN}/${domain}" "${PWD}/config/Caddyfile"
  sed -i "s/{MYEMAIL}/${email}" "${PWD}/config/Caddyfile"
  sed -i "s/{MYPASSWD}/${passwd}" "${PWD}/config/Caddyfile"

  sed -i "s/{MYDOMAIN}/${domain}" "${PWD}/config/clash.yaml"
  sed -i "s/{MYEMAIL}/${email}" "${PWD}/config/clash.yaml"
  sed -i "s/{MYPASSWD}/${passwd}" "${PWD}/config/clash.yaml"

  sed -i "s/{MYDOMAIN}/${domain}" "${PWD}/config/clash-premium.yaml"
  sed -i "s/{MYEMAIL}/${email}" "${PWD}/config/clash-premium.yaml"
  sed -i "s/{MYPASSWD}/${passwd}" "${PWD}/config/clash-premium.yaml"

  sed -i "s/{MYDOMAIN}/${domain}" "${PWD}/config/hysteria2.yaml"
  sed -i "s/{MYEMAIL}/${email}" "${PWD}/config/hysteria2.yaml"
  sed -i "s/{MYPASSWD}/${passwd}" "${PWD}/config/hysteria2.yaml"

  sed -i "s/{MYDOMAIN}/${domain}" "${PWD}/config/QuantumultX.yaml"
  sed -i "s/{MYEMAIL}/${email}" "${PWD}/config/QuantumultX.yaml"
  sed -i "s/{MYPASSWD}/${passwd}" "${PWD}/config/QuantumultX.yaml"

  sudo mv "${PWD}/config" /var/website/config
}
create_website(){
  sudo rm -rf /var/website
  git clone https://github.com/anwenzen/anwenzen.github.io.git "${PWD}/aria2-downloads/"
}

passwd=$(cat /dev/urandom | head -1 | md5sum | head -c 32)

echo -ne "${yellow}Enter your domain:${none}"
read domain

echo -ne "${yellow}Enter your email:${none}"
read email

MYPASSWD=${passwd}
MYEMAIL=${email}
MYDOMAIN=${domain}

ln -s "${PWD}/config" "${PWD}/aria2-downloads/config"