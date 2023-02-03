# Eclipse Mosquitto broker

Create the required directories:

```bash
mkdir /root/mosquitto/config
mkdir /root/mosquitto/data
mkdir /root/mosquitto/log
```

Create the config file:

```bash
touch /root/mosquitto/config/mosquitto.conf
```

Then copy the contents of the [config file](mosquitto.conf) from this repo to the newly created `mosquitto.conf` file above.

Then use the [docker-compose.yml](docker-compose.yml) file and create the stack.

## Create a username and password

Open the docker container and login to the console using `sh`, then run the following command replacing `{USERNAME}` with your desired username:

```bash
mosquitto_passwd -c /mosquitto/config/pwfile {USERNAME}
```

Enter & re-enter your desired password and this is all done as this command has now created a file called `pwdfile` in your config folder with your username and hashed password.

Restart the docker container.

## MQTT Explorer

To visualise and monitor the MQTT topics and activity in your network, there is a great desktop app called [MQTT Explorer](https://mqtt-explorer.com/) that you can use.
