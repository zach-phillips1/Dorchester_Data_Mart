$env:DB_HOST = $env:DB_HOST ?? "localhost"
$env:DB_PORT = $env:DB_PORT ?? "5432"
$env:DB_NAME = $env:DB_NAME ?? "postgres"
$env:DB_USER = $env:DB_USER ?? "postgres"

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force -Path "logs" | Out-Null
$logfile = "logs\etl_run_$ts.log"

Write-Host "Running ETL -> $($env:DB_USER)@$($env:DB_HOST):$($env:DB_PORT)/$($env:DB_NAME)"
Write-Host "Logging to $logfile"

& psql `
  -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME `
  -v ON_ERROR_STOP=1 `
  -f etl/00_run_all_upserts.sql 2>&1 | Tee-Object -FilePath $logfile
