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

# Check master nodes are ready
function master_nodes_ready() {
    sudo k3s kubectl get nodes 2> /dev/null | \
        grep master | \
        grep -v none | \
        grep Ready \
        > /dev/null
}

# Check system pods are ready
function system_pods_ready() {
    # State of pods rather than completed jobs
    K3S_NAMESPACE=kube-system

    ! ( \
        sudo k3s kubectl get pods -n ${K3S_NAMESPACE} \
            -o jsonpath='{range .items[*].status.containerStatuses[*]}{.ready}{"\t"}{.state}{"\n"}{end}' 2> /dev/null | \
            grep -v -e 'true' -e 'terminated' > /dev/null
    )
}

# Wait until master nodes are ready
function wait_until_master_nodes_ready() {
    monitor_condition master_nodes_ready "Master not yet ready...\n" 300 5
    if [[ $? -ne 0 ]]
    then
        echo -e "\nFATAL: Timeout waiting for master nodes to be ready. ABORTED.\n"
        exit 1
    fi
}

# Wait until system pods are ready
function wait_until_system_pods_ready() {
    monitor_condition system_pods_ready "K3s system pods not yet ready...\n" 300 5
    if [[ $? -ne 0 ]]
    then
        echo -e "\nFATAL: Timeout waiting for K3s system to be ready. ABORTED.\n"
        exit 1
    fi
}
