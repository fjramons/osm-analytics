# README  - Installations analysis

## Usage

Open and run the `installation_analysis.ipynb` notebook. The results will be published in the `outputs` folder:

- `installation_analysis.html`: Full report.

It can also be executed from the command line as:

```bash
jupyter nbconvert --to html --output outputs/installation_analysis.html --TemplateExporter.exclude_input=True --execute installation_analysis.ipynb
```

### Unattended execution

TBC.

<!-- UNIX/OSX/Linux:

```bash
./launch_installation_analysis.sh
```

Windows:

```powershell
launch_installation_analysis.cmd
``` -->

## Environment variables

TBC.

<!-- Default behaviours can be changed by setting specific environment variables:

- `INPUTS_FOLDER`: Folder where input data is located.
  - If not set, it will be the `etl_outputs` subfolder.
- `OUTPUTS_FOLDER`: Folder to save results.
  - If not set, it will use the `report_outputs` subfolder.
- `SKIP_EXPORT_TO_HTML`: If set, the Notebook is not exported to HTML. -->

## Main generated dataframes

### Basic dataframes

1. `df_install_events_and_operations`: Raw list of install events and operations. Excludes malformed lines of the original CSV file, and splits the `queries` field so that they become fully-fledged columns.

   ```python
   df_install_events_and_operations = (
       load_install_events_and_operations()
       .query("timestamp >= @date_first_valid_sample")
   )
   ```

   | # | Column          | Dtype          |
   |---|-----------------|----------------|
   | 0 | timestamp       | datetime64[ns] |
   | 1 | location        | category       |
   | 2 | installation_id | object         |
   | 3 | local_ts        | object         |
   | 4 | event           | category       |
   | 5 | operation       | category       |
   | 6 | value           | object         |
   | 7 | comment         | object         |
   | 8 | tags            | object         |

   - `timestamp`: Server-side timestamp.
   - `location`: Either `public` installations (from outside) or `local` installations (from ETSI's environment).
   - `installation_id`: Unique identifier of the installation attempt.
   - `local_ts`: Local-side timestamp.
   - `event`: Reported installation event.
   - `operation`: Reported operation.
   - `value`: Additional info of the operation. Used to report errors in the operation.
   - `comment`: Comment about the operation (optional).
   - `tags`: Tags related to the operation (optional)

2. `df_achieved_operations`: List of operations that have been completed successfully.

   ```bash
   df_achieved_operations = get_achieved_operations(df_install_events_and_operations)
   ```

   | #   Column          | Dtype          |
   |---------------------|----------------|
   | 0   timestamp       | datetime64[ns] |
   | 1   location        | category       |
   | 2   installation_id | object         |
   | 3   local_ts        | object         |
   | 4   event           | category       |
   | 5   achievement     | category       |
   | 6   comment         | object         |
   | 7   tags            | object         |

   - `timestamp`: Server-side timestamp.
   - `location`: Either `public` installations (from outside) or `local` installations (from ETSI's environment).
   - `installation_id`: Unique identifier of the installation attempt.
   - `local_ts`: Local-side timestamp.
   - `event`: Reported installation event where the operation was successful.
   - `achievement`: Operation reported as successful.
   - `comment`: Comment about the operation (optional).
   - `tags`: Tags related to the operation (optional)

3. `df_info_operations_wide`: Brief summary of all installation attempts, specifying the release, the docker tag, the installer type and, if applicable, the reasons of failure.

   ```bash
   df_info_operations_wide = get_info_operations_wide(df_install_events_and_operations)
   ```

   | # | Column            | Dtype  |
   |---|-------------------|--------|
   | 0 | installation_id   | object |
   | 1 | release           | object |
   | 2 | docker_tag        | object |
   | 3 | installation_type | object |
   | 4 | osm_unhealthy     | object |
   | 5 | fatal             | object |

   - `installation_id`: Unique identifier of the installation attempt.
   - `release`: Release that was requested.
   - `docker_tag`: Docker tag.
   - `installation_type`: Installer type (as of today, `Default`, `Charmed` or `Other`).
   - `osm_unhealthy`: Report of completed but unhealthy installation. Otherwise, NaN.
   - `fatal`: Report of fatal error during installation. Otherwise, NaN.

4. `df_installations_wide`: Dataframe of achieved operations (`df_operations`) enriched with the columns of the summary of each installation attempt (`df_info_operations_wide`).

| #  | Column            | Dtype          |
|----|-------------------|----------------|
| 0  | timestamp         | datetime64[ns] |
| 1  | location          | category       |
| 2  | installation_id   | object         |
| 3  | local_ts          | object         |
| 4  | event             | category       |
| 5  | achievement       | category       |
| 6  | comment           | object         |
| 7  | tags              | object         |
| 8  | release           | object         |
| 9  | docker_tag        | object         |
| 10 | installation_type | object         |
| 11 | osm_unhealthy     | object         |
| 12 | fatal             | object         |

### Time series of installation attempts per release

- `df_installations_per_week`: Number of installations per week and aggregated per release.

  | # | Column               | Dtype          |
  |---|----------------------|----------------|
  | 0 | timestamp            | datetime64[ns] |
  | 1 | release              | object         |
  | 2 | weekly_installations | int64          |
  | 3 | total_installations  | int64          |

  - `timestamp`: Timestamp representative of the week of aggregation.
  - `release`: Release whose installation attempts are aggregated in this sample.
  - `weekly_installations`: Number of installations of a given release during the week of reference.
  - `total_installations`: Cumulative number of installations of a given release until the week of reference (included).

### Analysis of progress during installation

- `df_funnels_per_release`: Count of the number of operations of each type achieved per release and installation type.

  ```bash
  df_funnels_per_release = get_funnels_per_release(df_installations_wide)
  ```

  | # | Column            | Dtype    |
  |---| ------            | -----    |
  | 0 | achievement       | category |
  | 1 | release           | object   |
  | 2 | installation_type | object   |
  | 3 | count             | int64    |
  | 4 | percentage        | float64  |

  - `achievement`.
  - `release`.
  - `installation_type`.
  - `count`: Absolute number of achievements per installation release and installation type.
  - `percentage`: Percentage with respect to the total number of installations attempts of that release and installation type.

### Analysis of failed installation attempts

1. `df_fatal_errors`: Dataframe with count of fatal errors per release, location and installation type.

   | # | Column            | Dtype    |
   |---|-------------------|----------|
   | 0 | location          | category |
   | 1 | release           | object   |
   | 2 | installation_type | object   |
   | 3 | fatal             | object   |
   | 4 | count             | int64    |

   - `location`.
   - `release`.
   - `installation_type`.
   - `fatal`: Type of fatal error.
   - `count`.

2. `df_unhealthy_installs`: Dataframe with count of installations reporting unhealthy state upon install completion (per release, location and installation type).

  | # | Column            | Dtype    |
  |---|-------------------|----------|
  | 0 | location          | category |
  | 1 | release           | object   |
  | 2 | installation_type | object   |
  | 3 | osm_unhealthy     | object   |
  | 4 | count             | int64    |

- `location`.
- `release`.
- `installation_type`.
- `osm_unhealthy`: Type of unhealthy state reported.
- `count`.
