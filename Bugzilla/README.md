# README  - Bugzilla analysis

## Usage

TODO:

## Main generated dataframes

1. `df_bug_full`
2. `df_bug_openings`
3. `df_status_changes_by_bug`
4. `df_current_bug_state`
5. `df_open_bugs`
6. `df_bug_summary`

### `df_bug_full`

RangeIndex: 16662 entries, 0 to 16661

Data columns (total 10 columns):

| #  | Column          | Non-Null Count | Dtype          |
|--- | ------          | -------------- | -----          |
| 0  | TIMESTAMP       | 16662 non-null | datetime64[ns] |
| 1  | BUG_ID          | 16662 non-null | int64          |
| 2  | OPERATION       | 16662 non-null | category       |
| 3  | VALUE           | 16561 non-null | object         |
| 4  | RELEASE         | 16662 non-null | category       |
| 5  | MODULE          | 16662 non-null | category       |
| 6  | BUG_DESCRIPTION | 16662 non-null | object         |
| 7  | ROW_NUMBER      | 16662 non-null | int64          |
| 8  | MONTH           | 16662 non-null | period[M]      |
| 9  | AGE             | 16662 non-null | category       |

dtypes: category(4), datetime64[ns] (1), int64(2), object(2), period[M] (1)

memory usage: 849.1+ KB

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

### `df_bug_openings`

RangeIndex: 1644 entries, 0 to 1643

Data columns (total 11 columns):

| #  | Column          | Non-Null Count | Dtype          |
|--- | ------          | -------------- | -----          |
| 0  | BUG_ID          | 1644 non-null  | int64          |
| 1  | TIMESTAMP       | 1644 non-null  | datetime64[ns] |
| 2  | OPERATION       | 1644 non-null  | object         |
| 3  | VALUE           | 1644 non-null  | object         |
| 4  | RELEASE         | 1644 non-null  | category       |
| 5  | MODULE          | 1644 non-null  | category       |
| 6  | BUG_DESCRIPTION | 1644 non-null  | object         |
| 7  | ROW_NUMBER      | 1644 non-null  | int64          |
| 8  | MONTH           | 1644 non-null  | period[M]      |
| 9  | AGE             | 1644 non-null  | category       |
| 10 | ISSUER          | 1644 non-null  | object         |

dtypes: category(3), datetime64[ns] (1), int64(2), object(4), period[M] (1)

memory usage: 109.9+ KB

### `df_status_changes_by_bug`

RangeIndex: 3599 entries, 0 to 3598

Data columns (total 11 columns):

| #  | Column          | Non-Null Count | Dtype          |
|--- | ------          | -------------- | -----          |
| 0  | TIMESTAMP       | 3599 non-null  | datetime64[ns] |
| 1  | BUG_ID          | 3599 non-null  | int64          |
| 2  | OPERATION       | 3599 non-null  | object         |
| 3  | VALUE           | 3599 non-null  | category       |
| 4  | RELEASE         | 3599 non-null  | category       |
| 5  | MODULE          | 3599 non-null  | category       |
| 6  | BUG_DESCRIPTION | 3599 non-null  | object         |
| 7  | ROW_NUMBER      | 3599 non-null  | int64          |
| 8  | MONTH           | 3599 non-null  | period[M]      |
| 9  | AGE             | 3599 non-null  | category       |
| 10 | ISSUER          | 1644 non-null  | object         |

dtypes: category(4), datetime64[ns](1), int64(2), object(3), period[M](1)

memory usage: 213.4+ KB

### `df_current_bug_state`

Int64Index: 1644 entries, 6 to 3598

Data columns (total 11 columns):

| #  | Column          | Non-Null Count | Dtype          |
|--- | ------          | -------------- | -----          |
| 0  | BUG_ID          | 1644 non-null  | int64          |
| 1  | TIMESTAMP       | 1644 non-null  | datetime64[ns] |
| 2  | OPERATION       | 1644 non-null  | object         |
| 3  | VALUE           | 1644 non-null  | category       |
| 4  | RELEASE         | 1644 non-null  | category       |
| 5  | MODULE          | 1644 non-null  | category       |
| 6  | BUG_DESCRIPTION | 1644 non-null  | object         |
| 7  | ROW_NUMBER      | 1644 non-null  | int64          |
| 8  | MONTH           | 1644 non-null  | period[M]      |
| 9  | AGE             | 1644 non-null  | category       |
| 10 | ISSUER          | 1644 non-null  | object         |

dtypes: category(4), datetime64[ns](1), int64(2), object(3), period[M](1)

memory usage: 111.6+ KB

### `df_open_bugs`

Int64Index: 131 entries, 2394 to 3596

Data columns (total 11 columns):

| #  | Column          | Non-Null Count | Dtype          |
|--- | ------          | -------------- | -----          |
| 0  | BUG_ID          | 131 non-null   | int64          |
| 1  | TIMESTAMP       | 131 non-null   | datetime64[ns] |
| 2  | OPERATION       | 131 non-null   | object         |
| 3  | VALUE           | 131 non-null   | category       |
| 4  | RELEASE         | 131 non-null   | category       |
| 5  | MODULE          | 131 non-null   | category       |
| 6  | BUG_DESCRIPTION | 131 non-null   | object         |
| 7  | ROW_NUMBER      | 131 non-null   | int64          |
| 8  | MONTH           | 131 non-null   | period[M]      |
| 9  | AGE             | 131 non-null   | category       |
| 10 | ISSUER          | 131 non-null   | object         |

dtypes: category(4), datetime64[ns](1), int64(2), object(3), period[M](1)

memory usage: 11.1+ KB

### `df_bug_summary`

This summary table (`df_bug_summmary`) aims to collect for each known bug (historical or active):

- Basic bug details:
  - Bug id
  - Bug description
  - Issuer (reporter of the bug)
- Latest states of the bug:
  - Currently assigned status
  - Currently assigned Release
  - Currently assigned MDG
  - Currently assigned owner
- Relevant timestamps:
  - Date of creation.
  - Date of latest change of state.
  - Date of latest event.
- Age tags:
  - Date of creation
  - Date of last event.
- Other relevant summary statistics, such as:
  - No. Release reassignments.
  - No. State reassignments.
  - No. State reassignments to `RESOLVED`.

Int64Index: 1644 entries, 11 to 1655

Data columns (total 22 columns):

| #  | Column               | Non-Null Count | Dtype |
|--- | ------               | -------------- | ----- |
| 0  | BUG_DESCRIPTION      | 1644 non-null  | object |
| 1  | ISSUER               | 1644 non-null  | object |
| 2  | CREATION_TIME        | 1644 non-null  | datetime64[ns] |
| 3  | CREATION_AGE         | 1644 non-null  | category |
| 4  | STATE                | 1644 non-null  | category |
| 5  | STATE_UPDATE_TIME    | 1644 non-null  | datetime64[ns] |
| 6  | STATE_UPDATE_AGE     | 1644 non-null  | category |
| 7  | STATE_CHANGES        | 1644 non-null  | int64 |
| 8  | CHANGES_TO_RESOLVED  | 1644 non-null  | int64 |
| 9  | RELEASE              | 1644 non-null  | category |
| 10 | MODULE               | 1644 non-null  | category |
| 11 | RELEASE_CHANGES      | 1644 non-null  | int64 |
| 12 | MODULE_CHANGES       | 1644 non-null  | int64 |
| 13 | LAST_ASSIGNMENT_TIME | 597 non-null   | datetime64[ns] |
| 14 | OWNER                | 597 non-null   | object |
| 15 | MONTH                | 597 non-null   | period[M] |
| 16 | OWNER_CHANGES        | 1644 non-null  | int64 |
| 17 | LAST_EVENT           | 1644 non-null  | category |
| 18 | LAST_EVENT_TIME      | 1644 non-null  | datetime64[ns] |
| 19 | LAST_EVENT_AGE       | 1644 non-null  | category |
| 20 | SOLVED               | 1644 non-null  | bool |
| 21 | BUG_RESOLUTION_TIME  | 1513 non-null  | timedelta64[ns] |

dtypes: bool(1), category(7), datetime64[ns] (4), int64(5), object(3), period[M] (1), timedelta64[ns] (1)

memory usage: 273.4+ KB
