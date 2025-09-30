BEGIN;
SET ROLE ems_owner;

CREATE TABLE IF NOT EXISTS stage.vitals_stg (
    -- Keys
    pcr_number              TEXT,
    vital_taken_time        TIMESTAMP WITHOUT TIME ZONE,
    last_modified           TIMESTAMP WITHOUT TIME ZONE,

    -- Flags / qualifiers
    obtained_prior_care     BOOLEAN,

    -- ECG / rhythm
    cardiac_rhythm          TEXT,
    ecg_type                TEXT,

    -- Hemodynamics
    sbp                     INTEGER,
    dbp                     INTEGER,
    bp_method               TEXT,
    map                     INTEGER,

    -- Cardio-pulmonary
    heart_rate              INTEGER,
    hr_method               TEXT,
    spo2                    INTEGER,
    pulse_rhythm            TEXT,
    resp_rate               INTEGER,
    resp_effort             TEXT,
    etco2                   INTEGER,

    -- Metabolic / labs
    blood_glucose           INTEGER,

    -- Neuro (GCS/AVPU)
    gcs_eye                 INTEGER,
    gcs_verbal              INTEGER,
    gcs_motor               INTEGER,
    gcs_qualifier_list      TEXT,
    gcs_total               INTEGER,
    avpu                    INTEGER,

    -- Temp
    temperature_f           INTEGER,
    temperature_method      TEXT,

    -- Pain & stroke
    pain_score              INTEGER,
    pain_scale_type         TEXT,
    stroke_scale_result     TEXT,
    stroke_scale_type       TEXT,

    -- Other scores
    reperfusion_checklist   TEXT,
    apgar_score             INTEGER,
    revised_trauma_score    INTEGER
);

-- Indexes
CREATE INDEX IF NOT EXISTS ix_vitals_stg_pcr               ON stage.vitals_stg(pcr_number);
CREATE INDEX IF NOT EXISTS ix_vitals_stg_pcr_taken_time    ON stage.vitals_stg(pcr_number, vital_taken_time);

-- Data dictionary comments
COMMENT ON TABLE  stage.vitals_stg IS
'Wide staging for eVitals (one row per vital set from ImageTrend Report Writer). Local times only; newer-wins via last_modified. Duplicates allowed.';

COMMENT ON COLUMN stage.vitals_stg.pcr_number IS $doc$
desc: ImageTrend unique PCR identifier
source: Report Writer export (“ems_mart_vitals”); headers map to columns
nemsis: eRecord.01
rules: natural key upstream; duplicates allowed in stage
$doc$;

COMMENT ON COLUMN stage.vitals_stg.vital_taken_time IS $doc$
desc: Date/time the vital signs were taken (local, America/New_York)
nemsis: eVitals.01
$doc$;

COMMENT ON COLUMN stage.vitals_stg.last_modified IS $doc$
desc: Last modified timestamp from export; used for incremental newer-wins
rules: TIMESTAMP WITHOUT TIME ZONE; local
$doc$;

COMMENT ON COLUMN stage.vitals_stg.obtained_prior_care IS $doc$
desc: Vital obtained prior to this unit’s EMS care
nemsis: eVitals.02
$doc$;

COMMENT ON COLUMN stage.vitals_stg.cardiac_rhythm IS $doc$
desc: Cardiac rhythm / ECG finding
nemsis: eVitals.03
$doc$;

COMMENT ON COLUMN stage.vitals_stg.ecg_type IS $doc$
desc: ECG type (e.g., 4-lead, 12-lead)
nemsis: eVitals.04
$doc$;

COMMENT ON COLUMN stage.vitals_stg.sbp IS $doc$
desc: Systolic blood pressure
nemsis: eVitals.06
$doc$;

COMMENT ON COLUMN stage.vitals_stg.dbp IS $doc$
desc: Diastolic blood pressure
nemsis: eVitals.07
$doc$;

COMMENT ON COLUMN stage.vitals_stg.bp_method IS $doc$
desc: Method of blood pressure measurement (manual, auto cuff)
nemsis: eVitals.08
$doc$;

COMMENT ON COLUMN stage.vitals_stg.map IS $doc$
desc: Mean arterial pressure
nemsis: eVitals.09
$doc$;

COMMENT ON COLUMN stage.vitals_stg.heart_rate IS $doc$
desc: Heart rate
nemsis: eVitals.10
$doc$;

COMMENT ON COLUMN stage.vitals_stg.hr_method IS $doc$
desc: Method of heart rate measurement
nemsis: eVitals.11
$doc$;

COMMENT ON COLUMN stage.vitals_stg.spo2 IS $doc$
desc: Pulse oximetry (%)
nemsis: eVitals.12
$doc$;

COMMENT ON COLUMN stage.vitals_stg.pulse_rhythm IS $doc$
desc: Pulse rhythm (regular/irregular)
nemsis: eVitals.13
$doc$;

COMMENT ON COLUMN stage.vitals_stg.resp_rate IS $doc$
desc: Respiratory rate
nemsis: eVitals.14
$doc$;

COMMENT ON COLUMN stage.vitals_stg.resp_effort IS $doc$
desc: Respiratory effort (descriptor)
nemsis: eVitals.15
$doc$;

COMMENT ON COLUMN stage.vitals_stg.etco2 IS $doc$
desc: End-tidal CO₂
nemsis: eVitals.16
$doc$;

COMMENT ON COLUMN stage.vitals_stg.blood_glucose IS $doc$
desc: Blood glucose level
nemsis: eVitals.18
$doc$;

COMMENT ON COLUMN stage.vitals_stg.gcs_eye IS $doc$
desc: Glasgow Coma Score—Eye
nemsis: eVitals.19
$doc$;

COMMENT ON COLUMN stage.vitals_stg.gcs_verbal IS $doc$
desc: Glasgow Coma Score—Verbal
nemsis: eVitals.20
$doc$;

COMMENT ON COLUMN stage.vitals_stg.gcs_motor IS $doc$
desc: Glasgow Coma Score—Motor
nemsis: eVitals.21
$doc$;

COMMENT ON COLUMN stage.vitals_stg.gcs_qualifier_list IS $doc$
desc: Glasgow Coma Score—qualifiers (list)
nemsis: eVitals.22
$doc$;

COMMENT ON COLUMN stage.vitals_stg.gcs_total IS $doc$
desc: Glasgow Coma Score—Total
nemsis: eVitals.23
$doc$;

COMMENT ON COLUMN stage.vitals_stg.temperature_f IS $doc$
desc: Body temperature (°F)
nemsis: eVitals.24
$doc$;

COMMENT ON COLUMN stage.vitals_stg.temperature_method IS $doc$
desc: Temperature measurement method
nemsis: eVitals.25
$doc$;

COMMENT ON COLUMN stage.vitals_stg.avpu IS $doc$
desc: Level of responsiveness (AVPU scale)
nemsis: eVitals.26
$doc$;

COMMENT ON COLUMN stage.vitals_stg.pain_score IS $doc$
desc: Pain scale score
nemsis: eVitals.27
$doc$;

COMMENT ON COLUMN stage.vitals_stg.pain_scale_type IS $doc$
desc: Pain scale type (e.g., Numeric 0–10, Faces)
nemsis: eVitals.28
$doc$;

COMMENT ON COLUMN stage.vitals_stg.stroke_scale_result IS $doc$
desc: Stroke scale result
nemsis: eVitals.29
$doc$;

COMMENT ON COLUMN stage.vitals_stg.stroke_scale_type IS $doc$
desc: Stroke scale type
nemsis: eVitals.30
$doc$;

COMMENT ON COLUMN stage.vitals_stg.reperfusion_checklist IS $doc$
desc: Reperfusion checklist indicator
nemsis: eVitals.31
$doc$;

COMMENT ON COLUMN stage.vitals_stg.apgar_score IS $doc$
desc: APGAR score
nemsis: eVitals.32
$doc$;

COMMENT ON COLUMN stage.vitals_stg.revised_trauma_score IS $doc$
desc: Revised Trauma Score
nemsis: eVitals.33
$doc$;

COMMIT;
RESET ROLE;
