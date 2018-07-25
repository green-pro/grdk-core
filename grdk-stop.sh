#!/bin/bash

source ./environment.sh

read -p "Confirma STOP dos serviços L3? (Y|n) [n] " answer
answer=${answer:-n}
if [ "$answer" != "Y" ]; then
	exit 1
fi

source ./src/grdk-stop.sh

read -p "Continuar L2? (Y|n) [n] " answer
answer=${answer:-n}
if [ "$answer" != "Y" ]; then
	exit 1
fi

source ./vendor/grdk-core/grdk-stop-step2.sh

read -p "Continuar L1? (Y|n) [n] " answer
answer=${answer:-n}
if [ "$answer" != "Y" ]; then
	exit 1
fi

source ./vendor/grdk-core/grdk-stop-step1.sh
