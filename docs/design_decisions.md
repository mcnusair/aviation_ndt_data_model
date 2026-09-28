# Design Decisions: NDT Inspection Star Schema

This document explains the key modeling choices made in the NDT inspection star schema. It is intended for anyone maintaining or extending this model.

---

## 1. Star schema over snowflake

The model uses a star schema with flat, denormalized dimension tables. A snowflake schema would normalize dimensions further, splitting facility type into its own table, or ATA chapter into a hierarchy, but the added joins hurt query performance with no meaningful benefit at this data volume. Analytical queries on inspection data need to be fast, and the star schema achieves that by keeping everything a single join away from the fact table.

---

## 2. Surrogate keys vs natural keys

Not every dimension gets a surrogate key. The choice depends on whether the dimension needs SCD2 versioning.

`dim_inspector` and `dim_equipment` use surrogate keys (`inspector_key`, `equipment_key`) because both change over time and need row versioning. The fact table must point to the exact version of the inspector or equipment that existed at the time of the inspection, not the current state.

`dim_facility`, `dim_component`, `dim_workorder`, and `dim_method` use natural keys because they are stable. A facility ID, component serial number, work order ID, and method code do not change in the source MRO system. A surrogate key would add complexity with no benefit.

---

## 3. SCD Type 2 on dim_inspector

Inspector certifications expire and get renewed. An inspector can also be upgraded from Level 2 to Level 3. The model needs to answer the question: what was this inspector's certification level at the time of this specific inspection? Overwriting the current row (SCD1) would lose that information. Each time a certification changes, a new row is inserted with updated `valid_from`, `valid_to`, and `is_current` fields. The fact table joins on `inspector_key`, which points to the exact version.

---

## 4. SCD Type 2 on dim_equipment

Calibration is not a fixed attribute of a piece of equipment. It changes on a regular cycle. If a calibration is found to have been out of date during a past inspection, the data must reflect what the calibration status actually was at that time, not what it is today. The same versioning pattern as `dim_inspector` applies here.

---

## 5. equipment_key is nullable in fact_inspections

Several NDT methods do not use calibrated equipment with a traceable serial number. Liquid penetrant (PT) and visual inspection (VT) rely on consumables and trained human judgment. Forcing a non-null equipment reference for these inspections would either produce dummy records in `dim_equipment` or require a separate fact table per method. A nullable foreign key is the correct and honest representation of the real-world process.

---

## 6. Inspector level restricted to 2 and 3

Per EN4179 and NAS410, only Level 2 and Level 3 personnel are authorized to independently perform and certify NDT inspections. Level 1 inspectors work under direct supervision and cannot sign off a task card. The check constraint reflects regulatory requirements, not a modeling preference. Any attempt to insert a Level 1 inspector as a certifying inspector is a data quality violation and should be rejected at the database level.

---

## 7. Max indication stored rather than individual indications

A single inspection can produce multiple indications. Storing each individual indication as a separate row in the fact table would make aggregation complex and would change the grain of the table from one row per inspection to one row per indication. The maximum indication dimensions are stored in the fact table because they drive the accept/reject decision. The full list of indications belongs in the inspection report, which is a document attached to the work order in the MRO system, not in the dimensional model.

---

## 8. next_inspection_due_hrs > 0 constraint

A component that passes inspection always gets a next inspection interval assigned, defined by the applicable Structural Inspection Document or Airworthiness Directive. A value of zero would imply immediate re-inspection, which is not a valid outcome of a passing inspection. The constraint prevents bad data from entering the model. A failing inspection that grounds the component would be handled through the work order system, not through a zero interval here.