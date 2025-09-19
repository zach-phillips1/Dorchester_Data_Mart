CREATE TABLE IF NOT EXISTS stage.incidents_stg (
  pcr_number                TEXT,
  incident_number           TEXT,
  unit_code                 TEXT,
  disposition_code          TEXT,
  disposition_label         TEXT,
  destination_name          TEXT,
  miles_transport           NUMERIC,
  primary_impression_code   TEXT,
  primary_impression_label  TEXT,
  call_created              TIMESTAMP WITHOUT TIME ZONE,
  notified                  TIMESTAMP WITHOUT TIME ZONE,
  enroute                   TIMESTAMP WITHOUT TIME ZONE,
  at_scene                  TIMESTAMP WITHOUT TIME ZONE,
  depart_scene              TIMESTAMP WITHOUT TIME ZONE,
  at_dest                   TIMESTAMP WITHOUT TIME ZONE,
  back_in_service           TIMESTAMP WITHOUT TIME ZONE,
  last_modified             TIMESTAMP WITHOUT TIME ZONE 
);
