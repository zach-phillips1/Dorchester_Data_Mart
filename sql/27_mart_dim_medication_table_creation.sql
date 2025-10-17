-- Canonical medication catalog (RxNorm/SNOMED/internal code)
SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS mart.dim_medication (
  medication_key   BIGSERIAL PRIMARY KEY,
  medication_code  TEXT NOT NULL,           -- from med_given_code (as TEXT)
  medication_name  TEXT,                    -- med_given (display)
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  first_seen_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  last_seen_at     TIMESTAMP WITHOUT TIME ZONE
);

COMMENT ON TABLE  mart.dim_medication IS 'Normalized medication catalog.';
COMMENT ON COLUMN mart.dim_medication.medication_code IS 'RxNorm/SNOMED/internal code (TEXT); unique.';
CREATE UNIQUE INDEX IF NOT EXISTS ux_dim_medication_code ON mart.dim_medication(medication_code);

COMMIT;
RESET ROLE;
