BEGIN;

WITH src AS (
    SELECT DISTINCT
        UPPER(BTRIM(destination_code)) AS code,
        NULLIF(BTRIM(destination_name), '') AS name
    FROM stage.incidents_stg
    WHERE destination_code IS NOT NULL
),
pick AS (
    SELECT code, MAX(name) as name
    FROM src
    GROUP BY code
)
INSERT INTO mart.dim_destination (destination_code, destination_name)
SELECT code, name
FROM pick
ON CONFLICT (destination_code) DO UPDATE
SET destination_name = COALESCE(EXCLUDED.destination_name, 
                                mart.dim_destination.destination_name);

COMMIT;