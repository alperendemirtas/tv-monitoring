#!/bin/bash
# TV Monitoring Dashboard - Health Check Script

LOG_FILE="/var/log/tv-monitoring-health.log"
DASHBOARD_URL="http://localhost"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a $LOG_FILE
}

# Check if nginx is running
if ! systemctl is-active --quiet nginx; then
    log_message "⚠️ Nginx is down, attempting to restart..."
    sudo systemctl start nginx
    
    if systemctl is-active --quiet nginx; then
        log_message "✅ Nginx restarted successfully"
    else
        log_message "❌ Failed to restart Nginx"
        exit 1
    fi
fi

# Check if dashboard is accessible
if ! curl -f -s $DASHBOARD_URL >/dev/null 2>&1; then
    log_message "⚠️ Dashboard not accessible, attempting to rebuild..."
    
    cd /home/ubuntu/tv-monitoring
    
    # Try to rebuild
    if npm run build >/dev/null 2>&1; then
        sudo chown -R www-data:www-data /home/ubuntu/haus-monitoring/dist
        sudo chmod -R 755 /home/ubuntu/haus-monitoring/dist
        sudo systemctl restart nginx
        log_message "✅ Dashboard rebuilt and Nginx restarted"
    else
        log_message "❌ Dashboard rebuild failed"
        exit 1
    fi
fi

# Check disk space (warn if less than 1GB free)
AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
if [ $AVAILABLE_SPACE -lt 1048576 ]; then # 1GB in KB
    log_message "⚠️ Low disk space: $(df -h / | awk 'NR==2 {print $4}') available"
fi

# Success - log only if there were issues (to avoid log spam)
# Uncomment the next line if you want to log every successful check
# log_message "✅ Health check passed"
