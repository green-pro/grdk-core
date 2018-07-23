#!/bin/bash

grdk_containers_checkup()
{
	# PARAMS
	PAR_CONT_NAME=$1
	PAR_MAX_ATTEMPTS=$2
	PAR_MULT=$3
	PAR_DELAY=2
	# CHECK
	sleep 1
	c=1
	proc_bar='.'
	while [ $c -le $PAR_MAX_ATTEMPTS ]
	do
		echo $proc_bar
		proc_bar="${proc_bar}."
		CONT_UP=$(docker ps -q -f name=$PAR_CONT_NAME)
		COUNT_CONT_UP=$(echo $CONT_UP | wc -w | awk '{print $1}')
		# echo "COUNT_CONT_UP = ${COUNT_CONT_UP}"
		if [[ "$COUNT_CONT_UP" = "$PAR_MULT" ]]; then
			# echo "Found ${PAR_MULT} containers"
			COUNT_STATUS=0
			for cid in $CONT_UP
			do
				c_inspect=$(docker container inspect -f '{{.State.Status}} {{.State.Running}} {{.State.Health}} {{.State.Pid}}' $cid)
				c_status=$(echo $c_inspect | awk '{print $1}')
				c_running=$(echo $c_inspect | awk '{print $2}')
				c_health=$(echo $c_inspect | awk '{print $3}')
				if [[ "$c_health" = '<nil>' ]]; then
					if [[ "$c_status" = 'running' && "$c_running" = 'true' ]]; then
						(( COUNT_STATUS++ ))
					fi
				else
					c_inspect=$(docker container inspect -f '{{.State.Health.Status}}' $cid)
					c_health_status=$(echo $c_inspect | awk '{print $1}')
					if [[ "$c_status" = 'running' && "$c_running" = 'true' && $c_health_status = 'healthy' ]]; then
						(( COUNT_STATUS++ ))
					fi
				fi
			done
			if [[ "$COUNT_STATUS" = "$PAR_MULT" ]]; then
				c=$PAR_MAX_ATTEMPTS
				return 1
			fi
		fi
		(( c++ ))
		sleep $PAR_DELAY
	done
	return 0
}

grdk_replace_vars()
{
	sed -e "s#{{ DK_SERVER_NODE_ROLE }}#${DK_SERVER_NODE_ROLE}#g" \
		-e "s#{{ DK_SERVER_IP }}#${DK_SERVER_IP}#g" \
		-e "s#{{ DK_SERVER_INST_NFS }}#${DK_SERVER_INST_NFS}#g" \
		-e "s#{{ DK_LOGGER_HOST }}#${DK_LOGGER_HOST}#g" \
		-e "s#{{ DK_REPO_HOST }}#${DK_REPO_HOST}#g" \
		-e "s#{{ DK_REPO_NFS_HOST }}#${DK_REPO_NFS_HOST}#g" \
		-e "s#{{ DK_REPO_NFS_PATH }}#${DK_REPO_NFS_PATH}#g" \
		-e "s#{{ DK_REPO_DI_HOST }}#${DK_REPO_DI_HOST}#g" \
		< $1 > $2
}

grdk_yaml2json()
{
	perl -MYAML::XS=LoadFile -MJSON::XS=encode_json -e 'for (@ARGV) { for (LoadFile($_)) { print encode_json($_),"\n" } }' \
		$1 > \
		$2
}

grdk_check_volumes()
{
	tmp_file="_grdk_check_volumes_js_${RANDOM}"
	grdk_yaml2json $1 $DK_INSTALL_PATH/tmp/$tmp_file
	echo "Searching in file: ${1}"
	nfs_volumes=$(cat $DK_INSTALL_PATH/tmp/$tmp_file | jq -r 'select(has("volumes")) |.volumes | to_entries | .[].value | select(.driver == "nfs") | select(has("driver_opts")) | .driver_opts | select(has("share")) | .share')
	for nfs_path in $nfs_volumes
	do
		echo "Volume: ${nfs_path}"
		read -p "Testar volume NFS? (Y|n) [n] " answer
		answer=${answer:-n}
		if [ "$answer" = "Y" ]; then
			echo "Resultado:"
			mkdir -p /var/tmp/test-nfs
			mount -t nfs4 $nfs_path /var/tmp/test-nfs
			nfs_ok=$(cat /proc/mounts | grep 'nfs4' | grep "${nfs_path} " -c)
			if [[ "$nfs_ok" -gt 0 ]]; then
				echo "NFS OK"
			else
				echo "NFS FAIL"
				exit 1
			fi
			umount /var/tmp/test-nfs
			sleep 1
		fi
	done
}
