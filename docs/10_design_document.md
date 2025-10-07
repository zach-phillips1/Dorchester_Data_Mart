# Project Overview
This project builds a **PostgreSQL 15 data mart** from **ImageTrend eMeds Report Writer CSV exports** to support Quality Assurance (QA), Quality Improvement (QI), and benchmarking for **Dorchester County EMS**.

Because Maryland’s statewide ImageTrend contract does not include licensing for the proprietary STAR Data Mart, Dorchester EMS is developing an **independent, open, auditable warehouse** that replicates that functionality locally while maintaining HIPAA compliance and traceability.  

The data mart provides a structured, relational foundation for analysis in **Power BI**, **Excel**, and future advanced analytics environments (e.g., Python, R, Izenda).

---

# Scope & Sources
- **Primary Source:** ImageTrend eMeds Report Writer CSV exports  
- **Schema Alignment:** NEMSIS v3.5 whenever possible  
- **Scope:** Structured data fields (numeric, coded, or timestamped).  
  - Narrative or free-text fields are **out of scope** for ingestion but may be considered in future NLP phases.
- **File Types:** Incident lists, vitals, procedures, medications, and operational reports.  
- **Update Frequency:** Daily exports (manual import now, automated later).

---

# Data Governance
- **Roles:**
  - `ems_owner` – owns all schema objects (DDL only)
  - `etl_writer` – loads and manages data (ETL DML)
  - `bi_reader` – read-only access for analytics
- **PHI Handling:**
  - PHI is minimized in `mart`; no names, MRNs, or full DOBs are stored.
  - Keys (e.g., `pcr_number`) are retained for joining back to secure ePCR systems if required.
- **Compliance:**
  - Access is restricted to authorized QA/QI and administrative personnel.
  - Architecture follows the HIPAA **minimum necessary** principle.
  - All PHI-carrying files (CSVs) are excluded from version control via `.gitignore`.

---

# Architecture
The warehouse runs on **PostgreSQL 15**, hosted on a secure Linux environment (currently in a controlled homelab prototype, with planned migration to County IT).  

Data flows through **four schemas**, representing distinct processing stages:

## 1. `land_raw`
- **Status:** Reserved for future automation (not yet used).  
- **Purpose:** Immutable landing zone for unaltered CSVs before transformation.  
- **Retention:** Short-term (30–60 days) for traceability and audit.

## 2. `stage`
- **Purpose:** Typed, lightly cleaned staging zone.  
- **Behavior:** Duplicates allowed, nullable fields permitted.  
- **Content:** Typed representations of Report Writer exports with standardized timestamps and nullable handling.  
- **Retention:** Temporary until promotion to `mart`.  

**Example tables:**
- `stage.incidents_stg`
- `stage.vitals_stg`

## 3. `mart`
- **Purpose:** Star-schema warehouse for analytics and QA/QI dashboards.  
- **Content:**
  - **Dimensions** (`dim_unit`, `dim_destination`, `dim_disposition`, `dim_vital_type`)  
  - **Facts** (`fact_incident`, `fact_vital`)  
- **Behavior:**
  - Incremental, “newer wins” logic via `last_modified`
  - Referential integrity enforced through surrogate keys  
  - Rich column-level comments for internal documentation  
- **Retention:** Long-term analytical store.

## 4. `etl`
- **Purpose:** Operational metadata, QA checks, and future audit logging.  
- **Content:**  
  - Validation views (e.g., chronology checks, missing documentation)  
  - Incremental load statistics and row counts  
  - QA/QI measure views (e.g., NEMSQA Trauma-01)

---

# Entities
## Facts
| Table | Description | Grain |
|--------|--------------|-------|
| `fact_incident` | One record per PCR (incident). | Per incident |
| `fact_vital` | One record per vital measurement (unpivoted). | Per vital sign |

## Dimensions
| Table | Description |
|--------|--------------|
| `dim_unit` | Normalized unit identifiers (ALS/BLS). |
| `dim_destination` | Receiving hospitals or facilities. |
| `dim_disposition` | Mapped transport and non-transport dispositions. |
| `dim_vital_type` | Normalized vital categories (pain score, GCS, etc.). |

*Future planned:* `dim_provider`, `dim_procedure`, `dim_medication`, `dim_location`.

---

# Keys and Rules
- **Natural Key:** `pcr_number` (unique EMS incident number from eMeds)
- **Surrogate Keys:** Used for all dimensions (`*_key` fields)
- **Incremental Load Rule:**  
  - Rows are compared by `pcr_number` and updated if the incoming record’s `last_modified` is newer.
  - “Newer wins” logic is enforced at the fact level.
- **Timestamp Policy:**  
All timestamps stored as `TIMESTAMP WITHOUT TIME ZONE` in local time (`America/New_York`).

---

# Business Rules
- Each PCR corresponds to exactly **one `fact_incident`** row.
- Each fact record (`vital`, `procedure`, `medication`) must reference a valid PCR.
- All `mart` tables must maintain referential integrity to their dimension keys.
- QA/QI business logic (e.g., NEMSQA Trauma-01, AHA EMS measures) is applied in downstream views.
- Missing or invalid chronology values are flagged in `etl` QA views.

---

# ETL Workflow
1. **CSV ingestion:**  
 Daily reports exported from ImageTrend → imported into `stage.*` tables.

2. **Dimension promotion:**  
 Run `etl/31–36_upsert_dim_*.sql` to normalize and update dimension tables.

3. **Fact promotion:**  
 - `etl/34_upsert_fact_incident.sql` → builds `mart.fact_incident`  
 - `etl/42_upsert_fact_vital.sql` → unpivots vitals, parses GCS strings, deduplicates, and upserts.

4. **Validation:**  
 - QA views detect duplicates, NULLs, or chronology violations.  
 - Manual or automated reports summarize ETL run results.

5. **Future steps:**  
 - Add ETL logs, automated import from scheduled reports, and Power BI refresh pipeline.

---

# QA & Validation Logic
Implemented and planned checks include:
| QA View | Purpose |
|----------|----------|
| `etl.vw_chronology_violations` | Detect timeline inconsistencies |
| `etl.vw_missing_pain_scores` | NEMSQA Trauma-01 compliance |
| `etl.vw_duplicate_vitals` | Identify duplicate vital sign entries |
| `etl.vw_disposition_conflicts` | Detect mismatched transport/destination |

---

# Security & Access
- **Roles:**
- `etl_writer` – may load data but not alter schema
- `bi_reader` – read-only for analytics
- **Privileges:**  
- `SELECT` only on `mart` for `bi_reader`
- `INSERT`/`UPDATE` on `stage` and `mart` for `etl_writer`
- **PHI Control:**  
- PHI is stripped before mart promotion
- CSVs containing PHI never committed to Git
- Database backups encrypted at rest

---

# Operations
- **Current:** Manual CSV imports via DBeaver or `\copy`.  
- **Planned:**  
- Automated scheduled exports from eMeds  
- Scripted ETL execution (bash or Python)  
- Email notifications or QA flag reports after each run  
- **Retention:** Stage cleared after successful load; mart retained indefinitely.

---

# Change Management
- All schema changes are versioned under `sql/`.  
- ETL logic changes live in `etl/` with idempotent scripts (`CREATE IF NOT EXISTS`, `ALTER IF NOT EXISTS`).  
- Schema documentation auto-updated via `COMMENT ON` statements.  
- Changelog maintained in root (`CHANGELOG.md`) for milestone tracking.

---

# Data Dictionary
Metadata is maintained within PostgreSQL and exported periodically to Markdown:

| Attribute | Description |
|------------|--------------|
| Column Name | Database column name |
| Type | PostgreSQL data type |
| Nullable | Y/N |
| Key | Primary or foreign key designation |
| NEMSIS Mapping | Relevant NEMSIS v3.5 element |
| Description | Plain-English meaning |
| QA Logic | Associated checks or constraints |

Export automation (future):
```bash
psql -d ems_mart -c "\d+ mart.fact_vital" > docs/20_data_dictionary/fact_vital.md
```

# Summary

The Dorchester EMS Data Mart is a modular, open, and standards-aligned analytics platform built from ImageTrend eMeds exports.
Its purpose is to provide transparency, improve patient outcomes through data-driven QA/QI, and establish a foundation for county-wide EMS performance reporting without reliance on proprietary systems.