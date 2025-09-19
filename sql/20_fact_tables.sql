-- mart.fact_incident
CREATE TABLE IF NOT EXISTS mart.fact_incident (
  incident_key              BIGSERIAL PRIMARY KEY,
  pcr_number                TEXT NOT NULL UNIQUE,        -- << natural key
  incident_number           TEXT,
  unit_key                  BIGINT REFERENCES mart.dim_unit(unit_key),
  dest_key                  BIGINT REFERENCES mart.dim_destination(dest_key),
  disp_key                  BIGINT REFERENCES mart.dim_disposition(disp_key),
  location_key              BIGINT REFERENCES mart.dim_location(location_key),
  call_created              TIMESTAMP WITHOUT TIME ZONE,
  notified                  TIMESTAMP WITHOUT TIME ZONE,
  enroute                   TIMESTAMP WITHOUT TIME ZONE,
  at_scene                  TIMESTAMP WITHOUT TIME ZONE,
  depart_scene              TIMESTAMP WITHOUT TIME ZONE,
  at_dest                   TIMESTAMP WITHOUT TIME ZONE,
  back_in_service           TIMESTAMP WITHOUT TIME ZONE,
  miles_transport           NUMERIC(8,2),
  primary_impression_code   TEXT,
  primary_impression_label  TEXT,
  last_modified             TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

-- mart.fact_vital
CREATE TABLE IF NOT EXISTS mart.fact_vital (
  vital_key     BIGSERIAL PRIMARY KEY,
  pcr_number    TEXT NOT NULL,                    -- <<
  taken         TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  provider_key  BIGINT REFERENCES mart.dim_provider(provider_key),
  hr INT, rr INT, sbp INT, dbp INT,
  spo2 INT, etco2 INT, gcs_total INT, pain_score INT,
  UNIQUE (pcr_number, taken, provider_key)
);

-- mart.fact_medication
CREATE TABLE IF NOT EXISTS mart.fact_medication (
  med_fact_key  BIGSERIAL PRIMARY KEY,
  pcr_number    TEXT NOT NULL,                    -- <<
  med_time      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  med_key       BIGINT REFERENCES mart.dim_medication(med_key),
  provider_key  BIGINT REFERENCES mart.dim_provider(provider_key),
  dose_value    NUMERIC(10,3),
  dose_units    TEXT,
  route_label   TEXT,
  UNIQUE (pcr_number, med_time, med_key, provider_key)
);

-- mart.fact_procedure
CREATE TABLE IF NOT EXISTS mart.fact_procedure (
  proc_fact_key         BIGSERIAL PRIMARY KEY,
  pcr_number            TEXT NOT NULL,                   -- <<
  proc_time             TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  proc_key              BIGINT REFERENCES mart.dim_procedure(proc_key),
  provider_key          BIGINT REFERENCES mart.dim_provider(provider_key),
  attempt_num           INT,
  is_success            BOOLEAN,
  device_label          TEXT,
  size_label            TEXT,
  site_label            TEXT,
  confirmation_label    TEXT,
  complication_label    TEXT,
  UNIQUE (pcr_number, proc_time, proc_key, provider_key, attempt_num)
);
