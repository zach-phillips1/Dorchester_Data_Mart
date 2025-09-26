SET ROLE ems_owner;

CREATE TABLE IF NOT EXISTS mart.fact_incident(
    -- Key identifiers
    pcr_number                      TEXT PRIMARY KEY NOT NULL,
    unit_key                        TEXT,
    destination_key                 TEXT,
    transport_disposition_key       TEXT,
    unit_disp_key                   TEXT,
    -- Times
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
    unit_cancelled_time             TIMESTAMP WITHOUT TIME ZONE,
    -- Carry
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
    last_modified                   TIMESTAMP WITHOUT TIME ZONE
)

CREATE INDEX IF NOT EXISTS ix_fact_incident_pcr ON mart.fact_incident(pcr_number);

