#! /bin/bash

set -eou pipefail

#usage: sudo ./docker-cleanup-volumes.sh [--dry-run]

docker_bin=$(which docker.io 2> /dev/null || which docker 2> /dev/null)

# Default dir
dockerdir=/var/lib/docker

# Look for an alternate docker directory with -g option
dockerPs=`ps aux | grep $docker_bin | grep -v grep` || :
if [[ $dockerPs =~ ' -g ' ]]; then
	dockerdir=`echo $dockerPs | sed 's/.* -g//' | cut -d ' ' -f 2`
fi

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
  for dir in $(find ${targetdir} -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  do
        dir=$(basename $dir)
        if [[ "${dir}" =~ [0-9a-f]{64} ]]; then
                if [ ${#allvolumes[@]} -gt 0 ] && [[ ${allvolumes[@]} =~ "${dir}" ]]; then
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

if [ -z "$docker_bin" ] ; then
    echo "Please install docker. You can install docker by running \"wget -qO- https://get.docker.io/ | sh\"."
    exit 1
fi

if [ $# -gt 0 ] && [ "$1" = "--dry-run" ]; then
        dryrun=true
else if [ $# -gt 0 ] && [ -n "$1" ]; then
        echo "Cleanup docker volumes: remove unused volumes."
        echo "Usage: ${0##*/} [--dry-run]"
        echo "   --dry-run: dry run: display what would get removed."
        exit 1
fi
fi

# Make sure that we can talk to docker daemon. If we cannot, we fail here.
${docker_bin} info >/dev/null

container_ids=$(${docker_bin} ps -a -q --no-trunc)

# Check if we're running as a docker container
if [[ ${container_ids[@]} =~ (^|[[:space:]])"$HOSTNAME" ]]; then
    # Get the dockerdir on the host from the volume mapped to /var/lib/docker
    dockerdir_match=`${docker_bin} inspect -f '{{ index .Volumes "/var/lib/docker" }}' $HOSTNAME`
else
    # Script is running standalone, dockerdir is the directory to use
    dockerdir_match=${dockerdir}
fi

# These directories are used to match with docker inspect values
volumesdir_match=${dockerdir_match}/volumes
vfsdir_match=${dockerdir_match}/vfs/dir

#All volumes from all containers
for container in $container_ids; do
        #add container id to list of volumes, don't think these
        #ever exists in the volumesdir but just to be safe
        allvolumes+=${container}
        #add all volumes from this container to the list of volumes
        for volpath in `${docker_bin} inspect --format='{{range $vol, $path := .Volumes}}{{$path}}{{"\n"}}{{end}}' ${container}`; do
		#try to get volume id from the volume path
		vid=$(echo "${volpath}"|sed "s|${vfsdir_match}||;s|${volumesdir_match}||;s/.*\([0-9a-f]\{64\}\).*/\1/")
                # host daemon shows original dir path - this is why _match variables are used:
                if [[ (${volpath} == ${vfsdir_match}* || ${volpath} == ${volumesdir_match}*) && "${vid}" =~ [0-9a-f]{64} ]]; then
                        allvolumes+=("${vid}")
                else
                        #check if it's a bindmount, these have a config.json file in the ${volumesdir} but no files in ${vfsdir} (docker 1.6.2 and below)
                        for bmv in `grep --include config.json -Rl "\"IsBindMount\":true" ${volumesdir} | xargs grep -l "\"Path\":\"${volpath}\""`; do
                                bmv="$(basename "$(dirname "${bmv}")")"
                                allvolumes+=("${bmv}")
                                #there should be only one config for the bindmount, delete any duplicate for the same bindmount.
                                break
                        done
                fi
        done
done

delete_volumes ${volumesdir}
delete_volumes ${vfsdir}
