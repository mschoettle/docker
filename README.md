# docker services on Raspberry Pi

A collection of docker files and configurations for my home server setup (using a Raspberry Pi 4).

Currently I use the following services:

  * [Gitea](https://gitea.io) for self-hosted Git service
  * [Nextcloud](https://nextcloud.com) (with nginx and redis) for syncing and sharing files at home
  * [traefik](https://containo.us/traefik/) v2 reverse proxy for TLS termination for all my services (including [Pi-hole](https://pi-hole.net/) and my routers web interface)

The containers can either be started using the shell script or docker-compose. However, please note that the start shell script is most likely outdated since I switched to the use of docker-compose at some point.

## Database

I run a MariaDB on the RPI directly and created a custom bridge network in docker that is used by the DB and all services. Therefore, you see the network `mynet` in the start script and docker-compose.

## Backups

I run a backup script (`backup.sh` in the respective service folder) every night which backs up the data to a second external disk using [restic](https://restic.net/).

## More Information 

For more information, such as how I set this all up in detail, check out my blog posts: https://mattsch.com/category/raspberry-pi/
