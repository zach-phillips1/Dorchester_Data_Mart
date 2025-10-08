SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS stage.procedures_stg (
    pcr_number                  TEXT,                           a-- key
    procedure_time              TIMESTAMP WITHOUT TIME ZONE,    -- eProcedures.01
    prior_to_ems                TEXT,                           -- eProcedures.02
    procedure_description       TEXT,                           -- eProcedures.03
    procedure_code              INTEGER,                        -- eProcedures.03
    equipment_size              TEXT,                           -- eProcedures.04
    attempts                    INTEGER,                        -- eProcedures.05
    successful                  TEXT,                           -- eProcedures.06
    complication_list           TEXT,                           -- eProcedures.07
    patient_response            TEXT,                           -- eProcedures.08
    crew_member_id              INTEGER,                        -- eProcedures.09
    performer_role              TEXT,                           -- eProcedures.10
    authorization               TEXT,                           -- eProcedures.11
    authorizing_physician       TEXT,                           -- eProcedures.12
    vascular_access_location    TEXT,                           -- eProcedures.13
    last_modified               TIMESTAMP WITHOUT TIME ZONE
);