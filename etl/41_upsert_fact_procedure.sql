-- sql/41_fact_procedure.sql
-- One row per performed procedure attempt/record.
-- Policies:
--   - Local timestamps (TIMESTAMP WITHOUT TIME ZONE)
--   - Newer-wins via last_modified
--   - De-dup within ETL by (pcr_number, procedure_time, procedure_key, crew_member_id)
SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS mart.fact_procedure (
    fact_procedure_key       BIGSERIAL PRIMARY KEY,

    -- Identity / chronology
    pcr_number               TEXT NOT NULL,
    procedure_time           TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    last_modified            TIMESTAMP WITHOUT TIME ZONE,   -- from source export

    -- Dimensions
    procedure_key            BIGINT NOT NULL REFERENCES mart.dim_procedure(procedure_key),
    -- Optional future dims: performer_role_key, access_location_key, authorization_key, etc.

    -- Crew / context (kept as text for now; can be lifted to dims later)
    crew_member_id           TEXT,          -- keep leading zeros
    performer_role           TEXT,          -- eProcedures.10 (normalize later if needed)
    prior_to_ems             BOOLEAN,       -- parsed from stage.prior_to_ems
    procedure_authorization  TEXT,          -- eProcedures.11
    authorizing_physician    TEXT,          -- eProcedures.12
    vascular_access_location TEXT,          -- eProcedures.13 (normalize later if needed)

    -- Core fields
    equipment_size           TEXT,
    attempts                 INTEGER,
    successful               BOOLEAN,       -- parsed from stage.successful
    patient_response         TEXT,

    -- ETL bookkeeping
    etl_loaded_at            TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now()
);

COMMENT ON TABLE  mart.fact_procedure IS 'Procedure facts (one row per recorded procedure on a PCR).';
COMMENT ON COLUMN mart.fact_procedure.pcr_number               IS 'eRecord.01 – PCR ID';
COMMENT ON COLUMN mart.fact_procedure.procedure_time           IS 'eProcedures.01 – local time performed';
COMMENT ON COLUMN mart.fact_procedure.last_modified            IS 'Source last_modified; used for newer-wins.';
COMMENT ON COLUMN mart.fact_procedure.procedure_key            IS 'FK → dim_procedure';
COMMENT ON COLUMN mart.fact_procedure.prior_to_ems             IS 'Derived boolean from eProcedures.02';
COMMENT ON COLUMN mart.fact_procedure.successful               IS 'Derived boolean from eProcedures.06';

-- Natural-ish uniqueness guard (ETL should upsert/merge on this)
-- NOTE: crew_member_id may be NULL in some feeds; include it in the key anyway.
CREATE UNIQUE INDEX IF NOT EXISTS ux_fact_procedure_natkey
ON mart.fact_procedure (pcr_number, procedure_time, procedure_key, COALESCE(crew_member_id, ''));

-- Helpful access paths
CREATE INDEX IF NOT EXISTS ix_fact_procedure_pcr          ON mart.fact_procedure (pcr_number);
CREATE INDEX IF NOT EXISTS ix_fact_procedure_time         ON mart.fact_procedure (procedure_time);
CREATE INDEX IF NOT EXISTS ix_fact_procedure_prockey      ON mart.fact_procedure (procedure_key);
CREATE INDEX IF NOT EXISTS ix_fact_procedure_success      ON mart.fact_procedure (successful);

COMMIT;
RESET ROLE;
