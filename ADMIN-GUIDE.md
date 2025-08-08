# TV Monitoring Dashboard - Yönetici Kılavuzu

## 🎯 Normal Kullanım
Sistem **tamamen otomatik** çalışır:
- ✅ Ubuntu açılışında otomatik başlar
- ✅ Çökse bile otomatik yeniden başlar
- ✅ Manuel müdahale gerektirmez

## 📊 Durum Kontrolü

### Hızlı Kontrol:
```bash
cd /var/www/tv-monitoring
./check-status.sh
```

### Detaylı Kontrol:
```bash
# Nginx durumu
sudo systemctl status nginx

# PHP-FPM durumu  
sudo systemctl status php*-fpm

# API testi
curl http://localhost/api/config.php
```

## 🛠️ Servis Yönetimi

### Kontrol Scripti:
```bash
cd /var/www/tv-monitoring

# Durum göster
./service-control.sh

# Servisleri yeniden başlat
./service-control.sh restart

# Servisleri durdur
./service-control.sh stop

# Servisleri başlat
./service-control.sh start
```

### Manuel Komutlar:
```bash
# Nginx yeniden başlat
sudo systemctl restart nginx

# PHP-FPM yeniden başlat
sudo systemctl restart php*-fpm

# Her ikisini birden
sudo systemctl restart nginx php*-fpm
```

## 🔄 Güncelleme

### Kod güncelleme:
```bash
cd /var/www/tv-monitoring
./simple-update.sh
```

### Sorun varsa tam temizlik:
```bash
wget https://raw.githubusercontent.com/alperendemirtas/tv-monitoring/main/manual-setup.sh
./manual-setup.sh
```

## 🆘 Sorun Giderme

### 1. Site açılmıyor:
```bash
# Servisleri kontrol et
./check-status.sh

# Nginx loglarını kontrol et
sudo tail -f /var/log/nginx/error.log
```

### 2. API çalışmıyor:
```bash
# PHP-FPM loglarını kontrol et
sudo tail -f /var/log/php*-fpm.log

# PHP versiyonu kontrol et
php --version
```

### 3. Ayarlar kayboldu:
```bash
# .env dosyasını kontrol et
cat /var/www/html/api/.env

# İzinleri düzelt
sudo chown -R www-data:www-data /var/www/html/api
```

## 📱 Erişim Adresleri

- **Ana Site**: http://10.10.11.164
- **API Test**: http://10.10.11.164/api/config.php
- **Sensibo Proxy**: http://10.10.11.164/api/sensibo/

## ⚙️ Konfigürasyon

### .env Dosyası Yolu:
`/var/www/html/api/.env`

### Örnek .env İçeriği:
```env
# TV Monitoring Dashboard Environment Variables
OPMANAGER_URL="http://your-opmanager-url"
SENSIBO_API_KEY="your-sensibo-api-key"
```

## 🔧 Sistem Gereksinimleri

- ✅ Ubuntu 20.04+
- ✅ Nginx
- ✅ PHP 7.4+ (PHP-FPM)
- ✅ Node.js 16+ (sadece build için)

## 📞 Hızlı Yardım

Problem varsa sırasıyla dene:
1. `./check-status.sh` - Durum kontrol et
2. `./service-control.sh restart` - Servisleri yeniden başlat  
3. `./manual-setup.sh` - Tam temizlik ve yeniden kurulum
