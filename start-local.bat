@echo off
echo 🚀 TV Monitoring Dashboard başlatılıyor...

REM Node.js ve npm kontrolü
echo 📦 Node.js kontrol ediliyor...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js bulunamadı! Lütfen Node.js kurun.
    echo 📥 https://nodejs.org adresinden indirebilirsiniz.
    pause
    exit /b 1
)

REM Dependencies kurulum kontrolü
if not exist "node_modules" (
    echo � Dependencies kuruluyor...
    npm install
)

REM React dev server'ı başlat
echo 🌐 Dashboard başlatılıyor...
echo 📍 Yerel adres: http://localhost:5173
echo 🌍 Ağ adresi: http://[IP]:5173
echo.
echo 💡 Durdurmak için CTRL+C kullanın
echo.

npm run dev

pause
