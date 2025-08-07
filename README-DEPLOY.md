# TV Monitoring Dashboard - Ubuntu Deployment Guide

Bu kılavuz, TV Monitoring Dashboard'unuzu Ubuntu server'da çalıştırmanız için gereken tüm adımları içerir.

## 🎯 Hızlı Kurulum

### 1. Ubuntu Server'a Bağlanın
```bash
ssh username@your-server-ip
# veya AWS için:
ssh -i your-key.pem ubuntu@your-server-ip
```

### 2. Deploy Script'ini İndirin ve Çalıştırın
```bash
# Deploy script'ini indir
wget https://raw.githubusercontent.com/YOUR_USERNAME/haus-monitoring/main/deploy-ubuntu.sh

# Çalıştırılabilir yap
chmod +x deploy-ubuntu.sh

# Deploy'u başlat
./deploy-ubuntu.sh
```

**Not:** `YOUR_USERNAME` kısmını GitHub kullanıcı adınızla değiştirin!

### 3. Dashboard'u Açın
Script tamamlandıktan sonra:
```
http://your-server-ip
```
adresinden dashboard'unuza erişebilirsiniz.

## ⚙️ Dashboard Ayarları

1. **Tarayıcıda dashboard'u açın**
2. **Sağ alt köşedeki ⚙️ ikonuna hover yapın**
3. **OpManager URL'i girin** (örn: `https://your-opmanager.com/dashboard`)
4. **Sensibo API anahtarını girin**
5. **"Kaydet" butonuna tıklayın**

## 🔄 Dashboard Güncelleme

Kodunuzda değişiklik yaptıktan sonra:

```bash
cd /home/ubuntu/haus-monitoring
./update-dashboard.sh
```

## 🏥 Otomatik Sağlık Kontrolü

Sistem otomatik olarak dashboard'un çalışıp çalışmadığını kontrol etsin:

```bash
# Crontab'ı düzenle
crontab -e

# Bu satırları ekle:
*/5 * * * * /home/ubuntu/haus-monitoring/health-check.sh
0 2 * * * /home/ubuntu/haus-monitoring/update-dashboard.sh
```

## 📊 TV Optimizasyonu

### Tarayıcı Ayarları
- **F11** ile tam ekran yapın
- **Otomatik güncellemeler:** Dashboard 5 dakikada bir kendini günceller
- **Dark Theme:** TV'ler için optimize edilmiş koyu tema

### Önerilen TV Ayarları
- Ekran parlaklığını ortaya ayarlayın
- "Game Mode" veya "PC Mode" açın (input lag için)
- Otomatik kapanma süresini uzun tutun

## 🔧 Troubleshooting

### Dashboard Açılmıyor
```bash
# Nginx durumunu kontrol et
sudo systemctl status nginx

# Nginx loglarını kontrol et
sudo journalctl -u nginx --no-pager --lines=50

# Nginx'i yeniden başlat
sudo systemctl restart nginx
```

### API Verileri Gelmiyor
```bash
# Build klasörünü kontrol et
ls -lah /home/ubuntu/haus-monitoring/dist

# Projeyi yeniden build et
cd /home/ubuntu/haus-monitoring
npm run build
sudo systemctl restart nginx
```

### Performans Sorunları
```bash
# Sistem kaynaklarını kontrol et
htop

# Disk alanını kontrol et
df -h

# Nginx access loglarını temizle
sudo truncate -s 0 /var/log/nginx/access.log
```

## 🌐 Ağ Ayarları

### Güvenlik Duvarı
```bash
# Mevcut kuralları görüntüle
sudo ufw status

# HTTP trafiğine izin ver
sudo ufw allow 'Nginx Full'

# SSH'ı güvenli tut
sudo ufw allow ssh
```

### Domain Bağlama (Opsiyonel)
Domain adınız varsa:

```bash
# Nginx config'i düzenle
sudo nano /etc/nginx/sites-available/tv-monitoring

# server_name kısmını değiştir:
server_name your-domain.com;

# SSL için Let's Encrypt kurulumu
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## 📱 Mobil Erişim

Dashboard mobil cihazlardan da erişilebilir:
- Responsive tasarım
- Touch-friendly interface
- Aynı ağdaki tüm cihazlardan erişim

## 🚨 Acil Durum Kurtarma

### Backup'tan Geri Yükleme
```bash
cd /home/ubuntu/haus-monitoring

# Mevcut backup'ları listele
ls -la dist.backup.*

# En son backup'ı geri yükle
sudo rm -rf dist
sudo mv dist.backup.YYYYMMDD_HHMMSS dist
sudo systemctl restart nginx
```

### Sıfırdan Kurulum
```bash
# Projeyi sil ve yeniden kur
sudo rm -rf /home/ubuntu/haus-monitoring
./deploy-ubuntu.sh
```

## 📞 Destek

Sorun yaşarsanız:
1. Logları kontrol edin: `/var/log/tv-monitoring-health.log`
2. Nginx logları: `sudo journalctl -u nginx`
3. System durumu: `htop` ve `df -h`

---

## 📋 Kurulum Özeti

1. ✅ Ubuntu server hazır
2. ✅ `deploy-ubuntu.sh` çalıştırıldı
3. ✅ Dashboard http://server-ip adresinde çalışıyor
4. ✅ OpManager URL ve Sensibo API key ayarlandı
5. ✅ Otomatik güncellemeler aktif
6. ✅ TV'de tam ekran test edildi

**🎉 Dashboard hazır kullanım!**
