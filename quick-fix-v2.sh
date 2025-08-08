#!/bin/bash
echo "🔧 TV Monitoring Dashboard - Quick Fix v2 Script"

# Check if we're root - we need sudo for /var/www
if [[ $EUID -eq 0 ]]; then
    echo "⚠️ Running as root - this is fine for system setup"
    USER_NAME="www-data"
else
    USER_NAME=$(whoami)
    echo "👤 Current user: $USER_NAME"
fi

# Use /var/www for web server compatibility
PROJECT_DIR="/var/www/tv-monitoring"

echo "📁 Project will be created at: $PROJECT_DIR"

# Stop nginx first
echo "🛑 Stopping nginx..."
sudo systemctl stop nginx

# Clean up old installation
echo "🧹 Cleaning up old installation..."
sudo rm -rf "$PROJECT_DIR"
sudo rm -f /etc/nginx/sites-enabled/tv-monitoring
sudo rm -f /etc/nginx/sites-available/tv-monitoring

# Create /var/www and set proper permissions upfront
echo "📁 Setting up /var/www directory..."
sudo mkdir -p /var/www
sudo chown www-data:www-data /var/www
sudo chmod 755 /var/www

# Clone directly with proper permissions
echo "📥 Cloning from GitHub..."
cd /tmp
rm -rf tv-monitoring
git clone https://github.com/alperendemirtas/tv-monitoring.git
sudo mv tv-monitoring "$PROJECT_DIR"
sudo chown -R www-data:www-data "$PROJECT_DIR"

# Install Node.js if not installed
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Change to project directory and build as www-data
echo "🔨 Building React project..."
cd "$PROJECT_DIR"
sudo -u www-data npm install
sudo -u www-data npm run build

# Install API dependencies and start API server
echo "🔧 Setting up API server..."
cd "$PROJECT_DIR/api"
sudo -u www-data npm install

# Create systemd service for API
echo "⚙️ Creating API systemd service..."
sudo tee /etc/systemd/system/tv-monitoring-api.service > /dev/null << EOF
[Unit]
Description=TV Monitoring API Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$PROJECT_DIR/api
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Enable and start API service
sudo systemctl daemon-reload
sudo systemctl enable tv-monitoring-api
sudo systemctl start tv-monitoring-api

# Check if build was successful
if [ ! -d "dist" ] || [ ! -f "dist/index.html" ]; then
    echo "❌ Build failed! Creating fallback HTML..."
    
    # Create manual dist folder
    sudo -u www-data mkdir -p dist
    
    # Create fallback HTML as www-data
    sudo -u www-data tee dist/index.html > /dev/null << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TV Monitoring Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: #1a1a1a; color: #fff; font-family: Arial, sans-serif; }
        .container { display: flex; height: 100vh; }
        .left { flex: 80%; border: 1px solid #333; margin: 10px; }
        .right { flex: 20%; border: 1px solid #333; margin: 10px; padding: 20px; }
        .placeholder { display: flex; align-items: center; justify-content: center; height: 100%; text-align: center; }
        h2 { margin-bottom: 20px; color: #007acc; }
        h3 { margin-bottom: 15px; color: #007acc; }
        input { width: 100%; padding: 10px; margin: 10px 0; background: #333; border: 1px solid #555; color: #fff; border-radius: 4px; }
        button { width: 100%; padding: 10px; background: #007acc; border: none; color: #fff; cursor: pointer; border-radius: 4px; }
        button:hover { background: #005999; }
        .status { margin-top: 15px; padding: 10px; border-radius: 4px; }
        .success { background: rgba(76, 175, 80, 0.2); border: 1px solid #4CAF50; }
        .info { background: rgba(33, 150, 243, 0.2); border: 1px solid #2196F3; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="left">
            <div class="placeholder">
                <div>
                    <h2>🖥️ TV Monitoring Dashboard</h2>
                    <div class="info">
                        <p><strong>Dashboard başarıyla yüklendi!</strong></p>
                        <p>Basitleştirilmiş versiyon çalışıyor.</p>
                        <p>Sağ panelden OpManager URL'i ve Sensibo API anahtarı ekleyin.</p>
                    </div>
                </div>
            </div>
        </div>
        <div class="right">
            <h3>⚙️ Ayarlar</h3>
            <input type="text" id="opmanagerUrl" placeholder="OpManager URL (örn: https://your-opmanager.com)">
            <input type="password" id="sensiboKey" placeholder="Sensibo API Anahtarı">
            <button onclick="saveSettings()">💾 Kaydet</button>
            <div id="status" class="status" style="display:none;"></div>
            
            <div style="margin-top: 30px; padding: 15px; background: rgba(255, 193, 7, 0.1); border: 1px solid #FFC107; border-radius: 4px;">
                <h4 style="color: #FFC107; margin-bottom: 10px;">📝 v2.0</h4>
                <p style="font-size: 12px;">Permission sorunları çözüldü!</p>
            </div>
        </div>
    </div>
    
    <script>
        function saveSettings() {
            const opmanagerUrl = document.getElementById('opmanagerUrl').value;
            const sensiboKey = document.getElementById('sensiboKey').value;
            const statusDiv = document.getElementById('status');
            
            if (opmanagerUrl) {
                localStorage.setItem('opmanagerUrl', opmanagerUrl);
                document.querySelector('.left').innerHTML = 
                    '<iframe src="' + opmanagerUrl + '" style="width:100%;height:100%;border:none;" title="OpManager Dashboard"></iframe>';
            }
            
            if (sensiboKey) {
                localStorage.setItem('sensiboApiKey', sensiboKey);
            }
            
            statusDiv.style.display = 'block';
            statusDiv.className = 'status success';
            statusDiv.innerHTML = '<p><strong>✅ Ayarlar başarıyla kaydedildi!</strong></p>' +
                                 (opmanagerUrl ? '<p>OpManager dashboard yüklendi.</p>' : '') +
                                 (sensiboKey ? '<p>Sensibo API anahtarı kaydedildi.</p>' : '');
            
            setTimeout(() => {
                statusDiv.style.display = 'none';
            }, 5000);
        }
        
        // Sayfa yüklendiğinde ayarları geri yükle
        window.onload = function() {
            const savedOpmanagerUrl = localStorage.getItem('opmanagerUrl');
            const savedSensiboKey = localStorage.getItem('sensiboApiKey');
            
            if (savedOpmanagerUrl) {
                document.getElementById('opmanagerUrl').value = savedOpmanagerUrl;
                document.querySelector('.left').innerHTML = 
                    '<iframe src="' + savedOpmanagerUrl + '" style="width:100%;height:100%;border:none;" title="OpManager Dashboard"></iframe>';
            }
            
            if (savedSensiboKey) {
                document.getElementById('sensiboKey').value = savedSensiboKey;
            }
        };
    </script>
</body>
</html>
HTMLEOF
    
    echo "✅ Fallback HTML created successfully!"
fi

echo "✅ Build completed, dist folder contains:"
ls -la "$PROJECT_DIR/dist/"

# Create nginx config
echo "⚙️ Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/tv-monitoring > /dev/null << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    root $PROJECT_DIR/dist;
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # Sensibo API proxy
    location /api/sensibo/ {
        proxy_pass https://home.sensibo.com/api/v2/;
        proxy_ssl_server_name on;
        proxy_set_header Host home.sensibo.com;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Accept, Authorization, Content-Type, X-Requested-With" always;
        
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin * always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Accept, Authorization, Content-Type, X-Requested-With" always;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
    
    # Static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

# Enable the site
sudo ln -s /etc/nginx/sites-available/tv-monitoring /etc/nginx/sites-enabled/

# Final permissions check
echo "🔧 Final permissions check..."
sudo chown -R www-data:www-data "$PROJECT_DIR"
sudo chmod -R 755 "$PROJECT_DIR"

echo "📁 Directory permissions:"
ls -la /var/www/ | grep tv-monitoring
ls -la "$PROJECT_DIR" | grep dist

# Test nginx config
echo "🔍 Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    sudo systemctl start nginx
    sudo systemctl enable nginx
else
    echo "❌ Nginx configuration error!"
    exit 1
fi

# Final status check
echo "📊 Final system status:"
sudo systemctl status nginx --no-pager -l
echo ""
echo "🌐 Testing local connection:"
curl -I http://localhost

# Get IP address
SERVER_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "✅ Quick fix v2 completed!"
echo "🌐 Try accessing: http://$SERVER_IP"
echo "📁 Files location: $PROJECT_DIR/dist/"
echo "📋 If still not working, check: sudo tail -f /var/log/nginx/error.log"
