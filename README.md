# Dorchester EMS Data Mart

PostgreSQL 15 **star-schema data mart** for EMS QA/QI analytics.  
Primary data sources are **ImageTrend eMeds Report Writer CSV exports** (NEMSIS v3.5 aligned).  
The project’s goal is an **auditable, reproducible warehouse** for clinical quality tracking and future **Power BI dashboards**.

---

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
**Database:** `ems_mart`  
**DBMS:** PostgreSQL 15  
**Schemas:**
- `land_raw` – reserved landing zone (for future untyped imports)
- `stage` – typed staging tables; duplicates allowed; permissive
- `mart` – curated star schema for analytics (facts + dimensions)
- `etl` – QA checks, logs, audit procedures, and helper views

**Current Data Flow**
- ✅ *Stage built:* `stage.incidents_stg`, `stage.vitals_stg`  
- ✅ *Dimensions:* `dim_unit`, `dim_destination`, `dim_disposition`, `dim_vital_type`  
- ✅ *Facts:* `fact_incident`, `fact_vital`  
- ✅ *ETL scripts:* `31–42_upsert_*.sql`  
- ✅ *Incremental rule:* “newer wins” via `last_modified`  


---

## Architecture
1. **Source ingestion:**  
 CSV exports from ImageTrend eMeds Report Writer are imported into the `stage` schema.

2. **Promotion and normalization:**  
 ETL scripts (`etl/*.sql`) normalize core domains such as units, destinations, and dispositions, inserting them into corresponding `mart.dim_*` tables.

3. **Fact construction:**  
 - `fact_incident` — one row per PCR (incident-level record).  
 - `fact_vital` — one row per vital measurement (unpivoted from wide format).  

4. **Data QA & validation:**  
 The `etl` schema contains (or will contain) validation and anomaly views:
 - Chronology checks  
 - Missing required values (e.g., NEMSQA Trauma-01 pain scale)  
 - Contradictions (e.g., no patient contact but vitals exist)

5. **Design goals:**
 - Role-based control for secure PHI handling  
 - Incremental, re-runnable ETL  
 - Power BI–ready data model  

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
  34_upsert_fact_incident.sql
  36_upsert_dim_vital_type.sql
  37_upsert_fact_vital.sql
  42_upsert_fact_vital.sql
sql/
  00_schema_and_roles.sql
  10_stage_incidents_table_creation.sql
  11_stage_vitals_table_creation.sql
  21_mart_dim_unit_table_creation.sql
  22_mart_dim_destination_table_creation.sql
  23_mart_dim_disposition_table_creation.sql
  24_mart_fact_incident_table_creation.sql
  25_mart_dim_vital_type_table_creation.sql
  26_mart_fact_vital_table_creation.sql
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
   git clone https://github.com/zach-phillips1/Dorchester_Data_Mart.git
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
\i sql/10_stage_incidents_table_creation.sql
\i sql/11_stage_vitals_table_creation.sql
\i sql/21_mart_dim_unit_table_creation.sql
\i sql/22_mart_dim_destination_table_creation.sql
\i sql/23_mart_dim_disposition_table_creation.sql
\i sql/24_mart_fact_incident_table_creation.sql
\i sql/25_mart_dim_vital_type_table_creation.sql
\i sql/26_mart_fact_vital_table_creation.sql
```
Each table is idempotent and includes COMMENT ON statements for data dictionary export.

---

## Load Stage (CSV → stage)
Choose either DBeaver GUI import or `\copy`.

### Option A: Option A: DBeaver (GUI)
- Right-click → Import Data
- Source: Report Writer CSV
- Options: Header checked, delimiter ,, empty strings → NULL
- Map by name → Finish

### Option B: psql `\copy`
```sql
\copy stage.incidents_stg FROM '/path/to/incidents.csv'
  WITH (FORMAT csv, HEADER true, NULL '', DELIMITER ',', ENCODING 'UTF8');

\copy stage.vitals_stg FROM '/path/to/vitals.csv'
  WITH (FORMAT csv, HEADER true, NULL '', DELIMITER ',', ENCODING 'UTF8');

```

## Promote to Mart (stage → mart)

### Dimension upserts (already working)
Run in order:
```sql
\i etl/31_upsert_dim_unit.sql
\i etl/32_upsert_dim_destination.sql
\i etl/33_upsert_dim_disposition.sql
\i etl/36_upsert_dim_vital_type.sql
```

### Fact upsert (next milestone)
```sql
\i etl/34_upsert_fact_incident.sql
\i etl/42_upsert_fact_vital.sql
```
The vitals upsert performs:
- Inline parsing of GCS component text (1–4 / 1–5 / 1–6)
- Unpivot of wide columns into atomic rows
- Deduplication (ROW_NUMBER by PCR + type + time)
- Conflict handling with “newer wins” update logic
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
- Planned export process:
```sql
psql -d ems_mart -c "\d+ mart.fact_vital" > docs/data_dictionary.md
```
- Future automation will extract all momments into Mardown for versioning.

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
