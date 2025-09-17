CREATE TABLE IF NOT EXISTS mart.fact_incident (
  incident_key              BIGSERIAL PRIMARY KEY,
  pcr_num                   TEXT NOT NULL UNIQUE,
  incident_number           TEXT,
  unit_key                  BIGINT REFERENCES mart.dim_unit(unit_key),
  dest_key                  BIGINT REFERENCES mart.dim_destination(dest_key),
  disp_key                  BIGINT REFERENCES mart.dim_disposition(disp_key),
  location_key              BIGINT REFERENCES mart.dim_location(location_key),
  call_created_utc          TIMESTAMPTZ,
  notified_utc              TIMESTAMPTZ,
  enroute_utc               TIMESTAMPTZ,
  at_scene_utc              TIMESTAMPTZ,
  depart_scene_utc          TIMESTAMPTZ,
  at_dest_utc               TIMESTAMPTZ,
  back_in_service_utc       TIMESTAMPTZ,
  miles_transport           NUMERIC(8,2),
  primary_impression_code   TEXT,
  primary_impression_label  TEXT,
  last_modified_utc         TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_fact_incident_unit_time ON mart.fact_incident (unit_key, call_created_utc);

CREATE TABLE IF NOT EXISTS mart.fact_vital (
  vital_key         BIGSERIAL PRIMARY KEY,
  pcr_num           TEXT NOT NULL,
  taken_utc         TIMESTAMPTZ NOT NULL,
  provider_key      BIGINT REFERENCES mart.dim_provider(provider_key),
  hr INT, rr INT, sbp INT, dbp INT,
  spo2 INT, etco2 INT, gcs_total INT, pain_score INT,
  UNIQUE (pcr_num, taken_utc, provider_key)
);

CREATE TABLE IF NOT EXISTS mart.fact_medication (
  med_fact_key      BIGSERIAL PRIMARY KEY,
  pcr_num           TEXT NOT NULL,
  med_time_utc      TIMESTAMPTZ NOT NULL,
  med_key           BIGINT REFERENCES mart.dim_medication(med_key),
  provider_key      BIGINT REFERENCES mart.dim_provider(provider_key),
  dose_value        NUMERIC(10,3),
  dose_units        TEXT,
  route_label       TEXT,
  UNIQUE (pcr_num, med_time_utc, med_key, provider_key)
);

CREATE TABLE IF NOT EXISTS mart.fact_procedure (
  proc_fact_key         BIGSERIAL PRIMARY KEY,
  pcr_num               TEXT NOT NULL,
  proc_time_utc         TIMESTAMPTZ NOT NULL,
  proc_key              BIGINT REFERENCES mart.dim_procedure(proc_key),
  provider_key          BIGINT REFERENCES mart.dim_provider(provider_key),
  attempt_num           INT,
  is_success            BOOLEAN,
  device_label          TEXT,
  size_label            TEXT,
  site_label            TEXT,
  confirmation_label    TEXT,
  complication_label    TEXT,
  UNIQUE (pcr_num, proc_time_utc, proc_key, provider_key, attempt_num)
);

CREATE TABLE IF NOT EXISTS etl.load_log (
  load_id        BIGSERIAL PRIMARY KEY,
  subject        TEXT NOT NULL,   -- incidents|vitals|meds|procs|crew
  file_name      TEXT NOT NULL,
  file_checksum  TEXT,
  rows_in_file   INT,
  rows_loaded    INT,
  loaded_at_utc  TIMESTAMPTZ DEFAULT now(),
  status         TEXT,            -- OK|WARN|ERROR
  notes          TEXT
);
