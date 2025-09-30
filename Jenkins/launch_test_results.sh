#!/bin/bash

# If not in the container...
if [[ -z "${IN_CONTAINER}" ]]; then
    # ... sets the Anaconda/Conda environment
    eval "$(conda shell.bash hook)"
    conda activate osm-analytics

    # ... and loads some environment variables
    source ../.env
fi

# Sets script's folder as working directory
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
pushd "$dir" > /dev/null

# Inputs: Folder and file names
export REPORT_OUTPUTS_FOLDER=${REPORT_OUTPUTS_FOLDER:-"report_outputs"}
export REMOTE_BASE_FOLDER=${REMOTE_BASE_FOLDER:-"analytics/cicd"}
export KEY_FILE_NAME=${KEY_FILE_NAME:-"analysis_of_test_results.html"}

# Environment variables to let the script assume some tasks performed by the Notebook by default
export SKIP_DATABASE_UPDATE=True
export SKIP_EXPORT_TO_HTML=True

# Unless explicitly prevented, updates the report
if [ -z ${SKIP_ALL_UPDATES} ]; then
    # In case there are special credentials for Jenkins and the database, it sources them
    [ -f inputs/env.rc ] && source inputs/env.rc

    # Refresh the database with the latest Jenkins builds
    echo "Refreshing database..."
    python ./00-script-jenkins_and_robot_etl.py

    # Run the Jupyter notebook and export as HTML report
    jupyter nbconvert --to html --output report_outputs/analysis_of_test_results.html --TemplateExporter.exclude_input=True --execute 01-analysis_of_test_results.ipynb
else
    echo "Skipping report update..."
fi

# If requested (i.e. `UPLOAD_REPORT` is defined), uploads the results to the FTP
if [ ! -z ${UPLOAD_REPORT} ]; then
    echo "Uploading report to FTP..."
    [ -f ../.env ] && source ../.env
    TIMESTAMP=$(date '+%Y%m%d_%H%M')

    # FTP uploader is "sourced" in a contained environment to inherit all the
    # current environment but preventing potential env modifications
    ( source ../ftp_uploader.sh "${REPORT_OUTPUTS_FOLDER}" ${TIMESTAMP} "${KEY_FILE_NAME}" )
fi

popd > /dev/null
