#!/bin/bash

echo "🔧 Manuel kurulum/onarım scripti başlatılıyor..."

# Eski dosyaları temizle
echo "🧹 Eski dosyalar temizleniyor..."
sudo rm -rf /var/www/tv-monitoring
sudo rm -rf /var/www/html/api
sudo rm -rf /var/www/html/index.html
sudo rm -rf /var/www/html/assets

# Repository'yi temiz olarak klonla
echo "📥 Repository klonlanıyor..."
cd /var/www/
sudo git clone https://github.com/alperendemirtas/tv-monitoring.git
cd tv-monitoring
sudo chown -R $(whoami):$(whoami) .

echo "🔍 Klonlanan dosyalar kontrol ediliyor..."
ls -la
echo ""
echo "📂 API klasörü:"
ls -la api/ 2>/dev/null || echo "❌ api klasörü yok!"

# React build
echo "📦 NPM bağımlılıkları kuruluyor..."
npm install || {
    echo "❌ npm install başarısız!"
    echo "🔧 Node.js ve npm kurulu mu kontrol edin:"
    node --version
    npm --version
    exit 1
}

echo "🏗️ React build yapılıyor..."
npm run build || {
    echo "❌ Build başarısız!"
    exit 1
}

# PHP kurulumu
echo "🐘 PHP kurulumu kontrol ediliyor..."
if ! command -v php &> /dev/null; then
    echo "📦 PHP kuruluyor..."
    sudo apt update
    sudo apt install -y php php-fpm php-json php-curl
fi

# Dosyaları kopyala
echo "📁 Dosyalar kopyalanıyor..."
sudo cp -r dist/* /var/www/html/
sudo mkdir -p /var/www/html/api
sudo cp api/config.php /var/www/html/api/ 2>/dev/null || {
    echo "❌ config.php bulunamadı!"
    echo "📋 config.php oluşturuluyor..."
    
    # config.php'yi manuel oluştur
    sudo tee /var/www/html/api/config.php > /dev/null << 'EOF'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$envFile = __DIR__ . '/.env';

function readEnvFile($filePath) {
    $envVars = [];
    if (file_exists($filePath)) {
        $lines = file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            $line = trim($line);
            if ($line && !str_starts_with($line, '#')) {
                $parts = explode('=', $line, 2);
                if (count($parts) === 2) {
                    $key = trim($parts[0]);
                    $value = trim($parts[1], '"\'');
                    $envVars[$key] = $value;
                }
            }
        }
    }
    return $envVars;
}

function writeEnvFile($filePath, $envVars) {
    $content = "# TV Monitoring Dashboard Environment Variables\n";
    $content .= "# Generated at: " . date('c') . "\n\n";
    
    foreach ($envVars as $key => $value) {
        $quotedValue = (strpos($value, ' ') !== false || strpos($value, '://') !== false) 
            ? '"' . $value . '"' 
            : $value;
        $content .= "$key=$quotedValue\n";
    }
    
    return file_put_contents($filePath, $content) !== false;
}

try {
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $envVars = readEnvFile($envFile);
        
        $config = [
            'opmanagerUrl' => $envVars['OPMANAGER_URL'] ?? '',
            'sensiboApiKey' => $envVars['SENSIBO_API_KEY'] ?? ''
        ];
        
        echo json_encode([
            'success' => true,
            'config' => $config
        ]);
        
    } elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            throw new Exception('Geçersiz JSON verisi');
        }
        
        $currentEnv = readEnvFile($envFile);
        
        $currentEnv['OPMANAGER_URL'] = $input['opmanagerUrl'] ?? '';
        $currentEnv['SENSIBO_API_KEY'] = $input['sensiboApiKey'] ?? '';
        
        if (writeEnvFile($envFile, $currentEnv)) {
            echo json_encode([
                'success' => true,
                'message' => 'Konfigürasyon başarıyla kaydedildi'
            ]);
        } else {
            throw new Exception('.env dosyasına yazılamadı');
        }
        
    } else {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'error' => 'Desteklenmeyen HTTP metodu'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
EOF
}

# İzinleri ayarla
echo "🔒 İzinler ayarlanıyor..."
sudo chown -R www-data:www-data /var/www/html/api
sudo chmod 755 /var/www/html/api
sudo chmod 644 /var/www/html/api/config.php

# Nginx config
echo "🔧 Nginx konfigürasyonu..."
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
echo "🐘 PHP Versiyonu: $PHP_VERSION"

sudo tee /etc/nginx/sites-available/tv-monitoring > /dev/null << EOF
server {
    listen 80;
    server_name 10.10.11.164;
    root /var/www/html;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    location ~ ^/api/config\.php$ {
        try_files \$uri =404;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index config.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
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

# Site'i aktifleştir
sudo ln -sf /etc/nginx/sites-available/tv-monitoring /etc/nginx/sites-enabled/

# Servisleri yeniden başlat
echo "🔄 Servisler yeniden başlatılıyor..."
sudo systemctl restart nginx
sudo systemctl restart php*-fpm

# Test
echo "🧪 API test ediliyor..."
sleep 2
curl -s http://localhost/api/config.php || echo "❌ API erişilemez"

echo ""
echo "✅ Manuel kurulum tamamlandı!"
echo "🌐 Site adresi: http://10.10.11.164"
echo "📁 .env dosya yolu: /var/www/html/api/.env"
