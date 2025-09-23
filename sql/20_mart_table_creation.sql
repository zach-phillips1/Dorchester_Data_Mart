SET ROLE ems_owner;

CREATE TABLE IF NOT EXISTS mart.dim_unit (
    unit_key            BIGSERIAL PRIMARY KEY,
    unit_code           TEXT NOT NULL UNIQUE,
    service_level       TEXT NOT NULL DEFAULT 'UNKNOWN'
                        CHECK (service_level IN ('BLS', 'ALS', 'UNKNOWN')),
    notes               TEXT
);

INSERT INTO mart.dim_unit (unit_code, service_level)
VALUES ('_UNK', 'UNKNOWN')
ON CONFLICT (unit_code) DO NOTHING;

ALTER TABLE mart.dim_unit
    ADD CONSTRAINT ck_unit_code_normalized
    CHECK (unit_code = UPPER(BTRIM(unit_code)));

COMMENT ON TABLE mart.dim_unit IS $doc$
purpose: Lookup for response units
grain: 1 row per unit_code
natural_key: unit_code
notes: service_level derived: A% -> BLS, P% -> ALS; other -> UNKNOWN, EMS1 and EMS10 are ALS.
$doc$;

COMMENT ON COLUMN mart.dim_unit.unit_key IS $doc$
desc: surrogate key, auto-generated; never reused/changed
rules: unique
$doc$;

COMMENT ON COLUMN mart.dim_unit.unit_code IS $doc$
desc: Agency unit identifier (e.g. A103, P500)
rules: trimmed, uppercase; unique
$doc$;

COMMENT ON COLUMN mart.dim_unit.service_level IS $doc$
desc: Clinical service level for the unit.
rules: derived from unit_code prefix (A=BLS, P=ALS, else UNKNOWN)
$doc$;

COMMENT ON COLUMN mart.dim_unit.notes IS $doc$
desc: “Optional free text; operational notes (e.g., seasonal staffing).”
rules: null
$doc$;

RESET ROLE;