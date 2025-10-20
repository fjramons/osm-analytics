#!/bin/bash
set -e -o pipefail

export HERE=$(dirname "$(readlink --canonicalize "$BASH_SOURCE")")
source "${HERE}/library/custom-functions.sh"
source "${HERE}/library/functions.sh"
source "${HERE}/library/trap.sh"

# Grants sensible defaults
export INSTALL_K3S_EXEC=${INSTALL_K3S_EXEC:-""}
export SERVICE_NODEPORT_RANGE=${SERVICE_NODEPORT_RANGE:-"30000-32767"}

# Generates a patch for the service with the right configuration
echo -e "\nUpdating the K3s service..."
SERVICE_NAME=/etc/systemd/system/k3s.service
DROP_IN_NAME=10-service-node-port-range-edits.conf
sudo mkdir -p ${SERVICE_NAME}.d

cat << EOF | sudo tee ${SERVICE_NAME}.d/${DROP_IN_NAME} > /dev/null
[Service]
ExecStart=
ExecStart=/usr/local/bin/k3s \
    server ${INSTALL_K3S_EXEC} \
    --kube-apiserver-arg=service-node-port-range=${SERVICE_NODEPORT_RANGE} \\
EOF

# Reloads and restarts
sudo systemctl daemon-reload
sudo systemctl restart k3s

# Wait until nodes are ready
echo -e "\nWaiting for master to be ready..."
wait_until_master_nodes_ready

# Wait until system pods are ready
echo -e "\nWaiting for system pods to be ready..."
sleep 5
wait_until_system_pods_ready
