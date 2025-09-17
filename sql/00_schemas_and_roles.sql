-- Schemas
CREATE SCHEMA IF NOT EXISTS land_raw;
CREATE SCHEMA IF NOT EXISTS stage;
CREATE SCHEMA IF NOT EXISTS mart;
CREATE SCHEMA IF NOT EXISTS etl;

-- Roles
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'etl_writer') THEN
        CREATE ROLE etl_writer LOGIN PASSWORD 'dorchester_etl_writer!';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bi_reader') THEN
        CREATE ROLE bi_reader LOGIN PASSWORD 'dorchester_bi_reader!';
    END IF;
END $$;

GRANT CONNECT ON DATABASE ems_mart TO etl_writer, bi_reader;

-- Ownership + permissions
ALTER SCHEMA land_raw OWNER TO etl_writer;
ALTER SCHEMA stage OWNER TO etl_writer;
ALTER SCHEMA mart OWNER TO etl_writer;
ALTER SCHEMA etl OWNER TO etl_writer;

GRANT USAGE ON SCHEMA mart TO bi_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA mart TO bi_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA mart GRANT SELECT ON TABLES TO bi_reader;