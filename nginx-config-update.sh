#!/bin/bash

echo "🔧 Nginx yapılandırması güncelleniyor..."

# Nginx config dosyasını güncelle
sudo tee /etc/nginx/sites-available/tv-monitoring > /dev/null << 'EOF'
server {
    listen 80;
    server_name 10.10.11.164;
    
    # Ana React uygulaması
    location / {
        root /var/www/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # API proxy - port 3001'i Nginx üzerinden erişilebilir yap
    location /api/config {
        proxy_pass http://localhost:3001/api/config;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Sensibo API proxy (mevcut)
    location /api/sensibo/ {
        proxy_pass https://home.sensibo.com/api/v2/;
        proxy_set_header Host home.sensibo.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_ssl_verify off;
    }
}
EOF

echo "✅ Nginx config güncellendi"

# Nginx'i test et ve yeniden başlat
echo "🧪 Nginx yapılandırması test ediliyor..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx yapılandırması geçerli"
    echo "🔄 Nginx yeniden başlatılıyor..."
    sudo systemctl restart nginx
    echo "🎉 Nginx güncellendi! Artık /api/config endpoint'i çalışacak"
else
    echo "❌ Nginx yapılandırmasında hata var!"
fi
