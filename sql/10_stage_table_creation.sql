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

COMMENT ON COLUMN stage.pcr_number IS $doc$
desc: ImageTrend unique PCR identifier
source: CSV "PCR Number"
nemsis: eRecord.01
rules: natural key upstream; must be present; duplicate allowed in stage
$doc$;

COMMENT ON COLUMN stage.incident_number IS $doc$
desc: Agency unique incident number
source: CSV "Incident Number"
nemsis: eResponse.03
rules: Should be unique, however, multiple patients can have same incident number
$doc$;

COMMENT ON COLUMN stage.unit_code IS $doc$
desc: Agency specific response unit identifier
source: CSV "Unit"
nemsis: eResponse.14
rules: 
$doc$;

COMMENT ON COLUMN stage.shift IS $doc$
desc: Agency specific shift identifier
source: CSV "Shift"
nemsis: itResponse.005
rules:
$doc$;

COMMENT ON COLUMN stage.crew_member_id_list IS $doc$
desc: List of crew members as IDs
source: CSV "Crew Member ID List"
nemsis: eCrew.01
rules: ID only, crew names not listed.
$doc$;

COMMENT ON COLUMN stage.psap_call_time IS $doc$
desc: Timestamp of PSAP notification time
source: CSV "PSAP Call Date Time"
nemsis: eTimes.01
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.dispatch_notification_time IS $doc$
desc: Timestamp of Dispatch Notification Time
source: CSV "Dispatch Notified Date Time"
nemsis: eTimes.02
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.unit_dispatch_time IS $doc$
desc: Timestamp of Unit Dispatch Time
source: CSV "Unit Dispatch Time"
nemsis: eTimes.03
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.unit_enroute_time IS $doc$
desc: Timestamp of Unit En Route Time
source: CSV "Unit En Route Time"
nemsis: eTimes.05
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.unit_arrival_time IS $doc$
desc: Timestamp of Unit Arrival Time
source: CSV "Unit Arrival Time"
nemsis: eTimes.06
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.unit_pt_contact_time IS $doc$
desc: Timestamp of Unit Patient Contact Time
source: CSV "Unit Arrived At Patient Time"
nemsis: eTimes.07
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.unit_left_scene_time IS $doc$
desc: Timestamp of Unit Left Scene Time
source: CSV "Unit Left Scene Date Time"
nemsis: eTimes.09
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.unit_arrive_dest_time IS $doc$
desc: Timestamp of Unit Arrive at Destination Time
source: CSV "Patient Arrived At Destination Time"
nemsis: eTimes.11
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.unit_toc_time IS $doc$
desc: Timestamp of Patient Transfer of Care Time
source: CSV "Patient Transfer Of Care Time"
nemsis: eTimes.12
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.unit_in_service_time IS $doc$
desc: Timestamp of Unit Back In Service Time
source: CSV "Unit Back In Service Time"
nemsis: eTimes.13
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.unit_cancel_time IS $doc$
desc: Timestamp of Unit Cancelled Time
source: CSV "Unit Cancelled Time"
nemsis: eTimes.14
rules: local time without TZ
$doc$

COMMENT ON COLUMN stage.destination_name IS $doc$
desc: Destination Hospital Name
source: CSV "Destination Name"
nemsis: eDisposition.01
rules: 
$doc$

COMMENT ON COLUMN stage.destination_code IS $doc$
desc: Destination Hospital Code based on eMeds/MIEMSS
source: CSV "Disposition Destination Code Delivered Transferred To"
nemsis: eDisposition.02
rules: 
$doc$

COMMENT ON COLUMN stage.transport_disposition IS $doc$
desc: Transport disposition some possible values "Transport by this EMS Unit"
source: CSV "Transport Disposition"
nemsis: eDisposition.30
rules: 
$doc$