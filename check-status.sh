#!/bin/bash

echo "📊 TV Monitoring Dashboard - Sistem Durumu"
echo "=========================================="

# Nginx durumu
echo "🌐 Nginx Durumu:"
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx çalışıyor"
else
    echo "❌ Nginx durmuş - Başlatılıyor..."
    sudo systemctl start nginx
fi

# PHP-FPM durumu
echo ""
echo "🐘 PHP-FPM Durumu:"
if sudo systemctl is-active --quiet php*-fpm; then
    echo "✅ PHP-FPM çalışıyor"
else
    echo "❌ PHP-FPM durmuş - Başlatılıyor..."
    sudo systemctl start php*-fpm
fi

# API testi
echo ""
echo "🔌 API Testi:"
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/config.php)
if [ "$API_RESPONSE" = "200" ]; then
    echo "✅ API çalışıyor (HTTP $API_RESPONSE)"
else
    echo "❌ API sorunu (HTTP $API_RESPONSE)"
fi

# Site erişimi testi
echo ""
echo "🌐 Site Testi:"
SITE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$SITE_RESPONSE" = "200" ]; then
    echo "✅ Site erişilebilir (HTTP $SITE_RESPONSE)"
else
    echo "❌ Site sorunu (HTTP $SITE_RESPONSE)"
fi

# Disk kullanımı
echo ""
echo "💾 Disk Kullanımı:"
df -h /var/www/html | tail -1 | awk '{print "📂 /var/www/html: " $3 " kullanılan / " $2 " toplam (" $5 " dolu)"}'

# .env dosyası kontrolü
echo ""
echo "⚙️  Konfigürasyon:"
if [ -f "/var/www/html/api/.env" ]; then
    echo "✅ .env dosyası mevcut"
    echo "📋 Kayıtlı ayarlar:"
    grep -E '^[^#]' /var/www/html/api/.env | sed 's/=.*/=***/' 2>/dev/null || echo "   (Boş)"
else
    echo "ℹ️  .env dosyası henüz oluşturulmamış"
fi

echo ""
echo "🎯 Erişim Adresi: http://10.10.11.164"
echo "📅 Kontrol Tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
