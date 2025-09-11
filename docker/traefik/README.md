# Traefik Setup for Local Network

This configuration sets up Traefik as a reverse proxy for your local homelab services, providing:
- Local domain names (e.g., `service.homelab.local` instead of `192.168.1.x:port`)
- HTTPS with self-signed or locally-trusted certificates
- Automatic Docker service discovery
- Clean, professional URLs for all your services

## Quick Start

### 1. Generate SSL Certificates

Run the certificate generation script:
```bash
./generate-certs.sh
```

Choose either:
- Option 1: Self-signed certificates (browser warnings, but works immediately)
- Option 2: mkcert (no warnings, requires mkcert installation)

### 2. Create Docker Network

On your Proxmox LXC container:
```bash
docker network create proxy
```

### 3. Configure AdGuard DNS

In your AdGuard Home admin panel (http://YOUR-ADGUARD-IP:81):
1. Go to **Filters** → **DNS rewrites**
2. Add a wildcard rewrite:
   - Domain: `*.homelab.local`
   - IP: Your Ubuntu LXC container IP where Traefik runs

### 4. Prepare Traefik Directories

On your Proxmox LXC container:
```bash
# Create directory structure
mkdir -p /root/traefik/data
mkdir -p /root/traefik/certs

# Copy configuration files
# (Copy traefik.yml and config.yml to /root/traefik/data/)
# (Copy generated certificates to /root/traefik/certs/)
```

### 5. Deploy Traefik

```bash
docker-compose up -d
```

### 6. Configure Your Services

Add Traefik labels to your existing Docker services. See `DOCKER_SERVICE_EXAMPLES.md` for detailed examples.

## Files Overview

- `docker-compose.yml` - Main Traefik container configuration
- `traefik.yml` - Traefik static configuration (local certs, no Cloudflare)
- `config.yml` - File provider for non-Docker services (Proxmox host)
- `generate-certs.sh` - Script to generate SSL certificates
- `DOCKER_SERVICE_EXAMPLES.md` - Examples for configuring Docker services
- `SETUP_GUIDE.md` - Detailed setup and troubleshooting guide

## Accessing Services

Once configured, your main services will be available at:
- **Traefik Dashboard**: https://traefik.homelab.local (default: admin/admin)
- **Main Dashboard**: https://dashboard.homelab.local (Homarr)
- **Proxmox**: https://proxmox.homelab.local
- **Home Assistant**: https://homeassistant.homelab.local
- **Plex**: https://plex.homelab.local
- **AdGuard**: https://adguard.homelab.local
- And many more...

See `SERVICE_URLS.md` for the complete list of all service URLs.

## Changing Dashboard Password

Generate a new password:
```bash
# Install htpasswd if not available
apt update && apt install apache2-utils

# Generate password (replace 'admin' with your username)
echo $(htpasswd -nB admin) | sed -e s/\\$/\\$\\$/g
```

Update the `traefik.http.middlewares.traefik-auth.basicauth.users` label in `docker-compose.yml`.

## Troubleshooting

1. **DNS not resolving**: 
   - Check AdGuard DNS rewrites
   - Ensure AdGuard is your network's DNS server
   - Test with `nslookup traefik.homelab.local`

2. **Certificate warnings**: 
   - Expected with self-signed certs
   - Use mkcert for trusted certificates
   - Or add browser exception

3. **Service not accessible**: 
   - Check `docker logs traefik`
   - Ensure service is on the proxy network
   - Verify labels are correct

4. **Port conflicts**: 
   - Ensure ports 80 and 443 are free
   - Check with `netstat -tulpn | grep -E ':80|:443'`

## Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [mkcert - Local CA tool](https://github.com/FiloSottile/mkcert)
