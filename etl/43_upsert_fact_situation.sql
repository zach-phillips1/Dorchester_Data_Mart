RESET ROLE;
SET ROLE ems_owner;

BEGIN;

WITH latest AS (
    SELECT *
    FROM (
        SELECT s.*,
               ROW_NUMBER() OVER (
                   PARTITION BY pcr_number
                   ORDER BY last_modified DESC
               ) AS rn
        FROM stage.situation_stg s
    ) x
    WHERE rn = 1
)

INSERT INTO mart.fact_situation AS fs (
    pcr_number,
    symptom_onset_time,
    last_modified,
    possible_injury,
    injury_flag,
    complaint_type,
    complaint_statement,
    complaint_duration,
    complaint_time_unit,
    complaint_location,
    complaint_organ_system,
    primary_symptom,
    other_symptoms,
    other_symptoms_icd,
    other_symptoms_list,
    primary_impression_code,
    primary_impression_description,
    secondary_impression_code,
    secondary_impression_description,
    initial_priority,
    symptom_last_known_well
)
SELECT
    l.pcr_number,
    l.symptom_onset_time,
    l.last_modified,
    l.possible_injury,
    (l.possible_injury ILIKE '%Trauma%'),
    l.complaint_type,
    l.complaint_statement,
    l.complaint_duration,
    l.complaint_time_unit,
    l.complaint_location,
    l.complaint_organ_system,
    l.primary_symptom,
    l.other_symptoms,
    l.other_symptoms_icd,
    l.other_symptoms_list,
    l.primary_impression_code,
    l.primary_impression_description,
    l.secondary_impression_code,
    l.secondary_impression_description,
    l.initial_priority,
    l.symptom_last_known_well
FROM latest l
WHERE l.symptom_onset_time IS NOT NULL  -- mirrors your Report Writer filter
ON CONFLICT (pcr_number) DO UPDATE
SET symptom_onset_time              = EXCLUDED.symptom_onset_time,
    last_modified                   = EXCLUDED.last_modified,
    possible_injury                 = EXCLUDED.possible_injury,
    injury_flag                     = EXCLUDED.injury_flag,
    complaint_type                  = EXCLUDED.complaint_type,
    complaint_statement             = EXCLUDED.complaint_statement,
    complaint_duration              = EXCLUDED.complaint_duration,
    complaint_time_unit             = EXCLUDED.complaint_time_unit,
    complaint_location              = EXCLUDED.complaint_location,
    complaint_organ_system          = EXCLUDED.complaint_organ_system,
    primary_symptom                 = EXCLUDED.primary_symptom,
    other_symptoms                  = EXCLUDED.other_symptoms,
    other_symptoms_icd              = EXCLUDED.other_symptoms_icd,
    other_symptoms_list             = EXCLUDED.other_symptoms_list,
    primary_impression_code         = EXCLUDED.primary_impression_code,
    primary_impression_description  = EXCLUDED.primary_impression_description,
    secondary_impression_code       = EXCLUDED.secondary_impression_code,
    secondary_impression_description= EXCLUDED.secondary_impression_description,
    initial_priority                = EXCLUDED.initial_priority,
    symptom_last_known_well         = EXCLUDED.symptom_last_known_well
WHERE fs.last_modified < EXCLUDED.last_modified;

COMMIT;
