SELECT current_user AS effective_role, session_user AS login_role;
SELECT nspname, relname, pg_get_userbyid(relowner)
FROM pg_class JOIN pg_namespace ON (relnamespace=pg_namespace.oid)
WHERE nspname='stage' AND relname='incidents_stg';

SELECT a.attname AS un_comment_col
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_description d ON d.objoid = a.attrelid AND d.objsubid = a.attnum
WHERE n.nspname = 'stage'
  AND c.relname = 'incidents_stg'
  AND a.attnum > 0 AND NOT a.attisdropped
  AND d.description IS NULL;
