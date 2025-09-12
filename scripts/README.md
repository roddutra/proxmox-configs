# Docker LXC Scripts

This directory contains utility scripts for managing Docker containers in Proxmox LXC environments.

## Scripts

### docker-optimization-setup.sh

A comprehensive setup script that configures Docker log rotation, system cleanup, and maintenance jobs to prevent storage buildup in Docker LXC containers.

#### Features:
- Configures Docker daemon with log rotation (10MB per file, max 3 files)
- Sets up weekly automated cleanup of unused Docker resources
- Configures system journal size limits (100MB max, 7 days retention)
- Creates monitoring scripts for storage analysis
- Performs initial cleanup of existing resources

#### Usage:

```bash
# Download and run on a new Docker LXC container
wget https://raw.githubusercontent.com/YOUR_USERNAME/proxmox-configs/main/scripts/docker-optimization-setup.sh
chmod +x docker-optimization-setup.sh
bash docker-optimization-setup.sh
```

Or if you have the repository cloned:

```bash
cd /path/to/proxmox-configs/scripts
chmod +x docker-optimization-setup.sh
bash docker-optimization-setup.sh
``` 

#### What it creates:

1. **`/etc/docker/daemon.json`** - Docker log rotation configuration
2. **`/root/docker-maintenance.sh`** - Weekly maintenance script
3. **`/root/check-docker-storage.sh`** - Storage monitoring script
4. **Cron job** - Runs maintenance every Sunday at 3 AM
5. **Journal limits** - `/etc/systemd/journald.conf.d/size-limit.conf`

#### After running the script:

- Check storage status: `/root/check-docker-storage.sh`
- Run maintenance manually: `/root/docker-maintenance.sh`
- View maintenance logs: `tail -f /var/log/docker-maintenance.log`
- Check scheduled jobs: `crontab -l`

#### Important Notes:

- Log rotation settings only apply to NEW containers
- To apply settings to existing containers, they need to be recreated
- The script must be run as root
- Docker must be installed before running the script

## Storage Optimization Results

Typical storage savings after optimization:
- Docker container logs: ~5-6GB reduction
- Unused images and volumes: ~1-2GB reduction
- System journals: ~200-300MB reduction
- Total savings: ~6-8GB immediate, prevents future buildup

## Maintenance Schedule

The automated maintenance runs weekly and performs:
- Remove dangling Docker images
- Remove stopped containers older than 1 week
- Remove unused Docker volumes
- Clean build cache older than 1 week
- Vacuum system journals older than 7 days
- Log current storage usage for monitoring
