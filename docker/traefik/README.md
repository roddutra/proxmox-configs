# Traefik Setup [Work-in-Progress]

> WARNING: this setup is not currently working and needs some tweaking ⚠️

1. Create the local folders for Traefik:

```bash
# Make sure you are in the home directory (eg. '/root')
cd
mkdir traefik
cd traefik
mkdir data
cd data
touch acme.json
chmod 600 acme.json
touch traefik.yml
touch config.yml
```

1. Generate Basic Auth Password:

```bash
apt update
apt install apache2-utils
```

then replace `<USER>` with your username and `<PASSWORD>` with your password to be hashed in the following command:

```bash
echo $(htpasswd -nb "<USER>" "<PASSWORD>") | sed -e s/\\$/\\$\\$/g
```

> If you get an error with the above command like `bash: !@: event not found` then type the following command to turn off history expansion and then try the previous command again:
>
> ```bash
> set +H
> ```

Paste the output in your [docker-compose.yml](docker-compose.yml) in line (`traefik.http.middlewares.traefik-auth.basicauth.users=<USER>:<HASHED-PASSWORD>`)

3. Use the [docker-compose.yml](docker-compose.yml) to create the stack in Portainer and start Traefik.

## Resources

- [Traefik docs](https://www.youtube.com/watch?v=wLrmmh1eI94)
- [VIDEO: Is this the BEST Reverse Proxy for Docker? // Traefik Tutorial](https://www.youtube.com/watch?v=wLrmmh1eI94)
- [ChristianLempa/boilerplates/docker-compose/traefik](https://github.com/ChristianLempa/boilerplates/tree/main/docker-compose/traefik)
- [VIDEO: Put Wildcard Certificates and SSL on EVERYTHING - Traefik Tutorial](https://www.youtube.com/watch?v=liV3c9m_OX8)
  - [Instructions](https://docs.technotim.live/posts/traefik-portainer-ssl/)
