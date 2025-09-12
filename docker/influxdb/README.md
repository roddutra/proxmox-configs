# InfluxDB 2.x

Time-series database configured for Home Assistant long-term data storage.

## Configuration

### docker-compose.yml
- InfluxDB 2.x with web UI on port 8086
- Initial retention: 52 weeks (1 year) via `DOCKER_INFLUXDB_INIT_RETENTION`
- Traefik integration for HTTPS access at `influxdb.homelab.local`

### Environment Variables
Update these in docker-compose.yml before first run:
- `DOCKER_INFLUXDB_INIT_USERNAME`: Admin username
- `DOCKER_INFLUXDB_INIT_PASSWORD`: Admin password
- `DOCKER_INFLUXDB_INIT_ORG`: Organization name
- `DOCKER_INFLUXDB_INIT_BUCKET`: Initial bucket name
- `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN`: Admin API token
- `DOCKER_INFLUXDB_INIT_RETENTION`: Data retention period (default: 52w)

## Home Assistant Integration

Configure in Home Assistant's `configuration.yaml`:

```yaml
influxdb:
  api_version: 2
  host: 192.168.1.2
  port: 8086
  organization: YOUR_ORG_ID
  bucket: homeassistant
  token: !secret influxdb_admin_token
  include:
    entity_globs:
      - sensor.*energy*
      - sensor.*power*
      - sensor.*solar*
      # Add patterns for data you want to keep long-term
```

## Storage Management

### Retention Policies
- Initial retention set to 52 weeks via docker-compose
- Can be adjusted via InfluxDB UI or CLI after deployment
- Different retention policies can be created for different data types

### Storage Optimization
- Only send essential data from Home Assistant (energy, solar, etc.)
- Use include filters rather than sending all data
- Regular compaction happens automatically

## Access

- Web UI: `https://influxdb.homelab.local` (via Traefik)
- Direct access: `http://192.168.1.2:8086`

## Resources

- [InfluxDB 2.x Documentation](https://docs.influxdata.com/influxdb/v2/)
- [Home Assistant InfluxDB Integration](https://www.home-assistant.io/integrations/influxdb/)