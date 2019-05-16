#!/bin/bash

echo "STEP2 - START"

### CHECK REQUIREMENTS
set +e
grdk_containers_checkup grdk-repo_ 600 3
if [ $? = 1 ]; then
	echo "GRDK-REPO - OK"
else
	echo "GRDK-REPO - Not Found"
	exit 1
fi
set -e

### AUTOIMPORT IMAGES
echo "AUTOIMPORT IMAGES"
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
					docker images ${cpimg} --format "docker tag {{.Repository}}:{{.Tag}} ${DK_REPO_DI_HOST}:5000/{{.Repository}}:{{.Tag}} | docker push ${DK_REPO_DI_HOST}:5000/{{.Repository}}:{{.Tag}}" | bash
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

### GRDK-REPO-DIND (GITLAB)
set +e
grdk_qbuild_img grdk-repo-dind
ret_b=$?
set -e
if [ $ret_b = 1 ]; then
	echo "GRDK-REPO-DIND - RUN BUILD"
	sed -e "s#{{ DK_SERVER_NODE_ROLE }}#${DK_SERVER_NODE_ROLE}#g" \
		-e "s#{{ DK_SERVER_IP }}#${DK_SERVER_IP}#g" \
		-e "s#{{ DK_SERVER_INST_NFS }}#${DK_SERVER_INST_NFS}#g" \
		-e "s#{{ DK_LOGGER_HOST }}#${DK_LOGGER_HOST}#g" \
		-e "s#{{ DK_REPO_HOST }}#${DK_REPO_HOST}#g" \
		-e "s#{{ DK_REPO_NFS_HOST }}#${DK_REPO_NFS_HOST}#g" \
		-e "s#{{ DK_REPO_NFS_PATH }}#${DK_REPO_NFS_PATH}#g" \
		-e "s#{{ DK_REPO_DI_HOST }}#${DK_REPO_DI_HOST}#g" \
		< ./vendor/grdk-core/services/repo/dind/Dockerfile \
		> ./vendor/grdk-core/services/repo/dind/_Dockerfile
	docker build -t ${DK_REPO_DI_HOST}:5000/grdk-repo-dind:latest -f ./vendor/grdk-core/services/repo/dind/_Dockerfile ./vendor/grdk-core/services/repo/dind/
	echo "GRDK-REPO-DIND - PUSH -> REPO-DI"
	docker push ${DK_REPO_DI_HOST}:5000/grdk-repo-dind:latest
else
	echo "GRDK-REPO-DIND - BUILD skiped"
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
	cp ./src/services/proxy/hosts.conf ./vendor/grdk-core/services/proxy/
	cp ./src/services/proxy/e_* ./vendor/grdk-core/services/proxy/
	file_acme_config=./vendor/grdk-core/services/proxy/acme.conf
	if [ -f "$file_acme_config" ]; then
		for acme_host in `cat ./vendor/grdk-core/services/proxy/hosts.conf`; do
			echo "ACME CONF for ${acme_host}"
			cat >> $file_acme_config << EOF
#
# ${acme_host}
#
server {
    listen 80;
    server_name ${acme_host};
    include conf.d/acme-loc.inc;
}
EOF
		echo "O arquivo ${file_acme_config} foi configurado com ${acme_host}"
		done
	fi
	docker build -t ${DK_REPO_DI_HOST}:5000/grdk-proxy:latest ./vendor/grdk-core/services/proxy/
	echo "GRDK-PROXY - PUSH -> REPO-DI"
	docker push ${DK_REPO_DI_HOST}:5000/grdk-proxy:latest
else
	echo "GRDK-PROXY - BUILD skiped"
fi

### GRDK-PROXY-DEPLOY (NGINX) - NAO DEU CERTO, PRECISA USAR A REDE LOCAL - PROBLEMA DOS IPS COM SWARM
#SERVICES=$(docker service ls -q -f name=grdk-proxy_web | wc -l)
#if [[ "$SERVICES" -gt 0 ]]; then
#    echo "GRDK-PROXY - STACK DEPLOY skiped"
#else
#    echo "GRDK-PROXY - RUN STACK DEPLOY"
#    docker stack deploy --compose-file ./proxy/docker-stack.yml grdk-proxy
#fi

### GRDK-PROXY-DEPLOY (NGINX)
if [ ! "$(docker ps -q -f name=grdk-proxy)" ]; then
	if [ "$(docker ps -aq -f status=exited -f name=grdk-proxy)" ]; then
		echo "GRDK-PROXY - START"
		docker start grdk-proxy
	else
		echo "GRDK-PROXY - UP"
		sed -e "s#{{ DK_SERVER_NODE_ROLE }}#${DK_SERVER_NODE_ROLE}#g" \
			-e "s#{{ DK_SERVER_IP }}#${DK_SERVER_IP}#g" \
			-e "s#{{ DK_SERVER_INST_NFS }}#${DK_SERVER_INST_NFS}#g" \
			-e "s#{{ DK_LOGGER_HOST }}#${DK_LOGGER_HOST}#g" \
			-e "s#{{ DK_REPO_HOST }}#${DK_REPO_HOST}#g" \
			-e "s#{{ DK_REPO_NFS_HOST }}#${DK_REPO_NFS_HOST}#g" \
			-e "s#{{ DK_REPO_NFS_PATH }}#${DK_REPO_NFS_PATH}#g" \
			-e "s#{{ DK_REPO_DI_HOST }}#${DK_REPO_DI_HOST}#g" \
			< ./vendor/grdk-core/services/proxy/docker-compose.yml \
			> ./vendor/grdk-core/services/proxy/_docker-compose.yml
		#docker run --name grdk-proxy -p 80:80 -p 8080:8080 -d repo-di.grdk:5000/grdk-proxy:latest
		docker-compose -f ./vendor/grdk-core/services/proxy/_docker-compose.yml up -d
		sleep 5s
		docker exec -it grdk-proxy start-servers.sh
	fi
else
	echo "GRDK-PROXY - START/UP skiped"
fi

### GRDK-BACKUP-BUILD
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

### GRDK-BACKUP-DEPLOY
SERVICES=$(docker service ls -q -f name=grdk-backup_cron | wc -l)
if [[ "$SERVICES" -gt 0 ]]; then
	echo "GRDK-BACKUP - STACK DEPLOY skiped"
else
	echo "GRDK-BACKUP - RUN STACK DEPLOY"
	docker stack deploy --compose-file  ./vendor/grdk-core/services/backup/docker-stack.yml grdk-backup
fi

echo "STEP2 - END"
