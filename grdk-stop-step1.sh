#!/bin/bash

echo "STEP1 - START"

if [ "$DK_REPO_INST_GL" = "Y" ]; then

	### GRDK-REPO (GITLAB)
	SERVICES=$(docker service ls -q -f name=grdk-repo_web | wc -l)
	if [[ "$SERVICES" -gt 0 ]]; then
		echo "GRDK-REPO - STACK REMOVED"
		docker stack rm grdk-repo
	else
		echo "GRDK-REPO - STACK REMOVE skiped"
	fi

else

	### GRDK-REPO (OTHERS)
	SERVICES=$(docker service ls -q -f name=grdk-repo_di | wc -l)
	if [[ "$SERVICES" -gt 0 ]]; then
		echo "GRDK-REPO - STACK REMOVED"
		docker stack rm grdk-repo
	else
		echo "GRDK-REPO - STACK REMOVE skiped"
	fi

fi

echo "STEP1 - END"
