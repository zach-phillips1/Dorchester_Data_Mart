# Dorchester EMS Data Mart

PostgreSQL 15 star-schema data mart for EMS QA/QI. Sources are **ImageTrend eMeds Report Writer CSV exports** (NEMSIS v3.5 aligned). The goal is an auditable, reproducible warehouse for analytics and future Power BI dashboards.

## Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Repo Structure](#repo-structure)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Create Schemas & Roles](#create-schemas--roles)
- [Create Tables](#create-tables)
- [Load Stage (CSV → stage)](#load-stage-csv--stage)
- [Promote to Mart (stage → mart)](#promote-to-mart-stage--mart)
- [Time Handling Policy](#time-handling-policy)
- [Validation & QA Checks](#validation--qa-checks)
- [Security & PHI](#security--phi)
- [Data Dictionary](#data-dictionary)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Overview
- **DBMS:** PostgreSQL 15  
- **Schemas:**  
  - `land_raw` – landing zone (reserved, not utilized yet)
  - `stage` – lightly cleaned/typed staging tables  
  - `mart` – star schema (facts & dimensions)  
  - `etl` – logs, audit, config  
- **Facts:** None yet.  
- **Dimensions:** `dim_unit`, `dim_destination`, `dim_disposition`
- **Natural key:** `pcr_number`  
- **Incremental rule:** “newer wins” via `last_modified`  
- **Chronology rule:** `notified ≤ enroute ≤ at_scene ≤ depart_scene ≤ at_dest ≤ back_in_service`

---

## Architecture
- CSV exports from ImageTrend Report Writer are imported into `stage`.
- Promotion scripts dedupe by `pcr_number` (latest `last_modified`) and upsert into `mart`.
- `etl` schema stores load logs and (future) QA results.
- Designed for SSH tunneled access during prototyping; later migratable to county IT.

---

## Repo Structure
```
docs/
  00_architechture.md
  10_design_document.md
etl/
  31_upsert_dim_unit.sql
  32_upsert_dim_destination.sql
  33_upsert_dim_disposition.sql
sql/
  00_schemas_and_roles.sql
  10_stage_table_creation.sql
  21_mart_dim_unit_table_creation.sql
  22_mart_dim_dest_table_creation.sql
  23_mart_dim_disposition_table_creation.sql
.gitignore
LICENSE
README.md
```

---

## Prerequisites
- **PostgreSQL 15** reachable locally or via SSH tunnel.
- A SQL client (DBeaver, psql).
- **CSV exports** from eMeds Report Writer.
- Optional: Termius or `autossh` for a stable tunnel.

**Example tunnel (Termius or CLI):**
- Local bind: `127.0.0.1:6543` → remote `127.0.0.1:5432`
- psql:  
  ```bash
  psql "host=127.0.0.1 port=6543 dbname=ems_mart user=<your_user>"
  ```

---

## Setup
1. **Clone the repo**
   ```bash
   git clone <your_repo_url>
   cd DORCHESTER_DATA_MART
   ```

2. **(Optional) Create a dedicated database**
   ```sql
   CREATE DATABASE ems_mart;
   ```

3. **Connect to the database** with your client.

---

## Create Schemas & Roles
Run:
```sql
\i sql/00_schemas_and_roles.sql
```
This creates:
- Schemas: `etl`, `land_raw`, `stage`, `mart`
- Roles (example): `etl_writer` (load/manage), `bi_reader` (read-only)

> Adjust grants/users as needed for your environment.

---

## Create Tables
Create dimensions and facts:
```sql
\i etl/sql/10_dim_tables.sql
\i etl/sql/20_fact_tables.sql
```

Create staging tables:
```sql
\i etl/sql/30_stage_tables.sql
```

> Tables are designed to keep **local times** (see policy below).

---

## Load Stage (CSV → stage)
Choose either DBeaver GUI import or `\copy`.

### Option A: DBeaver (GUI)
- Right-click the target stage table (e.g., `stage.incidents_stg`) → **Import Data**.
- Source: your CSV export.
- Options: Header checked, delimiter comma, quote `"`, empty string → NULL.
- Map columns by name → Finish.

### Option B: psql `\copy` (client-side CSV)
```sql
\copy stage.incidents_stg (
  pcr_number,
  incident_number,
  unit_code,
  disposition_code,
  disposition_label,
  destination_name,
  miles_transport,
  primary_impression_code,
  primary_impression_label,
  call_created,
  notified,
  enroute,
  at_scene,
  depart_scene,
  at_dest,
  back_in_service,
  last_modified
) FROM '/path/to/IncidentExport.csv'
  WITH (FORMAT csv, HEADER true, NULL '', DELIMITER ',', ENCODING 'UTF8');
```

---

## Promote to Mart (stage → mart)
Run the upsert script (dedupe + newer-wins):
```sql
\i etl/sql/40_upsert_incidents.sql
```
This:
- Partitions `stage.incidents_stg` by `pcr_number`,
- keeps the row with the greatest `last_modified`,
- upserts into `mart.fact_incident`,
- updates only if incoming `last_modified` is newer.

> Add analogous upserts later for vitals/meds/procs (e.g., `41_upsert_vitals.sql`, etc.).

---

## Time Handling Policy
**All timestamps are stored exactly as exported by Report Writer (local civil time, `America/New_York`).**
- Columns are `TIMESTAMP WITHOUT TIME ZONE`.
- No UTC conversion is performed in ETL.
- Chronology and incremental comparisons occur in local time.
- Downstream tools (e.g., Power BI) should **not** apply extra TZ conversions.

**DST tie-breakers:** if within the “fall back” repeated hour two records share the same `last_modified`, break ties deterministically (e.g., file arrival order + `row_number()` stored in `etl.load_log`).

---

## Validation & QA Checks
Open `etl/test.sql` and run the included queries. Common checks:

**Row counts (stage vs mart)**
```sql
SELECT 'stage.incidents_stg' AS tbl, COUNT(*) FROM stage.incidents_stg
UNION ALL
SELECT 'mart.fact_incident', COUNT(*) FROM mart.fact_incident;
```

**Duplicate PCRs in stage**
```sql
SELECT pcr_number, COUNT(*) AS dup_cnt
FROM stage.incidents_stg
GROUP BY pcr_number
HAVING COUNT(*) > 1;
```

**Newer-wins consistency**
```sql
WITH s AS (SELECT pcr_number, MAX(last_modified) AS s_max
           FROM stage.incidents_stg GROUP BY pcr_number)
SELECT m.pcr_number, s.s_max, m.last_modified
FROM mart.fact_incident m
JOIN s USING (pcr_number)
WHERE m.last_modified <> s.s_max;
```

**Chronology rule (local time)**
```sql
SELECT pcr_number
FROM mart.fact_incident
WHERE (enroute < notified)
   OR (at_scene < enroute)
   OR (depart_scene < at_scene)
   OR (at_dest < depart_scene)
   OR (back_in_service < at_dest)
LIMIT 100;
```

**Orphans (example)**
```sql
SELECT v.pcr_number, COUNT(*) AS cnt
FROM mart.fact_vital v
LEFT JOIN mart.fact_incident i USING (pcr_number)
WHERE i.pcr_number IS NULL
GROUP BY v.pcr_number
ORDER BY cnt DESC
LIMIT 50;
```

---

## Security & PHI
- `mart` excludes direct PHI (no names, full DOB, MRNs).
- Access via roles:
  - `etl_writer` – load/manage ETL
  - `bi_reader` – read-only reporting
- Keep CSVs and credentials **out of Git** (`.gitignore`).

---

## Data Dictionary
- Column/table comments maintained in SQL (`COMMENT ON ...`).
- A future Python script will export comments to Markdown in `docs/20-data-dictionary/` with: column name, type, nullable, keys, NEMSIS mapping, description, and QA checks.

---

## Troubleshooting
- **Can’t connect?** Verify SSH tunnel (Termius: auto-reconnect + keep-alive; or `autossh`).
- **Local port in use (6543)?** Stop any prior tunnels or change the local port.
- **CSV import errors?** Check header names/types; ensure empty string → NULL; verify quotes.
- **Zero rows in mart?** Confirm you ran the upsert script and that `last_modified` is populated.
- **Chronology false positives?** Confirm all times are local and of the expected format.

---

## Contributing
- Use feature branches, small commits, and meaningful messages.
- Add tests/queries to `etl/test.sql` when you introduce new tables or ETL steps.
- Keep docs in `docs/` synchronized with schema changes.

---

## License
See `LICENSE`.


