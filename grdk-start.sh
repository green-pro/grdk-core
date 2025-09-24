#!/bin/bash

source ./environment.sh
source ./vendor/grdk-core/lib/include-functions.sh

if [ "${DK_SERVER_NODE_ROLE}" = "manager" ]; then
	echo "NODE MANAGER - OK"
else
	echo "NODE MANAGER - FAIL - Run only manager node"
	exit 1
fi

if [ ! -d "${DK_INSTALL_PATH}/build" ]; then
	mkdir -p $DK_INSTALL_PATH/build
fi
rm -Rf $DK_INSTALL_PATH/build
mkdir -p $DK_INSTALL_PATH/build

if [ ! -d "${DK_INSTALL_PATH}/tmp" ]; then
	mkdir -p $DK_INSTALL_PATH/tmp
fi

### TODO
# check nodes
# check hosts e ping
# check internet

### PRE BUILD COMPOSER AND STACKS FILES
echo "PRE-BUILD YML FILES"
for entry in "./vendor/grdk-core/services"/*
do
	if [ -d "$entry" ]; then
		srv_build_path=$DK_BUILD_PATH/services/${entry##*/}
		mkdir -p $srv_build_path
		if [ -f "${entry}/docker-stack.yml" ]; then
			echo "Building: ${entry}/docker-stack.yml"
			grdk_replace_all_vars $entry/docker-stack.yml $srv_build_path/_docker-stack.yml
			grdk_yaml2json $srv_build_path/_docker-stack.yml $srv_build_path/_docker-stack.json
		fi
		if [ -f "${entry}/docker-compose.yml" ]; then
			echo "Building: ${entry}/docker-compose.yml"
			grdk_replace_all_vars $entry/docker-compose.yml $srv_build_path/_docker-compose.yml
			grdk_yaml2json $srv_build_path/_docker-compose.yml $srv_build_path/_docker-compose.json
		fi
	fi
done
for entry in "./src/services"/*
do
	if [ -d "$entry" ]; then
		srv_build_path=$DK_BUILD_PATH/services/${entry##*/}
		mkdir -p $srv_build_path
		if [ -f "${entry}/docker-stack.yml" ]; then
			echo "Building: ${entry}/docker-stack.yml"
			grdk_replace_all_vars $entry/docker-stack.yml $srv_build_path/_docker-stack.yml
			grdk_yaml2json $srv_build_path/_docker-stack.yml $srv_build_path/_docker-stack.json
		fi
		if [ -f "${entry}/docker-compose.yml" ]; then
			echo "Building: ${entry}/docker-compose.yml"
			grdk_replace_all_vars $entry/docker-compose.yml $srv_build_path/_docker-compose.yml
			grdk_yaml2json $srv_build_path/_docker-compose.yml $srv_build_path/_docker-compose.json
		fi
	fi
done

### CHECK NFS VOLUMES
read -p "Testar volumes NFS? (Y|n) [n] " answer
answer=${answer:-n}
if [ "$answer" = "Y" ]; then
	echo "CHECK NFS VOLUMES"
	for entry in "./build/services"/*
	do
		if [ -d "$entry" ]; then
			if [ -f "${entry}/_docker-stack.yml" ]; then
				grdk_check_volumes $entry/_docker-stack.yml
			fi
			if [ -f "${entry}/_docker-compose.yml" ]; then
				grdk_check_volumes $entry/_docker-compose.yml
			fi
		fi
	done
fi

source ./vendor/grdk-core/grdk-preload-images.sh

read -p "Confirma START-UP dos serviços L1? (Y|n) [n] " answer
answer=${answer:-n}
if [ "$answer" != "Y" ]; then
	exit 1
fi

source ./vendor/grdk-core/grdk-start-step1.sh

read -p "Continuar L2? (Y|n) [n] " answer
answer=${answer:-n}
if [ "$answer" != "Y" ]; then
	exit 1
fi

source ./vendor/grdk-core/grdk-start-step2.sh

read -p "Continuar L3? (Y|n) [n] " answer
answer=${answer:-n}
if [ "$answer" != "Y" ]; then
	exit 1
fi

source ./src/grdk-start.sh
