# README  - Bugzilla analysis

## Usage

Open and run the `bugzilla_analysis.ipynb` notebook. The results will be published in the `outputs` folder:

- `bugzilla_analysis.html`: Full report.
- `*.png`, `*.svg`: Figures extracted from the report.
- `XXXXXXXX_bugs_for_mdl_review.xlsx`: List of bug outliers per module.
  - If the file `inputs/former_mdl_assessments.xlsx` exists, it is taken into account to add a recommendation per bug.
- `XXXXXXXX_SUMMARY_bug_outliers.xlsx`: Summary of bug outliers per module.

It can also be run unattended as:

```bash
jupyter nbconvert --to html --output outputs/bugzilla_analysis.html --TemplateExporter.exclude_input=True --execute bugzilla_analysis.ipynb
```

## Main generated dataframes

### Current state of open bugs

1. `df_bug_full`: Data just loaded and cleaned from Bugzilla.

   ```python
   df_bug_full = load_bug_full()
   ```

   | # | Column          | Dtype          |
   |---|-----------------|----------------|
   | 0 | TIMESTAMP       | datetime64[ns] |
   | 1 | BUG_ID          | int64          |
   | 2 | OPERATION       | category       |
   | 3 | VALUE           | object         |
   | 4 | RELEASE         | category       |
   | 5 | MODULE          | category       |
   | 6 | BUG_DESCRIPTION | object         |
   | 7 | ROW_NUMBER      | int64          |
   | 8 | MONTH           | datetime64[ns] |
   | 9 | AGE             | category       |

   - **`OPERATION`**: most relevant values:
     - `assigned_to`: (Re)assignment of the bug to a **person**.
     - `version`: Explicit assignment to OSM Release: `master`, `v9.0`, etc.
       - `VALUE` in a `version` operation reflects **the new state at that time**. It may not be the latest state.
     - `component`: (Re)assigment of the bug to an **OSM module**.
     - `bug_status`: Change of bug state. Possible values:
       - `RESOLVED`
       - `CONFIRMED`
       - `IN_PROGRESS`
       - `VERIFIED`
       - `UNCONFIRMED`
     - `resolution`: Change of resolution state of the bug (related to `bug_status` when `RESOLVED`). Possible values:
       - `FIXED`
       - `WONTFIX`
       - `INVALID`
       - `DUPLICATE`
       - `WORKSFORME`
     - `comment`: New comment to the bug. The first one is the event that **opens** the bug:
     - `priority`: Change of bug priority.
     - `bug_severity`: Change of bug severity.
   - **`RELEASE`** reflects the **latest** state **even from the first row**.

2. `df_status_changes_by_bug`

   ```python
   df_status_changes_by_bug = get_status_changes_by_bug(df_bug_full)
   ```

   | #  | Column          | Dtype          |
   |----|-----------------|----------------|
   | 0  | TIMESTAMP       | datetime64[ns] |
   | 1  | BUG_ID          | int64          |
   | 2  | OPERATION       | object         |
   | 3  | VALUE           | category       |
   | 4  | RELEASE         | category       |
   | 5  | MODULE          | category       |
   | 6  | BUG_DESCRIPTION | object         |
   | 7  | ROW_NUMBER      | int64          |
   | 8  | MONTH           | datetime64[ns] |
   | 9  | AGE             | category       |
   | 10 | ISSUER          | object         |
   | 11 | SOLVED          | bool           |

   - **`SOLVED`**: Is the bug considered solved at the time of this event?

3. `df_current_bug_state`

   ```python
   df_current_bug_state = get_current_bug_state(df_status_changes_by_bug)
   ```

   | #  | Column          | Dtype          |
   |----|-----------------|----------------|
   | 0  | BUG_ID          | int64          |
   | 1  | TIMESTAMP       | datetime64[ns] |
   | 2  | OPERATION       | object         |
   | 3  | VALUE           | category       |
   | 4  | RELEASE         | category       |
   | 5  | MODULE          | category       |
   | 6  | BUG_DESCRIPTION | object         |
   | 7  | ROW_NUMBER      | int64          |
   | 8  | MONTH           | datetime64[ns] |
   | 9  | AGE             | category       |
   | 10 | ISSUER          | object         |
   | 11 | SOLVED          | bool           |

4. `df_bug_summary`

   ```python
   df_bug_summary = get_bug_summary(df_status_changes_by_bug, df_bug_full)
   ```

   | #  | Column                | Dtype          |
   |----|-----------------------|----------------|
   | 0  | BUG_DESCRIPTION       | object         |
   | 1  | ISSUER                | object         |
   | 2  | CREATION_TIME         | datetime64[ns] |
   | 3  | CREATION_AGE          | category       |
   | 4  | MONTH                 | datetime64[ns] |
   | 5  | STATE                 | category       |
   | 6  | STATE_UPDATE_TIME     | datetime64[ns] |
   | 7  | STATE_UPDATE_AGE      | category       |
   | 8  | STATE_UPDATE_MONTH    | datetime64[ns] |
   | 9  | STATE_CHANGES         | int64          |
   | 10 | CHANGES_TO_RESOLVED   | float64        |
   | 11 | RELEASE               | category       |
   | 12 | MODULE                | category       |
   | 13 | RELEASE_CHANGES       | float64        |
   | 14 | MODULE_CHANGES        | float64        |
   | 15 | LAST_ASSIGNMENT_TIME  | datetime64[ns] |
   | 16 | OWNER                 | object         |
   | 17 | LAST_ASSIGNMENT_MONTH | datetime64[ns] |
   | 18 | LAST_ASSIGNMENT_AGE   | category       |
   | 19 | OWNER_CHANGES         | float64        |
   | 20 | LAST_EVENT            | category       |
   | 21 | LAST_EVENT_TIME       | datetime64[ns] |
   | 22 | LAST_EVENT_AGE        | category       |
   | 23 | LAST_EVENT_MONTH      | datetime64[ns] |
   | 24 | SOLVED                | bool           |
   | 25 | BUG_RESOLUTION_TIME   | int64          |
   | 26 | TIME_SINCE_CREATION   | int64          |

   - This summary table (`df_bug_summmary`) aims to collect for each known bug (historical or active):
     - Basic bug details:
       - Bug id
       - Bug description
       - Issuer (reporter of the bug)
     - Latest states of the bug:
       - Currently assigned status
       - Currently assigned Release
       - Currently assigned MDG
       - Currently assigned owner
       - Is the bug solved?
     - Relevant timestamps:
       - Date of creation.
       - Date of latest change of state.
       - Date of latest event.
     - Age tags:
       - Date of creation
       - Date of last event.
     - Time since (until today):
       - It was created.
       - It was solved (if applicable).
     - Other relevant summary statistics, such as:
       - No. Release reassignments.
       - No. State reassignments.
       - No. State reassignments to `RESOLVED`.

5. `df_open_bugs`

   ```python
   df_open_bugs = df_current_bug_state[ ~df_current_bug_state['VALUE'].isin(['RESOLVED', 'VERIFIED']) ]
   ```

   | #  | Column          | Dtype          |
   |----|-----------------|----------------|
   | 0  | BUG_ID          | int64          |
   | 1  | TIMESTAMP       | datetime64[ns] |
   | 2  | OPERATION       | object         |
   | 3  | VALUE           | category       |
   | 4  | RELEASE         | category       |
   | 5  | MODULE          | category       |
   | 6  | BUG_DESCRIPTION | object         |
   | 7  | ROW_NUMBER      | int64          |
   | 8  | MONTH           | datetime64[ns] |
   | 9  | AGE             | category       |
   | 10 | ISSUER          | object         |
   | 11 | SOLVED          | bool           |

6. `df_multibranch_bugs_open`: Bugs open in multiple branches

   ```python
   df_multibranch_bugs_open = get_multibranch_bugs_open(df_open_bugs)
   ```

   | # | Column          | Dtype          |
   |---|-----------------|----------------|
   | 0 | BUG_DESCRIPTION | object         |
   | 1 | NUM_BRANCHES    | int64          |
   | 2 | RELEASE         | object         |
   | 3 | MODULE          | object         |
   | 4 | TIMESTAMP       | datetime64[ns] |

7. `df_open_bugs_selected`

   - From `df_bug_summary.query('SOLVED==False')`.
   - Only includes bugs from relevant modules (listed in `most_relevant_modules`).

8. `ct_open_bugs` and `ct_open_bugs_selected`

   - Crosstab: "Module" vs. "Age" (from `df_open_bugs`).

9.  `ct_open_bugs_age_vs_state`

   - Crosstab: "State" vs. "Age" (from `df_open_bugs`).

### Outliers

1. `bug_open_times`
   - From `df_bug_summary.query('(~SOLVED) & (CREATION_AGE!="OLD")')`
2. `quantiles_bug_open_times`
   - From `bug_open_times.groupby(['Module', 'OSM Release'])[['Time bug open (days)']]`
3. `bug_open_times_with_thresholds`
   - From `bug_open_times`, left merging columns from:
     - `quantiles_bug_open_times` (merged by "Module" and "OSM Release")
     - `df_bug_summary` (merged by "bug ID")
4. `df_recommendations`
5. `df_old_still_open`, `bug_open_outliers`, `bug_open_q3`, `bug_open_2_months`
   - Filtered + left merging `df_recommendations`
6. `summary_table_outliers`

### Temporal evolution

1. `df_status_changes_by_bug_extended`

   ```python
   df_status_changes_by_bug_extended = get_status_changes_by_bug_extended(df_status_changes_by_bug)
   ```

   | #  | Column            | Dtype           |
   |----|-------------------|-----------------|
   | 0  | TIMESTAMP         | datetime64[ns]  |
   | 1  | BUG_ID            | int64           |
   | 2  | OPERATION         | object          |
   | 3  | VALUE             | category        |
   | 4  | RELEASE           | category        |
   | 5  | MODULE            | category        |
   | 6  | BUG_DESCRIPTION   | object          |
   | 7  | ROW_NUMBER        | int64           |
   | 8  | MONTH             | datetime64[ns]  |
   | 9  | AGE               | category        |
   | 10 | ISSUER            | object          |
   | 11 | SOLVED            | bool            |
   | 12 | WAS_SOLVED        | object          |
   | 13 | JUST_OPENED       | bool            |
   | 14 | REOPENED          | bool            |
   | 15 | OPENED            | bool            |
   | 16 | CLOSED            | bool            |
   | 17 | TIMESTAMP_OPENING | datetime64[ns]  |
   | 18 | TIMESTAMP_4_EVENT | datetime64[ns]  |
   | 19 | TIME              | timedelta64[ns] |

   - **`SOLVED`** (already existing in the original dataframe, `df_status_changes_by_bug`): Is the bug considered solved at the time of this event?
   - **`WAS_SOLVED`**: Was the bug considered solved before this event?
   - **`JUST_OPENED`**: Was the bug just opened by this event for the first time?
   - **`REOPENED`**: Has the bug just been reopened due to this event?
   - **`OPENED`**: Is the bug considered open at the time of this event?
     - Should contain the negated value of `SOLVED` and `CLOSED`, but calculated by different means.
   - **`CLOSED`**: Is the bug considered closed at the time of this event?
     - It should contain the same value of `SOLVED`, but calculated by different means.
   - **`TIMESTAMP_OPENING`**: Time of creation of the bug (i.e. first event).
   - **`TIMESTAMP_4_EVENT`**: Effective timestamp for this event to compute time differences. Two cases:
     1. Bug is closed: Same as timestamp of this event.
     2. Bug is open: End of the month corresponding month.
        - In case the month is the current one, it adds the timestamp for _today_ (this avoids overestimations of times for bugs currently open).
   - **`TIME`**: Time duration, calculated as the difference `TIMESTAMP_OPENING - TIMESTAMP_4_EVENT`.

   <br>

   Example of sequence for a given bug:

   ```python
   df_status_changes_by_bug_extended.query("BUG_ID==1433")
   ```

   | #    | TIMESTAMP           | BUG_ID | OPERATION  | VALUE            | ... | MONTH               | ... | SOLVED | WAS_SOLVED | JUST_OPENED | REOPENED | OPENED | CLOSED | TIMESTAMP_OPENING   | TIMESTAMP_4_EVENT   | TIME             |
   |------|---------------------|--------|------------|------------------|-----|---------------------|-----|--------|------------|-------------|----------|--------|--------|---------------------|---------------------|------------------|
   | 3009 | 2021-02-05 11:15:25 | 1433   | bug_status | OPEN-UNCONFIRMED |     | 2021-02-28 23:59:59 |     | False  | False      | True        | False    | True   | False  | 2021-02-05 11:15:25 | 2021-02-28 23:59:59 | 23 days 12:44:34 |
   | 3017 | 2021-02-09 07:56:21 | 1433   | bug_status | RESOLVED         |     | 2021-02-28 23:59:59 |     | True   | False      | False       | False    | False  | True   | 2021-02-05 11:15:25 | 2021-02-09 07:56:21 | 3 days 20:40:56  |
   | 3018 | 2021-02-09 12:49:29 | 1433   | bug_status | UNCONFIRMED      |     | 2021-02-28 23:59:59 |     | False  | True       | False       | True     | True   | False  | 2021-02-05 11:15:25 | 2021-02-28 23:59:59 | 23 days 12:44:34 |
   | 3100 | 2021-03-10 12:11:00 | 1433   | bug_status | RESOLVED         |     | 2021-03-31 23:59:59 |     | True   | False      | False       | False    | False  | True   | 2021-02-05 11:15:25 | 2021-03-10 12:11:00 | 33 days 00:55:35 |
   | 3106 | 2021-03-15 11:48:54 | 1433   | bug_status | CONFIRMED        |     | 2021-03-31 23:59:59 |     | False  | True       | False       | True     | True   | False  | 2021-02-05 11:15:25 | 2021-03-31 23:59:59 | 54 days 12:44:34 |
   | 3113 | 2021-03-16 14:38:39 | 1433   | bug_status | RESOLVED         |     | 2021-03-31 23:59:59 |     | True   | False      | False       | False    | False  | True   | 2021-02-05 11:15:25 | 2021-03-16 14:38:39 | 39 days 03:23:14 |
   | 3130 | 2021-03-25 13:17:31 | 1433   | bug_status | CONFIRMED        |     | 2021-03-31 23:59:59 |     | False  | True       | False       | True     | True   | False  | 2021-02-05 11:15:25 | 2021-03-31 23:59:59 | 54 days 12:44:34 |
   | 3147 | 2021-04-01 07:47:32 | 1433   | bug_status | RESOLVED         |     | 2021-04-30 23:59:59 |     | True   | False      | False       | False    | False  | True   | 2021-02-05 11:15:25 | 2021-04-01 07:47:32 | 54 days 20:32:07 |
   | 3180 | 2021-04-14 12:52:23 | 1433   | bug_status | UNCONFIRMED      |     | 2021-04-30 23:59:59 |     | False  | True       | False       | True     | True   | False  | 2021-02-05 11:15:25 | 2021-04-30 23:59:59 | 84 days 12:44:34 |
   | 3188 | 2021-04-15 19:49:41 | 1433   | bug_status | RESOLVED         |     | 2021-04-30 23:59:59 |     | True   | False      | False       | False    | False  | True   | 2021-02-05 11:15:25 | 2021-04-15 19:49:41 | 69 days 08:34:16 |
   | 3190 | 2021-04-16 10:52:55 | 1433   | bug_status | UNCONFIRMED      |     | 2021-04-30 23:59:59 |     | False  | True       | False       | True     | True   | False  | 2021-02-05 11:15:25 | 2021-04-30 23:59:59 | 84 days 12:44:34 |
   | 3195 | 2021-04-19 11:38:06 | 1433   | bug_status | RESOLVED         |     | 2021-04-30 23:59:59 |     | True   | False      | False       | False    | False  | True   | 2021-02-05 11:15:25 | 2021-04-19 11:38:06 | 73 days 00:22:41 |

2. `df_monthly_time_samples_per_bug`: Evolution of age of open bugs at each month, disaggregated per module. 

   - The dataframe of bug events is oversampled to add to each month rows that represent the bugs that remain open by that time (i.e. if a month did not have any event related to the bug and the bug remains open by that month, an intermadiate sample is inserted).
   - This is required to compute e.g. average time of open bugs per month.

   ```python
   df_monthly_time_samples_per_bug = get_monthly_time_samples_per_bug(df_status_changes_by_bug_extended)
   ```

   | #  | Column            | Dtype          |
   |--- | ------            | -----          |
   | 0  | BUG_ID            | int64          |
   | 1  | MONTH             | datetime64[ns] |
   | 2  | TIMESTAMP         | datetime64[ns] |
   | 3  | OPERATION         | object         |
   | 4  | VALUE             | bool           |
   | 5  | RELEASE           | object         |
   | 6  | MODULE            | object         |
   | 7  | BUG_DESCRIPTION   | object         |
   | 8  | ROW_NUMBER        | float64        |
   | 9  | AGE               | object         |
   | 10 | ISSUER            | object         |
   | 11 | SOLVED            | bool           |
   | 12 | WAS_SOLVED        | object         |
   | 13 | JUST_OPENED       | object         |
   | 14 | REOPENED          | object         |
   | 15 | OPENED            | object         |
   | 16 | CLOSED            | object         |
   | 17 | TIMESTAMP_OPENING | datetime64[ns] |
   | 18 | TIMESTAMP_4_EVENT | datetime64[ns] |
   | 19 | TIME              | float64        |

   <br>

   For instance, given this sequence of `df_monthly_time_samples_per_bug` for a given bug that remains open with no activity for the last two months, two extra samples are inserted for the last two months to allow the computation of times at each month:

   ```bash
   df_status_changes_by_bug_extended.query("BUG_ID==1598")
   ```

   | #    | TIMESTAMP           | BUG_ID | OPERATION  | VALUE            | ... | MONTH               | ... | SOLVED | WAS_SOLVED | JUST_OPENED | REOPENED | OPENED | CLOSED | TIMESTAMP_OPENING   | TIMESTAMP_4_EVENT   | TIME             |
   |------|---------------------|--------|------------|------------------|-----|---------------------|-----|--------|------------|-------------|----------|--------|--------|---------------------|---------------------|------------------|
   | 3446 | 2021-07-15 11:52:18 | 1598   | bug_status | OPEN-UNCONFIRMED | ... | 2021-07-31 23:59:59 | ... | False  | False      | True        | False    | True   | False  | 2021-07-15 11:52:18 | 2021-07-31 23:59:59 | 16 days 12:07:41 |
   | 3447 | 2021-07-15 13:53:23 | 1598   | bug_status | RESOLVED         | ... | 2021-07-31 23:59:59 | ... | True   | False      | False       | False    | False  | True   | 2021-07-15 11:52:18 | 2021-07-15 13:53:23 | 0 days 02:01:05  |
   | 3448 | 2021-07-15 13:59:54 | 1598   | bug_status | CONFIRMED        | ... | 2021-07-31 23:59:59 | ... | False  | True       | False       | True     | True   | False  | 2021-07-15 11:52:18 | 2021-07-31 23:59:59 | 16 days 12:07:41 |
   | 3458 | 2021-07-16 23:32:59 | 1598   | bug_status | RESOLVED         | ... | 2021-07-31 23:59:59 | ... | True   | False      | False       | False    | False  | True   | 2021-07-15 11:52:18 | 2021-07-16 23:32:59 | 1 days 11:40:41  |
   | 3518 | 2021-08-10 10:03:05 | 1598   | bug_status | UNCONFIRMED      | ... | 2021-08-31 23:59:59 | ... | False  | True       | False       | True     | True   | False  | 2021-07-15 11:52:18 | 2021-08-31 23:59:59 | 47 days 12:07:41 |

   ```bash
   df_monthly_time_samples_per_bug.query("BUG_ID==1598")
   ```

   | #     | BUG_ID | MONTH                      | TIMESTAMP           | OPERATION  | VALUE | ... | SOLVED | WAS_SOLVED | JUST_OPENED | REOPENED | OPENED | CLOSED | TIMESTAMP_OPENING   | TIMESTAMP_4_EVENT          | TIME      |
   |-------|--------|----------------------------|---------------------|------------|-------|-----|--------|------------|-------------|----------|--------|--------|---------------------|----------------------------|-----------|
   | 48667 | 1598   | 2021-07-31 23:59:59.000000 | 2021-07-16 23:32:59 | bug_status | True  | ... | True   | False      | False       | False    | False  | True   | 2021-07-15 11:52:18 | 2021-07-16 23:32:59.000000 | 1.486586  |
   | 48668 | 1598   | 2021-08-31 23:59:59.000000 | 2021-08-10 10:03:05 | bug_status | True  | ... | False  | True       | False       | True     | True   | False  | 2021-07-15 11:52:18 | 2021-08-31 23:59:59.000000 | 47.505336 |
   | 48669 | 1598   | 2021-09-30 23:59:59.000000 | NaT                 | NaN        | True  | ... | False  | NaN        | NaN         | NaN      | NaN    | NaN    | 2021-07-15 11:52:18 | 2021-09-30 23:59:59.000000 | 77.505336 |
   | 48670 | 1598   | 2021-10-23 01:28:46.546332 | NaT                 | NaN        | True  | ... | False  | NaN        | NaN         | NaN      | NaN    | NaN    | 2021-07-15 11:52:18 | 2021-10-23 01:28:46.546332 | 99.566997 |

3. `df_bug_summary_per_month`: Net variation of open bugs per month (real and "ineffective"), disaggregated por module.

   ```python
   df_bug_summary_per_month = get_bug_summary_per_month(df_status_changes_by_bug_extended)
   ```

   | #   | Column            | Dtype           |
   |---  | ------            | -----           |
   | 0   | MONTH             | datetime64[ns]  |
   | 1   | BUG_ID            | int64           |
   | 2   | TIMESTAMP         | datetime64[ns]  |
   | 3   | OPERATION         | object          |
   | 4   | VALUE             | category        |
   | 5   | RELEASE           | category        |
   | 6   | MODULE            | category        |
   | 7   | BUG_DESCRIPTION   | object          |
   | 8   | ROW_NUMBER        | int64           |
   | 9   | AGE               | category        |
   | 10  | ISSUER            | object          |
   | 11  | SOLVED            | bool            |
   | 12  | WAS_SOLVED        | bool            |
   | 13  | TIMESTAMP_OPENING | datetime64[ns]  |
   | 14  | TIMESTAMP_4_EVENT | datetime64[ns]  |
   | 15  | TIME              | timedelta64[ns] |
   | 16  | OPENED            | int64           |
   | 17  | JUST_OPENED       | int64           |
   | 18  | REOPENED          | int64           |
   | 19  | CLOSED            | int64           |
   | 20  | REAL_CLOSED       | int64           |
   | 21  | FALSE_CLOSED      | int64           |
   | 22  | BUG_VARIATION     | int64           |

   - **`OPENED`**: Total number of bugs considered solved during the month per module (new + reopenings).
     - It should happen that `OPENED` = `JUST_OPENED` + `REOPENED`
   - **`JUST_OPENED`**: Number of bug opened for the first time during the month per module.
   - **`REOPENED`**: Number of bugs reopened during the month per module.
   - **`CLOSED`**: Total number of bugs considered closed during the month per module (real + "false closed").
     - It should happen that `CLOSED` = `REAL_CLOSED` + `FALSE_CLOSED`
   - **`REAL_CLOSED`**: Number of bugs considered definitely closed during the month per module (i.e. not reopened later).
   - **`FALSE_CLOSED`**: Number of bugs closed and reopened during the month per module.
   - **`BUG_VARIATION`**: Net variation in the number of bugs during the month per module.
     - It should happen that `BUG_VARIATION` = `OPENED` - `CLOSED`

   <br>

   For instance:

   ```bash
   df_bug_summary_per_month.query("BUG_ID==1433")
   ```

   | #    | MONTH               | BUG_ID | TIMESTAMP           | OPERATION  | VALUE       | ... | OPENED | JUST_OPENED | REOPENED | CLOSED | REAL_CLOSED | FALSE_CLOSED | BUG_VARIATION |
   |------|---------------------|--------|---------------------|------------|-------------|-----|--------|-------------|----------|--------|-------------|--------------|---------------|
   | 2108 | 2021-02-28 23:59:59 | 1433   | 2021-02-09 12:49:29 | bug_status | UNCONFIRMED | ... | 2      | 1           | 1        | 1      | 0           | 1            | 1             |
   | 2138 | 2021-03-31 23:59:59 | 1433   | 2021-03-25 13:17:31 | bug_status | CONFIRMED   | ... | 2      | 0           | 2        | 2      | 0           | 2            | 0             |
   | 2198 | 2021-04-30 23:59:59 | 1433   | 2021-04-19 11:38:06 | bug_status | RESOLVED    | ... | 2      | 0           | 2        | 3      | 1           | 2            | -1            |

4. `df_cummulative_bug_summary_per_month`: Number of open bugs at each month, disaggregated per module.

   ```python
   # Dataframe with the temporal evolution of the open bugs per module
   df_cummulative_bug_summary_per_month = get_cummulative_bug_summary_per_month(df_bug_summary_per_month)
   ```

   | # | Column        | Dtype          |
   |---|---------------|----------------|
   | 0 | MODULE        | category       |
   | 1 | MONTH         | datetime64[ns] |
   | 2 | BUG_VARIATION | int64          |
   | 3 | OPEN_BUGS     | int64          |

   - **`BUG_VARIATION`**: Monthly variation of the number of open bugs for a given module.
   - **`OPEN_BUGS`**: Total number of open bugs the module at a given month.

5. `temporal_bug_data_for_plots`: Contributions to variation of open bugs per month, disaggragated per module. Formatted as `<variable, value>` more convenient for plotting.

   - From `df_bug_summary_per_month`
     - Melted by month, bug ID and module, for easier plotting.
   - Differentiates between opened vs. reopened and closed vs. false closed.

   | # | Column   | Dtype          |
   |---|----------|----------------|
   | 0 | MONTH    | datetime64[ns] |
   | 1 | BUG_ID   | int64          |
   | 2 | MODULE   | category       |
   | 3 | variable | object         |
   | 4 | value    | int64          |

   - **`variable`**: Possible values:
     - `OPENED`
     - `REOPENED`
     - `FALSE_CLOSED`
     - `CLOSED`
   - **`value`**: Variation of the magnitude expressed in `variable`.

6. `ct_bug_variation_vs_module`: Summary crosstab table of the evolution of open bugs per month for the most relevant modules.
   - Rows: Months, expressed in 'YYYY-MM' format.
   - Columns: Selected modules.

### Top contributors

1. `df_bug_reporters` and `df_top_bug_reporters`
   - Stats of `df_current_bug_state.ISSUER` series.
   - Adds "organization" column based on email.
2. `df_bug_reporting_companies` and `df_top_bug_reporting_companies`
   - From `df_bug_reporters`, grouped by company.
3. `df_owner_events_by_bug`

   ```python
   df_owner_events_by_bug = df_bug_full[ df_bug_full.OPERATION=='assigned_to' ]
   ```

4. `df_current_owner_bug`

   ```python
   df_current_owner_bug = get_current_owner_bug(df_owner_events_by_bug)
   ```

   | #  | Column          | Dtype          |
   |--- | ------          | -----          |
   | 0  | BUG_ID          | int64          |
   | 1  | TIMESTAMP       | datetime64[ns] |
   | 2  | OPERATION       | category       |
   | 3  | VALUE           | object         |
   | 4  | RELEASE         | category       |
   | 5  | MODULE          | category       |
   | 6  | BUG_DESCRIPTION | object         |
   | 7  | ROW_NUMBER      | int64          |
   | 8  | MONTH           | datetime64[ns] |
   | 9  | AGE             | category       |

5. `df_bug_assignees`: Assignees of currently open bugs.

   | # | Column  | Non-Null Count | Dtype  |
   |---|---------|----------------|--------|
   | 0 | owner   | 12 non-null    | object |
   | 1 | n_bugs  | 12 non-null    | int64  |
   | 2 | company | 12 non-null    | object |

6. `df_bug_company_assignees`: Aggregation of bug assignees per company, sorted.

7. `df_bug_closers`, `df_top_bug_closers`: Last assignee of bugs already closed

   | # | Column  | Non-Null Count | Dtype  |
   |---|---------|----------------|--------|
   | 0 | closer  | 12 non-null    | object |
   | 1 | n_bugs  | 12 non-null    | int64  |
   | 2 | company | 12 non-null    | object |
