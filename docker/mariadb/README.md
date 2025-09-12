# MariaDB for Home Assistant

MariaDB database configured for Home Assistant with optimized storage settings.

## Configuration

### docker-compose.yml
Standard LinuxServer.io MariaDB container with persistent storage in `/root/mariadb`.

### custom.cnf
Custom MariaDB configuration with the following optimizations:

#### Storage Optimizations
- **Binary logging disabled** to prevent disk space issues
- InnoDB buffer pool: 256MB
- Query cache: 64MB
- Slow query logging enabled (queries >5 seconds)

#### Key Settings
```ini
# Binary logging disabled to prevent disk space issues
# log_bin = /config/log/mysql/mariadb-bin
# log_bin_index = /config/log/mysql/mariadb-bin.index

# Performance tuning
innodb_buffer_pool_size = 256M
key_buffer_size = 128M
query_cache_size = 64M
```

## Home Assistant Integration

Configure Home Assistant to use MariaDB in `configuration.yaml`:

```yaml
recorder:
  db_url: mysql://homeassistant:PASSWORD@192.168.1.2/homeassistant?charset=utf8mb4
  auto_purge: true
  auto_repack: true
  purge_keep_days: 7  # Adjust based on your needs
```

## Storage Management

### Important Note
Binary logging has been disabled in `custom.cnf` to prevent excessive disk usage. If you need point-in-time recovery or replication, you'll need to re-enable binary logging and configure appropriate log rotation.

### Database Maintenance
For database cleanup and optimization, see `/docker/homeassistant/STORAGE_OPTIMIZATION_GUIDE.md`.

## Default Credentials
- Root Password: `ROOT_ACCESS_PASSWORD` (change in docker-compose.yml)
- Database: `USER_DB_NAME`
- User: `MYSQL_USER`
- Password: `DATABASE_PASSWORD`

**Important**: Update these credentials in docker-compose.yml before deployment!