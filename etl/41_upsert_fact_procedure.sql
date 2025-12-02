-- etl/39_upsert_fact_procedure.sql
-- Upsert mart.fact_procedure from stage.procedures_stg
-- Policy: one row per procedure attempt (pcr + code + time + attempts).
-- Newer last_modified wins.

RESET ROLE;
SET ROLE ems_owner;
BEGIN;

WITH latest AS (
    SELECT *
    FROM (
        SELECT
            s.*,
            ROW_NUMBER() OVER (
                PARTITION BY
                    s.pcr_number,
                    s.procedure_time,
                    UPPER(BTRIM(s.procedure_code)),
                    COALESCE(s.attempts, 1)
                ORDER BY s.last_modified DESC
            ) AS rn
        FROM stage.procedures_stg s
        WHERE procedure_code IS NOT NULL
          AND procedure_time IS NOT NULL
    ) x
    WHERE rn = 1
),
lk AS (
    SELECT
        l.pcr_number,
        l.procedure_time,
        COALESCE(l.attempts, 1) AS attempts,
        l.successful,
        l.equipment_size,
        l.complication_list,
        l.patient_response,
        l.procedure_authorization,
        l.authorizing_physician,
        l.vascular_access_location,
        l.prior_to_ems,
        l.crew_member_id,
        l.performer_role,
        l.procedure_description,
        l.last_modified,
        dp.procedure_key
    FROM latest l
    JOIN mart.dim_procedure dp
      ON dp.procedure_code = UPPER(BTRIM(l.procedure_code))
)

INSERT INTO mart.fact_procedure (
    pcr_number,
    procedure_key,
    procedure_time,
    attempts,
    successful,
    equipment_size,
    complication_list,
    patient_response,
    procedure_authorization,
    authorizing_physician,
    vascular_access_location,
    prior_to_ems,
    crew_member_id,
    performer_role,
    procedure_description,
    last_modified
)
SELECT
    pcr_number,
    procedure_key,
    procedure_time,
    attempts,
    successful,
    equipment_size,
    complication_list,
    patient_response,
    procedure_authorization,
    authorizing_physician,
    vascular_access_location,
    prior_to_ems,
    crew_member_id,
    performer_role,
    procedure_description,
    last_modified
FROM lk
ON CONFLICT (pcr_number, procedure_key, procedure_time, attempts) DO UPDATE
SET
    successful              = EXCLUDED.successful,
    equipment_size          = EXCLUDED.equipment_size,
    complication_list       = EXCLUDED.complication_list,
    patient_response        = EXCLUDED.patient_response,
    procedure_authorization = EXCLUDED.procedure_authorization,
    authorizing_physician   = EXCLUDED.authorizing_physician,
    vascular_access_location= EXCLUDED.vascular_access_location,
    prior_to_ems            = EXCLUDED.prior_to_ems,
    crew_member_id          = EXCLUDED.crew_member_id,
    performer_role          = EXCLUDED.performer_role,
    procedure_description   = EXCLUDED.procedure_description,
    last_modified           = EXCLUDED.last_modified
WHERE EXCLUDED.last_modified > mart.fact_procedure.last_modified;

COMMIT;
RESET ROLE;
