# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains Docker Compose configurations and setup instructions for services running on a Proxmox server within LXC containers using Portainer for container management.

## Architecture

- **Host**: Proxmox VE hypervisor
- **Container Type**: LXC (Linux Containers) running Ubuntu
- **Container Management**: Docker with Portainer
- **Services**: 20+ containerized services including Home Assistant, Traefik, AdGuard Home, various databases, and media services
- **Network Configuration**: Static IPs within 192.168.1.x range

## Common Commands

### Docker Operations
```bash
# View running containers
docker ps

# View logs for a container
docker logs [container_name]

# Restart a container
docker restart [container_name]

# Access container shell
docker exec -it [container_name] /bin/bash
# or for Alpine-based containers:
docker exec -it [container_name] /bin/sh
```

### Docker Compose Operations
```bash
# Deploy a stack (from service directory)
docker-compose up -d

# Stop and remove containers
docker-compose down

# View logs
docker-compose logs -f

# Rebuild and restart
docker-compose up -d --force-recreate --build
```

## Directory Structure

Each service in `/docker/` has its own directory containing:
- `docker-compose.yml` - Service configuration
- `README.md` (optional) - Service-specific setup instructions
- Configuration files specific to that service

## Key Configuration Patterns

### Docker Compose Structure
- All compose files use version '3' or higher
- Services typically include:
  - Container name matching the service
  - Restart policy: `unless-stopped` or `always`
  - Volume mounts to `/root/[service_name]` for persistent data
  - Network mode: usually `bridge` unless sharing VPN (e.g., Gluetun)
  - Environment variables for configuration

### Volume Mounting Pattern
```yaml
volumes:
  - /root/[service_name]/config:/config
  - /root/[service_name]/data:/data
```

### Port Mapping Pattern
```yaml
ports:
  - "host_port:container_port"
```

## Special Configurations

### VPN Services (Gluetun)
- Services like Deluge share Gluetun's network using `network_mode: "service:gluetun"`
- Requires LXC container to be privileged with `/dev/net/tun` access

### USB Device Mapping (Zigbee Coordinators)
- USB devices mapped via LXC configuration in `/etc/pve/lxc/{NODE_ID}.conf`
- Device access through `/dev/ttyACM0` or similar

### Services Requiring Special Ports
- AdGuard Home requires disabling `systemd-resolved` to free up port 53
- Configuration in `/etc/systemd/resolved.conf`

## Service Dependencies

- **Home Assistant**: May depend on MariaDB/InfluxDB for history, Eclipse Mosquitto for MQTT
- **Zigbee2mqtt**: Requires Eclipse Mosquitto MQTT broker
- **Media Services**: Plex, Transmission, Deluge may share media directories
- **Reverse Proxy**: Traefik or Nginx Proxy Manager for SSL and routing

## Network Configuration

- Default gateway: `192.168.1.1`
- LXC container IP example: `192.168.1.2/24`
- Services exposed on various ports, documented in each `docker-compose.yml`

## Important Notes

- AppArmor must be uninstalled in the LXC container for Portainer to work
- LXC containers should be privileged for VPN functionality
- Nesting and "Create Device Nodes" features should be enabled in LXC options
- Always create required directories before deploying services
- Check file permissions, especially for config files (e.g., `chmod 600` for sensitive files)