SET ROLE ems_owner;

CREATE TABLE IF NOT EXISTS mart.dim_disposition (
  disposition_key        BIGSERIAL PRIMARY KEY,
  source_type            TEXT NOT NULL
                         CHECK (source_type IN ('transport','unit')),
  label_raw              TEXT NOT NULL,
  slug                   TEXT NOT NULL,
  category               TEXT NOT NULL
                         CHECK (category IN ('transport','no_transport','canceled',
                                                'standby','transfer','other')),
  is_transport_expected  BOOLEAN NOT NULL DEFAULT FALSE,
  is_patient_encounter   BOOLEAN NOT NULL DEFAULT FALSE,
  is_canceled            BOOLEAN NOT NULL DEFAULT FALSE,
  notes                  TEXT,
  UNIQUE (source_type, label_raw)
);

-- Unknown fallbacks (one per source_type)
INSERT INTO mart.dim_disposition (source_type, label_raw, slug, category)
VALUES 
  ('transport','_UNK','unknown','other'),
  ('unit','_UNK','unknown','other')
ON CONFLICT (source_type, label_raw) DO NOTHING;

-- Transport dispositions
INSERT INTO mart.dim_disposition
  (source_type, label_raw, slug, category, is_transport_expected, is_patient_encounter)
VALUES
  ('transport','Transport by This EMS Unit (This Crew Only)',
     'transport_this_unit','transport', true,  true),
  ('transport','Transport by This EMS Unit, with a Member of Another Crew',
     'transport_this_unit_mixed_crew','transport', true,  true),
  ('transport','Transport by Another EMS Unit/Agency',
     'transport_other_agency','transfer', false, true),
  ('transport','Transport by Another EMS Unit/Agency, with a Member of this Crew',
     'transport_other_agency_mixed_crew','transfer', false, true),
  ('transport','Patient Refused Transport',
     'refusal','no_transport', false, true),
  ('transport','No Transport',
     'no_transport_other','no_transport', false, true)
ON CONFLICT (source_type, label_raw) DO NOTHING;

-- Unit dispositions (labels must match your export exactly)
INSERT INTO mart.dim_disposition
  (source_type, label_raw, slug, category, is_patient_encounter, is_canceled)
VALUES
  ('unit','Patient Contact Made',
     'patient_contact_made','other',   true,  false),
  ('unit','No Patient Contact',
     'no_patient_contact','other',     false, false),
  ('unit','No Patient Found',
     'no_patient_found','standby',     false, false),
  ('unit','Cancelled on Scene',
     'canceled_on_scene','canceled',   true,  true),
  ('unit','Cancelled Prior to Arrival at Scene',
     'canceled_prior','canceled',      false, true)
ON CONFLICT (source_type, label_raw) DO NOTHING;

COMMENT ON TABLE mart.dim_disposition IS $doc$
purpose: Controlled vocabulary for ImageTrend disposition labels (both Transport and Unit)
grain: 1 row per (source_type, label_raw)
natural_key: (source_type, label_raw)
sources: stage.incidents_stg.transport_disposition and stage.incidents_stg.unit_disposition
usage: join from fact_incident (transport_disp_key / unit_disp_key); derive transport_outcome; drive QA rules
notes: Unknowns seeded as ('_UNK','unknown','other') per source_type; curate slug/category/flags over time
$doc$;

COMMENT ON COLUMN mart.dim_disposition.disposition_key IS $doc$
desc: Surrogate key for the disposition row
rules: auto-generated; never reused/changed
$doc$;

COMMENT ON COLUMN mart.dim_disposition.source_type IS $doc$
desc: Which source the raw label came from
values: 'transport' | 'unit'
rules: required; constrained by CHECK; participates in natural key with label_raw
$doc$;

COMMENT ON COLUMN mart.dim_disposition.label_raw IS $doc$
desc: Exact label as captured in ImageTrend (case/punctuation preserved)
rules: not normalized; with source_type forms the natural key; UNIQUE per source_type
$doc$;

COMMENT ON COLUMN mart.dim_disposition.slug IS $doc$
desc: Stable, lower_snake_case identifier for analytics
rules: curated; should remain stable even if label_raw changes; used by BI/QA
$doc$;

COMMENT ON COLUMN mart.dim_disposition.category IS $doc$
desc: High-level bucket for slicing and rules
values: 'transport' (this unit transports) |
        'transfer' (another unit/agency transports) |
        'no_transport' (e.g., refusal, treat/release) |
        'canceled' (any cancel state) |
        'standby' (no patient) |
        'other' (unmapped/uncategorized)
rules: constrained by CHECK; used to derive transport_outcome and QA checks
$doc$;

COMMENT ON COLUMN mart.dim_disposition.is_transport_expected IS $doc$
desc: Whether a destination is expected for this disposition
rules: true for transport-by-this-unit; typically false for transfer/no_transport/canceled/standby
$doc$;

COMMENT ON COLUMN mart.dim_disposition.is_patient_encounter IS $doc$
desc: Whether a patient encounter is expected/implied
rules: true for most transports/refusals; false for standby/no-patient and some cancels
$doc$;

COMMENT ON COLUMN mart.dim_disposition.is_canceled IS $doc$
desc: Convenience flag for any canceled state
rules: set true for cancel variants (prior to arrival, on scene, en route, etc.)
$doc$;

COMMENT ON COLUMN mart.dim_disposition.notes IS $doc$
desc: Optional free text for local mapping rationale/policy notes
rules: nullable; not used in joins
$doc$;

COMMENT ON CONSTRAINT dim_disposition_source_type_check ON mart.dim_disposition IS
  'Allowed source_type values: transport, unit';
COMMENT ON CONSTRAINT dim_disposition_category_check ON mart.dim_disposition IS
  'Allowed category values: transport, no_transport, canceled, standby, transfer, other';

RESET ROLE;
