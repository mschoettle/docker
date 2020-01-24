#!/bin/bash

version="2.1.2"

docker container stop traefik-$version
docker container rm traefik-$version

docker run \
	-d \
	--name=traefik-$version \
	--restart always \
	-p 80:80 \
	-p 443:443 \
	-v $(pwd)/traefik.yml:/etc/traefik/traefik.yml \
	-v $(pwd)/config:/config \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	-v /etc/localtime:/etc/localtime:ro \
	--network=mynet \
        traefik:$version
