# Docker Setup Instructions

## Create LXC Container in Proxmox

TODO!

## Install Docker

TODO!

### Uninstall AppArmor

AppArmor prevents the Portainer image from running in the LXC container so it needs to be uninstalled.

```bash
apt remove apparmor --purge -y
rm -rf /etc/apparmor*
```

## Install Portainer

TODO!

### Free up necessary ports for AdGuardHome, etc

Certain containers (aka. AdGuardHome) need access to ports that are used by systemd-resolved which needs to be disabled.

Open up an SSH console and run:

```
nano /etc/systemd/resolved.conf
```

and change the values to the ones below

```
DNS=1.1.1.1
DNSStubListener=no
```

then run:

```
systemctl disable systemd-resolved.service
```

and finally:

```
reboot now
```

You can now create the AdGuardHome stack.
