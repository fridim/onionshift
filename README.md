# Tor on Openshift 3

![tor on openshift](tor_openshift.png)

This repository contains a Dockerfile for Tor images to be used on Openshift to easily expose an openshift service of your app on Tor and get a .onion URL in return to access it.

## cut the blabla, i just want to test it

To start a single ephemeral tor instance :

    oc new-app https://github.com/fridim/onionshift -e SERVICE_NAME=ruby-ex,SERVICE_PORT=8080

This will create everything (deployment config, buildconfig, ...) and pod(s) will have a simple torrc based on the template in the repository. It's dead simple, and if you want to add a more complex tor configuration, you can use configMap.

You should see the docker build and the final push to the registry. Then a pod onionshift--... should be running.

Tor will create a private\_key and hostname in the directory specify by <code>HiddenServiceDir</code>.

If you want to be able to reuse the same .onion address over and over across pod creations, you'll need to store it somewhere (mount secrets inside pods, or add persistent volume). But since we are going to use onionbalance, we don't really care about those tor pods, they can be considered ephemeral, as long as the one UP and running are populated correctly in <code>config.yaml</code> of onionbalance.

Check the logs :

    $ oc logs onionshift-7-buxlt
    + cd /data
    + export SERVICE_NAME=ruby-ex
    + SERVICE_NAME=ruby-ex
    + export SERVICE_PORT=8080
    + SERVICE_PORT=8080
    + export HS_PORT=80
    + HS_PORT=80
    + '[' '!' -e /etc/tor/torrc ']'
    + envsubst
    + /usr/bin/tor -f torrc
    Sep 29 13:05:40.101 [notice] Tor v0.2.8.7 running on Linux with Libevent 2.0.22-stable, OpenSSL 1.0.2j and Zlib 1.2.8.
    Sep 29 13:05:40.101 [notice] Tor can't help you if you use it wrong! Learn how to be safe at https://www.torproject.org/download/download#warning
    Sep 29 13:05:40.101 [notice] Read configuration file "/data/torrc".
    Sep 29 13:05:40.107 [notice] Wow!  I detected that you have 24 CPUs. I will not autodetect any more than 16, though.  If you want to configure more, set NumCPUs in your torrc
    Sep 29 13:05:40.107 [notice] Opening Socks listener on 127.0.0.1:9050
    Sep 29 13:05:40.000 [notice] Parsing GEOIP IPv4 file //share/tor/geoip.
    Sep 29 13:05:40.000 [notice] Parsing GEOIP IPv6 file //share/tor/geoip6.
    Sep 29 13:05:40.000 [notice] Bootstrapped 0%: Starting
    Sep 29 13:05:41.000 [notice] Bootstrapped 5%: Connecting to directory server
    Sep 29 13:05:41.000 [notice] Bootstrapped 10%: Finishing handshake with directory server
    Sep 29 13:05:41.000 [notice] Bootstrapped 15%: Establishing an encrypted directory connection
    Sep 29 13:05:41.000 [notice] Bootstrapped 20%: Asking for networkstatus consensus
    Sep 29 13:05:41.000 [notice] Bootstrapped 25%: Loading networkstatus consensus
    Sep 29 13:05:41.000 [notice] I learned some more directory information, but not enough to build a circuit: We have no usable consensus.
    Sep 29 13:05:41.000 [notice] Bootstrapped 40%: Loading authority key certs
    Sep 29 13:05:41.000 [notice] Bootstrapped 45%: Asking for relay descriptors
    Sep 29 13:05:41.000 [notice] I learned some more directory information, but not enough to build a circuit: We need more microdescriptors: we have 0/7187, and can only build 0% of likely paths. (We have 0% of guards bw, 0% of midpoint bw, and 0% of exit bw = 0% of path bw.)
    Sep 29 13:05:41.000 [notice] Bootstrapped 50%: Loading relay descriptors
    Sep 29 13:05:42.000 [notice] Bootstrapped 56%: Loading relay descriptors
    Sep 29 13:05:42.000 [notice] Bootstrapped 62%: Loading relay descriptors
    Sep 29 13:05:42.000 [notice] Bootstrapped 67%: Loading relay descriptors
    Sep 29 13:05:42.000 [notice] Bootstrapped 75%: Loading relay descriptors
    Sep 29 13:05:42.000 [notice] Bootstrapped 80%: Connecting to the Tor network
    Sep 29 13:05:42.000 [notice] Bootstrapped 90%: Establishing a Tor circuit
    Sep 29 13:05:43.000 [notice] Tor has successfully opened a circuit. Looks like client functionality is working.
    Sep 29 13:05:43.000 [notice] Bootstrapped 100%: Done

Grab the .onion address:

    $ oc exec onionshift-7-buxlt cat /data/tor/hidden_service/hostname
    siojz6ucairjccsu.onion

Test it in tor-browser :)

![reachable .onion](https://lut.im/73gqgqMrYC/wzxwOJThzR0Jw1WQ)

### Persistent .onion
If you don't want to setup onionbalance and still want to have persistent .onion address, you'll need to keep the same private\_key of your hidden service accross pod creations.

The first time you run tor it creates hidden_service directory and generates private\_key.

Backup the private_key and hostname using rsync:


    fridim@master ~]$ mkdir hidden_service
    [fridim@master ~]$ oc rsync tor-7-buxlt:/data/tor/hidden_service/ hidden_service/
    receiving incremental file list
    ./
    hostname
    private_key

    sent 68 bytes  received 1074 bytes  761.33 bytes/sec
    total size is 910  speedup is 0.80

Create a secret with the private key :

    [fridim@master hidden_service]$ oc create secret generic privatekey --from-file=privatekey=./private_key
    secret "privatekey" created

(You need to specify the secret name as you can't have underscore in the name)

Now mount this private\_key to be used at runtime:

    oc volume dc/onionshift --add --mount-path=/data/import --secret-name=privatekey

There you go, .onion address will last across pod deletion/creation.
