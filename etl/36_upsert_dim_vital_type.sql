-- etl/36_upsert_dim_vital_type.sql
-- Seed/refresh vital types to match stage.vitals_stg columns and NEMSIS eVitals.
-- Idempotent; also widens the scale_family constraint to include 'boolean'.

RESET ROLE; SET ROLE ems_owner;
BEGIN;

-- Ensure scale_family allows 'boolean' in addition to existing values
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'dim_vital_type_scale_family_chk'
      AND conrelid = 'mart.dim_vital_type'::regclass
  ) THEN
    -- Drop and recreate with the expanded set
    EXECUTE 'ALTER TABLE mart.dim_vital_type DROP CONSTRAINT dim_vital_type_scale_family_chk';
  END IF;

  EXECUTE $SQL$
    ALTER TABLE mart.dim_vital_type
    ADD CONSTRAINT dim_vital_type_scale_family_chk
    CHECK (scale_family IS NULL OR scale_family IN ('numeric','faces','ordinal','text','boolean'))
  $SQL$;
END$$;

-- Seed/refresh rows
INSERT INTO mart.dim_vital_type
  (vital_type_code, display_name, nemsis_element, is_pain_score, is_numeric, scale_family, notes)
VALUES
  -- Common numeric vitals
  ('sbp',               'Systolic BP',                 'eVitals.06', FALSE, TRUE,  'numeric', NULL),
  ('dbp',               'Diastolic BP',                'eVitals.07', FALSE, TRUE,  'numeric', NULL),
  ('map',               'Mean Arterial Pressure',      'eVitals.09', FALSE, TRUE,  'numeric', NULL),
  ('heart_rate',        'Heart Rate',                  'eVitals.10', FALSE, TRUE,  'numeric', NULL),
  ('resp_rate',         'Respiratory Rate',            'eVitals.14', FALSE, TRUE,  'numeric', NULL),
  ('spo2',              'Pulse Oximetry',              'eVitals.12', FALSE, TRUE,  'numeric', NULL),
  ('etco2',             'End Tidal CO₂',               'eVitals.16', FALSE, TRUE,  'numeric', NULL),
  ('blood_glucose',     'Blood Glucose',               'eVitals.18', FALSE, TRUE,  'numeric', NULL),
  ('temperature_f',     'Temperature (°F)',            'eVitals.24', FALSE, TRUE,  'numeric', NULL),

  -- Methods / qualifiers / descriptors (text)
  ('bp_method',         'Blood Pressure Method',       'eVitals.08', FALSE, FALSE, 'text',    'Manual vs automatic'),
  ('hr_method',         'Heart Rate Method',           'eVitals.11', FALSE, FALSE, 'text',    NULL),
  ('pulse_rhythm',      'Pulse Rhythm',                'eVitals.13', FALSE, FALSE, 'text',    'Regular/irregular'),
  ('resp_effort',       'Respiratory Effort',          'eVitals.15', FALSE, FALSE, 'text',    NULL),
  ('temperature_method','Temperature Method',          'eVitals.25', FALSE, FALSE, 'text',    NULL),

  -- ECG/Rhythm
  ('cardiac_rhythm',    'Cardiac Rhythm / ECG',        'eVitals.03', FALSE, FALSE, 'text',    NULL),
  ('ecg_type',          'ECG Type',                    'eVitals.04', FALSE, FALSE, 'text',    '4-lead / 12-lead etc.'),

  -- AVPU
  ('avpu',              'Level of Responsiveness (AVPU)','eVitals.26',FALSE, FALSE, 'ordinal', NULL),

  -- Pain (Trauma-01)
  ('pain_score',        'Pain Scale Score',            'eVitals.27', TRUE,  TRUE,  'numeric', '0–10 numeric pain scale'),
  ('pain_scale_type',   'Pain Scale Type',             'eVitals.28', FALSE, FALSE, 'faces',   'Faces/numeric scale name'),

  -- GCS (components + total)
  ('gcs_eye',           'GCS Eye',                     'eVitals.19', FALSE, TRUE,  'ordinal', '1–4'),
  ('gcs_verbal',        'GCS Verbal',                  'eVitals.20', FALSE, TRUE,  'ordinal', '1–5'),
  ('gcs_motor',         'GCS Motor',                   'eVitals.21', FALSE, TRUE,  'ordinal', '1–6'),
  ('gcs_qualifier_list','GCS Qualifiers',              'eVitals.22', FALSE, FALSE, 'text',    'e.g., intubated, sedated'),
  ('gcs_total',         'GCS Total',                   'eVitals.23', FALSE, TRUE,  'numeric', NULL),

  -- Stroke
  ('stroke_scale_result','Stroke Scale Result',        'eVitals.29', FALSE, FALSE, 'text',    NULL),
  ('stroke_scale_type', 'Stroke Scale Type',           'eVitals.30', FALSE, FALSE, 'text',    NULL),
  ('stroke_scale_score','Stroke Scale Score',          'eVitals.34', FALSE, TRUE,  'numeric', NULL),

  -- Reperfusion / APGAR / RTS
  ('reperfusion_checklist','Reperfusion Checklist',    'eVitals.31', FALSE, FALSE, 'text',    NULL),
  ('apgar_score',       'APGAR Score',                 'eVitals.32', FALSE, TRUE,  'numeric', NULL),
  ('revised_trauma_score','Revised Trauma Score',      'eVitals.33', FALSE, TRUE,  'numeric', NULL),

  -- Prior to care flag
  ('obtained_prior_care','Obtained Prior to This Unit''s Care','eVitals.02', FALSE, FALSE, 'boolean', 'Vital obtained prior to this unit')
ON CONFLICT (vital_type_code) DO UPDATE
SET display_name   = EXCLUDED.display_name,
    nemsis_element = EXCLUDED.nemsis_element,
    is_pain_score  = EXCLUDED.is_pain_score,
    is_numeric     = EXCLUDED.is_numeric,
    scale_family   = EXCLUDED.scale_family,
    notes          = EXCLUDED.notes;

COMMIT;
RESET ROLE;
