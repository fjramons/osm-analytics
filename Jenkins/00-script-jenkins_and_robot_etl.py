#!/usr/bin/env python

# %% [markdown]
# # Analysis of Robot reports from OSM Jenkins (Step 1)
#
# ## ETL preprocessing and loading into database

# %%
import os
from dotenv import load_dotenv
import pandas as pd
import numpy as np
import jenkins
import getpass
from jenkins_lib import *
from robot_lib import *
from jenkins_robot_etl import *
import json
from sqlalchemy import create_engine

# %% [markdown]
# 0. Input parameters

# %%
# Default values
inputs_folder = 'inputs'
outputs_folder = 'etl_outputs'
url_jenkins_server = 'https://osm.etsi.org/jenkins'
input_robot_file = 'output.xml'
database_uri = f'sqlite:///{outputs_folder}/test_executions.db'
table_known_builds = 'builds_info'
table_robot_reports = 'robot_reports'
table_robot_reports_extended = 'robot_reports_extended'
dump_all_as_spreadsheets = False

# %% [markdown]
# Tries to bulk load credentials and other environment variables from .env file:

# %%
# If the '.env' file exists, loads the environment variables
load_dotenv();


# %%
# Retrieves Jenkins credentials from environment, if applicable
username = os.environ.get('JENKINS_USER', None) or input('Username: ')
password = os.environ.get('JENKINS_PASS', None) or getpass.getpass()

# Other environment variables
url_jenkins_server = os.environ.get('URL_JENKINS_SERVER', None) or url_jenkins_server
database_uri = os.environ.get('DATABASE_URI', None) or database_uri
inputs_folder = os.environ.get('INPUTS_FOLDER', None) or inputs_folder
outputs_folder = os.environ.get('OUTPUTS_FOLDER', None) or outputs_folder
input_robot_file = os.environ.get('INPUT_ROBOT_FILE', None) or input_robot_file
table_known_builds = os.environ.get('TABLE_KNOWN_BUILDS', None) or table_known_builds
table_robot_reports = os.environ.get('TABLE_ROBOT_REPORTS', None) or table_robot_reports
table_robot_reports_extended = os.environ.get('TABLE_ROBOT_REPORTS_EXTENDED', None) or table_robot_reports_extended

# %% [markdown]
# 2. Populates the database with all builds from a set of relevant jobs

# %%
job_ids_prefix = 'osm-stage_3-merge/'
job_ids_prefix = os.environ.get('JOB_IDS_PREFIX', None) or job_ids_prefix

job_ids = ['master', 'v17.0', 'v16.0', 'v15.0', 'v14.0']
temp_job_ids = os.environ.get('JOB_IDS', None)

if temp_job_ids:
    job_ids = json.loads(temp_job_ids.replace("'", ""))

job_names = ['Master branch', 'Release SEVENTEEN', 'Release SIXTEEN', 'Release FIFTEEN', 'Release FOURTEEN']
temp_job_names = os.environ.get('JOB_NAMES', None)
if temp_job_names:
    job_names = json.loads(temp_job_names.replace("'", ""))

# relevant_jobs = ['osm-stage_3-merge/' + job_id for job_id in job_ids]
relevant_jobs = [job_ids_prefix + job_id for job_id in job_ids]


# %%
# Connection to the Jenkins server
server = jenkins.Jenkins(
    url_jenkins_server,
    username=username,
    password=password
)
#------------------------------

# %%
# Database setup
engine = create_engine(database_uri)


# %%
print(f"Getting new builds from: {', '.join(relevant_jobs)}")
for job in relevant_jobs:
    ingest_update_all_jenkins_job(
        jenkins_server=server,
        job_name=job,
        database_engine=engine,
        robot_report=os.path.join(
            inputs_folder,
            input_robot_file
        ),
        table_known_builds=table_known_builds,
        table_robot_reports=table_robot_reports,
        table_robot_reports_extended=table_robot_reports_extended
    )

print("DONE")
