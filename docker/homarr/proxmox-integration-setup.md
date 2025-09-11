# Homarr Proxmox Integration Setup

## Get Proxmox Certificate

1. Access Proxmox web UI at `https://192.168.1.x:8006`
2. Navigate to **Datacenter → Your Node → System → Certificates**
3. View the PVE Certificate details
4. Copy the raw certificate content (PEM format)
5. Save to a local `.crt` file (e.g., `proxmox.crt`)

## Upload to Homarr

1. In Homarr, go to **Management → Tools → Certificates**
2. Click "Add Certificate"
3. Upload the `.crt` file
4. Name it (e.g., "Proxmox")

## Configure Proxmox Widget

1. Add Proxmox widget to dashboard
2. Use configuration:
   - URL: `https://192.168.1.x:8006`
   - Username: 
   - API Token/Key: 
   - Realm: `pve`
