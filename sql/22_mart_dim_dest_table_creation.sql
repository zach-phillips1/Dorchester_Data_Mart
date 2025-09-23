SET ROLE ems_owner;

CREATE TABLE IF NOT EXISTS mart.dim_destination (
  destination_key   BIGSERIAL PRIMARY KEY,
  destination_code  TEXT NOT NULL UNIQUE,  -- natural key (matches stage)
  destination_name  TEXT,                  -- display label (may drift)
  notes             TEXT
);

-- Seed unknown
INSERT INTO mart.dim_destination (destination_code, destination_name)
VALUES ('_UNK', 'UNKNOWN')
ON CONFLICT (destination_code) DO NOTHING;

COMMENT ON TABLE mart.dim_destination IS $doc$
purpose: Lookup for transport destinations (facilities)
grain: 1 row per destination_code
natural_key: destination_code
notes: name may drift; code is stable; stage->dim normalized to TRIM/UPPER
$doc$;

COMMENT ON COLUMN mart.dim_destination.destination_key IS $doc$
desc: Surrogate key, auto-generated; never reused
$doc$;

COMMENT ON COLUMN mart.dim_destination.destination_code IS $doc$
desc: Facility code/ID (e.g., MIEMSS code)
nemsis: eDisposition.02
rules: unique; trimmed/uppercased
$doc$;

COMMENT ON COLUMN mart.dim_destination.destination_name IS $doc$
desc: Facility display name
nemsis: eDisposition.01
rules: not unique; may change over time
$doc$;

COMMENT ON COLUMN mart.dim_destination.notes IS $doc$
desc: Optional free text
$doc$;

RESET ROLE;
