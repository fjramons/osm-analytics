# OSM Analytics

- [OSM Analytics](#osm-analytics)
  - [0. Introduction](#0-introduction)
  - [1. Installation](#1-installation)
    - [1.1 Kubernetes (recommended for production)](#11-kubernetes-recommended-for-production)
      - [**Step 1.** Prepare folder structure and clone this repo](#step-1-prepare-folder-structure-and-clone-this-repo)
      - [**Step 2.** Setup of a Kubernetes cluster](#step-2-setup-of-a-kubernetes-cluster)
      - [**Step 3.** Fill-in files with key configuration parameters](#step-3-fill-in-files-with-key-configuration-parameters)
      - [**Step 4.** Deploy Argo WorkFlows CRDs and operators](#step-4-deploy-argo-workflows-crds-and-operators)
      - [**Step 5.** Deploy the MySQL database using the helm chart](#step-5-deploy-the-mysql-database-using-the-helm-chart)
      - [**Step 6.** Deploy workflow templates](#step-6-deploy-workflow-templates)
      - [**Step 7.** (optional) Test workflow templates using sample workflow](#step-7-optional-test-workflow-templates-using-sample-workflow)
      - [**Step 8.** Deploy scheduled workflows using `CronWorkflows`](#step-8-deploy-scheduled-workflows-using-cronworkflows)
    - [1.2 Standalone over VM or server](#12-standalone-over-vm-or-server)
      - [1.2.1 Default installation](#121-default-installation)
      - [1.2.2 Manual installation (advanced)](#122-manual-installation-advanced)
  - [3. Docker execution](#3-docker-execution)
    - [Use of the container for development](#use-of-the-container-for-development)

## 0. Introduction

OSM Analytics is a set of tools and scripts to analyze statistics from development tools of Open Source MANO (ETSI OSM). It includes functionalities for data extraction, transformation, and visualization for its main tools:

- CI/CD based on Jenkins and E2E test results based on Robot Framework.
- Bug tracking based on Bugzilla.
- Download statistics of the different OSM releases.
- License compliance based on FOSSA data.

## 1. Installation

### 1.1 Kubernetes (recommended for production)

Outline:

1. Prepare an appropriate folder structure and clone this repo.
2. Setup a Kubernetes cluster.
3. Fill-in files with key configuration parameters:
   - `ftp-credentials.env`: Credentials for the FTP server where reports are saved.
   - `jenkins-credentials.env`: Credentials for accessing Jenkins API.
   - `db-credentials.env`: Credentials for accessing the database where historical builds and analysis are accumulated.
   - `installations-config.env`: General configuration parameters for the analysis of installations.
   - `bugzilla-config.env`: General configuration parameters for the analysis of bugs.
   - `jenkins-config.env`: General configuration parameters for the analysis of CI/CD builds.
4. Deploy Argo WorkFlows CRDs and operators.
5. Deploy the MySQL database using the helm chart.
6. Deploy workflow templates.
7. (optional) Test workflow templates using sample workflow.
8. Deploy scheduled workflows using `CronWorkflows`.

#### **Step 1.** Prepare folder structure and clone this repo

In our client environment (i.e., not in the cluster VM/server), we are expected to create the following folder structure:

   ```text
   ..
   ├── .credentials
   ├── configurations
   └── osm-analytics   # <- this repo
   ```

   Where:

- `osm-analytics` is the local clone of this repo.
- `.credentials` contains sensitive data related to the environment, such as: `kubeconfig` of the target cluster, Jenkins credentials, database credentials, or FTP credentials.
- `configurations` contains configuration files for the different analysis workflows.

#### **Step 2.** Setup of a Kubernetes cluster

Create a Kubernetes cluster using your preferred method, and copy the `kubeconfig` file for accessing the target cluster to the `.credentials` folder:

```bash
KUBECONFIG_NAME="your-cluster-kubeconfig.yaml"
cp "${KUBECONFIG_NAME}" "../.credentials/${KUBECONFIG_NAME}"

# Then we should set the kubeconfig as the current default
export KUBECONFIG="../.credentials/${KUBECONFIG_NAME}"
export KUBECONFIG="$(readlink -f ${KUBECONFIG})"

# (optional) Check access to the cluster
kubectl get nodes
```

In case you are given a VM or server, you might want to use a lightweight Kubernetes distribution, such as [K3s](https://k3s.io/). The current repo contains a set of scripts to create easily a K3s cluster over a single VM/server, following this procedure:

```bash
# Update accordingly
export VMS_K8S_IP="your.vm.ip.address.here"
export VMS_K8S_NAME=${VMS_K8S_NAME:-"osm-analytics"}

# Recommended: disable Traefik installation
export INSTALL_K3S_EXEC="--disable traefik"

# Finally, run the script to install K3s over the VM
pushd k8s/clusters >/dev/null
./01-create-k3s-in-vm.sh
popd >/dev/null
```

This procedure will also export the new cluster's kubeconfig to the expected location: `../.credentials/${VMS_K8S_NAME}-kubeconfig.yaml`. We would just need to set the kubeconfig as the current default:

```bash
KUBECONFIG_NAME="${VMS_K8S_NAME}-kubeconfig.yaml"
export KUBECONFIG="../.credentials/${KUBECONFIG_NAME}"
export KUBECONFIG="$(readlink -f ${KUBECONFIG})"

# (optional) Check access to the cluster
kubectl get nodes
```

**NOTE:** The scripts assume that the VM/server already has a user named `ubuntu` with sudo privileges and no need of password, and SSH key-based authentication enabled.

#### **Step 3.** Fill-in files with key configuration parameters

`ftp-credentials.env`: Credentials for the FTP server where reports are saved.

TODO:

`jenkins-credentials.env`: Credentials for accessing Jenkins API.

TODO:

`db-credentials.env`: Credentials for accessing the database where historical builds and analysis are accumulated.

TODO:

`installations-config.env`: General configuration parameters for the analysis of installations.

TODO:

`bugzilla-config.env`: General configuration parameters for the analysis of bugs.

TODO:

`jenkins-config.env`: General configuration parameters for the analysis of CI/CD builds.

#### **Step 4.** Deploy Argo WorkFlows CRDs and operators

TODO:

#### **Step 5.** Deploy the MySQL database using the helm chart

TODO:

#### **Step 6.** Deploy workflow templates

TODO:

#### **Step 7.** (optional) Test workflow templates using sample workflow

TODO:

#### **Step 8.** Deploy scheduled workflows using `CronWorkflows`

TODO:

### 1.2 Standalone over VM or server

#### 1.2.1 Default installation

Clone the repo and run the install script **as regular user**:

```bash
wget https://raw.githubusercontent.com/fjramons/osm-analytics/main/install-conda-and-analytics.sh
chmod +x install-conda-and-analytics.sh
./install-conda-and-analytics.sh
```

#### 1.2.2 Manual installation (advanced)

Conda/Miniconda setup:

```bash
export BASEDIR=${BASEDIR:-/home/$(whoami)}

# Installation of Conda
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh -P "${BASEDIR}"
chmod +x "${BASEDIR}"/Miniconda3-py39_4.10.3-Linux-x86_64.sh
bash "${BASEDIR}"/Miniconda3-py39_4.10.3-Linux-x86_64.sh -b

# Activation of shell for Conda
eval "$(${BASEDIR}/miniconda3/bin/conda shell.bash hook)"
conda init
```

Retrieval of analytics repo:

```bash
# Retrieves the analytics repo
git clone https://github.com/fjramons/osm-analytics.git "${BASEDIR}"/osm-analytics
```

Setup of Conda environment:

```bash
# Retrieves the analytics repo and creates an environment
conda env create -f "${BASEDIR}"/osm-analytics/environment.yml

# Activates the environment
conda activate osm-analytics
```

## 3. Docker execution

First, we will set the container names for regular execution and development:

```bash
# Base names (CHANGE AS NEEDED)
OSM_ANALYTICS_IMAGE=${OSM_ANALYTICS_IMAGE:-"osm-analytics"}
DOCKER_REPO=${DOCKER_REPO:-"ttl.sh"}
DOCKER_SDK_TAG=${DOCKER_SDK_TAG:-"24h"}

# Container for regular execution
FULL_IMAGE_NAME=${DOCKER_REPO}/${OSM_ANALYTICS_IMAGE}:${DOCKER_SDK_TAG}
echo "${FULL_IMAGE_NAME}"

# Container for local development
FULL_DEV_IMAGE_NAME=${DOCKER_REPO}/${OSM_ANALYTICS_IMAGE}-dev:${DOCKER_SDK_TAG}
echo "${FULL_DEV_IMAGE_NAME}"
```

Now we can pull or build the containers as needed.

In case we needed to build them locally:

```bash
# Option A) Normal build
docker build -t ${FULL_IMAGE_NAME} .
# Option B) Build with non-pinned dependencies
# docker build -t ${FULL_IMAGE_NAME} --build-arg ENVFILE=environment-docker.yml .
# Option C) Build including Jupyter Lab
docker build -t ${FULL_DEV_IMAGE_NAME} --build-arg DEVELOPMENT=true .
```

Now we should be ready to launch the container.

### Use of the container for development

For code editors supporting the _dev containers_ specification (e.g., VSCode), we might use the existing specification in the repo to launch the base container as development platform. **This is option is highly recommended**.

Alternatively, in case we wanted to invoke the _development_ version of the container to become our local Jupyter server, we could type:

```bash
docker run --rm -it \
    -p 8888:8888 \
    ${FULL_DEV_IMAGE_NAME} \
    jupyter notebook \
        --notebook-dir=/osm-analytics \
        --ip='*' \
        --port=8888 \
        --no-browser --allow-root
```

