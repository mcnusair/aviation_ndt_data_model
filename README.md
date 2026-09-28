# NDT Inspection Data Model
 
A dimensional data model for aviation Non-Destructive Testing (NDT) inspection data, designed for deployment on Azure Databricks. The model follows Kimball star schema principles and is built around the core business event in any MRO environment: an NDT inspection performed on an aircraft component under a work order.
 
The repository includes the production DDL in Databricks SQL, a DuckDB-compatible version for local execution and testing, realistic sample data drawn from real MRO inspection records, five analytical queries, and a full set of design decision notes explaining every modeling choice.
 
---
 
## Background
 
Every NDT inspection in an MRO environment produces a structured record covering what was inspected, who inspected it, what method and equipment were used, where the inspection took place, and what was found. Regulatory frameworks (EASA Part 145, EN4179, NAS410) require this data to be traceable and auditable, which means the model must preserve historical states rather than overwrite them.
 
The two SCD Type 2 dimensions are `dim_inspector` and `dim_equipment`. Inspector certifications change when authorizations are renewed or upgraded. Equipment goes through calibration cycles. The model preserves the exact state of both at the time of each inspection, which is essential for audit and regulatory traceability.
 
---
 
## Star schema
 
```
                    ┌─────────────────┐
                    │   dim_date      │
                    │─────────────────│
                    │ date_id (PK)    │
                    │ full_date       │
                    │ day             │
                    │ month           │
                    │ year            │
                    │ quarter         │
                    └────────┬────────┘
                             │
┌──────────────────┐         │         ┌──────────────────┐
│  dim_facility    │         │         │  dim_workorder   │
│──────────────────│         │         │──────────────────│
│ facility_id (PK) │         │         │ workorder_id(PK) │
│ facility_name    │         │         │ task_card_ref    │
│ facility_type    │         │         │ workorder_type   │
└────────┬─────────┘         │         └────────┬─────────┘
         │                   │                  │
         │      ┌────────────▼──────────────┐   │
         │      │      fact_inspections     │   │
         └─────►│───────────────────────────│◄──┘
                │ inspection_id (PK)        │
                │ date_id (FK)              │
                │ component_id (FK)         │
                │ workorder_id (FK)         │◄──────────────────────┐
                │ method_key (FK)           │                       │
                │ equipment_key (FK, null)  │◄───────────┐          │
                │ facility_id (FK)          │            │          │
                │ inspector_key (FK)        │◄──────┐    │          │
                │ inspection_duration_min   │       │    │          │
                │ pass_fail                 │       │    │          │
                │ indication_count          │       │    │          │
                │ max_indication_length_mm  │       │    │          │
                │ max_indication_width_mm   │       │    │          │
                │ next_inspection_due_hrs   │       │    │          │
                └────────────┬──────────────┘       │    │          │
                             │                      │    │          │
              ┌──────────────▼───────────┐          │    │    ┌─────┴────────────┐
              │     dim_component        │          │    │    │   dim_method     │
              │──────────────────────────│          │    │    │──────────────────│
              │ component_id (PK)        │          │    │    │ method_key (PK)  │
              │ component_description    │          │    │    │ method_id        │
              │ component_partnumber     │          │    │    │ method_name      │
              │ component_serialnumber   │          │    │    └──────────────────┘
              │ component_material_type  │          │    │
              │ component_ata_chapter    │          │    │
              └──────────────────────────┘          │    │
                                                    │    │
                    ┌───────────────────────────────┘    │
                    │                                    │
         ┌──────────▼──────────────────┐    ┌───────────┴──────────────────┐
         │     dim_inspector (SCD2)    │    │     dim_equipment (SCD2)     │
         │─────────────────────────────│    │──────────────────────────────│
         │ inspector_key (PK)          │    │ equipment_key (PK)           │
         │ inspector_id                │    │ equipment_id                 │
         │ inspector_name              │    │ equipment_description        │
         │ inspector_authorization_num │    │ equipment_partnumber         │
         │ authorization_expiry        │    │ equipment_serialnumber       │
         │ inspector_max_EN4179_level  │    │ calibrated_on                │
         │ valid_from                  │    │ calibration_due              │
         │ valid_to                    │    │ valid_from                   │
         │ is_current                  │    │ valid_to                     │
         └─────────────────────────────┘    │ is_current                   │
                                            └──────────────────────────────┘
```
 
---
 
## Repository structure
 
```
ndt-data-model/
    schema/
        ndt_star_schema.sql           production DDL, Databricks SQL compatible
        ndt_star_schema_duckdb.sql    simplified DDL for local DuckDB execution
        sample_data.sql               realistic aviation NDT inspection records
        example_queries.sql           five analytical queries with comments
    src/
        setup_db.py                   creates and populates the local DuckDB database
        run_queries.py                runs all five analytical queries against ndt.db
    docs/
        design_decisions.md           explains every modeling choice in plain English
    requirements.txt
    README.md
```
 
---
 
## Setup
 
**1. Clone the repo**
 
```bash
git clone https://github.com/mcnusair/ndt-data-model.git
cd ndt-data-model
```
 
**2. Create and activate a virtual environment**
 
```bash
python3 -m venv .venv
source .venv/bin/activate
```
 
**3. Install dependencies**
 
```bash
pip install -r requirements.txt
```
 
---
 
## How to run
 
**Set up the local database (run once)**
 
```bash
python src/setup_db.py
```
 
This creates `ndt.db`, drops and recreates all tables, and loads the sample data. Run it again any time you want to reset to a clean state.
 
**Run the analytical queries**
 
```bash
python src/run_queries.py
```
 
This connects to the existing `ndt.db` and prints the results of all five queries to the terminal.
 
---
 
## Analytical queries
 
The five queries in `schema/example_queries.sql` and `src/run_queries.py` answer the following business questions:
 
| Query | Business question |
|-------|------------------|
| 1 | Which NDT methods have the highest failure rates? |
| 2 | How many inspections did each inspector perform and what was their pass rate? |
| 3 | Which components had the highest average indication length across all inspections? |
| 4 | Which equipment has calibration expiring within the next 90 days? |
| 5 | How many inspections were performed at each facility per quarter? |
 
**Sample output — Query 1: Pass rate by NDT method**
 
```
              method_name  total_inspections  passed  pass_rate_pct
 Eddy Current Testing                     1     1.0          100.0
   Ultrasonic Testing                     1     1.0          100.0
       Visual Testing                     1     1.0          100.0
 Radiographic Testing                     1     1.0          100.0
Liquid Penetrant Testing                  1     0.0            0.0
```
 
**Sample output — Query 2: Inspector workload and performance**
 
```
     inspector_name  certification_level  total_inspections  pass_rate_pct
    James Whitfield                    3                  2          100.0
    Rashid Al-Farsi                    3                  1          100.0
    Sofia Marchetti                    2                  1            0.0
```
 
---
 
## Data dictionary
 
### fact_inspections
 
One row per NDT inspection event.
 
| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| inspection_id | STRING | No | Unique inspection identifier |
| date_id | STRING | No | FK to dim_date |
| component_id | STRING | No | FK to dim_component |
| workorder_id | STRING | No | FK to dim_workorder |
| method_key | BIGINT | No | FK to dim_method |
| equipment_key | BIGINT | Yes | FK to dim_equipment. Null for PT and VT methods |
| facility_id | STRING | No | FK to dim_facility |
| inspector_key | BIGINT | No | FK to dim_inspector |
| inspection_duration_min | INT | No | Time taken to complete the inspection in minutes |
| pass_fail | BOOLEAN | No | True if component meets acceptance criteria |
| indication_count | INT | No | Number of indications found. Zero for clean inspections |
| max_indication_length_mm | FLOAT | No | Length of the largest indication in mm |
| max_indication_width_mm | FLOAT | No | Width of the largest indication in mm |
| next_inspection_due_hrs | INT | No | Flight hours until the next required inspection |
 
### dim_inspector (SCD2)
 
One row per inspector per certification version.
 
| Column | Type | Description |
|--------|------|-------------|
| inspector_key | BIGINT | Surrogate key |
| inspector_id | STRING | Natural key from the source HR system |
| inspector_name | STRING | Full name |
| inspector_authorization_num | STRING | Regulatory authorization reference |
| authorization_expiry | DATE | Certification expiry date |
| inspector_max_EN4179_level | INT | Level 2 or 3 only |
| valid_from | DATE | Start of this version |
| valid_to | DATE | End of this version. Null if current |
| is_current | BOOLEAN | True for the active version |
 
### dim_equipment (SCD2)
 
One row per equipment calibration cycle.
 
| Column | Type | Description |
|--------|------|-------------|
| equipment_key | BIGINT | Surrogate key |
| equipment_id | STRING | Natural key from the source asset register |
| equipment_description | STRING | Make and model |
| equipment_partnumber | STRING | Manufacturer part number |
| equipment_serialnumber | STRING | Manufacturer serial number |
| calibrated_on | DATE | Date of last calibration |
| calibration_due | DATE | Date calibration expires |
| valid_from | DATE | Start of this calibration version |
| valid_to | DATE | End of this version. Null if current |
| is_current | BOOLEAN | True for the active calibration record |
 
---
 
## Production deployment
 
The production DDL in `schema/ndt_star_schema.sql` targets Databricks SQL and Spark SQL. It uses `BIGINT GENERATED ALWAYS AS IDENTITY` for surrogate keys, named `CONSTRAINT` syntax for all primary keys, foreign keys, and check constraints, and `STRING` as the character type.
 
The DuckDB version in `schema/ndt_star_schema_duckdb.sql` is a simplified equivalent for local development and testing. The two files represent the same logical model with syntax adapted to each engine.
 
To deploy to Databricks, run `ndt_star_schema.sql` in a Databricks SQL notebook or via the Databricks CLI against your target catalog and schema in Unity Catalog.
 
---
 
## Design decisions
 
All modeling choices are documented in `docs/design_decisions.md`, covering the choice of star over snowflake schema, the surrogate key strategy, SCD Type 2 on inspectors and equipment, the nullable equipment key, the EN4179 level constraint, and the grain of the fact table.
 
---
 
## Stack
 
| Tool | Purpose |
|------|---------|
| Databricks SQL | Production target for the DDL |
| DuckDB | Local execution and query testing |
| Python | Database setup and query runner |
| pandas | DataFrame output for query results |