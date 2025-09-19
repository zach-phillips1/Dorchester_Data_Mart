-- mart.fact_incident
CREATE TABLE IF NOT EXISTS mart.fact_incident (
  incident_key       BIGSERIAL PRIMARY KEY,
  pcr_number         TEXT NOT NULL UNIQUE,        -- << natural key
  incident_number    TEXT,
  unit_key           BIGINT REFERENCES mart.dim_unit(unit_key),
  dest_key           BIGINT REFERENCES mart.dim_destination(dest_key),
  disp_key           BIGINT REFERENCES mart.dim_disposition(disp_key),
  location_key       BIGINT REFERENCES mart.dim_location(location_key),
  call_created_utc   TIMESTAMPTZ,
  notified_utc       TIMESTAMPTZ,
  enroute_utc        TIMESTAMPTZ,
  at_scene_utc       TIMESTAMPTZ,
  depart_scene_utc   TIMESTAMPTZ,
  at_dest_utc        TIMESTAMPTZ,
  back_in_service_utc TIMESTAMPTZ,
  miles_transport    NUMERIC(8,2),
  primary_impression_code  TEXT,
  primary_impression_label TEXT,
  last_modified_utc  TIMESTAMPTZ NOT NULL
);

-- mart.fact_vital
CREATE TABLE IF NOT EXISTS mart.fact_vital (
  vital_key     BIGSERIAL PRIMARY KEY,
  pcr_number    TEXT NOT NULL,                    -- <<
  taken_utc     TIMESTAMPTZ NOT NULL,
  provider_key  BIGINT REFERENCES mart.dim_provider(provider_key),
  hr INT, rr INT, sbp INT, dbp INT,
  spo2 INT, etco2 INT, gcs_total INT, pain_score INT,
  UNIQUE (pcr_number, taken_utc, provider_key)
);

-- mart.fact_medication
CREATE TABLE IF NOT EXISTS mart.fact_medication (
  med_fact_key  BIGSERIAL PRIMARY KEY,
  pcr_number    TEXT NOT NULL,                    -- <<
  med_time_utc  TIMESTAMPTZ NOT NULL,
  med_key       BIGINT REFERENCES mart.dim_medication(med_key),
  provider_key  BIGINT REFERENCES mart.dim_provider(provider_key),
  dose_value    NUMERIC(10,3),
  dose_units    TEXT,
  route_label   TEXT,
  UNIQUE (pcr_number, med_time_utc, med_key, provider_key)
);

-- mart.fact_procedure
CREATE TABLE IF NOT EXISTS mart.fact_procedure (
  proc_fact_key  BIGSERIAL PRIMARY KEY,
  pcr_number     TEXT NOT NULL,                   -- <<
  proc_time_utc  TIMESTAMPTZ NOT NULL,
  proc_key       BIGINT REFERENCES mart.dim_procedure(proc_key),
  provider_key   BIGINT REFERENCES mart.dim_provider(provider_key),
  attempt_num    INT,
  is_success     BOOLEAN,
  device_label   TEXT,
  size_label     TEXT,
  site_label     TEXT,
  confirmation_label TEXT,
  complication_label TEXT,
  UNIQUE (pcr_number, proc_time_utc, proc_key, provider_key, attempt_num)
);
