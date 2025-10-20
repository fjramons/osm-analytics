#!/bin/bash

set -e -o pipefail

export INSTALL_K3S_EXEC=${INSTALL_K3S_EXEC:-""}
# (Optional) Here you may specify installation parameters by using these environment variables. E.g.:
# export INSTALL_K3S_EXEC="--disable traefik"
# export VMS_K8S_NAME="k3s-cluster"
# export K8S_VERSION="v1.29.3+k3s1"
# export VMS_K8S_IP=192.168.1.33

# Install K3s and retrieve its credentials
pushd k3s >/dev/null
./01-create-cluster.sh
# Generates -----> `../../../.credentials/${VMS_K8S_NAME}-kubeconfig.yaml`
popd >/dev/null
