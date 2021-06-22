#!/bin/sh

# Download and install XRay
mkdir /tmp/xray
curl -L -H "Cache-Control: no-cache" -o /tmp/xray/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip /tmp/xray/xray.zip -d /tmp/xray
install -m 755 /tmp/xray/xray /usr/local/bin/xray
xray -version

# Remove xray temporary directory
rm -rf /tmp/xray

# XRay new configuration
install -d /usr/local/etc/xray
cat << EOF > /usr/local/etc/xray/config.json
{
    "inbounds": [
        {        
            "listen": "/etc/caddy/vless",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$ID", 
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "love@v2fly.org"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "allowInsecure": false,
                "wsSettings": {
                  "acceptProxyProtocol": false,
                  "path": "/$ID-vless?ed=2048"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ],
    "dns": {
        "servers": [
            "1.1.1.1"
        ]
    }
}
EOF

# Config Caddy
sed -e "/^#/d"\
    -e "1c :$PORT"
    -e "s/\$ID/$ID/g" 
    -e "s/\$MYUUID-HASH/$(caddy hash-password --plaintext $ID)/g"
    -e "$s"\
    /etc/nginx.conf > /etc/nginx/nginx.conf
echo /etc/nginx/nginx.conf
cat /etc/nginx/nginx.conf

# Run XRay
tor & /usr/local/bin/xray -config /usr/local/etc/xray/config.json & nginx -g 'daemon off;'
