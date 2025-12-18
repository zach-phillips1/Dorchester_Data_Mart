# Case Study: Diltiazem Supply Disruption and Metoprolol Stocking Decision
## Background

The manufacturer of the powdered (reconstituted) form of diltiazem discontinued production, creating a supply disruption for EMS agencies. In response, MIEMSS and the State Medical Director evaluated protocol-approved alternatives, including metoprolol.

While vial diltiazem remains available, it introduces operational challenges:
- Requires refrigeration, or
- Carries a 30-day expiration if stored unrefrigerated

To inform medication stocking decisions and reduce unnecessary logistical burden, Dorchester EMS performed a rapid review of historical medication utilization using its internal analytics platform, ems_mart.

---

## Data Source

Analysis was performed using the Dorchester EMS Data Mart (ems_mart), populated from ImageTrend eMeds medication administration records covering the first 11 months of 2025.

Relevant tables:
- mart.fact_medication (medication administrations)
- mart.dim_medication (normalized medication reference data)

The data mart structure allows medication usage to be queried directly without manual chart review or ad-hoc report building.

---

## Query Used

To determine recent utilization of diltiazem, the following SQL query was executed:

```{sql}
SELECT
  COUNT(*) AS diltiazem_admin_events
FROM mart.fact_medication fm
WHERE fm.medication_key = 16
  AND fm.med_admin_date_time >= (CURRENT_DATE - INTERVAL '1 year');
```

This query was executed in seconds and required no additional data cleaning or reconciliation.

---

## Results

- Total diltiazem administrations in the past 12 months: 7
- Utilization pattern: Very low annual utilization across the system

These results indicate that diltiazem is used infrequently and primarily for select, high-acuity cases.

---

## Stocking Analysis
Protocol Dosing
- Metoprolol: 5 mg IV
- Repeat dose: One additional 5 mg if indicated
- Maximum dose per patient: 10 mg

Supplier Packaging and Cost
- Supplied as 5 mg / 5 mL vials
- 10 vials per box
- Approximate cost: $24 per box

Proposed Stocking Plan
- 3 boxes total (30 vials)
- Distributed across 5 ALS units
- Provides:
    - 30 single-dose administrations, or
    - 15 full maximum-dose treatments

Based on historical usage (7 administrations/year), this stocking level provides a substantial operational buffer while minimizing waste, refrigeration requirements, and expiration risk.

---

## Conclusion

Historical medication utilization data supports transitioning primary rate-control stocking away from refrigerated diltiazem as existing powdered stock expires and toward metoprolol. This approach:
- Aligns with state-level protocol guidance
- Reduces cold-chain and expiration management
- Uses objective, system-wide utilization data to inform purchasing decisions
- Maintains appropriate clinical capability for infrequent but high-acuity cases

This case study highlights how ems_mart enables rapid, defensible, data-driven decision-making to support clinical operations, logistics, and fiscal stewardship without delaying care or adding administrative burden.