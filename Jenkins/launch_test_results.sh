#!/bin/bash

# Sets script's folder as working directory
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
pushd "$dir" > /dev/null

# Environment variables to let the script to assume some tasks performed by the Notebook by default
export SKIP_DATABASE_UPDATE=True
export SKIP_EXPORT_TO_HTML=True

# Refresh the database with the latest Jenkins builds
echo "Refreshing database..."
python ./00-script-jenkins_and_robot_etl.py

# Run the Jupyter notebook and export as HTML report
jupyter nbconvert --to html --output report_outputs/analysis_of_test_results.html --TemplateExporter.exclude_input=True --execute 01-analysis_of_test_results.ipynb

popd > /dev/null
