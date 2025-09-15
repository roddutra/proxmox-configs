# Homelab Overview: Proxmox Docker Infrastructure

## Table of Contents
- [Infrastructure Overview](#infrastructure-overview)
- [Proxmox Host Configuration](#proxmox-host-configuration)
- [LXC Container Architecture](#lxc-container-architecture)
- [Storage Configuration](#storage-configuration)
- [Docker Services](#docker-services)
- [USB Device Passthrough](#usb-device-passthrough)
- [Network Architecture](#network-architecture)

## Infrastructure Overview

This homelab consists of a **Proxmox Virtual Environment (PVE)** host running a single **Ubuntu LXC container** that hosts all Docker services managed through **Portainer**. The setup emphasizes containerization, centralized management, and efficient resource utilization.

### Key Components
- **Hypervisor**: Proxmox VE (bare-metal virtualization platform)
- **Virtualization**: LXC (Linux Container) - Privileged mode for Docker compatibility
- **LXC Operating System**: Ubuntu 24.04 LTS
- **Docker Management**: Portainer CE for web-based Docker administration
- **Services**: 18 Docker containers providing various homelab services

## Proxmox Host Configuration

### System Specifications
- **Platform**: Single Proxmox host server
- **Storage**: Single internal drive for system and VMs
- **External Storage**: TOSHIBA USB Drive (900GB) for media storage
- **USB Devices**: Conbee II Zigbee controller

### Container Details
```
Container ID: 103
Container Name: Docker-LXC
Mode: Privileged (required for Docker functionality)
Resources:
  - CPU Cores: 4
  - Memory: 16GB
  - Swap: 8GB
  - Root Disk: 100GB (local-lvm storage)
```

## LXC Container Architecture

### Why LXC + Docker?
The architecture uses an LXC container running Docker, providing:
1. **Resource Isolation**: LXC provides OS-level virtualization with minimal overhead
2. **Docker Compatibility**: Privileged LXC allows full Docker functionality
3. **Centralized Management**: All services in one container for easier backup/migration
4. **Performance**: Near-native performance compared to full VMs

### Container Configuration
- **Privileged Mode**: Enabled (`unprivileged: 0`)
- **Nesting**: Enabled (allows Docker within LXC)
- **Features**: `mknod=1,nesting=1` for Docker compatibility
- **Network**: Bridge mode (vmbr0) with static IP
- **Boot Order**: Priority 1, 15-second startup delay

## Storage Configuration

### Primary Storage (Proxmox Host)
```
local-lvm: LVM thin pool on internal drive
  └── Container Root FS: 100GB allocated
      └── /root/: Docker service configuration directories
```

### External Storage
```
TOSHIBA USB Drive (900GB)
  Host: /dev/sdb
  Container Mount: /mnt/Toshiba_USB_Drive
  Purpose: Plex media library storage
  Mount Type: Raw disk passthrough (vm-103-disk-0.raw)

USB SSD Drive (250GB)
  Host: /dev/sdc1 → /mnt/shared-storage/usb-ssd
  Container Mount: /mnt/shared-media
  Purpose: Shared storage across multiple containers
  Mount Type: Host mount + bind mount
```

### Shared Storage Architecture
The homelab uses a **UUID-based mounting strategy** for reliable USB storage across reboots. Both external USB drives are mounted on the Proxmox host using UUIDs in `/etc/fstab` to ensure consistent device identification regardless of USB enumeration order.

**fstab configuration template:**
```
UUID=<your-toshiba-uuid> /mnt/Toshiba_USB_Drive ext4 defaults 0 0
UUID=<your-usb-ssd-uuid> /mnt/shared-storage/usb-ssd ext4 defaults,nofail 0 0
```

**Find your drive UUIDs:**
```bash
# List all device UUIDs
blkid

# Or show filesystem info
lsblk -f
```

**Why UUIDs are Critical:**
- USB device paths (`/dev/sdb1`, `/dev/sdc1`) can change between reboots
- UUIDs remain constant regardless of device enumeration order
- Prevents boot failures when USB devices are detected in different sequences
- The `nofail` option ensures system boots even if USB drive is temporarily unavailable

**USB SSD Shared Storage Structure:**
```
Proxmox Host: /mnt/shared-storage/usb-ssd/
├── media/              # Shared media library
├── downloads/          # Shared download location  
├── config/             # Shared configuration storage
└── backups/            # Backup staging area
```

**Container Access via Host Mount + Bind Mount:**
- Multiple LXC containers can bind mount `/mnt/shared-storage/usb-ssd`
- Enables services like Plex and Jellyfin to access the same media files
- Centralized storage management with no file duplication
- Docker containers within LXC access via volume binds to the mounted path

### Docker Volume Organization
Each service has a dedicated directory in `/root/` that serves as a bind mount:
```
/root/
├── adguardhome/        # DNS ad-blocking
├── grafana/            # Monitoring dashboards
├── homeassistant/      # Home automation (not used)
├── nginx-proxy-manager/# Reverse proxy
├── plex/               # Media server (data on external drives)
├── portainer/          # Docker management UI
├── postgres/           # Database server
├── transmission/       # BitTorrent client
├── uptime-kuma/        # Service monitoring
├── zigbee2mqtt/        # Zigbee device management
└── [20+ other services]
```

## Docker Services

### Service Management
- **Orchestration**: Docker Compose stacks via Portainer
- **Configuration**: Each service has its own directory with persistent data
- **Networking**: Custom Docker networks for inter-service communication
- **Updates**: Managed through Portainer's stack interface

### Key Services Running

#### Infrastructure Services
- **Portainer**: Docker management GUI (port 9000/9443)
- **Nginx Proxy Manager**: Reverse proxy with SSL termination
- **AdGuard Home**: Network-wide ad blocking and DNS

#### Media Services
- **Plex**: Media server with library on external TOSHIBA drive
- **Transmission/Deluge/qBittorrent**: Download clients
- **Homarr**: Customizable dashboard

#### Monitoring & Analytics
- **Grafana**: Metrics visualization
- **InfluxDB**: Time-series database
- **Uptime Kuma**: Service uptime monitoring
- **Metabase**: Data analytics platform

#### Automation & Integration
- **n8n**: Workflow automation
- **Zigbee2MQTT**: Zigbee device integration
- **Mosquitto**: MQTT broker

#### Databases
- **PostgreSQL**: Multiple instances for different services
- **MariaDB**: MySQL-compatible database

## USB Device Passthrough

### Conbee II Zigbee Controller
The Zigbee controller is passed through from the Proxmox host to the LXC container:

```
Physical Device: USB Conbee II
Host Detection: /dev/conbee
Container Access: /dev/ttyACM0
Used By: zigbee2mqtt Docker container
Configuration: LXC cgroup rules for device access
```

**LXC Configuration:**
```bash
lxc.cgroup2.devices.allow: c 166:* rwm
lxc.mount.entry: /dev/conbee dev/ttyACM0 none bind,optional,create=file
```

## Network Architecture

### Network Topology
```
Internet Gateway (192.168.1.1)
         │
    Proxmox Bridge (vmbr0)
         │
    LXC Container (192.168.1.3)
         │
    Docker Bridge Network
         │
    ├── Container Networks
    │   ├── frontend_network
    │   ├── backend_network
    │   └── database_network
    │
    └── Service Containers
        └── Exposed ports via host networking
```

### Network Configuration
- **Container IP**: Static (192.168.1.3)
- **Gateway**: 192.168.1.1
- **DNS**: Managed by AdGuard Home
- **Docker Networks**: Multiple custom networks for service isolation


## Backup & Recovery

### Backup Components
- **Docker Volumes**: Individual tarballs for each service volume
- **Configuration Directories**: Compressed archives of `/root/` subdirectories
- **Docker Networks**: Exported network configurations
- **Container Lists**: Documentation of running containers

### Recovery Process
1. Create new container with identical specifications
2. Install Docker and Portainer
3. Restore Docker volumes
4. Restore configuration directories
5. Recreate Docker networks
6. Deploy services via Portainer stacks

## Security Considerations

### Container Security
- **Privileged Mode**: Required for Docker but increases attack surface
- **Root Access**: Services run as root within container (isolated from host)
- **SSH Access**: Password authentication enabled for management

### Network Security
- **Firewall**: Enabled on container network interface
- **Reverse Proxy**: Nginx Proxy Manager handles external access
- **Ad Blocking**: AdGuard Home provides DNS-level filtering

## Maintenance & Operations

### Regular Tasks
- **Updates**: OS and Docker updates via apt
- **Backups**: Scheduled backups of critical data
- **Monitoring**: Uptime Kuma tracks service availability
- **Log Management**: Docker logs rotated automatically

### Access Methods
- **SSH**: Direct root access to container
- **Portainer**: Web UI for Docker management
- **Proxmox Console**: Emergency access via host
- **Service UIs**: Individual web interfaces for each service

## Conclusion

This homelab leverages Proxmox's virtualization capabilities with LXC containers to create an efficient, manageable Docker hosting environment. The architecture provides excellent performance, easy backup/migration capabilities, and centralized management while maintaining service isolation through Docker containers. Running Ubuntu 24.04 LTS ensures long-term stability and continued security updates.