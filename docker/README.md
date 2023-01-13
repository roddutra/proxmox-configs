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

## Setup VSCode on a Client Machine

Rather than using `vi` or `nano` via the terminal in the Linux host, you can simply connect your VSCode (eg. from your Mac) to the host via SSH so you have the ease of use of VSCode with direct access to the config files in the Linux box.

For this, simply install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) VSCode extension and then click the **Remote Explorer** icon on the primary sidebar.

Then click the `+` icon next to SSH (you need to hover over SSH to see it) then type the SSH command to connect to the host. For example:

```bash
ssh root@192.168.1.2
```

Then select the default location to store your credentials (unless you have a reason, select the first option on the list).

Hit the refresh icon next to SSH to see your new configuration. Click on the arrow to connect using the current window or right-click to open in a new window instead.

You'll now be promted for the password and then you'll be connected to the remote host.

Now go to the file explorer icon in VSCode and click **Open Folder**. There you'll be shown a list of directories available in the host to select from. Once you select it, you'll be prompted again for a password and you'll have the full VSCode experience directly into your Linux box, including integrated terminal and file uploads!

Goodbye `vi` or `nano` 👋.

---

## [WIP - Currently broken] Mapping a USB device to a LXC Container

When using a USB device like a Zigbee Coordinator, you need to map the USB serial port from the host to the Container so it can be accessed.

Plug the USB device into the host machine and SSH into it (or open the Console in Proxmox) then run `lsusb`. This should give you an output like:

```
Bus 002 Device 002: ID 0480:a00a Toshiba America Inc External USB 3.0
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 003: ID 1cf1:0030 Dresden Elektronik ZigBee gateway [ConBee II]
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

I am using a ConBee 2 USB stick so my device's **VENDOR** is `1cf1` and the **PRODUCT** is `0030`.

Run `ls -la /dev/ttyACM0` and note **cgroup**, in my case it was 166:

```
crw-rw---- 1 root dialout 166, 0 Jan 13 13:47 /dev/ttyACM0
```

Now, you'll need to find out what your USER and GROUP are for your Linux user:

```bash
id -u
# 0 is your USER
id -g
# 0 is your GROUP
```

Use the outputs from these commands to replace `{USER}` and `{GROUP}` in the following commands.

To handle the permission for the device I created a new directory where I created a device file with correct permissions. Change `166` in **mknod** to the **cgroup** you noted in previous step and replace `{YOUR_PROXMOX_ID}` with the ID of the relevant LXC/VM from Proxmox (eg. `100`):

```bash
mkdir -p /lxc/{YOUR_PROXMOX_ID}/devices
cd /lxc/{YOUR_PROXMOX_ID}/devices/
mknod -m 660 ttyACM0 c 166 0
chown {USER}:{GROUP} ttyACM0
ls -al /lxc/{YOUR_PROXMOX_ID}/devices/ttyACM0
```

Now open `/etc/pve/lxc/{YOUR_PROXMOX_ID}.conf` (with VSCode as per above or nano or vi) and add the following lines for **cgroup** and **mount** to the end of the config but before the list of snapshots (eg. `[snapshot_name] ...`).

Change `166` in **cgroup** to the cgroup you noted before.

```conf
lxc.cgroup2.devices.allow: c 166:* rwm
lxc.mount.entry: /lxc/{YOUR_PROXMOX_ID}/devices/ttyACM0 dev/ttyACM0 none bind,optional,create=file,mode=0666
```

Now create `/etc/udev/rules.d/50-myusb.rules` and, makind sure to replace `{VENDOR}` and `{PRODUCT}`, add:

```bash
SUBSYSTEM=="tty", ATTRS{idVendor}=="{VENDOR}", ATTRS{idProduct}=="{PRODUCT}", MODE="0666", SYMLINK+="conbee"
```

Save the file and run:

```bash
udevadm control --reload-rules && service udev restart && udevadm trigger
ls -l /dev/ttyACM*

# crw-rw-rw- 1 root dialout 166, 0 Jan 13 14:24 /dev/ttyACM0
```

Note the output of the last command, which you will need to pass to the relevant Docker container (eg. `/dev/ttyACM0`). In the Docker Compose file for the relevant container you want to access the USB device from you should then use:

```yml
# ...
devices:
  - /dev/ttyACM0:/dev/ttyACM0
```

### Resources

The information for this guide was compiled from the following links:

- https://www.homeautomationguy.io/docker-tips/accessing-usb-devices-from-docker-containers/
- https://gist.github.com/crundberg/a77b22de856e92a7e14c81f40e7a74bd

### USB Device option 2

Run `ls -l /dev/serial/by-id` on the Proxmox node shell (not the LXC):

```bash
total 0
lrwxrwxrwx 1 root root 13 Jan 13 14:24 usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2430090-if00 -> ../../ttyACM0
```

The device path is then `/dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2430090-if00`
