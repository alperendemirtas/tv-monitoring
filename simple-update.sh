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

# API sunucusunu durduralım artık gerek yok
echo "🛑 API sunucusu durduruluyor (artık gerek yok)..."
sudo systemctl stop tv-monitoring-api
sudo systemctl disable tv-monitoring-api

echo "🎉 Sistem artık sadece localStorage ile çalışıyor!"
