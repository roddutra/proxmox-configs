# Home Assistant Container installation

This install is for the **Home Assistant Container** installation method. You can compare them in [this link](https://www.home-assistant.io/installation#compare-installation-methods) from Home Assistant's docs.

I have chosen to use the Container installation method for the following reasons:

- Using a container, HA can share the resources already made available to my Ubuntu LXC container from the Proxmox host rather than spinning up a whole new VM which will have it's own overhead (eg. RAM, processor cores)
- I can keep HA separate from other services like MQTT so, for example, when I need to restart HA my Zigbee network doesn't go down
- And, most importantly, I am not locked in to the Add-ons that HA or the HA Community have built which are all typically available as individual services themselves that I can run independently in Docker alongside HA

## Install

Use the [docker compose file](docker-compose.yml) to setup your stack for HA.

## Displaying other Docker Services in HA

As we are not using the built-in add-ons from Home Assistant, we can still show the web UIs from our different services using the `panel_iframe` feature from Home Assistant.

Open the `configuration.yml` in the HA folder and add:

```yml
panel_iframe:
  portainer:
    title: 'Portainer'
    url: 'https://192.168.1.2:9443/#!/2/docker/containers'
    icon: mdi:docker
    require_admin: true
  zigbee2mqtt:
    title: 'zigbee2mqtt'
    url: 'http://192.168.1.2:8080/#/'
    icon: mdi:zigbee
    require_admin: true
```

Restart Home Assistant via the Developer Tools tab for the changes to take effect.

The example above adds 2 menu items, one for Portainer (displayed with a Docker icon) and one for Zigbee2MQTT (using the Ziggee icon).

## Resources

- [Installing Docker and Home Assistant Container](https://www.youtube.com/watch?v=S-itdbqwj4I)
- [Living without add-ons on Home Assistant Container](https://www.youtube.com/watch?v=DV_OD4OPKno)
- [Automatically Updating Home Assistant Container (and other Docker Containers)](https://www.youtube.com/watch?v=Wx1TsuTgv_Q)
