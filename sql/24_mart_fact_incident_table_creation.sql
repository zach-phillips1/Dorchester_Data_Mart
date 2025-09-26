-- 24_mart_fact_incident_table_creation.sql
SET ROLE ems_owner;
BEGIN;

CREATE TABLE IF NOT EXISTS mart.fact_incident (
    -- Key identifiers
    pcr_number                      TEXT PRIMARY KEY,
    unit_key                        INTEGER,  -- FK → mart.dim_unit(unit_key)
    destination_key                 INTEGER,  -- FK → mart.dim_destination(destination_key)
    transport_disp_key              INTEGER,  -- FK → mart.dim_disposition(disposition_key, source_type='transport')
    unit_disp_key                   INTEGER,  -- FK → mart.dim_disposition(disposition_key, source_type='unit')

    -- Times (all local: America/New_York; TIMESTAMP WITHOUT TIME ZONE)
    psap_call_time                  TIMESTAMP WITHOUT TIME ZONE,
    dispatch_notified_time          TIMESTAMP WITHOUT TIME ZONE,
    unit_dispatch_time              TIMESTAMP WITHOUT TIME ZONE,
    unit_enroute_time               TIMESTAMP WITHOUT TIME ZONE,
    unit_arrival_time               TIMESTAMP WITHOUT TIME ZONE,
    unit_pt_contact_time            TIMESTAMP WITHOUT TIME ZONE,
    unit_left_scene_time            TIMESTAMP WITHOUT TIME ZONE,
    unit_arrive_dest_time           TIMESTAMP WITHOUT TIME ZONE,
    unit_toc_time                   TIMESTAMP WITHOUT TIME ZONE,
    unit_in_service_time            TIMESTAMP WITHOUT TIME ZONE,
    unit_cancel_time                TIMESTAMP WITHOUT TIME ZONE,

    -- Carry (denormalized for convenience/auditing)
    incident_number                 TEXT,
    unit_code                       TEXT,
    destination_code                TEXT,
    destination_name                TEXT,
    transport_disposition           TEXT,
    unit_disposition                TEXT,
    level_of_care_provided          TEXT,
    response_mode_to_scene          TEXT,
    transport_mode_from_scene       TEXT,
    dest_odometer_reading           NUMERIC,
    scene_postal_code               TEXT,
    who_canceled                    TEXT,
    incident_status                 TEXT,
    incident_validity_score         INTEGER,
    primary_impression_code         TEXT,
    primary_impression_desc         TEXT,
    secondary_impression_code_list  TEXT,
    secondary_impression_desc_list  TEXT,
    dispatch_reason                 TEXT,
    dispatch_reason_with_code       TEXT,
    emd_card_number                 TEXT,

    -- Incremental control
    last_modified                   TIMESTAMP WITHOUT TIME ZONE
);

-- Foreign keys (assumes standard PKs in dims)
ALTER TABLE mart.fact_incident
  ADD CONSTRAINT fk_fact_unit
    FOREIGN KEY (unit_key) REFERENCES mart.dim_unit(unit_key);

ALTER TABLE mart.fact_incident
  ADD CONSTRAINT fk_fact_destination
    FOREIGN KEY (destination_key) REFERENCES mart.dim_destination(destination_key);

ALTER TABLE mart.fact_incident
  ADD CONSTRAINT fk_fact_transport_disp
    FOREIGN KEY (transport_disp_key) REFERENCES mart.dim_disposition(disposition_key);

ALTER TABLE mart.fact_incident
  ADD CONSTRAINT fk_fact_unit_disp
    FOREIGN KEY (unit_disp_key) REFERENCES mart.dim_disposition(disposition_key);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS ix_fact_incident_unit_key        ON mart.fact_incident(unit_key);
CREATE INDEX IF NOT EXISTS ix_fact_incident_destination_key ON mart.fact_incident(destination_key);
CREATE INDEX IF NOT EXISTS ix_fact_incident_transport_disp  ON mart.fact_incident(transport_disp_key);
CREATE INDEX IF NOT EXISTS ix_fact_incident_unit_disp       ON mart.fact_incident(unit_disp_key);
CREATE INDEX IF NOT EXISTS ix_fact_incident_last_modified   ON mart.fact_incident(last_modified);

-- Data dictionary (comments)
COMMENT ON TABLE  mart.fact_incident IS 'One row per PCR from ImageTrend; local times only; newer-wins via last_modified.';
COMMENT ON COLUMN mart.fact_incident.pcr_number IS 'Natural key from ePCR (TEXT).';
COMMENT ON COLUMN mart.fact_incident.unit_key IS 'FK to dim_unit; _UNK if unmapped.';
COMMENT ON COLUMN mart.fact_incident.destination_key IS 'FK to dim_destination; _UNK if unmapped.';
COMMENT ON COLUMN mart.fact_incident.transport_disp_key IS 'FK to dim_disposition (source_type=transport).';
COMMENT ON COLUMN mart.fact_incident.unit_disp_key IS 'FK to dim_disposition (source_type=unit).';
COMMENT ON COLUMN mart.fact_incident.last_modified IS 'Incremental control from Report Writer; local civil time.';

COMMIT;
RESET ROLE;
