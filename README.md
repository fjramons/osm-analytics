# OSM Analytics

## Introduction

TODO:

## Installation

### Default installation

Clone the repo and run the install script **as regular user**:

```bash
wget https://raw.githubusercontent.com/fjramons/osm-analytics/main/install-conda-and-analytics.sh
chmod +x install-conda-and-analytics.sh
./install-conda-and-analytics.sh
```

### Manual installation (advanced)

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

## Docker execution

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
docker build -t ${FULL_IMAGE_NAME} --build-arg ENVFILE=environment-docker.yml .
# Option C) Build including Jupyter Lab
docker build -t ${FULL_DEV_IMAGE_NAME} --build-arg DEVELOPMENT=true .
```

Now we should be ready to launch the container. For instance, to invoke the development version of the container to become our local Jupyter server, we could type:

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

In addition, for code editors supporting the _dev containers_ specification (e.g., VSCode), you might use the existing specification in the repo to launch the base container as development platform. **This is highly recommended**.
