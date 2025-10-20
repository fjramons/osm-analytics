#!/bin/bash

# Monitor progress of a condition
monitor_condition() {
    local CONDITION="$1"        # Function with the condition
    local MESSAGE="${2:-}"      # Message during each check
    local TIMEOUT="${3:-300}"   # Timeout, in seconds (default: 5 minutes)
    local STEP="${4:-2}"        # Polling period (default: 2 seconds)

    # echo ${TIMEOUT}
    until "${CONDITION}" || [ ${TIMEOUT} -le 0 ]
    do
        echo -en "${MESSAGE}"

        ((TIMEOUT-=${STEP}))
        # echo ${TIMEOUT}

        sleep "${STEP}"
    done

    "${CONDITION}"
}


# Check the VM is reachable by SSH
function vms_ssh_ready() {
    VMS_K8S_IP=${1:-"${VMS_K8S_IP}"}
    ssh \
        -T \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        ubuntu@${VMS_K8S_IP} echo "SSH ready" > /dev/null
}


# Wait until the VM is reachable by SSH
function wait_until_ssh_ready() {
    monitor_condition vms_ssh_ready "SSH not ready yet...\n" 300 5
}
