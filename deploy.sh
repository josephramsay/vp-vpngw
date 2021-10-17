#!/bin/bash

WGPK=$(wg genkey | base64)

helm install vp-vpngw . \
    --set data.privatekey=$WGPK \
    --debug

#sudo systemctl enable --now systemd-resolved
