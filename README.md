docker-cleanup-volumes
======================

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/chadoe/docker-cleanup-volumes/master/LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/martin/docker-cleanup-volumes.svg)](https://hub.docker.com/r/martin/docker-cleanup-volumes/)
[![ImageLayers Size](https://img.shields.io/imagelayers/image-size/martin/docker-cleanup-volumes/latest.svg)](https://hub.docker.com/r/martin/docker-cleanup-volumes/)
[![ImageLayers Layers](https://img.shields.io/imagelayers/layers/martin/docker-cleanup-volumes/latest.svg)](https://hub.docker.com/r/martin/docker-cleanup-volumes/)
[![Docker Stars](https://img.shields.io/docker/stars/martin/docker-cleanup-volumes.svg)](https://hub.docker.com/r/martin/docker-cleanup-volumes/)

##### WARNING: Use at your own risk, always test with the `--dry-run` parameter first. If it's not compatible with your system or Docker version it *will* delete all your volumes.

Shellscript to delete orphaned docker volumes in /var/lib/docker/volumes and /var/lib/docker/vfs/dir  
Docker version 1.4.1 up to 1.10.x

### Note about Docker 1.9 and up
To delete orphaned volumes in Docker 1.9 and up you can also use the built-in `docker volume` commands instead of this docker-cleanup-volumes script. The built-in command also deletes any directory in /var/lib/docker/volumes that is not a volume so make sure you didn't put anything in there you want to save:  
List:
```
$ docker volume ls -qf dangling=true
```

Cleanup:
```
$ docker volume rm $(docker volume ls -qf dangling=true)
```
Or, handling a no-op better but Linux specific:
```
$ docker volume ls -qf dangling=true | xargs -r docker volume rm
```

### Precautions
1. Don't use with boot2docker, docker machine or any tools that use a virtual machine to run docker, unless you run the script on the virtual machine itself (meaning don't run this script or docker command from your MAC).
2. [Backup your volumes](https://docs.docker.com/userguide/dockervolumes/#backup-restore-or-migrate-data-volumes "Docker Docs") because.. you know.. the script may not like your system.
3. When using the script for the first time or after upgrading the host Docker version, run the script with the `--dry-run` parameter first to make sure it works okay and doesn't delete any volumes that shouldn't be deleted. If you feel bold and run it without `--dry-run` anyway, make sure you did 1.

### Usage standalone script
$ sudo ./docker-cleanup-volumes.sh [--dry-run] [--verbose]

--dry-run : Use the --dry-run option to have the script print the volumes that would have been deleted without actually deleting them.  
--verbose : Have the script output more information.  

### Running from Docker
Run the "latest" forward compatible Docker client version (works with host Docker 1.4.x up to 1.9.x)
```
$ docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes --dry-run
```

If you symlinked /var/lib/docker to somewhere else make sure you tell the Docker container where it is by providing the real path or by using readlink in volume parameter.
```
$ docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(readlink -f /var/lib/docker):/var/lib/docker --rm martin/docker-cleanup-volumes --dry-run
```

### Running from docker using the host docker binary
It is also possible to use the host docker binary by mounting the host docker bin directory. This way you make sure the Docker versions are the same between host and container. For example:
```
$ docker run -v $(which docker):/bin/docker -v /var/run/docker.sock:/var/run/docker.sock -v $(readlink -f /var/lib/docker):/var/lib/docker --rm martin/docker-cleanup-volumes --dry-run
```
