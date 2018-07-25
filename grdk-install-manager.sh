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
curl -sSL https://get.docker.com | CHANNEL=stable sh
echo "{\"dns\":[\"${DK_SERVER_DNS}\"],\"insecure-registries\":[\"${DK_REPO_DI_HOST}:5000\"]}" > /etc/docker/daemon.json

### DOCKER-COMPOSE
curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

### DOCKER-VOLUME-NETSHARE
wget https://github.com/ContainX/docker-volume-netshare/releases/download/v0.34/docker-volume-netshare_0.34_amd64.deb
dpkg -i docker-volume-netshare_0.34_amd64.deb
rm docker-volume-netshare_0.34_amd64.deb

### SERVICES UP
if [[ ! `ps ax | grep dockerd | grep -v grep` ]]; then
	service docker start
	sleep 10
	echo "Service Docker started"
else
	service docker restart
	sleep 10
	echo "Service Docker restarted"
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

### OTHERS
cp ./vendor/grdk-core/scripts/grdk-cron-daily-cleanup /etc/cron.daily/
service cron restart
