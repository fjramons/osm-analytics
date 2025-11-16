# README  - Jenkins and Robot analysis

## Usage

Open and run the `01-analysis_of_test_results.ipynb` notebook. The results will be published in the `report_outputs` folder:

- `analysis_of_test_results.html`: Full report.
- `*.png`, `*.svg`: Figures extracted from the report.

It can also be executed from the command line as:

```bash
jupyter nbconvert --to html --output report_outputs/analysis_of_test_results.html --TemplateExporter.exclude_input=True --execute 01-analysis_of_test_results.ipynb
```

In case only a refresh of the database is intended, then just do:

```bash
./00-script-jenkins_and_robot_etl.py
```

### Unattended execution

UNIX/OSX/Linux:

```bash
./launch_test_results.sh
```

Windows:

```powershell
launch_test_results.cmd
```

### From Docker container

First, load all the required variables, to ease the work:

```bash
# Lock to this very folder
HERE="${PWD}"

# Variables to access Jenkins
URL_JENKINS_SERVER="https://osm.etsi.org/jenkins"
## Sensitive data
# JENKINS_USER=
# JENKINS_PASS=

# Jobs to watch
JOB_IDS='["master", "v17.0", "v16.0", "v15.0", "v14.0"]'
JOB_NAMES='["Master branch", "Release SEVENTEEN", "Release SIXTEEN", "Release FIFTEEN", "Release FOURTEEN"]'
## OSM's defaults - Touch only for other Jenkins servers/jobs
JOB_IDS_PREFIX='osm-stage_3-merge/'
LINK_TO_BUILD="https://osm.etsi.org/jenkins/view/Robot%20tests/job/{stage}/job/{branch}/{build}/"
LINK_TO_REPORT="https://osm.etsi.org/jenkins/view/Robot%20tests/job/{stage}/job/{branch}/{build}/robot/report/report.html"

# Time period to analyse
TOO_OLD_BUILDS="2023-12-15"
DAYS_SINCE_TODAY_4_ANALYSIS="21"

# Variables to connect to the database
ETL_OUTPUTS_FOLDER=etl_outputs
DATABASE_URI="sqlite:///${ETL_OUTPUTS_FOLDER}/test_executions.db"
## DATABASE_URI for MySQL (SENSITIVE VALUE)
# DATABASE_URI="mysql+pymysql://${MYSQL_USER}:${MYSQL_USER_PASSWORD}@127.0.0.1:30306/osm_metrics_db"

# Variables to upload to the FTP server (as needed)
## OSM's case
FTP_SERVER="ftp://osm-download.etsi.org"
REMOTE_BASE_FOLDER="analytics/cicd"
## FTP_USERNAME=<sensitive>
## FTP_PASSWORD=<sensitive>

# Time zone to timestamp the reports
TIME_ZONE="Europe/Paris"

## Flags
## - If the variable is defined AND is "Yes" or "True" (case insensitive), the flag is true.
## - If the variable is not defined OR is "No" or "False" (case insensitive), the flag is false.
#
SKIP_DATABASE_UPDATE="False"
SKIP_EXPORT_TO_HTML="False"
UPLOAD_REPORT="True"
#
## NOTE: The default behaviour is that:
## - The notebook can run any task interactively, i.e.,
##   - It can update the database
##   - I can export to HTML directly from one of its cells.
## - This is ok also fo the script, since, whenever is invoked, it will override both variables to "True", so that it assumes these two tasks instead of the own notebook.
## - In addition, in case script is invoked interactively, it should try to upload the report to the FTP server

## Folder to save the HTML report (do not touch)
REPORT_OUTPUTS_FOLDER="report_outputs"

## Other variables to change behaviour (do not touch)
TABLE_KNOWN_BUILDS="builds_info"
TABLE_ROBOT_REPORTS="robot_reports"
TABLE_ROBOT_REPORTS_EXTENDED="robot_reports_extended"


## REMINDER: SECRET VALUES:
## Sourcing this file is expected to load the contents of:
## - `JENKINS_USER`
## - `JENKINS_PASS`
## - `FTP_USERNAME`
## - `FTP_PASSWORD`
## - (optionally) `DATABASE_URI` if it includes a database password
# source ../.env
```

As shortcut, you can simply define the docker image name and source these two files for development purposes:

```bash
# Load all required environment variables
# set -a
source init-dev.rc
[ -f ../.env ] && source ../.env || echo ".env file does not exist. Skipping..."
# set +a

# Image name
OSM_ANALYTICS_IMAGE=${OSM_ANALYTICS_IMAGE:-"osm-analytics"}
DOCKER_REPO=${DOCKER_REPO:-"ttl.sh"}
DOCKER_SDK_TAG=${DOCKER_SDK_TAG:-"24h"}
FULL_IMAGE_NAME=${DOCKER_REPO}/${OSM_ANALYTICS_IMAGE}:${DOCKER_SDK_TAG}
```

#### Option A) Interactive execution (testing only)

Then, launch the container:

```bash
# Run the container mounting local folders and setting environment variables
docker run --rm -it \
  --tmpfs /osm-analytics/Jenkins/inputs \
  -v "${HERE}/${ETL_OUTPUTS_FOLDER}":/osm-analytics/Jenkins/etl_outputs \
  -v "${HERE}/${REPORT_OUTPUTS_FOLDER}":/osm-analytics/Jenkins/report_outputs \
  -e TZ="${TZ:-"${TIME_ZONE}"}" \
  -e URL_JENKINS_SERVER="${URL_JENKINS_SERVER}" \
  -e JOB_IDS="${JOB_IDS}" \
  -e JOB_NAMES="${JOB_NAMES}" \
  -e JOB_IDS_PREFIX=${JOB_IDS_PREFIX} \
  -e LINK_TO_BUILD=${LINK_TO_BUILD} \
  -e LINK_TO_REPORT=${LINK_TO_REPORT} \
  -e TOO_OLD_BUILDS=${TOO_OLD_BUILDS} \
  -e DAYS_SINCE_TODAY_4_ANALYSIS=${DAYS_SINCE_TODAY_4_ANALYSIS} \
  -e ETL_OUTPUTS_FOLDER=${ETL_OUTPUTS_FOLDER} \
  -e DATABASE_URI=${DATABASE_URI} \
  -e SKIP_DATABASE_UPDATE=${SKIP_DATABASE_UPDATE} \
  -e SKIP_EXPORT_TO_HTML=${SKIP_EXPORT_TO_HTML} \
  -e UPLOAD_REPORT=${UPLOAD_REPORT} \
  -e REPORT_OUTPUTS_FOLDER=${REPORT_OUTPUTS_FOLDER} \
  -e TABLE_KNOWN_BUILDS=${TABLE_KNOWN_BUILDS} \
  -e TABLE_ROBOT_REPORTS=${TABLE_ROBOT_REPORTS} \
  -e TABLE_ROBOT_REPORTS_EXTENDED=${TABLE_ROBOT_REPORTS_EXTENDED} \
  -e FTP_SERVER=${FTP_SERVER} \
  -e REMOTE_BASE_FOLDER=${REMOTE_BASE_FOLDER} \
  -e JENKINS_USER=${JENKINS_USER} \
  -e JENKINS_PASS=${JENKINS_PASS} \
  -e FTP_USERNAME=${FTP_USERNAME} \
  -e FTP_PASSWORD=${FTP_PASSWORD} \
  ${FULL_IMAGE_NAME} \
  bash

# Alternatively, you may prefer using temporary folders, particularly if you plan to upload only fresh contents to the FTP
## This technique may also be useful if you are connecting to a remote database instead of SQLite, since no local DB file is needed at `etl_outputs/`.
# docker run --rm -it \
#   --tmpfs /osm-analytics/Jenkins/inputs \
#   --tmpfs /osm-analytics/Jenkins/etl_outputs \
#   --tmpfs :/osm-analytics/Jenkins/report_outputs \
#   # All environment variables would go here
#   . . .
#   . . .
#   . . .
#   ${FULL_IMAGE_NAME} \
#   bash
```

From within the container, we will run the required commands.

We have two options:

##### A.1) Run with script

```bash
# Run all-in-one script
Jenkins/launch_test_results.sh

# Exit from the container
exit

# Ensure the generated files are owned by the user
sudo chown -R $(id -u):$(id -g) "${HERE}/etl_outputs"
sudo chown -R $(id -u):$(id -g) "${HERE}/report_outputs"
```

##### A.2) Run step by step

```bash
# Move to the processing folder
cd Jenkins

# Refresh database
python ./00-script-jenkins_and_robot_etl.py

# Run the Jupyter notebook and export as HTML report
jupyter nbconvert --to html --output report_outputs/analysis_of_test_results.html --TemplateExporter.exclude_input=True --execute 01-analysis_of_test_results.ipynb

# Upload the results to the FTP
TIMESTAMP=$(date '+%Y%m%d_%H%M')
( source ../ftp_uploader.sh "${OUTPUTS_FOLDER}" ${TIMESTAMP} "analysis_of_test_results.html" )

# Exit from the container
exit

# Ensure the generated files are owned by the user
sudo chown -R $(id -u):$(id -g) "${HERE}/etl_outputs"
sudo chown -R $(id -u):$(id -g) "${HERE}/report_outputs"
```

#### Option B) Unattended execution

```bash
docker run --rm -it \
  --tmpfs /osm-analytics/Jenkins/inputs \
  -v "${HERE}/${ETL_OUTPUTS_FOLDER}":/osm-analytics/Jenkins/etl_outputs \
  -v "${HERE}/${REPORT_OUTPUTS_FOLDER}":/osm-analytics/Jenkins/report_outputs \
  -e TZ="${TZ:-"${TIME_ZONE}"}" \
  -e URL_JENKINS_SERVER="${URL_JENKINS_SERVER}" \
  -e JOB_IDS="${JOB_IDS}" \
  -e JOB_NAMES="${JOB_NAMES}" \
  -e JOB_IDS_PREFIX=${JOB_IDS_PREFIX} \
  -e LINK_TO_BUILD=${LINK_TO_BUILD} \
  -e LINK_TO_REPORT=${LINK_TO_REPORT} \
  -e TOO_OLD_BUILDS=${TOO_OLD_BUILDS} \
  -e DAYS_SINCE_TODAY_4_ANALYSIS=${DAYS_SINCE_TODAY_4_ANALYSIS} \
  -e ETL_OUTPUTS_FOLDER=${ETL_OUTPUTS_FOLDER} \
  -e DATABASE_URI=${DATABASE_URI} \
  -e SKIP_DATABASE_UPDATE=${SKIP_DATABASE_UPDATE} \
  -e SKIP_EXPORT_TO_HTML=${SKIP_EXPORT_TO_HTML} \
  -e UPLOAD_REPORT=${UPLOAD_REPORT} \
  -e REPORT_OUTPUTS_FOLDER=${REPORT_OUTPUTS_FOLDER} \
  -e TABLE_KNOWN_BUILDS=${TABLE_KNOWN_BUILDS} \
  -e TABLE_ROBOT_REPORTS=${TABLE_ROBOT_REPORTS} \
  -e TABLE_ROBOT_REPORTS_EXTENDED=${TABLE_ROBOT_REPORTS_EXTENDED} \
  -e FTP_SERVER=${FTP_SERVER} \
  -e REMOTE_BASE_FOLDER=${REMOTE_BASE_FOLDER} \
  -e JENKINS_USER=${JENKINS_USER} \
  -e JENKINS_PASS=${JENKINS_PASS} \
  -e FTP_USERNAME=${FTP_USERNAME} \
  -e FTP_PASSWORD=${FTP_PASSWORD} \
  ${FULL_IMAGE_NAME} \
  Jenkins/launch_test_results.sh

# Alternatively, you may prefer using temporary folders, particularly if you plan to upload only fresh contents to the FTP
## This technique may also be useful if you are connecting to a remote database instead of SQLite, since no local DB file is needed at `etl_outputs/`.
# docker run --rm -it \
#   --tmpfs /osm-analytics/Jenkins/inputs \
#   --tmpfs /osm-analytics/Jenkins/etl_outputs \
#   --tmpfs :/osm-analytics/Jenkins/report_outputs \
#   # All environment variables would go here
#   . . .
#   . . .
#   . . .
#   ${FULL_IMAGE_NAME} \
#   Jenkins/launch_test_results.sh
```

## Environment variables

Default behaviours can be changed by setting specific environment variables:

- `INPUTS_FOLDER`: Folder where input data is located.
  - If not set, it will be the `etl_outputs` subfolder.
- `SKIP_DATABASE_UPDATE`: If set, the database update from Jenkins is skipped.
- `SKIP_EXPORT_TO_HTML`: If set, the Notebook is not exported to HTML.
- `DATABASE_URI`: URI of the database where historical Jenkins runs are stored.
  - If not set, the URI will correspond to the following SQLite location: `f'sqlite:///{inputs_folder}/test_executions.db'`
- `JENKINS_USER`: Username to access the Jenkins server. If not set, the user will be prompted interactively.
- `JENKINS_PASS`: Password to access the Jenkins server. If not set, the user will be prompted interactively.
- `OUTPUTS_FOLDER`: Folder to save results.
  - If not set, it will use the `report_outputs` subfolder.
- `TABLE_KNOWN_BUILDS`: Name of the table in the database that saves the historical series of builds.
  - If not set, it will use the `builds_info` table.
- `TABLE_ROBOT_REPORTS`: Name of the table in the database that saves basic information of the Robot reports.
  - If not set, it will use the `robot_reports` table.
- `TABLE_ROBOT_REPORTS_EXTENDED`: Name of the table in the database that saves extended information of the Robot reports.
  - If not set, it will be the `robot_reports_extended` table.
- `TOO_OLD_BUILDS`: Only builds after this date will be considered in the analysis.
  - If not set, it will take `2020-12-15` as limit date.
- `LINK_TO_BUILD`: Format of the URL of a specific build, given the `stage`, the `branch` and the `build` number.
  - If not set, it will use `"https://osm.etsi.org/jenkins/view/Robot%20tests/job/{stage}/job/{branch}/{build}/"` as URL format.
- `LINK_TO_REPORT`: Format of the URL of a specific Robot report, given the `stage`, the `branch` and the `build` number.
  - If not set, it will use `"https://osm.etsi.org/jenkins/view/Robot%20tests/job/{stage}/job/{branch}/{build}/robot/report/report.html"` as URL format.
- `DAYS_SINCE_TODAY_4_ANALYSIS`: If defined, it is used as the number of days considered in the charts of the report, including today.
  - If not set, it will consider a window of **21** days up to the current day.
- `JOB_IDS`: List of jobs/branches considered in the analysis.
  - If not set, the following list will be used: `['master', 'v16.0', 'v15.0', 'v14.0']`
- `JOB_NAMES`: List of human-readable jobs/branches considered in the analysis.
  - If not set, the following list will be used: `['Master branch', 'Release SIXTEEN', 'Release FIFTEEN', 'Release FOURTEEN']`
- `FIRST_DATE`: If defined, it is used to define the oldest date considered in the charts of the report. When defined, it overrides the window defined by `DAYS_SINCE_TODAY_4_ANALYSIS`.
- `LAST_DATE`: If defined, it is used to define the latest date considered in the charts of the report. If not defined, it will be set to the current day (`today`).

