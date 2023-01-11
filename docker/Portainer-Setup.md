# Portainer Setup

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

## Extras

### Add Environment address

For the container links in the Portainer dashboard to work correctly, you need to setup the address for the **local** environment.

Go to **Environments > local** in the Portainer dashboard and modify the **Public IP** field with the IP address of the LXC Container you created (eg. `192.168.1.2`).

### Add custom Portainer App Templates URL

Community Portainer App Templates provide more preconfigured Portainer templates than what Portainer includes by default.

To modify this go to the **Settings** tab and change the `URL` in the **App Templates** section.

Here are some options:

- [https://github.com/mycroftwilde/portainer_templates](https://github.com/mycroftwilde/portainer_templates)
  - **URL:** `https://raw.githubusercontent.com/mycroftwilde/portainer_templates/master/Template/template.json`
- [https://github.com/Qballjos/portainer_templates](https://github.com/Qballjos/portainer_templates)
  - **URL:** `https://raw.githubusercontent.com/Qballjos/portainer_templates/master/Template/template.json`

When you update the App Templates URL, go to the **App Templates** tab in Portainer to see the updates list of available templates.

## Sample community Docker Stacks

- [Awesome Compose](https://github.com/docker/awesome-compose)
- [Awesome Stacks](https://github.com/ethibox/awesome-stacks)
