BEGIN;
SET ROLE ems_owner;

CREATE TABLE IF NOT EXISTS mart.dim_unit (
    unit_key            BIGSERIAL PRIMARY KEY,
    unit_code           TEXT NOT NULL UNIQUE,
    service_level       TEXT NOT NULL DEFAULT 'UNKNOWN'
                        CHECK (service_level IN ('BLS', 'ALS', 'UNKNOWN')),
    shift_label         TEXT,
    notes               TEXT
);

