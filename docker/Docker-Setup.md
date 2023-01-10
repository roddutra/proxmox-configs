# Docker Setup Instructions

## Create LXC Container in Proxmox

1. Go to the `local (proxmox)` storage drive, then open the **CT Templates** tab.
2. Click the **Templates** button and download the latest image for Ubuntu.
3. On the top-right click the **Create CT** button, give your container an ID and a custom Hostname (eg. `Docker-LXC`) and setup a password.
4. On the **Template** step, pick the Ubuntu image downloaded earlier, then give the container the desired disk space, number of CPUs and RAM (eg. `4096`) and leave all other configs as they are.

> ⚠️ IMPORTANT: when creating the container make sure it is setup as **Priviledged** by unticking the `Unpriviledged container` checkbox on the first step.
>
> Once created, go back to **Options > Features** and enable `Nesting` as well as `Create Device Nodes`.

5.

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
