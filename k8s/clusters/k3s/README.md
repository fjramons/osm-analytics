# Cluster management with K3s

[TOC]

Utility scripts and environments required to manage the K3s clusters used in this project.

## Pre-requirements

- A VM in a cloud where K3s will be installed.
- SSH access to that VM
- To test the cluster, you will need `kubectl` and `helm`

## Create clusters

First, you must **always source a specific environment and a VM profile** that will be used in subsequent operations. For instance, to work with `aux-services-cluster1` and the info of a pre-created VM you should do:

```bash
source aux-services-cluster1.rc
source ../../.credentials/k8s_vms_info.rc
echo ${VMS_K8S_IP}
```

Then, the following command will install the cluster software into the VM:

```bash
./01-create-cluster.sh
```

The previous command will also save the cluster kubeconfig at `../../../../.credentials/<clustername>-kubeconfig.yaml`

You may add special installation options by setting the environment variable `INSTALL_K3S_EXEC`. For instance, to prevent the installation of Traefik as ingress controller:

```bash
INSTALL_K3S_EXEC="--disable traefik" ./01-create-cluster.sh
```

## Retrieve cluster credentials

Although the cluster kubeconfig is saved to `../../../../.credentials/${VMS_K8S_NAME}-kubeconfig.yaml` upon creation, it can also be retrieved again (e.g., in case you needed to use a cluster created by someone else):

```bash
./02-get-credentials.sh
```

Note that this command, besides saving the standalone kubeconfig again under `../../../../.credentials/`, it will also print its contents to stdout, so that they can be cleanly redirected to create another kubeconfig file.

## Update the service NodePort range (advanced)

In case you needed to update the service NodePort range of the cluster, you might do:

```bash
SERVICE_NODEPORT_RANGE="80-32767" ./03-update-nodeport-range.sh
```

## Uninstall K3s software from the VM

Finally, the K3s software can be deleted from the VM by using:

```bash
./90-delete-cluster.sh
```

Note that this procedure has been included for developer's convenience. For normal operation, we will likely prefer to delete the VM instead.

