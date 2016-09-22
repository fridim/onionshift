#!/bin/bash
set -xe
cd /data

export SERVICE_NAME=${SERVICE_NAME:-"127.0.0.1"}
export SERVICE_PORT=${SERVICE_PORT:-"8080"}
export HS_PORT=${HS_PORT:-"80"}

# allow user to have persistent .onion
# they just have to put a key inside /data/import
if [ -d import ]; then
    mkdir -p tor/hidden_service
    chmod 700 tor tor/hidden_service

    if [ $(ls import/*|wc -l) != 1 ]; then
        echo >&2 "you must import only one key"
        exit 2
    fi

    cp import/* tor/hidden_service/private_key
fi

if [ ! -e /etc/tor/torrc ]; then
    envsubst < torrc.template > torrc
    /usr/bin/tor -f torrc
else
    /usr/bin/tor
fi
