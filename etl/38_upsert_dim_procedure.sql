-- etl/31_upsert_dim_procedure.sql
-- Build/refresh mart.dim_procedure from stage.procedures_stg
-- Policy: one row per SNOMED code (TEXT). Keep latest non-NULL name, bump last_seen_at.

RESET ROLE; SET ROLE etl_writer;
BEGIN;

WITH src AS (
  SELECT DISTINCT
         NULLIF(btrim(procedure_code), '')              AS procedure_code,
         NULLIF(btrim(procedure_description), '')       AS procedure_name
  FROM stage.procedures_stg
  WHERE procedure_code IS NOT NULL
    AND NULLIF(btrim(procedure_code), '') IS NOT NULL
),
touch AS (
  INSERT INTO mart.dim_procedure (procedure_code, procedure_name, is_active, first_seen_at, last_seen_at)
  SELECT s.procedure_code, s.procedure_name, TRUE, now(), now()
  FROM src s
  ON CONFLICT (procedure_code) DO UPDATE
    SET procedure_name = COALESCE(EXCLUDED.procedure_name, mart.dim_procedure.procedure_name),
        is_active      = TRUE,
        last_seen_at   = now()
  RETURNING 1
)
SELECT 1;

COMMIT;
RESET ROLE;
