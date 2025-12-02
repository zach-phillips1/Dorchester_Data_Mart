RESET ROLE; SET ROLE ems_owner;
BEGIN;

WITH src AS (
  SELECT DISTINCT
         NULLIF(btrim(med_given_code::text), '') AS medication_code,
         NULLIF(btrim(med_given), '')            AS medication_name
  FROM stage.medications_stg
  WHERE med_given_code IS NOT NULL OR NULLIF(btrim(med_given), '') IS NOT NULL
),
ins AS (
  INSERT INTO mart.dim_medication (medication_code, medication_name, is_active, first_seen_at, last_seen_at)
  SELECT medication_code, medication_name, TRUE, now(), now()
  FROM src
  ON CONFLICT (medication_code) DO UPDATE
    SET medication_name = COALESCE(EXCLUDED.medication_name, mart.dim_medication.medication_name),
        is_active      = TRUE,
        last_seen_at   = now()
  RETURNING 1
)
SELECT 1;

COMMIT;
RESET ROLE;
