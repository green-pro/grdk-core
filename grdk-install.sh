#!/bin/bash

source ./vendor/grdk-core/lib/include-functions.sh

set -e

curr_dir="$(pwd)"

if [ ! -d "./build" ]; then
	mkdir -p ./build
fi
rm -Rf ./build
mkdir -p ./build

if [ ! -d "./tmp" ]; then
	mkdir -p ./tmp
fi

# DEFAULT ENV VARS
DK_INSTALL_TYPE="empty"
DK_SERVER_NODE_ROLE="empty"
DK_SERVER_IP=$(hostname -i | awk '{print $1}')
DK_SERVER_HOST=$(hostname -s | awk '{print $1}')
DK_SERVER_DNS="192.168.0.1"
DK_SERVER_INST_NFS="Y"
DK_LOGGER_HOST="logger.domain"
DK_REPO_INST_GL="Y"
DK_REPO_HOST="repo.domain"
DK_REPO_NFS_HOST="storage-1.domain"
DK_REPO_NFS_PATH="/mnt/storage-1/grdk-repo"
DK_REPO_DI_HOST="repo-di.domain"
DK_MSG_HOST="msg.domain"
DK_MSG_GITLAB_WH_TK="secret"
DK_AWS_ACCESS_KEY_ID=""
DK_AWS_SECRET_ACCESS_KEY=""
DK_AWS_BUCKET=""
DK_SWARM_IP="192.168.0.1"
DK_SWARM_TOKEN="secret"

if [ -f "./environment.sh" ]; then
	source ./environment.sh
fi

# DEFINED ENV VARS
DK_VERSION=$(cat ./vendor/grdk-core/VERSION)
DK_DOCKER_VERSION="18.06.3"
DK_INSTALL_PATH="${curr_dir}"
DK_BUILD_PATH="${curr_dir}/build"

echo "[GRDK] - VERSION: ${DK_VERSION}"
echo "[GRDK] - DOCKER VERSION: ${DK_DOCKER_VERSION}"

if [ "$DK_SERVER_NODE_ROLE" = "manager" ]; then
	DK_INSTALL_TYPE="M"
elif [ "$DK_SERVER_NODE_ROLE" = "worker" ]; then
	DK_INSTALL_TYPE="w"
else
	read -p "[GRDK] - Install Docker \"M\" (MANAGER) or \"w\" (WORKER)? (M/w) " -e answer
	DK_INSTALL_TYPE=${answer:-${DK_INSTALL_TYPE}}
fi

if [ "$DK_INSTALL_TYPE" = "M" ]; then
	DK_SERVER_NODE_ROLE="manager"
elif [ "$DK_INSTALL_TYPE" = "w" ]; then
	DK_SERVER_NODE_ROLE="worker"
else
	echo "Nothing selected: \"M\" for DOCKER MANAGER or \"w\" for DOCKER WORKER"
	exit 1
fi

echo "[GRDK] - DOCKER NODE ROLE: ${DK_SERVER_NODE_ROLE}"

read -p "[SERVER] - Informe o IP local deste servidor: [${DK_SERVER_IP}] " -e answer
DK_SERVER_IP=${answer:-${DK_SERVER_IP}}
read -p "[SERVER] - Informe o HOST local deste servidor: [${DK_SERVER_HOST}] " -e answer
DK_SERVER_HOST=${answer:-${DK_SERVER_HOST}}
read -p "[SERVER] - Informe o IP do servidor DNS: [${DK_SERVER_DNS}] " -e answer
DK_SERVER_DNS=${answer:-${DK_SERVER_DNS}}

### STARTUP SCRIPT
if [ "$DK_INSTALL_TYPE" = "M" ]; then

	read -p "[SERVER] - Instalar NFS SERVER neste servidor? (Y/n) [${DK_SERVER_INST_NFS}] " -e answer
	DK_SERVER_INST_NFS=${answer:-${DK_SERVER_INST_NFS}}
	read -p "[LOGGER] - Informe o host do servidor de log: [${DK_LOGGER_HOST}] " -e answer
	DK_LOGGER_HOST=${answer:-${DK_LOGGER_HOST}}
	read -p "[REPO] - Utilizar GitLab? (Y/n) [${DK_REPO_INST_GL}] " -e answer
	DK_REPO_INST_GL=${answer:-${DK_REPO_INST_GL}}
	if [ "$DK_REPO_INST_GL" = "Y" ]; then
		read -p "[REPO] - Informe o host do repositório GitLab: [${DK_REPO_HOST}] " -e answer
		DK_REPO_HOST=${answer:-${DK_REPO_HOST}}
	fi
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
	read -p "[AWS] - Informe o AWS_ACCESS_KEY_ID: [${DK_AWS_ACCESS_KEY_ID}] " -e answer
	DK_AWS_ACCESS_KEY_ID=${answer:-${DK_AWS_ACCESS_KEY_ID}}
	read -p "[AWS] - Informe o AWS_SECRET_ACCESS_KEY: [${DK_AWS_SECRET_ACCESS_KEY}] " -e answer
	DK_AWS_SECRET_ACCESS_KEY=${answer:-${DK_AWS_SECRET_ACCESS_KEY}}
	read -p "[AWS] - Informe o AWS_BUCKET: [${DK_AWS_BUCKET}] " -e answer
	DK_AWS_BUCKET=${answer:-${DK_AWS_BUCKET}}

	cat > ./environment.sh << EOF
#!/bin/bash
export DK_VERSION="${DK_VERSION}"
export DK_DOCKER_VERSION="${DK_DOCKER_VERSION}"
export DK_INSTALL_PATH="${DK_INSTALL_PATH}"
export DK_BUILD_PATH="${DK_BUILD_PATH}"
export DK_SERVER_NODE_ROLE="${DK_SERVER_NODE_ROLE}"
export DK_SERVER_IP="${DK_SERVER_IP}"
export DK_SERVER_HOST="${DK_SERVER_HOST}"
export DK_SERVER_DNS="${DK_SERVER_DNS}"
export DK_SERVER_INST_NFS="${DK_SERVER_INST_NFS}"
export DK_LOGGER_HOST="${DK_LOGGER_HOST}"
export DK_REPO_INST_GL="${DK_REPO_INST_GL}"
export DK_REPO_HOST="${DK_REPO_HOST}"
export DK_REPO_NFS_HOST="${DK_REPO_NFS_HOST}"
export DK_REPO_NFS_PATH="${DK_REPO_NFS_PATH}"
export DK_REPO_DI_HOST="${DK_REPO_DI_HOST}"
export DK_MSG_HOST="${DK_MSG_HOST}"
export DK_MSG_GITLAB_WH_TK="${DK_MSG_GITLAB_WH_TK}"
export DK_AWS_ACCESS_KEY_ID="${DK_AWS_ACCESS_KEY_ID}"
export DK_AWS_SECRET_ACCESS_KEY="${DK_AWS_SECRET_ACCESS_KEY}"
export DK_AWS_BUCKET="${DK_AWS_BUCKET}"
EOF

elif [ "$DK_INSTALL_TYPE" = "w" ]; then

	read -p "[REPO] - Utilizar GitLab? (Y/n) [${DK_REPO_INST_GL}] " -e answer
	DK_REPO_INST_GL=${answer:-${DK_REPO_INST_GL}}
	if [ "$DK_REPO_INST_GL" = "Y" ]; then
		read -p "[REPO] - Informe o host do repositório GitLab: [${DK_REPO_HOST}] " -e answer
		DK_REPO_HOST=${answer:-${DK_REPO_HOST}}
	fi
	read -p "[REPO-DI] - Informe o host do repositório de imagens Docker: [${DK_REPO_DI_HOST}] " -e answer
	DK_REPO_DI_HOST=${answer:-${DK_REPO_DI_HOST}}
	read -p "[SWARM] - Informe o IP do servidor MANAGER: [${DK_SWARM_IP}] " -e answer
	DK_SWARM_IP=${answer:-${DK_SWARM_IP}}
	read -p "[SWARM] - Informe o token: [${DK_SWARM_TOKEN}] " -e answer
	DK_SWARM_TOKEN=${answer:-${DK_SWARM_TOKEN}}

	cat > ./environment.sh << EOF
#!/bin/bash
export DK_VERSION="${DK_VERSION}"
export DK_DOCKER_VERSION="${DK_DOCKER_VERSION}"
export DK_INSTALL_PATH="${DK_INSTALL_PATH}"
export DK_BUILD_PATH="${DK_BUILD_PATH}"
export DK_SERVER_NODE_ROLE="${DK_SERVER_NODE_ROLE}"
export DK_SERVER_IP="${DK_SERVER_IP}"
export DK_SERVER_HOST="${DK_SERVER_HOST}"
export DK_SERVER_DNS="${DK_SERVER_DNS}"
export DK_REPO_INST_GL="${DK_REPO_INST_GL}"
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
