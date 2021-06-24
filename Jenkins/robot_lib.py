# High-level library to parse Robot reports

import pandas as pd
import xml.etree.ElementTree as et


def get_stats_from_report(robot_report):
    '''
    Extracts numerical statistics from a Robot report as a Pandas dataframe:

    def get_stats_from_report(robot_report)
    '''
    # Finds the root of the XML tree:
    xtree = et.parse(robot_report)
    xroot = xtree.getroot()
    timestamp = xroot.attrib['generated']

    # Obtains the section of numerical statistics, which includes the number of passed/failed tests per testsuite:
    statistics = xroot.find('statistics')
    stat_suites = statistics.find('suite')
    fields = ['id', 'name', 'pass', 'fail']
    rows = []
    for stat in stat_suites:
        rows.append( {f: stat.attrib[f] for f in fields} )
    df_test_stats = pd.DataFrame(rows)

    # Fixes the types of some columns
    df_test_stats['pass'] = df_test_stats['pass'].astype('int64')
    df_test_stats['fail'] = df_test_stats['fail'].astype('int64')

    # Removes the first row, which is redundant (just summarizes the stats of all the testsuites)
    df_test_stats = df_test_stats.loc[1:].reset_index(drop=True)

    # Adds a new column with the overall result of the test suite
    df_test_stats['status'] = 'PASS'
    df_test_stats.loc[df_test_stats.fail>0, 'status'] = 'FAIL'
    df_test_stats['status'] = df_test_stats.status.astype('category')

    return df_test_stats


def get_results_from_report(robot_report):
    '''
    Extracts from a Robot report the results per test suite as a Pandas dataframe:

    def get_results_from_report(robot_report)
    '''
    # Finds the root of the XML tree:
    xtree = et.parse(robot_report)
    xroot = xtree.getroot()
    timestamp = xroot.attrib['generated']

    # 1. Dataframe of results of the test suites of the tests of the day
    all_suites = xroot.find('suite')

    suite_rows = []
    status_rows = []
    for suite in all_suites.findall('suite'):
        # suite
        suite_rows.append(suite.attrib)

        ## suite --> status
        status_rows.append(suite.find('status').attrib)

    df_test_suites = pd.concat([pd.DataFrame(suite_rows), pd.DataFrame(status_rows)], axis=1)
    df_test_suites['status'] = df_test_suites.status.astype('category')
    df_test_suites['starttime'] = pd.to_datetime(df_test_suites.starttime)
    df_test_suites['endtime'] = pd.to_datetime(df_test_suites.endtime)

    return df_test_suites


def get_detailed_results_from_report(robot_report):
    '''
    Extracts from a Robot report the detailed results per test suite, up to the
    level of keyword, and returns them as a Pandas dataframe:

    get_detailed_results_from_report(robot_report)
    '''
    # Finds the root of the XML tree:
    xtree = et.parse(robot_report)
    xroot = xtree.getroot()
    timestamp = xroot.attrib['generated']

    # Dataframe with details of each keyword run in the test
    all_suites = xroot.find('suite')

    rows = []
    for suite in all_suites.findall('suite'):
        # suite
        suite_id = suite.attrib['id']
        suite_name = suite.attrib['name']

        ## tests in the suite
        for test in suite.findall('test'):
            test_id = test.attrib['id']
            test_name = test.attrib['name']

            for kw in test.findall('kw'):
                keyword_name = kw.attrib['name']
                resultado = kw.find('status').attrib

                line = {'suite_id': suite_id, 'suite_name': suite_name, 'test_id': test_id, 'test_name': test_name, 'keyword_name': keyword_name, **resultado}
                rows.append(line)

    df_tests_and_keywords = pd.DataFrame(rows)

    # Guarantees that the dataframe always has the right shape
    empty = pd.DataFrame(columns=['suite_id', 'suite_name', 'test_id', 'test_name', 'keyword_name', 'status', 'starttime', 'endtime'])
    df_tests_and_keywords = pd.concat([empty, df_tests_and_keywords], ignore_index=True)

    # Fixes the dtype of some columns
    df_tests_and_keywords['status'] = df_tests_and_keywords.status.astype('category')
    df_tests_and_keywords['starttime'] = pd.to_datetime(df_tests_and_keywords.starttime)
    df_tests_and_keywords['endtime'] = pd.to_datetime(df_tests_and_keywords.endtime)

    return df_tests_and_keywords


def get_consolidated_results_from_report(robot_report, with_rca=False):
    '''
    Extracts from a Robot report the results and stats per test suite as a Pandas dataframe:

    def get_consolidated_results_from_report(robot_report)
    '''
    df_test_suites = get_results_from_report(robot_report)
    df_test_stats = get_stats_from_report(robot_report)

    df_consolidated_test_results = pd.merge(df_test_suites, df_test_stats.loc[:, ['id', 'pass', 'fail']], how='left', on='id')

    if with_rca:
        df_tests_and_keywords = get_detailed_results_from_report(robot_report)
        df_root_cause_errors = df_tests_and_keywords.loc[df_tests_and_keywords.status=='FAIL'].groupby('suite_id').first()
        #df_root_cause_errors_simple = df_root_cause_errors.reset_index().loc[:, ['suite_id', 'test_id', 'test_name', 'keyword_name']].rename(columns={'test_id': 'failed_test_id', 'test_name': 'failed_test_name', 'keyword_name': 'failed_keyword'})
        df_root_cause_errors_simple = df_root_cause_errors.reset_index().loc[:, ['suite_id', 'test_id', 'test_name', 'keyword_name']]
        df_root_cause_errors_simple = df_root_cause_errors_simple.rename(columns={'test_id': 'failed_test_id', 'test_name': 'failed_test_name', 'keyword_name': 'failed_keyword'})
        df_consolidated_test_results = pd.merge(df_consolidated_test_results, df_root_cause_errors_simple, how='left', left_on='id', right_on='suite_id').drop(columns='suite_id')

    return df_consolidated_test_results
