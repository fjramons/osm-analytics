#!/bin/bash
set -e -o pipefail

# Runs installation script in the remote server
REMOTEUSER=${REMOTEUSER:-"ubuntu"}
ssh \
    -T \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    ${REMOTEUSER}@${VMS_K8S_IP} \
<< EOF 2>&1
rm -rf k3s-scripts
sudo /usr/local/bin/k3s-uninstall.sh
EOF

echo -e "\nDone.\n"
