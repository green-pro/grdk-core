#!/bin/bash
set -e

### INSTALL PKG APT-GET
if [ "${DK_SERVER_INST_NFS}" = "Y" ]; then
	apt-get update && apt-get install -y nfs-kernel-server nfs-common unzip libconfig-yaml-perl libjson-xs-perl jq
else
	apt-get update && apt-get install -y nfs-common unzip libconfig-yaml-perl libjson-xs-perl jq
fi

### CALLBACK PRE INSTALL
for entry in "./vendor/grdk-core/services"/*
do
	if [ -d "$entry" ]; then
		if [ -f "${entry}/install_pre.sh" ]; then
			source "${entry}/install_pre.sh"
		fi
	fi
done
for entry in "./src/services"/*
do
	if [ -d "$entry" ]; then
		if [ -f "${entry}/install_pre.sh" ]; then
			source "${entry}/install_pre.sh"
		fi
	fi
done

### NFS SERVER
if [ "${DK_SERVER_INST_NFS}" = "Y" ]; then
	mkdir -p /mnt/storage-1/teste
	chown -R nobody:nogroup /mnt/storage-1
	echo "/mnt/storage-1/teste *(rw,sync,no_root_squash,no_subtree_check,insecure)" > /etc/exports
	for entry in "./vendor/grdk-core/services"/*
	do
		if [ -d "$entry" ]; then
			if [ -f "${entry}/nfs_exports.conf" ]; then
				cat "${entry}/nfs_exports.conf" >> /etc/exports
			fi
		fi
	done
	for entry in "./src/services"/*
	do
		if [ -d "$entry" ]; then
			if [ -f "${entry}/nfs_exports.conf" ]; then
				cat "${entry}/nfs_exports.conf" >> /etc/exports
			fi
		fi
	done
fi

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
	curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
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

if [ "${DK_SERVER_INST_NFS}" = "Y" ]; then
	service nfs-kernel-server restart
	echo "NFS restarted"
fi

### SWARM INIT
set +e; docker node ls 2> /dev/null | grep "Leader"
if [ $? -ne 0 ]; then
	#docker swarm init > /dev/null 2>&1
	docker swarm init --advertise-addr ${DK_SERVER_IP}
	echo "SWARM INIT OK"
fi
set -e
SWARM_TOKEN=$(docker swarm join-token -q worker)
echo "Use TOKEN ${SWARM_TOKEN}"
SWARM_MASTER_IP=$(docker info --format "{{.Swarm.NodeAddr}}")
echo "Swarm master IP: ${SWARM_MASTER_IP}"

### DOCKER-NODE-LABELS
#DK_SERVER_HOST=$(docker info --format "{{.Name}}")
CHECK_LABEL=$(docker node inspect -f '{{ .Spec.Labels }}' $DK_SERVER_HOST | grep 'grdkm:true' | wc -l)
if [[ "$CHECK_LABEL" -gt 0 ]]; then
	echo "DOCKER-NODE-LABELS - grdkm skiped"
else
	echo "DOCKER-NODE-LABELS - ADD grdkm"
	docker node update --label-add grdkm=true $DK_SERVER_HOST
fi
CHECK_LABEL=$(docker node inspect -f '{{ .Spec.Labels }}' $DK_SERVER_HOST | grep 'grdkw:true' | wc -l)
if [[ "$CHECK_LABEL" -gt 0 ]]; then
	echo "DOCKER-NODE-LABELS - grdkw already exists"
else
	read -p "Adicionar label Worker (grdkw) nesse Manager? (Y|n) [n] " answer
	answer=${answer:-n}
	if [ "$answer" = "Y" ]; then
		echo "DOCKER-NODE-LABELS - ADD grdkw"
		docker node update --label-add grdkw=true $DK_SERVER_HOST
	fi
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
