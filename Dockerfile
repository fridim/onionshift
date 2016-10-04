#
# Tor image for Openshift 3
#
# Environment:
# * $SERVICE_NAME : service to expose in tor as an hidden service
# * $SERVICE_PORT : service port to expose
# * $HS_PORT      : hidden_service port reachable via the .onion URL (default: 80)

FROM alpine
MAINTAINER fridim fridim@onfi.re

# update TOR_VER and SHA256 for new version
# (verify download with gpg signature & create md5)
ENV TOR_ENV production
ENV TOR_VER 0.2.8.7
ENV TOR_SHA256 ae44e2b699e82db7ff318432fd558dfa941ad154e4055f16d208514951742fc6

ENV ARM_VER 1.4.5.0

ENV TOR_URL https://www.torproject.org/dist/tor-$TOR_VER.tar.gz
ENV TOR_FILE tor.tar.gz
ENV TOR_TEMP tor-$TOR_VER


LABEL io.k8s.description="Tor client and hidden service on Openshift" \
      io.k8s.display-name="Tor 0.2.8.7" \
      io.openshift.tags="tor,route"

RUN apk add -U build-base \
               gmp-dev \
               libevent \
               libevent-dev \
               libgmpxx \
               openssl \
               openssl-dev \
               python \
               python-dev \
               rsync \
               tar \
               bash \
               gettext\
               socat \
        && wget -O- https://bootstrap.pypa.io/get-pip.py | python \
        && pip install onionbalance \
        && wget -O $TOR_FILE $TOR_URL \
        && echo "${TOR_SHA256}  ${TOR_FILE}" | sha256sum -c \
        && tar xzf $TOR_FILE \
        && cd $TOR_TEMP \
        && ./configure --prefix=/ --exec-prefix=/usr \
        && make install \
        && cd .. \
        && rm -rf $TOR_FILE $TOR_TEMP \
        && apk del build-base \
               git \
               gmp-dev \
               go \
               python-dev \
        && rm -rf /root/.cache/pip/* \
        && rm -rf /var/cache/apk/*

COPY ./damianJohnson.asc /tmp/

RUN cd /tmp \
    && apk -U add gnupg \
    && wget https://www.atagar.com/arm/resources/static/arm-${ARM_VER}.tar.bz2 \
    && wget https://www.atagar.com/arm/resources/static/arm-${ARM_VER}.tar.bz2.asc \
    && gpg --import damianJohnson.asc \
    && gpg --verify arm-${ARM_VER}.tar.bz2.asc \
    && tar xjf /tmp/arm-${ARM_VER}.tar.bz2 \
    && cd arm \
    && ./install \
    && cd /tmp \
    && rm -rf arm arm-${ARM_VER}.tar.bz2* \
    && rm -rf damianJohnson.asc /root/.gnupg \
    && apk del gnupg

# tor will create a rep in /data
RUN mkdir /data && chmod 777 /data

VOLUME /data

COPY ./torrc.template /data/
COPY ./tor-entrypoint.sh /
COPY ./onionbalance-entrypoint.sh /

CMD ["/tor-entrypoint.sh"]
