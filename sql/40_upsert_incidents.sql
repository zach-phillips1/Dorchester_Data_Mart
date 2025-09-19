WITH keys AS (
  SELECT
    s.*,
    u.unit_key,
    d.dest_key,
    x.disp_key
  FROM stage.incidents_stg s
  LEFT JOIN mart.dim_unit u ON u.unit_code = s.unit_code
  LEFT JOIN mart.dim_destination d ON d.dest_name = s.destination_name
  LEFT JOIN mart.dim_disposition x ON x.disp_code = s.disposition_code
)
INSERT INTO mart.fact_incident (
  pcr_number, incident_number, unit_key, dest_key, disp_key,
  miles_transport, primary_impression_code, primary_impression_label,
  call_created, notified, enroute, at_scene, depart_scene,
  at_dest, back_in_service, last_modified
)
SELECT
  pcr_number, incident_number, unit_key, dest_key, disp_key,
  miles_transport, primary_impression_code, primary_impression_label,
  call_created, notified, enroute, at_scene, depart_scene, at_dest, back_in_service, last_modified
FROM keys
ON CONFLICT (pcr_number) DO UPDATE
SET incident_number = EXCLUDED.incident_number,
    unit_key = EXCLUDED.unit_key,
    dest_key = EXCLUDED.dest_key,
    disp_key = EXCLUDED.disp_key,
    miles_transport = EXCLUDED.miles_transport,
    primary_impression_code = EXCLUDED.primary_impression_code,
    primary_impression_label = EXCLUDED.primary_impression_label,
    call_created = EXCLUDED.call_created,
    notified = EXCLUDED.notified,
    enroute = EXCLUDED.enroute,
    at_scene = EXCLUDED.at_scene,
    depart_scene = EXCLUDED.depart_scene,
    at_dest = EXCLUDED.at_dest,
    back_in_service = EXCLUDED.back_in_service,
    last_modified = EXCLUDED.last_modified
WHERE mart.fact_incident.last_modified < EXCLUDED.last_modified;
