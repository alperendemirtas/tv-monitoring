#!/bin/bash

echo "🔄 PHP tabanlı güncelleme başlıyor..."

# Proje dizinine git
cd /var/www/tv-monitoring

# Git güncellemesi
echo "📥 Git'den son değişiklikleri çekiyor..."
git pull origin main

# React bağımlılıklarını güncelle
echo "📦 React bağımlılıkları güncelleniyor..."
npm install

# Projeyi build et
echo "🏗️ Proje build ediliyor..."
npm run build

# Build klasörünü kopyala
echo "📁 Build dosyaları Nginx dizinine kopyalanıyor..."
sudo cp -r dist/* /var/www/html/

# PHP API klasörünü kopyala
echo "📁 PHP API dosyaları kopyalanıyor..."
sudo mkdir -p /var/www/html/api
sudo cp api/config.php /var/www/html/api/

# API klasörüne yazma izni ver
echo "🔒 API klasörü izinleri ayarlanıyor..."
sudo chown -R www-data:www-data /var/www/html/api
sudo chmod 755 /var/www/html/api
sudo chmod 644 /var/www/html/api/config.php

# Nginx config'i güncelle
echo "🔧 Nginx config güncelleniyor (PHP destekli)..."
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
    
    # PHP API endpoint
    location ~ ^/api/config\.php$ {
        root /var/www/html;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_index config.php;
        fastcgi_param SCRIPT_FILENAME /var/www/html/api/config.php;
        include fastcgi_params;
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

# PHP-FPM kurulu mu kontrol et
echo "🐘 PHP kurulumu kontrol ediliyor..."
if ! command -v php &> /dev/null; then
    echo "📦 PHP kuruluyor..."
    sudo apt update
    sudo apt install -y php php-fpm
fi

# Nginx yeniden başlat
echo "🔄 Nginx yeniden başlatılıyor..."
sudo systemctl restart nginx
sudo systemctl restart php*-fpm

# Eski Node.js API servisini durdur (varsa)
echo "🛑 Eski Node.js API servisi durduruluyor..."
sudo systemctl stop tv-monitoring-api 2>/dev/null || true
sudo systemctl disable tv-monitoring-api 2>/dev/null || true

# .env dosyasının oluşup oluşmadığını kontrol et
echo "📄 .env dosyası kontrol ediliyor..."
if [ -f "/var/www/html/api/.env" ]; then
    echo "✅ .env dosyası mevcut: /var/www/html/api/.env"
    echo "📝 .env dosyası içeriği:"
    sudo cat /var/www/html/api/.env
else
    echo "ℹ️  .env dosyası henüz yok - İlk ayar girişinde otomatik oluşturulacak"
fi

echo "✅ PHP tabanlı güncelleme tamamlandı!"
echo "🌐 Site adresi: http://10.10.11.164"
echo "🐘 Backend: PHP (Node.js gerektirmez!)"
echo "📁 .env dosya yolu: /var/www/html/api/.env"
echo "🎉 Sistem artık PHP ile çalışıyor - Çok daha basit!"
