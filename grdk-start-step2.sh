#!/bin/bash

echo "STEP2 - START"

### CHECK REQUIREMENTS

CHKRC=1
if [ "$DK_REPO_INST_GL" = "Y" ]; then
	CHKRC=3
fi
set +e
grdk_containers_checkup grdk-repo_ 600 $CHKRC
if [ $? = 1 ]; then
	echo "GRDK-REPO - OK"
else
	echo "GRDK-REPO - Not Found"
	exit 1
fi
set -e

### PAUSA
echo "Aguardando..."
sleep 5s

### AUTOIMPORT IMAGES
echo "AUTOIMPORT IMAGES"
for entry in "./vendor/grdk-core/services"/*
do
	if [ -d "$entry" ]; then
		if [ -f "${entry}/autoimport_images.conf" ]; then
			echo "Processing AutoimportImages: ${entry}/autoimport_images.conf"
			for cpimg in `cat $entry/autoimport_images.conf`; do
				echo "Image: ${cpimg}"
				imgname="${cpimg%:*}"
				imgtag="${cpimg##*:}"
				if [ "$imgname" = "$imgtag" ]; then
					imgtag=latest
				fi
				echo "    name: ${imgname}"
				echo "    tag: ${imgtag}"
				imginfo=$(curl -sS "http://${DK_REPO_DI_HOST}:5000/v2/${imgname}/tags/list")
				imgtagexists=$(echo $imginfo | jq -r 'select(has("tags")) | .tags | to_entries | .[] | select(.value == "'$imgtag'") | .value' | wc -l)
				if [ $imgtagexists == 1 ]; then
					echo "A imagem \"${cpimg}\" já existe em ${DK_REPO_DI_HOST}"
				else
					docker pull ${cpimg}
					sleep 3s
					docker images ${cpimg} --format "docker tag {{.Repository}}:{{.Tag}} ${DK_REPO_DI_HOST}:5000/{{.Repository}}:{{.Tag}}" | bash
					sleep 3s
					docker images ${cpimg} --format "docker push ${DK_REPO_DI_HOST}:5000/{{.Repository}}:{{.Tag}}" | bash
				fi
			done
		fi
	fi
done
for entry in "./src/services"/*
do
	if [ -d "$entry" ]; then
		if [ -f "${entry}/autoimport_images.conf" ]; then
			echo "Processing AutoimportImages: ${entry}/autoimport_images.conf"
			for cpimg in `cat $entry/autoimport_images.conf`; do
				echo "Image: ${cpimg}"
				imgname="${cpimg%:*}"
				imgtag="${cpimg##*:}"
				if [ "$imgname" = "$imgtag" ]; then
					imgtag=latest
				fi
				echo "    name: ${imgname}"
				echo "    tag: ${imgtag}"
				imginfo=$(curl -sS "http://${DK_REPO_DI_HOST}:5000/v2/${imgname}/tags/list")
				imgtagexists=$(echo $imginfo | jq -r 'select(has("tags")) | .tags | to_entries | .[] | select(.value == "'$imgtag'") | .value' | wc -l)
				if [ $imgtagexists == 1 ]; then
					echo "A imagem \"${cpimg}\" já existe em ${DK_REPO_DI_HOST}"
				else
					docker pull ${cpimg}
					sleep 3s
					docker images ${cpimg} --format "docker tag {{.Repository}}:{{.Tag}} ${DK_REPO_DI_HOST}:5000/{{.Repository}}:{{.Tag}}" | bash
					sleep 3s
					docker images ${cpimg} --format "docker push ${DK_REPO_DI_HOST}:5000/{{.Repository}}:{{.Tag}}" | bash
				fi
			done
		fi
	fi
done

### GRDK-MSG-BUILD
set +e
grdk_qbuild_img grdk-msg
ret_b=$?
set -e
if [ $ret_b = 1 ]; then
	echo "GRDK-MSG - RUN BUILD"
	cp ./src/services/msg/config.php ./vendor/grdk-core/services/msg/
	cp -R ./src/services/msg/gitlab-webhooks ./vendor/grdk-core/services/msg/
	docker build -t ${DK_REPO_DI_HOST}:5000/grdk-msg:latest -f ./vendor/grdk-core/services/msg/Dockerfile ./vendor/grdk-core/services/msg/
	echo "GRDK-MSG - PUSH -> REPO-DI"
	docker push ${DK_REPO_DI_HOST}:5000/grdk-msg:latest
else
	echo "GRDK-MSG - BUILD skiped"
fi

### GRDK-MSG-DEPLOY
SERVICES=$(docker service ls -q -f name=grdk-msg_web | wc -l)
if [[ "$SERVICES" -gt 0 ]]; then
	echo "GRDK-MSG - STACK DEPLOY skiped"
else
	echo "GRDK-MSG - RUN STACK DEPLOY"
	docker stack deploy --compose-file  ./vendor/grdk-core/services/msg/docker-stack.yml grdk-msg
fi

if [ "$DK_REPO_INST_GL" = "Y" ]; then

	### GRDK-REPO-RUNNER-1 (GITLAB)
	DK_REPO_RUNNER_CID=$(docker container ls -q -f name=grdk-repo_runner-1)
	if [ `docker exec -it $DK_REPO_RUNNER_CID cat /etc/gitlab-runner/config.toml | grep -c 'grdk-repo-runner-1'` != "0" ]; then
		echo "GRDK-REPO-RUNNER-1 - OK"
	else
		echo "GRDK-REPO-RUNNER-1 - REGISTER"
		read -p "Informe o Runner registration token: " DK_REPO_RUNNER_TK
		docker exec -it $DK_REPO_RUNNER_CID /usr/bin/gitlab-runner register \
			--non-interactive \
			--description "grdk-repo-runner-1" \
			--url "http://${DK_REPO_HOST}:8000/" \
			--registration-token "${DK_REPO_RUNNER_TK}" \
			--executor "docker" \
			--docker-image docker:latest \
			--docker-privileged \
			--docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
			--tag-list "grdk,grdkrr1" \
			--run-untagged \
			--locked="false"
	fi

	### GRDK-REPO-DOCKER (GITLAB)
	set +e
	grdk_qbuild_img grdk-repo-docker
	ret_b=$?
	set -e
	if [ $ret_b = 1 ]; then
		echo "GRDK-REPO-DOCKER - RUN BUILD"
		grdk_replace_all_vars ./vendor/grdk-core/services/repo/docker/Dockerfile ./vendor/grdk-core/services/repo/docker/_Dockerfile
		docker build -t ${DK_REPO_DI_HOST}:5000/grdk-repo-docker:latest -f ./vendor/grdk-core/services/repo/docker/_Dockerfile ./vendor/grdk-core/services/repo/docker/
		echo "GRDK-REPO-DOCKER - PUSH -> REPO-DI"
		docker push ${DK_REPO_DI_HOST}:5000/grdk-repo-docker:latest
	else
		echo "GRDK-REPO-DOCKER - BUILD skiped"
	fi

	### GRDK-REPO-DIND (GITLAB)
	set +e
	grdk_qbuild_img grdk-repo-dind
	ret_b=$?
	set -e
	if [ $ret_b = 1 ]; then
		echo "GRDK-REPO-DIND - RUN BUILD"
		grdk_replace_all_vars ./vendor/grdk-core/services/repo/dind/Dockerfile ./vendor/grdk-core/services/repo/dind/_Dockerfile
		docker build -t ${DK_REPO_DI_HOST}:5000/grdk-repo-dind:latest -f ./vendor/grdk-core/services/repo/dind/_Dockerfile ./vendor/grdk-core/services/repo/dind/
		echo "GRDK-REPO-DIND - PUSH -> REPO-DI"
		docker push ${DK_REPO_DI_HOST}:5000/grdk-repo-dind:latest
	else
		echo "GRDK-REPO-DIND - BUILD skiped"
	fi

fi

### GRDK-LOGGER (GRAYLOG)
SERVICES=$(docker service ls -q -f name=grdk-logger_server | wc -l)
if [[ "$SERVICES" -gt 0 ]]; then
    echo "GRDK-LOGGER - STACK DEPLOY skiped"
else
    echo "TODO TODO TODO - GRDK-LOGGER - RUN STACK DEPLOY"
    echo "INICIAR LOGGER MANUALMENTE COM docker-compose up -d no 239"
#    docker stack deploy --compose-file ./logger/docker-stack.yml grdk-logger
fi

### PAUSA
echo "Aguardando..."
sleep 5s

### GRDK-PROXY-BUILD (NGINX)
set +e
grdk_qbuild_img grdk-proxy
ret_b=$?
set -e
if [ $ret_b = 1 ]; then
	echo "GRDK-PROXY - RUN BUILD"
	cp -r ./vendor/grdk-core/services/proxy/* ./build/services/proxy/
	cp ./src/services/proxy/hosts.conf ./build/services/proxy/
	cp ./src/services/proxy/e_* ./build/services/proxy/
	docker build -t ${DK_REPO_DI_HOST}:5000/grdk-proxy:latest ./build/services/proxy/
	echo "GRDK-PROXY - PUSH -> REPO-DI"
	docker push ${DK_REPO_DI_HOST}:5000/grdk-proxy:latest
else
	echo "GRDK-PROXY - BUILD skiped"
fi

### GRDK-PROXY-DEPLOY (NGINX)
if [ ! "$(docker ps -q -f name=grdk-proxy)" ]; then
	if [ "$(docker ps -aq -f status=exited -f name=grdk-proxy)" ]; then
		echo "GRDK-PROXY - START"
		docker start grdk-proxy
	else
		echo "GRDK-PROXY - UP"
		docker-compose -f ./build/services/proxy/_docker-compose.yml up -d
		sleep 5s
		echo "GRDK-PROXY - start-servers.sh"
		docker exec -it grdk-proxy start-servers.sh
	fi
else
	echo "GRDK-PROXY - START/UP skiped"
fi

### GRDK-BACKUP
if [ "$DK_BK_INST" = "Y" ]; then
	### BUILD
	set +e
	grdk_qbuild_img grdk-backup
	ret_b=$?
	set -e
	if [ $ret_b = 1 ]; then
		echo "GRDK-BACKUP - RUN BUILD"
		cp ./src/services/backup/dblist.conf ./vendor/grdk-core/services/backup/scripts/
		docker build -t ${DK_REPO_DI_HOST}:5000/grdk-backup:latest -f ./vendor/grdk-core/services/backup/Dockerfile ./vendor/grdk-core/services/backup/
		echo "GRDK-BACKUP - PUSH -> REPO-DI"
		docker push ${DK_REPO_DI_HOST}:5000/grdk-backup:latest
	else
		echo "GRDK-BACKUP - BUILD skiped"
	fi
	### DEPLOY
	SERVICES=$(docker service ls -q -f name=grdk-backup_cron | wc -l)
	if [[ "$SERVICES" -gt 0 ]]; then
		echo "GRDK-BACKUP - STACK DEPLOY skiped"
	else
		echo "GRDK-BACKUP - RUN STACK DEPLOY"
		docker stack deploy --compose-file  ./vendor/grdk-core/services/backup/docker-stack.yml grdk-backup
	fi
fi

### GRDK-MONITOR-BUILD
set +e
grdk_qbuild_img grdk-node-exporter
ret_b=$?
set -e
if [ $ret_b = 1 ]; then
	echo "GRDK-MONITOR - RUN BUILD"
	docker build -t ${DK_REPO_DI_HOST}:5000/grdk-node-exporter:latest -f ./vendor/grdk-core/services/monitor/node-exporter/Dockerfile ./vendor/grdk-core/services/monitor/node-exporter/
	echo "GRDK-MONITOR - PUSH -> REPO-DI"
	docker push ${DK_REPO_DI_HOST}:5000/grdk-node-exporter:latest
else
	echo "GRDK-MONITOR - BUILD skiped"
fi

### GRDK-MONITOR-DEPLOY
SERVICES=$(docker service ls -q -f name=grdk-monitor_prometheus | wc -l)
if [[ "$SERVICES" -gt 0 ]]; then
	echo "GRDK-MONITOR - STACK DEPLOY skiped"
else
	echo "GRDK-MONITOR - RUN STACK DEPLOY"
	docker stack deploy --compose-file  ./vendor/grdk-core/services/monitor/docker-stack.yml grdk-monitor
fi

echo "STEP2 - END"
