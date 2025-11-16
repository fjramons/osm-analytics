#!/bin/bash

set -e -o pipefail

# Delete obsolete credentials
OBSOLETE_CREDENTIALS="../../../.credentials/${VMS_K8S_NAME}-kubeconfig.yaml"
OBSOLETE_CREDENTIALS="$(readlink -f "${OBSOLETE_CREDENTIALS}")"

echo "Deleting obsolete credentials at ${OBSOLETE_CREDENTIALS}"
rm "${OBSOLETE_CREDENTIALS}"
