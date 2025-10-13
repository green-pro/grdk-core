#!/bin/bash
set -e

### INSTALL PKG APT-GET
apt-get update && apt-get install -y nfs-common unzip libconfig-yaml-perl libjson-xs-perl jq

### DOCKER-CE
if command_exists docker; then
	echo "Docker already installed"
	echo $(docker -v | cut -d ' ' -f3 | cut -d ',' -f1)
else
	curl -sSL https://get.docker.com | VERSION=$DK_DOCKER_VERSION sh
	echo "{\"dns\":[\"${DK_SERVER_DNS}\"],\"insecure-registries\":[\"${DK_REPO_DI_HOST}:5000\"]}" > /etc/docker/daemon.json
fi

### SERVICES UP
if [[ ! `ps ax | grep dockerd | grep -v grep` ]]; then
	service docker start
	sleep 10
	echo "Service Docker started"
else
	echo "Service Docker already started"
	read -p "Restart service Docker? (Y|n) [Y] " answer
	answer=${answer:-Y}
	if [ "$answer" = "Y" ]; then
		service docker restart
		sleep 10
		echo "Service Docker restarted"
	fi
fi

### SWARM JOIN
read -p "Docker Swarm Join? (Y|n) [Y] " answer
answer=${answer:-Y}
if [ "$answer" = "Y" ]; then
	docker swarm join --token ${DK_SWARM_TOKEN} ${DK_SWARM_IP}:2377
fi

### CALLBACK POST INSTALL
for entry in "./vendor/grdk-core/services"/*
do
	if [ -d "$entry" ]; then
		if [ -f "${entry}/install_post.sh" ]; then
			source "${entry}/install_post.sh"
		fi
	fi
done
for entry in "./src/services"/*
do
	if [ -d "$entry" ]; then
		if [ -f "${entry}/install_post.sh" ]; then
			source "${entry}/install_post.sh"
		fi
	fi
done

### GRDK BIN
if [ -f "/usr/local/bin/grdk" ]; then
	echo "Scripts bin grdk deleted"
	rm /usr/local/bin/grdk
fi

cmd="ln -s ${DK_INSTALL_PATH}/vendor/grdk-core/bin/grdk.sh /usr/local/bin/grdk"
echo $cmd
$cmd
cmd="chmod +x /usr/local/bin/grdk"
echo $cmd
$cmd

### CRON JOBS
grdk install cron
