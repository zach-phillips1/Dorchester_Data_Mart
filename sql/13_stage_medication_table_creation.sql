-- 22_stage_medications_table_creation.sql
SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS stage.medications_stg (
    pcr_number              TEXT,
    incident_number         TEXT,

    med_admin_date_time     TIMESTAMP WITHOUT TIME ZONE,
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

    last_modified           TIMESTAMP WITHOUT TIME ZONE
);

COMMENT ON TABLE stage.medications_stg IS
'Raw medication administrations from ImageTrend Report Writer export. Dirty/typed staging area for ETL.';

COMMIT;
RESET ROLE;
