# 📺 TV Monitoring Dashboard - Yerel Ağ Yapılandırma Sistemi

## 🎯 Özellikler

- **TV-Dostu Yapılandırma**: Ayarları TV'den değil, bilgisayardan girebilirsiniz
- **Yerel Ağ Tabanlı**: İnternet gerektirmez, tamamen offline çalışır
- **Otomatik Senkronizasyon**: Ayarlar sunucuda saklanır ve TV otomatik güncellenir
- **OpManager Entegrasyonu**: Sol panelde OpManager dashboard'u
- **Sensibo Climate Data**: Sağ panelde gerçek zamanlı iklim verileri

## 🏗️ Sistem Mimarisi

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   TV Tarayıcı   │    │  Ubuntu Sunucu   │    │ Kullanıcı PC'si │
│                 │    │                  │    │                 │
│ React App       │◄──►│ Backend API      │◄──►│ React App       │
│ :3000           │    │ :3001            │    │ :3000           │
│                 │    │                  │    │                 │
│ (Dashboard)     │    │ (Config Storage) │    │ (Config Entry)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🚀 Kurulum ve Çalıştırma

### 1️⃣ Ubuntu Sunucuda Hızlı Kurulum

```bash
# Repository'yi klonla
git clone https://github.com/alperendemirtas/tv-monitoring.git
cd tv-monitoring

# Otomatik kurulum (React + API + Nginx)
chmod +x quick-fix-v2.sh
sudo ./quick-fix-v2.sh
```

### 2️⃣ Manuel Kurulum

#### Backend API (Port 3001)
```bash
cd tv-monitoring/api
npm install
node server.js
```

#### Frontend React App (Port 3000) 
```bash
cd tv-monitoring
npm install
npm run dev
```

## 📋 Kullanım Kılavuzu

### TV Kurulumu:
1. **TV tarayıcısında açın**: `http://[SERVER_IP]:3000`
2. **"Yapılandırma Bekleniyor" ekranını** göreceksiniz
3. Ekrandaki talimatları takip edin

### Bilgisayardan Yapılandırma:
1. **Aynı ağdaki bilgisayardan**: `http://[SERVER_IP]:3000`
2. **Ayarlar bölümünü** açın (sağ panel alt kısmı)
3. **OpManager URL** ve **Sensibo API Key** girin  
4. **"Kaydet"** butonuna tıklayın
5. **TV ekranı otomatik güncellenir** ✨

## 🔧 API Endpoints

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/api/config` | Ayarları oku |
| POST | `/api/config` | Ayarları kaydet |
| DELETE | `/api/config` | Ayarları sıfırla |
| GET | `/api/status` | API durumu |
| GET | `/health` | Sağlık kontrolü |

## 📁 Proje Yapısı

```
tv-monitoring/
├── 📱 Frontend (React)
│   ├── src/
│   │   ├── App.jsx        # Ana uygulama
│   │   └── App.css        # Stiller
│   └── public/
├── 🔧 Backend (Node.js API)
│   ├── api/
│   │   ├── server.js      # API sunucu
│   │   ├── package.json   # API dependencies
│   │   └── config.json    # Ayar dosyası (otomatik)
├── 🖥️ Deployment
│   ├── quick-fix-v2.sh    # Ubuntu otomatik kurulum
│   ├── start-api.sh       # API başlatıcı (Linux)
│   └── start-api.bat      # API başlatıcı (Windows)
└── 📚 Docs
    └── README.md
```

## 🛠️ Sistem Gereksinimleri

- **Ubuntu Server** (18.04+)
- **Node.js** (16+) 
- **Nginx** (reverse proxy için)
- **Yerel Ağ** (Wi-Fi/Ethernet)

## 🔍 Sorun Giderme

### API Çalışmıyor:
```bash
# API durumunu kontrol et
curl http://localhost:3001/api/status

# Service loglarını incele
journalctl -u tv-monitoring-api -f
```

### TV Yapılandırma Yüklenmiyor:
```bash
# Config dosyasını kontrol et
cat /var/www/tv-monitoring/api/config.json

# API portunu kontrol et
netstat -tlnp | grep 3001
```

### Network Sorunları:
```bash
# Sunucu IP adresini bul
hostname -I

# Port erişimini test et
telnet [SERVER_IP] 3001
```

## 🎨 Özelleştirme

### Server IP'sini Değiştir:
`src/App.jsx` içinde:
```javascript
const [serverIp, setServerIp] = useState('YOUR_SERVER_IP')
```

### API Portunu Değiştir:
`api/server.js` içinde:
```javascript
const PORT = 3001; // İstediğiniz port
```

## 🚨 Güvenlik Notları

- **Yerel ağ kullanımı**: Bu sistem sadece güvenli yerel ağlarda kullanılmalıdır
- **Firewall**: Gerekirse sadece yerel ağdan erişime izin verin
- **API Keys**: Sensibo API anahtarlarınızı güvenli tutun

## 📞 Destek

Sorun yaşarsanız:
1. **Logları kontrol edin**: `journalctl -u tv-monitoring-api -f`
2. **Port durumunu kontrol edin**: `netstat -tlnp`  
3. **Config dosyasını kontrol edin**: `cat api/config.json`

---
**Geliştirici**: [alperendemirtas](https://github.com/alperendemirtas)
**Lisans**: MIT
