-- etl/41_upsert_fact_incident.sql
RESET ROLE; SET ROLE etl_writer;
BEGIN;

WITH latest AS (
  -- keep the newest row per PCR (by last_modified)
  SELECT *
  FROM (
    SELECT s.*,
           ROW_NUMBER() OVER (PARTITION BY pcr_number ORDER BY last_modified DESC) AS rn
    FROM stage.incidents_stg s
  ) x
  WHERE rn = 1
),
lk AS (
  -- look up dimension surrogate keys; fall back to _UNK
  SELECT
    l.*,
    COALESCE(u.unit_key,
             (SELECT unit_key FROM mart.dim_unit WHERE unit_code = '_UNK')) AS unit_key,
    COALESCE(d.destination_key,
             (SELECT destination_key FROM mart.dim_destination WHERE destination_code = '_UNK')) AS destination_key,
    COALESCE(td.disposition_key,
             (SELECT disposition_key FROM mart.dim_disposition WHERE source_type='transport' AND slug='_UNK')) AS transport_disp_key,
    COALESCE(ud.disposition_key,
             (SELECT disposition_key FROM mart.dim_disposition WHERE source_type='unit' AND slug='_UNK')) AS unit_disp_key
  FROM latest l
  LEFT JOIN mart.dim_unit u
    ON u.unit_code = UPPER(TRIM(l.unit_code))
  LEFT JOIN mart.dim_destination d
    ON d.destination_code = l.destination_code
  LEFT JOIN mart.dim_disposition td
    ON td.source_type = 'transport' AND td.label_raw = l.transport_disposition
  LEFT JOIN mart.dim_disposition ud
    ON ud.source_type = 'unit' AND ud.label_raw = l.unit_disposition
)

INSERT INTO mart.fact_incident (
  pcr_number, incident_number,
  unit_key, destination_key, transport_disp_key, unit_disp_key,

  psap_call_time, dispatch_notified_time, unit_dispatch_time, unit_enroute_time,
  unit_arrival_time, unit_pt_contact_time, unit_left_scene_time, unit_arrive_dest_time,
  unit_toc_time, unit_in_service_time, unit_cancel_time,

  unit_code, destination_code, destination_name,
  transport_disposition, unit_disposition,
  level_of_care_provided, response_mode_to_scene, transport_mode_from_scene,
  dest_odometer_reading, scene_postal_code, who_canceled,
  incident_status, incident_validity_score,
  primary_impression_code, primary_impression_desc,
  secondary_impression_code_list, secondary_impression_desc_list,
  dispatch_reason, dispatch_reason_with_code,
  emd_card_number,
  last_modified
)
SELECT
  pcr_number, incident_number,
  unit_key, destination_key, transport_disp_key, unit_disp_key,

  psap_call_time, dispatch_notified_time, unit_dispatch_time, unit_enroute_time,
  unit_arrival_time, unit_pt_contact_time, unit_left_scene_time, unit_arrive_dest_time,
  unit_toc_time, unit_in_service_time, unit_cancel_time,

  unit_code, destination_code, destination_name,
  transport_disposition, unit_disposition,
  level_of_care_provided, response_mode_to_scene, transport_mode_from_scene,
  dest_odometer_reading, scene_postal_code, who_canceled,
  incident_status, incident_validity_score,
  primary_impression_code, primary_impression_desc,
  secondary_impression_code_list, secondary_impression_desc_list,
  dispatch_reason, dispatch_reason_with_code,
  emd_card_number,
  last_modified
FROM lk
ON CONFLICT (pcr_number) DO UPDATE
SET
  unit_key = EXCLUDED.unit_key,
  destination_key = EXCLUDED.destination_key,
  transport_disp_key = EXCLUDED.transport_disp_key,
  unit_disp_key = EXCLUDED.unit_disp_key,

  psap_call_time = EXCLUDED.psap_call_time,
  dispatch_notified_time = EXCLUDED.dispatch_notified_time,
  unit_dispatch_time = EXCLUDED.unit_dispatch_time,
  unit_enroute_time = EXCLUDED.unit_enroute_time,
  unit_arrival_time = EXCLUDED.unit_arrival_time,
  unit_pt_contact_time = EXCLUDED.unit_pt_contact_time,
  unit_left_scene_time = EXCLUDED.unit_left_scene_time,
  unit_arrive_dest_time = EXCLUDED.unit_arrive_dest_time,
  unit_toc_time = EXCLUDED.unit_toc_time,
  unit_in_service_time = EXCLUDED.unit_in_service_time,
  unit_cancel_time = EXCLUDED.unit_cancel_time,

  unit_code = EXCLUDED.unit_code,
  destination_code = EXCLUDED.destination_code,
  destination_name = EXCLUDED.destination_name,
  transport_disposition = EXCLUDED.transport_disposition,
  unit_disposition = EXCLUDED.unit_disposition,
  level_of_care_provided = EXCLUDED.level_of_care_provided,
  response_mode_to_scene = EXCLUDED.response_mode_to_scene,
  transport_mode_from_scene = EXCLUDED.transport_mode_from_scene,
  dest_odometer_reading = EXCLUDED.dest_odometer_reading,
  scene_postal_code = EXCLUDED.scene_postal_code,
  who_canceled = EXCLUDED.who_canceled,
  incident_status = EXCLUDED.incident_status,
  incident_validity_score = EXCLUDED.incident_validity_score,
  primary_impression_code = EXCLUDED.primary_impression_code,
  primary_impression_desc = EXCLUDED.primary_impression_desc,
  secondary_impression_code_list = EXCLUDED.secondary_impression_code_list,
  secondary_impression_desc_list = EXCLUDED.secondary_impression_desc_list,
  dispatch_reason = EXCLUDED.dispatch_reason,
  dispatch_reason_with_code = EXCLUDED.dispatch_reason_with_code,
  emd_card_number = EXCLUDED.emd_card_number,

  last_modified = EXCLUDED.last_modified
WHERE EXCLUDED.last_modified > mart.fact_incident.last_modified;

COMMIT;
RESET ROLE;
