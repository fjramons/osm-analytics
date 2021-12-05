# README  - Jenkins and Robot analysis

## Usage

Open and run the `01-analysis_of_test_results.ipynb` notebook. The results will be published in the `report_outputs` folder:

- `analysis_of_test_results.html`: Full report.
- `*.png`, `*.svg`: Figures extracted from the report.

It can also be run unattended as:

```bash
!jupyter nbconvert --to html --output report_outputs/analysis_of_test_results.html --TemplateExporter.exclude_input=True --execute  01-analysis_of_test_results.ipynb
```

In case only a refresh of the database is intended, then just do:

```bash
./00-script-jenkins_and_robot_etl.py
```

## Environment variables

Default behaviours can be changed by setting specific environment variables:

- `INPUTS_FOLDER`: Folder where input data is located.
  - If not set, it will be the `etl_outputs` subfolder.
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
  - If not set, the following list will be used: `['v11.0', 'v10.0', 'master', 'v9.0']`
- `JOB_NAMES`: List of human-readable jobs/branches considered in the analysis.
  - If not set, the following list will be used: `['Master branch', 'Release ELEVEN', 'Release TEN', 'Release NINE']`
- `FIRST_DATE`: If defined, it is used to define the oldest date considered in the charts of the report. When defined, it overrides the window defined by `DAYS_SINCE_TODAY_4_ANALYSIS`.
- `LAST_DATE`: If defined, it is used to define the latest date considered in the charts of the report. If not defined, it will be set to the current day (`today`).
