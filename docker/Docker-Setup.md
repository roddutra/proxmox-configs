# Docker Setup Instructions

## Create LXC Container in Proxmox

1. Go to the `local (proxmox)` storage drive, then open the **CT Templates** tab.
2. Click the **Templates** button and download the latest image for Ubuntu.
3. On the top-right click the **Create CT** button, give your container an ID and a custom Hostname (eg. `Docker-LXC`) and setup a password.

> ⚠️ IMPORTANT: when creating the container make sure it is setup as **Priviledged** by unticking the `Unpriviledged container` checkbox on the first step.
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

Follow the Portainer install instructions here: [Install Portainer with Docker on Linux](https://docs.portainer.io/start/install/server/docker/linux).

### Free up necessary ports for AdGuardHome, etc

Certain containers (aka. AdGuardHome) need access to ports that are used by systemd-resolved which needs to be disabled.

Open up an SSH console and run:

```bash
nano /etc/systemd/resolved.conf
```

and change the values to the ones below

```bash
DNS=1.1.1.1
DNSStubListener=no
```

then run:

```bash
systemctl disable systemd-resolved.service
```

and finally:

```bash
reboot now
```

You can now create the AdGuardHome stack and others.

# Troubleshooting

## VPN issue: /dev/net/tun

Following the instructions from [OpenVPN in LXC](https://pve.proxmox.com/wiki/OpenVPN_in_LXC) from the Proxmox wiki, run the following commands on the host machine in Proxmox (eg. `Docker-LXC`) to create the tunnel:

```bash
# Replace '{NODE_ID}' with the ID of the node in Proxmox (eg. 100.conf)
nano /etc/pve/lxc/{NODE_ID}.conf
```

Add the following lines at the end:

```bash
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net dev/net none bind,create=dir
```

For your unprivileged container to be able to access the /dev/net/tun from your host, you need to set the owner by running:

```bash
# Replace '0:0' with the PID and GID from your user (eg. run id -u and id -g to find out)
chown 0:0 /dev/net/tun
```

Then check the permissions are set correctly:

```bash
ls -l /dev/net
# total 0
# crw-rw-rw- 1 root root 10, 200 Jan  9 15:14 tun
```
