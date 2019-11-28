#!/bin/bash
set -e

### MANAGER
if [ "${DK_SERVER_NODE_ROLE}" = "manager" ]; then

	### STORAGE LOCAL
	mkdir -p /mnt/storage-local/grdk-proxy
	mkdir -p /mnt/storage-local/grdk-proxy/certboot
	mkdir -p /mnt/storage-local/grdk-proxy/certboot/etc
	mkdir -p /mnt/storage-local/grdk-proxy/certboot/lib
	mkdir -p /mnt/storage-local/grdk-proxy/certboot/www
	mkdir -p /mnt/storage-local/grdk-proxy/certboot/www/.well-known/acme-challenge

fi

### ALL
