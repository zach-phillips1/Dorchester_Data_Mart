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

-- Transport disposition
INSERT INTO  mart.dim_disposition
    (source_type, label_raw, slug, category, is_transport_expected, is_patient_encounter)
VALUES
    ('transport', 'Transport by This EMS Unit (This Crew Only)',
        'transport_this_unit', 'transpot', true, true),
    ('transport', 'Transport by This EMS Unit, with a Member of Another Crew',
        'transport_this_unit_mixed_crew', 'transport', true, true),
    ('transport', 'Transport by Another EMS Unit/Agency',
        'transport_other_agency', 'transfer', false, true),
    ('transport', 'Transport by Another EMSUnitAgency, with a Member of this Crew',
        'transport_other_agency_mixed_crew', 'transfer', false, true),
    ('transport', 'Patient Refused Transport',
        'refusal', 'no_transport', false, true),
    ('transport', 'No Transport',
        'no_transport_other', 'no_transport', false, true)
ON CONFLICT (source_type, label_raw) DO NOTHING;

-- Unit Disposition
INSERT INTO mart.dim_disposition
    (source_type, label_raw, slig, category, is_patient_encounter, is_canceled)
VALUES
    ('unit', 'Patient Contact Made',
        'patient_contact_made', 'other', true, false),
    ('unit', 'No Patient Contact Made',
        'no_patient_contact_made', 'other', false, false),
    ('unit', 'No Patient Found',
        'no_patient_found', 'standby', false, false),
    ('unit', 'Cancelled on Scene',
        'cancelled_on_scene', 'canceled', false, false),
    ('unit', 'Cancelled Prior to Arrival at Scene',
        'canceled_prior', 'canceled', false, false)
ON CONFLICT (source_type, label_raw) DO NOTHING;





RESET ROLE;
