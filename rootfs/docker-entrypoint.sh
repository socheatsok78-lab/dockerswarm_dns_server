#!/bin/bash
set -e

DOCKER_HOST=${DOCKER_HOST:-dockerswarm_sd_server:9093}

TEMPLATE_DIR="${TEMPLATE_DIR:-/opt/gomplate}"

NAMED_CONFIG_DIR="${NAMED_CONFIG_DIR:-/etc/bind}"
NAMED_CONF_FILE="${NAMED_CONFIG_DIR}/named.conf"

function gomplate_docker() {
    gomplate \
        --datasource dockerinfo=http://${DOCKER_HOST}/v1.41/info \
        --datasource dockerswarm=http://${DOCKER_HOST}/v1.41/nodes \
        --datasource dockerservices=http://${DOCKER_HOST}/v1.41/services \
        --datasource dockertasks=http://${DOCKER_HOST}/v1.41/tasks \
        "$@"
}


# Generate named.conf files
gomplate_docker --input-dir ${TEMPLATE_DIR}/named --output-dir ${NAMED_CONFIG_DIR}

# Generate zone files
gomplate_docker --input-dir ${TEMPLATE_DIR}/zones --output-dir ${NAMED_CONFIG_DIR}/zones

set +x
named-checkconf -z ${NAMED_CONF_FILE}
named -d 11 -f -c ${NAMED_CONF_FILE}
