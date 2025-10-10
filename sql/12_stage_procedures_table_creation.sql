SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS stage.procedures_stg (
    -- Identity / chronology
    pcr_number                  TEXT,                        -- eRecord.01
    procedure_time              TIMESTAMP WITHOUT TIME ZONE, -- eProcedures.01 (local)
    last_modified               TIMESTAMP WITHOUT TIME ZONE, -- source "last modified"

    -- Core procedure fields
    procedure_description       TEXT,                        -- eProcedures.03 (display)
    procedure_code              TEXT,                        -- eProcedures.03 (SNOMED as TEXT)
    equipment_size              TEXT,                        -- eProcedures.04
    attempts                    INTEGER,                     -- eProcedures.05
    successful                  TEXT,                        -- eProcedures.06 (parsed to boolean in ETL)
    complication_list           TEXT,                        -- eProcedures.07 (delimited)
    patient_response            TEXT,                        -- eProcedures.08
    procedure_authorization     TEXT,                        -- eProcedures.11  <-- renamed
    authorizing_physician       TEXT,                        -- eProcedures.12
    vascular_access_location    TEXT,                        -- eProcedures.13

    -- Crew / performer
    prior_to_ems                TEXT,                        -- eProcedures.02 (parsed to boolean in ETL)
    crew_member_id              TEXT,                        -- eProcedures.09 (keep leading zeros)
    performer_role              TEXT                         -- eProcedures.10
);

COMMENT ON TABLE  stage.procedures_stg IS 'Stage import for NEMSIS eProcedures.01–.13.';
COMMENT ON COLUMN stage.procedures_stg.pcr_number               IS 'eRecord.01 – PCR';
COMMENT ON COLUMN stage.procedures_stg.procedure_time           IS 'eProcedures.01 – Performed time (local)';
COMMENT ON COLUMN stage.procedures_stg.last_modified            IS 'Source/export last modified';
COMMENT ON COLUMN stage.procedures_stg.procedure_description    IS 'eProcedures.03 – Description';
COMMENT ON COLUMN stage.procedures_stg.procedure_code           IS 'eProcedures.03 – SNOMED code (TEXT)';
COMMENT ON COLUMN stage.procedures_stg.equipment_size           IS 'eProcedures.04 – Equipment size';
COMMENT ON COLUMN stage.procedures_stg.attempts                 IS 'eProcedures.05 – Attempts';
COMMENT ON COLUMN stage.procedures_stg.successful               IS 'eProcedures.06 – Raw success flag';
COMMENT ON COLUMN stage.procedures_stg.complication_list        IS 'eProcedures.07 – Delimited list';
COMMENT ON COLUMN stage.procedures_stg.patient_response         IS 'eProcedures.08 – Response';
COMMENT ON COLUMN stage.procedures_stg.procedure_authorization  IS 'eProcedures.11 – Authorization';   -- renamed
COMMENT ON COLUMN stage.procedures_stg.authorizing_physician    IS 'eProcedures.12 – Physician';
COMMENT ON COLUMN stage.procedures_stg.vascular_access_location IS 'eProcedures.13 – Access location';
COMMENT ON COLUMN stage.procedures_stg.prior_to_ems             IS 'eProcedures.02 – Prior to EMS (raw)';
COMMENT ON COLUMN stage.procedures_stg.crew_member_id           IS 'eProcedures.09 – Crew ID (TEXT)';
COMMENT ON COLUMN stage.procedures_stg.performer_role           IS 'eProcedures.10 – Performer role';

CREATE INDEX IF NOT EXISTS ix_procedures_stg_pcr  ON stage.procedures_stg (pcr_number);
CREATE INDEX IF NOT EXISTS ix_procedures_stg_time ON stage.procedures_stg (procedure_time);
CREATE INDEX IF NOT EXISTS ix_procedures_stg_code ON stage.procedures_stg (procedure_code);

COMMIT;
RESET ROLE;
