-- Upsert new disposition labels from stage -> mart.dim_disposition
-- Run as: etl_writer
BEGIN;

WITH src_raw AS (
  SELECT 'transport'::text AS source_type,
         NULLIF(BTRIM(transport_disposition), '') AS label_raw
  FROM stage.incidents_stg
  UNION ALL
  SELECT 'unit'::text,
         NULLIF(BTRIM(unit_disposition), '')
  FROM stage.incidents_stg
),
src AS (
  -- distinct, non-null labels
  SELECT source_type, label_raw
  FROM src_raw
  WHERE label_raw IS NOT NULL
  GROUP BY source_type, label_raw
),
prepared AS (
  -- default mapping for anything not already seeded/curated
  SELECT
    s.source_type,
    s.label_raw,
    -- slugify: lower, replace non-alnum with "_", collapse/trim "_"
    lower(regexp_replace(regexp_replace(btrim(s.label_raw), '[^a-zA-Z0-9]+', '_', 'g'),
                         '^_+|_+$', '', 'g'))              AS slug,
    'other'::text                                          AS category,
    false::boolean                                         AS is_transport_expected,
    false::boolean                                         AS is_patient_encounter,
    false::boolean                                         AS is_canceled
  FROM src s
)
INSERT INTO mart.dim_disposition
  (source_type, label_raw, slug, category,
   is_transport_expected, is_patient_encounter, is_canceled)
SELECT p.source_type, p.label_raw, p.slug, p.category,
       p.is_transport_expected, p.is_patient_encounter, p.is_canceled
FROM prepared p
ON CONFLICT (source_type, label_raw) DO NOTHING;

COMMIT;
