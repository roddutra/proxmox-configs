# Home Assistant Container Installation

This install is for the **Home Assistant Container** installation method. You can compare them in [this link](https://www.home-assistant.io/installation#compare-installation-methods) from Home Assistant's docs.

## Why Container Installation?

I have chosen to use the Container installation method for the following reasons:

- Using a container, HA can share the resources already made available to my Ubuntu LXC container from the Proxmox host rather than spinning up a whole new VM which will have it's own overhead (eg. RAM, processor cores)
- I can keep HA separate from other services like MQTT so, for example, when I need to restart HA my Zigbee network doesn't go down
- And, most importantly, I am not locked in to the Add-ons that HA or the HA Community have built which are all typically available as individual services themselves that I can run independently in Docker alongside HA

## ⚠️ SECURITY WARNING

**NEVER commit the following files to version control:**
- `secrets.yaml` - Contains passwords and API tokens
- `configuration.yaml` - May contain sensitive information

The `.gitignore` file is configured to prevent accidental commits of sensitive files.

## Setup Instructions

### 1. Initial Setup

1. Copy the template files:
   ```bash
   cp configuration-template.yaml configuration.yaml
   cp secrets-example.yaml secrets.yaml
   cp automations-template.yaml automations.yaml
   ```

2. Edit `secrets.yaml` with your actual values:
   - MariaDB password and connection details
   - InfluxDB host, organization ID, and token
   - Any other sensitive configuration

3. Update `configuration.yaml`:
   - Adjust IP addresses if needed
   - Configure trusted proxies for your network
   - Add any additional integrations

4. Update `automations.yaml`:
   - Replace device IDs with your actual device IDs
   - Update entity IDs for your specific devices
   - Customize automation logic as needed

### 2. Database Configuration

#### MariaDB Setup
The configuration uses MariaDB for the recorder. Ensure MariaDB is running and accessible:
- Default connection: `mysql://homeassistant:PASSWORD@192.168.1.2/homeassistant`
- Database must exist and user must have full permissions
- Uses UTF8MB4 charset for full emoji support

#### InfluxDB Setup
InfluxDB is used for long-term statistics:
- Requires InfluxDB 2.x
- Organization ID and admin token required
- Default bucket: `homeassistant`

### 3. Traefik Integration

The configuration includes HTTP settings for Traefik reverse proxy:
```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.20.0.0/16  # Docker proxy network
    - 192.168.1.0/24  # Local network
```

Access Home Assistant through: `https://homeassistant.homelab.local`

### 4. Finding Device and Entity IDs

To find IDs for your automations:

1. **Device IDs**:
   - Go to Settings → Devices & Services
   - Click on your device
   - Device ID is in the URL: `/config/devices/device/YOUR_DEVICE_ID_HERE`

2. **Entity IDs**:
   - Go to Developer Tools → States
   - Find your entity in the list
   - Copy the entity ID (e.g., `sensor.temperature_bedroom`)

3. **Discovery IDs** (for MQTT devices):
   - Go to Settings → Devices & Services → MQTT
   - Click on your device
   - Discovery ID is shown in device info

### 5. Docker Deployment

This configuration is designed to work with the docker-compose.yml in this directory:
- Uses host network mode for device discovery
- Mounts configuration at `/config`
- Timezone set to Australia/Brisbane (adjust as needed)

## File Structure

```
homeassistant/
├── configuration-template.yaml  # Template configuration (safe to commit)
├── configuration.yaml           # Actual configuration (DO NOT COMMIT)
├── secrets-example.yaml         # Template for secrets (safe to commit)
├── secrets.yaml                 # Actual secrets (DO NOT COMMIT)
├── automations-template.yaml    # Template automations (safe to commit)
├── automations.yaml            # Your automations
├── groups.yaml                 # Group definitions
├── scenes.yaml                 # Scene definitions
├── scripts.yaml                # Script definitions
├── docker-compose.yml          # Docker deployment
├── .gitignore                  # Prevents committing sensitive files
└── README.md                   # This file
```

## Security Best Practices

1. **Use secrets.yaml**: Never hardcode passwords in configuration.yaml
2. **Strong Passwords**: Use strong, unique passwords for databases
3. **Network Security**: Limit database access to local network only
4. **Regular Updates**: Keep Home Assistant and integrations updated
5. **Backup Secrets**: Keep encrypted backup of secrets.yaml separately

## Troubleshooting

### Cannot Connect to MariaDB
- Check MariaDB is running: `docker ps | grep mariadb`
- Verify credentials in secrets.yaml
- Ensure database and user exist
- Check network connectivity

### InfluxDB Not Recording
- Verify InfluxDB 2.x is running
- Check organization ID and token
- Ensure bucket exists
- Review Home Assistant logs

### Devices Not Found
- Update device IDs in automations.yaml
- Check MQTT integration is configured
- Verify Zigbee2MQTT is running
- Review device discovery settings

## Install

Use the [docker compose file](docker-compose.yml) to setup your stack for HA.

## Displaying other Docker Services in HA

As we are not using the built-in add-ons from Home Assistant, we can still show the web UIs from our different services using the `panel_iframe` feature from Home Assistant.

Open the `configuration.yml` in the HA folder and add:

```yml
panel_iframe:
  portainer:
    title: 'Portainer'
    url: 'https://192.168.1.2:9443/#!/2/docker/containers'
    icon: mdi:docker
    require_admin: true
  zigbee2mqtt:
    title: 'zigbee2mqtt'
    url: 'http://192.168.1.2:8080/#/'
    icon: mdi:zigbee
    require_admin: true
```

Restart Home Assistant via the Developer Tools tab for the changes to take effect.

The example above adds 2 menu items, one for Portainer (displayed with a Docker icon) and one for Zigbee2MQTT (using the Ziggee icon).

## Resources

- [Installing Docker and Home Assistant Container](https://www.youtube.com/watch?v=S-itdbqwj4I)
- [Living without add-ons on Home Assistant Container](https://www.youtube.com/watch?v=DV_OD4OPKno)
- [Automatically Updating Home Assistant Container (and other Docker Containers)](https://www.youtube.com/watch?v=Wx1TsuTgv_Q)
