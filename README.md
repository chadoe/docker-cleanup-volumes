docker-cleanup-volumes.sh
======================

##### WARNING: volumes have changed in Docker 1.7.0, if your're using Docker 1.7.0 (or up) and you downloaded the script before June 27th 2015 you should download an updated version of the script or `docker pull martin/docker-cleanup-volumes` an updated image. Older versions of the script *will* delete all your volumes on Docker 1.7.0.

Shellscript to delete orphaned docker volumes in /var/lib/docker/volumes and /var/lib/docker/vfs/dir

usage: sudo ./docker-cleanup-volumes.sh [--dry-run]

--dry-run : Use the --dry-run option to have the script print the volumes that would have been deleted without actually deleting them.

### Running from Docker
run the "latest" forward compatible Docker client version, currently 1.5.0 (available are 1.4.1, 1.5.0, 1.6.2 and 1.7.0)
```
docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes --dry-run
```
or run a specific Docker client version, e.g. 1.4.1
```
docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes:1.4.1 --dry-run
```
