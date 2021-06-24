# High-level library to handle communications with Jenkins

import jenkins
import pandas as pd
import requests


def test_jenkins_connection(server):
    '''
    Tests the connection to the Jenkins server:

    def test_jenkins_connection(server)

    - server: handler of Jenkins server. E.g.:
        server = jenkins.Jenkins(url_jenkins_server, username=username, password=password)
    '''

    user = server.get_whoami()
    version = server.get_version()
    print(f'Hello {user["fullName"]} from Jenkins {version}')


def get_all_jenkins_jobs_as_df(server):
    '''
    Retrieves the list of jobs that exist in the Jenkins server:

    def get_all_jenkins_jobs_as_df(server)
    '''
    jenkinsJobs = server.get_all_jobs()
    df_jobs = pd.DataFrame(jenkinsJobs)
    return df_jobs


def get_job_summary(server, job_name):
    '''
    Obtains the summary of the current status of a job:

    def get_job_summary(server, job_name)
    '''

    # Obtains all the raw information about the job:
    my_job = server.get_job_info(job_name, 0, True)

    job_fields = [key for key in my_job]

    # Builds a summary table of the selected job:
    ## Retrieves all the fields except those that embed complex structures in the JSON
    composite_fields = ['actions', 'builds', 'firstBuild', 'healthReport', 'lastBuild', 'lastCompletedBuild', 'lastFailedBuild', 'lastStableBuild', 'lastSuccessfulBuild','lastUnstableBuild', 'lastUnsuccessfulBuild', 'property']
    my_job.get('resumeBlocked')
    my_job_status = {k: my_job.get(k, None) for k in my_job if k not in composite_fields}

    ## Adds additional info that was nested in the JSON
    reference_builds_of_job = ['firstBuild', 'lastBuild', 'lastCompletedBuild', 'lastFailedBuild', 'lastStableBuild', 'lastSuccessfulBuild','lastUnstableBuild', 'lastUnsuccessfulBuild']
    for k in reference_builds_of_job:
        item = my_job.get(k, None)
        if item:
            my_job_status[k + '_number'] = item.get('number', None)
            my_job_status[k + '_url'] = item.get('url', None)

    return my_job_status


def get_job_health(server, job_name):
    '''
    Retrieves the health report of a job:

    def get_job_health(server, job_name)
    '''
    my_job = server.get_job_info(job_name, 0, True)
    return my_job.get('healthReport')


def get_all_job_builds(server, job_name):
    '''
    List of historical builds of the job:

    def get_all_job_builds(server, job_name)
    '''
    my_job = server.get_job_info(job_name, 0, True)
    return pd.DataFrame(my_job.get('builds')).drop(columns='_class')


def get_build_summary(server, job_name, build_number):
    '''
    Retrieves all the information about a specific build:

    def get_build_summary(server, job_name, build_number)
    '''
    # Retrieves raw build data
    build_info = server.get_build_info(job_name, build_number)

    # Summary of key data of the build
    relevant_build_fields = ['id', 'number', 'result', 'duration', 'estimatedDuration', 'timestamp', 'url']
    return {k: build_info.get(k, None) for k in relevant_build_fields}


def get_robot_report(server, job_name, build_number):
    '''
    Retrieves the contents of the report file of a given build of a job:

    def get_robot_report(server, job_name, build_number)
    '''
    robot_results_url = get_build_summary(server, job_name, build_number)['url'] + 'robot/report/output.xml'
    req = requests.Request('POST',  robot_results_url)
    return server.jenkins_open(req)
