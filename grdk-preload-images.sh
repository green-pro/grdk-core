#!/bin/bash

ANS_DEFAULT="n"

### PRELOAD DOCKER IMAGES
echo "### PRELOAD DOCKER IMAGES"
echo "Searching..."
dimgs=()
for dfile in `find ./vendor/grdk-core/services -type f -name docker\-*.yml`
do
	for dimg in `cat $dfile | awk "/^[[:space:]]*image:[[:space:]]*\"[a-z\/\-]+:[a-z0-9\.\-]*\"$/{print}" | awk '/image:/{print $2}' | sed 's/"//g'`
	do
		n=${#dimgs[@]}
		echo "$(($n + 1)). ${dimg}"
		dimgs[$n]=$dimg
	done
done
read -p "Preload Docker images? (Y/n) [${ANS_DEFAULT}] " -e answer
answer=${answer:-${ANS_DEFAULT}}
if [ $answer = "Y" ]; then
	echo "Start downloading..."
	for dimg in "${dimgs[@]}"
	do
		docker image pull $dimg
	done
fi
