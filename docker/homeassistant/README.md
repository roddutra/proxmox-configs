# Home Assistant Container installation

This install is for the **Home Assistant Container** installation method. You can compare them in [this link](https://www.home-assistant.io/installation#compare-installation-methods) from Home Assistant's docs.

I have chosen to use the Container installation method for the following reasons:

- Using a container, HA can share the resources already made available to my Ubuntu LXC container from the Proxmox host rather than spinning up a whole new VM which will have it's own overhead (eg. RAM, processor cores)
- I can keep HA separate from other services like MQTT so, for example, when I need to restart HA my Zigbee network doesn't go down
- And, most importantly, I am not locked in to the Add-ons that HA or the HA Community have built which are all typically available as individual services themselves that I can run independently in Docker alongside HA

## Install

TODO!

##

## Resources

- [Living without add-ons on Home Assistant Container](https://www.youtube.com/watch?v=DV_OD4OPKno)
- [Installing Docker and Home Assistant Container](https://www.youtube.com/watch?v=S-itdbqwj4I)
- [Automatically Updating Home Assistant Container (and other Docker Containers)](https://www.youtube.com/watch?v=Wx1TsuTgv_Q)
