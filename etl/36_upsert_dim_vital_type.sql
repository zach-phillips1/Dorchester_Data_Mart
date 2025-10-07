
RESET ROLE; SET ROLE etl_writer;
BEGIN;

-- Seed the types we need right away (Trauma-01 + common vitals)
INSERT INTO mart.dim_vital_type (vital_type_code, nemsis_element, is_pain_score, is_numeric, scale_family, notes)
VALUES
  ('pain_score',      'eVitals.27', TRUE,  TRUE,  'numeric', '0–10 numeric pain scale'),
  ('pain_scale_type', 'eVitals.28', FALSE, FALSE, 'faces',   'faces/numeric name'),
  ('spo2',            'eVitals.12', FALSE, TRUE,  'numeric', NULL),
  ('heart_rate',      'eVitals.10', FALSE, TRUE,  'numeric', NULL),
  ('resp_rate',       'eVitals.14', FALSE, TRUE,  'numeric', NULL),
  ('sbp',             'eVitals.06', FALSE, TRUE,  'numeric', NULL),
  ('dbp',             'eVitals.07', FALSE, TRUE,  'numeric', NULL),
  ('map',             'eVitals.09', FALSE, TRUE,  'numeric', NULL),
  ('etco2',           'eVitals.16', FALSE, TRUE,  'numeric', NULL),
  ('blood_glucose',   'eVitals.18', FALSE, TRUE,  'numeric', NULL),
  ('temperature_f',   'eVitals.24', FALSE, TRUE,  'numeric', NULL),
  ('avpu',            'eVitals.26', FALSE, FALSE, 'ordinal', NULL),
  ('gcs_eye',         'eVitals.19', FALSE, TRUE,  'ordinal', '1–4'),
  ('gcs_verbal',      'eVitals.20', FALSE, TRUE,  'ordinal', '1–5'),
  ('gcs_motor',       'eVitals.21', FALSE, TRUE,  'ordinal', '1–6'),
  ('gcs_total',       'eVitals.23', FALSE, TRUE,  'numeric', NULL),
  ('stroke_scale_type','eVitals.30',FALSE,FALSE,  'text',    NULL),
  ('stroke_scale_result','eVitals.29',FALSE,FALSE,'text',    NULL),
  ('stroke_scale_score','eVitals.34',FALSE,TRUE,  'numeric', NULL),
  ('apgar_score',     'eVitals.32', FALSE, TRUE,  'numeric', NULL),
  ('revised_trauma_score','eVitals.33',FALSE,TRUE,'numeric', NULL)
ON CONFLICT (vital_type_code) DO NOTHING;

COMMIT;
RESET ROLE;
