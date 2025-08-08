#!/bin/bash

echo "🔄 PHP tabanlı güncelleme başlıyor..."

# Proje dizinine git ve kontrol et
echo "📂 Proje dizinine geçiliyor..."
TARGET_DIR="/var/www/tv-monitoring"

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ $TARGET_DIR bulunamadı!"
    echo "🔄 İlk kurulum yapılıyor..."
    sudo mkdir -p /var/www/
    cd /var/www/
    sudo git clone https://github.com/alperendemirtas/tv-monitoring.git
    sudo chown -R $(whoami):$(whoami) tv-monitoring
fi

cd "$TARGET_DIR" || {
    echo "❌ $TARGET_DIR dizinine geçilemedi!"
    exit 1
}

echo "✅ Çalışma dizini: $(pwd)"

# Git güncellemesi ve doğrulama
echo "📥 Git'den son değişiklikleri çekiyor..."

# Önce git durumunu kontrol et
echo "🔍 Git durumu kontrol ediliyor..."
if [ ! -d ".git" ]; then
    echo "❌ Bu bir git repository değil!"
    echo "🔄 Repository yeniden klonlanıyor..."
    cd /var/www/
    sudo rm -rf tv-monitoring
    sudo git clone https://github.com/alperendemirtas/tv-monitoring.git
    cd tv-monitoring
    sudo chown -R $(whoami):$(whoami) .
else
    echo "✅ Git repository mevcut"
    
    # Local değişiklikler varsa stash yap
    if ! git diff-index --quiet HEAD --; then
        echo "⚠️  Local değişiklikler tespit edildi, stash yapılıyor..."
        git stash
    fi
    
    # Pull yap
    git pull origin main || {
        echo "❌ Git pull başarısız, repository yeniden klonlanıyor..."
        cd /var/www/
        sudo rm -rf tv-monitoring
        sudo git clone https://github.com/alperendemirtas/tv-monitoring.git
        cd tv-monitoring
        sudo chown -R $(whoami):$(whoami) .
    }
fi

# Git pull sonrası dosya kontrolü
echo "🔍 Git pull sonrası dosya kontrolü:"
echo "📂 Proje klasörü içeriği:"
ls -la
echo ""
echo "📂 api/ klasörü içeriği:"
if [ -d "api" ]; then
    ls -la api/
else
    echo "❌ api/ klasörü bulunamadı!"
    echo "🔄 Git durumunu kontrol edelim:"
    git status
    echo "🌿 Mevcut branch:"
    git branch
    exit 1
fi

# React bağımlılıklarını güncelle
echo "📦 React bağımlılıkları güncelleniyor..."
npm install

# Projeyi build et
echo "🏗️ Proje build ediliyor..."
npm run build

# Build klasörünü kopyala
echo "📁 Build dosyaları Nginx dizinine kopyalanıyor..."
sudo cp -r dist/* /var/www/html/

# PHP API klasörünü kopyala ve kontrol et
echo "📁 PHP API dosyaları kontrol ediliyor..."
if [ -f "api/config.php" ]; then
    echo "✅ config.php kaynak dosyası mevcut"
    sudo mkdir -p /var/www/html/api
    sudo cp api/config.php /var/www/html/api/
    echo "📋 config.php kopyalandı"
    
    # Dosyanın başarıyla kopyalanıp kopyalanmadığını kontrol et
    if [ -f "/var/www/html/api/config.php" ]; then
        echo "✅ config.php hedef konumda mevcut"
        echo "📏 Dosya boyutu: $(wc -c < /var/www/html/api/config.php) byte"
    else
        echo "❌ config.php kopyalanamadı!"
        exit 1
    fi
else
    echo "❌ api/config.php kaynak dosyası bulunamadı!"
    ls -la api/
    exit 1
fi

# API klasörüne yazma izni ver ve kontrol et
echo "🔒 API klasörü izinleri ayarlanıyor..."
sudo chown -R www-data:www-data /var/www/html/api
sudo chmod 755 /var/www/html/api
sudo chmod 644 /var/www/html/api/config.php

# İzinleri kontrol et
echo "🔍 İzin kontrolü:"
ls -la /var/www/html/api/
echo "📂 API klasörü içeriği:"
sudo ls -la /var/www/html/api/

echo "🔧 Nginx config güncelleniyor (PHP destekli)..."

# PHP version tespit et
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
echo "🐘 PHP Versiyonu: $PHP_VERSION"

sudo tee /etc/nginx/sites-available/tv-monitoring > /dev/null << EOF
server {
    listen 80;
    server_name 10.10.11.164;
    root /var/www/html;
    index index.html;
    
    # Ana React uygulaması
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # PHP API endpoint
    location ~ ^/api/config\.php$ {
        try_files \$uri =404;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index config.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Sensibo API proxy (mevcut)
    location /api/sensibo/ {
        proxy_pass https://home.sensibo.com/api/v2/;
        proxy_set_header Host home.sensibo.com;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_ssl_verify off;
    }
}
EOF

# PHP-FPM kurulu mu kontrol et ve kurulum detayları
echo "🐘 PHP kurulumu kontrol ediliyor..."
if ! command -v php &> /dev/null; then
    echo "📦 PHP kuruluyor..."
    sudo apt update
    sudo apt install -y php php-fpm php-json
else
    echo "✅ PHP zaten kurulu: $(php --version | head -n1)"
fi

# PHP-FPM servisi kontrolü
echo "🔄 PHP-FPM servis durumu:"
sudo systemctl status php*-fpm --no-pager -l
echo ""

# PHP socket dosyasını bul
echo "🔌 PHP-FPM socket konumu:"
PHP_SOCKET=$(find /var/run/php* -name "*fpm.sock" 2>/dev/null | head -n1)
if [ -n "$PHP_SOCKET" ]; then
    echo "✅ PHP-FPM socket: $PHP_SOCKET"
    ls -la "$PHP_SOCKET"
else
    echo "❌ PHP-FPM socket bulunamadı!"
    echo "🔍 /var/run/php* klasör içeriği:"
    sudo ls -la /var/run/php* 2>/dev/null || echo "PHP run klasörü yok"
fi

# Nginx yeniden başlat ve test et
echo "🔄 Nginx yeniden başlatılıyor..."

# Site'i aktifleştir
sudo ln -sf /etc/nginx/sites-available/tv-monitoring /etc/nginx/sites-enabled/
echo "🔗 Site aktifleştirildi"

sudo systemctl restart nginx
sudo systemctl restart php*-fpm

# Nginx durumu
echo "📊 Nginx servis durumu:"
sudo systemctl status nginx --no-pager -l

# Nginx config test
echo "🧪 Nginx config test:"
sudo nginx -t

# API endpoint test
echo "🧪 API endpoint test:"
echo "GET http://localhost/api/config.php"
curl -s http://localhost/api/config.php || echo "❌ API endpoint erişilemez"

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
