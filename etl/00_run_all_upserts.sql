-- etl/00_run_all_upserts.sql
-- Runs all upserts in a single psql session

\set ON_ERROR_STOP on

-- (Optional) If your scripts rely on role switching, you can do it here too.
-- SET ROLE ems_owner;

\echo '== Running DIM upserts =='
\i etl/31_upsert_dim_unit.sql
\i etl/32_upsert_dim_destination.sql
\i etl/33_upsert_dim_disposition.sql
\i etl/36_upsert_dim_vital_type.sql
\i etl/38_upsert_dim_procedure.sql
\i etl/39_upsert_dim_medication.sql

\echo '== Running FACT upserts =='
\i etl/34_upsert_fact_incident.sql
\i etl/37_upsert_fact_vital.sql
\i etl/41_upsert_fact_procedure.sql
\i etl/42_upsert_fact_medication.sql
\i etl/43_upsert_fact_situation.sql

\echo '== Done =='
