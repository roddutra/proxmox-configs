# Jellyfin with Intel Quick Sync Hardware Transcoding

This configuration enables hardware-accelerated transcoding using Intel Quick Sync Video (QSV) from your Intel i5 processor.

## Prerequisites

### 1. Proxmox Host Configuration

Ensure Intel GPU is available and drivers are loaded:
```bash
# On Proxmox host, verify Intel GPU is detected
lspci | grep -i vga
# Should show something like: Intel Corporation UHD Graphics

# Check if i915 driver is loaded
lsmod | grep i915

# If not loaded, enable it:
modprobe i915
echo "i915" >> /etc/modules
```

### 2. LXC Container Configuration

Edit your LXC container configuration file on the Proxmox host:
```bash
# On Proxmox host (replace CONTAINER_ID with your actual container ID)
nano /etc/pve/lxc/CONTAINER_ID.conf
```

Add these lines to pass through the Intel GPU:
```conf
# Intel GPU passthrough for hardware transcoding
lxc.cgroup2.devices.allow: c 226:* rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file

# Additional permissions (if using privileged container)
lxc.cgroup2.devices.allow: c 29:0 rwm
lxc.mount.entry: /dev/fb0 dev/fb0 none bind,optional,create=file
```

**Note:** If you're using an unprivileged container, you'll also need to add:
```conf
# UID/GID mapping for render and video groups
lxc.idmap: u 0 100000 65536
lxc.idmap: g 0 100000 44
lxc.idmap: g 44 44 1
lxc.idmap: g 45 100045 59
lxc.idmap: g 104 104 1
lxc.idmap: g 105 100105 65431
```

### 3. Inside the LXC Container

After starting/restarting the container, verify device access:
```bash
# Check if /dev/dri exists
ls -la /dev/dri/
# Should show: card0, renderD128

# Install Intel GPU tools for testing (optional)
apt-get update
apt-get install -y intel-gpu-tools vainfo

# Test Intel GPU access
vainfo
# Should show Intel iGPU capabilities

# Check render and video group IDs
getent group render
getent group video
# Note these IDs - update docker-compose.yml if different from 104 and 44
```

## Docker Deployment

1. **Deploy the container:**
```bash
cd /docker/jellyfin
docker-compose up -d
```

2. **Verify hardware acceleration in container:**
```bash
# Check if device is accessible inside container
docker exec jellyfin ls -la /dev/dri

# Check transcoding capabilities
docker exec jellyfin vainfo
```

## Jellyfin Configuration

1. **Access Jellyfin Web UI:**
   - Navigate to: `http://192.168.1.2:8096` or `https://jellyfin.homelab.local` (if using Traefik)

2. **Enable Hardware Acceleration:**
   - Go to Dashboard → Playback
   - Hardware acceleration: `Intel QuickSync (QSV)`
   - Enable hardware decoding for supported codecs:
     - H.264
     - HEVC (H.265)
     - VP8
     - VP9 (if supported by your Intel GPU)
     - AV1 (12th gen Intel and newer)

3. **Transcoding Settings:**
   - Hardware encoding: Enabled
   - Allow encoding in HEVC: Enable if your Intel GPU supports it
   - Prefer OS native DXVA or VA-API hardware decoders: Enabled
   - Enable Intel Low-Power H.264/HEVC hardware encoder: Enabled (for newer Intel CPUs)

## Troubleshooting

### Permission Issues
If transcoding fails with permission errors:
```bash
# In the container, check group membership
docker exec jellyfin id jellyfin

# Manually add jellyfin user to groups if needed
docker exec jellyfin usermod -aG video,render jellyfin

# Restart container
docker-compose restart
```

### Verify Hardware Transcoding is Working
1. Play a video that requires transcoding
2. Check Dashboard → Active Devices during playback
3. Look for "(hw)" indicator next to video codec
4. Monitor CPU usage - should be significantly lower with hardware transcoding

### Check Logs
```bash
# Container logs
docker logs jellyfin -f

# Transcode logs in Jellyfin
# Located at: /config/log/
docker exec jellyfin tail -f /config/log/FFmpeg.Transcode*.log
```

## Performance Tips

1. **Tone Mapping**: Enable hardware tone mapping for HDR to SDR conversion (10th gen Intel and newer)
2. **Throttle Transcodes**: Limit simultaneous hardware transcodes based on your CPU's capabilities
3. **Pre-transcoding**: Consider using Jellyfin's scheduled task to pre-transcode commonly watched content

## Intel GPU Generation Support

- **6th-9th Gen (Skylake-Coffee Lake)**: H.264, HEVC (decode only on some)
- **10th-11th Gen (Ice Lake/Tiger Lake)**: H.264, HEVC, VP9
- **12th Gen+ (Alder Lake+)**: H.264, HEVC, VP9, AV1

Check your specific Intel processor model for exact codec support at [Intel Quick Sync Video](https://en.wikipedia.org/wiki/Intel_Quick_Sync_Video).