@echo off
echo 🚀 Local development sunucusu başlatılıyor...

REM React dev server'ı başlat (arka planda)
echo 📦 React dev server başlatılıyor...
start "React Dev" cmd /k "npm run dev"

REM PHP API server'ı başlat (arka planda)  
echo 🐘 PHP API server başlatılıyor...
start "PHP API" cmd /k "cd api && php -S localhost:3001 config.php"

echo ✅ Sunucular başlatıldı!
echo 🌐 React App: http://localhost:5173
echo 🔌 PHP API: http://localhost:3001
echo 💡 Her iki pencereyi kapatmak için CTRL+C kullanın

pause
