FROM alpine:latest

RUN apk update && \
    apk add bash bind && \
    rm -rf /var/cache/apk/*

ARG GOMPLATE_VERSION=v3.11.3
ADD --chmod=755 https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64 /usr/bin/gomplate

ADD rootfs /

# Create rndc key
RUN rndc-confgen -a && \
    cp /etc/bind/rndc.key /etc/rndc.key

# Create cluster-sync key
ARG CLUSTERSYNC_KEY_NAME=cluster-sync
ENV CLUSTERSYNC_KEY_NAME=${CLUSTERSYNC_KEY_NAME}
RUN rndc-confgen -a -k "${CLUSTERSYNC_KEY_NAME}" -c "/etc/bind/cluster-sync.key" && \
    cat /etc/bind/cluster-sync.key

# Create octodns key
ARG OCTODNS_KEY_NAME=octodns
ENV OCTODNS_KEY_NAME=${OCTODNS_KEY_NAME}
RUN rndc-confgen -a -k "${OCTODNS_KEY_NAME}" -c "/etc/bind/octodns.key" && \
    cat /etc/bind/octodns.key

ENV DOCKERSWARM_SD_HOST=dockerswarm_sd_server:9093
ENV DOCKERSWARM_SD_INTERVAL=15
ENV CLUSTERSYNC_KEY_FILE=
ENV OCTODNS_KEY_FILE=

VOLUME [ "/etc/bind/zones" ]
ENTRYPOINT [ "/docker-entrypoint.sh" ]
