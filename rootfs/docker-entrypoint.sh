#!/bin/bash
set -e

DOCKERSWARM_SD_HOST=${DOCKERSWARM_SD_HOST:-dockerswarm_sd_server:9093}
DOCKERSWARM_SD_INTERVAL=${DOCKERSWARM_SD_INTERVAL:-60}

TEMPLATE_DIR="${TEMPLATE_DIR:-/opt/gomplate}"
NAMED_CONFIG_DIR="${NAMED_CONFIG_DIR:-/etc/bind}"
NAMED_CONF_FILE="${NAMED_CONFIG_DIR}/named.conf"

function gomplate_docker() {
	gomplate \
		--datasource dockerinfo=http://${DOCKERSWARM_SD_HOST}/v1.41/info \
		--datasource dockerswarm=http://${DOCKERSWARM_SD_HOST}/v1.41/nodes \
		--datasource dockerservices=http://${DOCKERSWARM_SD_HOST}/v1.41/services \
		--datasource dockertasks=http://${DOCKERSWARM_SD_HOST}/v1.41/tasks \
		"$@"
}

# Generate zone files
function default_zone_config() {
	if [ ! -f "${NAMED_CONFIG_DIR}/zones/db.default" ]; then
		gomplate_docker --file ${TEMPLATE_DIR}/zones/db.default --out ${NAMED_CONFIG_DIR}/zones/db.default
	fi
}

# Periodically sync zones
function default_zone_loop() {
	echo "Starting zone sync loop..."
	while true; do
		sleep 60
		rndc sync
	done
}

# Generate named.conf files
function named_config() {
	gomplate_docker --input-dir ${TEMPLATE_DIR}/named --output-dir ${NAMED_CONFIG_DIR}
}
function named_config_loop() {
	echo "Starting named.conf sync loop..."
	while true; do
		sleep ${DOCKERSWARM_SD_INTERVAL}
		echo "Regenerating configs and zones from Service Discovery..."
		named_config
	done
}

if [[ -z "${CLUSTERSYNC_KEY_FILE}" ]]; then
	echo "The CLUSTERSYNC_KEY_FILE env is not set, using default..."
	CLUSTERSYNC_KEY_FILE=${NAMED_CONFIG_DIR}/cluster-sync.key
fi
if [[ -z "${OCTODNS_KEY_FILE}" ]]; then
	echo "The OCTODNS_KEY_FILE env is not set, using default..."
	OCTODNS_KEY_FILE=${NAMED_CONFIG_DIR}/octodns.key
fi

echo "Generating configs and zones from Service Discovery..."
named_config
named_config_loop &

echo "Generating default zone files if not present..."
default_zone_config
default_zone_loop &

# Set trap to stop named
trap "rndc stop" SIGINT SIGTERM

set +x
named-checkconf -z ${NAMED_CONF_FILE}
named -d 11 -f -c ${NAMED_CONF_FILE}
