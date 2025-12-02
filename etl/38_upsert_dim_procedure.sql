-- etl/38_upsert_dim_procedure.sql
-- Build/refresh mart.dim_procedure from stage.procedures_stg
-- Policy: one row per procedure_code. Keep latest non-NULL display_name.

RESET ROLE;
SET ROLE ems_owner;
BEGIN;

WITH src AS (
    SELECT DISTINCT
        UPPER(BTRIM(procedure_code))          AS procedure_code,
        NULLIF(BTRIM(procedure_description), '') AS display_name
    FROM stage.procedures_stg
    WHERE procedure_code IS NOT NULL
      AND NULLIF(BTRIM(procedure_code), '') IS NOT NULL
),
upsert AS (
    INSERT INTO mart.dim_procedure (procedure_code, display_name)
    SELECT s.procedure_code, s.display_name
    FROM src s
    ON CONFLICT (procedure_code) DO UPDATE
    SET display_name = COALESCE(EXCLUDED.display_name,
                                mart.dim_procedure.display_name)
    RETURNING 1
)
SELECT 1;

COMMIT;
RESET ROLE;
