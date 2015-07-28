docker-cleanup-volumes.sh
======================

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/chadoe/docker-cleanup-volumes/master/LICENSE)


##### WARNING: volumes have changed in Docker 1.7.0, if your're using Docker 1.7.0 (or up) and you downloaded the script before June 27th 2015 you should download an updated version of the script or `docker pull martin/docker-cleanup-volumes` an updated image. Older versions of the script *will* delete all your volumes on Docker 1.7.0.

Shellscript to delete orphaned docker volumes in /var/lib/docker/volumes and /var/lib/docker/vfs/dir

### Precautions
1. [Backup your volumes](https://docs.docker.com/userguide/dockervolumes/#backup-restore-or-migrate-data-volumes "Docker Docs") because.. you know.. the script may not like your system.
2. When using the script for the first time or after upgrading the host Docker version, run the script with the `--dry-run` parameter first to make sure it works okay and doesn't delete any volumes that shouldn't be deleted. If you feel bold and run it without `--dry-run` anyway, make sure you did 1.

### Usage standalone script
$ sudo ./docker-cleanup-volumes.sh [--dry-run]

--dry-run : Use the --dry-run option to have the script print the volumes that would have been deleted without actually deleting them.

### Running from Docker
Run the "latest" forward compatible Docker client version (works with host Docker 1.5.x, 1.6.x and 1.7.x)
```
$ docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes --dry-run
```
To run a specific Docker client version, e.g. 1.4.1
```
$ docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes:1.4.1 --dry-run
```

### Running from docker using the host docker binary
It is also possible to use the host docker binary by mounting the host docker bin directory. This way you make sure the Docker versions are the same between host and container. For example:
```
$ docker run -v $(which docker):/bin/docker -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes --dry-run
```
