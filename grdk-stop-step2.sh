#!/bin/bash

echo "STEP2 - START"

### GRDK-N8N
SERVICES=$(docker service ls -q -f name=grdk-n8n_ | wc -l)
if [[ "$SERVICES" -gt 0 ]]; then
	echo "GRDK-N8N - STACK REMOVED"
	docker stack rm grdk-n8n
else
	echo "GRDK-N8N - STACK REMOVE skiped"
fi

### GRDK-BACKUP
SERVICES=$(docker service ls -q -f name=grdk-backup_cron | wc -l)
if [[ "$SERVICES" -gt 0 ]]; then
	echo "GRDK-BACKUP - STACK REMOVED"
	docker stack rm grdk-backup
else
	echo "GRDK-BACKUP - STACK REMOVE skiped"
fi

### GRDK-PROXY (NGINX)
if [ "$(docker ps -q -f name=grdk-proxy)" ]; then
	if [ "$(docker ps -aq -f status=exited -f name=grdk-proxy)" ]; then
		echo "GRDK-PROXY - STOP skiped"
	else
		echo "GRDK-PROXY - STOP"
		docker stop grdk-proxy
	fi
else
	echo "GRDK-PROXY - STOP skiped"
fi

### GRDK-MSG
SERVICES=$(docker service ls -q -f name=grdk-msg_web | wc -l)
if [[ "$SERVICES" -gt 0 ]]; then
	echo "GRDK-MSG - STACK REMOVED"
	docker stack rm grdk-msg
else
	echo "GRDK-MSG - STACK REMOVE skiped"
fi

echo "STEP2 - END"
