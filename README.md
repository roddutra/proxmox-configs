# Proxmox Configs

This repository holds all my configs for my local Proxmox server, including install instructions, Docker/Portainer stack templates, etc.

## Homelab Overview

This homelab runs on **Proxmox VE** with a streamlined architecture designed for efficiency and centralized management:

- **Single Proxmox host** running an **Ubuntu 24.04 LXC container** (ID: 103)
- **20+ Docker services** managed through **Portainer CE**
- **Privileged LXC** configuration for full Docker compatibility
- **100GB root storage** + **900GB external USB** for media
- **USB passthrough** for Zigbee controller (Conbee II)
- Services include: Plex, Home Assistant, Traefik, AdGuard Home, various databases, monitoring tools, and automation platforms

For detailed architecture documentation, see [HOMELAB-OVERVIEW.md](./HOMELAB-OVERVIEW.md).

## SSH Access Configuration

### Setting Up SSH Keys

SSH key authentication provides secure, password-less access to your Proxmox host and LXC containers.

#### Option 1: Using 1Password (Recommended)

1Password provides seamless SSH key management with biometric/touch approval:

1. **Generate SSH key in 1Password:**
   - Open 1Password → New Item → SSH Key
   - Give it a descriptive name (e.g., "Proxmox Host Key")
   - 1Password generates a secure key automatically

2. **Export public key from 1Password:**
   - Click on the SSH key item → Copy public key
   - Save for adding to servers

**Note:** The 1Password CLI automatically configures the SSH agent when installed, providing touch/biometric approval for key usage.

#### Option 2: Generate SSH Key Manually

**On macOS:**
```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Or RSA key (if ED25519 not supported)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# View your public key
cat ~/.ssh/id_ed25519.pub
```

**On Linux:**
```bash
# Generate ED25519 key
ssh-keygen -t ed25519 -C "your_email@example.com"

# View public key
cat ~/.ssh/id_ed25519.pub
```

### Adding SSH Keys to Proxmox Host

1. **Access Proxmox host** (use existing password authentication initially):
   ```bash
   ssh root@192.168.1.100  # Replace with your Proxmox IP
   ```

2. **Add your public key:**
   ```bash
   # Create .ssh directory if it doesn't exist
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh

   # Add your public key (replace with your actual key)
   echo "ssh-ed25519 AAAAC3NzaC1... your_email@example.com" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

3. **Test SSH key access** (from your local machine):
   ```bash
   ssh root@192.168.1.100
   # Should connect without password prompt
   # 1Password users will see touch/biometric approval request
   ```

### Adding SSH Keys to LXC Containers

**Method 1: From Proxmox Host**
```bash
# Access container from Proxmox host
pct enter 103  # Replace 103 with your container ID

# Inside container, add SSH key
mkdir -p /root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1... your_email@example.com" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh

# Exit container
exit
```

**Method 2: Direct SSH (if container has SSH enabled)**
```bash
# SSH to container (use password first time)
ssh root@192.168.1.3  # Replace with container IP

# Add key as shown above
mkdir -p ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1..." >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Securing SSH Access

After setting up key authentication:

1. **Disable password authentication** (optional but recommended):
   ```bash
   # Edit SSH config
   nano /etc/ssh/sshd_config

   # Set these options:
   PasswordAuthentication no
   PubkeyAuthentication yes

   # Restart SSH
   systemctl restart sshd
   ```

2. **Configure SSH client** for easy access:
   ```bash
   # Add to ~/.ssh/config on your local machine
   Host proxmox
       HostName 192.168.1.100
       User root
       Port 22

   Host docker-lxc
       HostName 192.168.1.3
       User root
       Port 22
   ```

   Then connect simply with:
   ```bash
   ssh proxmox
   ssh docker-lxc
   ```

## Proxmox VE Helper-Scripts

The [Proxmox VE Helper-Scripts](https://community-scripts.github.io/ProxmoxVE/) project provides **300+ community-maintained scripts** to automate and simplify Proxmox VE management.

### Key Features:
- **One-line LXC deployments** for popular services (Home Assistant, Docker, Plex, etc.)
- **Automated setup** with optimized configurations
- **Post-installation scripts** for updates and maintenance
- **System utilities** including:
  - Dark theme for Proxmox UI
  - Enabling updates without subscription
  - CPU scaling governor optimization
  - Kernel cleanup tools
  - Hardware passthrough helpers

### Quick Usage Example:
```bash
# Deploy a Docker LXC container
bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/docker.sh)"

# Install Home Assistant OS VM
bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/vm/haos-vm.sh)"
```

### Categories:
- **LXC Containers**: Pre-configured templates for 100+ applications
- **Virtual Machines**: Automated VM creation for various OS and applications
- **Proxmox Tools**: System optimization and management utilities
- **Miscellaneous**: Backup solutions, monitoring tools, and more

Visit [https://community-scripts.github.io/ProxmoxVE/](https://community-scripts.github.io/ProxmoxVE/) for the full script collection and documentation.
