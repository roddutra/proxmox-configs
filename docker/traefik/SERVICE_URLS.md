# Complete Service URL List

Once Traefik is configured and running, you can access your services at these URLs:

## Core Services
- **Traefik Dashboard**: https://traefik.homelab.local (admin/admin)
- **Main Dashboard (Homarr)**: https://dashboard.homelab.local
- **Proxmox Host**: https://proxmox.homelab.local

## Network & Security
- **AdGuard Home**: https://adguard.homelab.local
- **Uptime Kuma**: https://uptime.homelab.local

## Home Automation
- **Home Assistant**: https://homeassistant.homelab.local *(requires config.yml setup)*
- **Zigbee2MQTT**: https://z2m.homelab.local
- **Eclipse Mosquitto**: https://mosquitto.homelab.local (WebSocket UI on port 9001)

## Media & Downloads
- **Plex Media Server**: https://plex.homelab.local

### VPN-Protected Download Clients
*These services route through Gluetun VPN:*
- **qBittorrent**: https://qbittorrent.homelab.local
- **Deluge**: https://deluge.homelab.local
- **Transmission**: https://transmission.homelab.local *(if using Gluetun version)*

## Monitoring & Databases
- **Grafana**: https://grafana.homelab.local
- **InfluxDB**: https://influxdb.homelab.local
- **Adminer** (Database Admin): https://adminer.homelab.local

## Utilities
- **FileBrowser**: https://filebrowser.homelab.local

## Services NOT Using Traefik
These services either conflict with Traefik or don't have web interfaces:
- **MariaDB**: Database only, no web UI (access via Adminer if needed)
- **PostgreSQL**: Database only, access via Adminer
- **Nginx Proxy Manager**: Conflicts with Traefik (both are reverse proxies)
- **n8n**: Not yet deployed (compose file only has TODO)

## Direct Access Ports (Bypassing Traefik)
If Traefik is down, you can still access services directly:
- AdGuard Home: `http://<LXC-IP>:81`
- Plex: `http://<LXC-IP>:32401`
- Home Assistant: `http://<LXC-IP>:8123`
- Grafana: `http://<LXC-IP>:3000`
- Uptime Kuma: `http://<LXC-IP>:3001`
- Homarr Dashboard: `http://<LXC-IP>:7575`
- qBittorrent: `http://<LXC-IP>:8082`
- Deluge: `http://<LXC-IP>:8112`
- Transmission: `http://<LXC-IP>:9091`

## DNS Configuration Required
Remember to add `*.homelab.local` DNS rewrite in AdGuard pointing to your LXC container IP where Traefik runs.

## Notes
- All HTTPS certificates are handled by Traefik
- HTTP automatically redirects to HTTPS
- Services behind VPN maintain privacy while being locally accessible
- Home Assistant requires special configuration due to host network mode