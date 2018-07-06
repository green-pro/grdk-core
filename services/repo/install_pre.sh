#!/bin/bash
set -e

### MANAGER
if [ "${DK_SERVER_NODE_ROLE}" = "manager" ]; then

	### STORAGE NFS
	if [ "${DK_SERVER_INST_NFS}" = "Y" ]; then
		mkdir -p /mnt/storage-1/grdk-repo
		mkdir -p /mnt/storage-1/grdk-repo/glconf
		mkdir -p /mnt/storage-1/grdk-repo/gllog
		mkdir -p /mnt/storage-1/grdk-repo/gldata
		mkdir -p /mnt/storage-1/grdk-repo/glr1conf
		mkdir -p /mnt/storage-1/grdk-repo/didata
		chown -R nobody:nogroup /mnt/storage-1/grdk-repo
	fi

fi

### ALL
