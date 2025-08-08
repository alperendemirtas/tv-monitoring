@echo off
echo 🚀 TV Monitoring Dashboard - API Server Starter (Windows)

cd /d "%~dp0"

REM API dizinine geç
if not exist "api" (
    echo ❌ API dizini bulunamadı!
    pause
    exit /b 1
)

cd api

REM Node.js kontrol et
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js yüklü değil! Lütfen Node.js kurun.
    pause
    exit /b 1
)

REM NPM paketlerini kur
if not exist "node_modules" (
    echo 📦 NPM paketleri yükleniyor...
    npm install
    
    if errorlevel 1 (
        echo ❌ NPM paketleri kurulamadı!
        pause
        exit /b 1
    )
)

REM API sunucusunu başlat
echo 🚀 API sunucusu başlatılıyor...
node server.js
pause
