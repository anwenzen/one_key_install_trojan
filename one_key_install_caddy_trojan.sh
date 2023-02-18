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
		reverse_proxy /jupyter* 127.0.0.1:8888
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
        respond  "<h1 align=\"center\">{http.error.status_code} {http.error.status_text}</h1>"
    }
}
EOF

caddy fmt ${TargetDir}/Caddyfile | caddy adapt > ${TargetDir}/caddy.json
#sudo rm -rf ${TargetDir}/Caddyfile
}

create_clashfile(){
sudo rm -rf /var/website
git clone https://github.com/anwenzen/anwenzen.github.io.git
sudo mv "$(pwd)/anwenzen.github.io" /var/website
sudo mkdir /var/website/v2



cat > '/var/website/v2/clash_utf8.conf' <<EOF
port: 7890
socks-port: 7891
redir-port: 7892
allow-lan: false
mode: rule
log-level: silent
external-controller: 127.0.0.1:9090
hosts:

dns:
  enable: true
  listen: 0.0.0.0:53
  ipv6: true  
  default-nameserver:
    - 223.5.5.5
    - 114.114.114.114
    - 119.29.29.29
  enhanced-mode: redir-host 
  fake-ip-range: 198.18.0.1/16 
  nameserver:
    - https://dns.alidns.com/dns-query
    - https://13800000000.rubyfish.cn/
    - https://doh.360.cn/dns-query
  fallback-filter:
    geoip: false
    ipcidr:

proxies:
  - name: "xyz"
    type: trojan
    server: ${domain}
    port: 443
    password: ${passwd}
    udp: true
    sni: ${domain}
    alpn:
      - h2
      - http/1.1
    skip-cert-verify: true

proxy-groups:
  - name: "fallback-auto"
    type: fallback
    proxies:
      - xyz
    url: 'http://www.gstatic.com/generate_204'
    interval: 300
  - name: "load-balance"
    type: load-balance
    proxies:
      - xyz
    url: 'http://www.gstatic.com/generate_204'
    interval: 300
  - name: Proxy
    type: select
    proxies:
      - fallback-auto
      - xyz

proxy-providers:
  

rules:
  - DOMAIN,safebrowsing.urlsec.qq.com,DIRECT 
  - DOMAIN,safebrowsing.googleapis.com,DIRECT 
  - DOMAIN,developer.apple.com,Proxy
  - DOMAIN-SUFFIX,digicert.com,Proxy
  - DOMAIN,ocsp.apple.com,Proxy
  - DOMAIN,ocsp.sectigo.com,Proxy
  - DOMAIN,ocsp.verisign.net,Proxy
  - DOMAIN-SUFFIX,apple-dns.net,Proxy
  - DOMAIN,testflight.apple.com,Proxy
  - DOMAIN,sandbox.itunes.apple.com,Proxy
  - DOMAIN,itunes.apple.com,Proxy
  - DOMAIN-SUFFIX,apps.apple.com,Proxy
  - DOMAIN-SUFFIX,blobstore.apple.com,Proxy
  - DOMAIN,cvws.icloud-content.com,Proxy
  - DOMAIN-SUFFIX,mzstatic.com,DIRECT
  - DOMAIN-SUFFIX,itunes.apple.com,DIRECT
  - DOMAIN-SUFFIX,icloud.com,DIRECT
  - DOMAIN-SUFFIX,icloud-content.com,DIRECT
  - DOMAIN-SUFFIX,me.com,DIRECT
  - DOMAIN-SUFFIX,aaplimg.com,DIRECT
  - DOMAIN-SUFFIX,cdn20.com,DIRECT
  - DOMAIN-SUFFIX,cdn-apple.com,DIRECT
  - DOMAIN-SUFFIX,akadns.net,DIRECT
  - DOMAIN-SUFFIX,akamaiedge.net,DIRECT
  - DOMAIN-SUFFIX,edgekey.net,DIRECT
  - DOMAIN-SUFFIX,mwcloudcdn.com,DIRECT
  - DOMAIN-SUFFIX,mwcname.com,DIRECT
  - DOMAIN-SUFFIX,apple.com,DIRECT
  - DOMAIN-SUFFIX,apple-cloudkit.com,DIRECT
  - DOMAIN-SUFFIX,apple-mapkit.com,DIRECT
  - DOMAIN-SUFFIX,cn,DIRECT
  - DOMAIN-KEYWORD,-cn,DIRECT
  - DOMAIN-SUFFIX,126.com,DIRECT
  - DOMAIN-SUFFIX,126.net,DIRECT
  - DOMAIN-SUFFIX,127.net,DIRECT
  - DOMAIN-SUFFIX,163.com,DIRECT
  - DOMAIN-SUFFIX,360buyimg.com,DIRECT
  - DOMAIN-SUFFIX,36kr.com,DIRECT
  - DOMAIN-SUFFIX,acfun.tv,DIRECT
  - DOMAIN-SUFFIX,air-matters.com,DIRECT
  - DOMAIN-SUFFIX,aixifan.com,DIRECT
  - DOMAIN-KEYWORD,alicdn,DIRECT
  - DOMAIN-KEYWORD,alipay,DIRECT
  - DOMAIN-KEYWORD,taobao,DIRECT
  - DOMAIN-SUFFIX,amap.com,DIRECT
  - DOMAIN-SUFFIX,autonavi.com,DIRECT
  - DOMAIN-KEYWORD,baidu,DIRECT
  - DOMAIN-SUFFIX,bdimg.com,DIRECT
  - DOMAIN-SUFFIX,bdstatic.com,DIRECT
  - DOMAIN-SUFFIX,bilibili.com,DIRECT
  - DOMAIN-SUFFIX,bilivideo.com,DIRECT
  - DOMAIN-SUFFIX,caiyunapp.com,DIRECT
  - DOMAIN-SUFFIX,clouddn.com,DIRECT
  - DOMAIN-SUFFIX,cnbeta.com,DIRECT
  - DOMAIN-SUFFIX,cnbetacdn.com,DIRECT
  - DOMAIN-SUFFIX,cootekservice.com,DIRECT
  - DOMAIN-SUFFIX,csdn.net,DIRECT
  - DOMAIN-SUFFIX,ctrip.com,DIRECT
  - DOMAIN-SUFFIX,dgtle.com,DIRECT
  - DOMAIN-SUFFIX,dianping.com,DIRECT
  - DOMAIN-SUFFIX,douban.com,DIRECT
  - DOMAIN-SUFFIX,doubanio.com,DIRECT
  - DOMAIN-SUFFIX,duokan.com,DIRECT
  - DOMAIN-SUFFIX,easou.com,DIRECT
  - DOMAIN-SUFFIX,ele.me,DIRECT
  - DOMAIN-SUFFIX,feng.com,DIRECT
  - DOMAIN-SUFFIX,fir.im,DIRECT
  - DOMAIN-SUFFIX,frdic.com,DIRECT
  - DOMAIN-SUFFIX,g-cores.com,DIRECT
  - DOMAIN-SUFFIX,godic.net,DIRECT
  - DOMAIN-SUFFIX,gtimg.com,DIRECT
  - DOMAIN,cdn.hockeyapp.net,DIRECT
  - DOMAIN-SUFFIX,hongxiu.com,DIRECT
  - DOMAIN-SUFFIX,hxcdn.net,DIRECT
  - DOMAIN-SUFFIX,iciba.com,DIRECT
  - DOMAIN-SUFFIX,ifeng.com,DIRECT
  - DOMAIN-SUFFIX,ifengimg.com,DIRECT
  - DOMAIN-SUFFIX,ipip.net,DIRECT
  - DOMAIN-SUFFIX,iqiyi.com,DIRECT
  - DOMAIN-SUFFIX,jd.com,DIRECT
  - DOMAIN-SUFFIX,jianshu.com,DIRECT
  - DOMAIN-SUFFIX,knewone.com,DIRECT
  - DOMAIN-SUFFIX,le.com,DIRECT
  - DOMAIN-SUFFIX,lecloud.com,DIRECT
  - DOMAIN-SUFFIX,lemicp.com,DIRECT
  - DOMAIN-SUFFIX,licdn.com,DIRECT
  - DOMAIN-SUFFIX,linkedin.com,DIRECT
  - DOMAIN-SUFFIX,luoo.net,DIRECT
  - DOMAIN-SUFFIX,meituan.com,DIRECT
  - DOMAIN-SUFFIX,meituan.net,DIRECT
  - DOMAIN-SUFFIX,mi.com,DIRECT
  - DOMAIN-SUFFIX,miaopai.com,DIRECT
  - DOMAIN-SUFFIX,microsoft.com,DIRECT
  - DOMAIN-SUFFIX,microsoftonline.com,DIRECT
  - DOMAIN-SUFFIX,miui.com,DIRECT
  - DOMAIN-SUFFIX,miwifi.com,DIRECT
  - DOMAIN-SUFFIX,mob.com,DIRECT
  - DOMAIN-SUFFIX,netease.com,DIRECT
  - DOMAIN-SUFFIX,office.com,DIRECT
  - DOMAIN-SUFFIX,office365.com,DIRECT
  - DOMAIN-KEYWORD,officecdn,DIRECT
  - DOMAIN-SUFFIX,oschina.net,DIRECT
  - DOMAIN-SUFFIX,ppsimg.com,DIRECT
  - DOMAIN-SUFFIX,pstatp.com,DIRECT
  - DOMAIN-SUFFIX,qcloud.com,DIRECT
  - DOMAIN-SUFFIX,qdaily.com,DIRECT
  - DOMAIN-SUFFIX,qdmm.com,DIRECT
  - DOMAIN-SUFFIX,qhimg.com,DIRECT
  - DOMAIN-SUFFIX,qhres.com,DIRECT
  - DOMAIN-SUFFIX,qidian.com,DIRECT
  - DOMAIN-SUFFIX,qihucdn.com,DIRECT
  - DOMAIN-SUFFIX,qiniu.com,DIRECT
  - DOMAIN-SUFFIX,qiniucdn.com,DIRECT
  - DOMAIN-SUFFIX,qiyipic.com,DIRECT
  - DOMAIN-SUFFIX,qq.com,DIRECT
  - DOMAIN-SUFFIX,qqurl.com,DIRECT
  - DOMAIN-SUFFIX,rarbg.to,DIRECT
  - DOMAIN-SUFFIX,ruguoapp.com,DIRECT
  - DOMAIN-SUFFIX,segmentfault.com,DIRECT
  - DOMAIN-SUFFIX,sinaapp.com,DIRECT
  - DOMAIN-SUFFIX,smzdm.com,DIRECT
  - DOMAIN-SUFFIX,snapdrop.net,DIRECT
  - DOMAIN-SUFFIX,sogou.com,DIRECT
  - DOMAIN-SUFFIX,sogoucdn.com,DIRECT
  - DOMAIN-SUFFIX,sohu.com,DIRECT
  - DOMAIN-SUFFIX,soku.com,DIRECT
  - DOMAIN-SUFFIX,speedtest.net,DIRECT
  - DOMAIN-SUFFIX,sspai.com,DIRECT
  - DOMAIN-SUFFIX,suning.com,DIRECT
  - DOMAIN-SUFFIX,taobao.com,DIRECT
  - DOMAIN-SUFFIX,tencent.com,DIRECT
  - DOMAIN-SUFFIX,tenpay.com,DIRECT
  - DOMAIN-SUFFIX,tianyancha.com,DIRECT
  - DOMAIN-SUFFIX,tmall.com,DIRECT
  - DOMAIN-SUFFIX,tudou.com,DIRECT
  - DOMAIN-SUFFIX,umetrip.com,DIRECT
  - DOMAIN-SUFFIX,upaiyun.com,DIRECT
  - DOMAIN-SUFFIX,upyun.com,DIRECT
  - DOMAIN-SUFFIX,veryzhun.com,DIRECT
  - DOMAIN-SUFFIX,weather.com,DIRECT
  - DOMAIN-SUFFIX,weibo.com,DIRECT
  - DOMAIN-SUFFIX,xiami.com,DIRECT
  - DOMAIN-SUFFIX,xiami.net,DIRECT
  - DOMAIN-SUFFIX,xiaomicp.com,DIRECT
  - DOMAIN-SUFFIX,ximalaya.com,DIRECT
  - DOMAIN-SUFFIX,xmcdn.com,DIRECT
  - DOMAIN-SUFFIX,xunlei.com,DIRECT
  - DOMAIN-SUFFIX,yhd.com,DIRECT
  - DOMAIN-SUFFIX,yihaodianimg.com,DIRECT
  - DOMAIN-SUFFIX,yinxiang.com,DIRECT
  - DOMAIN-SUFFIX,ykimg.com,DIRECT
  - DOMAIN-SUFFIX,youdao.com,DIRECT
  - DOMAIN-SUFFIX,youku.com,DIRECT
  - DOMAIN-SUFFIX,zealer.com,DIRECT
  - DOMAIN-SUFFIX,zhihu.com,DIRECT
  - DOMAIN-SUFFIX,zhimg.com,DIRECT
  - DOMAIN-SUFFIX,zimuzu.tv,DIRECT
  - DOMAIN-SUFFIX,zoho.com,DIRECT
  - DOMAIN-KEYWORD,amazon,Proxy
  - DOMAIN-KEYWORD,google,Proxy
  - DOMAIN-KEYWORD,gmail,Proxy
  - DOMAIN-KEYWORD,youtube,Proxy
  - DOMAIN-KEYWORD,facebook,Proxy
  - DOMAIN-SUFFIX,fb.me,Proxy
  - DOMAIN-SUFFIX,fbcdn.net,Proxy
  - DOMAIN-KEYWORD,twitter,Proxy
  - DOMAIN-KEYWORD,instagram,Proxy
  - DOMAIN-KEYWORD,dropbox,Proxy
  - DOMAIN-SUFFIX,twimg.com,Proxy
  - DOMAIN-KEYWORD,blogspot,Proxy
  - DOMAIN-SUFFIX,youtu.be,Proxy
  - DOMAIN-KEYWORD,whatsapp,Proxy
  - DOMAIN-KEYWORD,admarvel,REJECT
  - DOMAIN-KEYWORD,admaster,REJECT
  - DOMAIN-KEYWORD,adsage,REJECT
  - DOMAIN-KEYWORD,adsmogo,REJECT
  - DOMAIN-KEYWORD,adsrvmedia,REJECT
  - DOMAIN-KEYWORD,adwords,REJECT
  - DOMAIN-KEYWORD,adservice,REJECT
  - DOMAIN-SUFFIX,appsflyer.com,REJECT
  - DOMAIN-KEYWORD,domob,REJECT
  - DOMAIN-SUFFIX,doubleclick.net,REJECT
  - DOMAIN-KEYWORD,duomeng,REJECT
  - DOMAIN-KEYWORD,dwtrack,REJECT
  - DOMAIN-KEYWORD,guanggao,REJECT
  - DOMAIN-KEYWORD,lianmeng,REJECT
  - DOMAIN-SUFFIX,mmstat.com,REJECT
  - DOMAIN-KEYWORD,mopub,REJECT
  - DOMAIN-KEYWORD,omgmta,REJECT
  - DOMAIN-KEYWORD,openx,REJECT
  - DOMAIN-KEYWORD,partnerad,REJECT
  - DOMAIN-KEYWORD,pingfore,REJECT
  - DOMAIN-KEYWORD,supersonicads,REJECT
  - DOMAIN-KEYWORD,uedas,REJECT
  - DOMAIN-KEYWORD,umeng,REJECT
  - DOMAIN-KEYWORD,usage,REJECT
  - DOMAIN-SUFFIX,vungle.com,REJECT
  - DOMAIN-KEYWORD,wlmonitor,REJECT
  - DOMAIN-KEYWORD,zjtoolbar,REJECT
  - DOMAIN-SUFFIX,9to5mac.com,Proxy
  - DOMAIN-SUFFIX,abpchina.org,Proxy
  - DOMAIN-SUFFIX,adblockplus.org,Proxy
  - DOMAIN-SUFFIX,adobe.com,Proxy
  - DOMAIN-SUFFIX,akamaized.net,Proxy
  - DOMAIN-SUFFIX,alfredapp.com,Proxy
  - DOMAIN-SUFFIX,amplitude.com,Proxy
  - DOMAIN-SUFFIX,ampproject.org,Proxy
  - DOMAIN-SUFFIX,android.com,Proxy
  - DOMAIN-SUFFIX,angularjs.org,Proxy
  - DOMAIN-SUFFIX,aolcdn.com,Proxy
  - DOMAIN-SUFFIX,apkpure.com,Proxy
  - DOMAIN-SUFFIX,appledaily.com,Proxy
  - DOMAIN-SUFFIX,appshopper.com,Proxy
  - DOMAIN-SUFFIX,appspot.com,Proxy
  - DOMAIN-SUFFIX,arcgis.com,Proxy
  - DOMAIN-SUFFIX,archive.org,Proxy
  - DOMAIN-SUFFIX,armorgames.com,Proxy
  - DOMAIN-SUFFIX,aspnetcdn.com,Proxy
  - DOMAIN-SUFFIX,att.com,Proxy
  - DOMAIN-SUFFIX,awsstatic.com,Proxy
  - DOMAIN-SUFFIX,azureedge.net,Proxy
  - DOMAIN-SUFFIX,azurewebsites.net,Proxy
  - DOMAIN-SUFFIX,bing.com,Proxy
  - DOMAIN-SUFFIX,bintray.com,Proxy
  - DOMAIN-SUFFIX,bit.com,Proxy
  - DOMAIN-SUFFIX,bit.ly,Proxy
  - DOMAIN-SUFFIX,bitbucket.org,Proxy
  - DOMAIN-SUFFIX,bjango.com,Proxy
  - DOMAIN-SUFFIX,bkrtx.com,Proxy
  - DOMAIN-SUFFIX,blog.com,Proxy
  - DOMAIN-SUFFIX,blogcdn.com,Proxy
  - DOMAIN-SUFFIX,blogger.com,Proxy
  - DOMAIN-SUFFIX,blogsmithmedia.com,Proxy
  - DOMAIN-SUFFIX,blogspot.com,Proxy
  - DOMAIN-SUFFIX,blogspot.hk,Proxy
  - DOMAIN-SUFFIX,bloomberg.com,Proxy
  - DOMAIN-SUFFIX,box.com,Proxy
  - DOMAIN-SUFFIX,box.net,Proxy
  - DOMAIN-SUFFIX,cachefly.net,Proxy
  - DOMAIN-SUFFIX,chromium.org,Proxy
  - DOMAIN-SUFFIX,cl.ly,Proxy
  - DOMAIN-SUFFIX,cloudflare.com,Proxy
  - DOMAIN-SUFFIX,cloudfront.net,Proxy
  - DOMAIN-SUFFIX,cloudmagic.com,Proxy
  - DOMAIN-SUFFIX,cmail19.com,Proxy
  - DOMAIN-SUFFIX,cnet.com,Proxy
  - DOMAIN-SUFFIX,cocoapods.org,Proxy
  - DOMAIN-SUFFIX,comodoca.com,Proxy
  - DOMAIN-SUFFIX,crashlytics.com,Proxy
  - DOMAIN-SUFFIX,culturedcode.com,Proxy
  - DOMAIN-SUFFIX,d.pr,Proxy
  - DOMAIN-SUFFIX,danilo.to,Proxy
  - DOMAIN-SUFFIX,dayone.me,Proxy
  - DOMAIN-SUFFIX,db.tt,Proxy
  - DOMAIN-SUFFIX,deskconnect.com,Proxy
  - DOMAIN-SUFFIX,disq.us,Proxy
  - DOMAIN-SUFFIX,disqus.com,Proxy
  - DOMAIN-SUFFIX,disquscdn.com,Proxy
  - DOMAIN-SUFFIX,dnsimple.com,Proxy
  - DOMAIN-SUFFIX,docker.com,Proxy
  - DOMAIN-SUFFIX,docker.io,Proxy
  - DOMAIN-SUFFIX,dribbble.com,Proxy
  - DOMAIN-SUFFIX,droplr.com,Proxy
  - DOMAIN-SUFFIX,duckduckgo.com,Proxy
  - DOMAIN-SUFFIX,dueapp.com,Proxy
  - DOMAIN-SUFFIX,dytt8.net,Proxy
  - DOMAIN-SUFFIX,edgecastcdn.net,Proxy
  - DOMAIN-SUFFIX,edgekey.net,Proxy
  - DOMAIN-SUFFIX,edgesuite.net,Proxy
  - DOMAIN-SUFFIX,engadget.com,Proxy
  - DOMAIN-SUFFIX,entrust.net,Proxy
  - DOMAIN-SUFFIX,eurekavpt.com,Proxy
  - DOMAIN-SUFFIX,evernote.com,Proxy
  - DOMAIN-SUFFIX,fabric.io,Proxy
  - DOMAIN-SUFFIX,fast.com,Proxy
  - DOMAIN-SUFFIX,fastly.net,Proxy
  - DOMAIN-SUFFIX,fc2.com,Proxy
  - DOMAIN-SUFFIX,feedburner.com,Proxy
  - DOMAIN-SUFFIX,feedly.com,Proxy
  - DOMAIN-SUFFIX,feedsportal.com,Proxy
  - DOMAIN-SUFFIX,fiftythree.com,Proxy
  - DOMAIN-SUFFIX,firebaseio.com,Proxy
  - DOMAIN-SUFFIX,flexibits.com,Proxy
  - DOMAIN-SUFFIX,flickr.com,Proxy
  - DOMAIN-SUFFIX,flipboard.com,Proxy
  - DOMAIN-SUFFIX,g.co,Proxy
  - DOMAIN-SUFFIX,gabia.net,Proxy
  - DOMAIN-SUFFIX,geni.us,Proxy
  - DOMAIN-SUFFIX,gfx.ms,Proxy
  - DOMAIN-SUFFIX,ggpht.com,Proxy
  - DOMAIN-SUFFIX,ghostnoteapp.com,Proxy
  - DOMAIN-SUFFIX,git.io,Proxy
  - DOMAIN-KEYWORD,github,Proxy
  - DOMAIN-SUFFIX,globalsign.com,Proxy
  - DOMAIN-SUFFIX,gmodules.com,Proxy
  - DOMAIN-SUFFIX,godaddy.com,Proxy
  - DOMAIN-SUFFIX,golang.org,Proxy
  - DOMAIN-SUFFIX,gongm.in,Proxy
  - DOMAIN-SUFFIX,goo.gl,Proxy
  - DOMAIN-SUFFIX,goodreaders.com,Proxy
  - DOMAIN-SUFFIX,goodreads.com,Proxy
  - DOMAIN-SUFFIX,gravatar.com,Proxy
  - DOMAIN-SUFFIX,gstatic.com,Proxy
  - DOMAIN-SUFFIX,gvt0.com,Proxy
  - DOMAIN-SUFFIX,hockeyapp.net,Proxy
  - DOMAIN-SUFFIX,hotmail.com,Proxy
  - DOMAIN-SUFFIX,icons8.com,Proxy
  - DOMAIN-SUFFIX,ifixit.com,Proxy
  - DOMAIN-SUFFIX,ift.tt,Proxy
  - DOMAIN-SUFFIX,ifttt.com,Proxy
  - DOMAIN-SUFFIX,iherb.com,Proxy
  - DOMAIN-SUFFIX,imageshack.us,Proxy
  - DOMAIN-SUFFIX,img.ly,Proxy
  - DOMAIN-SUFFIX,imgur.com,Proxy
  - DOMAIN-SUFFIX,imore.com,Proxy
  - DOMAIN-SUFFIX,instapaper.com,Proxy
  - DOMAIN-SUFFIX,ipn.li,Proxy
  - DOMAIN-SUFFIX,is.gd,Proxy
  - DOMAIN-SUFFIX,issuu.com,Proxy
  - DOMAIN-SUFFIX,itgonglun.com,Proxy
  - DOMAIN-SUFFIX,itun.es,Proxy
  - DOMAIN-SUFFIX,ixquick.com,Proxy
  - DOMAIN-SUFFIX,j.mp,Proxy
  - DOMAIN-SUFFIX,js.revsci.net,Proxy
  - DOMAIN-SUFFIX,jshint.com,Proxy
  - DOMAIN-SUFFIX,jtvnw.net,Proxy
  - DOMAIN-SUFFIX,justgetflux.com,Proxy
  - DOMAIN-SUFFIX,kat.cr,Proxy
  - DOMAIN-SUFFIX,klip.me,Proxy
  - DOMAIN-SUFFIX,libsyn.com,Proxy
  - DOMAIN-SUFFIX,linode.com,Proxy
  - DOMAIN-SUFFIX,lithium.com,Proxy
  - DOMAIN-SUFFIX,littlehj.com,Proxy
  - DOMAIN-SUFFIX,live.com,Proxy
  - DOMAIN-SUFFIX,live.net,Proxy
  - DOMAIN-SUFFIX,livefilestore.com,Proxy
  - DOMAIN-SUFFIX,llnwd.net,Proxy
  - DOMAIN-SUFFIX,macid.co,Proxy
  - DOMAIN-SUFFIX,macromedia.com,Proxy
  - DOMAIN-SUFFIX,macrumors.com,Proxy
  - DOMAIN-SUFFIX,mashable.com,Proxy
  - DOMAIN-SUFFIX,mathjax.org,Proxy
  - DOMAIN-SUFFIX,medium.com,Proxy
  - DOMAIN-SUFFIX,mega.co.nz,Proxy
  - DOMAIN-SUFFIX,mega.nz,Proxy
  - DOMAIN-SUFFIX,megaupload.com,Proxy
  - DOMAIN-SUFFIX,microsofttranslator.com,Proxy
  - DOMAIN-SUFFIX,mindnode.com,Proxy
  - DOMAIN-SUFFIX,mobile01.com,Proxy
  - DOMAIN-SUFFIX,modmyi.com,Proxy
  - DOMAIN-SUFFIX,msedge.net,Proxy
  - DOMAIN-SUFFIX,myfontastic.com,Proxy
  - DOMAIN-SUFFIX,name.com,Proxy
  - DOMAIN-SUFFIX,nextmedia.com,Proxy
  - DOMAIN-SUFFIX,nsstatic.net,Proxy
  - DOMAIN-SUFFIX,nssurge.com,Proxy
  - DOMAIN-SUFFIX,nyt.com,Proxy
  - DOMAIN-SUFFIX,nytimes.com,Proxy
  - DOMAIN-SUFFIX,omnigroup.com,Proxy
  - DOMAIN-SUFFIX,onedrive.com,Proxy
  - DOMAIN-SUFFIX,onenote.com,Proxy
  - DOMAIN-SUFFIX,ooyala.com,Proxy
  - DOMAIN-SUFFIX,openvpn.net,Proxy
  - DOMAIN-SUFFIX,openwrt.org,Proxy
  - DOMAIN-SUFFIX,orkut.com,Proxy
  - DOMAIN-SUFFIX,osxdaily.com,Proxy
  - DOMAIN-SUFFIX,outlook.com,Proxy
  - DOMAIN-SUFFIX,ow.ly,Proxy
  - DOMAIN-SUFFIX,paddleapi.com,Proxy
  - DOMAIN-SUFFIX,parallels.com,Proxy
  - DOMAIN-SUFFIX,parse.com,Proxy
  - DOMAIN-SUFFIX,pdfexpert.com,Proxy
  - DOMAIN-SUFFIX,periscope.tv,Proxy
  - DOMAIN-SUFFIX,pinboard.in,Proxy
  - DOMAIN-SUFFIX,pinterest.com,Proxy
  - DOMAIN-SUFFIX,pixelmator.com,Proxy
  - DOMAIN-SUFFIX,pixiv.net,Proxy
  - DOMAIN-SUFFIX,playpcesor.com,Proxy
  - DOMAIN-SUFFIX,playstation.com,Proxy
  - DOMAIN-SUFFIX,playstation.com.hk,Proxy
  - DOMAIN-SUFFIX,playstation.net,Proxy
  - DOMAIN-SUFFIX,playstationnetwork.com,Proxy
  - DOMAIN-SUFFIX,pushwoosh.com,Proxy
  - DOMAIN-SUFFIX,rime.im,Proxy
  - DOMAIN-SUFFIX,servebom.com,Proxy
  - DOMAIN-SUFFIX,sfx.ms,Proxy
  - DOMAIN-SUFFIX,shadowsocks.org,Proxy
  - DOMAIN-SUFFIX,sharethis.com,Proxy
  - DOMAIN-SUFFIX,shazam.com,Proxy
  - DOMAIN-SUFFIX,skype.com,Proxy
  - DOMAIN-SUFFIX,smartdnsProxy.com,Proxy
  - DOMAIN-SUFFIX,smartmailcloud.com,Proxy
  - DOMAIN-SUFFIX,sndcdn.com,Proxy
  - DOMAIN-SUFFIX,sony.com,Proxy
  - DOMAIN-SUFFIX,soundcloud.com,Proxy
  - DOMAIN-SUFFIX,sourceforge.net,Proxy
  - DOMAIN-SUFFIX,spotify.com,Proxy
  - DOMAIN-SUFFIX,squarespace.com,Proxy
  - DOMAIN-SUFFIX,sstatic.net,Proxy
  - DOMAIN-SUFFIX,st.luluku.pw,Proxy
  - DOMAIN-SUFFIX,stackoverflow.com,Proxy
  - DOMAIN-SUFFIX,startpage.com,Proxy
  - DOMAIN-SUFFIX,staticflickr.com,Proxy
  - DOMAIN-SUFFIX,steamcommunity.com,Proxy
  - DOMAIN-SUFFIX,symauth.com,Proxy
  - DOMAIN-SUFFIX,symcb.com,Proxy
  - DOMAIN-SUFFIX,symcd.com,Proxy
  - DOMAIN-SUFFIX,tapbots.com,Proxy
  - DOMAIN-SUFFIX,tapbots.net,Proxy
  - DOMAIN-SUFFIX,tdesktop.com,Proxy
  - DOMAIN-SUFFIX,techcrunch.com,Proxy
  - DOMAIN-SUFFIX,techsmith.com,Proxy
  - DOMAIN-SUFFIX,thepiratebay.org,Proxy
  - DOMAIN-SUFFIX,theverge.com,Proxy
  - DOMAIN-SUFFIX,time.com,Proxy
  - DOMAIN-SUFFIX,timeinc.net,Proxy
  - DOMAIN-SUFFIX,tiny.cc,Proxy
  - DOMAIN-SUFFIX,tinypic.com,Proxy
  - DOMAIN-SUFFIX,tmblr.co,Proxy
  - DOMAIN-SUFFIX,todoist.com,Proxy
  - DOMAIN-SUFFIX,trello.com,Proxy
  - DOMAIN-SUFFIX,trustasiassl.com,Proxy
  - DOMAIN-SUFFIX,tumblr.co,Proxy
  - DOMAIN-SUFFIX,tumblr.com,Proxy
  - DOMAIN-SUFFIX,tweetdeck.com,Proxy
  - DOMAIN-SUFFIX,tweetmarker.net,Proxy
  - DOMAIN-SUFFIX,twitch.tv,Proxy
  - DOMAIN-SUFFIX,txmblr.com,Proxy
  - DOMAIN-SUFFIX,typekit.net,Proxy
  - DOMAIN-SUFFIX,ubertags.com,Proxy
  - DOMAIN-SUFFIX,ublock.org,Proxy
  - DOMAIN-SUFFIX,ubnt.com,Proxy
  - DOMAIN-SUFFIX,ulyssesapp.com,Proxy
  - DOMAIN-SUFFIX,urchin.com,Proxy
  - DOMAIN-SUFFIX,usertrust.com,Proxy
  - DOMAIN-SUFFIX,v.gd,Proxy
  - DOMAIN-SUFFIX,v2ex.com,Proxy
  - DOMAIN-SUFFIX,vimeo.com,Proxy
  - DOMAIN-SUFFIX,vimeocdn.com,Proxy
  - DOMAIN-SUFFIX,vine.co,Proxy
  - DOMAIN-SUFFIX,vivaldi.com,Proxy
  - DOMAIN-SUFFIX,vox-cdn.com,Proxy
  - DOMAIN-SUFFIX,vsco.co,Proxy
  - DOMAIN-SUFFIX,vultr.com,Proxy
  - DOMAIN-SUFFIX,w.org,Proxy
  - DOMAIN-SUFFIX,w3schools.com,Proxy
  - DOMAIN-SUFFIX,webtype.com,Proxy
  - DOMAIN-SUFFIX,wikiwand.com,Proxy
  - DOMAIN-SUFFIX,wikileaks.org,Proxy
  - DOMAIN-SUFFIX,wikimedia.org,Proxy
  - DOMAIN-SUFFIX,wikipedia.com,Proxy
  - DOMAIN-SUFFIX,wikipedia.org,Proxy
  - DOMAIN-SUFFIX,windows.com,Proxy
  - DOMAIN-SUFFIX,windows.net,Proxy
  - DOMAIN-SUFFIX,wire.com,Proxy
  - DOMAIN-SUFFIX,wordpress.com,Proxy
  - DOMAIN-SUFFIX,workflowy.com,Proxy
  - DOMAIN-SUFFIX,wp.com,Proxy
  - DOMAIN-SUFFIX,wsj.com,Proxy
  - DOMAIN-SUFFIX,wsj.net,Proxy
  - DOMAIN-SUFFIX,xda-developers.com,Proxy
  - DOMAIN-SUFFIX,xeeno.com,Proxy
  - DOMAIN-SUFFIX,xiti.com,Proxy
  - DOMAIN-SUFFIX,yahoo.com,Proxy
  - DOMAIN-SUFFIX,yimg.com,Proxy
  - DOMAIN-SUFFIX,ying.com,Proxy
  - DOMAIN-SUFFIX,yoyo.org,Proxy
  - DOMAIN-SUFFIX,ytimg.com,Proxy
  - DOMAIN-SUFFIX,telegra.ph,Proxy
  - DOMAIN-SUFFIX,telegram.org,Proxy
  - IP-CIDR,91.108.4.0/22,Proxy
  - IP-CIDR,91.108.8.0/21,Proxy
  - IP-CIDR,91.108.16.0/22,Proxy
  - IP-CIDR,91.108.56.0/22,Proxy
  - IP-CIDR,149.154.160.0/20,Proxy
  - IP-CIDR6,2001:67c:4e8::/48,Proxy
  - IP-CIDR6,2001:b28:f23d::/48,Proxy
  - IP-CIDR6,2001:b28:f23f::/48,Proxy
  - DOMAIN,injections.adguard.org,DIRECT
  - DOMAIN,local.adguard.org,DIRECT
  - DOMAIN-SUFFIX,local,DIRECT
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - IP-CIDR,17.0.0.0/8,DIRECT
  - IP-CIDR,100.64.0.0/10,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,Proxy
EOF
}
create_quanxfile(){
cat > '/var/website/v2/quanx_utf8.conf' <<EOF
;2022-09-26：增加对各个模块的说明(部分内容只适用于 1.1.0 以上版本)
;⚠️注意⚠️: 以下内容中，带“;” “#”的都是注释符号，去掉前面的符号，该行才有效

;general 模块内为一些通用的设置参数项
[general]

;Quantumult X 会对 server_check_url 指定的网址进行相应测试，以确认节点的可用性
;你同样可以在 server_local/remote 中，为节点、订阅单独指定server_check_url参数
;如您为节点单独指定了 url，则所有相关延迟测试中，均会采用此 url 地址
server_check_url= http://www.qualcomm.cn/generate_204
;节点延迟测试超时参数，需小于 5000 毫秒才生效
server_check_timeout=2000

;👍👍👍资源解析器，可用于自定义各类远程资源的转换，如节点，规则 filter，复写 rewrite 等，url 地址可远程，可 本地/iCloud(Quantumult X/Scripts目录);
;下面是我写的一个解析器，具体内容直接参照链接里的使用说明
resource_parser_url= https://fastly.jsdelivr.net/gh/KOP-XIAO/QuantumultX@master/Scripts/resource-parser.js

;👍👍geo_location_checker用于节点页面的节点信息展示，可完整自定义展示内容与方式
; extreme-ip-lookup为Quantumult X 作者提供的示范 api
;geo_location_checker=http://extreme-ip-lookup.com/json/, https://raw.githubusercontent.com/crossutility/Quantumult-X/master/sample-location-with-script.js
;下面是我所使用的 api 及获取、展示节点信息的 js
geo_location_checker=http://ip-api.com/json/?lang=zh-CN, https://raw.githubusercontent.com/KOP-XIAO/QuantumultX/master/Scripts/IP_API.js


;👍👍👍运行模式模块，running_mode_trigger 设置，即根据网络自动切换 分流/直连/全局代理 等模式。
;running-mode-trigger 模式下，跟手动切换直连/全局代理 等效，rewrite/task 模块始终会生效，比 ssid 策略组设置简单，比 ssid-suspend 更灵活。

;running_mode_trigger=filter, filter, asus-5g:all_direct, asus:all_proxy
; 上述写法，前两个 filter 先后表示 在 [数据蜂窝网络] 跟 [一般 Wi-Fi] 下，走 filter(分流)模式，后面则表示在 asus-5g 下切换为全局直连[all_direct]，asus 切换为全局代理[all_proxy]
; 如需使用，相应 SSID 换成你自己 Wi-Fi 名即可

;ssid_suspended_list，让 Quantumult X 在特定 Wi-Fi 网络下暂停工作(仅 task 模块会继续工作)，多个Wi-Fi用“,”连接
;ssid_suspended_list=Asus, Shawn-Wifi

;dns exclusion list中的域名将不使用fake-ip方式. 其它域名则全部采用 fake-ip 及远程解析的模式
;dns_exclusion_list=*.qq.com

;UDP 白名单，留空则默认所有为端口。不在udp白名单列表中的端口，将被丢弃处理（返回 ICMP  “端口不可达” 信息）。
;udp_whitelist=53, 80-427, 444-65535

; UDP Drop名单，同白名单类似，但不会返回 ICMP “端口不可达” 信息
; drop 名单仅处理 whitelist名单中的端口
;udp_drop_list = 1900, 80

# 参数 fallback_udp_policy 仅支持 v1.0.19 以及之后的版本。
# 参数 fallback_udp_policy 的值仅支持末端策略（末端策略为经由规则模块和策略模块后所命中的策略，例如：direct、reject 以及节点；不支持内置策略 proxy 以及其它自定义策略）。
fallback_udp_policy=direct

;下列表中的内容将不经过 QuantumultX的处理，设置后建议重启设备
;excluded_routes= 192.168.0.0/16, 172.16.0.0/12, 100.64.0.0/10, 10.0.0.0/8
;icmp_auto_reply=true

;指定 DoH  请求所使用的 User-Agent
;doh_user_agent=Agent/1.0

;指定服务器测试时所使用的 User-Agent
;server_check_user_agent = Agent/1.0

// 默认当 DNS 层面某domain 被reject时，将返回loopback IP。你可以通过下面的参数
// 修改成为 “no-error-no-answer”，或者 “nxdomain”
;dns_reject_domain_behavior = loopback



[dns]
; 禁用系统 DNS（no-system） 以及 ipv6
;no-system
;no-ipv6
;支持参数 excluded_ssids , included_ssids(1.0.29+) 指定在特定 Wi-Fi下失效/生效

// circumvent-ipv4-answer, circumvent-ipv6-answer 参数
//1、当并发向多个上游 DNS 进行查询时，如响应最快的上游 DNS 抢答的结果命中了该条目，则 Quantumult X Tunnel DNS 模块会等待其他 DNS 服务器的响应结果（如抢答的结果中至少有一个不属于该条目，则不会等待其他 DNS 的响应，此时有效结果采用不属于该条目的所有记录）
//2、如所有上游 DNS 返回的所有结果均命中该条目，则判定为 DNS 查询失败
//3、如配置的上游 DNS 包含有去广告功能的 DNS 服务器，请勿使用该参数
;circumvent-ipv4-answer = 127.0.0.1, 0.0.0.0
;circumvent-ipv6-answer = ::

//如需使用 DoH3，DNS over HTTP/3，请开启下面👇参数
;prefer-doh3

;指定 dns 服务器，并发响应选取最优结果
server=114.114.114.114
server=202.141.176.93 
server=202.141.178.13
server=117.50.10.10
server=223.5.5.5
server=119.29.29.29:53
server=119.28.28.28

;如指定 doh 服务，则👆️上面的一般 dns 解析均失效 额外参数，在特定网络下禁用该 doh
;doh-server=xxx.com, excluded_ssids=SSID1, SSID2
; 1.0.29 版本后支持多个 doh 并发，👇
;doh-server=xx1.com,xx2.com,excluded_ssids=SSID1, SSID2
; 1.0.29 版本后支持 alias 映射类型
;alias=/example.com/another-example.com


;如指定了 DoQ 服务，则 DoH 以及其它 dns解析均失效
;doq-server = quic://dns.adguard.com
;doq-server = quic://dns1.example.com, quic://dns2.example.com
;doq-server = quic://dns.adguard.com, excluded_ssids=SSID1
;doq-server = quic://dns.adguard.com, included_ssids=SSID2



;指定域名解析dns, 下面为示范，按需启用, 同样支持 excluded_ssids/included_ssids 参数
;server=/*.taobao.com/223.5.5.5, excluded_ssids=My-Wifi, Your-Wifi
;server=/*.tmall.com/223.5.5.5, included_ssids=His-Wifi
;server=/example1.com/8.8.4.4
;server=/*.example2.com/223.5.5.5
;server=/example4.com/[2001:4860:4860::8888]:53
;address=/example5.com/192.168.16.18
;address=/example6.com/[2001:8d3:8d3:8d3:8d3:8d3:8d3:8d3]
//映射域名到其它域名的类型
;alias = /example7.com/another-example.com


[task_local]
;包含3⃣️种类型: cron 定时任务，UI交互脚本，网络切换脚本

; 1⃣️ 任务模块，可用于签到,天气话费查询等
;js文件放于iCloud或者本机的Quantumult X/Scripts 路径下。TF版本可直接使用远程js链接
;从 “分” 开始的5位cron 写法，具体 cron 表达式可自行 Google
;比如上述语句 代表每天 12 点 2 分，自动执行一次;
;tag参数为 task 命名标识;
;img-url参数用于指定 task 的图标(108*108)

2 12 * * * sample.js, tag=本地示范(左滑编辑，右滑执行), enabled=false, img-url=https://raw.githubusercontent.com/crossutility/Quantumult-X/master/quantumult-x.png
13 12 * * * https://raw.githubusercontent.com/crossutility/Quantumult-X/master/sample-task.js, tag=远程示范(点击缓存/更新脚本), enabled=false, img-url=https://raw.githubusercontent.com/crossutility/Quantumult-X/master/quantumult-x.png

# 2⃣️ UI交互查询脚本示范，在首页长按 节点/策略组 唤出
event-interaction https://raw.githubusercontent.com/KOP-XIAO/QuantumultX/master/Scripts/streaming-ui-check.js, tag = 流媒体 - 解锁查询，img-url=checkmark.seal.system, enabled=true

# 3⃣️ 网络切换/变化时 触发的脚本类型
;event-network sample-taks.js


#以下为策略组[policy]部分
# static 策略组中，你需要手动选择想要的节点/策略组。
# available 策略组将按顺序选择你列表中第一个可用的节点。
# round-robin 策略组，将按列表的顺序轮流使用其中的节点。
# url-latency-benchmark 延迟策略组，选取延迟最优节点。
# dest-hash 策略组，随机负载均衡，但相同域名走固定节点。
# ssid 策略组，将根据你所设定的网络来自动切换节点/策略组
;img-url 参数用于指定策略组图标，可远程，也可本地/iCloud(Quantumult X/Images路径下) （108*108 大小）
;direct/proxy/reject 则只能用本地图标，名字分别为 direct.png, proxy.png,reject.png 放置于 Images 文件夹下即可生效 (108*108 大小)

[policy]
static=🍎 苹果服务, direct, proxy, img-url= https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Apple.png
static=💻 国外影视, proxy, direct, img-url= https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/ForeignMedia.png
static=📽 国内视频, direct, proxy, img-url= https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/DomesticMedia.png
static=🎬 YouTube, proxy, direct, img-url= https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/YouTube.png
static=📺 Netflix, proxy, direct, img-url= https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Netflix_Letter.png
static=🌏 国外网站, proxy,direct,🇭🇰️ 香港(正则示范), img-url= https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Global.png
static=🕹 终极清单,direct, proxy, img-url= https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Final.png
static= 🇭🇰️ 香港(正则示范), server-tag-regex= 香港|🇭🇰️|HK|Hong, img-url=https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/HK.png

#server-tag-regex 以及 resource-tag-regex 参数用于正则筛选来建立策略组
#具体可参见教程部分: https://shrtm.nu/DAFP

#以下是quantumultX的3普通种策略组类型写法，也可以用正则参数 server-tag-regex 或者 resource-tag-regex 来筛选
;static=policy-name-1, Sample-A, Sample-B, Sample-C
;available=policy-name-2, Sample-A, Sample-B, Sample-C
;round-robin=policy-name-3, Sample-A, Sample-B, Sample-C
;url-latency-benchmark=policy-name-4, Sample-A, Sample-B, Sample-C
;dest-hash=policy-name-5, Sample-A, Sample-B, Sample-C
#下面是ssid策略组示范
;ssid=policy-name-4, Sample-A, Sample-B, LINK_22E171:Sample-B, LINK_22E172:Sample-C


# "tag" 跟 "enabled" 为可选参数，分别表示 “标签”及“开启状态”, true 为开启，false 关闭.
# update-interval 为更新时间参数，单位 秒, 默认更新时间为 24*60*60=86400 秒，也就是24小时.
# opt-parser=true/false 用于控制是否对本订阅 开启资源解析器，不写或者 false 表示不启用解析器;

#服务器远程订阅
[server_remote]
#远程服务器订阅模块，可直接订阅SSR，SS链接，以及Quantumult X格式的vmess/trojan/https订阅
#其它格式可用 opt-parser 参数开启解析器导入使用
#img-url参数用于指定图标，格式要求同样为 108*108 的 png 图片，可远程，可本地
# https://raw.githubusercontent.com/crossutility/Quantumult-X/master/server.snippet#rename=[香港], tag=URI格式示范(请导入自己订阅), update-interval=86400, opt-parser=true,  img-url=https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Quantumult_X.png, enabled=true
# https://raw.githubusercontent.com/crossutility/Quantumult-X/master/server-complete.snippet, tag=QuanX格式示范(导入后删除这两个示范),  img-url=https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Quantumult_X.png, enabled=true

#支持本地/iCloud的节点文件/片段，位于Quantumult X/Profiles路径下
;servers.snippet, tag=本地服务器, img-url=https://raw.githubusercontent.com/crossutility/Quantumult-X/master/quantumult-x.png, enabled=false

#规则分流远程订阅
[filter_remote]
#远程分流模块，可使用force-policy来强制使用策略偏好, 替换远程规则内所指定的策略组
;同样的
# update-interval 为更新时间参数，单位 秒, 默认更新时间为 24*60*60=86400 秒，也就是24小时.
# opt-parser=true/false 用于控制是否对本订阅 开启资源解析器，不写或者 false 表示不启用解析器;

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/Guard/Advertising.list, tag=🚦去广告, update-interval=86400, opt-parser=true, enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/Guard/Hijacking.list, tag=🚫 运营商劫持, enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/StreamingMedia/StreamingCN.list, force-policy=📽 国内视频, tag=📽 国内视频, enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/StreamingMedia/Video/Netflix.list, tag=📺 Netflix, force-policy=📺 Netflix, enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/StreamingMedia/Video/YouTube.list, tag=🎬 YouTube, force-policy=🎬 YouTube, enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/StreamingMedia/Streaming.list, tag=💻 国外影视,force-policy= 💻 国外影视, enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/Global.list, tag=🌍 国外网站, force-policy= 🌏 国外网站, enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/Extra/Apple/Apple.list, tag= Apple服务, force-policy=🍎 苹果服务,enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/Extra/Apple/BlockiOSUpdate.list, tag= 屏蔽更新,enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/China.list, tag=🐼 国内网站, enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Filter/Extra/ChinaIP.list, tag=🇨🇳️ 国内IP池, enabled=true

#支持本地/iCloud规则文件，位于Quantumult X/Profiles路径下
;filter.txt, tag=本地分流, enabled=false

#rewrite 复写远程订阅
[rewrite_remote]
#远程复写模块，内包含主机名hostname以及复写rewrite规则
# update-interval 为更新时间参数，单位 秒, 默认更新时间为 24*60*60=86400 秒，也就是24小时.
# opt-parser=true/false 用于控制是否对本订阅 开启资源解析器，不写或者 false 表示不启用解析器;


https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Rewrite/Block/Advertising.conf, tag=神机复写(⛔️去广告), update-interval=86400, opt-parser=false, enabled=true

https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Rewrite/General.conf, tag=神机复写(😄️通用), update-interval=86400, opt-parser=false, enabled=true

;Youtube premium 会员请勿开启此条
https://raw.githubusercontent.com/DivineEngine/Profiles/master/Quantumult/Rewrite/Block/YouTubeAds.conf, tag=神机复写(🈲YouTube-AD) , update-interval=86400, opt-parser=false, enabled=false

#支持本地/iCloud的复写规则文件，位于Quantumult X/Profiles路径下
;rewrite.txt, tag=本地复写, opt-parser=false, enabled=false

# 本地服务器部分
[server_local]
# 以下示范都是 ip(域名):端口，
# 比如 vmess-a.203.167.55.4:777 ，实际是 203.167.55.4:777
# 前面的 ss-a，ws-tls这些，只是为了让你快速找到自己节点的类型
# 实际使用时，请不要真的 傻乎乎的 写 vmess-a.203.167.55.4:777 这种。
# 目前支持 shadowsocks/shadowsocksR/Vmess/Trojan/http(s)/Socks5 等类型
# 支持 tls-cert-sha256 以及 tls-pubkey-sha256 参数等自定义TLS验证

#shadowsocks以及shadowsocksR类型, 支持 V2-Plugin
#支持UDP，支持UDP-OVER-TCP（版本1.0.29 665+）
;shadowsocks=ss-a.example.com:80, method=chacha20, password=pwd, obfs=http, obfs-host=bing.com, obfs-uri=/resource/file, fast-open=false, udp-relay=false, server_check_url=http://www.apple.com/generate_204, tag=Sample-A
;shadowsocks=ss-b.example.com:80, method=chacha20, password=pwd, obfs=http, obfs-host=bing.com, obfs-uri=/resource/file, fast-open=false, udp-relay=false, tag=Sample-B
;shadowsocks=ss-c.example.com:443, method=chacha20, password=pwd, obfs=tls, obfs-host=bing.com, fast-open=false, udp-relay=false, tag=Sample-C
;shadowsocks=ssr-a.example.com:443, method=chacha20, password=pwd, ssr-protocol=auth_chain_b, ssr-protocol-param=def, obfs=tls1.2_ticket_fastauth, obfs-host=bing.com, tag=Sample-D
;shadowsocks=ws-a.example.com:80, method=aes-128-gcm, password=pwd, obfs=ws, obfs-uri=/ws, fast-open=false, udp-relay=false, tag=Sample-E
;shadowsocks=ws-b.example.com:80, method=aes-128-gcm, password=pwd, obfs=ws, fast-open=false, udp-relay=false, tag=Sample-F
;shadowsocks=ws-tls-a.example.com:443, method=aes-128-gcm, password=pwd, obfs=wss, obfs-uri=/ws, fast-open=false, udp-relay=false, tag=Sample-G
;shadowsocks=ws-tls-a.example.com:443, method=aes-128-gcm, password=pwd, udp-over-tcp=true fast-open=false, udp-relay=false, tag=Sample-H

# vmess 类型，ws，wss(ws+tls),over-tls,tcp，支持 UDP
# vmess 类型节点默认开启 aead，关闭请用 aead=false
; ws 类型
;vmess=ws-c.example.com:80, method=chacha20-ietf-poly1305, password= 23ad6b10-8d1a-40f7-8ad0-e3e35cd32291, obfs-host=ws-c.example.com, obfs=ws, obfs-uri=/ws, fast-open=false, udp-relay=false, aead=false, tag=Sample-H
; wss(ws+tls) 类型
;vmess=ws-tls-b.example.com:443, method=chacha20-ietf-poly1305, password= 23ad6b10-8d1a-40f7-8ad0-e3e35cd32291, obfs-host=ws-tls-b.example.com, obfs=wss, obfs-uri=/ws, tls-verification=true,fast-open=false, udp-relay=false, tag=Sample-I
; http 类型
;vmess=example.com:80, method=chacha20-poly1305, password=23ad6b10-8d1a-40f7-8ad0-e3e35cd32291, obfs=http, obfs-host=bing.com, obfs-uri=/resource/file, fast-open=false, udp-relay=false, server_check_url=http://www.apple.com/generate_204, tag=vmess-http
; tcp 类型
;vmess=vmess-a.example.com:80, method=aes-128-gcm, password=23ad6b10-8d1a-40f7-8ad0-e3e35cd32291, fast-open=false, udp-relay=false, tag=Sample-J
;vmess=vmess-b.example.com:80, method=none, password=23ad6b10-8d1a-40f7-8ad0-e3e35cd32291, fast-open=false, udp-relay=false, tag=Sample-K
; over-tls 类型
;vmess=vmess-over-tls.example.com:443, method=none, password=23ad6b10-8d1a-40f7-8ad0-e3e35cd32291, obfs-host=vmess-over-tls.example.com, obfs=over-tls, tls-verification=true, fast-open=false, udp-relay=false, tag=Sample-L

; http(s) 类型
;http=http.example.com:80, username=name, password=pwd, fast-open=false, udp-relay=false, tag=http
;http=https.example.com:443, username=name, password=pwd, over-tls=true, tls-verification=true, tls-host=example.com, tls-verification=true, fast-open=false, udp-relay=false, tag=http-tls

# socks5 类型节点
;socks5=example.com:80,fast-open=false, udp-relay=false, tag=socks5-01
;socks5=example.com:80, username=name, password=pwd, fast-open=false, udp-relay=false, tag=socks5-02
;socks5=example.com:443, username=name, password=pwd, over-tls=true, tls-host=example.com, tls-verification=true, fast-open=false, udp-relay=false, tag=socks5-tls-01
;socks5=example.com:443, username=name, password=pwd, over-tls=true, tls-host=example.com, tls-verification=true, tls-pubkey-sha256=eb5ec6684564fd0d04975903ed75342d1b9fdc2096ea54b4cf8caf4740f4ae25, fast-open=false, udp-relay=false, tag=socks5-tls-02

; trojan 类型, 支持 over-tls 以及 websockets，支持 UDP
;trojan=example.com:443, password=pwd, over-tls=true, tls-verification=true, fast-open=false, udp-relay=true, tag=trojan-tls-01
trojan=${domain}:443, password=${passwd}, over-tls=true, tls-host=${domain}, tls-verification=true, fast-open=false, udp-relay=false, tag=${domain}
;trojan=192.168.1.1:443, password=pwd, obfs=wss, obfs-host=example.com, obfs-uri=/path, udp-relay=true, tag=trojan-wss-05


#本地分流规则(对于完全相同的某条规则，本地的将优先生效)
[filter_local]
// 如开启其他设置中的  “分流匹配优化” 选项，则匹配优先级为👇

// host > host-suffix > host-keyword(wildcard) > geoip = ip-cidr > user-agennt

// 完整域名匹配
;host, www.google.com, proxy
// 域名关键词匹配
;host-keyword, adsite, reject
// 域名后缀匹配
;host-suffix, googleapis.com, proxy
// 域名通配符匹配
;host-wildcard, *abc.com, proxy

// User-Agent 匹配
;user-agent, ?abc*, proxy


//强制分流走蜂窝网络
;host-suffix, googleapis.com, proxy, force-cellular
//让分流走蜂窝网络跟 Wi-Fi 中的优选结果
;host-suffix, googleapis.com, proxy, multi-interface
//让分流走蜂窝网络跟 Wi-Fi 中的负载均衡，提供更大带宽出入接口
;host-suffix, googleapis.com, proxy, multi-interface-balance
//指定分流走特定网络接口
;host-suffix, googleapis.com, proxy, via-interface=pdp_ip0

// %TUN% 参数，回传给 Quantumult X 接口，可用于曲线实现代理链功能
;host-suffix, example.com, ServerA, via-interface=%TUN%
;ip-cidr, ServerA's IP Range, ServerB

// ip 规则
ip-cidr, 10.0.0.0/8, direct
ip-cidr, 127.0.0.0/8, direct
ip-cidr, 172.16.0.0/12, direct
ip-cidr, 192.168.0.0/16, direct
ip-cidr, 224.0.0.0/24, direct
//ipv6 规则
;ip6-cidr, 2001:4860:4860::8888/32, direct
# 已采用 ip 池数据，因此注释掉 geoip cn
;geoip, cn, direct

# 1.0.28 build628 后支持如下的geoip库写法（需 GEO-IP 库支持）
;geoip, netflix, proxy

#不在上述规则中(远程以及本地)的剩余请求，将走final 指定的节点/策略，这里即是 → 🕹 终极清单, 请根据自己的需求来选择直连或节点、策略
final, 🕹 终极清单


#本地复写规则
[rewrite_local]

#以下为证书&主机名部分
[mitm]
;以下模块去掉;才生效
;请自行在 APP 的UI中 生成证书 并安装&信任（💡请按确保照文字提示操作💡）
;skip_validating_cert = false
;force_sni_domain_name = false

//当使用 Quantumult X 在 M 芯片的 Mac 设备上作为局域网网关时，使用下面的参数来 跳过某些特定设备的 mitm 需求
;skip_src_ip = 192.168.4.50, 92.168.4.51

// 当多个不同的 TCP 连接（非域名类请求）的目标 IP 不同，但这些连接的 TSL 握手 SNI 字段相同时，如需跳过其中某些连接的 MitM hostname 匹配过程，可使用👇参数。
;skip_dst_ip = 123.44.55.4

;hostname 为主机名，用,分隔多个
;hostname = *.example.com, *.sample.com

//以下为证书参数，可去UI界面自行生成并安装证书，会在此生成对应信息
;passphrase = 
;p12 = 
EOF
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


echo -ne "${cyan}请手动确定类型${none}\n"
echo -ne "${cyan}1.安装汉字工具包等${none}\n"
echo -ne "${cyan}2.安装go环境${none}\n"
echo -ne "${cyan}3.安装并构建caddy${none}\n"
echo -ne "${cyan}4.构建caddy配置文件${none}\n"
echo -ne "${cyan}5.构建clash配置文件${none}\n"
echo -ne "${cyan}6.运行caddy\n>> ${none}"
read  step
case "$step" in 
  0)  update
      install_go
      install_xcaddy
      build_caddy
      create_caddyfile
      create_clashfile
      run
      ;;
  1)  update
      ;;
  2)  install_go
      ;;
  3)  install_xcaddy
      build_caddy
      ;;
  4)  create_caddyfile
      ;;
  5)  create_clashfile
      ;;
  6)  run
      ;;
esac
