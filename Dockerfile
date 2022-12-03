#
#Cleanup orphaned docker volumes
#Usage:
#docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes [--dry-run]
#
FROM alpine:3.17

MAINTAINER Martin van Beurden <chadoe@gmail.com>

ENV DOCKER_VERSION=20.10.21

#Install an up to date version of docker
RUN apk add --update-cache curl bash grep && \
# the docker package in alpine disables aufs and devicemapper
    curl -sSL https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz | tar -xz docker/docker --strip-components 1 && \
    mv ./docker /usr/bin && chmod +x /usr/bin/docker && \
#cleanup
    apk del curl && rm -rf /var/cache/apk/*

#Add the cleanup script
COPY ./docker-cleanup-volumes.sh /usr/local/bin/

#Define entrypoint
ENTRYPOINT ["/usr/local/bin/docker-cleanup-volumes.sh"]
