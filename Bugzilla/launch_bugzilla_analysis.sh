#!/bin/bash

# Sets the Anaconda/Conda environment
eval "$(conda shell.bash hook)"
conda activate osm-analytics

# Sets script's folder as working directory
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
pushd "$dir" > /dev/null

# Inputs: Folder and file names
OUTPUTS_FOLDER=outputs
REMOTE_BASE_FOLDER=analytics/bugs
KEY_FILE_NAME=bugzilla_analysis.html

# Environment variables to let the script to assume some tasks performed by the Notebook by default
export SKIP_EXPORT_TO_HTML=True

# Unless explicitly prevented, updates the report
if [ -z ${SKIP_ALL_UPDATES} ]; then
    # Move former .XLSX spreadsheets to another folder
    mv outputs/*.xlsx xlsx-outputs/

    # Run the Jupyter notebook and export as HTML report
    jupyter nbconvert --to html --output outputs/bugzilla_analysis.html --TemplateExporter.exclude_input=True --execute bugzilla_analysis.ipynb
else
    echo "Skipping report update..."
fi

# If requested (i.e. `UPLOAD_REPORT` is defined), uploads the results to the FTP
if [ ! -z ${UPLOAD_REPORT} ]; then
    echo "Uploading report to FTP..."
    source ../.env
    TIMESTAMP=$(date '+%Y%m%d_%H%M')

    # FTP uploader is "sourced" in a contained environment to inherit all the
    # current environment but preventing potential env modifications
    ( source ../ftp_uploader.sh "${OUTPUTS_FOLDER}" ${TIMESTAMP} "${KEY_FILE_NAME}" )
fi

popd > /dev/null
