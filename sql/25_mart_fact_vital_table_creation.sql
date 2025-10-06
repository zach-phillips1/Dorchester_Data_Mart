SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS mart.dim_vital_type (
    vital_type_key          SERIAL PRIMARY KEY,
    vital_type_code         TEXT UNIQUE NOT NULL,
    nemsis_element          TEXT,
    is_pain_score           BOOLEAN,
    is_numeric              BOOLEAN,
    scale_family            TEXT,
    notes                   TEXT
);

CREATE TABLE IF NOT EXISTS mart.fact_vitals (
    pcr_number          TEXT NOT NULL,
    vital_type_key      INTEGER NOT NULL REFERENCES mart.dim_vital_type(vital_type_key),
    vital_taken_time    TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    value_numeric       NUMERIC,
    value_text          TEXT,
    unit                TEXT,
    scale_name          TEXT,
    qualifiers          TEXT,
    recorded_by         TEXT,
    last_modified       TIMESTAMP WITHOUT TIME ZONE NOT NULL,

    CONSTRAINT pk_fact_vital UNIQUE (pcr_number, vital_type_key, vital_taken_time)
);

CREATE INDEX IF NOT EXISTS ix_fact_vital_pcr            ON mart.fact_vitals(pcr_number);
CREATE INDEX IF NOT EXISTS ix_fact_vital_type           ON mart.fact_vitals(vital_type_key);
CREATE INDEX IF NOT EXISTS ix_fact_vital_taken_time     ON mart.fact_vitals(vital_taken_time);
CREATE INDEX IF NOT EXISTS ix_fact_vital_last_modified  ON mart.fact_vitals(last_modified);

COMMENT ON TABLE mart.fact_vitals IS
'One row per vital measurement per PCR (unpivoted from stage.vitals_stg). Local times; newer-wins via last_modified.';

COMMIT;
RESET ROLE;