#
#Cleanup orphaned docker volumes
#Usage:
#docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes [--dry-run]
#
FROM alpine:3.2

MAINTAINER Martin van Beurden <chadoe@gmail.com>

ENV DOCKER_VERSION=1.4.1

#Install an up to date version of docker
RUN apk add --update-cache curl bash grep && \
# the docker package in alpine disables aufs and devicemapper
    curl -sSL https://get.docker.com/builds/Linux/x86_64/docker-$DOCKER_VERSION -o /usr/bin/docker && \
    chmod +x /usr/bin/docker && \
#cleanup
    apk del curl && rm -rf /var/cache/apk/*

#Add the cleanup script
COPY ./docker-cleanup-volumes.sh /usr/local/bin/

#Define entrypoint
ENTRYPOINT ["/usr/local/bin/docker-cleanup-volumes.sh"]
