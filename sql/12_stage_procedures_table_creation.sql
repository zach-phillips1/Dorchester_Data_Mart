SET ROLE ems_owner;
BEGIN;

-- Stage import for NEMSIS eProcedures (01–13) from ImageTrend Report Writer.
-- Typed but permissive; duplicates allowed. Local timestamps (TIMESTAMP WITHOUT TIME ZONE).

CREATE TABLE IF NOT EXISTS stage.procedures_stg (
    -- Identity / chronology
    pcr_number                  TEXT,                        -- eRecord.01 – Incident PCR number
    procedure_time              TIMESTAMP WITHOUT TIME ZONE, -- eProcedures.01 – Date/Time Performed (local)
    last_modified               TIMESTAMP WITHOUT TIME ZONE, -- Export/source "last modified" used for newer-wins ETL

    -- Core procedure fields
    procedure_description       TEXT,                        -- eProcedures.03 – Description (display text)
    procedure_code              TEXT,                        -- eProcedures.03 – SNOMED code (as TEXT to preserve formatting)
    equipment_size              TEXT,                        -- eProcedures.04 – Size of equipment (free text / size)
    attempts                    INTEGER,                     -- eProcedures.05 – Number of attempts
    successful                  TEXT,                        -- eProcedures.06 – Raw Yes/No/True/False (parsed to boolean in ETL)
    complication_list           TEXT,                        -- eProcedures.07 – Delimited list (e.g., "|", ";", ",")
    patient_response            TEXT,                        -- eProcedures.08 – Response to procedure
    authorization               TEXT,                        -- eProcedures.11 – Authorization (e.g., Protocol, MD Order)
    authorizing_physician       TEXT,                        -- eProcedures.12 – Authorizing physician (text)
    vascular_access_location    TEXT,                        -- eProcedures.13 – Vascular access location (text)

    -- Crew / performer metadata
    prior_to_ems                TEXT,                        -- eProcedures.02 – Raw boolean-ish (parsed in ETL)
    crew_member_id              TEXT,                        -- eProcedures.09 – Keep TEXT to preserve leading zeros
    performer_role              TEXT                         -- eProcedures.10 – Role/Type of person performing
);

-- Table comment
COMMENT ON TABLE stage.procedures_stg IS
  'Stage import for NEMSIS eProcedures.01–.13. Local timestamps; duplicates allowed; minimal constraints.';

-- Column comments
COMMENT ON COLUMN stage.procedures_stg.pcr_number                IS 'eRecord.01 – Incident Patient Care Report Number (PCR).';
COMMENT ON COLUMN stage.procedures_stg.procedure_time            IS 'eProcedures.01 – Date/Time Procedure Performed (local time).';
COMMENT ON COLUMN stage.procedures_stg.last_modified             IS 'Source/export last modified; used for newer-wins upsert.';
COMMENT ON COLUMN stage.procedures_stg.procedure_description     IS 'eProcedures.03 – Procedure description from export.';
COMMENT ON COLUMN stage.procedures_stg.procedure_code            IS 'eProcedures.03 – SNOMED code as TEXT.';
COMMENT ON COLUMN stage.procedures_stg.equipment_size            IS 'eProcedures.04 – Size of procedure equipment.';
COMMENT ON COLUMN stage.procedures_stg.attempts                  IS 'eProcedures.05 – Number of procedure attempts.';
COMMENT ON COLUMN stage.procedures_stg.successful                IS 'eProcedures.06 – Raw success flag (Yes/No/True/False).';
COMMENT ON COLUMN stage.procedures_stg.complication_list         IS 'eProcedures.07 – Delimited complications (| ; ,).';
COMMENT ON COLUMN stage.procedures_stg.patient_response          IS 'eProcedures.08 – Patient response to procedure.';
COMMENT ON COLUMN stage.procedures_stg.authorization             IS 'eProcedures.11 – Procedure authorization.';
COMMENT ON COLUMN stage.procedures_stg.authorizing_physician     IS 'eProcedures.12 – Authorizing physician (free text).';
COMMENT ON COLUMN stage.procedures_stg.vascular_access_location  IS 'eProcedures.13 – Vascular access location.';
COMMENT ON COLUMN stage.procedures_stg.prior_to_ems              IS 'eProcedures.02 – Performed prior to this unit''s EMS care (raw boolean-ish).';
COMMENT ON COLUMN stage.procedures_stg.crew_member_id            IS 'eProcedures.09 – Crew member ID; TEXT to preserve leading zeros.';
COMMENT ON COLUMN stage.procedures_stg.performer_role            IS 'eProcedures.10 – Role/type of person performing.';

-- Helpful indexes for ETL & QA queries
CREATE INDEX IF NOT EXISTS ix_procedures_stg_pcr   ON stage.procedures_stg (pcr_number);
CREATE INDEX IF NOT EXISTS ix_procedures_stg_time  ON stage.procedures_stg (procedure_time);
CREATE INDEX IF NOT EXISTS ix_procedures_stg_code  ON stage.procedures_stg (procedure_code);

COMMIT;
RESET ROLE;
