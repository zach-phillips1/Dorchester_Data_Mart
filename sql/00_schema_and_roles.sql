-- **Create Roles**
-- Group Roles
CREATE ROLE ems_admin WITH NOLOGIN;
CREATE ROLE ems_owner WITH NOLOGIN;
CREATE ROLE etl_writer WITH NOLOGIN;
CREATE ROLE bi_reader WITH NOLOGIN;

-- User Roles
CREATE USER zach WITH LOGIN INHERIT;
GRANT etl_writer TO zach;
CREATE USER bi_tool WITH NOLOGIN;
GRANT bi_reader TO bi_tool;

-- **Create Schemas**
CREATE SCHEMA IF NOT EXISTS etl;
ALTER SCHEMA etl OWNER TO ems_owner;
CREATE SCHEMA IF NOT EXISTS stage;
ALTER SCHEMA stage OWNER TO ems_owner;
CREATE SCHEMA IF NOT EXISTS mart;
ALTER SCHEMA mart OWNER TO ems_owner;