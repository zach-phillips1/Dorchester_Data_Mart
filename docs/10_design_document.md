# Dorchester EMS Data Mart – Design Document
Version: 2025-12  
Status: Active

---

## 1. Purpose & Scope

This document describes the **logical and physical design** of the Dorchester EMS Data Mart. It is intended for:

- EMS leadership and QA/QI staff who need a high-level understanding of how analytics are produced.
- Analysts and developers who will maintain or extend the warehouse.
- Other EMS agencies interested in adapting this pattern for their own ImageTrend eMeds environments.

The Data Mart converts **ImageTrend eMeds Report Writer CSV exports** (NEMSIS v3.5 aligned) into a **star-schema warehouse** optimized for:

- EMS quality measures (e.g., NEMSQA-aligned).
- Clinical and operational QA/QI.
- Longitudinal trend analysis.
- Downstream tools like R, Power BI, or Python.

This document focuses on the **current deployed design**. It does not prescribe a specific automation strategy for scheduling exports or ETL jobs.

---

## 2. Technical Stack

- **Database:** PostgreSQL 18.x
- **Host:** Local Windows 11 workstation (accessed via `localhost`)
- **Schemas:**
  - `land_raw` – reserved, currently unused.
  - `stage` – typed staging tables populated from CSV exports.
  - `mart` – star-schema analytics layer (dimensions + facts).
  - `etl` – ETL logic and future QA helpers.
  - `qa` – reserved for future QA views/materialized views.
  - `public` – not used for warehouse objects.

- **Primary Data Source:** ImageTrend eMeds (Maryland state-hosted)  
  - Extracted using **Report Writer**.
  - Aligned to NEMSIS v3.5 data structures where possible.

- **Typical Consumers:**
  - R / RStudio (using `DBI` + `RPostgres`).
  - SQL clients (DBeaver, psql).
  - Future: Power BI, other BI tools.

---

## 3. High-Level Data Flow

```text
ImageTrend eMeds (Report Writer CSVs)
        |
        v
    stage schema  (incidents_stg, situation_stg, vitals_stg, procedures_stg, medications_stg)
        |
        |  ETL (SQL upserts, last_modified, normalization)
        v
    mart schema   (dimensions + fact tables)
        |
        v
  QA views / analytics (R scripts, future qa schema, BI dashboards)
```

Key principles:

- **Separation of concerns**:
  - `stage` mirrors the source exports.
  - `mart` is clean, normalized, and analytics-ready.
- **Idempotent ETL**:
  - Upsert scripts can be re-run safely.
- **Incremental merges**:
  - Newer records (by `last_modified`) override older ones.

---

## 4. Schema Design

### 4.1 `stage` Schema

The `stage` schema holds **typed copies** of the CSV exports from ImageTrend Report Writer. It is designed to:

- Accept **full-year** or **incremental** date range exports.
- Allow duplicates (no unique constraints).
- Serve as the only place where CSV column names and table columns must match 1:1.

Current tables:

- `stage.incidents_stg`  
  - One row per incident/PCR per export.
  - Core incident-level fields (eResponse, eTimes, eDisposition, eDispatch, operational metadata).

- `stage.situation_stg`  
  - eSituation data: chief complaint, impressions, possible injury, etc.

- `stage.vitals_stg`  
  - Wide-format vitals (multiple vital fields in columns per record).
  - Later unpivoted into long-form records in `mart.fact_vital`.

- `stage.procedures_stg`  
  - eProcedures data: procedure codes, timestamps, success/attempts, etc.

- `stage.medications_stg`  
  - eMedications data: medication, dose, route, units, timestamps.

#### Stage Loading

Loading is performed via:

```sql
TRUNCATE stage.incidents_stg;

\copy stage.incidents_stg
  FROM 'C:/path/to/incidents.csv'
  WITH (FORMAT csv, HEADER true, NULL '', DELIMITER ',', ENCODING 'UTF8');
```

Similar commands apply to `situation_stg`, `vitals_stg`, `procedures_stg`, and `medications_stg`.

No complex transformations are done in `stage`: it is a **landing and typing** layer.

---

### 4.2 `mart` Schema

The `mart` schema implements the **star-schema analytics model**. It contains:

- Dimension tables (`dim_*`)
- Fact tables (`fact_*`)

#### 4.2.1 Dimensions

**`mart.dim_unit`**

- One row per distinct unit identifier.
- Attributes:
  - `unit_key` (surrogate PK)
  - `unit_code`
  - `service_level` (ALS / BLS / UNKNOWN)
  - `notes` (optional)

**`mart.dim_destination`**

- One row per normalized destination facility.
- Handles multiple raw spellings/codes from eMeds.
- Attributes:
  - `destination_key`
  - `destination_code`
  - `destination_name`
  - Optional grouping fields (e.g., region, facility type).

**`mart.dim_disposition`**

- One row per distinct raw disposition combination.
- Attributes:
  - `disposition_key`
  - Natural key (e.g., source type + raw label)
  - `category`:
    - `transport`
    - `transfer`
    - `no_transport`
    - `canceled`
    - `standby`
    - `other`
  - Flags for “Other” and potential curation.

**`mart.dim_vital_type`**

- One row per vital measurement type.
- Attributes:
  - `vital_type_key`
  - Code or name (e.g., `AVPU`, `GCS_TOTAL`, `PAIN_SCORE`).
  - Optional mapping to NEMSIS fields.

**`mart.dim_medication`**

- One row per distinct medication as charted in eMeds.
- Attributes:
  - `medication_key`
  - Raw medication name/code
  - Optional normalized name, category, and notes.

**`mart.dim_procedure`**

- One row per distinct procedure as charted in eMeds.
- Attributes:
  - `procedure_key`
  - Raw procedure name/code
  - Optional normalized category and notes.

All dimensions are populated using `etl/3x_upsert_dim_*.sql` scripts, which:

- Insert new rows as new codes appear.
- Avoid destructive changes.
- Allow future normalization (e.g., grouping multiple raw values into a single normalized category).

---

#### 4.2.2 Facts

**`mart.fact_incident`**

- Grain: **1 row per PCR/incident**.
- Attributes (high-level):
  - `incident_key` (PK)
  - Natural identifiers (pcr_number, incident_number)
  - FK references:
    - `unit_key`
    - `destination_key`
    - `disposition_key`
  - Times:
    - psap_call_time
    - dispatch_notified_time
    - unit_enroute_time
    - unit_at_scene_time
    - depart_scene_time
    - at_destination_time
    - back_in_service_time
  - Operational flags and basic clinical attributes.

**`mart.fact_situation`**

- Grain: **1 row per PCR**.
- Contains the eSituation block:
  - Chief complaint
  - Primary and secondary impressions
  - Possible injury fields
  - Derived flags such as `injury_flag` (used for trauma analytics).

**`mart.fact_vital`**

- Grain: **1 row per vital measurement** (long/unpivoted format).
- Attributes:
  - `vital_key` (PK)
  - `incident_key` (FK)
  - `vital_type_key` (FK)
  - Vital value fields (depending on type)
  - Vital timestamp

Source:

- Built from `stage.vitals_stg` by:
  - Parsing wide-form records.
  - Mapping each vital to a `vital_type_key`.
  - Deduplicating where necessary.

**`mart.fact_procedure`**

- Grain: **1 row per procedure occurrence**.
- Attributes:
  - `procedure_fact_key` (PK)
  - `incident_key` (FK)
  - `procedure_key` (FK)
  - Procedure datetime
  - Attempts/success fields where present.

**`mart.fact_medication`**

- Grain: **1 row per medication administration**.
- Attributes:
  - `medication_fact_key` (PK)
  - `incident_key` (FK)
  - `medication_key` (FK)
  - Dose, units, route
  - Medication datetime

All facts are populated with `etl/3x_upsert_fact_*.sql` scripts.

---

## 5. ETL Design

### 5.1 ETL Characteristics

- **Manual trigger**: ETL is run by a human operator (no scheduler is defined yet).
- **Script-driven**: All transformations are pure SQL, checked into version control.
- **Incremental**: Uses `last_modified` (or equivalent) to implement **“newer wins”** logic.

### 5.2 Run Order

Typical sequence after CSV import:

1. **Create schemas and tables** (initial setup only):  
   - `sql/00_schema_and_roles.sql`  
   - `sql/1x_stage_*_table_creation.sql`  
   - `sql/2x_mart_*_table_creation.sql`

2. **Load CSV → stage**  
   - `\copy` or GUI import into `stage.*_stg`.

3. **Populate dimensions** (idempotent upserts):  

   ```sql
   \i etl/31_upsert_dim_unit.sql
   \i etl/32_upsert_dim_destination.sql
   \i etl/33_upsert_dim_disposition.sql
   \i etl/36_upsert_dim_vital_type.sql
   \i etl/38_upsert_dim_procedure.sql
   \i etl/39_upsert_dim_medication.sql
   ```

4. **Populate facts**:

   ```sql
   \i etl/34_upsert_fact_incident.sql
   \i etl/43_upsert_fact_situation.sql
   \i etl/37_upsert_fact_vital.sql
   \i etl/40_upsert_fact_procedure.sql
   \i etl/42_upsert_fact_medication.sql
   ```

5. **Run QA checks** (queries/views in `etl` and/or `qa`).

### 5.3 Incremental Merge (“Newer Wins”)

For dimensions and facts, merge logic follows this pattern (conceptually):

```sql
INSERT INTO mart.some_fact AS f ( ... )
SELECT ...
FROM stage.some_stg s
ON CONFLICT (natural_key_or_surrogate_combination)
DO UPDATE
SET ...
WHERE f.last_modified < EXCLUDED.last_modified;
```

This ensures:

- New or updated records from `stage` replace older versions in `mart`.
- Re-running ETL with overlapping date ranges is safe and deterministic.

---

## 6. Timestamp Handling

- All timestamps are stored as **`TIMESTAMP WITHOUT TIME ZONE`**.
- All values are interpreted as **local civil time (America/New_York)**.
- No UTC conversion or timezone shifting is applied.
- Chronology checks (e.g., psap ≤ dispatch ≤ enroute ≤ at_scene ≤ at_dest ≤ back_in_service) are performed in local time.

This matches how EMS incidents are documented and reviewed operationally.

---

## 7. Security & Access Design

- Database is reachable only from the local Windows workstation (via `localhost`), or via remote tools that connect to that workstation.
- Credentials are **not** stored in notebooks or scripts:
  - R uses **`.Renviron`** with environment variables:
    - `EMS_MART_USER`
    - `EMS_MART_PASSWORD`
    - `EMS_MART_HOST`
    - `EMS_MART_PORT`
    - `EMS_MART_DB`
- Roles:
  - `etl_writer` – allowed to run ETL, truncate/load stage tables, and execute upsert scripts.
  - `bi_reader` – read-only access to `mart` (and, in future, `qa`) for analytics.

### PHI Strategy

- `mart` intentionally excludes directly identifying fields:
  - No patient names.
  - No full DOB.
  - No MRNs.
- `stage` may contain PHI if present in the exported CSVs, but PHI is **not propagated** into `mart`.

---

## 8. QA & Validation Approach

QA and validation are integral to the design:

- **Row count comparisons:**
  - Verify that `stage` and `mart` row counts are reasonable (not necessarily equal, due to normalization and deduplication).
- **Orphan detection:**
  - Facts (e.g., procedures, medications) with no matching incident.
- **Chronology checks:**
  - Time fields in `fact_incident` are checked for logical order.
- **Disposition/destination consistency:**
  - Transport dispositions without destinations.
  - Non-transport dispositions with a destination.
- **“Other” normalization:**
  - Dispositions or destinations using “Other” free text flagged for review.

QA logic currently lives in ad-hoc queries and is planned to move into views or helper tables within `etl` and `qa`.

---

## 9. Design Constraints & Assumptions

- **State-hosted ImageTrend:**  
  Dorchester EMS does not control the underlying ImageTrend database; access is limited to what Report Writer exposes.
- **Report Writer limitations:**
  - Internal `it*.xxx` fields (non-NEMSIS) may be difficult to interpret and are used sparingly.
  - Export date range options are limited; complex relative windows (e.g., “2–5 days ago”) are not supported.
- **No hard real-time requirement:**
  - ETL does not need to run in near-real-time; daily or weekly refresh is sufficient for QA/QI.

---

## 10. Future Enhancements (Design-Level)

Planned future extensions include:

- **Additional facts/dimensions:**
  - Crew, airway, response, injury detail, history, and other NEMSIS domains.
- **qa schema:**
  - Stable, documented views for QA dashboards (e.g., NEMSQA measures, AHA metrics, internal KPIs).
- **Data dictionary:**
  - Exported from `COMMENT ON` metadata for all `mart` objects.
- **Documentation:**
  - Detailed measure specifications and SQL/R examples in `/docs/`.

These enhancements will build on the design principles described in this document.

---

## 11. Summary

The Dorchester EMS Data Mart design:

- Uses **PostgreSQL 18.x on a local Windows 11 workstation**.
- Separates concerns via `stage`, `mart`, `etl`, and `qa` schemas.
- Implements a clean, extensible **star schema** for EMS analytics.
- Supports incremental, idempotent ETL using **“newer wins”** logic.
- Keeps PHI out of analytics tables while preserving clinical and operational detail.
- Provides a reusable blueprint for other EMS agencies operating under state-hosted ImageTrend environments.

This design document should be kept up to date as the warehouse evolves, particularly when new facts, dimensions, or automation patterns are introduced.
