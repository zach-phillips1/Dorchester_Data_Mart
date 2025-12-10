# Dorchester EMS Data Mart

PostgreSQL 18.x **star-schema data mart** for EMS QA/QI analytics.  
Primary data sources are **ImageTrend eMeds Report Writer CSV exports** (NEMSIS v3.5 aligned).  

The project’s goal is an **auditable, reproducible warehouse** for clinical quality tracking, NEMSQA measures, and future dashboards (Power BI, R/Shiny, or similar). It is designed so that another EMS agency on a state-hosted ImageTrend system could fork and adapt it with minimal changes.

---

## Contents

- [Overview](#overview)
- [Architecture](#architecture)
  - [Schemas](#schemas)
  - [Time Handling Policy](#time-handling-policy)
- [Data Model](#data-model)
  - [Stage Tables](#stage-tables)
  - [Dimensions](#dimensions)
  - [Fact Tables](#fact-tables)
- [Repository Structure](#repository-structure)
- [ETL Workflow](#etl-workflow)
  - [Run Order](#run-order)
  - [Incremental Load Strategy](#incremental-load-strategy)
- [Manual Load Process (CSV → stage → mart)](#manual-load-process-csv--stage--mart)
- [NEMSQA & Clinical Measures](#nemsqa--clinical-measures)
- [Known ImageTrend / eMeds Caveats](#known-imagetrend--emeds-caveats)
- [Frequently Used SQL Snippets](#frequently-used-sql-snippets)
- [QA & Validation Checks](#qa--validation-checks)
- [Security & PHI](#security--phi)
- [Milestones](#milestones)
  - [Completed](#completed)
  - [Planned](#planned)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**Database:** `ems_mart`  
**DBMS:** PostgreSQL 18.x  

This project builds a **local copy of a state-level EMS data mart** for Dorchester County EMS.  
Because Dorchester uses the **Maryland state–hosted ImageTrend eMeds system**, the built‑in ImageTrend Data Mart is not accessible at the agency level. This repository recreates that concept locally using:

- Scheduled / ad‑hoc **Report Writer CSV exports**
- A **typed `stage` layer** for ingestion
- A **`mart` layer** with a star schema and clean keys
- A future **`qa` layer** for QA dashboards and views

Design goals:

- **Re-runnable**, fully SQL-based, no GUI dependencies
- **Incremental** ETL using `last_modified` semantics (“newer wins”)
- **NEMSIS-aware**, but opinionated toward QA/QI questions (NEMSQA, AHA, internal CQI)
- Structured so other EMS agencies can **fork and adapt** with low friction

---

## Architecture

### Schemas

- `land_raw`  
  Reserved for future raw file loads (e.g., direct `COPY` from untyped CSVs). Currently unused.

- `stage`  
  Typed staging layer. Tables here are **1:1 with Report Writer exports** (incidents, situation, vitals, procedures, medications).  
  - Duplicates allowed  
  - Minimal constraints  
  - Used as the **only place** where CSV headers must match column names.

- `mart`  
  Curated star-schema layer. Contains:
  - Dimension tables (`dim_*`)
  - Fact tables (`fact_*`)
  - Surrogate keys and cleaned enums
  - Logic to normalize ImageTrend quirks into stable analytics entities

- `etl`  
  Home for:
  - Upsert scripts
  - Validation queries
  - Future load logs and QA scorecards

- `qa`  
  Reserved for read-only QA / dashboard views (not populated yet).

- `public`  
  Left mostly empty; all analytics objects live in `stage`, `mart`, `etl`, or `qa`.

### Time Handling Policy

- All timestamps are stored as **local civil time (America/New_York)**.
- Columns are `TIMESTAMP WITHOUT TIME ZONE`.
- No UTC conversion is performed in ETL.
- Chronology rules (e.g., `psap ≤ dispatch ≤ enroute ≤ at_scene ≤ at_dest ≤ back_in_service`) are enforced and validated in **local time**.

This keeps the model aligned with how EMS operations actually think and chart times.

---

## Data Model

At a high level, the model follows a classic star schema:

```text
            dim_unit
               |
            fact_incident ----- dim_destination
               |   \
               |    \---- dim_disposition
               |
        +------+-------+---------------------+
        |              |                     |
   fact_situation  fact_vital         fact_procedure
                                        |
                                   fact_medication
```

> Note: More facts/dimensions (e.g., crew, airway, response, history) will be added as the project matures.

### Stage Tables

The following `stage` tables are populated from ImageTrend eMeds Report Writer CSV exports:

- `stage.incidents_stg`
  - One row per PCR / incident per export.
  - Contains eResponse, eTimes, eDisposition, eDispatch, and operational fields.

- `stage.situation_stg`
  - eSituation block (chief complaint, impressions, possible injury, etc.).

- `stage.vitals_stg`
  - Wide-format vital signs (multiple columns per record), later unpivoted into atomic rows.

- `stage.procedures_stg`
  - eProcedures block, including procedure codes, datetime, success, attempts, etc.

- `stage.medications_stg`
  - eMedications block, including medication given, dose, route, datetime, etc.

Each `*_stg` table is:

- Typed to match the CSV headers for that report.
- Permissive on constraints (allows duplicates).
- Cleared with `TRUNCATE` before each import.

### Dimensions

Current `mart` dimensions:

- `mart.dim_unit`
  - Normalized unit identifiers (ambulances, chase cars, specialty units).
  - Includes a simple **service level** classification (ALS/BLS/UNKNOWN) and optional notes.

- `mart.dim_destination`
  - Normalized destination facilities.
  - Handles multiple spellings / codes for the same hospital.
  - Designed to support grouping (e.g., STEMI centers, stroke centers, trauma).

- `mart.dim_disposition`
  - Normalized combinations of raw disposition fields (source type + label).
  - Adds a **disposition category**:
    - `transport`
    - `transfer`
    - `no_transport`
    - `canceled`
    - `standby`
    - `other`
  - Flags for curation (e.g., “Other – needs review”).

- `mart.dim_vital_type`
  - NEMSIS-aligned vital sign types.
  - Maps internal codes to stable names (e.g., AVPU, GCS total, pain scale, systolic BP).

- `mart.dim_medication`
  - Distinct medications charted in eMeds.
  - Used as a lookup for `fact_medication`.

- `mart.dim_procedure`
  - Distinct procedures charted in eMeds (eProcedures).
  - Used as a lookup for `fact_procedure`.

All dimensions are built with **idempotent upsert scripts**, so they can be safely re-run when new units, facilities, or codes appear.

### Fact Tables

Current `mart` fact tables:

- `mart.fact_incident`
  - Grain: **1 row per PCR / incident**.
  - Contains:
    - Unit, destination, disposition foreign keys
    - PSAP, dispatch, enroute, at-scene, depart-scene, at-destination, back-in-service timestamps
    - Incident-level operational flags and basic NEMSIS attributes

- `mart.fact_situation`
  - Grain: **1 row per PCR** (joined to incident by PCR number/key).
  - Contains:
    - Chief complaint
    - Primary/secondary impressions
    - Possible injury fields
    - Derived `injury_flag` for trauma analytics

- `mart.fact_vital`
  - Grain: **1 row per vital measurement**.
  - Built by unpivoting the wide `vitals_stg` export.
  - Includes:
    - `incident_key`
    - `vital_type_key`
    - Vital value(s)
    - Vital timestamp
  - Special handling for:
    - AVPU
    - GCS components and total
    - Pain score and pain scale type

- `mart.fact_procedure`
  - Grain: **1 row per procedure event**.
  - Links to:
    - `incident_key`
    - `procedure_key` (from `dim_procedure`)
  - Includes:
    - Procedure datetime
    - Attempts, success, and other metadata where available

- `mart.fact_medication`
  - Grain: **1 row per medication administration**.
  - Links to:
    - `incident_key`
    - `medication_key` (from `dim_medication`)
  - Includes:
    - Dose, route, units, and datetime

These tables together support end‑to‑end clinical analytics across a full year of EMS operations.

---

## Repository Structure

The repository is organized as follows:

```text
.
├── .vscode/
│   └── settings.json
├── docs/
│   ├── 00_architechture.md
│   └── 10_design_document.md
├── etl/
│   ├── 31_upsert_dim_unit.sql
│   ├── 32_upsert_dim_destination.sql
│   ├── 33_upsert_dim_disposition.sql
│   ├── 34_upsert_fact_incident.sql
│   ├── 36_upsert_dim_vital_type.sql
│   ├── 37_upsert_fact_vital.sql
│   ├── 38_upsert_dim_procedure.sql
│   ├── 39_upsert_dim_medication.sql
│   ├── 40_upsert_fact_procedure.sql
│   ├── 42_upsert_fact_medication.sql
│   └── 43_upsert_fact_situation.sql
├── sql/
│   ├── 00_schema_and_roles.sql
│   ├── 10_stage_incidents_table_creation.sql
│   ├── 11_stage_vitals_table_creation.sql
│   ├── 12_stage_procedures_table_creation.sql
│   ├── 13_stage_medication_table_creation.sql
│   ├── 14_stage_situation_table_creation.sql
│   ├── 21_mart_dim_unit_table_creation.sql
│   ├── 22_mart_dim_dest_table_creation.sql
│   ├── 23_mart_dim_disposition_table_creation.sql
│   ├── 24_mart_fact_incident_table_creation.sql
│   ├── 25_mart_dim_vital_type_table_creation.sql
│   ├── 26_mart_fact_vital_table_creation.sql
│   ├── 27_mart_dim_medication_table_creation.sql
│   ├── 28_mart_dim_procedure_table_creation.sql
│   ├── 290_mart_fact_medication_table_creation.sql
│   └── 291_mart_fact_situation_table_creation.sql
├── .gitignore
├── LICENSE
└── README.md  (this file)
```

> File names may evolve; the intent is that **20‑series scripts create objects** and **30/40‑series scripts populate them**.

---

## ETL Workflow

All ETL is currently **manual** (SQL‑driven) but designed to be automated later with cron / Task Scheduler + `psql`.

### Run Order

1. **Create schemas and roles**

   ```sql
   \i sql/00_schema_and_roles.sql
   ```

2. **Create stage tables**

   ```sql
   \i sql/10_stage_incidents_table_creation.sql
   \i sql/11_stage_vitals_table_creation.sql
   \i sql/12_stage_procedures_table_creation.sql
   \i sql/13_stage_medication_table_creation.sql
   \i sql/14_stage_situation_table_creation.sql
   ```

3. **Create mart tables**

   ```sql
   \i sql/21_mart_dim_unit_table_creation.sql
   \i sql/22_mart_dim_dest_table_creation.sql
   \i sql/23_mart_dim_disposition_table_creation.sql
   \i sql/25_mart_dim_vital_type_table_creation.sql
   \i sql/27_mart_dim_medication_table_creation.sql
   \i sql/28_mart_dim_procedure_table_creation.sql
   \i sql/24_mart_fact_incident_table_creation.sql
   \i sql/26_mart_fact_vital_table_creation.sql
   \i sql/290_mart_fact_medication_table_creation.sql
   \i sql/291_mart_fact_situation_table_creation.sql
   ```

4. **Load CSVs into stage** (see [Manual Load Process](#manual-load-process-csv--stage--mart)).

5. **Run upsert scripts to populate mart**

   ```sql
   \i etl/31_upsert_dim_unit.sql
   \i etl/32_upsert_dim_destination.sql
   \i etl/33_upsert_dim_disposition.sql
   \i etl/36_upsert_dim_vital_type.sql
   \i etl/38_upsert_dim_procedure.sql
   \i etl/39_upsert_dim_medication.sql

   \i etl/34_upsert_fact_incident.sql
   \i etl/37_upsert_fact_vital.sql
   \i etl/40_upsert_fact_procedure.sql
   \i etl/42_upsert_fact_medication.sql
   \i etl/43_upsert_fact_situation.sql
   ```

6. **Run QA checks** (see [QA & Validation Checks](#qa--validation-checks)).

### Incremental Load Strategy

The project assumes **incremental exports** from Report Writer based on date ranges, e.g.:

- “Yesterday”
- “Last week”
- Specific date ranges (e.g., `2025-01-01` to `2025-01-31`)

For now, a **full‑year export** was used to bootstrap the system (for TRAUMA‑01 analytics).  
Going forward, the plan is:

- Nightly exports for the **previous day** per data domain  
- `TRUNCATE` + `COPY`/import into the appropriate `*_stg` table  
- Run upsert scripts which use `last_modified` to implement “newer wins” logic in `mart`

The main limitation on automation is on the **ImageTrend side** (how exports are scheduled), not on the SQL side.

---

## Manual Load Process (CSV → stage → mart)

1. **Export CSV from ImageTrend eMeds Report Writer**

   For each domain (incidents, situation, vitals, procedures, medications):

   - Set the desired date range (e.g., entire year, yesterday).
   - Ensure the exported columns match the `stage` table definitions.

2. **Import into `stage`**

   Using `psql`:

   ```sql
   TRUNCATE stage.incidents_stg;

   \copy stage.incidents_stg
     FROM '/path/to/incidents.csv'
     WITH (FORMAT csv, HEADER true, NULL '', DELIMITER ',', ENCODING 'UTF8');
   ```

   Repeat for:

   - `stage.situation_stg`
   - `stage.vitals_stg`
   - `stage.procedures_stg`
   - `stage.medications_stg`

3. **Promote to `mart`**

   Run the upsert scripts in the [Run Order](#run-order) section.

4. **Validate**

   - Compare row counts between `*_stg` and `fact_*`.
   - Check basic QA views (see below).

---

## NEMSQA & Clinical Measures

The long‑term goal is to support a wide set of **NEMSQA measures** and internal CQI metrics.

Currently:

- Data model supports building **TRAUMA‑01** (pain assessment for trauma patients).
- Supporting facts/dims:
  - `fact_incident`
  - `fact_situation`
  - `fact_vital`
  - `dim_disposition`
  - `dim_vital_type`

Example logic (high‑level):

- **Denominator** (eligible trauma transports)
  - Injury flag true (derived from eSituation possible injury fields).
  - Normal mentation:
    - AVPU = “Alert”, or
    - GCS Total = 15.
  - Disposition category in `{transport, transfer}`.

- **Numerator**
  - At least one pain assessment documented:
    - Pain score vital, or
    - Pain scale type vital.

R scripts (not included here yet) use `DBI` + `RPostgres` + `dplyr`/`dbplyr` to query PostgreSQL and generate monthly performance charts, including pre‑ vs post‑validation comparisons (e.g., after state‑level documentation rules were implemented in eMeds).

More detailed measure definitions and SQL/R examples will live in `docs/` as the project matures.

---

## Example Analytics: TRAUMA-01 (Pain Assessment for Trauma Patients)

This data mart is designed to support NEMSQA-aligned EMS quality measures.  
As an example, the **TRAUMA-01** measure (pain assessment for trauma patients with normal mentation) was implemented using:

- `fact_incident`
- `fact_situation` (injury flag, impressions)
- `fact_vital` (AVPU / GCS / Pain Score fields)
- `dim_disposition` (transport vs non-transport)

Once the model was complete, Dorchester EMS produced a full-year TRAUMA-01 trend showing:

- **Significant documentation gaps early in the year**  
- A **sharp improvement beginning mid-September**, corresponding to a state-level documentation validation added in eMeds

This example illustrates how the mart supports:
- Longitudinal QA/QI monitoring  
- Detection of documentation issues  
- Evaluation of process changes  
- Compliance tracking across operational and clinical domains  

(A full case study or measure definition will be added to `docs/`.)


---

## Known ImageTrend / eMeds Caveats

This project is opinionated by experience with the **Maryland eMeds configuration** of ImageTrend. Some common quirks:

- **NEMSIS vs non‑NEMSIS fields**
  - ImageTrend supports normal NEMSIS v3.5 fields (e.g., eResponse, eTimes, eSituation, eVitals, eProcedures, eMedications).
  - It also exposes many **non‑NEMSIS, system‑specific fields** with internal names like `itAirway.007`, `itVitals.023`, etc.
  - These `it*.xxx` fields often correspond to discrete UI elements or checkboxes that do not appear directly in the NEMSIS data dictionary.

- **Internal item labels in Report Writer**
  - Report Writer sometimes exposes internal item labels and concatenated values (e.g., `ChestRiseLeftObservationStatus_Yes`) rather than clean code/value pairs.
  - This project prefers **standard NEMSIS exports** wherever possible and only uses `it*.xxx` data when absolutely necessary.

- **Export scheduling**
  - Report Writer supports:
    - Fixed date ranges (start/end date).
    - Relative ranges like “yesterday” and “last week”.
  - It **does not** support complex relative windows such as “between 2 days ago and 5 days ago”.  
    This is a consideration for automation design.

- **Occasional incomplete rows**
  - It is possible to export rows with only a PCR number and little else (e.g., procedures with missing datetime).
  - For analytics:
    - This project filters out such records at the **export or stage** level (e.g., requiring eProcedures datetime to be non‑blank).

These caveats are documented so other agencies can anticipate them when adapting this project.

---

## Frequently Used SQL Snippets

### 1. Check for orphan procedures (no matching incident)

```sql
SELECT COUNT(*) AS orphan_procedures
FROM mart.fact_procedure p
LEFT JOIN mart.fact_incident i
  ON p.incident_key = i.incident_key
WHERE i.incident_key IS NULL;
```

### 2. Chronology violations (basic example)

```sql
SELECT i.pcr_number,
       i.psap_time,
       i.dispatch_notified_time,
       i.unit_enroute_time,
       i.unit_at_scene_time,
       i.depart_scene_time,
       i.at_destination_time
FROM mart.fact_incident i
WHERE i.unit_at_scene_time < i.unit_enroute_time
   OR i.depart_scene_time   < i.unit_at_scene_time
   OR i.at_destination_time < i.depart_scene_time;
```

### 3. Transport incidents missing destination

```sql
SELECT i.pcr_number,
       d.category AS disposition_category
FROM mart.fact_incident i
JOIN mart.dim_disposition d
  ON i.disposition_key = d.disposition_key
LEFT JOIN mart.dim_destination dest
  ON i.destination_key = dest.destination_key
WHERE d.category IN ('transport', 'transfer')
  AND dest.destination_key IS NULL;
```

### 4. Pain assessment completeness for trauma patients (sketch)

```sql
-- Trauma denominator (simplified)
WITH trauma_denominator AS (
  SELECT i.incident_key
  FROM mart.fact_incident  i
  JOIN mart.fact_situation s ON s.incident_key = i.incident_key
  JOIN mart.dim_disposition d ON d.disposition_key = i.disposition_key
  WHERE s.injury_flag = TRUE
    AND d.category IN ('transport', 'transfer')
),

pain_vitals AS (
  SELECT DISTINCT v.incident_key
  FROM mart.fact_vital v
  JOIN mart.dim_vital_type t
    ON v.vital_type_key = t.vital_type_key
  WHERE t.vital_type_code IN ('PAIN_SCORE', 'PAIN_SCALE_TYPE')
)

SELECT
  COUNT(*)                            AS denominator,
  COUNT(p.incident_key)               AS numerator,
  COUNT(p.incident_key)::numeric
    / COUNT(*)::numeric               AS rate
FROM trauma_denominator d
LEFT JOIN pain_vitals p
  ON p.incident_key = d.incident_key;
```

These snippets are intentionally generic so they can be adapted by other agencies.

---

## QA & Validation Checks

Planned / existing QA checks live in the `etl` schema (as views and helper queries). Examples include:

- **Chronology checks**
  - Times out of order (incident‑level).
- **Disposition vs destination consistency**
  - Transport disposition without destination.
  - Destination documented on non‑transport dispositions.
- **Contact contradictions**
  - “No patient contact” but vitals or procedures present.
- **“Other” curation**
  - Dispositions or destinations using “Other” text fields that need normalization.
- **Measure‑specific checks**
  - Trauma pain assessment completeness (TRAUMA‑01).
  - Future pain and cardiac arrest measures.

---

## Security & PHI

This project is designed to keep **PHI exposure minimal**:

- `mart` layer:
  - Excludes direct identifiers (no names, no full DOB, no MRNs).
  - Focuses on operational and clinical fields for QA/QI.
- Roles (defined in `sql/00_schema_and_roles.sql`):
  - `etl_writer` – ETL / maintenance privileges.
  - `bi_reader` – read‑only access for reporting/analytics.
- Raw CSVs:
  - Never stored in the repository.
  - Ignored via `.gitignore`.
- If you fork this project, review your local/state PHI policies and adjust accordingly.

---

## Milestones

### Completed

- Core schemas created (`stage`, `mart`, `etl`, `qa`, `land_raw`).
- Stage tables for incidents, situation, vitals, procedures, medications.
- Dimension tables for units, destinations, dispositions, vital types, procedures, medications.
- Fact tables for incidents, situation, vitals, procedures, medications.
- Working upsert scripts with **incremental “newer wins” logic**.
- Bootstrap of a full‑year dataset for TRAUMA‑01 analytics.
- First R‑based analytics workflow for Trauma‑01 (monthly trend with validation impact).

### Planned

- Add additional NEMSIS blocks:
  - Crew, airway, response, history, and others.
- Build out the `qa` schema:
  - Stable QA views suitable for Power BI or R/Shiny dashboards.
- Automation:
  - Nightly export jobs from ImageTrend for “yesterday”.
  - Scheduled `psql` scripts to run ETL and QA checks.
- Additional measures:
  - Trauma‑02, PAIN‑01, PAIN‑02, cardiac arrest bundles, and AHA Mission Lifeline elements.
- Documentation:
  - Detailed measure definitions in `docs/`.
  - Data dictionary exports with `COMMENT ON` metadata.

---

## Troubleshooting

- **Object not found errors**
  - Confirm you’ve run `00_schema_and_roles.sql` and all `*_table_creation.sql` scripts before ETL upserts.
- **CSV import failures**
  - Ensure CSV headers match the `stage` table columns exactly.
  - Confirm delimiter, encoding, and NULL handling.
- **Row count mismatches**
  - Remember that `mart` facts are **deduplicated and normalized**; perfect equality with `stage` is not always expected.
- **Orphaned facts**
  - Check for incidents loaded after the last `fact_incident` ETL run.
  - Or use the orphan snippets in [Frequently Used SQL Snippets](#frequently-used-sql-snippets).

---

## Contributing

This repository is primarily built for Dorchester County EMS, but the design is intentionally generic.

If you are an EMS agency or data analyst:

- Feel free to fork and adapt.
- Use feature branches and small, focused commits.
- Keep schema changes documented in `docs/`.
- Prefer SQL‑only solutions where possible (no GUI‑only logic).

Pull requests that:

- Improve portability,
- Enhance QA views,
- Or add well‑documented NEMSQA measure implementations

are especially welcome.

---

## License

See `LICENSE` for details.

