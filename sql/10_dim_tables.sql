CREATE TABLE IF NOT EXISTS mart.dim_date (
    date_key    INT PRIMARY KEY,
    date        DATE NOT NULL,
    year        INT NOT NULL,
    month       INT NOT NULL,
    day         INT NOT NULL,
    day_of_week INT NOT NULL,
    is_weekend  BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS mart.dim_unit (
    unit_key        BIGSERIAL PRIMARY KEY,
    unit_code       TEXT UNIQUE NOT NULL,
    level_label     TEXT,
    base_name       TEXT,
    active_from TIMESTAMP WITHOUT TIME ZONE,
    active_to   TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE IF NOT EXISTS mart.dim_destination (
    dest_key        BIGSERIAL PRIMARY KEY,
    dest_name       TEXT UNIQUE,
    service_type    TEXT,
    notes           TEXT
);

CREATE TABLE IF NOT EXISTS mart.dim_disposition (
    disp_key        BIGSERIAL PRIMARY KEY,
    disp_code       TEXT UNIQUE,
    disp_label      TEXT
);

CREATE TABLE IF NOT EXISTS mart.dim_medication (
    med_key         BIGSERIAL PRIMARY KEY,
    med_code        TEXT,
    med_label       TEXT,
    class_label     TEXT
);

CREATE TABLE IF NOT EXISTS mart.dim_procedure (
    proc_key        BIGSERIAL PRIMARY KEY,
    proc_code       TEXT,
    proc_label      TEXT,
    category_label  TEXT
);

CREATE TABLE IF NOT EXISTS mart.dim_provider (
    provider_key    BIGSERIAL PRIMARY KEY,
    provider_hash   TEXT UNIQUE,
    role_label      TEXT,
    cert_level      TEXT
);

CREATE TABLE IF NOT EXISTS mart.dim_location (
    location_key    BIGSERIAL PRIMARY KEY,
    zip_code        TEXT,
    county_name     TEXT,
    zone_label      TEXT,
    latitude        DOUBLE PRECISION,
    longitude       DOUBLE PRECISION,
    census_tract    TEXT
);