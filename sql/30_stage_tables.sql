CREATE TABLE IF NOT EXISTS stage.incidents_stg (
  pcr_number TEXT,                                 -- << from Report Writer
  incident_number TEXT,
  unit_code TEXT,
  disposition_code TEXT,
  disposition_label TEXT,
  destination_name TEXT,
  miles_transport NUMERIC,
  primary_impression_code TEXT,
  primary_impression_label TEXT,
  call_created TIMESTAMPTZ,
  notified TIMESTAMPTZ,
  enroute TIMESTAMPTZ,
  at_scene TIMESTAMPTZ,
  depart_scene TIMESTAMPTZ,
  at_dest TIMESTAMPTZ,
  back_in_service TIMESTAMPTZ,
  last_modified TIMESTAMPTZ
);
