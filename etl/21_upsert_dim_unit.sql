BEGIN;

WITH src AS (
  SELECT DISTINCT UPPER(BTRIM(unit_code)) AS code
  FROM stage.incidents_stg
  WHERE unit_code IS NOT NULL
),
prepared AS (
  SELECT
    code AS unit_code,
    CASE
      WHEN code IN ('EMS1','EMS10') THEN 'ALS'
      WHEN code LIKE 'P%'           THEN 'ALS'
      WHEN code LIKE 'A%'           THEN 'BLS'
      ELSE 'UNKNOWN'
    END AS service_level
  FROM src
)
INSERT INTO mart.dim_unit (unit_code, service_level)
SELECT unit_code, service_level
FROM prepared
ON CONFLICT (unit_code) DO UPDATE
SET service_level = EXCLUDED.service_level;

COMMIT;
