-- sql/31_dim_procedure.sql
-- Canonical catalog of procedures (SNOMED code + display/alias)
-- Keys are surrogate; code is unique for dedupe.
SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS mart.dim_procedure (
    procedure_key        BIGSERIAL PRIMARY KEY,
    procedure_code       TEXT NOT NULL,           -- SNOMED (from stage.procedures_stg.procedure_code)
    procedure_name       TEXT,                    -- display/description
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    first_seen_at        TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    last_seen_at         TIMESTAMP WITHOUT TIME ZONE
);

COMMENT ON TABLE  mart.dim_procedure IS 'Normalized procedure catalog (SNOMED).';
COMMENT ON COLUMN mart.dim_procedure.procedure_code IS 'SNOMED code as TEXT; unique.';
COMMENT ON COLUMN mart.dim_procedure.procedure_name IS 'Display text from eProcedures.03.';
COMMENT ON COLUMN mart.dim_procedure.last_seen_at  IS 'Updated by ETL when code/name observed.';

-- One code = one row (name may vary; keep latest non-null by ETL policy)
CREATE UNIQUE INDEX IF NOT EXISTS ux_dim_procedure_code ON mart.dim_procedure (procedure_code);

COMMIT;
RESET ROLE;
