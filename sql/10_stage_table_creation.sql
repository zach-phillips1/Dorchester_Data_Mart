CREATE TABLE IF NOT EXISTS stage.incidents_stg (
    -- Identifiers
    pcr_number                      TEXT NOT NULL,
    incident_number                 TEXT,
    -- Unit / shift / crew
    unit_code                       TEXT,
    shift                           TEXT,
    crew_member_id_list             TEXT,
    -- Times (all local)
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
    -- Destination and disposition
    destination_name                TEXT,
    destination_code                TEXT,
    transport_disposition           TEXT,
    -- Dispatch / clinical
    dispatch_reason                 TEXT,
    dispatch_reason_with_code       TEXT,
    primary_impression_code         TEXT,
    primary_impression_desc         TEXT,
    secondary_impression_code_list  TEXT,
    secondary_impression_desc_list  TEXT,
    -- Ops / Quality
    level_of_care_provided          TEXT,
    response_mode_to_scene          TEXT,
    transport_mode_from_scene       TEXT,
    dest_odometer_reading           NUMERIC,
    scene_postal_code               TEXT,
    who_canceled                    TEXT,
    incident_status                 TEXT,
    incident_validity_score         INTEGER,
    -- Incremental
    last_modified                   TIMESTAMP WITHOUT TIME ZONE,
);

CREATE INDEX IF NOT EXISTS ix_incidents_stg_pcr ON stage.incidents_stg(pcr_number);

-- === Documentation ===
COMMENT ON TABLE stage.incidents_stg IS $doc$
purpose: Mirror of Daily Incident List CSV (one row per PCR as exported)
time_policy: local (America/New_York); no TZ conversion
notes: Stage is permissive; duplicates allowed; mart enforces newer-wins.
phi: No names/MRN in this feed; crew IDs only
$doc$;