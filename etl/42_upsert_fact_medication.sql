-- 41_upsert_fact_medication.sql
RESET ROLE; SET ROLE ems_owner;
BEGIN;

WITH latest AS (
    SELECT *
    FROM (
        SELECT s.*,
               ROW_NUMBER() OVER (
                   PARTITION BY 
                   pcr_number, 
                   med_given_code,
                   med_admin_date_time
                   ORDER BY last_modified DESC
               ) AS rn
        FROM stage.medications_stg s
    ) x
    WHERE rn = 1
),

lk AS (
    SELECT
        l.*,
        COALESCE(
            dm.medication_key,
            (SELECT medication_key
             FROM mart.dim_medication
             WHERE medication_code = '_UNK')
        ) AS medication_key
    FROM latest l
    LEFT JOIN mart.dim_medication dm
        ON dm.medication_code = l.med_given_code::text
)

INSERT INTO mart.fact_medication (
    pcr_number,
    medication_key,
    med_admin_date_time,
    med_admin_prior_to_ems,
    med_given,
    med_admin_route,
    med_admin_route_code,
    med_dosage,
    med_dosage_unit,
    med_response,
    med_complication_list,
    med_crew_admin_id,
    med_crew_role,
    med_authorization,
    med_authorization_md,
    last_modified
)
SELECT
    pcr_number,
    medication_key,
    med_admin_date_time,
    med_admin_prior_to_ems,
    med_given,
    med_admin_route,
    med_admin_route_code,
    med_dosage,
    med_dosage_unit,
    med_response,
    med_complication_list,
    med_crew_admin_id,
    med_crew_role,
    med_authorization,
    med_authorization_md,
    last_modified
FROM lk

ON CONFLICT (pcr_number, medication_key, med_admin_date_time)
DO UPDATE SET
    med_admin_prior_to_ems = EXCLUDED.med_admin_prior_to_ems,
    med_given              = EXCLUDED.med_given,
    med_admin_route        = EXCLUDED.med_admin_route,
    med_admin_route_code   = EXCLUDED.med_admin_route_code,
    med_dosage             = EXCLUDED.med_dosage,
    med_dosage_unit        = EXCLUDED.med_dosage_unit,
    med_response           = EXCLUDED.med_response,
    med_complication_list  = EXCLUDED.med_complication_list,
    med_crew_admin_id      = EXCLUDED.med_crew_admin_id,
    med_crew_role          = EXCLUDED.med_crew_role,
    med_authorization      = EXCLUDED.med_authorization,
    med_authorization_md   = EXCLUDED.med_authorization_md,
    last_modified          = EXCLUDED.last_modified
WHERE EXCLUDED.last_modified > mart.fact_medication.last_modified;

COMMIT;
RESET ROLE;
