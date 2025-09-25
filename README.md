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
  - `land_raw` – landing zone (reserved, not used yet)  
  - `stage` – typed staging (permissive; duplicates allowed)  
  - `mart` – star schema (facts & dimensions)  
  - `etl` – QA views, logs, audit (in progress)  
- **Stage built:** `stage.incidents_stg`  
- **Dimensions built:** `dim_unit`, `dim_destination`, `dim_disposition`  
- **Facts:** none yet (next step: `fact_incident`)  
- **Natural key:** `pcr_number`  
- **Incremental rule:** “newer wins” via `last_modified`  
- **Chronology rule:** `notified ≤ enroute ≤ at_scene ≤ depart_scene ≤ at_dest ≤ back_in_service`

---

## Architecture
- CSV exports from ImageTrend Report Writer are imported into `stage`.  
- Promotion scripts normalize units/destinations/dispositions and upsert into `mart` dimensions.  
- Facts will reference dimension surrogate keys; first fact to be built is `mart.fact_incident`.  
- `etl` schema will store QA checks (e.g., chronology violations, disposition contradictions).  
- Designed for SSH-tunneled access during prototyping; later migratable to county IT.

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
  00_schema_and_roles.sql
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
```bash
# Local bind 127.0.0.1:6543 → remote 127.0.0.1:5432
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
\i sql/00_schema_and_roles.sql
```
This creates:
- Schemas: `etl`, `land_raw`, `stage`, `mart`
- Roles (example): `etl_writer` (load/manage), `bi_reader` (read-only)

---

## Create Tables
Create staging and dimensions:
```sql
\i sql/10_stage_table_creation.sql
\i sql/21_mart_dim_unit_table_creation.sql
\i sql/22_mart_dim_dest_table_creation.sql
\i sql/23_mart_dim_disposition_table_creation.sql
```

> `fact_incident` table not yet created — this is the next milestone.

---

## Load Stage (CSV → stage)
Choose either DBeaver GUI import or `\copy`.

### Option A: DBeaver (GUI)
- Right-click the target stage table (e.g., `stage.incidents_stg`) → **Import Data**.
- Source: your CSV export.
- Options: Header checked, delimiter comma, quote `"`, empty string → NULL.
- Map columns by name → Finish.

### Option B: psql `\copy`
```sql
\copy stage.incidents_stg FROM '/path/to/IncidentExport.csv'
  WITH (FORMAT csv, HEADER true, NULL '', DELIMITER ',', ENCODING 'UTF8');
```

---

## Promote to Mart (stage → mart)

### Dimension upserts (already working)
Run in order:
```sql
\i etl/31_upsert_dim_unit.sql
\i etl/32_upsert_dim_destination.sql
\i etl/33_upsert_dim_disposition.sql
```

### Fact upsert (next milestone)
`mart.fact_incident` will be created and populated with:
- All key timestamps  
- FKs to unit, destination, transport disposition, and unit disposition  
- Derived fields such as `transport_outcome`  
- “newer wins” logic on `last_modified`  

---

## Time Handling Policy
- All timestamps stored as **local civil time (America/New_York)**.  
- Columns are `TIMESTAMP WITHOUT TIME ZONE`.  
- No UTC conversion in ETL.  
- Chronology and incremental comparisons occur in local time.  

---

## Validation & QA Checks
Initial QA checks will live in `etl` as views. Planned checks include:
- Chronology violations (times out of order)  
- Transport with missing destination / destination with non-transport disposition  
- Contradictions (e.g., “No Patient Contact” but contact time present)  
- “Other” dispositions for curation  

Row counts, duplicate detection, and incremental logic are already validated during dimension upserts.

---

## Security & PHI
- `mart` excludes direct PHI (no names, full DOB, MRNs).  
- Access via roles:  
  - `etl_writer` – load/manage ETL  
  - `bi_reader` – read-only reporting  
- CSVs and credentials must remain outside Git (`.gitignore` covers them).

---

## Data Dictionary
- Column/table comments maintained in SQL via `COMMENT ON`.  
- Future script will export comments into Markdown under `docs/`.  

---

## Troubleshooting
- **Can’t connect?** Verify SSH tunnel (Termius or `autossh`).  
- **Local port in use (6543)?** Stop prior tunnels or change port.  
- **CSV import errors?** Check headers match stage columns; empty string → NULL.  
- **Missing fact rows?** Fact upsert not yet implemented (next milestone).  

---

## Contributing
- Use feature branches, small commits, and meaningful messages.  
- Update `docs/` when schema changes.  
- Add validation queries to `etl` QA views.  

---

## License
See `LICENSE`.
