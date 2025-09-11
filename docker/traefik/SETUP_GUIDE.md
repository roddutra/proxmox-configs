# Traefik Local Network Setup Guide

This guide will help you set up Traefik as a reverse proxy for your Proxmox homelab with local domain names and HTTPS.

## Overview

This setup provides:
- Local domain access (e.g., `plex.homelab.local` instead of `192.168.1.x:port`)
- Valid HTTPS certificates without browser warnings
- Automatic service discovery for Docker containers
- Manual configuration for non-Docker services (Proxmox, VMs)

## Architecture

```
[Client Device] 
    ↓ (DNS Query)
[AdGuard Home] → Resolves *.homelab.local to Traefik IP
    ↓
[Traefik] → Routes to appropriate service
    ↓
[Service] (Container or VM)
```

## Step 1: Configure AdGuard Home DNS

### Option A: Wildcard DNS (Recommended)
In AdGuard Home web interface (http://YOUR-ADGUARD-IP:81):

1. Go to **Filters** → **DNS rewrites**
2. Add a new rewrite:
   - Domain: `*.homelab.local`
   - IP Address: `192.168.1.2` (Your Traefik container IP)

### Option B: Individual Service Entries
Add individual DNS rewrites for each service:
- `traefik.homelab.local` → `192.168.1.2`
- `plex.homelab.local` → `192.168.1.2`
- `homeassistant.homelab.local` → `192.168.1.2`
- etc.

## Step 2: Generate SSL Certificates

We'll use self-signed certificates for the local setup. Two options:

### Option A: Using OpenSSL (Quick Setup)
A script is provided to generate certificates: `generate-certs.sh`

### Option B: Using mkcert (Recommended for no warnings)
1. Install mkcert on your local machine
2. Generate and trust the root CA
3. Generate wildcard certificate
4. Copy certificates to Traefik

## Step 3: Deploy Traefik

1. Create required directories on your Proxmox LXC container:
```bash
mkdir -p /root/traefik/data
mkdir -p /root/traefik/certs
```

2. Copy configuration files:
- `traefik.yml` → `/root/traefik/data/traefik.yml`
- `config.yml` → `/root/traefik/data/config.yml`
- SSL certificates → `/root/traefik/certs/`

3. Deploy with Docker Compose:
```bash
cd /path/to/docker/traefik
docker-compose up -d
```

## Step 4: Configure Your Services

### For Docker Containers
Add labels to your docker-compose.yml files:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.service-name.rule=Host(`service.homelab.local`)"
  - "traefik.http.routers.service-name.entrypoints=https"
  - "traefik.http.routers.service-name.tls=true"
  - "traefik.http.services.service-name.loadbalancer.server.port=8080"
```

### For External Services (VMs, Proxmox)
Configure in `config.yml` file - see examples provided.

## Step 5: Access Your Services

Once configured, access your services at:
- https://traefik.homelab.local (Traefik dashboard)
- https://proxmox.homelab.local (Proxmox web interface)
- https://plex.homelab.local (Plex media server)
- https://homeassistant.homelab.local (Home Assistant)
- etc.

## Troubleshooting

### DNS Resolution Issues
1. Test DNS resolution: `nslookup service.homelab.local`
2. Ensure AdGuard is set as your network's DNS server
3. Clear DNS cache on client devices

### Certificate Warnings
1. If using self-signed certificates, add exception in browser
2. For mkcert, ensure root CA is trusted on all devices
3. Check certificate validity dates

### Service Not Accessible
1. Check Traefik logs: `docker logs traefik`
2. Verify service is running: `docker ps`
3. Check Traefik dashboard for routing rules
4. Ensure ports are not blocked by firewall

## Security Considerations

1. This setup is designed for LOCAL network use only
2. Do not expose Traefik ports to the internet without proper security
3. Use strong passwords for Traefik dashboard access
4. Regularly update Traefik and all services
5. Consider network segmentation for IoT devices

## Backup

Important files to backup:
- `/root/traefik/data/` - All Traefik configurations
- `/root/traefik/certs/` - SSL certificates
- AdGuard DNS rewrite rules
- Docker compose files for all services