@echo off
echo 🚀 TV Monitoring Dashboard başlatılıyor...

REM PHP kontrolü
echo 🔍 PHP kurulumunu kontrol ediliyor...
php -v >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PHP bulunamadı! Lütfen PHP kurun.
    echo 📥 https://windows.php.net adresinden indirebilirsiniz.
    pause
    exit /b 1
)

REM Node.js kontrolü
echo 🔍 Node.js kurulumunu kontrol ediliyor...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js bulunamadı! Lütfen Node.js kurun.
    echo 📥 https://nodejs.org adresinden indirebilirsiniz.
    pause
    exit /b 1
)

REM Dependencies kurulum kontrolü
if not exist "node_modules" (
    echo 📦 Dependencies kuruluyor...
    npm install
)

echo ✅ Sistem kontrolleri tamamlandı!
echo.

REM React dev server'ı başlat (arka planda)
echo 📦 React Dashboard başlatılıyor...
start "React Dashboard" cmd /k "npm run dev"

REM 3 saniye bekle (React'in başlaması için)
timeout /t 3 /nobreak >nul

REM PHP API server'ı başlat (arka planda)  
echo 🐘 PHP API Server başlatılıyor...
start "PHP API Server" cmd /k "cd /d %~dp0api & php -S localhost:3001 config.php"

echo.
echo ✅ Tüm sunucular başlatıldı!
echo 🌐 React Dashboard: http://localhost:5173 (veya farklı port)
echo 🔌 PHP API Server: http://localhost:3001
echo.
echo 💡 Sunucuları durdurmak için açılan terminal pencerelerini kapatın
echo 🔧 Ayarlar menüsünden OpManager URL ve Sensibo API Key'i girebilirsiniz

pause
