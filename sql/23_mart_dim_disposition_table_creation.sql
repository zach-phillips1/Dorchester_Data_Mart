SET ROLE ems_owner;

CREATE TABLE IF NOT EXISTS mart.dim_disposition (
    disposition_key             BIGSERIAL PRIMARY KEY,
    label_raw                   TEXT,
    is_patient_encounter        BOOL,
    is_canceled                 BOOL,
    notes                       TEXT
)







RESET ROLE;