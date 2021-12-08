#!/bin/bash

# Sets the Anaconda/Conda environment
eval "$(conda shell.bash hook)"
conda activate osm-analytics

# Sets script's folder as working directory
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
pushd "$dir" > /dev/null

# Environment variables to let the script to assume some tasks performed by the Notebook by default
export SKIP_EXPORT_TO_HTML=True

# Run the Jupyter notebook and export as HTML report
jupyter nbconvert --to html --output outputs/bugzilla_analysis.html --TemplateExporter.exclude_input=True --execute bugzilla_analysis.ipynb

popd > /dev/null
