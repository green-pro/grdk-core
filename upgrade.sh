#!/bin/bash
set -e

curl -LOk https://github.com/green-pro/grdk-core/archive/master.zip
unzip master.zip
rm ./master.zip
cp -r ./grdk-core-master/. .
rm -Rf ./grdk-core-master
