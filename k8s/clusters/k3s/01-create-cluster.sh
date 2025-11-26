#!/bin/bash
set -e -o pipefail

export HERE=$(dirname "$(readlink --canonicalize "$BASH_SOURCE")")
source "${HERE}/library/custom-functions.sh"

# Checks if the required environment variables are defined
if [[ -z ${VMS_K8S_IP} ]]; then
  echo -e "\nERROR: \'VMS_K8S_IP\' not defined. Set to the IP address of the remote VM.\n"
  exit 1
fi

# Sets reasonable defaults
# export INSTALL_K3S_EXEC="--disable traefik"
export INSTALL_K3S_EXEC=${INSTALL_K3S_EXEC:-""}
export VMS_K8S_NAME=${VMS_K8S_NAME:-"k3s-cluster"}
REMOTEUSER=${REMOTEUSER:-"ubuntu"}

# K3s releases: https://github.com/k3s-io/k3s/releases/
export K8S_VERSION=${K8S_VERSION:-"v1.29.3+k3s1"}

# Waits until SSH is ready in the remote VM
wait_until_ssh_ready

# Copies all the scripts to the remote server
SCRIPT_FOLDER="${HERE}/remote"
scp \
  -p \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -r "${SCRIPT_FOLDER}" \
  ${REMOTEUSER}@${VMS_K8S_IP}:k3s-scripts

# Runs installation script in the remote server
ssh \
  -T \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  ${REMOTEUSER}@${VMS_K8S_IP} \
  <<EOF 2>&1
find . -name '*.sh' -exec chmod +x {} \;
K8S_VERSION="${K8S_VERSION}" INSTALL_K3S_EXEC="${INSTALL_K3S_EXEC}" ./k3s-scripts/install-k3s.sh
EOF

# Saves credentials to file at default location (avoids echoing to stdout)
echo
NO_PRINT=true "${HERE}/02-get-credentials.sh"
