-- incident
SELECT 'stage.incidents_stg' AS tbl, COUNT(*) FROM stage.incidents_stg
UNION ALL
SELECT 'mart.fact_incident', COUNT(*) FROM mart.fact_incident;

