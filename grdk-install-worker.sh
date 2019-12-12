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

### DOCKER-COMPOSE
if command_exists docker-compose; then
	echo "Docker Composer already installed"
else
	curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
fi

### DOCKER-VOLUME-NETSHARE
if command_exists docker-volume-netshare; then
	echo "Docker Volume Netshare already installed"
else
	wget https://github.com/ContainX/docker-volume-netshare/releases/download/v0.34/docker-volume-netshare_0.34_amd64.deb
	dpkg -i docker-volume-netshare_0.34_amd64.deb
	rm docker-volume-netshare_0.34_amd64.deb
fi

### SERVICES UP
if [[ ! `ps ax | grep dockerd | grep -v grep` ]]; then
	service docker start
	sleep 10
	echo "Service Docker started"
else
	echo "Service Docker already started"
	read -p "Restart service Docker? (Y|n) [n] " answer
	answer=${answer:-n}
	if [ "$answer" = "Y" ]; then
		service docker restart
		sleep 10
		echo "Service Docker restarted"
	fi
fi

if [[ ! `ps ax | grep docker-volume-netshare | grep -v grep` ]]; then
	service docker-volume-netshare start
	sleep 10
	echo "Service Docker NetShare started"
else
	echo "Service Docker NetShare already started"
fi

if [[ `service --status-all | grep 'docker-volume-netshare'` ]]; then
	update-rc.d docker-volume-netshare defaults
	echo "Service Docker NetShare set autoload"
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
