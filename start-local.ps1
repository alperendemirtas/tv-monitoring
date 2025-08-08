# Local development sunucusu başlat
Write-Host "🚀 Local development sunucusu başlatılıyor..." -ForegroundColor Green

# React dev server'ı başlat
Write-Host "📦 React dev server başlatılıyor..." -ForegroundColor Yellow
Start-Process -FilePath "cmd" -ArgumentList "/k", "npm run dev" -WindowStyle Normal

# PHP API server'ı başlat
Write-Host "🐘 PHP API server başlatılıyor..." -ForegroundColor Yellow  
Start-Process -FilePath "cmd" -ArgumentList "/k", "cd api && php -S localhost:3001 config.php" -WindowStyle Normal

Write-Host "✅ Sunucular başlatıldı!" -ForegroundColor Green
Write-Host "🌐 React App: http://localhost:5173" -ForegroundColor Cyan
Write-Host "🔌 PHP API: http://localhost:3001" -ForegroundColor Cyan
Write-Host "💡 Sunucuları durdurmak için terminal pencerelerini kapatın" -ForegroundColor Gray

Read-Host "Devam etmek için Enter'a basın"
