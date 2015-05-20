#
#Cleanup orphaned docker volumes
#Usage:
#docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes [--dry-run]
#
FROM alpine:3.1

MAINTAINER Martin van Beurden <chadoe@gmail.com>

ENV DOCKER_VERSION=1.6.2

#Install an up to date version of docker
RUN apk add --update-cache curl bash grep && rm -rf /var/cache/apk/*
# the docker package in alpine disables aufs and devicemapper
RUN curl -sSL https://get.docker.com/builds/Linux/x86_64/docker-$DOCKER_VERSION -o /usr/bin/docker && \
  chmod +x /usr/bin/docker

#Add the cleanup script
ADD ./docker-cleanup-volumes.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-cleanup-volumes.sh

#Define entrypoint
ENTRYPOINT ["/usr/local/bin/docker-cleanup-volumes.sh"]
