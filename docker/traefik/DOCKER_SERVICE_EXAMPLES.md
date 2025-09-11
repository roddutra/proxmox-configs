# Docker Service Configuration Examples for Traefik

This file shows how to add Traefik labels to your existing Docker services so they can be accessed via local domain names.

## Prerequisites

1. Ensure the service is on the same Docker network as Traefik:
```yaml
networks:
  - proxy
```

2. At the bottom of your docker-compose.yml, add the external network reference:
```yaml
networks:
  proxy:
    external: true
```

## Service Examples

### AdGuard Home
Add these labels to your AdGuard docker-compose.yml:

```yaml
services:
  adguardhome:
    # ... existing configuration ...
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.adguard.rule=Host(`adguard.homelab.local`)"
      - "traefik.http.routers.adguard.entrypoints=https"
      - "traefik.http.routers.adguard.tls=true"
      - "traefik.http.services.adguard.loadbalancer.server.port=80"
      # Since AdGuard runs on port 81 for the web interface:
      - "traefik.http.services.adguard.loadbalancer.server.port=81"

networks:
  proxy:
    external: true
```

### Home Assistant
```yaml
services:
  homeassistant:
    # ... existing configuration ...
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.homeassistant.rule=Host(`homeassistant.homelab.local`)"
      - "traefik.http.routers.homeassistant.entrypoints=https"
      - "traefik.http.routers.homeassistant.tls=true"
      - "traefik.http.services.homeassistant.loadbalancer.server.port=8123"

networks:
  proxy:
    external: true
```

### Plex
```yaml
services:
  plex:
    # ... existing configuration ...
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.plex.rule=Host(`plex.homelab.local`)"
      - "traefik.http.routers.plex.entrypoints=https"
      - "traefik.http.routers.plex.tls=true"
      - "traefik.http.services.plex.loadbalancer.server.port=32400"

networks:
  proxy:
    external: true
```

### Portainer (if you want to access it through Traefik)
```yaml
services:
  portainer:
    # ... existing configuration ...
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(`portainer.homelab.local`)"
      - "traefik.http.routers.portainer.entrypoints=https"
      - "traefik.http.routers.portainer.tls=true"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"

networks:
  proxy:
    external: true
```

### Grafana
```yaml
services:
  grafana:
    # ... existing configuration ...
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`grafana.homelab.local`)"
      - "traefik.http.routers.grafana.entrypoints=https"
      - "traefik.http.routers.grafana.tls=true"
      - "traefik.http.services.grafana.loadbalancer.server.port=3000"

networks:
  proxy:
    external: true
```

### Homarr (Dashboard)
```yaml
services:
  homarr:
    # ... existing configuration ...
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.homarr.rule=Host(`dashboard.homelab.local`)"
      - "traefik.http.routers.homarr.entrypoints=https"
      - "traefik.http.routers.homarr.tls=true"
      - "traefik.http.services.homarr.loadbalancer.server.port=7575"

networks:
  proxy:
    external: true
```

### Zigbee2MQTT
```yaml
services:
  zigbee2mqtt:
    # ... existing configuration ...
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.zigbee2mqtt.rule=Host(`z2m.homelab.local`)"
      - "traefik.http.routers.zigbee2mqtt.entrypoints=https"
      - "traefik.http.routers.zigbee2mqtt.tls=true"
      - "traefik.http.services.zigbee2mqtt.loadbalancer.server.port=8080"

networks:
  proxy:
    external: true
```

### Services Behind VPN (Deluge/Transmission via Gluetun)
For services that share Gluetun's network, add labels to the Gluetun container:

```yaml
services:
  gluetun:
    # ... existing configuration ...
    networks:
      - proxy
    labels:
      # For Deluge
      - "traefik.enable=true"
      - "traefik.http.routers.deluge.rule=Host(`deluge.homelab.local`)"
      - "traefik.http.routers.deluge.entrypoints=https"
      - "traefik.http.routers.deluge.tls=true"
      - "traefik.http.services.deluge.loadbalancer.server.port=8112"
      
      # For Transmission (if also using Gluetun)
      - "traefik.http.routers.transmission.rule=Host(`transmission.homelab.local`)"
      - "traefik.http.routers.transmission.entrypoints=https"
      - "traefik.http.routers.transmission.tls=true"
      - "traefik.http.services.transmission.loadbalancer.server.port=9091"

networks:
  proxy:
    external: true
```

## Important Notes

1. **Port Numbers**: The `loadbalancer.server.port` should be the INTERNAL container port, not the host port you might have mapped.

2. **Network Mode**: Services using `network_mode: "service:another_service"` (like those sharing Gluetun's network) need labels on the network provider service.

3. **Create the proxy network first**:
   ```bash
   docker network create proxy
   ```

4. **Service Names**: Router and service names in labels must be unique across all containers.

5. **HTTP to HTTPS Redirect**: The main Traefik configuration already handles HTTP→HTTPS redirects globally.

## Quick Label Template

For any new service, use this template and adjust accordingly:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.SERVICE_NAME.rule=Host(`SERVICE_NAME.homelab.local`)"
  - "traefik.http.routers.SERVICE_NAME.entrypoints=https"
  - "traefik.http.routers.SERVICE_NAME.tls=true"
  - "traefik.http.services.SERVICE_NAME.loadbalancer.server.port=INTERNAL_PORT"
```

Replace:
- `SERVICE_NAME` with your service name (must be unique)
- `INTERNAL_PORT` with the port the service listens on inside the container