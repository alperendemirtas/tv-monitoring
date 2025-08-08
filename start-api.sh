#!/bin/bash
echo "🚀 TV Monitoring Dashboard - API Server Starter"

cd "$(dirname "$0")"

# API dizinine geç
if [ ! -d "api" ]; then
    echo "❌ API dizini bulunamadı!"
    exit 1
fi

cd api

# Node.js kontrol et
if ! command -v node &> /dev/null; then
    echo "❌ Node.js yüklü değil! Lütfen Node.js kurun."
    exit 1
fi

# NPM paketlerini kur
if [ ! -d "node_modules" ]; then
    echo "📦 NPM paketleri yükleniyor..."
    npm install
    
    if [ $? -ne 0 ]; then
        echo "❌ NPM paketleri kurulamadı!"
        exit 1
    fi
fi

# API sunucusunu başlat
echo "🚀 API sunucusu başlatılıyor..."
node server.js
