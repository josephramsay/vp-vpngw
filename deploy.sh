#!/bin/bash

I=0

if [[ $2 != 'COMMIT' ]]; then
    echo Dry Run
    DD="--dry-run"
fi

CTX="arn:aws:eks:us-west-1:725561212619:cluster/vp-test"

kns () {
    if [[ ! -z "$1" ]] && [[ -z "$DD" ]]; then
    echo setting namespace to $1
	    kubectl config set-context --current --namespace=$1
    fi
    kubectl config view -o=json | jq '.contexts[].context.namespace'
}


install () {
    kns default

    WGPK=$(wg genkey | base64 | tee .private.key)

    helm install vp-vpngw . \
        --set data.privatekey=$WGPK \
        --debug $DD

    kns wireguard

    export WGP=$(kubectl get pods -o=json | jq -r "[.items[].metadata.name][$I]")
}

upgrade () {
    kns default

    WGPK=$(cat .private.key)

    helm upgrade --install vp-vpngw . \
        --set data.privatekey=$WGPK \
        --debug $DD

    kns wireguard
    export WGP=$(kubectl get pods -o=json | jq -r "[.items[].metadata.name][$I]")
}

uninstall () {
    kns default

    helm uninstall vp-vpngw
}

if [[ $1 == 'install' ]]; then
    install;
elif [[ $1 == 'upgrade' ]]; then
    upgrade;
elif [[ $1 == 'uninstall' ]]; then
    uninstall;
fi
