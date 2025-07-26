#!/bin/sh

set -e

sleep 2

NG_ACME=~/.acme.sh/acme.sh
NG_SSL=/etc/nginx/ssl
NG_CONF=/etc/nginx/nginx.conf
NG_HTTP_UPGRADE='$http_upgrade'
NG_HOST='$host'
NG_REMOTE='$remote_addr'
NG_FORWARD='$proxy_add_x_forwarded_for'
NG_CF='$http_cf_connecting_ip'
NG_SCHEME='$scheme'
CF_Token=$(echo "$CLOUDFLARE" | base64 -d)

CURRENT_IP=$(curl -fsSL https://ipinfo.io/ip)
CF_DOMAIN=$(curl -fsSL "https://api.cloudflare.com/client/v4/zones" \
    -H "Authorization: Bearer $CF_Token" \
    -H "Content-Type: application/json" | \
    grep -o '"name":"[^"]*' | cut -d'"' -f4 | head -n 1)
CF_Zone_ID=$(curl -fsSL "https://api.cloudflare.com/client/v4/zones" \
    -H "Authorization: Bearer $CF_Token" \
    -H "Content-Type: application/json" | \
    grep -o '"id":"[^"]*' | cut -d'"' -f4 | head -n 1)
CF_RECORD=$(curl -fsSL "https://api.cloudflare.com/client/v4/zones/$CF_Zone_ID/dns_records?name=${SERVICE_NAME}.${CF_DOMAIN}" \
    -H "Authorization: Bearer $CF_Token" \
    -H "Content-Type: application/json" | \
    grep -o '"id":"[^"]*' | cut -d'"' -f4 | head -n 1)

if [ -n "$CF_RECORD" ]; then
    echo "DNS record found. Modifying the existing DNS record..."
    curl -sX PUT "https://api.cloudflare.com/client/v4/zones/$CF_Zone_ID/dns_records/$CF_RECORD" \
        -H "Authorization: Bearer $CF_Token" \
        -H "Content-Type: application/json" \
        -d '{
            "type": "A",
            "name": "'"$SERVICE_NAME.$CF_DOMAIN"'",
            "content": "'"$CURRENT_IP"'",
            "proxied": false
        }'
else
    echo "DNS record not found. Creating a new DNS record..."
    curl -sX POST "https://api.cloudflare.com/client/v4/zones/$CF_Zone_ID/dns_records" \
        -H "Authorization: Bearer $CF_Token" \
        -H "Content-Type: application/json" \
        -d '{
            "type": "A",
            "name": "'"$SERVICE_NAME.$CF_DOMAIN"'",
            "content": "'"$CURRENT_IP"'",
            "proxied": false
        }'
fi

export CF_Token="$CF_Token"
export CF_Zone_ID="$CF_Zone_ID"
FULL_DOMAIN="$SERVICE_NAME.$CF_DOMAIN"
SSL_KEY="$NG_SSL/$FULL_DOMAIN.key"
SSL_FULL_CHAIN="$NG_SSL/$FULL_DOMAIN.pem"
SSL_DHPARAM="$NG_SSL/$FULL_DOMAIN.dpr"

if [ -z "$CURRENT_IP" ]; then
    echo "Error: Failed to get current IP address"
    exit 1
fi

if [ -z "$CF_Zone_ID" ]; then
    echo "Error: Unable to retrieve Cloudflare zone ID for domain $CF_DOMAIN."
    exit 1
fi

echo "[INFO] $FULL_DOMAIN Cloudflare $CURRENT_IP set!"
mkdir -p /var/log/nginx
mkdir -p /etc/nginx/conf.d
mkdir -p /etc/nginx/service.d
mkdir -p /etc/nginx/html

cat <<'EOF' | tee /etc/nginx/conf.d/gzip.conf
types_hash_max_size 2048;
server_names_hash_bucket_size 256;

gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_disable "msie6";
gzip_min_length 200;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css text/xml text/javascript application/json application/javascript  application/xml application/xml+rss application/sla application/vnd.ms-pki.stl;
EOF

cat <<'EOF' | tee /etc/nginx/conf.d/log.conf
access_log /var/log/nginx/access.log;
error_log /var/log/nginx/error.log;
log_format main '$remote_addr - $remote_user [$time_local] '
                '"$request" $status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for"';
EOF

cat <<'EOF' | tee /etc/nginx/conf.d/tcp.conf
sendfile on;
tcp_nopush on;
tcp_nodelay on;
port_in_redirect off;
server_name_in_redirect on;
keepalive_timeout 65;
real_ip_header proxy_protocol;
EOF

cat <<'EOF' | tee /etc/nginx/conf.d/ssl.conf
server_tokens off;
ssl_prefer_server_ciphers off;
ssl_protocols TLSv1.3 TLSv1.2;
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:MozSSL:10m;
ssl_session_tickets off;
ssl_session_timeout 21h;
ssl_stapling on;
ssl_stapling_verify on;
ssl_buffer_size 4k;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
EOF

cat <<EOF | tee /etc/nginx/mime.types
types {
    text/html                             html htm shtml;
    text/css                              css;
    text/xml                              xml;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    application/javascript                js;
    application/atom+xml                  atom;
    application/rss+xml                   rss;

    text/mathml                           mml;
    text/plain                            txt;
    text/vnd.sun.j2me.app-descriptor      jad;
    text/vnd.wap.wml                      wml;
    text/x-component                      htc;

    image/png                             png;
    image/tiff                            tif tiff;
    image/vnd.wap.wbmp                    wbmp;
    image/x-icon                          ico;
    image/x-jng                           jng;
    image/x-ms-bmp                        bmp;
    image/svg+xml                         svg svgz;
    image/webp                            webp;

    application/font-woff                 woff;
    application/java-archive              jar war ear;
    application/json                      json;
    application/mac-binhex40              hqx;
    application/msword                    doc;
    application/pdf                       pdf;
    application/postscript                ps eps ai;
    application/rtf                       rtf;
    application/vnd.apple.mpegurl         m3u8;
    application/vnd.ms-excel              xls;
    application/vnd.ms-fontobject         eot;
    application/vnd.ms-powerpoint         ppt;
    application/vnd.wap.wmlc              wmlc;
    application/vnd.google-earth.kml+xml  kml;
    application/vnd.google-earth.kmz      kmz;
    application/x-7z-compressed           7z;
    application/x-cocoa                   cco;
    application/x-java-archive-diff       jardiff;
    application/x-java-jnlp-file          jnlp;
    application/x-makeself                run;
    application/x-perl                    pl pm;
    application/x-pilot                   prc pdb;
    application/x-rar-compressed          rar;
    application/x-redhat-package-manager  rpm;
    application/x-sea                     sea;
    application/x-shockwave-flash         swf;
    application/x-stuffit                 sit;
    application/x-tcl                     tcl tk;
    application/x-x509-ca-cert            der pem crt;
    application/x-xpinstall               xpi;
    application/xhtml+xml                 xhtml;
    application/xspf+xml                  xspf;
    application/zip                       zip;

    application/octet-stream              bin exe dll;
    application/octet-stream              deb;
    application/octet-stream              dmg;
    application/octet-stream              iso img;
    application/octet-stream              msi msp msm;

    application/vnd.openxmlformats-officedocument.wordprocessingml.document    docx;
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet          xlsx;
    application/vnd.openxmlformats-officedocument.presentationml.presentation  pptx;

    audio/midi                            mid midi kar;
    audio/mpeg                            mp3;
    audio/ogg                             ogg;
    audio/x-m4a                           m4a;
    audio/x-realaudio                     ra;

    video/3gpp                            3gpp 3gp;
    video/mp2t                            ts;
    video/mp4                             mp4;
    video/mpeg                            mpeg mpg;
    video/quicktime                       mov;
    video/webm                            webm;
    video/x-flv                           flv;
    video/x-m4v                           m4v;
    video/x-mng                           mng;
    video/x-ms-asf                        asx asf;
    video/x-ms-wmv                        wmv;
    video/x-msvideo                       avi;
}
EOF

if [ ! -e $NG_CONF ]; then
    cat <<EOF | tee $NG_CONF
        daemon off;
        worker_processes 1;
        error_log stderr notice;
        pid /run/nginx.pid;

        events {
            accept_mutex off;
            worker_connections 2048;
            multi_accept on;
            use epoll;
        }

        http {
            charset utf-8;
            include /etc/nginx/mime.types;
            default_type application/octet-stream;
            include /etc/nginx/conf.d/*.conf;
            include /etc/nginx/service.d/*.conf;
        }
EOF

    if [ -n "$CF_DOMAIN" ]; then
        if [ -n "$SERVICE_HOST" ] && [ -n "$SERVICE_PORT" ]; then
            cat <<EOF | tee /etc/nginx/service.d/"$FULL_DOMAIN.conf"
                server
                {
                    listen                          443 ssl;
                    http2 on;
                    server_name             ${FULL_DOMAIN};
                    ssl_certificate         ${SSL_FULL_CHAIN};
                    ssl_certificate_key     ${SSL_KEY};
                    ssl_dhparam             ${SSL_DHPARAM};

                    resolver 8.8.8.8 1.1.1.1;

                    client_max_body_size 100M;
                    client_body_buffer_size 70m;

                    location / {
                        proxy_pass http://${SERVICE_HOST}:${SERVICE_PORT}/;
                        proxy_redirect off;
                        proxy_buffering off;
                        proxy_request_buffering off;
                        proxy_http_version 1.1;

                        proxy_set_header Upgrade ${NG_HTTP_UPGRADE};
                        proxy_set_header Connection "upgrade";
                        proxy_set_header Host ${NG_HOST};
                        proxy_set_header X-Real-IP ${NG_REMOTE};
                        proxy_set_header X-Forwarded-For ${NG_FORWARD};
                        proxy_set_header X-Forwarded-Proto ${NG_SCHEME};
                        proxy_set_header CF-Connecting-IP ${NG_CF};
                    }

                    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
                    add_header Referrer-Policy no-referrer-when-downgrade;
                    add_header X-Frame-Options "SAMEORIGIN";
                    add_header X-Content-Type-Options "nosniff";
                    add_header X-XSS-Protection "1; mode=block";
                    set_real_ip_from 127.0.0.1;
                    real_ip_header X-Forwarded-For;
                    real_ip_recursive on;
                }
EOF
        fi
        echo "Applying acme for $FULL_DOMAIN ..."
        if [ ! -e "$SSL_FULL_CHAIN" ]; then
            mkdir -p $NG_SSL
        fi

        if [ ! -e $NG_ACME ]; then
            curl https://get.acme.sh | sh -s email="admin@$CF_DOMAIN"
        fi

        if [ -e $NG_ACME ]; then
            $NG_ACME --upgrade --auto-upgrade
            $NG_ACME --issue -d "$FULL_DOMAIN" --server letsencrypt --dns dns_cf -k ec-256
            $NG_ACME --install-cert -d "$FULL_DOMAIN" \
                --key-file       "$SSL_KEY"  \
                --fullchain-file "$SSL_FULL_CHAIN" \
                --dns dns_cf --ecc
            openssl dhparam -dsaparam -out "$SSL_DHPARAM" 4096
            $NG_ACME --install-cronjob
        fi
    fi
fi

if [ ! -e "/usr/bin/run-nginx" ]; then
    # echo "nginx || sleep 10000" > "/usr/bin/run-nginx"
    echo "nginx" > "/usr/bin/run-nginx"
    chmod +x "/usr/bin/run-nginx"
fi

exec "$@"