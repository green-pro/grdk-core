#!/bin/bash
set -e

curr_dir="$(pwd)"

echo "Install for Docker \"MANAGER\" or \"WORKER\"? [M|w]"
read type_install

### STARTUP SCRIPT
if [ "$type_install" = "M" ]; then
	echo "[SERVER] - Informe o IP do servidor:"
	read server_ip
	echo "[SERVER] - Instalar NFS SERVER neste servidor? [Y|n]"
	read server_install_nfs
	echo "[LOGGER] - Informe o host do servidor de log:"
	read logger_host
	echo "[REPO] - Informe o host do repositório GitLab:"
	read repo_host
	echo "[REPO] - Informe o host do servidor NFS:"
	read repo_nfs_host
	if [ "${server_install_nfs}" = "Y" ]; then
		repo_nfs_path=/mnt/storage-1/grdk-repo
	else
		echo "[REPO] - Informe o diretório do servidor NFS:"
		read repo_nfs_path
	fi
	echo "[REPO-DI] - Informe o host do repositório de imagens Docker:"
	read repo_di_host
	echo "[MSG] - Informe o token para GitLab WebHooks:"
	read msg_gitlab_wh_tk

	unset DK_INSTALL_PATH
	unset DK_SERVER_NODE_ROLE
	unset DK_SERVER_IP
	unset DK_SERVER_INST_NFS
	unset DK_LOGGER_HOST
	unset DK_REPO_HOST
	unset DK_REPO_NFS_HOST
	unset DK_REPO_NFS_PATH
	unset DK_REPO_DI_HOST
	unset DK_MSG_GITLAB_WH_TK

	cat > /etc/environment << EOF
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
DK_INSTALL_PATH="${curr_dir}"
DK_SERVER_NODE_ROLE="manager"
DK_SERVER_IP="${server_ip}"
DK_SERVER_INST_NFS="${server_install_nfs}"
DK_LOGGER_HOST="${logger_host}"
DK_REPO_HOST="${repo_host}"
DK_REPO_NFS_HOST="${repo_nfs_host}"
DK_REPO_NFS_PATH="${repo_nfs_path}"
DK_REPO_DI_HOST="${repo_di_host}"
DK_MSG_GITLAB_WH_TK="${msg_gitlab_wh_tk}"
EOF
	#for line in $( cat /etc/environment ) ; do export $line ; done
	#for line in $( cat /etc/environment ) ; do set $line ; done

	cat > ./environment.sh << EOF
#!/bin/bash
export DK_INSTALL_PATH="${curr_dir}"
export DK_SERVER_NODE_ROLE="manager"
export DK_SERVER_IP="${server_ip}"
export DK_SERVER_INST_NFS="${server_install_nfs}"
export DK_LOGGER_HOST="${logger_host}"
export DK_REPO_HOST="${repo_host}"
export DK_REPO_NFS_HOST="${repo_nfs_host}"
export DK_REPO_NFS_PATH="${repo_nfs_path}"
export DK_REPO_DI_HOST="${repo_di_host}"
export DK_MSG_GITLAB_WH_TK="${msg_gitlab_wh_tk}"
EOF
	source ./environment.sh

	echo 'DK_INSTALL_PATH: '$DK_INSTALL_PATH
	echo 'DK_SERVER_NODE_ROLE: '$DK_SERVER_NODE_ROLE
	echo 'DK_SERVER_IP: '$DK_SERVER_IP
	echo 'DK_SERVER_INST_NFS: '$DK_SERVER_INST_NFS
	echo 'DK_LOGGER_HOST: '$DK_LOGGER_HOST
	echo 'DK_REPO_HOST: '$DK_REPO_HOST
	echo 'DK_REPO_NFS_HOST: '$DK_REPO_NFS_HOST
	echo 'DK_REPO_NFS_PATH: '$DK_REPO_NFS_PATH
	echo 'DK_REPO_DI_HOST: '$DK_REPO_DI_HOST
	echo 'DK_MSG_GITLAB_WH_TK: '$DK_MSG_GITLAB_WH_TK
	read -p "Continuar? [Y|n] " answer
	if [ $answer != "Y" ]; then
		exit 1
	fi
	source ./vendor/grdk-core/grdk-install-manager.sh
elif [ "$type_install" = "w" ]; then
	echo "[SERVER] - Informe o IP do servidor:"
	read server_ip
	echo "[REPO] - Informe o host do repositório GitLab:"
	read repo_host
	echo "[REPO-DI] - Informe o host do repositório de imagens Docker:"
	read repo_di_host
	echo "[SWARM] - Informe o IP do servidor MANAGER:"
	read swarm_ip
	echo "[SWARM] - Informe o token:"
	read swarm_token

	unset DK_INSTALL_PATH
	unset DK_SERVER_NODE_ROLE
	unset DK_SERVER_IP
	unset DK_REPO_HOST
	unset DK_REPO_DI_HOST
	unset DK_SWARM_IP
	unset DK_SWARM_TOKEN

	cat > /etc/environment << EOF
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
DK_INSTALL_PATH="${curr_dir}"
DK_SERVER_NODE_ROLE="worker"
DK_SERVER_IP="${server_ip}"
DK_REPO_HOST="${repo_host}"
DK_REPO_DI_HOST="${repo_di_host}"
DK_SWARM_IP="${swarm_ip}"
DK_SWARM_TOKEN="${swarm_token}"
EOF
	#for line in $( cat /etc/environment ) ; do export $line ; done
	#for line in $( cat /etc/environment ) ; do set $line ; done

	cat > ./environment.sh << EOF
#!/bin/bash
export DK_INSTALL_PATH="${curr_dir}"
export DK_SERVER_NODE_ROLE="worker"
export DK_SERVER_IP="${server_ip}"
export DK_REPO_HOST="${repo_host}"
export DK_REPO_DI_HOST="${repo_di_host}"
export DK_SWARM_IP="${swarm_ip}"
export DK_SWARM_TOKEN="${swarm_token}"
EOF
	source ./environment.sh

	echo 'DK_INSTALL_PATH: '$DK_INSTALL_PATH
	echo 'DK_SERVER_NODE_ROLE: '$DK_SERVER_NODE_ROLE
	echo 'DK_SERVER_IP: '$DK_SERVER_IP
	echo 'DK_REPO_HOST: '$DK_REPO_HOST
	echo 'DK_REPO_DI_HOST: '$DK_REPO_DI_HOST
	echo 'DK_SWARM_IP: '$DK_SWARM_IP
	echo 'DK_SWARM_TOKEN: '$DK_SWARM_TOKEN
	read -p "Continuar? [Y|n] " answer
	if [ $answer != "Y" ]; then
		exit 1
	fi
	source ./vendor/grdk-core/grdk-install-worker.sh
else
	echo "Nothing selected"
fi
