# Home Assistant Storage Optimization Guide

## Overview
This guide will help you reduce your Home Assistant database storage from 26GB (MariaDB) + 2.3GB (InfluxDB) to approximately 3-5GB total while preserving all important energy data for multiple years.

## Current Configuration Changes
The `configuration.yaml` has been updated with:
- **Default retention**: 7 days for most entities
- **Energy data retention**: Preserved in both databases
- **Excluded entities**: Non-essential frequently updating sensors
- **Included entities**: All energy, solar, battery, and power-related sensors

### Preserved Entities
All your SolarEdge entities are preserved:
- `sensor.solaredge_consumed_energy`
- `sensor.solaredge_current_power`
- `sensor.solaredge_energy_today`
- `sensor.solaredge_exported_energy`
- `sensor.solaredge_grid_power`
- `sensor.solaredge_imported_energy`
- `sensor.solaredge_lifetime_energy`
- `sensor.solaredge_power_consumption`
- `sensor.solaredge_produced_energy`
- `sensor.solaredge_self_consumed_energy`
- `sensor.solaredge_solar_power`

### Future-Ready for SigEnergy
The configuration includes patterns for:
- Battery state of charge (SOC)
- Charge/discharge rates
- Inverter statistics
- Any entity containing "sigenergy" in its name

---

## Migration Steps

### Phase 1: Pre-Migration Backup (CRITICAL)

#### 1.1 Create Full Database Backups
```bash
# SSH into your Docker LXC container
ssh root@192.168.1.2

# Create backup directory
mkdir -p /root/backups/$(date +%Y%m%d)
cd /root/backups/$(date +%Y%m%d)

# Backup MariaDB (replace ROOT_ACCESS_PASSWORD with your actual password)
docker exec mariadb mysqldump -u root -p'ROOT_ACCESS_PASSWORD' homeassistant > homeassistant_backup.sql
# Or more securely, use -p without password and enter when prompted:
# docker exec -it mariadb mysqldump -u root -p homeassistant > homeassistant_backup.sql

# Compress the backup
gzip homeassistant_backup.sql

# Backup InfluxDB
docker exec influxdb influx backup /backup -t ADMIN_TOKEN
docker cp influxdb:/backup ./influxdb_backup
tar -czf influxdb_backup.tar.gz influxdb_backup/

# Verify backups
ls -lh
```

#### 1.2 Export Energy Data (Optional but Recommended)
```sql
# Connect to MariaDB (replace ROOT_ACCESS_PASSWORD with your actual password)
docker exec -it mariadb mysql -u root -p'ROOT_ACCESS_PASSWORD' homeassistant
# Or more securely, omit password to be prompted:
# docker exec -it mariadb mysql -u root -p homeassistant

# Export energy data to CSV (run from mysql prompt)
SELECT entity_id, state, last_updated 
INTO OUTFILE '/tmp/energy_data.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM states 
WHERE entity_id LIKE '%energy%' 
   OR entity_id LIKE '%solar%' 
   OR entity_id LIKE '%power%'
   OR entity_id LIKE '%consumption%';
```

---

### Phase 2: Apply Configuration Changes

#### 2.1 Restart Home Assistant
```bash
# Option 1: Check configuration via Home Assistant UI (RECOMMENDED)
# Go to Developer Tools → YAML → Check Configuration
# If it shows "Configuration will not prevent Home Assistant from starting!" you're good

# Option 2: Check configuration via command line (if needed)
docker exec homeassistant python -m homeassistant --config /config --script check_config

# Once configuration is valid, restart Home Assistant
docker restart homeassistant

# Monitor logs for any errors
docker logs -f homeassistant

# Press Ctrl+C to stop following logs once you see it's running properly
```

#### 2.2 Verify New Configuration
1. Go to Settings → System → Logs in Home Assistant
2. Check for any recorder or InfluxDB errors
3. Verify entities are being recorded properly

---

### Phase 3: Database Cleanup

#### 3.1 Clean MariaDB (After Configuration is Working)

**WARNING**: Only proceed after verifying backups and new configuration!

```sql
# Connect to MariaDB (replace ROOT_ACCESS_PASSWORD with your actual password)
docker exec -it mariadb mysql -u root -p'ROOT_ACCESS_PASSWORD' homeassistant
# Or more securely, omit password to be prompted:
# docker exec -it mariadb mysql -u root -p homeassistant

# Check current database size
SELECT 
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS 'Size (GB)'
FROM information_schema.tables
WHERE table_schema = 'homeassistant'
GROUP BY table_schema;

# First, check the table structure to verify column names
DESCRIBE states;

# Delete old non-energy data (keeping 7 days as per new config)
# Note: Home Assistant uses 'last_updated_ts' timestamp column
DELETE FROM states 
WHERE last_updated_ts < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 7 DAY))
  AND entity_id NOT LIKE '%energy%'
  AND entity_id NOT LIKE '%power%'
  AND entity_id NOT LIKE '%solar%'
  AND entity_id NOT LIKE '%consumption%'
  AND entity_id NOT LIKE '%grid%'
  AND entity_id NOT LIKE '%battery%'
  AND entity_id NOT LIKE '%kwh%'
  AND entity_id NOT LIKE '%voltage%'
  AND entity_id NOT LIKE '%current%'
  AND entity_id NOT LIKE '%import%'
  AND entity_id NOT LIKE '%export%'
  AND entity_id NOT LIKE '%production%'
  AND entity_id NOT LIKE '%cost%'
  AND entity_id NOT LIKE '%tariff%'
  AND entity_id NOT LIKE '%price%'
  AND entity_id NOT REGEXP 'climate\.|water_heater\.';

# Clean up events table
# Note: Events table uses 'time_fired_ts' timestamp column
DELETE FROM events 
WHERE time_fired_ts < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 7 DAY));

# CRITICAL: Clean up orphaned attributes (this is where most space is used!)
# This removes attributes no longer referenced by any state
DELETE sa FROM state_attributes sa
LEFT JOIN states s ON sa.attributes_id = s.attributes_id
WHERE s.state_id IS NULL;

# Clean up orphaned event data
DELETE ed FROM event_data ed
LEFT JOIN events e ON ed.data_id = e.data_id
WHERE e.event_id IS NULL;

# Clean up orphaned states metadata
DELETE sm FROM states_meta sm
LEFT JOIN states s ON sm.metadata_id = s.metadata_id
WHERE s.state_id IS NULL;

# Optimize tables to reclaim space (do this AFTER the cleanup above)
OPTIMIZE TABLE states;
OPTIMIZE TABLE state_attributes;
OPTIMIZE TABLE events;
OPTIMIZE TABLE event_data;
OPTIMIZE TABLE states_meta;
OPTIMIZE TABLE statistics;
OPTIMIZE TABLE statistics_short_term;

# Check new size
SELECT 
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS 'Size (GB)'
FROM information_schema.tables
WHERE table_schema = 'homeassistant'
GROUP BY table_schema;

# Exit MySQL
exit
```

#### 3.2 Configure InfluxDB Retention Policy

```bash
# Access InfluxDB CLI
docker exec -it influxdb influx -t ADMIN_TOKEN

# Create retention policies (InfluxQL)
# For energy data - 5 years retention
CREATE RETENTION POLICY "energy_5years" ON "homeassistant" DURATION 1825d REPLICATION 1

# For other data - 30 days retention
CREATE RETENTION POLICY "short_term" ON "homeassistant" DURATION 30d REPLICATION 1

# Set default retention policy
ALTER RETENTION POLICY "autogen" ON "homeassistant" DURATION 30d REPLICATION 1 DEFAULT

# Exit InfluxDB CLI
exit
```

---

### Phase 4: Post-Migration Monitoring

#### 4.1 Add Database Size Sensors
Add these to your `configuration.yaml`:

```yaml
sensor:
  - platform: sql
    db_url: mysql://homeassistant:6R!unpTy7QzudaTQkQhE@192.168.1.2/homeassistant?charset=utf8mb4
    queries:
      - name: MariaDB Database Size
        query: "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'size' FROM information_schema.tables WHERE table_schema='homeassistant';"
        column: "size"
        unit_of_measurement: MB
        scan_interval: 3600  # Check every hour

  - platform: command_line
    name: InfluxDB Database Size
    command: "docker exec influxdb du -sm /var/lib/influxdb2 | cut -f1"
    unit_of_measurement: MB
    scan_interval: 3600
```

#### 4.2 Create Maintenance Automation
Add to `automations.yaml`:

```yaml
- alias: "Database Maintenance Weekly"
  trigger:
    - platform: time
      at: "03:00:00"
    - platform: time
      at: "Sunday"
  action:
    - service: recorder.purge
      data:
        keep_days: 7
        repack: true
    - service: notify.persistent_notification
      data:
        title: "Database Maintenance"
        message: "Weekly database purge completed"
```

---

### Phase 5: Verification Checklist

- [ ] Backups created and verified
- [ ] Configuration.yaml updated
- [ ] Home Assistant restarted without errors
- [ ] Energy entities still being recorded
- [ ] MariaDB cleaned and optimized
- [ ] InfluxDB retention policies configured
- [ ] Database size sensors added
- [ ] Maintenance automation created
- [ ] Monitor database size for 24-48 hours

---

## Troubleshooting

### Issue: Energy data not being recorded
**Solution**: Check that your energy entities match the patterns in the include list. Add specific entity IDs if needed.

### Issue: Database still large after cleanup
**Solution**: 
1. Check for large `statistics` tables - these are meant for long-term storage
2. Run `SHOW TABLE STATUS FROM homeassistant;` to identify large tables
3. Consider purging `recorder_runs` and `schema_changes` tables if very old

### Issue: InfluxDB still growing
**Solution**: Verify retention policies are applied:
```bash
docker exec -it influxdb influx -t ADMIN_TOKEN
SHOW RETENTION POLICIES ON homeassistant
```

### Issue: Some entities missing from history
**Solution**: Add them explicitly to the `include` section of recorder configuration

---

## Expected Results

After completing this migration:
- **MariaDB**: Should reduce from 26GB to approximately 3-5GB
- **InfluxDB**: Should stabilize at 500MB-1GB for energy data
- **Performance**: Faster Home Assistant UI and history queries
- **Energy Data**: All preserved for multiple years
- **Non-essential Data**: Only 7 days retained

---

## Regular Maintenance

### Weekly
- Automatic purge via automation (already configured)

### Monthly
- Check database size sensors
- Review excluded entities list
- Verify energy data is being captured

### Quarterly
- Review and adjust retention policies
- Check for new energy entities (especially after adding SigEnergy)
- Optimize tables if needed

---

## Phase 6: Complete Cleanup After Successful Migration

### 6.1 Verify Everything is Working
Before removing ALL backups, ensure:
- [ ] Home Assistant has been running stable for at least 48 hours
- [ ] All energy entities are being recorded properly
- [ ] Database size has reduced as expected
- [ ] You can view historical energy data
- [ ] No errors in Home Assistant logs
- [ ] You have tested a full Home Assistant backup/restore through the UI

### 6.2 Complete Removal of Migration Backups
**IMPORTANT**: Only proceed once you're absolutely confident the migration was successful!

```bash
# SSH into your Docker LXC container
ssh root@192.168.1.2

# Check current size of backups
du -sh /root/backups
du -sh /root/permanent_backups 2>/dev/null
du -sh /root/*.sql* 2>/dev/null
du -sh /root/*.tar.gz 2>/dev/null

# Total space used by root directory before cleanup
du -sh /root/

# COMPLETE REMOVAL - Remove ALL migration backup files
rm -rf /root/backups/
rm -rf /root/permanent_backups/
rm -f /root/*.sql
rm -f /root/*.sql.gz
rm -f /root/*.tar.gz
rm -f /root/influxdb_backup*
rm -f /root/homeassistant_backup*

# Clean up any migration reports
rm -f /root/migration_report_*.txt

# Verify backups are gone
ls -la /root/ | grep -E "(backup|\.sql|\.tar\.gz)"

# Check space freed up
du -sh /root/
```

### 6.3 Clean Up Docker Container Space
```bash
# Remove any temporary export files from MariaDB container
docker exec mariadb rm -f /tmp/energy_data.csv

# Clean up InfluxDB backup directory inside container
docker exec influxdb rm -rf /backup

# Prune unused Docker volumes (be careful with this)
docker volume prune -f

# Check Docker space usage
docker system df

# Optional: Clean Docker build cache if needed
docker builder prune -f
```

### 6.4 Optimize System Storage for LXC Migration
```bash
# Check storage usage before optimization
df -h
du -h --max-depth=1 /root/ | sort -hr

# Clear apt cache completely
apt-get clean
apt-get autoremove -y
apt-get autoclean

# Aggressive journal cleanup (keep only 1 day)
journalctl --vacuum-time=1d
journalctl --vacuum-size=50M

# Clear all package manager caches
rm -rf /var/cache/apt/archives/*
rm -rf /var/cache/apt/*.bin
rm -rf /var/lib/apt/lists/*

# Clear temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clear bash history and cache
rm -f /root/.bash_history
rm -rf /root/.cache/*

# Clear any core dumps
rm -f /var/crash/*

# Final storage check - should show significant reduction
echo "=== Final Storage Status ==="
df -h
echo ""
echo "=== Root directory size ==="
du -sh /root/
echo ""
echo "=== LXC ready for migration ==="
```

### 6.5 Schedule Regular Cleanup
Add this automation to Home Assistant to prevent future buildup:

```yaml
# Add to automations.yaml
- alias: "Monthly Backup Cleanup"
  trigger:
    - platform: time
      at: "04:00:00"
    - platform: template
      value_template: "{{ now().day == 1 }}"  # First day of month
  action:
    - service: shell_command.cleanup_old_backups
```

And create the shell command in `configuration.yaml`:

```yaml
shell_command:
  cleanup_old_backups: 'find /root/backups/ -type f -mtime +30 -delete'
```

### 6.6 Pre-LXC Migration Summary
Expected storage reduction for LXC migration:

```bash
# Get final size summary before LXC migration
echo "=== Storage Reduction Summary ==="
echo "Before optimization:"
echo "- MariaDB: 26GB"
echo "- InfluxDB: 2.3GB" 
echo "- Total databases: ~28.3GB"
echo ""
echo "After optimization and cleanup:"
echo "- MariaDB: $(docker exec mariadb du -sh /config 2>/dev/null | cut -f1 || echo 'N/A')"
echo "- InfluxDB: $(docker exec influxdb du -sh /var/lib/influxdb2 2>/dev/null | cut -f1 || echo 'N/A')"
echo "- Root directory: $(du -sh /root/ | cut -f1)"
echo "- Total LXC size: $(df -h / | awk 'NR==2 {print $3}')"
echo ""
echo "Space freed: ~25GB+"
echo "LXC is now ready for migration!"
```

### 6.7 LXC Migration Command
Once all cleanup is complete, migrate your LXC container:

```bash
# From Proxmox host (not inside LXC)
# Stop the container
pct stop <CONTAINER_ID>

# Create backup for migration (much smaller now!)
vzdump <CONTAINER_ID> --compress gzip --storage <STORAGE_NAME>

# Or migrate directly to another node
pct migrate <CONTAINER_ID> <TARGET_NODE> --online
```

---

## Notes for SigEnergy Integration

When you add your SigEnergy battery system:
1. The configuration already includes patterns for battery entities
2. Any entity with "sigenergy" in the name will be automatically included
3. Battery SOC, charge/discharge rates will be captured
4. You may want to create custom sensors for specific metrics

No configuration changes needed - the patterns will automatically capture the new entities!