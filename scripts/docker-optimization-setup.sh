#!/bin/bash
# Docker LXC Optimization Setup Script
# This script configures Docker log rotation, system cleanup, and maintenance jobs
# to prevent storage buildup in Docker LXC containers.
#
# Usage: bash docker-optimization-setup.sh
# Author: Generated for Proxmox Docker LXC containers
# Date: $(date +"%Y-%m-%d")

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

echo "========================================"
echo "Docker LXC Optimization Setup Script"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

print_status "Starting Docker optimization setup..."

# 1. Configure Docker daemon with log rotation
echo ""
echo "Step 1: Configuring Docker log rotation..."

if [ -f /etc/docker/daemon.json ]; then
    print_warning "Backing up existing daemon.json to daemon.json.bak"
    cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
fi

cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true"
  }
}
EOF

# Validate JSON
if python3 -m json.tool /etc/docker/daemon.json > /dev/null 2>&1; then
    print_status "Docker daemon.json configured successfully"
else
    print_error "Invalid JSON in daemon.json"
    exit 1
fi

# Reload Docker daemon
systemctl reload docker
print_status "Docker daemon reloaded"

# 2. Create maintenance script
echo ""
echo "Step 2: Creating Docker maintenance script..."

cat > /root/docker-maintenance.sh << 'MAINTENANCE_EOF'
#!/bin/bash
# Docker Maintenance Script - Run weekly to clean up unused resources

LOG_FILE="/var/log/docker-maintenance.log"

echo "=== Docker Maintenance Started: $(date) ===" | tee -a $LOG_FILE

# Clean up dangling images
echo "Cleaning dangling images..." | tee -a $LOG_FILE
docker image prune -f 2>&1 | tee -a $LOG_FILE

# Clean up stopped containers older than 1 week
echo "Cleaning old stopped containers..." | tee -a $LOG_FILE
docker container prune -f --filter "until=168h" 2>&1 | tee -a $LOG_FILE

# Clean up unused volumes
echo "Cleaning unused volumes..." | tee -a $LOG_FILE
docker volume prune -f 2>&1 | tee -a $LOG_FILE

# Clean up build cache older than 1 week
echo "Cleaning build cache..." | tee -a $LOG_FILE
docker builder prune -f --filter "until=168h" 2>&1 | tee -a $LOG_FILE

# Clean up old journal logs
echo "Cleaning system journals..." | tee -a $LOG_FILE
journalctl --vacuum-time=7d 2>&1 | tee -a $LOG_FILE

# Report disk usage
echo "" | tee -a $LOG_FILE
echo "Current disk usage:" | tee -a $LOG_FILE
df -h / | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Docker storage usage:" | tee -a $LOG_FILE
docker system df | tee -a $LOG_FILE

echo "=== Docker Maintenance Completed: $(date) ===" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Rotate maintenance log if it gets too large (keep last 1000 lines)
if [ $(wc -l < $LOG_FILE) -gt 2000 ]; then
    tail -n 1000 $LOG_FILE > $LOG_FILE.tmp
    mv $LOG_FILE.tmp $LOG_FILE
    echo "Log file rotated at $(date)" >> $LOG_FILE
fi
MAINTENANCE_EOF

chmod +x /root/docker-maintenance.sh
print_status "Docker maintenance script created at /root/docker-maintenance.sh"

# 3. Setup cron job for weekly maintenance
echo ""
echo "Step 3: Setting up weekly maintenance cron job..."

# Remove existing cron job if exists (to avoid duplicates)
crontab -l 2>/dev/null | grep -v 'docker-maintenance.sh' | crontab - 2>/dev/null || true

# Add new cron job (Sundays at 3 AM)
(crontab -l 2>/dev/null || true; echo "0 3 * * 0 /root/docker-maintenance.sh") | crontab -

print_status "Cron job configured for weekly maintenance (Sundays at 3 AM)"

# 4. Configure system journal size limits
echo ""
echo "Step 4: Configuring system journal limits..."

mkdir -p /etc/systemd/journald.conf.d/
cat > /etc/systemd/journald.conf.d/size-limit.conf << 'EOF'
[Journal]
SystemMaxUse=100M
SystemMaxFileSize=10M
MaxRetentionSec=7day
EOF

systemctl restart systemd-journald
print_status "System journal limits configured (max 100MB, 7 days retention)"

# 5. Initial cleanup
echo ""
echo "Step 5: Performing initial cleanup..."

# Clean journals
journalctl --vacuum-time=7d > /dev/null 2>&1
journalctl --vacuum-size=100M > /dev/null 2>&1
print_status "System journals cleaned"

# Clean Docker resources
docker image prune -f > /dev/null 2>&1
print_status "Dangling images removed"

docker volume prune -f > /dev/null 2>&1
print_status "Unused volumes removed"

# 6. Create monitoring script
echo ""
echo "Step 6: Creating storage monitoring script..."

cat > /root/check-docker-storage.sh << 'MONITOR_EOF'
#!/bin/bash
# Quick script to check Docker storage usage

echo "========================================"
echo "Docker Storage Report - $(date)"
echo "========================================"
echo ""
echo "Filesystem Usage:"
df -h / | grep -E "Filesystem|/"
echo ""
echo "Top directories in /root:"
du -h --max-depth=1 /root 2>/dev/null | sort -hr | head -10
echo ""
echo "Docker System Usage:"
docker system df
echo ""
echo "Docker Directory Breakdown:"
du -h --max-depth=1 /var/lib/docker/ 2>/dev/null | sort -hr | head -10
echo ""
echo "Large Docker Logs (>10MB):"
find /var/lib/docker/containers -name "*-json.log" -size +10M -exec ls -lh {} \; 2>/dev/null
echo ""
echo "Journal Disk Usage:"
journalctl --disk-usage
MONITOR_EOF

chmod +x /root/check-docker-storage.sh
print_status "Storage monitoring script created at /root/check-docker-storage.sh"

# 7. Final report
echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
print_status "Docker log rotation configured (10MB per file, max 3 files)"
print_status "Weekly maintenance scheduled (Sundays at 3 AM)"
print_status "System journal limits set (100MB max)"
print_status "Monitoring script available at /root/check-docker-storage.sh"
echo ""
echo "Useful commands:"
echo "  - Check storage: /root/check-docker-storage.sh"
echo "  - Run maintenance: /root/docker-maintenance.sh"
echo "  - View maintenance log: tail -f /var/log/docker-maintenance.log"
echo "  - Check cron jobs: crontab -l"
echo ""
echo "Current storage status:"
df -h / | grep -E "Filesystem|/"
echo ""
docker system df
echo ""
print_warning "Note: Log rotation settings only apply to NEW containers."
print_warning "Restart existing containers to apply new log settings if needed."
