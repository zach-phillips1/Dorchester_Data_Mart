# Project Overview
- This project creates a structured PostgreSQL database from eMeds Report Writer CSV exports to support ongoing Quality Management (QM) and benchmarking for Dorchester EMS. Because the Statewide ImageTrend contract does not include licensing for Data Mart, Dorchester EMS cannot access ImageTrend’s proprietary STAR-schema Data Mart service. This project replicates that functionality locally to ensure reliable analytics.
---
# Scope & Sources
- Sourced from eMeds Report Writer which allows for CSV export and import into database.
- NEMSIS v3.5 alignment when possible.
- Scope is limited to structured data fields; narrative text and free-text fields are not currently ingested.

---
# Data Governance
- Roles: `etl_writer` (load and manage), `bi_reader` (read-only)
- PHI Handling: PHI minimized in `mart`; excluded fields documented.
- Compliance: Access limited to authorized QM staff; aligns with HIPAA minimum-necessary standard.
---

# Architecture
The warehouse is built on **PostgreSQL 15**, hosted on a secure Linux server (currently in a controlled homelab for prototyping, with the option to migrate to county IT infrastructure).

Data is structured into **four zones**:

1. **`land_raw`**
    
    - **`land_raw` is being reserved for furture automation; current loads go directly to `stage`.**
    - Purpose: Immutable landing zone for incoming CSV files.
    - Content: Normalized data types, standardized timestamps, cleaned nulls.
    - Retention: Short-term (30-60 days), for traceability.
2. **`stage`**
    
    - Purpose: Typed and lightly cleaned staging tables.
    - Content: Normalized data types, standardized timestamps, cleaned nulls.
    - Retention: Short-term (until data is successfully promoted).
3. **`mart`**
    
    - Purpose: Star-schema warehouse for analytics
    - Content:
        - **Dimensions** (units, destination, disposition, providers, etc)
        - **Facts** (incidents, vitals, mediations, procedures)
    - Retention: Long-term, supports QA/QI dashboards and reporting
4. **`etl`**
    
    - Purpose: Operational metadata.
    - Content: Load logs, QA checks, and ETL audit trail.
---

# Entities
- fact_incident
- fact_vital
- fact_medication
- fact_procedure
- dim_unit
- dim_destination
- dim_disposition
- dim_provider
- dim_medication
- dim_procedure
- dim_location
---

# Keys and Rules
Natural key is the unique eMeds PCR number labeled as pcr_number.

Timestamps: All datetime fields are stored as provided by Report Writer in local time (America/New_York) using TIMESTAMP WITHOUT TIME ZONE.

Incremental load (“newer wins”) compares last_modified (local time) within the same source feed.

Chronology rule: notified ≤ enroute ≤ at_scene ≤ depart_scene ≤ at_dest ≤ back_in_service — evaluated in local time.
---

# Business Rules
- Every PCR must map to exactly one `fact_incident`.
- Every fact record (`vital`, `medication`, `procedure`) must reference a valid `pcr_number`.
- Time fields must follow chronology.
- Missing or invalid values are flagged in `etl.load_log`.

---

# Security & Access
- Roles: `etl_writer` and `bi_reader`
- PHI minimized in `mart`
---

# Operations
- CSVs will be automated into email via scheduled reports. Those CSV files will be manually dropped into a County network drive for retention and import into the database. Initial loads are manual; future state includes automated ingestion and scheduled ETL.
---
# Change Management
- Migrations in `sql/` and a regenerative data dictionary.
---
# Data Dictionary
The data dictionary is maintained within PostgreSQL using `COMMENT ON ...` statements at both table and column levels. A Python script extracts this metadata into Markdown files in `docs/20-data-dictionary/` for stakeholder review. The dictionary will include: column name, type, nullable, key flags, NEMSIS mapping, plain-English description, and QA checks.