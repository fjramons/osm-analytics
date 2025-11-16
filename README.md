# OSM Analytics

- [OSM Analytics](#osm-analytics)
  - [0. Introduction](#0-introduction)
  - [1. Installation](#1-installation)
    - [1.1 Kubernetes (recommended for production)](#11-kubernetes-recommended-for-production)
      - [**Step 1.** Prepare folder structure and clone this repo](#step-1-prepare-folder-structure-and-clone-this-repo)
      - [**Step 2.** Setup of a Kubernetes cluster](#step-2-setup-of-a-kubernetes-cluster)
      - [**Step 3.** Fill-in files with key configuration parameters](#step-3-fill-in-files-with-key-configuration-parameters)
      - [**Step 4.** Deploy Kustomization](#step-4-deploy-kustomization)
      - [**Step 5.** (optional) Pre-populate the database with data of former Jenkins builds (if applicable)](#step-5-optional-pre-populate-the-database-with-data-of-former-jenkins-builds-if-applicable)
      - [**Step 6.** (optional) Test workflow templates using sample workflow](#step-6-optional-test-workflow-templates-using-sample-workflow)
    - [1.2 Standalone over VM or server](#12-standalone-over-vm-or-server)
      - [1.2.1 Default installation](#121-default-installation)
      - [1.2.2 Manual installation (advanced)](#122-manual-installation-advanced)
  - [3. Docker execution](#3-docker-execution)
    - [Use of the container for development](#use-of-the-container-for-development)
  - [ANNEX A: Database debugging](#annex-a-database-debugging)
    - [A.1 Check if the database is up and accesible](#a1-check-if-the-database-is-up-and-accesible)
    - [A.2 Re-run database provisioning job](#a2-re-run-database-provisioning-job)
    - [A.3 **DANGEROUS:** Revert all provisioning, by removing the database and the new user](#a3-dangerous-revert-all-provisioning-by-removing-the-database-and-the-new-user)
    - [A.4 Interactive debugging](#a4-interactive-debugging)
  - [ANNEX B: Database backup](#annex-b-database-backup)
    - [B.1 From the old database (VM-based installation)](#b1-from-the-old-database-vm-based-installation)
    - [B.2 From the new database (Kubernetes-based installation)](#b2-from-the-new-database-kubernetes-based-installation)
  - [ANNEX C: Troubleshooting](#annex-c-troubleshooting)
    - [C.1 Container troubleshooting](#c1-container-troubleshooting)
    - [C.2 Database troubleshooting](#c2-database-troubleshooting)
      - [C.2.1 From the `jenkins-analytics-troubleshoot` container](#c21-from-the-jenkins-analytics-troubleshoot-container)
      - [C.2.2 From your desktop](#c22-from-your-desktop)

## 0. Introduction

OSM Analytics is a set of tools and scripts to analyze statistics from development tools of Open Source MANO (ETSI OSM), but which are suitable for other projects using the same tooling. It includes functionalities for data extraction, transformation, and visualization for its main tools:

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
   - `db-credentials.env`: Credentials for accessing the database where historical builds and analysis are accumulated.
   - `ftp-credentials.env`: Credentials for the FTP server where reports are saved.
   - `jenkins-credentials.env`: Credentials for accessing Jenkins API.
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
   └── osm-analytics   # <- this repo
       └── k8s
           ├── clusters
           └── manifests
               ├── env-templates
               ├── tests
               │  . . .
               ├── crds
               ├── base
               ├── overlay-dev
               │   └── config (untracked)
               └── overlay-prod
                   └── config (untracked)
   ```

   Where:

- `.credentials` contains sensitive data such as new `kubeconfig`s for target clusters, database backups, etc.
- `osm-analytics` is the local clone of this repo.
- `k8s/clusters/` contains automation scripts to create a simple K3s cluster.
- `k8s/manifests/crds/` contains the required CRDs for OSM Analytics.
- `k8s/manifests/base/` contains the base Kustomization for the OSM Analytics installation.
- `k8s/manifests/<TARGET-ENV>-overlay/` contains the overlay Kustomization for a specific target deployment environment. With the base clone, `<TARGET-ENV>` may be `dev` or `prod`.
- `k8s/manifests/<TARGET-ENV>-overlay/config/` contains configuration files for the different analysis workflows in the `<TARGET-ENV>` environment.
- `k8s/manifests/env-templates/` contains templates for generating configuration files for a given target deployment environment.
- `k8s/manifests/tests/` contains additional K8s manifests to perform various troubleshooting tasks.

#### **Step 2.** Setup of a Kubernetes cluster

Create a Kubernetes cluster using your preferred method.

In case you are given a VM or server, you might want to use a lightweight Kubernetes distribution, such as [K3s](https://k3s.io/). The current repo contains a set of scripts to create easily a K3s cluster over a single VM/server, following this procedure:

```bash
# Update accordingly
## In case it exists
export VMS_K8S_IP=${VMS_K8S_IP:-"your.vm.ip.address.or.fqdn.here"}
export VMS_K8S_NAME=${VMS_K8S_NAME:-"osm-analytics"}

# Recommended: disable Traefik installation
export INSTALL_K3S_EXEC="--disable traefik"

# Finally, run the script to install K3s over the VM
pushd k8s/clusters >/dev/null
./01-create-k3s-in-vm.sh
popd >/dev/null
```

This procedure will also export the new cluster's kubeconfig to the `../.credentials` folder.

**NOTE:** The scripts assume that the VM/server already has a user named `ubuntu` with sudo privileges and no need of password, and SSH key-based authentication enabled.

**Once you have created your cluster** (either with these scripts or with any other procedure), you will need to copy the `kubeconfig` file to the `config` folder for the corresponding target environment:

```bash
# Select the target environment for your deployment
TARGET_ENVIRONMENT=overlay-prod
# TARGET_ENVIRONMENT=overlay-dev
ENVIRONMENT_CONFIG="k8s/manifests/${TARGET_ENVIRONMENT}/config"
#-------------------------------------------------------------------

# Determine the kubeconfig filename
#
## CASE A) If you created the cluster using the script:
source ../.credentials/k8s_vms_info.rc
KUBECONFIG_NAME="${VMS_K8S_NAME}-kubeconfig.yaml"
#
## CASE B) Otherwise:
# KUBECONFIG_NAME="yourcluster-kubeconfig.yaml"

# Copy to the environment config
cp "../.credentials/k8s_vms_info.rc" "${ENVIRONMENT_CONFIG}/" || true
cp "../.credentials/${KUBECONFIG_NAME}" "${ENVIRONMENT_CONFIG}/"

# Then we set the kubeconfig as the current default
export KUBECONFIG="${ENVIRONMENT_CONFIG}/${KUBECONFIG_NAME}"
export KUBECONFIG="$(readlink -f ${KUBECONFIG})"

# (optional) Check access to the cluster
kubectl get nodes
kubectl get ns
```

#### **Step 3.** Fill-in files with key configuration parameters

First, copy all templates for environment variables to be filled-in to the `config` folder at the corresponding overlay for the target deployment environment:

```bash
# cp -i k8s/manifests/env-templates/* k8s/manifests/${TARGET_ENVIRONMENT}/config/
cp -i k8s/manifests/env-templates/* "${ENVIRONMENT_CONFIG}/"
```

Then, fill-in all the required parameters for each of the following files:

- **`db-credentials.env`**: (**sensitive file**) Credentials for accessing the database where historical builds and analysis are accumulated. Required keys are:
  - `rootUser`: Username of the InnoDBCluster root user.
  - `rootPassword`: Password of the InnoDBCluster root user.
  - `stdUser`: Username of the standard user for accessing the database.
  - `stdPassword`: Password of the standard user for accessing the database.
- **`ftp-credentials.env`**: (**sensitive file**) Credentials for the FTP server where reports are saved.
  - `FTP_SERVER`: Url of the FTP server to upload the reports. Note that the format should be `ftp://<server_address>`.
  - `FTP_USERNAME`: FTP user for analytics.
  - `FTP_PASSWORD`: Password of the FTP user.
  - **NOTE:** The `REMOTE_BASE_FOLDER` is not defined here, since it may vary depending on the type of analysis (CI/CD, installations, bugs). It will be defined in the corresponding `ConfigMap` for each analysis type.
- **`jenkins-credentials.env`**: (**sensitive file**) Credentials for accessing Jenkins API.
  - `URL_JENKINS_SERVER`: Base URL of your Jenkins server.
  - `DATABASE_URI`: Metrics database URL with authentication. The format is likely to follow this format:

    ```python
    "mysql+pymysql://${MYSQL_USER}:${MYSQL_USER_PASSWORD}@osm-metrics.database.svc.cluster.local:3306/osm_metrics_db"
    ```

    Where `${MYSQL_USER}` and `${MYSQL_USER_PASSWORD}` should be replaced by the same values set for `stdUser` and `stdPassword` at `db-credentials.env`, respectively.
- **`installations-config.env`**: General configuration parameters for the analysis of installations.
  - `UPLOAD_REPORT`: Whether to upload the report to an FTP server. Possible values: `YES` or `NO`.
  - `REMOTE_BASE_FOLDER`: FTP subfolder to upload the report.
  - `TZ`: Time zone to timestamp the reports.
  - `OUTPUTS_FOLDER`: Local folder to save the report. Sensible default: `outputs`.
  - `KEY_FILE_NAME`: Name of the HTML file generated with the report. Sensible default: `installation_analysis.html`.
- **`bugzilla-config.env`**: General configuration parameters for the analysis of bugs.
  - `UPLOAD_REPORT`: Whether to upload the report to an FTP server. Possible values: `YES` or `NO`.
  - `REMOTE_BASE_FOLDER`: FTP subfolder to upload the report.
  - `TZ`: Time zone to timestamp the reports.
  - `OUTPUTS_FOLDER`: Local folder to save the report. Sensible default: `outputs`.
  - `KEY_FILE_NAME`: Name of the HTML file generated with the report. Sensible default: `bugzilla_analysis.html`.
- **`jenkins-config.env`**: General configuration parameters for the analysis of CI/CD builds.
  - `UPLOAD_REPORT`: Whether to upload the report to an FTP server. Possible values: `YES` or `NO`.
  - `REMOTE_BASE_FOLDER`: FTP subfolder to upload the report.
  - `TZ`: Time zone to timestamp the reports.
  - `REPORT_OUTPUTS_FOLDER`: Local folder to save the report. Sensible default: `report_outputs`.
  - `ETL_OUTPUTS_FOLDER`: Local folder to save intermediate ETL results. Sensible default: `etl_outputs`.
  - `KEY_FILE_NAME`: Name of the HTML file generated with the report. Sensible default: `analysis_of_test_results.html`.
  - `JOB_IDS`: List of Jenkins job IDs to monitor.
  - `JOB_NAMES`: List of human-friendly names for the Jenkins jobs to monitor.
  - `JOB_IDS_PREFIX`: Prefix to be added to each job ID (if applicable).
  - `LINK_TO_BUILD`: Template link to access each build in the Jenkins server.
  - `LINK_TO_REPORT`: Template link to access each Robot Framework report in the Jenkins server.
  - `TOO_OLD_BUILDS`: Date (YYYY-MM-DD) to consider builds older than this date as out-of-scope for the analysis.
  - `DAYS_SINCE_TODAY_4_ANALYSIS`: Number of days from today to consider builds as in-scope for the analysis.
  - `SKIP_DATABASE_UPDATE`: Whether to skip the update of the database with new builds from Jenkins. Sensible default: `False`.
  - `SKIP_EXPORT_TO_HTML`: Whether to skip the export of the analysis to an HTML report. Sensible default: `False`.
  - `TABLE_KNOWN_BUILDS`: Name of the database table where known builds are stored. Sensible default: `builds_info`.
  - `TABLE_ROBOT_REPORTS`: Name of the database table where Robot Framework reports are stored. Sensible default: `robot_reports`.
  - `TABLE_ROBOT_REPORTS_EXTENDED`: Name of the database table where extended Robot Framework reports are stored. Sensible default: `robot_reports_extended`.

#### **Step 4.** Deploy Kustomization

These Kustomizations will deploy:

- Argo WorkFlows CRDs and operators.
- Deploy the MySQL database using the helm chart.
- Deploy workflow templates.
- Deploy scheduled workflows using `CronWorkflows`.
- All the Secrets and ConfigMaps that need to be generated to fully configure all resources above.

```bash
# First, install all CRDs
kubectl apply -k ./k8s/manifests/crds/

# Check/Select the target environment for your deployment
echo "${TARGET_ENVIRONMENT}"
# TARGET_ENVIRONMENT=overlay-dev
# # TARGET_ENVIRONMENT=overlay-prod
# ENVIRONMENT_CONFIG="k8s/manifests/${TARGET_ENVIRONMENT}/config"
#-------------------------------------------------------------------

# (optional) Dry-run for all resources that will be deployed to the target environment
kubectl kustomize "./k8s/manifests/${TARGET_ENVIRONMENT}" | bat -l yaml

# Finally, install all resources for the target environment
kubectl kustomize "./k8s/manifests/${TARGET_ENVIRONMENT}" | kubectl apply -f -
```

(optional) Check that the resources are properly created and the database provisioned:

```bash
# Wait for readiness of the database pods and provisioning job completion
watch kubectl get pod -n database

# Check that the database was created and is accessible with the provisioned user (the job should complete successfully)
kubectl apply -f ./k8s/manifests/tests/db-provisioning-check.yaml
kubectl get job/db-provisioning-check -n database
kubectl logs job/db-provisioning-check -n database
## Same info, but in a more readable print
printf "$(kubectl logs job/db-provisioning-check -n database)"
kubectl delete -f ./k8s/manifests/tests/db-provisioning-check.yaml

## To remove everything
# kubectl kustomize "./k8s/manifests/${TARGET_ENVIRONMENT}" | kubectl delete -f -
# kubectl delete -k ./k8s/manifests/crds/
```

#### **Step 5.** (optional) Pre-populate the database with data of former Jenkins builds (if applicable)

```bash
# Retrieve user's credentials
export DB_STD_USER=$(
  kubectl get secret/osm-metrics \
    -n database \
    -o jsonpath="{.data.stdUser}" \
  | base64 --decode
)
export DB_STD_PASSWORD=$(
  kubectl get secret/osm-metrics \
    -n database \
    -o jsonpath="{.data.stdPassword}" \
  | base64 --decode
)
echo ${DB_STD_USER}
echo ${DB_STD_PASSWORD}

# Create a port-forward to access the database from the client machine
## (optional) Inspect the service
kubectl get service/osm-metrics -n database
## Run the port-forward in background
SOURCE_DB_PORT=3306
FWD_DB_PORT=33060
kubectl port-forward service/osm-metrics -n database ${FWD_DB_PORT}:${SOURCE_DB_PORT} &
## (optional) Test connection
mysql -u "${DB_STD_USER}" -p"${DB_STD_PASSWORD}" -P ${FWD_DB_PORT} -h 127.0.0.1 osm_metrics_db
SHOW TABLES;
exit;

# Import the dump from the backup file
BACKUP_FILE="../.credentials/backups/osm_metrics_db.sql.gz"
gzip -d -c "${BACKUP_FILE}" | mysql -u "${DB_STD_USER}" -p"${DB_STD_PASSWORD}" -P ${FWD_DB_PORT} -h 127.0.0.1 osm_metrics_db
# gzip -d -c "${BACKUP_FILE}" | mysql -u "${DB_ROOT_USER}" -p"${DB_ROOT_PASSWORD}" -P ${FWD_DB_PORT} -h 127.0.0.1 osm_metrics_db

# (optional) METHOD 1: Check that data was properly imported by accessing to the database interactively
mysql -u "${DB_STD_USER}" -p"${DB_STD_PASSWORD}" -P ${FWD_DB_PORT} -h 127.0.0.1 osm_metrics_db
SHOW TABLES;
SELECT COUNT(*) FROM builds_info;
SELECT * FROM builds_info LIMIT 5;
SELECT COUNT(*) FROM robot_reports;
SELECT * FROM robot_reports LIMIT 5;
SELECT COUNT(*) FROM robot_reports_extended;
SELECT * FROM robot_reports_extended LIMIT 5;
DESC builds_info;
DESC robot_reports;
DESC robot_reports_extended;
SHOW CREATE TABLE builds_info;
SHOW CREATE TABLE robot_reports;
SHOW CREATE TABLE robot_reports_extended;
exit;

# (optional) METHOD 2: Use a temporary job to check that data was properly imported
kubectl apply -f ./k8s/manifests/tests/db-provisioning-check.yaml
kubectl get job/db-provisioning-check -n database
printf "$(kubectl logs job/db-provisioning-check -n database)"
kubectl delete -f ./k8s/manifests/tests/db-provisioning-check.yaml

# Kill port-forward
pkill -f "kubectl port-forward service/osm-metrics -n database"
```

#### **Step 6.** (optional) Test workflow templates using sample workflow

```bash
# Check that the WorkflowTemplates exist
kubectl get WorkFlowTemplate -n workflow-runs

# Submit a workflow to generate the installations report
argo submit -n workflow-runs --watch ./k8s/manifests/tests/launcher-installations-report.yaml
## Check logs
argo logs -n workflow-runs -f @latest
argo get -n workflow-runs @latest

# Submit a workflow to generate the Bugzilla report
argo submit -n workflow-runs --watch ./k8s/manifests/tests/launcher-bugzilla-report.yaml
## Check logs
argo logs -n workflow-runs -f @latest
argo get -n workflow-runs @latest

# Submit a workflow to generate the Jenkins report
argo submit -n workflow-runs --watch ./k8s/manifests/tests/launcher-jenkins-report.yaml
## Check logs
argo logs -n workflow-runs -f @latest
argo get -n workflow-runs @latest

# List the workflows
argo list -n workflow-runs

# Acccess the web interface to inspect the workflows
kubectl -n argo port-forward svc/argo-server 2746:2746
# Then access <https://localhost:2746> and Ctrl+C when done.
```

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
## Source environment variables in case we had release names there
[ -f .env ] && source .env || echo ".env file does not exist. Skipping..."
OSM_ANALYTICS_IMAGE=${OSM_ANALYTICS_IMAGE:-"osm-analytics"}
DOCKER_REPO=${DOCKER_REPO:-"ttl.sh"}
DOCKER_SDK_TAG=${DOCKER_SDK_TAG:-"24h"}

# Container for regular execution
FULL_IMAGE_NAME=${DOCKER_REPO}/${OSM_ANALYTICS_IMAGE}:${DOCKER_SDK_TAG}
FULL_IMAGE_NAME_LATEST=${DOCKER_REPO}/${OSM_ANALYTICS_IMAGE}:latest
echo "${FULL_IMAGE_NAME}"
echo "${FULL_IMAGE_NAME_LATEST}"

# Container for local development
FULL_DEV_IMAGE_NAME=${DOCKER_REPO}/${OSM_ANALYTICS_IMAGE}-dev:${DOCKER_SDK_TAG}
FULL_DEV_IMAGE_NAME_LATEST=${DOCKER_REPO}/${OSM_ANALYTICS_IMAGE}-dev:${DOCKER_SDK_TAG}
echo "${FULL_DEV_IMAGE_NAME}"
echo "${FULL_DEV_IMAGE_NAME_LATEST}"
```

Now we can pull or build the containers as needed.

In case we needed to build them locally:

```bash
# Option A) Normal build
docker build -t ${FULL_IMAGE_NAME_LATEST} .
docker tag ${FULL_IMAGE_NAME_LATEST} ${FULL_IMAGE_NAME}
# Option B) Build with non-pinned dependencies
# docker build -t ${FULL_IMAGE_NAME} --build-arg ENVFILE=environment-docker.yml .
# Option C) Build including Jupyter Lab
docker build -t ${FULL_DEV_IMAGE_NAME_LATEST} --build-arg DEVELOPMENT=true .
docker tag ${FULL_DEV_IMAGE_NAME_LATEST} ${FULL_DEV_IMAGE_NAME}
```

In case we wanted to push it as a release:

```bash
# Assuming we have GHCR_PAT and USERNAME set in the environment
echo ${GHCR_PAT} | docker login ghcr.io -u ${USERNAME} --password-stdin
docker push ${FULL_IMAGE_NAME_LATEST}
## If we want to create a new release
docker push ${FULL_IMAGE_NAME}
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

## ANNEX A: Database debugging

### A.1 Check if the database is up and accesible

```bash
# Retrieve root credentials
export DB_ROOT_USER=$(
  kubectl get secret/osm-metrics \
    -n database \
    -o jsonpath="{.data.rootUser}" \
  | base64 --decode
)
export DB_ROOT_PASSWORD=$(
  kubectl get secret/osm-metrics \
    -n database \
    -o jsonpath="{.data.rootPassword}" \
  | base64 --decode
)
echo ${DB_ROOT_USER}
echo ${DB_ROOT_PASSWORD}

# Using official MySQL client image, any namespace
# NOTE: You may need to press ENTER to see the prompt
kubectl run --rm -it myshell \
  --image=mysql:9.5.0 \
  -n workflow-runs \
  --env="DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}" \
  -- mysql -h osm-metrics.database.svc.cluster.local -u "${DB_ROOT_USER}" -p"${DB_ROOT_PASSWORD}"

# ALTERNATIVE: Using Oracle's operator image, any namespace
kubectl run --rm -it myshell \
  --image=container-registry.oracle.com/mysql/community-operator \
  -n workflow-runs \
  --env="DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}" \
  -- mysqlsh --password="${DB_ROOT_PASSWORD}" "${DB_ROOT_USER}@osm-metrics.database.svc.cluster.local"
```

### A.2 Re-run database provisioning job

This job provisions the database by:

- Creating the user.
- Creating the database (empty).
- Granting privileges to the user over the database.

```bash
# Re-create the job for unattended execution
kubectl delete job/db-provisioning -n database || true
kubectl apply -f ./k8s/manifests/tests/db-provisioning-job.yaml

# Check execution
kubectl get job -n database
kubectl logs job/db-provisioning -n database
kubectl describe job/db-provisioning -n database
```

### A.3 **DANGEROUS:** Revert all provisioning, by removing the database and the new user

```bash
kubectl apply -f ./k8s/manifests/tests/db-DELETE-provisioning-job.yaml
db-provisioning-delete
kubectl get job -n database
kubectl logs job/db-provisioning-delete -n database
kubectl describe job/db-provisioning-delete -n database
kubectl delete job/db-provisioning-delete -n database
```

Now we would be ready to re-run the provisioning job again if needed (see previous section).

### A.4 Interactive debugging

Example: List the tables in the database:

```bash
# First create a temporary job that mounts the secret with the credentials and then attach to it to run commands interactively
kubectl apply -f ./k8s/manifests/tests/db-interactive-shell-job.yaml
kubectl attach -it job/myshell -n database

# --------------- Inside the container ---------------
## Undo any provisioning if needed
mysql -h osm-metrics.database.svc.cluster.local -u "${stdUser}" -p"${stdPassword}"
# mysql -h osm-metrics.database.svc.cluster.local -u "${rootUser}" -p"${rootPassword}"
USE osm_metrics_db;
SHOW TABLES;
exit;
exit
# ----------------------------------------------------

# When the temporary job is no longer needed, delete it
kubectl delete job/myshell -n database
```

## ANNEX B: Database backup

This annex focuses on procedures for database backup. For database restoration, refer to [**Step 5.** (optional) Pre-populate the database with data of former Jenkins builds (if applicable)](#step-5-optional-pre-populate-the-database-with-data-of-former-jenkins-builds-if-applicable).

### B.1 From the old database (VM-based installation)

```bash
# Retrieve root password (user was always `root` in the old installation)
REMOTE_KUBECONFIG="../.credentials/osm-metrics-OLD-kubeconfig.yaml"
OLD_DB_ROOT_PASSWORD=$(
  kubectl get secret mysql-metrics \
  --namespace default \
  --kubeconfig="${REMOTE_KUBECONFIG}" \
  -o jsonpath="{.data.mysql-root-password}" \
  | base64 --decode
)
echo "${OLD_DB_ROOT_PASSWORD}"

# Folder to save backups
mkdir -p ../.credentials/backups

## Run the port-forward in background
OLD_SOURCE_DB_PORT=3306
# OLD_SOURCE_DB_PORT=30306
OLD_FWD_DB_PORT=30306
kubectl port-forward service/mysql-metrics \
  -n default \
  --kubeconfig="${REMOTE_KUBECONFIG}" \
  ${OLD_FWD_DB_PORT}:${OLD_SOURCE_DB_PORT} &

## Dump database
BACKUP_FILE="../.credentials/backups/osm_metrics_db.sql.gz"
mysqldump -u root -p"${OLD_DB_ROOT_PASSWORD}" -h 127.0.0.1 -P ${OLD_FWD_DB_PORT} osm_metrics_db \
| gzip > "${BACKUP_FILE}"

# Kill port-forward
pkill -f "kubectl port-forward service/mysql-metrics"
```

However, note that this database backup will need some modifications before being used in the new Kubernetes-based installation, which have additional restrictions to comply and requires the addition of `AUTO_INCREMENT PRIMARY KEY` columns in the tables. In order to fix it, we will need to use the script `k8s/tools/modernize-database.sh` to generate an updated database dump:

```bash
# Create a copy of the original dump file and extract it
BACKUP_FILE="../.credentials/backups/osm_metrics_db.sql.gz"
ORIGINAL_BACKUP_FILE="../.credentials/backups/osm_metrics_db_ORIGINAL.sql.gz"
mv "${BACKUP_FILE}" "${ORIGINAL_BACKUP_FILE}"
gzip -d --keep "${ORIGINAL_BACKUP_FILE}"

# Postprocess the dump to add the required columns
./k8s/tools/modernize-database.sh "../.credentials/backups/osm_metrics_db_ORIGINAL.sql" "../.credentials/backups/osm_metrics_db.sql"

# Finally, compress the updated dump and remove the uncompressed version of the original
gzip ../.credentials/backups/osm_metrics_db.sql
# gzip --keep ../.credentials/backups/osm_metrics_db.sql
rm ../.credentials/backups/osm_metrics_db_ORIGINAL.sql
```

### B.2 From the new database (Kubernetes-based installation)

```bash
# Retrieve root credentials
export SOURCE_DB_ROOT_USER=$(
  kubectl get secret/osm-metrics \
    -n database \
    -o jsonpath="{.data.rootUser}" \
  | base64 --decode
)
export SOURCE_DB_ROOT_PASSWORD=$(
  kubectl get secret/osm-metrics \
    -n database \
    -o jsonpath="{.data.rootPassword}" \
  | base64 --decode
)
echo ${SOURCE_DB_ROOT_USER}
echo ${SOURCE_DB_ROOT_PASSWORD}

# Folder to save backups
mkdir -p ../.credentials/backups

# Run the port-forward in background
SOURCE_DB_PORT=3306
FWD_DB_PORT=33060
kubectl port-forward service/osm-metrics -n database ${FWD_DB_PORT}:${SOURCE_DB_PORT} &
## (optional) Check that the connection is ready and stable
mysql -u ${SOURCE_DB_ROOT_USER} -p"${SOURCE_DB_ROOT_PASSWORD}" -h 127.0.0.1 -P ${FWD_DB_PORT} osm_metrics_db

## Dump database
BACKUP_FILE="../.credentials/backups/osm_metrics_db.sql.gz"
mysqldump -u ${SOURCE_DB_ROOT_USER} -p"${SOURCE_DB_ROOT_PASSWORD}" -h 127.0.0.1 -P ${FWD_DB_PORT} --set-gtid-purged=OFF --single-transaction osm_metrics_db \
| gzip > "${BACKUP_FILE}"

# Kill port-forward
pkill -f "kubectl port-forward service/mysql-metrics"
```

## ANNEX C: Troubleshooting

Before beginning any troubleshooting session, make sure that the kubeconfig for the target cluster is properly enabled:

```bash
source k8s/manifests/${TARGET_ENVIRONMENT}/config/k8s_vms_info.rc || true
KUBECONFIG_NAME="${VMS_K8S_NAME}-kubeconfig.yaml"
export KUBECONFIG="k8s/manifests/${TARGET_ENVIRONMENT}/config/${KUBECONFIG_NAME}"
export KUBECONFIG="$(readlink -f ${KUBECONFIG})"

# (optional) Check
kubectl get ns
```

### C.1 Container troubleshooting

For troubleshooting each of the processings, there are specific `deployment` definitions which also mount the required `ConfigMaps` and `Secrets` required for each case:

```bash
$ ls -1 k8s/manifests/tests/troubleshoot-*
k8s/manifests/tests/troubleshoot-bugzilla-analytics.yaml
k8s/manifests/tests/troubleshoot-installations-analytics.yaml
k8s/manifests/tests/troubleshoot-jenkins-analytics.yaml
```

For instance, if we wanted to troubleshoot the **Jenkins analytics** in the target cluster, we might proceed as follows:

```bash
kubectl apply -f k8s/manifests/tests/troubleshoot-jenkins-analytics.yaml
kubectl get all -n workflow-runs
kubectl exec -it deploy/jenkins-analytics-troubleshoot -n workflow-runs -- bash
# kubectl delete -f k8s/manifests/tests/troubleshoot-jenkins-analytics.yaml
```

In case we needed to debug one of the Notebooks, we might proceed as follows:

```bash
# Enter the container
kubectl exec -it deploy/jenkins-analytics-troubleshoot -n workflow-runs -- bash

# ------ Inside the container ------

# Install Jupyter
conda install jupyter -y

# Then launch the notebook
# jupyter notebook \
jupyter lab --notebook-dir=/osm-analytics --ip='*' --port=8888 --no-browser --allow-root &

# Exit, so that we can access from outside
exit
```

Now, we can access from our browser as follows:

```bash
# (optional) Check that Jupyter is active
kubectl exec -it deploy/jenkins-analytics-troubleshoot -n workflow-runs -- jupyter server list

# Create a port forward, so that it is accessible
kubectl port-forward deploy/jenkins-analytics-troubleshoot -n workflow-runs 8888:8888 &

# Get the Notebook token
NOTEBOOK_TOKEN=$(
  kubectl exec -it deploy/jenkins-analytics-troubleshoot -n workflow-runs -- jupyter server list --jsonlist \
  | jq -r '.[0].token'
)
# Open the URL:
echo "http://localhost:8888/?token=${NOTEBOOK_TOKEN}"

# Do troubleshooting here
# ...
```

Once finished, drop the port forward and remove the debug deployment:

```bash
pkill -f "kubectl port-forward deploy/jenkins-analytics-troubleshoot -n workflow-runs 8888:8888"
kubectl delete -f k8s/manifests/tests/troubleshoot-jenkins-analytics.yaml
```

### C.2 Database troubleshooting

#### C.2.1 From the `jenkins-analytics-troubleshoot` container

```bash
# Create the container if unavailable
kubectl apply -f k8s/manifests/tests/troubleshoot-jenkins-analytics.yaml
kubectl get all -n workflow-runs

# Enter the container
kubectl exec -it deploy/jenkins-analytics-troubleshoot -n workflow-runs -- bash

# ------ Inside the container ------

# Install MySQL client
apt update
apt install -y default-mysql-client

# Connect
# mysql -u "${stdUser}" -p"${stdPassword}" -P 3306 -h 127.0.0.1 osm_metrics_db
mysql -u "${stdUser}" -p"${stdPassword}" -P 3306 -h osm-metrics.database.svc.cluster.local osm_metrics_db
SHOW TABLES;
SELECT COUNT(*) FROM builds_info;
SELECT * FROM builds_info LIMIT 5;
exit;

# Exit the container
exit
```

Once finished the troubleshoting, drop the port forward and remove the debug deployment:

```bash
pkill -f "kubectl port-forward deploy/jenkins-analytics-troubleshoot -n workflow-runs 8888:8888"
kubectl delete -f k8s/manifests/tests/troubleshoot-jenkins-analytics.yaml
```

#### C.2.2 From your desktop

```bash
# Retrieve user's credentials
export DB_STD_USER=$(
  kubectl get secret/osm-metrics \
    -n database \
    -o jsonpath="{.data.stdUser}" \
  | base64 --decode
)
export DB_STD_PASSWORD=$(
  kubectl get secret/osm-metrics \
    -n database \
    -o jsonpath="{.data.stdPassword}" \
  | base64 --decode
)
echo ${DB_STD_USER}
echo ${DB_STD_PASSWORD}

# Create a port-forward to access the database from the client machine
## (optional) Inspect the service
kubectl get service/osm-metrics -n database
## Run the port-forward in background
SOURCE_DB_PORT=3306
FWD_DB_PORT=33060
kubectl port-forward service/osm-metrics -n database ${FWD_DB_PORT}:${SOURCE_DB_PORT} &

# Connect to the database
mysql -u "${DB_STD_USER}" -p"${DB_STD_PASSWORD}" -P ${FWD_DB_PORT} -h 127.0.0.1 osm_metrics_db
SHOW TABLES;
SELECT COUNT(*) FROM builds_info;
SELECT * FROM builds_info LIMIT 5;
SELECT COUNT(*) FROM robot_reports;
SELECT * FROM robot_reports LIMIT 5;
SELECT COUNT(*) FROM robot_reports_extended;
SELECT * FROM robot_reports_extended LIMIT 5;
exit;
```

Once finished the troubleshooting, finish the port-forward:

```bash
pkill -f "kubectl port-forward service/osm-metrics -n database"
```

