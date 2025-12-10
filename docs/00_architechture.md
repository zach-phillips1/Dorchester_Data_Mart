# EMS QA/QI Data Warehouse – Architecture Overview
Dorchester EMS Data Mart — Updated Architecture Document (2025)

---

## Purpose

The Dorchester EMS Data Mart provides a **transparent, reproducible, auditable** analytics warehouse for EMS Quality Assurance (QA) and Quality Improvement (QI).

Because Maryland EMS agencies use the **state-hosted ImageTrend eMeds system** and do not have access to the ImageTrend Data Mart, this project recreates that capability locally using:

- Structured PostgreSQL schemas  
- Deterministic SQL-based ETL  
- Typed staging tables aligned to ImageTrend Report Writer exports  
- A curated star-schema analytics layer  

The warehouse supports:

- NEMSQA clinical measures  
- AHA Mission Lifeline metrics  
- Trauma, cardiac, stroke, and CQI analytics  
- Longitudinal QA monitoring  
- Dashboarding in Power BI, R/Shiny, or Python  

---

## High‑Level Architecture

The system runs on **PostgreSQL 18.x**, hosted on a secure Linux VM (homelab environment), with the option to migrate into county-managed infrastructure later.

### Schema Overview

### 1. `land_raw`  
Reserved for future ingestion pipelines.  
Currently **unused**, but intended for raw untyped CSV storage if automated workflows are implemented.

### 2. `stage`  
Active staging layer where CSV exports are imported.

- Mirrors the column structure of ImageTrend Report Writer CSVs  
- Fully typed tables  
- Duplicates allowed  
- Minimal transformations (NULL cleanup, type enforcement)  
- Cleared (`TRUNCATE`) before new imports  

Tables include:

- `incidents_stg`
- `situation_stg`
- `vitals_stg`
- `procedures_stg`
- `medications_stg`

### 3. `mart`  
The core analytics warehouse implementing a **star schema**.

Dimensions:

- `dim_unit`
- `dim_destination`
- `dim_disposition`
- `dim_vital_type`
- `dim_medication`
- `dim_procedure`

Facts:

- `fact_incident`
- `fact_situation`
- `fact_vital`
- `fact_procedure`
- `fact_medication`

All tables use surrogate keys and normalized lookup structures.

### 4. `etl`  
Operational schema for:

- Upsert logic  
- Incremental merge rules  
- QA helper queries  
- Future audit logs and load status tables  

### 5. `qa`  
Reserved for future QA dashboards and materialized views.

### 6. `public`  
Not used for warehouse objects.

---

## Data Flow

### Extract  
Source data comes from **ImageTrend eMeds Report Writer CSV exports**.  
Supported range modes include:

- Arbitrary date ranges (e.g., full year)
- Relative windows: “yesterday”, “last week”  
- **Limitation:** cannot express ranges like “between 2 and 5 days ago.”

### Load (CSV → stage)

- CSVs imported using `\copy` or GUI tools like DBeaver.
- Column names must match stage table definitions exactly.
- No PHI cleaning is performed here; PHI remains only in `stage` (if present).

### Transform (stage → mart)

ETL scripts perform:

- Surrogate key lookup for all dimensions  
- Deduplication  
- Enforcement of required fields  
- Normalization of enumerations  
- Unpivoting of vitals from wide to long format  
- Linking of facts to dimensions  
- **Incremental merge using `last_modified` (“newer wins”)**  

### Promote (mart)

Facts and dimensions are inserted or updated in a deterministic order:

1. `dim_unit`
2. `dim_destination`
3. `dim_disposition`
4. `dim_vital_type`
5. `dim_procedure`
5. `dim_medication`
7. `fact_incident`
8. `fact_situation`
9. `fact_vital`
10. `fact_procedure`
11. `fact_medication`

---

## Timestamp Policy

The warehouse intentionally uses:

- **TIMESTAMP WITHOUT TIME ZONE**  
- All timestamps interpreted in **local civil time (America/New_York)**  
- No UTC conversion  
- Chronology comparisons performed in local time  

This approach aligns with EMS operational documentation and avoids confusion created by system-level timezone handling.

---

## Security & Access

- Database access restricted to localhost or SSH tunnels.
- R/RStudio access uses environment variables set via `.Renviron`, not hard-coded credentials.
- Roles:
  - `etl_writer` — permission to load and transform data  
  - `bi_reader` — read-only access for analytics  

### PHI Handling

- `mart` schema contains **no PHI**:
  - No patient names  
  - No MRNs  
  - DOB fields excluded or truncated  

- `stage` may contain PHI if present in CSVs; PHI does **not** propagate into `mart`.

---

## Benefits

- **Reproducibility** through SQL-only, version-controlled ETL
- **Auditability** via clear upsert logic and future load logs
- **Scalability** — can expand to more fact tables or new data sources
- **Portability** — other EMS agencies can adopt the framework
- **Operational alignment** with NEMSIS 3.5 and ImageTrend’s Maryland configuration

---

## Future Development

### High Priority

- Automated nightly ETL  
- QA dashboards via `qa` schema  
- Additional NEMSQA measures:
  - TRAUMA‑02  
  - PAIN‑01 / PAIN‑02  
  - Cardiac arrest bundles  

### Medium Priority

- Additional facts/dimensions:
  - Crew  
  - Airway  
  - Response  
  - Injury detail  
  - History  

- Power BI or Shiny integration  
- Documentation of all measures in `/docs/`

### Long Term

- Migration into county-managed PostgreSQL infrastructure  
- Stable scheduled job execution (cron, systemd, Windows Task Scheduler)
- Advanced trend analysis: shift-based, unit-based, clinician-based analytics  

---

## Summary

The Dorchester EMS Data Mart provides a **robust, extensible foundation** for EMS QA/QI analytics.  
It transforms fragmented ImageTrend CSV exports into a coherent analytics warehouse capable of supporting operational decisions, clinical measures, and statewide reporting requirements.

