#!/usr/bin/env bash
# The site as xty serves it (enc's elcubodeedgar.hhefesto.dev vhost: static
# files, the COOP/COEP headers SharedArrayBuffer needs, the tables sent as
# brotli, /api/ to the solver on delfos), on 127.0.0.1:PORT, with a user's
# nginx, for tests. A thin shim: writes the config, runs nginx in the
# foreground.
#
#   probe/site-test.sh WWW PORT [API]      (API: 127.0.0.1:8093, delfos's page server)
set -eu
WWW=$1
PORT=$2
API=${3:-127.0.0.1:8093}
D=$(mktemp -d /tmp/elcubo-nginx.XXXXXX)
NGINX=${NGINX:-$(nix build --no-link --print-out-paths nixpkgs#nginx)}
# the MIME types xty has (mailcap's: .mjs is text/javascript)
MAILCAP=${MAILCAP:-$(nix build --no-link --print-out-paths nixpkgs#mailcap)}
mkdir -p "$D/logs"
cat > "$D/nginx.conf" <<EOF
daemon off;
error_log $D/logs/error.log;
pid $D/nginx.pid;
events {}
http {
  include $MAILCAP/etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log $D/logs/access.log;
  client_body_temp_path $D; proxy_temp_path $D; fastcgi_temp_path $D; uwsgi_temp_path $D; scgi_temp_path $D;
  gzip on;
  gzip_types application/javascript text/html text/css application/json;
  gzip_min_length 1000;
  server {
    listen 127.0.0.1:$PORT;
    root $WWW;
    etag off;
    if_modified_since off;
    add_header Cross-Origin-Opener-Policy same-origin always;
    add_header Cross-Origin-Embedder-Policy require-corp always;
    add_header Cross-Origin-Resource-Policy same-origin always;
    add_header X-Content-Type-Options nosniff always;
    location / { expires 5m; }
    location = / { expires -1; }
    location = /index.html { expires -1; }
    location = /tables.json { expires -1; }
    location /t/ {
      expires max;
      gzip off;
      add_header Cross-Origin-Opener-Policy same-origin always;
      add_header Cross-Origin-Embedder-Policy require-corp always;
      add_header Cross-Origin-Resource-Policy same-origin always;
      add_header X-Content-Type-Options nosniff always;
      location ~ \.br\$ {
        types {}
        default_type application/octet-stream;
        expires max;
        gzip off;
        add_header Content-Encoding br always;
        add_header Cross-Origin-Opener-Policy same-origin always;
        add_header Cross-Origin-Embedder-Policy require-corp always;
        add_header Cross-Origin-Resource-Policy same-origin always;
        add_header X-Content-Type-Options nosniff always;
      }
    }
    location /api/ { proxy_pass http://$API; proxy_read_timeout 300s; }
  }
}
EOF
echo "nginx: $NGINX, config: $D/nginx.conf"
exec "$NGINX/bin/nginx" -p "$D" -c "$D/nginx.conf"
