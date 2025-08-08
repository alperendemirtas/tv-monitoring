#!/bin/bash

echo "🔄 Basit güncelleme başlıyor..."

# Proje dizinine git
cd /# API sunucusunu başlat ve etkinleştir
echo "🚀 API sunucusu başlatılıyor (.env sistemi)..."
cd api
npm install
cd ..
sudo systemctl start tv-monitoring-api
sudo systemctl enable tv-monitoring-api

echo "✅ Güncelleme tamamlandı!"
echo "🌐 Site adresi: http://10.10.11.164"
echo "🎉 Sistem artık .env dosyası tabanlı çalışıyor - Tüm cihazlarda senkronize!"w/tv-monitoringh

echo "🔄 Basit güncelleme başlıyor..."

# Proje dizinine# API sunucusunu başlat - .env sistemi
echo "� API sunucusu başlatılıyor (.env sistemi)..."
sudo systemctl start tv-monitoring-api
sudo systemctl enable tv-monitoring-api

echo "🎉 Sistem artık .env dosyası tabanlı çalışıyor - Tüm cihazlarda senkronize!"d /var/www/tv-monitoring

# Git güncellemesi
echo "📥 Git'den son değişiklikleri çekiyor..."
git pull origin main

# Node modüllerini güncelle
echo "📦 Bağımlılıkları güncelleniyor..."
npm install

# Projeyi build et
echo "🏗️ Proje build ediliyor..."
npm run build

# Build klasörünü kopyala
echo "📁 Build dosyaları Nginx dizinine kopyalanıyor..."
sudo cp -r dist/* /var/www/html/

# Nginx config'i güncelle
echo "🔧 Nginx config güncelleniyor..."
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

# Nginx restart
echo "🔄 Nginx yeniden başlatılıyor..."
sudo systemctl restart nginx

echo "✅ Güncelleme tamamlandı!"
echo "🌐 Site adresi: http://10.10.11.164"

# API sunucusunu başlat
echo "� API sunucusu başlatılıyor..."
sudo systemctl start tv-monitoring-api
sudo systemctl enable tv-monitoring-api

echo "🎉 Sistem artık sunucu tabanlı çalışıyor - Tüm cihazlarda senkronize!"
