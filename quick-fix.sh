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

echo "🔨 Building project..."
npm run build

# Check if build was successful
if [ ! -d "dist" ] || [ ! -f "dist/index.html" ]; then
    echo "❌ Build failed! dist/index.html not found"
    exit 1
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
sudo chown -R www-data:www-data /home/ubuntu/tv-monitoring/dist
sudo chmod -R 755 /home/ubuntu/tv-monitoring/dist

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
