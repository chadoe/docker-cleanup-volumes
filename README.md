docker-cleanup-volumes.sh
======================

Shellscript to delete orphaned docker volumes in /var/lib/docker/volumes and /var/lib/docker/vfs/dir

usage: sudo ./docker-cleanup-volumes.sh [--dry-run]

--dry-run : Use the --dry-run option to have the script print the volumes that would have been deleted without actually deleting them.

### Running from Docker
run the latest Docker client version, currently 1.5.0
```
docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes --dry-run
```
or run a specific Docker client version, e.g. 1.4.1
```
docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes:1.4.1 --dry-run
```

boot2docker-cleanup-volumes.sh
==============================

Boot2docker flavor of the shellscript above.

usage: ./boot2docker-cleanup-volumes.sh [--size]

--size : display also the total size of each volume

You can use (copy and paste) the output of this script to remove the volumes in
your boot2docker VM using the `boot2docker ssh` shell.
