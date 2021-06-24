# Library for ETL preprocessing of Jenkins and Robot, loading into database

import pandas as pd
import numpy as np
import jenkins
from jenkins_lib import *
from robot_lib import *
from sqlalchemy import create_engine

def ingest_update_all_jenkins_job(jenkins_server, job_name, database_engine,
                                  robot_report = 'tmp_robot_report.xml',
                                  table_known_builds = 'builds_info',
                                  table_robot_reports = 'robot_reports',
                                  table_robot_reports_extended = 'robot_reports_extended'):


    # If there is historical data about former builds of this job, it is retrieved first (otherwise, it should return an empty dataframe):
    try:
        with database_engine.connect() as connection:
            df_known_builds = pd.read_sql_table(table_known_builds, con=connection)
    except (NameError, ValueError) as e:   # If it does not exist, bootstraps a new dataframe
        df_known_builds = pd.DataFrame(columns=['job', 'build', 'timestamp', 'duration', 'build_result', 'test_result', 'pass_count', 'fail_count'])

    # Retrieves from Jenkins a fresh list of builds of the job:
    df_builds_of_job = get_all_job_builds(jenkins_server, job_name)

    # Compares the fresh list with the historical one and determines which builds we need to add to our database:
    known_builds = df_known_builds.loc[df_known_builds.job==job_name, 'build'].tolist()
    jenkins_builds = df_builds_of_job.loc[:, 'number'].tolist()
    new_builds = np.setdiff1d(jenkins_builds, known_builds)

    # Creates a new dataframe and appends it to the original one to book the space to save data afterwards:
    df_unknown_builds = pd.DataFrame(columns=['job', 'build', 'timestamp', 'duration', 'build_result', 'test_result', 'pass_count', 'fail_count'])
    df_unknown_builds['build'] = new_builds
    df_unknown_builds['job'] = job_name
    df_unknown_builds['timestamp'] = pd.to_datetime(df_unknown_builds.timestamp)
    df_known_builds = pd.concat([df_known_builds, df_unknown_builds], ignore_index=True)

    # Starts with empty dataframes
    df_new_build_reports = pd.DataFrame(columns=['job', 'build', 'id', 'name', 'source', 'status', 'starttime', 'endtime', 'pass', 'fail', 'failed_test_id', 'failed_test_name', 'failed_keyword'])
    df_new_build_reports_details = pd.DataFrame(columns=['job', 'build', 'suite_id', 'suite_name', 'test_id', 'test_name', 'keyword_name', 'status', 'starttime', 'endtime'])
    builds_with_missing_info = df_known_builds.loc[(df_known_builds.job==job_name) & (df_known_builds.build_result.isna()), 'build'].tolist()

    for build_number in builds_with_missing_info:
        print(f'Retrieving build {build_number} from "{job_name}"...\t', end='')

        # Shortcut to filter this build and job
        this_build_and_job = (df_known_builds.job==job_name) & (df_known_builds.build==build_number)

        # Retrieves the information about the own build
        build_info = get_build_summary(jenkins_server, job_name, build_number)
        df_known_builds.loc[this_build_and_job, 'build_result'] = build_info['result']
        print(f"Build: {build_info['result']}\t", end='')
        df_known_builds.loc[this_build_and_job, 'timestamp'] = pd.to_datetime(build_info['timestamp'], unit='ms') # Unit in Jenkins for timestamps
        # timestamp_translated = str(df_known_builds.loc[this_build_and_job, 'timestamp'])
        #timestamp_translated = df_known_builds.loc[this_build_and_job, 'timestamp'].dt.strftime('%Y-%m-%d')
        # print(f"{timestamp_translated}({build_info['timestamp']})\t", end='')
        df_known_builds.loc[this_build_and_job, 'duration'] = build_info['duration']

        # Retrieves the Robot report, if it exists
        try:
            robot_report_contents = get_robot_report(jenkins_server, job_name, build_number)
            with open(robot_report, 'w', encoding='utf-8') as f:
                print(robot_report_contents, file=f)

            print('Report available: ', end='')

            # Retrieves the rows that need to be added the corresponding database table, and appends them
            df_build_report = get_consolidated_results_from_report(robot_report, with_rca=True)
            df_build_report_details = get_detailed_results_from_report(robot_report)
            df_new_build_reports = pd.concat([df_new_build_reports, df_build_report], ignore_index=True)
            df_new_build_reports_details = pd.concat([df_new_build_reports_details, df_build_report_details], ignore_index=True)

            # Adds the build number to the new rows
            df_new_build_reports.build.fillna(build_number, inplace=True)
            df_new_build_reports_details.build.fillna(build_number, inplace=True)

            # Records the number of tests passed vs. failed
            df_known_builds.loc[this_build_and_job, 'pass_count'] = df_build_report['pass'].sum()
            df_known_builds.loc[this_build_and_job, 'fail_count'] = df_build_report['fail'].sum()

            # If any test is different from 'PASS', the whole build is marked as 'FAIL'
            if len(df_build_report.loc[df_build_report.status!='PASS']):
                # Job name will surely match, so there is no need to check it
                df_known_builds.loc[this_build_and_job, 'test_result'] = 'FAIL'
                print('FAIL')
            else:
                # Job name will surely match, so there is no need to check it
                df_known_builds.loc[this_build_and_job, 'test_result'] = 'PASS'
                print('PASS')
        except jenkins.NotFoundException as e:
            # If the Robot report could not be retrieved, it marks it as unavailable
            df_known_builds.loc[this_build_and_job, 'test_result'] = 'UNAVAILABLE'
            print('Report unavailable')

    # All new rows should come from the same job
    df_new_build_reports.job.fillna(job_name, inplace=True)
    df_new_build_reports_details.job.fillna(job_name, inplace=True)

    # Fixes the data types
    df_new_build_reports['build'] = df_new_build_reports.build.astype('int')
    df_new_build_reports['status'] = df_new_build_reports.status.astype('category')
    df_new_build_reports_details['build'] = df_new_build_reports_details.build.astype('int')
    df_new_build_reports_details['status'] = df_new_build_reports_details.status.astype('category')

    df_known_builds['build_result'] = df_known_builds.build_result.astype('category')
    df_known_builds['test_result'] = df_known_builds.test_result.astype('category')
    df_known_builds['pass_count'] = df_known_builds.pass_count.astype('float')
    df_known_builds['fail_count'] = df_known_builds.fail_count.astype('float')

    # Saves the results to the database as a single transaction:
    with database_engine.begin() as conn:
        df_known_builds.to_sql(name=table_known_builds, con=conn, if_exists='replace', index=False)
        df_new_build_reports.to_sql(name=table_robot_reports, con=conn, if_exists='append', index=False)
        df_new_build_reports_details.to_sql(name=table_robot_reports_extended, con=conn, if_exists='append', index=False)
