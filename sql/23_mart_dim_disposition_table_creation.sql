SET ROLE ems_owner;

CREATE TABLE IF NOT EXISTS mart.dim_disposition (
    disposition_key                 BIGSERIAL PRIMARY KEY,
    label_raw                       TEXT NOT NULL UNIQUE,
    slug                            TEXT NOT NULL,
    category                        CHECK (category IN ('transport', 'no_transpot', 'canceled', 'standby', 'transfer', 'other')),
    is_tranport_expected            BOOLEAN NOT NULL DEFAULT FALSE,
    is_patient_encounter            BOOLEAN NOT NULL DEFAULT FALSE,
    is_canceled                     BOOLEAN NOT NULL DEFAULT FALSE,
    notes                           TEXT
);

INSERT INTO mart.dim_disposition (label_raw, slug, category)
VALUES ('_UNK', 'unknown', 'other')
ON CONFLICT (label_raw) DO NOTHING;





RESET ROLE;