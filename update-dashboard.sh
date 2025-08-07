#!/bin/bash
# TV Monitoring Dashboard - Update Script

echo "🔄 Updating TV Monitoring Dashboard..."

cd /home/ubuntu/haus-monitoring

# Backup current build
echo "💾 Creating backup..."
sudo cp -r dist dist.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Pull latest changes
echo "📥 Pulling latest changes from GitHub..."
git pull origin main

# Check if pull was successful
if [ $? -ne 0 ]; then
    echo "❌ Git pull failed!"
    exit 1
fi

# Install any new dependencies
echo "📦 Installing dependencies..."
npm install

# Rebuild project
echo "🔨 Rebuilding project..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    if [ -d "dist.backup.$(date +%Y%m%d)_*" ]; then
        echo "🔄 Restoring backup..."
        sudo rm -rf dist
        sudo mv dist.backup.* dist
    fi
    exit 1
fi

# Set correct permissions
sudo chown -R www-data:www-data /home/ubuntu/haus-monitoring/dist
sudo chmod -R 755 /home/ubuntu/haus-monitoring/dist

# Test nginx configuration
sudo nginx -t

if [ $? -eq 0 ]; then
    # Restart nginx
    sudo systemctl restart nginx
    echo "✅ Dashboard updated and Nginx restarted successfully!"
    
    # Clean old backups (keep last 3)
    find . -name "dist.backup.*" -type d | sort | head -n -3 | xargs rm -rf
    
    echo "🌐 Dashboard is running at: http://$(hostname -I | awk '{print $1}')"
else
    echo "❌ Nginx configuration error!"
    exit 1
fi
