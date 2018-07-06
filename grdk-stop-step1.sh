#!/bin/bash

echo "STEP1 - START"

### GRDK-REPO (GITLAB)
SERVICES=$(docker service ls -q -f name=grdk-repo_web | wc -l)
if [[ "$SERVICES" -gt 0 ]]; then
	echo "GRDK-REPO - STACK REMOVED"
	docker stack rm grdk-repo
else
	echo "GRDK-REPO - STACK REMOVE skiped"
fi

echo "STEP1 - END"
