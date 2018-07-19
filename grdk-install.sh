#!/bin/bash
set -e

curr_dir="$(pwd)"

if [ ! -d "./build" ]; then
	mkdir -p ./build
fi

# DEFAULT ENV VARS
DK_INSTALL_TYPE="empty"
DK_INSTALL_PATH="${curr_dir}"
DK_BUILD_PATH="${curr_dir}/build"
DK_SERVER_NODE_ROLE="empty"
DK_SERVER_IP="192.168.0.1"
DK_SERVER_INST_NFS="Y"
DK_LOGGER_HOST="logger.domain"
DK_REPO_HOST="repo.domain"
DK_REPO_NFS_HOST="storage-1.domain"
DK_REPO_NFS_PATH="/mnt/storage-1/grdk-repo"
DK_REPO_DI_HOST="repo-di.domain"
DK_MSG_HOST="msg.domain"
DK_MSG_GITLAB_WH_TK="secret"
DK_SWARM_IP="192.168.0.1"
DK_SWARM_TOKEN="secret"

if [ -f "./environment.sh" ]; then
	source ./environment.sh
fi

read -p "Install Docker \"MANAGER\" or \"WORKER\"? (M/w) " -e answer
DK_INSTALL_TYPE=${answer:-${DK_INSTALL_TYPE}}
if [ "$DK_INSTALL_TYPE" = "M" ]; then
	DK_SERVER_NODE_ROLE="manager"
elif [ "$DK_INSTALL_TYPE" = "w" ]; then
	DK_SERVER_NODE_ROLE="worker"
else
	echo "Nothing selected: \"M\" for DOCKER MANAGER or \"w\" for DOCKER WORKER"
	exit 1
fi

read -p "[SERVER] - Informe o IP do servidor: [${DK_SERVER_IP}] " -e answer
DK_SERVER_IP=${answer:-${DK_SERVER_IP}}

### STARTUP SCRIPT
if [ "$DK_INSTALL_TYPE" = "M" ]; then

	read -p "[SERVER] - Instalar NFS SERVER neste servidor? (Y/n) [${DK_SERVER_INST_NFS}] " -e answer
	DK_SERVER_INST_NFS=${answer:-${DK_SERVER_INST_NFS}}
	read -p "[LOGGER] - Informe o host do servidor de log: [${DK_LOGGER_HOST}] " -e answer
	DK_LOGGER_HOST=${answer:-${DK_LOGGER_HOST}}
	read -p "[REPO] - Informe o host do repositório GitLab: [${DK_REPO_HOST}] " -e answer
	DK_REPO_HOST=${answer:-${DK_REPO_HOST}}
	read -p "[REPO] - Informe o host do servidor NFS: [${DK_REPO_NFS_HOST}] " -e answer
	DK_REPO_NFS_HOST=${answer:-${DK_REPO_NFS_HOST}}
	read -p "[REPO] - Informe o diretório do servidor NFS: [${DK_REPO_NFS_PATH}] " -e answer
	DK_REPO_NFS_PATH=${answer:-${DK_REPO_NFS_PATH}}
	read -p "[REPO-DI] - Informe o host do repositório de imagens Docker: [${DK_REPO_DI_HOST}] " -e answer
	DK_REPO_DI_HOST=${answer:-${DK_REPO_DI_HOST}}
	read -p "[MSG] - Informe o host do servidor de mensagens: [${DK_MSG_HOST}] " -e answer
	DK_MSG_HOST=${answer:-${DK_MSG_HOST}}
	read -p "[MSG] - Informe o token para GitLab WebHooks: [${DK_MSG_GITLAB_WH_TK}] " -e answer
	DK_MSG_GITLAB_WH_TK=${answer:-${DK_MSG_GITLAB_WH_TK}}

	cat > ./environment.sh << EOF
#!/bin/bash
export DK_INSTALL_PATH="${DK_INSTALL_PATH}"
export DK_BUILD_PATH="${DK_BUILD_PATH}"
export DK_SERVER_NODE_ROLE="${DK_SERVER_NODE_ROLE}"
export DK_SERVER_IP="${DK_SERVER_IP}"
export DK_SERVER_INST_NFS="${DK_SERVER_INST_NFS}"
export DK_LOGGER_HOST="${DK_LOGGER_HOST}"
export DK_REPO_HOST="${DK_REPO_HOST}"
export DK_REPO_NFS_HOST="${DK_REPO_NFS_HOST}"
export DK_REPO_NFS_PATH="${DK_REPO_NFS_PATH}"
export DK_REPO_DI_HOST="${DK_REPO_DI_HOST}"
export DK_MSG_HOST="${DK_MSG_HOST}"
export DK_MSG_GITLAB_WH_TK="${DK_MSG_GITLAB_WH_TK}"
EOF

elif [ "$DK_INSTALL_TYPE" = "w" ]; then

	read -p "[REPO] - Informe o host do repositório GitLab: [${DK_REPO_HOST}] " -e answer
	DK_REPO_HOST=${answer:-${DK_REPO_HOST}}
	read -p "[REPO-DI] - Informe o host do repositório de imagens Docker: [${DK_REPO_DI_HOST}] " -e answer
	DK_REPO_DI_HOST=${answer:-${DK_REPO_DI_HOST}}
	read -p "[SWARM] - Informe o IP do servidor MANAGER: [${DK_SWARM_IP}] " -e answer
	DK_SWARM_IP=${answer:-${DK_SWARM_IP}}
	read -p "[SWARM] - Informe o token: [${DK_SWARM_TOKEN}] " -e answer
	DK_SWARM_TOKEN=${answer:-${DK_SWARM_TOKEN}}

	cat > ./environment.sh << EOF
#!/bin/bash
export DK_INSTALL_PATH="${DK_INSTALL_PATH}"
export DK_BUILD_PATH="${DK_BUILD_PATH}"
export DK_SERVER_NODE_ROLE="${DK_SERVER_NODE_ROLE}"
export DK_SERVER_IP="${DK_SERVER_IP}"
export DK_REPO_HOST="${DK_REPO_HOST}"
export DK_REPO_DI_HOST="${DK_REPO_DI_HOST}"
export DK_SWARM_IP="${DK_SWARM_IP}"
export DK_SWARM_TOKEN="${DK_SWARM_TOKEN}"
EOF

fi

if [ ! -f "./environment.sh" ]; then
	echo "ERROR - File \"environment.sh\" not found"
	exit 1
fi

source ./environment.sh

sed '/^DK_/ d' < /etc/environment > $DK_BUILD_PATH/environment
sed -n -e '/^export/ p' < ./environment.sh | awk '{print $2}' >> $DK_BUILD_PATH/environment
cp $DK_BUILD_PATH/environment /etc/environment

echo ""
echo "###"
echo "### Variáveis definidas:"
echo "###"
echo ""
sed -n -e '/^export/ p' < ./environment.sh | awk '{print $2}'
echo ""

read -p "Continuar? (Y|n) [n] " answer
answer=${answer:-n}
if [ "$answer" != "Y" ]; then
	echo "Saindo..."
	exit 1
fi

if [ "$DK_INSTALL_TYPE" = "M" ]; then
	source ./vendor/grdk-core/grdk-install-manager.sh
elif [ "$DK_INSTALL_TYPE" = "w" ]; then
	source ./vendor/grdk-core/grdk-install-worker.sh
fi
