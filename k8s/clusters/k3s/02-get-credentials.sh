#!/bin/bash
set -e -o pipefail

export HERE=$(dirname "$(readlink --canonicalize "$BASH_SOURCE")")

export VMS_K8S_NAME=${VMS_K8S_NAME:-"k3s-cluster"}
export CREDENTIALS_DIR="${HERE}/../../../../.credentials"
export CREDENTIALS_DIR=$(readlink -f "${CREDENTIALS_DIR}")
export KUBEFILE=${CREDENTIALS_DIR}/${VMS_K8S_NAME}-kubeconfig.yaml
REMOTEUSER=${REMOTEUSER:-"ubuntu"}

# Echoes the action, for safety
echo "==========> FETCHING CREDENTIALS FROM \"${VMS_K8S_NAME}\" (${VMS_K8S_IP})" >&2
scp \
  -p \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  ${REMOTEUSER}@${VMS_K8S_IP}:.kube/config \
  "${KUBEFILE}" >&2

chmod 700 "${KUBEFILE}"
sed -i "s/127.0.0.1/${VMS_K8S_IP}/g" "${KUBEFILE}"

# Sends also the contents to stdout if not prevented
[[ -z ${NO_PRINT} ]] && cat "${KUBEFILE}"

echo "==========> CREDENTIALS STORED AT \"${KUBEFILE}\"" >&2

# Echoes the completion
echo -e "\nDone.\n" >&2
