#!/bin/bash
set -e

### MANAGER
if [ "${DK_SERVER_NODE_ROLE}" = "manager" ]; then

	### STORAGE NFS
	if [ "${DK_SERVER_INST_NFS}" = "Y" ]; then
		mkdir -p /mnt/storage-1/grdk-proxy
		mkdir -p /mnt/storage-1/grdk-proxy/certboot
		mkdir -p /mnt/storage-1/grdk-proxy/certboot/etc
		mkdir -p /mnt/storage-1/grdk-proxy/certboot/lib
		mkdir -p /mnt/storage-1/grdk-proxy/certboot/www
		mkdir -p /mnt/storage-1/grdk-proxy/certboot/www/.well-known/acme-challenge
	fi

fi

### ALL
