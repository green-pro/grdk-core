#!/bin/bash

source ./environment.sh
source ./vendor/grdk-core/lib/include-functions.sh

### TODO
# check nodes
# check hosts e ping
# check nfs
# check internet

source ./vendor/grdk-core/grdk-preload-images.sh

read -p "Confirma START UP dos serviços L1 ? [Y|n] " answer
if [ $answer != "Y" ]; then
	exit 1
fi

source ./vendor/grdk-core/grdk-start-step1.sh

read -p "Continuar L2 ? [Y|n] " answer
if [ $answer != "Y" ]; then
	exit 1
fi

source ./vendor/grdk-core/grdk-start-step2.sh

read -p "Continuar L3 ? [Y|n] " answer
if [ $answer != "Y" ]; then
	exit 1
fi

source ./src/grdk-start.sh
