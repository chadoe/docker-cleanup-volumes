#! /bin/bash

set -eo pipefail

dockerdir=/mnt/sda1/var/lib/docker
volumesdir=${dockerdir}/volumes
vfsdir=${dockerdir}/vfs/dir
allvolumes=()

function delete_volumes() {
	targetdir=$1
	if ! boot2docker ssh sudo test -d ${targetdir} ; then
        echo "Directory ${targetdir} does not exist, skipping."
        return
	fi
	echo "# Delete unused volume directories from $targetdir"
	for dir in $(boot2docker ssh sudo ls ${targetdir} 2>/dev/null)
	do
        dir=$(basename $dir)
        if [[ "${dir}" =~ [0-9a-f]{64} ]]; then
            if [[ ! ${allvolumes[@]} =~ "${dir}" ]]; then
				if [ "$report_size" = "true" ] ; then
					echo -n sudo rm -rf ${targetdir}/${dir}
					echo " # ($(boot2docker ssh sudo du -sh ${targetdir}/${dir} | cut -f 1))"
				else
					echo sudo rm -rf ${targetdir}/${dir}
				fi
            fi
        fi
	done
}

docker_bin=$(which docker.io || which docker)
if [ -z "$docker_bin" ] ; then
    echo "docker cli not found"
    exit 1
fi

if [ "$1" = "--size" ] ; then
	report_size=true
elif [ -n "$1" ]; then
    cat <<EOF
Cleanup docker volumes, boot2docker version:

This script will not remove or change anything. It will just report a list
of commands to be run manually in a boot2docker ssh shell to remove
orphaned volumes in the boot2docker VM.

Use --size to report the total size for each volume.

Usage: ${0##*/} [ --size ]
EOF
    exit 1
fi

# Make sure that we can talk to docker daemon. If we cannot, we fail here.
docker info >/dev/null

#All volumes from all containers
for container in `${docker_bin} ps -a -q --no-trunc`; do
    #add container id to list of volumes, don't think these
    #ever exists in the volumesdir but just to be safe
    allvolumes+=${container}
    #add all volumes from this container to the list of volumes
    for vid in `${docker_bin} inspect --format='{{range $vol, $path := .Volumes}}{{$path}}{{"\n"}}{{end}}' ${container}`; do
        if [[ ${vid} == ${vfsdir}* && "${vid##*/}" =~ [0-9a-f]{64} ]]; then
            allvolumes+=("${vid##*/}")
		# else
		# 	echo "# Check volume \"$vid\" manually"
		fi
    done
done

delete_volumes ${volumesdir}
delete_volumes ${vfsdir}
