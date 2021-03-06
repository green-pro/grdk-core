#!/bin/bash

source $DK_INSTALL_PATH/vendor/grdk-core/lib/include-functions.sh

grdk_logger_send "[CheckServices] Started"

### CHECK REQUIREMENTS

grdk_containers_checkup grdk-msg_web 10 1
if [ $? != 1 ]; then
	grdk_logger_send "[CheckServices] GRDK-MSG - Not Found"
	exit 1
fi

### CHECK SERVICES

now_s=$(date -u +'%s')

services=$(docker service ls --filter mode=replicated --format '{{.ID}} {{.Name}} {{.Replicas}} {{.Image}}')
i=0

oldIFS=$IFS
IFS=$'\n'
for line in $services; do
	fields=($(echo $line | tr " " "\n"))
	id=${fields[0]}
	name=${fields[1]}
	replicas=${fields[2]}
	_replicas=($(echo $replicas | tr "/" "\n"))
	image=${fields[3]}

	updatedat=$(docker service inspect --format='{{.UpdatedAt}}' $name)
	updatedat=${updatedat:0:19}
	updatedat_s=$(date -u -d "$updatedat" +'%s')

	# Skip recent 5 min
	updatedat_se=300
	let updatedat_se=$updatedat_s+$updatedat_se
	if [ $updatedat_se -ge $now_s ]; then
		grdk_logger_send "[CheckServices] Service ${name} skiped - Recent"
		continue
	fi

	if [ "${_replicas[0]}" = "${_replicas[1]}" ]; then
		running=$(docker service ps --filter 'desired-state=running' --format "{{.Image}}" $name)
		for run_image in $running; do
			if [ "$image" != "$run_image" ]; then
				grdk_msg_send "[CheckServices] Service ${name} not match run image ${image}"
				grdk_logger_send "[CheckServices] Service ${name} not match run image ${image}"
			fi
		done
	else
		grdk_msg_send "[CheckServices] Service ${name} with replicas is down ${replicas}"
		grdk_logger_send "[CheckServices] Service ${name} with replicas is down ${replicas}"
	fi

	let i=$i+1
done
IFS=$old_IFS

### END

grdk_logger_send "[CheckServices] Completed (${i})"
