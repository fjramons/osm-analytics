#!/bin/bash
set -e -o pipefail

export HERE=$(dirname "$(readlink --canonicalize "$BASH_SOURCE")")
source "${HERE}/library/custom-functions.sh"
source "${HERE}/library/functions.sh"
source "${HERE}/library/trap.sh"

# K3s releases: https://github.com/k3s-io/k3s/releases/
export K8S_VERSION=${K8S_VERSION:-"v1.29.3+k3s1"}

# Install K3s with requested options
export INSTALL_K3S_EXEC=${INSTALL_K3S_EXEC:-""}
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K8S_VERSION} sh -s -

# Wait until nodes are ready
echo -e "\nWaiting for master to be ready..."
wait_until_master_nodes_ready

# Wait until system pods are ready
echo -e "\nWaiting for system pods to be ready..."
sleep 5
wait_until_system_pods_ready

# Copies credentials to the current user's profile and sets the right permissions
KUBEDIR="${HOME}/.kube"
KUBEFILE="$KUBEDIR/config"
mkdir -p "${KUBEDIR}"
sudo cp /etc/rancher/k3s/k3s.yaml "${KUBEFILE}"
sudo chown ${USER}:${USER} "${KUBEFILE}"
chmod 700 "${KUBEFILE}"
