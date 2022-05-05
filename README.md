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

## Execution

TODO:
