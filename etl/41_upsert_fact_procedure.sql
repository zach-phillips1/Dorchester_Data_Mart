-- etl/41_upsert_fact_procedure.sql
-- Load mart.fact_procedure from stage.procedures_stg
-- Policies:
--   * Local timestamps only
--   * Skip rows with NULL pcr_number or procedure_time
--   * Join to mart.dim_procedure by procedure_code
--   * Natural key: (pcr_number, procedure_time, procedure_key, COALESCE(crew_member_id,''))
--   * Newer-wins by last_modified

RESET ROLE; SET ROLE etl_writer;
BEGIN;

WITH base AS (
  SELECT
    s.pcr_number,
    s.procedure_time,
    COALESCE(s.last_modified, s.procedure_time) AS last_modified,

    -- Join key
    NULLIF(btrim(s.procedure_code), '')         AS procedure_code,
    -- Crew/context
    s.crew_member_id,
    s.performer_role,
    s.prior_to_ems,
    s.procedure_authorization,
    s.authorizing_physician,
    s.vascular_access_location,
    -- Core
    s.equipment_size,
    s.attempts,
    s.successful,
    s.patient_response
  FROM stage.procedures_stg s
  WHERE s.pcr_number IS NOT NULL
    AND s.procedure_time IS NOT NULL
),
parsed AS (
  SELECT
    b.*,
    CASE
      WHEN b.prior_to_ems IS NULL THEN NULL
      WHEN lower(trim(b.prior_to_ems)) IN ('y','yes','t','true','1') THEN TRUE
      WHEN lower(trim(b.prior_to_ems)) IN ('n','no','f','false','0') THEN FALSE
      ELSE NULL
    END AS prior_to_ems_bool,
    CASE
      WHEN b.successful IS NULL THEN NULL
      WHEN lower(trim(b.successful)) IN ('y','yes','t','true','1') THEN TRUE
      WHEN lower(trim(b.successful)) IN ('n','no','f','false','0') THEN FALSE
      ELSE NULL
    END AS successful_bool
  FROM base b
),
joined AS (
  SELECT
    p.pcr_number,
    p.procedure_time,
    p.last_modified,
    d.procedure_key,
    p.crew_member_id,
    p.performer_role,
    p.prior_to_ems_bool        AS prior_to_ems,
    p.procedure_authorization,
    p.authorizing_physician,
    p.vascular_access_location,
    p.equipment_size,
    p.attempts,
    p.successful_bool          AS successful,
    p.patient_response
  FROM parsed p
  JOIN mart.dim_procedure d
    ON d.procedure_code = p.procedure_code
)
INSERT INTO mart.fact_procedure (
  pcr_number, procedure_time, last_modified,
  procedure_key,
  crew_member_id, performer_role, prior_to_ems, procedure_authorization,
  authorizing_physician, vascular_access_location,
  equipment_size, attempts, successful, patient_response
)
SELECT
  j.pcr_number, j.procedure_time, j.last_modified,
  j.procedure_key,
  j.crew_member_id, j.performer_role, j.prior_to_ems, j.procedure_authorization,
  j.authorizing_physician, j.vascular_access_location,
  j.equipment_size, j.attempts, j.successful, j.patient_response
FROM joined j
-- Natural-key upsert; index was created in DDL as ux_fact_procedure_natkey
ON CONFLICT (pcr_number, procedure_time, procedure_key, COALESCE(crew_member_id, '')) DO UPDATE
SET
  last_modified            = EXCLUDED.last_modified,
  crew_member_id           = EXCLUDED.crew_member_id,
  performer_role           = EXCLUDED.performer_role,
  prior_to_ems             = EXCLUDED.prior_to_ems,
  procedure_authorization  = EXCLUDED.procedure_authorization,
  authorizing_physician    = EXCLUDED.authorizing_physician,
  vascular_access_location = EXCLUDED.vascular_access_location,
  equipment_size           = EXCLUDED.equipment_size,
  attempts                 = EXCLUDED.attempts,
  successful               = EXCLUDED.successful,
  patient_response         = EXCLUDED.patient_response
WHERE EXCLUDED.last_modified > mart.fact_procedure.last_modified
   OR mart.fact_procedure.last_modified IS NULL;

COMMIT;
RESET ROLE;
