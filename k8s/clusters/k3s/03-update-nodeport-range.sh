#!/bin/bash
set -e -o pipefail

export HERE=$(dirname "$(readlink --canonicalize "$BASH_SOURCE")")

# Grants sensible defaults
# export SERVICE_NODEPORT_RANGE="80-32767"
export SERVICE_NODEPORT_RANGE=${SERVICE_NODEPORT_RANGE:-"30000-32767"}
export INSTALL_K3S_EXEC=${INSTALL_K3S_EXEC:-""}
REMOTEUSER=${REMOTEUSER:-"ubuntu"}


# Runs installation script in the remote server
ssh \
  -T \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  ${REMOTEUSER}@${VMS_K8S_IP} \
  <<EOF 2>&1
SERVICE_NODEPORT_RANGE="${SERVICE_NODEPORT_RANGE}" INSTALL_K3S_EXEC="${INSTALL_K3S_EXEC}" ./k3s-scripts/change-node-port-range.sh
EOF

echo -e "\nDone.\n"
