-- NDT Inspection Star Schema
-- DuckDB compatible version for local execution
-- Production Databricks SQL version: schema/ndt_star_schema.sql
-- Author: M.Salah


-- DIMENSION TABLES


CREATE TABLE IF NOT EXISTS dim_facility (
  facility_id       VARCHAR       NOT NULL PRIMARY KEY,
  facility_name     VARCHAR       NOT NULL,
  facility_type     VARCHAR       NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_method (
  method_key        INTEGER       PRIMARY KEY,
  method_id         VARCHAR       NOT NULL,
  method_name       VARCHAR       NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_workorder (
  workorder_id          VARCHAR   NOT NULL PRIMARY KEY,
  task_card_reference   VARCHAR   NOT NULL,
  workorder_type        VARCHAR   NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_component (
  component_id            VARCHAR   NOT NULL PRIMARY KEY,
  component_description   VARCHAR   NOT NULL,
  component_partnumber    VARCHAR   NOT NULL,
  component_serialnumber  VARCHAR   NOT NULL,
  component_material_type VARCHAR   NOT NULL,
  component_ata_chapter   VARCHAR   NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_date (
  date_id       VARCHAR   NOT NULL PRIMARY KEY,
  full_date     DATE      NOT NULL,
  day           INT       NOT NULL CHECK (day > 0 AND day <= 31),
  month         INT       NOT NULL CHECK (month > 0 AND month <= 12),
  year          INT       NOT NULL,
  quarter       INT       NOT NULL CHECK (quarter > 0 AND quarter <= 4)
);

CREATE TABLE IF NOT EXISTS dim_equipment (
  equipment_key           INTEGER   PRIMARY KEY,
  equipment_id            VARCHAR   NOT NULL,
  equipment_description   VARCHAR   NOT NULL,
  equipment_partnumber    VARCHAR   NOT NULL,
  equipment_serialnumber  VARCHAR   NOT NULL,
  calibrated_on           DATE      NOT NULL,
  calibration_due         DATE      NOT NULL,
  valid_from              DATE      NOT NULL,
  valid_to                DATE,
  is_current              BOOLEAN   NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_inspector (
  inspector_key               INTEGER   PRIMARY KEY,
  inspector_id                VARCHAR   NOT NULL,
  inspector_name              VARCHAR   NOT NULL,
  inspector_authorization_num VARCHAR   NOT NULL,
  authorization_expiry        DATE      NOT NULL,
  inspector_max_EN4179_level  INT       NOT NULL CHECK (inspector_max_EN4179_level IN (2, 3)),
  valid_from                  DATE      NOT NULL,
  valid_to                    DATE,
  is_current                  BOOLEAN   NOT NULL
);


-- FACT TABLE


CREATE TABLE IF NOT EXISTS fact_inspections (
  inspection_id             VARCHAR   NOT NULL PRIMARY KEY,
  date_id                   VARCHAR   NOT NULL REFERENCES dim_date(date_id),
  component_id              VARCHAR   NOT NULL REFERENCES dim_component(component_id),
  workorder_id              VARCHAR   NOT NULL REFERENCES dim_workorder(workorder_id),
  method_key                INTEGER   NOT NULL REFERENCES dim_method(method_key),
  equipment_key             INTEGER            REFERENCES dim_equipment(equipment_key),
  facility_id               VARCHAR   NOT NULL REFERENCES dim_facility(facility_id),
  inspector_key             INTEGER   NOT NULL REFERENCES dim_inspector(inspector_key),
  inspection_duration_min   INT       NOT NULL CHECK (inspection_duration_min > 0),
  pass_fail                 BOOLEAN   NOT NULL,
  indication_count          INT       NOT NULL CHECK (indication_count >= 0),
  max_indication_length_mm  FLOAT     NOT NULL CHECK (max_indication_length_mm >= 0),
  max_indication_width_mm   FLOAT     NOT NULL CHECK (max_indication_width_mm >= 0),
  next_inspection_due_hrs   INT       NOT NULL CHECK (next_inspection_due_hrs > 0)
);