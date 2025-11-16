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
OUTPUTS_FOLDER=${OUTPUTS_FOLDER:-"outputs"}
KEY_FILE_NAME=${KEY_FILE_NAME:-"bugzilla_analysis.html"}
REMOTE_BASE_FOLDER=${REMOTE_BASE_FOLDER:-"analytics/bugs"}

# Environment variables to let the script to assume some tasks performed by the Notebook by default
export SKIP_EXPORT_TO_HTML=True

# Unless explicitly prevented, updates the report
if [ -z ${SKIP_ALL_UPDATES} ]; then
    # Move former .XLSX spreadsheets to another folder
    mv ${OUTPUTS_FOLDER}/*.xlsx xlsx-outputs/ || true

    # Run the Jupyter notebook and export as HTML report
    jupyter nbconvert --to html --output ${OUTPUTS_FOLDER}/${KEY_FILE_NAME} --TemplateExporter.exclude_input=True --execute bugzilla_analysis.ipynb
else
    echo "Skipping report update..."
fi

# If requested (i.e. `UPLOAD_REPORT` is defined), uploads the results to the FTP
if [ ! -z ${UPLOAD_REPORT} ]; then
    echo "Uploading report to FTP..."
    TIMESTAMP=$(date '+%Y%m%d_%H%M')

    # FTP uploader is "sourced" in a contained environment to inherit all the
    # current environment but preventing potential env modifications
    ( source ../ftp_uploader.sh "${OUTPUTS_FOLDER}" ${TIMESTAMP} "${KEY_FILE_NAME}" )
fi

popd > /dev/null

