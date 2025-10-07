-- etl/42_upsert_fact_vital.sql
-- Unpivot stage.vitals_stg (wide) into mart.fact_vital (one row per measurement)
-- Policies:
--   - Local time only (TIMESTAMP WITHOUT TIME ZONE)
--   - Newer-wins via last_modified
--   - Skip rows with NULL vital_taken_time
--   - Deduplicate within this statement on (pcr_number, vital_type_key, vital_taken_time)

RESET ROLE; SET ROLE etl_writer;
BEGIN;

WITH base AS (
  SELECT
    s.pcr_number,
    s.vital_taken_time,
    COALESCE(s.last_modified, s.vital_taken_time) AS last_modified,

    -- raw columns from stage (wide)
    s.pain_score, s.pain_scale_type,
    s.spo2, s.heart_rate, s.resp_rate, s.sbp, s.dbp, s.map,
    s.etco2, s.blood_glucose, s.temperature_f, s.avpu,
    s.gcs_eye, s.gcs_verbal, s.gcs_motor, s.gcs_total, s.gcs_qualifier_list,
    s.stroke_scale_type, s.stroke_scale_result,
    s.apgar_score, s.revised_trauma_score
  FROM stage.vitals_stg s
  WHERE s.pcr_number IS NOT NULL
    AND s.vital_taken_time IS NOT NULL               -- guard for NOT NULL target
),
-- Parse GCS component strings into bounded integers
parsed AS (
  SELECT
    b.*,

    -- GCS Eye (1–4)
    LEAST(4, GREATEST(1, COALESCE(
      ((regexp_match(b.gcs_eye,   '([0-9]+)\s*$'))[1])::int,   -- ... - 4
      ((regexp_match(b.gcs_eye,   '^\s*([0-9]+)'))[1])::int,   -- 4 - ...
      CASE
        WHEN b.gcs_eye ILIKE '%spontan%' THEN 4
        WHEN b.gcs_eye ILIKE '%speech%'  OR b.gcs_eye ILIKE '%verbal%' THEN 3
        WHEN b.gcs_eye ILIKE '%pain%'    THEN 2
        WHEN b.gcs_eye ILIKE '%none%'    THEN 1
        ELSE NULL
      END
    ))) AS gcs_eye_num,

    -- GCS Verbal (1–5)
    LEAST(5, GREATEST(1, COALESCE(
      ((regexp_match(b.gcs_verbal,'([0-9]+)\s*$'))[1])::int,
      ((regexp_match(b.gcs_verbal,'^\s*([0-9]+)'))[1])::int,
      CASE
        WHEN b.gcs_verbal ILIKE '%oriented%'      THEN 5
        WHEN b.gcs_verbal ILIKE '%confused%'      THEN 4
        WHEN b.gcs_verbal ILIKE '%inappropriate%' THEN 3
        WHEN b.gcs_verbal ILIKE '%incompreh%'     THEN 2
        WHEN b.gcs_verbal ILIKE '%none%'          THEN 1
        ELSE NULL
      END
    ))) AS gcs_verbal_num,

    -- GCS Motor (1–6)
    LEAST(6, GREATEST(1, COALESCE(
      ((regexp_match(b.gcs_motor, '([0-9]+)\s*$'))[1])::int,
      ((regexp_match(b.gcs_motor, '^\s*([0-9]+)'))[1])::int,
      CASE
        WHEN b.gcs_motor ILIKE '%obeys%'    THEN 6
        WHEN b.gcs_motor ILIKE '%localiz%'  THEN 5
        WHEN b.gcs_motor ILIKE '%withdraw%' THEN 4
        WHEN b.gcs_motor ILIKE '%flex%'     THEN 3  -- abnormal flexion
        WHEN b.gcs_motor ILIKE '%extend%'   THEN 2
        WHEN b.gcs_motor ILIKE '%none%'     THEN 1
        ELSE NULL
      END
    ))) AS gcs_motor_num
  FROM base b
),
-- Unpivot (one SELECT per vital) → UNION ALL
unpivot AS (

  -- Pain score (numeric)
  SELECT pcr_number, vital_taken_time, last_modified,
         'pain_score'::text AS vital_type_code,
         NULLIF(pain_score::text,'')::numeric AS value_numeric,
         pain_score::text AS value_text,
         NULL::text AS unit, pain_scale_type AS scale_name,
         NULL::text AS qualifiers
  FROM parsed WHERE pain_score IS NOT NULL

  UNION ALL
  -- Pain scale type (keep for context)
  SELECT pcr_number, vital_taken_time, last_modified,
         'pain_scale_type', NULL::numeric, pain_scale_type::text, NULL, pain_scale_type::text, NULL
  FROM parsed WHERE pain_scale_type IS NOT NULL

  UNION ALL
  -- SpO2
  SELECT pcr_number, vital_taken_time, last_modified,
         'spo2', NULLIF(spO2::text,'')::numeric, s.spo2::text, '%', NULL, NULL
  FROM parsed s WHERE s.spo2 IS NOT NULL

  UNION ALL
  -- Heart rate
  SELECT pcr_number, vital_taken_time, last_modified,
         'heart_rate', NULLIF(heart_rate::text,'')::numeric, heart_rate::text, 'bpm', NULL, NULL
  FROM parsed WHERE heart_rate IS NOT NULL

  UNION ALL
  -- Resp rate
  SELECT pcr_number, vital_taken_time, last_modified,
         'resp_rate', NULLIF(resp_rate::text,'')::numeric, resp_rate::text, 'rpm', NULL, NULL
  FROM parsed WHERE resp_rate IS NOT NULL

  UNION ALL
  -- BP / MAP
  SELECT pcr_number, vital_taken_time, last_modified,
         'sbp', NULLIF(sbp::text,'')::numeric, sbp::text, 'mmHg', NULL, NULL FROM parsed WHERE sbp IS NOT NULL
  UNION ALL
  SELECT pcr_number, vital_taken_time, last_modified,
         'dbp', NULLIF(dbp::text,'')::numeric, dbp::text, 'mmHg', NULL, NULL FROM parsed WHERE dbp IS NOT NULL
  UNION ALL
  SELECT pcr_number, vital_taken_time, last_modified,
         'map', NULLIF(map::text,'')::numeric, map::text, 'mmHg', NULL, NULL FROM parsed WHERE map IS NOT NULL

  UNION ALL
  -- EtCO2
  SELECT pcr_number, vital_taken_time, last_modified,
         'etco2', NULLIF(etco2::text,'')::numeric, etco2::text, 'mmHg', NULL, NULL
  FROM parsed WHERE etco2 IS NOT NULL

  UNION ALL
  -- Blood glucose
  SELECT pcr_number, vital_taken_time, last_modified,
         'blood_glucose', NULLIF(blood_glucose::text,'')::numeric, blood_glucose::text, 'mg/dL', NULL, NULL
  FROM parsed WHERE blood_glucose IS NOT NULL

  UNION ALL
  -- Temp (F)
  SELECT pcr_number, vital_taken_time, last_modified,
         'temperature_f', NULLIF(temperature_f::text,'')::numeric, temperature_f::text, 'F', NULL, NULL
  FROM parsed WHERE temperature_f IS NOT NULL

  UNION ALL
  -- AVPU (store as text; you can later map to ordinal if desired)
  SELECT pcr_number, vital_taken_time, last_modified,
         'avpu', NULL::numeric, avpu::text, NULL, NULL, NULL
  FROM parsed WHERE avpu IS NOT NULL

  UNION ALL
  -- GCS components + reported total
  SELECT pcr_number, vital_taken_time, last_modified,
         'gcs_eye', gcs_eye_num::numeric, gcs_eye, NULL, NULL, gcs_qualifier_list
  FROM parsed WHERE gcs_eye IS NOT NULL

  UNION ALL
  SELECT pcr_number, vital_taken_time, last_modified,
         'gcs_verbal', gcs_verbal_num::numeric, gcs_verbal, NULL, NULL, gcs_qualifier_list
  FROM parsed WHERE gcs_verbal IS NOT NULL

  UNION ALL
  SELECT pcr_number, vital_taken_time, last_modified,
         'gcs_motor', gcs_motor_num::numeric, gcs_motor, NULL, NULL, gcs_qualifier_list
  FROM parsed WHERE gcs_motor IS NOT NULL

  UNION ALL
  SELECT pcr_number, vital_taken_time, last_modified,
         'gcs_total', NULLIF(gcs_total::text,'')::numeric, gcs_total::text, NULL, NULL, gcs_qualifier_list
  FROM parsed WHERE gcs_total IS NOT NULL

  UNION ALL
  -- Stroke, APGAR, RTS
  SELECT pcr_number, vital_taken_time, last_modified,
         'stroke_scale_type', NULL::numeric, stroke_scale_type::text, NULL, NULL, NULL FROM parsed WHERE stroke_scale_type IS NOT NULL

  UNION ALL
  SELECT pcr_number, vital_taken_time, last_modified,
         'stroke_scale_result', NULL::numeric, stroke_scale_result::text, NULL, NULL, NULL FROM parsed WHERE stroke_scale_result IS NOT NULL

  UNION ALL
  SELECT pcr_number, vital_taken_time, last_modified,
         'apgar_score', NULLIF(apgar_score::text,'')::numeric, apgar_score::text, NULL, NULL, NULL FROM parsed WHERE apgar_score IS NOT NULL

  UNION ALL
  SELECT pcr_number, vital_taken_time, last_modified,
         'revised_trauma_score', NULLIF(revised_trauma_score::text,'')::numeric, revised_trauma_score::text, NULL, NULL, NULL FROM parsed WHERE revised_trauma_score IS NOT NULL
),
-- Join to dim and deduplicate rows that share the same conflict key
dedup AS (
  SELECT *
  FROM (
    SELECT
      u.*,
      d.vital_type_key,
      ROW_NUMBER() OVER (
        PARTITION BY u.pcr_number, d.vital_type_key, u.vital_taken_time
        ORDER BY u.last_modified DESC,
                 CASE WHEN u.value_numeric IS NOT NULL THEN 0 ELSE 1 END,
                 u.value_text DESC
      ) AS rn
    FROM unpivot u
    LEFT JOIN mart.dim_vital_type d
      ON d.vital_type_code = u.vital_type_code
    WHERE d.vital_type_key IS NOT NULL
  ) x
  WHERE rn = 1
)

INSERT INTO mart.fact_vital (
  pcr_number, vital_type_key, vital_taken_time,
  value_numeric, value_text, unit, scale_name, qualifiers,
  recorded_by, last_modified
)
SELECT
  pcr_number, vital_type_key, vital_taken_time,
  value_numeric, value_text, unit, scale_name, qualifiers,
  NULL::text AS recorded_by,
  last_modified
FROM dedup
ON CONFLICT (pcr_number, vital_type_key, vital_taken_time) DO UPDATE
SET
  value_numeric = EXCLUDED.value_numeric,
  value_text    = EXCLUDED.value_text,
  unit          = EXCLUDED.unit,
  scale_name    = EXCLUDED.scale_name,
  qualifiers    = EXCLUDED.qualifiers,
  recorded_by   = EXCLUDED.recorded_by,
  last_modified = EXCLUDED.last_modified
WHERE EXCLUDED.last_modified > mart.fact_vital.last_modified;

COMMIT;
RESET ROLE;

-- If/when you add stage.vitals_stg.stroke_scale_score, re-enable this block inside UNPIVOT:
-- UNION ALL
-- SELECT pcr_number, vital_taken_time, last_modified,
--        'stroke_scale_score', NULLIF(stroke_scale_score::text,'')::numeric, stroke_scale_score::text, NULL, NULL, NULL
-- FROM parsed WHERE stroke_scale_score IS NOT NULL;
