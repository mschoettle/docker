#!/bin/bash

version="1.10.3"

docker container stop gitea-$version
docker container rm gitea-$version

docker run \
	-d \
	--name=gitea-$version \
	--restart always \
	`#-p 22:22` \
	--expose 3000 \
	-v /mnt/mydisk/docker-volumes/gitea/:/data \
	-v /etc/localtime:/etc/localtime:ro \
	--network=mynet \
	-l "traefik.enable=true" \
	-l "traefik.http.routers.gitea.rule=Host(\"git.mattsch.com\")" \
	-l "traefik.http.routers.gitea.tls=true" \
	-l "traefik.http.services.gitea.loadbalancer.server.port=3000" \
	mschoettle/gitea:$version
