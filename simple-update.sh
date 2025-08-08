#!/bin/bash

echo "🔄 Basit güncelleme başlıyor..."

# Proje dizinine git
cd /var/www/tv-monitoring

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
