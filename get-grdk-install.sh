#!/bin/bash
set -e

curr_dir="$(pwd)"

### GIT - GRDK-INSTALL (SOURCES)
if [ -d "./grdk-install" ]; then
	if [ -d "./grdk-install/.git" ]; then
		echo "GIT - Clone grdk-install skiped"
		echo "GIT - Pull grdk-install"
		git -C ./grdk-install pull
	fi
else
	if [[ "$curr_dir" == *"/grdk-install" ]]; then
		if [ -d "./.git" ]; then
			echo "GIT - Clone grdk-install skiped"
			echo "GIT - Pull grdk-install"
			git pull
		fi
	else
		echo "GIT - Clone grdk-install"
		git clone https://github.com/nereysessa/grdk-install.git ./grdk-install
	fi
fi
if [ -d "./grdk-install" ]; then
	echo "Change dir grdk-install"
	cd grdk-install
fi

### EXECUTE SCRIPT
sh ./grdk-install.sh
