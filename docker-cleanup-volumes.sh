#! /bin/bash

#usage: sudo ./docker-cleanup-volumes.sh [--dry-run]

dockerdir=/var/lib/docker
volumesdir=${dockerdir}/volumes
vfsdir=${dockerdir}/vfs/dir
allvolumes=()
dryrun=false

function delete_volumes() {
  targetdir=$1
  echo
  if [[ ! -d ${targetdir} ]]; then
        echo "Directory ${targetdir} does not exist, skipping."
        return
  fi
  echo "Delete unused volume directories from $targetdir"
  for dir in /${targetdir}/*/
  do
        dir=${dir%*/}
        dir=${dir##*/}
        if [[ "${dir}" =~ [0-9a-f]{64} ]]; then
                if [[ ${allvolumes[@]} =~ "${dir}" ]]; then
                        echo In use ${dir}
                else
                        if [ "${dryrun}" = false ]; then
                                echo Deleting ${dir}
                                rm -rf ${targetdir}/${dir}
                        else
                                echo Would have deleted ${dir}
                        fi
                fi
        else
                echo Not a volume ${dir}
        fi
  done
}

if [ $UID != 0 ]; then
    echo "You need to be root to use this script."
    exit 1
fi

docker_bin=$(which docker.io || which docker)
if [ -z "$docker_bin" ] ; then
    echo "Please install docker. You can install docker by running \"wget -qO- https://get.docker.io/ | sh\"."
    exit 1
fi

if [ "$1" = "--dry-run" ]; then
        dryrun=true
else if [ -n "$1" ]; then
        echo "Cleanup docker volumes: remove unused volumes."
        echo "Usage: ${0##*/} [--dry-run]"
        echo "   --dry-run: dry run: display what would get removed."
        exit 1
fi
fi


#All volumes from all containers
for container in `${docker_bin} ps -a -q --no-trunc`; do
        #add container id to list of volumes, don't think these
        #ever exists in the volumesdir but just to be safe
        allvolumes+=${container}
        #add all volumes from this container to the list of volumes
        for vid in `${docker_bin} inspect --format='{{range $vol, $path := .Volumes}}{{$path}}{{"\n"}}{{end}}' ${container}`; do
                if [[ "${vid##*/}" =~ [0-9a-f]{64} ]]; then
                        allvolumes+=("${vid##*/}")
                fi
        done
done

delete_volumes ${volumesdir}
delete_volumes ${vfsdir}
