#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST:-192.168.42.184}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-ems_mart}"
DB_USER="${DB_USER:-zach}"
DB_SSLMODE="${DB_SSLMODE:-prefer}"

ts="$(date +'%Y%m%d_%H%M%S')"
mkdir -p logs
logfile="logs/etl_run_${ts}.log"

echo "Running ETL -> ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
echo "Logging to ${logfile}"

psql \
  "host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$DB_NAME sslmode=$DB_SSLMODE" \
  -v ON_ERROR_STOP=1 \
  -f etl/00_run_all_upserts.sql \
  |& tee "$logfile"
