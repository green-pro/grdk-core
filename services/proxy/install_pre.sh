#!/bin/bash
set -e

### MANAGER
if [ "${DK_SERVER_NODE_ROLE}" = "manager" ]; then

	### STORAGE LOCAL
	if [ -d "/mnt/storage-local/grdk-proxy" ]; then
		mkdir -p /mnt/storage-local/grdk-proxy/certboot
		mkdir -p /mnt/storage-local/grdk-proxy/certboot/etc
		mkdir -p /mnt/storage-local/grdk-proxy/certboot/lib
		mkdir -p /mnt/storage-local/grdk-proxy/certboot/www
		mkdir -p /mnt/storage-local/grdk-proxy/certboot/www/.well-known/acme-challenge
	else
		echo "New dir /mnt/storage-local/grdk-proxy"
		mkdir -p /mnt/storage-local/grdk-proxy
		mkdir -p /mnt/storage-local/grdk-proxy/certboot
		mkdir -p /mnt/storage-local/grdk-proxy/certboot/etc
		mkdir -p /mnt/storage-local/grdk-proxy/certboot/lib
		mkdir -p /mnt/storage-local/grdk-proxy/certboot/www
		mkdir -p /mnt/storage-local/grdk-proxy/certboot/www/.well-known/acme-challenge
		chown -R root:root /mnt/storage-local/grdk-proxy
	fi

fi

### ALL
