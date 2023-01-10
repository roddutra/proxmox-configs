# Portainer Setup

Follow the instructions in the [Docker-Setup](Docker-Setup.md) instructions and Portainer will be ready to use.

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
