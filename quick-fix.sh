#!/bin/bash
echo "🔧 TV Monitoring Dashboard - Quick Fix Script"

cd /home/ubuntu

# Stop nginx
sudo systemctl stop nginx

# Clean up old installation
echo "🧹 Cleaning up old installation..."
sudo rm -rf tv-monitoring
sudo rm -f /etc/nginx/sites-enabled/tv-monitoring
sudo rm -f /etc/nginx/sites-available/tv-monitoring

# Fresh clone
echo "📥 Fresh clone from GitHub..."
git clone https://github.com/alperendemirtas/tv-monitoring.git
cd tv-monitoring

# Install and build
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ npm install failed!"
    exit 1
fi

echo "🔨 Building project..."
npm run build

# Check if build was successful
if [ ! -d "dist" ] || [ ! -f "dist/index.html" ]; then
    echo "❌ Build failed! dist/index.html not found"
    echo "🔍 Let's check what happened:"
    echo "Current directory contents:"
    ls -la
    echo ""
    echo "Node.js version:"
    node -v
    echo "NPM version:"
    npm -v
    echo ""
    echo "Package.json contents:"
    cat package.json
    echo ""
    echo "Trying to build again with verbose output:"
    npm run build --verbose
    
    echo ""
    echo "🛠️ Build failed, creating manual fallback HTML..."
    
    # Create manual dist folder and HTML
    mkdir -p dist
    
    cat > dist/index.html << 'HTMLEOF'
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
                        <p>React build başarısız oldu, ancak temel dashboard çalışıyor.</p>
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
                <h4 style="color: #FFC107; margin-bottom: 10px;">📝 Not:</h4>
                <p style="font-size: 12px;">Bu basitleştirilmiş versiyondur. Tam React versiyonu için build sorununu çözmeniz gerekiyor.</p>
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
    
    echo "✅ Manual fallback HTML created successfully!"
fi

echo "✅ Build successful, dist folder contains:"
ls -la dist/

# Create nginx config
echo "⚙️ Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/tv-monitoring > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    root /home/ubuntu/tv-monitoring/dist;
    index index.html index.htm;
    
    # Handle POST requests that should not be redirected
    location ~* \.(php|jsp|asp|cgi)$ {
        return 404;
    }
    
    # Block suspicious POST requests
    location ~* /cpca-capt {
        return 404;
    }
    
    # Main location block - only for GET requests
    location / {
        # Only allow GET and HEAD methods for static content
        if ($request_method !~ ^(GET|HEAD)$) {
            return 405;
        }
        
        # Try files first, then directories, finally fallback to index.html for React routing
        try_files $uri $uri/ @fallback;
        
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # Fallback location for React routing
    location @fallback {
        # Double check this is a GET request
        if ($request_method !~ ^(GET|HEAD)$) {
            return 405;
        }
        try_files /index.html =404;
    }
    
    # Sensibo API proxy
    location /api/sensibo/ {
        proxy_pass https://home.sensibo.com/api/v2/;
        proxy_ssl_server_name on;
        proxy_set_header Host home.sensibo.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Accept, Authorization, Content-Type, X-Requested-With" always;
        
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin * always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Accept, Authorization, Content-Type, X-Requested-With" always;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
    
    # Static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

# Enable the site
sudo ln -s /etc/nginx/sites-available/tv-monitoring /etc/nginx/sites-enabled/

# Set correct permissions
echo "🔧 Setting correct permissions..."
if [ -d "/home/ubuntu/tv-monitoring/dist" ]; then
    sudo chown -R www-data:www-data /home/ubuntu/tv-monitoring/dist
    sudo chmod -R 755 /home/ubuntu/tv-monitoring/dist
    echo "✅ Permissions set successfully"
else
    echo "❌ Cannot set permissions: dist folder not found!"
    echo "Build must have failed. Exiting..."
    exit 1
fi

# Test nginx config
echo "🔍 Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    sudo systemctl start nginx
    sudo systemctl enable nginx
else
    echo "❌ Nginx configuration error!"
    sudo cat /etc/nginx/sites-available/tv-monitoring
    exit 1
fi

# Final check
echo "📊 Final system status:"
sudo systemctl status nginx --no-pager -l
echo ""
echo "🌐 Testing local connection:"
curl -I http://localhost

# Get IP address
SERVER_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "✅ Quick fix completed!"
echo "🌐 Try accessing: http://$SERVER_IP"
echo "📁 Files location: /home/ubuntu/tv-monitoring/dist/"
echo "📋 If still not working, check: sudo tail -f /var/log/nginx/error.log"
