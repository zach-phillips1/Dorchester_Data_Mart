SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS mart.fact_situation (

    ----------------------------------------------------------------------
    -- Identity / Chronology
    ----------------------------------------------------------------------
    pcr_number                      TEXT PRIMARY KEY,
    symptom_onset_time              TIMESTAMP WITHOUT TIME ZONE,
    last_modified                   TIMESTAMP WITHOUT TIME ZONE NOT NULL,

    ----------------------------------------------------------------------
    -- eSituation.02 – Possible Injury + derived flag
    ----------------------------------------------------------------------
    possible_injury                 TEXT,
    injury_flag                     BOOLEAN,   -- TRUE if Trauma/BOTH; core for TRAUMA-01

    ----------------------------------------------------------------------
    -- eSituation.PatientComplaintGroup (eSituation.03–10)
    ----------------------------------------------------------------------
    complaint_type                  TEXT,
    complaint_statement             TEXT,
    complaint_duration              INTEGER,
    complaint_time_unit             TEXT,
    complaint_location              TEXT,
    complaint_organ_system          TEXT,
    primary_symptom                 TEXT,

    other_symptoms                  TEXT,
    other_symptoms_icd              TEXT,
    other_symptoms_list             TEXT,

    ----------------------------------------------------------------------
    -- eSituation.11 & 12 – Provider Impressions
    ----------------------------------------------------------------------
    primary_impression_code         TEXT,
    primary_impression_description  TEXT,
    secondary_impression_code       TEXT,
    secondary_impression_description TEXT,

    ----------------------------------------------------------------------
    -- eSituation.13 – Initial Patient Acuity
    ----------------------------------------------------------------------
    initial_priority                TEXT,

    ----------------------------------------------------------------------
    -- eSituation.18 – Time Last Known Well (Stroke)
    ----------------------------------------------------------------------
    symptom_last_known_well         TIMESTAMP WITHOUT TIME ZONE

);

COMMENT ON TABLE mart.fact_situation
    IS 'One row per PCR with NEMSIS eSituation fields (wide), plus injury_flag for TRAUMA-01 and related measures.';

COMMENT ON COLUMN mart.fact_situation.pcr_number
    IS 'eRecord.01 – PCR unique identifier; PK and FK target for incident/vitals facts.';

COMMENT ON COLUMN mart.fact_situation.symptom_onset_time
    IS 'eSituation.01 – Date/Time of Symptom Onset.';

COMMENT ON COLUMN mart.fact_situation.last_modified
    IS 'Timestamp of freshest eSituation record used to populate this row. Newer rows from stage overwrite older ones.';

COMMENT ON COLUMN mart.fact_situation.possible_injury
    IS 'eSituation.02 – Possible Injury (Medical, Trauma, BOTH).';

COMMENT ON COLUMN mart.fact_situation.injury_flag
    IS 'Derived flag: TRUE if possible_injury IN (''Trauma'', ''BOTH Medical & Trauma Patient''); driving TRAUMA-01 denominator.';

COMMENT ON COLUMN mart.fact_situation.complaint_type
    IS 'eSituation.03 – Complaint Type.';

COMMENT ON COLUMN mart.fact_situation.complaint_statement
    IS 'eSituation.04 – Complaint (Narrative).';

COMMENT ON COLUMN mart.fact_situation.complaint_duration
    IS 'eSituation.05 – Duration of Complaint.';

COMMENT ON COLUMN mart.fact_situation.complaint_time_unit
    IS 'eSituation.06 – Time Units of Complaint Duration.';

COMMENT ON COLUMN mart.fact_situation.complaint_location
    IS 'eSituation.07 – Chief Complaint Anatomic Location.';

COMMENT ON COLUMN mart.fact_situation.complaint_organ_system
    IS 'eSituation.08 – Chief Complaint Organ System.';

COMMENT ON COLUMN mart.fact_situation.primary_symptom
    IS 'eSituation.09 – Primary Symptom.';

COMMENT ON COLUMN mart.fact_situation.other_symptoms
    IS 'eSituation.10 – Other Associated Symptoms (text list / coded expansion).';

COMMENT ON COLUMN mart.fact_situation.primary_impression_code
    IS 'eSituation.11 – Provider’s Primary Impression (coded).';

COMMENT ON COLUMN mart.fact_situation.primary_impression_description
    IS 'Provider’s Primary Impression (description).';

COMMENT ON COLUMN mart.fact_situation.secondary_impression_code
    IS 'eSituation.12 – Provider’s Secondary Impression(s) (coded).';

COMMENT ON COLUMN mart.fact_situation.secondary_impression_description
    IS 'Provider’s Secondary Impression(s) (description).';

COMMENT ON COLUMN mart.fact_situation.initial_priority
    IS 'eSituation.13 – Initial Patient Acuity (Priority).';

COMMENT ON COLUMN mart.fact_situation.symptom_last_known_well
    IS 'eSituation.18 – Time Last Known Well (Stroke metrics).';

COMMIT;
