# EMS QA/QI Data Warehouse - Architecture Overview

## Purpose
This system provides a structured, reliable, and transparent data warehouse for EMS Quality Assurance (QA) and Quality Improvement (QI) analytics.
It ingests data from **ePCR (eMeds Report Writer exports)** that includes CAD (Computer Aided Dispatch) information, normalizes it into a consistent schema, and produces analytics-ready fact and dimension tables.

The goal of this is to mimic the functionality of ImageTrend Data Mart, which is not available to our agency due to the State ImageTrend license, while ensuring compliance, reporoducibility and auditability.

---

## High-Level Design
The warehouse is built on **PostgreSQL 15**, hosted on a secure Linux server (currently in a controlled homelab for prototyping, with the option to migrate to county IT infrastructure).

Data is structured into **four zones**:

1. **`land_raw`**
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
    - Retention: Long-term, supporst QA/QI dashboards and reporting

4. **`etl`**
    - Purpose: Operational metadata.
    - Content: Load logs, QA checks, and ETL audit trail.

---

## Data Flow
1. **Extract**
    - Source: ePCR Report Writer CSVs.
    - Delivery: Placed into a secure input folder by QM team.

2. **Load to Stage**
    - Method: Automated CSV imports using SQL `COPY` or Python loader scripts.
    - Schema: `stage.*_stg` tables mirror input structure.

3. **Transform & Merge**
    - Standardize timestamps to UTC.
    - Deduplicate records.
    - Upsert facts and dimension using natural keys (e.g, PCR number for incidents).
    - Track row counts, load times, and validation checks in `et.load_log`.

4. **Promote to Mart**
    - Dimension tables populated first.
    - Fact tables populated with foreign keys referencing dimensions.
    - QA checks executed after load (e.g., orphan detection, missing values, extreme durations).

---

## Security & Access
- **Network:** Database bound to localhost; external access only via SSH tunnel.
- **Authentication:**
    - `etl_writer` role: load rights on `land_raw`, `stage`, `mart`, `etl`.
    - `bi_reader` role: read-only rights on `mart`.
- **PHI Handling:**
    - `mart` schema contains no direct PHI (no names, full DOB, MRNs).
    - Any identifiers in `stage` are hashed and then dropped.
- **Backups:**
    - Nightly `pg_dump` logical backups.
    - Weekly base backups when hosted in county IT environment.

---

## Benefits
- **Transparency**: Fully documented schemas, transformations, and QA checks.
- **Reproducibility**: Version-controlled SQL and ETL scripts in GitHub.
- **Auditability**: Load logs and QA gates provide accountability.
- **Scalability**: Structure design to scale from a single laptop to county IT servers.
- **Compliance**: Aligns with HIPAA principles by minimizing PHI in analytics layer.

---

## Next Steps
- Finalize schema design for fact and dimension tables.
- Build initial ETL loaders for Incident and Vital datasets.
- Develop QA checks aligned to NEMSQA and state reporting measures.
- Provide IT with deployment guide for hosting within county-managed infrastructure.