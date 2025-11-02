#!/bin/bash

input_dump=${1:-"../../../.credentials/backups/osm_metrics_db_ORIGINAL.sql"}
output_dump=${2:-"../../../.credentials/backups/osm_metrics_db.sql"}

# Define tables and its existing columns (i.e., without `auto_id`)
declare -A tables_columns
tables_columns=(
  ["builds_info"]="job, build, timestamp, duration, build_result, test_result, pass_count, fail_count"
  ["robot_reports"]="job, build, id, name, source, status, starttime, endtime, pass, fail, failed_test_id, failed_test_name, failed_keyword"
  ["robot_reports_extended"]="job, build, suite_id, suite_name, test_id, test_name, keyword_name, status, starttime, endtime"
)

cp "$input_dump" "$output_dump"

# Step 1: Insert in each `CREATE TABLE` the new column `auto_id` PRIMARY KEY AUTO_INCREMENT
sed -i "/CREATE TABLE \`/,/);/{
  /CREATE TABLE \`/!b
  s/(\s*/(\n  \`auto_id\` BIGINT AUTO_INCREMENT PRIMARY KEY,\n/
  :a
  N
  s/\n\n/\n/
  ta
}" "$output_dump"

# Step 2: For each table, modify each `INSERT INTO` to specify the columns explicitly
for table in "${!tables_columns[@]}"; do
  columnas=${tables_columns[$table]}
  sed -i "s/INSERT INTO \`$table\` VALUES/INSERT INTO \`$table\` ($columnas) VALUES/g" "$output_dump"
done

