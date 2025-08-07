# TV İçin Çift Panelli Gözetim Ekranı

# TV Monitoring Dashboard

Modern React + Vite tabanlı TV monitoring dashboard'u. OpManager ve Sensibo verilerini tek ekranda gösterir.

## ✨ Özellikler

- **Split-screen Layout:** OpManager (%80) + Sensibo Climate Data (%20)
- **TV Optimized:** Dark theme, büyük fontlar, tam ekran desteği
- **Auto-refresh:** 5 dakikada bir otomatik veri güncelleme
- **Modern UI:** Gradient kartlar, animasyonlu göstergeler, renk kodlu veriler
- **Responsive:** TV, desktop ve mobil uyumlu
- **Persistent Settings:** localStorage ile ayar saklama
- **Real-time Data:** Sensibo API entegrasyonu ile canlı veri

## 🚀 Hızlı Başlangıç

### Yerel Development
```bash
npm install
npm run dev
```
Dashboard http://localhost:5173 adresinde çalışacak.

### Production Deployment (Ubuntu)
```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/haus-monitoring/main/deploy-ubuntu.sh
chmod +x deploy-ubuntu.sh
./deploy-ubuntu.sh
```

Detaylı kurulum için [README-DEPLOY.md](README-DEPLOY.md) dosyasına bakın.

## 📋 Gereksinimler

- Node.js 18+
- Modern web browser
- OpManager URL (iframe için)
- Sensibo API Key

## ⚙️ Kullanım

1. Dashboard'u açın
2. Sağ alt köşedeki ⚙️ simgesine hover yapın
3. OpManager URL'i girin
4. Sensibo API anahtarını girin
5. Kaydet'e tıklayın

## 🎨 Görsel Özellikler

- **Sıcaklık Renk Kodları:**
  - 🔵 Soğuk (< 18°C)
  - 🟢 Normal (18-24°C) 
  - 🟡 Sıcak (> 24°C)

- **Nem Gauges:**
  - Düşük (< 40%)
  - Normal (40-60%)
  - Yüksek (> 60%)

## 🔧 Teknolojiler

- React 18
- Vite
- CSS3 (Animations, Flexbox, Grid)
- Sensibo API
- Nginx (Production)

## 📱 TV Optimizasyonu

- F11 ile tam ekran
- 80/20 split layout
- Koyu tema göz yormaz
- Büyük, okunabilir fontlar
- 5 dakikada otomatik yenileme

## 🛠️ Scripts

```bash
npm run dev          # Development server
npm run build        # Production build
npm run preview      # Preview production build
```

## 📂 Proje Yapısı

```
haus-monitoring/
├── src/
│   ├── App.jsx         # Ana component
│   ├── App.css         # Styling
│   └── main.jsx        # Entry point
├── deploy-ubuntu.sh    # Ubuntu deployment
├── update-dashboard.sh # Update script
├── health-check.sh     # Health monitoring
└── README-DEPLOY.md    # Deployment guide
```

## 🔄 Güncelleme

Ubuntu server'da:
```bash
cd /home/ubuntu/haus-monitoring
./update-dashboard.sh
```

## 📊 Monitoring

Otomatik sağlık kontrolü:
```bash
crontab -e
# Add:
*/5 * * * * /home/ubuntu/haus-monitoring/health-check.sh
```

## 🎯 TV Kurulum Önerileri

1. **Network:** TV'yi ethernet ile bağlayın
2. **Browser:** Chrome/Edge kullanın
3. **Display:** "PC Mode" veya "Game Mode" açın
4. **Power:** Otomatik kapanmayı devre dışı bırakın
5. **Brightness:** Ortada tutun

## 📞 Destek

Sorun yaşarsanız:
- Nginx logs: `sudo journalctl -u nginx`
- Health logs: `/var/log/tv-monitoring-health.log`
- Rebuild: `npm run build && sudo systemctl restart nginx`

---

**🏠 Made for Smart Home Monitoring** Ekran dikey olarak iki eşit parçaya bölünür ve her panelde farklı monitörleme verileri gösterilir.

## Özellikler

### 🖥️ Çift Panel Layout
- **Sol Panel**: OpManager web arayüzü (iframe)
- **Sağ Panel**: Sensibo klima verileri (API)

### ⚙️ Ayarlar Sistemi
- OpManager URL ayarı
- Sensibo API anahtarı ayarı
- localStorage ile kalıcı saklama

### 🔄 Otomatik Yenileme
- Sensibo verileri 5 dakikada bir otomatik güncellenir
- Anlık sıcaklık ve nem verileri

### 📺 TV Optimize
- Tam ekran layout
- Koyu tema
- Büyük ve okunaklı fontlar
- 1080p/4K TV desteği

## Kurulum

```bash
# Bağımlılıkları yükle
npm install

# Sensibo API proxy sunucusunu başlat (ayrı terminal)
npm run proxy

# Geliştirme sunucusunu başlat (ayrı terminal)  
npm run dev

# Üretim için build
npm run build
```

## Kullanım

1. **Proxy Sunucu**: Terminal'de `npm run proxy` komutu ile Sensibo API proxy sunucusunu başlatın (port 3001)
2. **Dev Sunucu**: Başka bir terminal'de `npm run dev` komutu ile geliştirme sunucusunu başlatın (port 5174)
3. **Ayarlar**: Üst kısımdaki input alanlarından OpManager URL'i ve Sensibo API anahtarını girin
4. **Kaydet**: "Kaydet" butonuna tıklayarak ayarları localStorage'a kaydedin  
5. **Gözetim**: Sol panelde OpManager, sağ panelde Sensibo verileri görüntülenir
6. **Otomatik**: Sensibo verileri her 5 dakikada otomatik yenilenir

## API Kullanımı

### Sensibo API
- Endpoint: `https://home.sensibo.com/api/v2/users/me/pods`
- Authentication: Bearer token
- Gösterilen veriler: Oda adı, sıcaklık, nem oranı

## Teknik Detaylar

- **Framework**: React 18 + Vite
- **Styling**: Vanilla CSS
- **State Management**: React Hooks (useState, useEffect)
- **Data Persistence**: localStorage
- **API Client**: Fetch API
- **Auto Refresh**: setInterval (5 dakika)

## Geliştirme

Proje klasik React + Vite yapısını kullanır:
- `src/App.jsx` - Ana uygulama bileşeni
- `src/App.css` - TV optimize stilleri
- `src/index.css` - Global stiller

## TV Kurulum Önerileri

1. TV'yi tam ekran modunda açın
2. Otomatik uyku modunu kapatın
3. Ekran koruyucuyu devre dışı bırakın
4. Uygulamayı tam ekran modda (F11) çalıştırın+ Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh

## Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.
