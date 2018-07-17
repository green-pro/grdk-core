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
