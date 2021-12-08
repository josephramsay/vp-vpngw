#!/bin/bash

TAG_NAME='josephramsay/tfbuild'
HOME_DIR='/Users/ramsayj/'

if [[ ! -z $1 && $1 == "b" ]]
then
    echo "building $1"
    docker build -t $TAG_NAME $HOME_DIR/git/vp-wgvpn/setup/
fi
echo "running"
docker run -it --platform linux/amd64 --mount src=$HOME_DIR,target=/root,type=bind $TAG_NAME