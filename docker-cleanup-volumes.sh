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
elif [[ $dockerPs =~ ' --graph=' ]]; then
    dockerdir=`echo $dockerPs | sed 's/.* --graph//' | cut -d '=' -f 2 | awk '{print $1}'`
fi

dockerdir=$(readlink -f $dockerdir)

volumesdir=${dockerdir}/volumes
vfsdir=${dockerdir}/vfs/dir
allvolumes=()
dryrun=false
verbose=false

function log_verbose() {
    if [ "${verbose}" = true ]; then
        echo "$1"
    fi;
}

function delete_volumes() {
  targetdir=$1
  echo
  if [[ ! -d ${targetdir} || ! "$(ls -A ${targetdir})" ]]; then
        echo "Directory ${targetdir} does not exist or is empty, skipping."
        return
  fi
  echo "Delete unused volume directories from $targetdir"
  for dir in $(find ${targetdir} -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  do
        dir=$(basename $dir)
        if [[ -d "${targetdir}/${dir}/_data" || "${dir}" =~ [0-9a-f]{64} ]]; then
                if [ ${#allvolumes[@]} -gt 0 ] && [[ ${allvolumes[@]} =~ "${dir}" ]]; then
                        echo "In use ${dir}"
                else
                        if [ "${dryrun}" = false ]; then
                                echo "Deleting ${dir}"
                                rm -rf "${targetdir}/${dir}"
                        else
                                echo "Would have deleted ${dir}"
                        fi
                fi
        else
                echo "Not a volume ${dir}"
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

while [[ $# > 0 ]]
do
    key="$1"

    case $key in
        -n|--dry-run)
            dryrun=true
        ;;
        -v|--verbose)
            verbose=true
        ;;
        *)
            echo "Cleanup docker volumes: remove unused volumes."
            echo "Usage: ${0##*/} [--dry-run] [--verbose]"
            echo "   -n, --dry-run: dry run: display what would get removed."
            echo "   -v, --verbose: verbose output."
            exit 1
        ;;
    esac
    shift
done

# Make sure that we can talk to docker daemon. If we cannot, we fail here.
${docker_bin} info >/dev/null

container_ids=$(${docker_bin} ps -a -q --no-trunc)

#All volumes from all containers
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for container in $container_ids; do
        #add container id to list of volumes, don't think these
        #ever exists in the volumesdir but just to be safe
        allvolumes+=${container}
        #add all volumes from this container to the list of volumes
        for volpath in $(
                ${docker_bin} inspect --format='{{range $vol, $path := .Volumes}}{{$path}}{{"\n"}}{{end}}' ${container}; \
                ${docker_bin} inspect --format='{{range $mount := .Mounts}}{{$mount.Source}}{{"\n"}}{{end}}' ${container} \
        ); do
                log_verbose "Processing volumepath ${volpath} for container ${container}"
                #try to get volume id from the volume path
                vid=$(echo "${volpath}"|sed 's|.*/\(.*\)/_data$|\1|;s|.*/\([0-9a-f]\{64\}\)$|\1|')
                # check for either a 64 character vid or then end of a volumepath containing _data:
                if [[ "${vid}" =~ ^[0-9a-f]{64}$ || (${volpath} =~ .*/_data$ && ! "${vid}" =~ "/") ]]; then
                        log_verbose "Found volume ${vid}"
                        allvolumes+=("${vid}")
                else
                        #check if it's a bindmount, these have a config.json file in the ${volumesdir} but no files in ${vfsdir} (docker 1.6.2 and below)
                        for bmv in $(find ${volumesdir} -name config.json -print | xargs grep -l "\"IsBindMount\":true" | xargs grep -l "\"Path\":\"${volpath}\""); do
                                bmv="$(basename "$(dirname "${bmv}")")"
                                log_verbose "Found bindmount ${bmv}"
                                allvolumes+=("${bmv}")
                                #there should be only one config for the bindmount, delete any duplicate for the same bindmount.
                                break
                        done
                fi
        done
done
IFS=$SAVEIFS

delete_volumes ${volumesdir}
delete_volumes ${vfsdir}

