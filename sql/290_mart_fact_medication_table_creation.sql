-- 25_mart_fact_medication_table_creation.sql
SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS mart.fact_medication (
    pcr_number              TEXT NOT NULL,
    medication_key          BIGINT NOT NULL REFERENCES mart.dim_medication(medication_key),
    med_admin_date_time     TIMESTAMP WITHOUT TIME ZONE NOT NULL,

    med_admin_prior_to_ems  TEXT,
    med_given               TEXT,
    med_given_code          TEXT,
    med_admin_route         TEXT,
    med_admin_route_code    TEXT,
    med_dosage              NUMERIC,
    med_dosage_unit         TEXT,
    med_response            TEXT,
    med_complication_list   TEXT,
    med_crew_admin_id       TEXT,
    med_crew_role           TEXT,
    med_authorization       TEXT,
    med_authorization_md    TEXT,

    last_modified           TIMESTAMP WITHOUT TIME ZONE NOT NULL,

    CONSTRAINT pk_fact_medication
        UNIQUE (pcr_number, medication_key, med_admin_date_time)
);

-- Useful indexes
CREATE INDEX IF NOT EXISTS ix_fact_med_medkey
    ON mart.fact_medication(medication_key);

CREATE INDEX IF NOT EXISTS ix_fact_med_pcr
    ON mart.fact_medication(pcr_number);

CREATE INDEX IF NOT EXISTS ix_fact_med_time
    ON mart.fact_medication(med_admin_date_time);

CREATE INDEX IF NOT EXISTS ix_fact_med_lastmod
    ON mart.fact_medication(last_modified);

COMMENT ON TABLE mart.fact_medication IS
'One row per medication administration event (unpivoted from stage.medications_stg).';

COMMIT;
RESET ROLE;
