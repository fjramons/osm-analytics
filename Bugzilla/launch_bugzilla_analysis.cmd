:: Launches Bugzilla analysis
@ECHO OFF

REM Sets the Anaconda/Conda environment
CALL conda activate osm-analytics

REM Sets script's folder as working directory
PUSHD "%~dp0"

REM Environment variables to let the script to assume some tasks performed by the Notebook by default
SET SKIP_EXPORT_TO_HTML=True

REM Run the Jupyter notebook and export as HTML report
jupyter nbconvert --to html --output outputs/bugzilla_analysis.html --TemplateExporter.exclude_input=True --execute bugzilla_analysis.ipynb

POPD
