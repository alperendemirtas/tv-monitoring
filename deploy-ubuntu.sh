#!/bin/bash
# TV Monitoring Dashboard - Ubuntu Deployment Script

echo "🚀 TV Monitoring Dashboard - Ubuntu Deployment Started"

# System update
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs git nginx

# Verify installations
echo "✅ Verifying installations..."
echo "Node.js version: $(node -v)"
echo "NPM version: $(npm -v)"
echo "Nginx version: $(nginx -v)"

# Clone project
echo "📥 Cloning TV Monitoring Dashboard from GitHub..."
cd /home/ubuntu
git clone https://github.com/alperendemirtas/tv-monitoring.git
cd tv-monitoring

# Install dependencies
echo "📦 Installing project dependencies..."
npm install

# Build project
echo "🔨 Building project..."
npm run build

# Configure Nginx
echo "⚙️ Configuring Nginx..."
sudo rm -f /etc/nginx/sites-enabled/default

# Create nginx config for TV monitoring
sudo tee /etc/nginx/sites-available/tv-monitoring > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    
    root /home/ubuntu/tv-monitoring/dist;
    index index.html;
    
    # React router support
    location / {
        try_files $uri /index.html;
    }
    
    # Sensibo API proxy (CORS için gerekli)
    location /api/sensibo/ {
        proxy_pass https://home.sensibo.com/api/v2/;
        proxy_ssl_server_name on;
        proxy_set_header Host home.sensibo.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization";
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }
    
    # Static asset caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/tv-monitoring /etc/nginx/sites-enabled/

# Test nginx configuration
echo "🔍 Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    sudo systemctl restart nginx
else
    echo "❌ Nginx configuration error!"
    exit 1
fi

# Configure firewall
echo "🔒 Configuring firewall..."
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# Set correct permissions
sudo chown -R www-data:www-data /home/ubuntu/tv-monitoring/dist
sudo chmod -R 755 /home/ubuntu/tv-monitoring/dist

# Final status check
echo "📊 Final status check..."
sudo systemctl status nginx --no-pager -l

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ TV Monitoring Dashboard Deployment Completed!"
echo "🌐 Your dashboard is available at: http://$SERVER_IP"
echo ""
echo "📝 Next steps:"
echo "1. Open http://$SERVER_IP in your browser"
echo "2. Hover over ⚙️ icon in bottom right"
echo "3. Enter your OpManager URL"
echo "4. Enter your Sensibo API key"
echo "5. Click 'Kaydet' to save settings"
echo ""
echo "🔄 To update later, run:"
echo "   cd /home/ubuntu/tv-monitoring && ./update-dashboard.sh"
