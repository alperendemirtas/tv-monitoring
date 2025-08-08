#!/bin/bash

ACTION=${1:-status}

case $ACTION in
    "start")
        echo "🚀 TV Monitoring servisleri başlatılıyor..."
        sudo systemctl start nginx
        sudo systemctl start php*-fpm
        echo "✅ Servisler başlatıldı"
        ;;
    "stop")
        echo "🛑 TV Monitoring servisleri durduruluyor..."
        sudo systemctl stop nginx
        sudo systemctl stop php*-fpm
        echo "✅ Servisler durduruldu"
        ;;
    "restart")
        echo "🔄 TV Monitoring servisleri yeniden başlatılıyor..."
        sudo systemctl restart nginx
        sudo systemctl restart php*-fpm
        echo "✅ Servisler yeniden başlatıldı"
        ;;
    "status"|*)
        echo "📊 TV Monitoring Servis Durumu:"
        echo ""
        echo "🌐 Nginx:"
        sudo systemctl status nginx --no-pager -l | head -3
        echo ""
        echo "🐘 PHP-FPM:"
        sudo systemctl status php*-fpm --no-pager -l | head -3
        echo ""
        echo "📋 Kullanım:"
        echo "  $0 start    - Servisleri başlat"
        echo "  $0 stop     - Servisleri durdur" 
        echo "  $0 restart  - Servisleri yeniden başlat"
        echo "  $0 status   - Durum göster (varsayılan)"
        ;;
esac
