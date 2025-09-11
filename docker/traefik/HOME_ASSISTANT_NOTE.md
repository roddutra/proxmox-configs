# Home Assistant with Traefik - Special Configuration

## The Challenge

Home Assistant uses `network_mode: host` in its docker-compose.yml, which means:
- It binds directly to the host network interfaces
- It cannot simultaneously join the Docker `proxy` network
- Traefik labels cannot be applied directly to the container

## Solution: Use Traefik's File Provider

Since Home Assistant can't join the proxy network, you need to configure it in Traefik's `config.yml` file instead of using Docker labels.

### Add to `/root/traefik/data/config.yml`:

```yaml
http:
  routers:
    # ... existing proxmox configuration ...
    
    homeassistant:
      entryPoints:
        - 'https'
      rule: 'Host(`homeassistant.homelab.local`)'
      middlewares:
        - default-headers
      tls: {}
      service: homeassistant

  services:
    # ... existing proxmox service ...
    
    homeassistant:
      loadBalancer:
        servers:
          - url: 'http://192.168.1.X:8123'  # Replace X with your LXC container IP
        passHostHeader: true
```

## Why Home Assistant Uses Host Network Mode

Home Assistant requires host network mode for:
1. **Device Discovery**: Auto-discovering smart home devices on your network (mDNS, SSDP, etc.)
2. **Multicast Traffic**: Communication with devices using multicast protocols
3. **Direct Network Access**: Some integrations need raw network access
4. **Performance**: Reduced network latency for real-time device control

## Alternative Approaches (Not Recommended)

### Option 1: Remove Host Network Mode
You could remove `network_mode: host` and add Home Assistant to the proxy network, but you would lose:
- Automatic device discovery
- Many integrations that rely on multicast
- Potentially some Zigbee/Z-Wave functionality

### Option 2: Use a Separate Container
Run a lightweight proxy container on the same host that forwards to Home Assistant, but this adds complexity.

## Recommended Setup

Keep Home Assistant with `network_mode: host` and configure it in Traefik's `config.yml` as shown above. This preserves all Home Assistant functionality while still providing HTTPS access through Traefik.

## Access Methods

After configuration:
- **Via Traefik**: https://homeassistant.homelab.local
- **Direct access**: http://192.168.1.X:8123 (still works)
- **Home Assistant app**: Will work with either URL

## Important Notes

1. The Home Assistant container IP will be the same as your LXC container IP
2. Ensure port 8123 is not blocked by any firewall rules
3. You may need to add Traefik's IP to Home Assistant's `trusted_proxies` configuration
4. In Home Assistant's `configuration.yaml`, you might need:
   ```yaml
   http:
     use_x_forwarded_for: true
     trusted_proxies:
       - 172.20.0.0/16  # Traefik's proxy network subnet
       - 192.168.1.X     # Your LXC container IP
   ```