# Configuring VPN-Protected Services with Traefik

This guide shows how to configure services that use Gluetun's VPN network with Traefik.

## Key Concept

When a service uses `network_mode: 'container:gluetun'`, all Traefik configuration must be on the Gluetun container, not the dependent service.

## Configuration Steps

### 1. Update Gluetun's docker-compose.yml

```yaml
version: '3'
services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    networks:
      - proxy  # Add this - Gluetun joins the proxy network
    ports:
      - 8888:8888/tcp # HTTP proxy
      - 8388:8388/tcp # Shadowsocks
      - 8388:8388/udp # Shadowsocks
      # qBittorrent WebUI port (if using qBittorrent)
      - 8082:8082
      # Deluge ports (if using Deluge)
      - 8112:8112
      - 6881-6889:6881-6889
      - 6881-6889:6881-6889/udp
      # Transmission ports (if using Transmission)
      - 9091:9091
      - 51413:51413
      - 51413:51413/udp
    volumes:
      - /root/gluetun:/gluetun
    environment:
      # Your existing VPN configuration
      - VPN_SERVICE_PROVIDER=nordvpn
      - OPENVPN_USER=<service_credentials_username>
      - OPENVPN_PASSWORD=<service_credentials_password>
      - SERVER_COUNTRIES=Australia
      - TZ=Australia/Brisbane
      - SHADOWSOCKS=on
      - SHADOWSOCKS_PASSWORD=<shadowsocks_password>
      - FIREWALL_OUTBOUND_SUBNETS=192.168.1.0/24
    labels:
      # Traefik labels for ALL services using this network
      - "traefik.enable=true"
      
      # qBittorrent labels
      - "traefik.http.routers.qbittorrent.rule=Host(`qbittorrent.homelab.local`)"
      - "traefik.http.routers.qbittorrent.entrypoints=https"
      - "traefik.http.routers.qbittorrent.tls=true"
      - "traefik.http.services.qbittorrent.loadbalancer.server.port=8082"
      
      # Deluge labels (if you use Deluge)
      - "traefik.http.routers.deluge.rule=Host(`deluge.homelab.local`)"
      - "traefik.http.routers.deluge.entrypoints=https"
      - "traefik.http.routers.deluge.tls=true"
      - "traefik.http.services.deluge.loadbalancer.server.port=8112"
      
      # Transmission labels (if you use Transmission)
      - "traefik.http.routers.transmission.rule=Host(`transmission.homelab.local`)"
      - "traefik.http.routers.transmission.entrypoints=https"
      - "traefik.http.routers.transmission.tls=true"
      - "traefik.http.services.transmission.loadbalancer.server.port=9091"

networks:
  proxy:
    external: true
```

### 2. qBittorrent Configuration (No Changes Needed)

Your qBittorrent container stays the same - no Traefik labels or network configuration:

```yaml
version: '2.1'
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    network_mode: 'container:gluetun'  # Uses Gluetun's network
    environment:
      - PUID=0
      - PGID=0
      - TZ=Australia/Brisbane
      - WEBUI_PORT=8082
    volumes:
      - /root/qbittorrent:/config
      - /mnt/Toshiba_USB_Drive:/downloads
    # No ports section - ports are defined in Gluetun
    # No networks section - uses Gluetun's network
    # No labels section - labels are on Gluetun
    restart: unless-stopped
```

## Important Notes

1. **Port Mapping**: All ports must be exposed through Gluetun, not the dependent containers

2. **Service Order**: Start Gluetun first, then the dependent services:
   ```bash
   docker-compose up -d gluetun
   sleep 10  # Wait for VPN to connect
   docker-compose up -d qbittorrent
   ```

3. **DNS Access**: Services behind VPN can still be accessed locally via Traefik because:
   - Traefik connects to Gluetun (which is on the proxy network)
   - Gluetun internally routes to qBittorrent on port 8082
   - Your local DNS (AdGuard) resolves the domain to Traefik

4. **Firewall Rules**: The `FIREWALL_OUTBOUND_SUBNETS=192.168.1.0/24` in Gluetun allows local network access while maintaining VPN for internet traffic

## Testing

1. Verify VPN is working:
   ```bash
   docker exec gluetun curl ifconfig.co
   # Should show VPN IP, not your real IP
   ```

2. Access services:
   - https://qbittorrent.homelab.local (through Traefik)
   - http://GLUETUN-IP:8082 (direct access for testing)

## Troubleshooting

- **Service not accessible**: Check Gluetun logs: `docker logs gluetun`
- **VPN not connecting**: Verify VPN credentials and server availability
- **Traefik can't reach service**: Ensure Gluetun is on the proxy network
- **Port conflicts**: Make sure ports aren't used by other services