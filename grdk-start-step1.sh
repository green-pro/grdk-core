#!/bin/bash

echo "STEP1 - START"

if [ "$DK_REPO_INST_GL" = "Y" ]; then

	### GRDK-REPO (GITLAB)
	SERVICES=$(docker service ls -q -f name=grdk-repo_web | wc -l)
	if [[ "$SERVICES" -gt 0 ]]; then
		echo "GRDK-REPO - STACK DEPLOY skiped"
	else
		echo "GRDK-REPO - RUN STACK DEPLOY"
		grdk_replace_all_vars ./vendor/grdk-core/services/repo/docker-stack.yml ./vendor/grdk-core/services/repo/_docker-stack.yml
		docker stack deploy --compose-file  ./vendor/grdk-core/services/repo/_docker-stack.yml grdk-repo
	fi

else

	### GRDK-REPO (OTHERS)
	SERVICES=$(docker service ls -q -f name=grdk-repo_di | wc -l)
	if [[ "$SERVICES" -gt 0 ]]; then
		echo "GRDK-REPO - STACK DEPLOY skiped"
	else
		echo "GRDK-REPO - RUN STACK DEPLOY"
		grdk_replace_all_vars ./vendor/grdk-core/services/repo/docker-stack-nogl.yml ./vendor/grdk-core/services/repo/_docker-stack-nogl.yml
		docker stack deploy --compose-file  ./vendor/grdk-core/services/repo/_docker-stack-nogl.yml grdk-repo
	fi

fi

echo "STEP1 - END"
