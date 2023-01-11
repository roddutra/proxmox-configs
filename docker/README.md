# Docker Setup Instructions

## Create LXC Container in Proxmox

1. Go to the `local (proxmox)` storage drive, then open the **CT Templates** tab.
2. Click the **Templates** button and download the latest image for Ubuntu.
3. On the top-right click the **Create CT** button, give your container an ID and a custom Hostname (eg. `Docker-LXC`) and setup a password.

> ⚠️ IMPORTANT: when creating the container make sure it is setup as **Priviledged** by unticking the `Unpriviledged container` checkbox on the first step. This is not necessary for all applications and there might be a workaround ⁉️, but to create a container that connects to a VPN this was the only way that I got it to work and create the tunnel.
>
> Once created, go back to **Options > Features** and enable `Nesting` as well as `Create Device Nodes`.

4. Give it a Static IP in the IPv4 section (eg. `192.168.1.2/24` and Gateway `192.168.1.1`) and leave IPv6 blank.
5. On the **Template** step, pick the Ubuntu image downloaded earlier, then give the container the desired disk space, number of CPUs and RAM (eg. `4096`) and leave all other configs as they are.

## Install Docker

Follow the Docker install instructions here: [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

### Uninstall AppArmor

AppArmor prevents the Portainer image from running in the LXC container so it needs to be uninstalled.

```bash
apt remove apparmor --purge -y
rm -rf /etc/apparmor*
```

## Install Portainer

Follow the instructions in the [Portainer Setup](Portainer-Setup.md) file.
