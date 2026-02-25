#!/bin/sh

# === 1. Gera env.js (URL vazia = proxy no mesmo domínio, evita CORS) ===
ENV_FILE="/usr/share/nginx/html/env.js"
echo ">>> Gerando $ENV_FILE..."
cat <<EOF > "$ENV_FILE"
window._env_ = {
  REACT_APP_CHATWOOT_URL: "",
  REACT_APP_CHATWOOT_TOKEN: "${REACT_APP_CHATWOOT_TOKEN}",
  REACT_APP_CHATWOOT_ACCOUNT_ID: "${REACT_APP_CHATWOOT_ACCOUNT_ID}",
  REACT_APP_DEBUG: "${REACT_APP_DEBUG}"
};
EOF
cat "$ENV_FILE"

# === 2. Gera nginx.conf com proxy reverso para Chatwoot ===
NGINX_CONF="/etc/nginx/conf.d/default.conf"
BACKEND="${CHATWOOT_BACKEND_URL:-http://localhost}"
echo ">>> Gerando $NGINX_CONF com proxy para $BACKEND..."
cat <<EOF > "$NGINX_CONF"
underscores_in_headers on;

server {
    listen 3000;
    server_name localhost;

    # Nunca cachear env.js (muda a cada deploy)
    location = /env.js {
        root   /usr/share/nginx/html;
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0";
        add_header Pragma "no-cache";
        etag off;
    }

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }

    # Proxy reverso para API do Chatwoot (evita CORS)
    location /api/ {
        proxy_pass ${BACKEND}/api/;
        proxy_set_header Host chatwoot.zippydigital.com.br;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_connect_timeout 30s;
        proxy_read_timeout 60s;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF
cat "$NGINX_CONF"

# === 3. Inicia Nginx ===
echo ">>> Iniciando Nginx..."
exec nginx -g "daemon off;"