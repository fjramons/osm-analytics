:: Launches the Jupyter Notebook with the analysis of test results
@ECHO OFF

REM Sets script's folder as working directory
PUSHD "%~dp0"

REM Environment variables to let the script to assume some tasks performed by the Notebook by default
SET SKIP_DATABASE_UPDATE=True
SET SKIP_EXPORT_TO_HTML=True

REM Refresh the database with the latest Jenkins builds
ECHO "Refreshing database..."
python ./00-script-jenkins_and_robot_etl.py

REM Run the Jupyter notebook and export as HTML report
jupyter nbconvert --to html --output report_outputs/analysis_of_test_results.html --TemplateExporter.exclude_input=True --execute 01-analysis_of_test_results.ipynb

POPD
