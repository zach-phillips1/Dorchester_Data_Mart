SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS stage.situation_stg (

    ----------------------------------------------------------------------
    -- Identity / Chronology
    ----------------------------------------------------------------------
    pcr_number                      TEXT NOT NULL,
    symptom_onset_time             TIMESTAMP WITHOUT TIME ZONE,   -- eSituation.01
    last_modified                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,

    ----------------------------------------------------------------------
    -- eSituation.02 – Possible Injury
    ----------------------------------------------------------------------
    possible_injury                TEXT,  -- Values: Medical, Trauma, BOTH Medical & Trauma Patient

    ----------------------------------------------------------------------
    -- eSituation.PatientComplaintGroup (eSituation.03–10)
    ----------------------------------------------------------------------
    complaint_type                 TEXT,       -- eSituation.03
    complaint_statement            TEXT,       -- eSituation.04
    complaint_duration             INTEGER,    -- eSituation.05
    complaint_time_unit            TEXT,       -- eSituation.06
    complaint_location             TEXT,       -- eSituation.07
    complaint_organ_system         TEXT,       -- eSituation.08
    primary_symptom                TEXT,       -- eSituation.09

    ----------------------------------------------------------------------
    -- eSituation.10 – Other Associated Symptoms
    ----------------------------------------------------------------------
    other_symptoms                 TEXT,
    other_symptoms_icd             TEXT,
    other_symptoms_list            TEXT,

    ----------------------------------------------------------------------
    -- eSituation.11 & 12 – Provider Impressions
    ----------------------------------------------------------------------
    primary_impression_code        TEXT,
    primary_impression_description TEXT,
    secondary_impression_code      TEXT,
    secondary_impression_description TEXT,

    ----------------------------------------------------------------------
    -- eSituation.13 – Initial Patient Acuity
    ----------------------------------------------------------------------
    initial_priority               TEXT,

    ----------------------------------------------------------------------
    -- eSituation.18 – Time Last Known Well (Stroke Metrics)
    ----------------------------------------------------------------------
    symptom_last_known_well        TIMESTAMP WITHOUT TIME ZONE

);

----------------------------------------------------------------------
-- Table Comment
----------------------------------------------------------------------
COMMENT ON TABLE stage.situation_stg
    IS 'Stage import of NEMSIS eSituation fields (eSituation.01–18). Used for injury, stroke, and complaint-related QA/QI analytics.';

----------------------------------------------------------------------
-- Column Comments (NEMSIS-aligned)
----------------------------------------------------------------------
COMMENT ON COLUMN stage.situation_stg.pcr_number
    IS 'eRecord.01 – PCR unique identifier.';

COMMENT ON COLUMN stage.situation_stg.symptom_onset_time
    IS 'eSituation.01 – Date/Time of Symptom Onset.';

COMMENT ON COLUMN stage.situation_stg.last_modified
    IS 'Timestamp used for newer-wins ETL logic. Each row represents the freshest import of situation data for the PCR.';

COMMENT ON COLUMN stage.situation_stg.possible_injury
    IS 'eSituation.02 – Possible Injury (Medical, Trauma, BOTH). Primary field for TRAUMA-01 denominator.';

COMMENT ON COLUMN stage.situation_stg.complaint_type
    IS 'eSituation.03 – Complaint Type.';

COMMENT ON COLUMN stage.situation_stg.complaint_statement
    IS 'eSituation.04 – Complaint (Narrative).';

COMMENT ON COLUMN stage.situation_stg.complaint_duration
    IS 'eSituation.05 – Duration of Complaint.';

COMMENT ON COLUMN stage.situation_stg.complaint_time_unit
    IS 'eSituation.06 – Time Units of Complaint Duration.';

COMMENT ON COLUMN stage.situation_stg.complaint_location
    IS 'eSituation.07 – Chief Complaint Anatomic Location.';

COMMENT ON COLUMN stage.situation_stg.complaint_organ_system
    IS 'eSituation.08 – Chief Complaint Organ System.';

COMMENT ON COLUMN stage.situation_stg.primary_symptom
    IS 'eSituation.09 – Primary Symptom.';

COMMENT ON COLUMN stage.situation_stg.other_symptoms
    IS 'eSituation.10 – Other Associated Symptoms (text list).';

COMMENT ON COLUMN stage.situation_stg.primary_impression_code
    IS 'eSituation.11 – Provider’s Primary Impression (coded).';

COMMENT ON COLUMN stage.situation_stg.primary_impression_description
    IS 'Provider’s Primary Impression (description).';

COMMENT ON COLUMN stage.situation_stg.secondary_impression_code
    IS 'eSituation.12 – Provider’s Secondary Impression(s) (coded).';

COMMENT ON COLUMN stage.situation_stg.secondary_impression_description
    IS 'Provider’s Secondary Impression(s) (description).';

COMMENT ON COLUMN stage.situation_stg.initial_priority
    IS 'eSituation.13 – Initial Patient Acuity (Priority).';

COMMENT ON COLUMN stage.situation_stg.symptom_last_known_well
    IS 'eSituation.18 – Time Last Known Well (Stroke-related measures).';

----------------------------------------------------------------------
-- Indexes
----------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_situation_stg_pcr_number
    ON stage.situation_stg (pcr_number);

CREATE INDEX IF NOT EXISTS idx_situation_stg_last_modified
    ON stage.situation_stg (last_modified);

COMMIT;
