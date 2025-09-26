BEGIN;

SET ROLE ems_owner;

CREATE TABLE IF NOT EXISTS stage.vitals_stg (
    pcr_number              TEXT,
    vital_taken_time        TIMESTAMP WITHOUT TIME ZONE,
    obtained_prior_care     BOOLEAN,
    cardiac_rhythm          TEXT,
    ecg_type                TEXT,
    sbp                     INTEGER,
    dbp                     INTEGER,
    bp_method               TEXT,
    map                     INTEGER,
    heart_rate              INTEGER,
    hr_method               TEXT,
    spo2                    INTEGER,
    pulse_rhytm             TEXT,
    resp_rate               INTEGER,
    resp_effort             TEXT,
    etco2                   INTEGER,
    blood_glucose           INTEGER,
    gcs_eye                 TEXT,
    gcs_verbal              TEXT,
    gcs_motor               TEXT,
    gcs_qualifier_list      TEXT,
    gcs_total               INTEGER,
    temperature_f           INTEGER,
    temperature_method      TEXT,
    avpu                    INTEGER,
    pain_score              INTEGER,
    pain_scale_type         TEXT,
    reperfusion_checklist   TEXT,
    apgar_score             INTEGER,
    revised_trauma_score    INTEGER
)

CREATE INDEX IF NOT EXISTS ix_vitals_stg_pcr ON stage.vitals_stg(pcr_number);



RESET ROLE;