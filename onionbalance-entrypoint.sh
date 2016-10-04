#!/bin/bash
set -xe

TIMEOUT=${TIMEOUT:-500}

cd /data
mkdir -p onionbalance tor

if [ -d import-key ]; then
    # import
    cp import-key/* onionbalance/
    cp import-conf/* onionbalance/
else
    # generate new key and config
    (cd /tmp
    /usr/bin/onionbalance-config -n 0
    mv config/master/*key config/master/config.yaml /data/onionbalance/)
fi

# To be able to control tor that is running in another container,
# the cookie file is needed.
# /data/shared is an emptyDir volume mounted by both containers (tor and onionbalance)
wait_and_copy_cookie() {
    while true; do
        if [ -e /data/shared/control_auth_cookie ]; then
            cp /data/shared/control_auth_cookie /data/tor/
            break
        fi
        sleep 5
    done
}

if [ -d /data/shared ]; then
    export -f wait_and_copy_cookie
    timeout -t ${TIMEOUT} bash -c wait_and_copy_cookie
fi

cd /data/onionbalance
/usr/bin/onionbalance -c config.yaml
