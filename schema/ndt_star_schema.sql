
-- NDT Inspection Star Schema
-- Databricks SQL / Spark SQL compatible
-- Author: M.Salah
-- Description: Dimensional model for aviation NDT inspection data
--              covering inspectors, components, equipment, work orders,
--              facilities, methods, and inspection outcomes.



-- -----------------------------------------------------------------------------
-- DIMENSION TABLES
-- -----------------------------------------------------------------------------

-- Facilities where NDT inspections are performed

CREATE TABLE IF NOT EXISTS dim_facility (
  facility_id       STRING        NOT NULL,
  facility_name     STRING        NOT NULL,
  facility_type     STRING        NOT NULL,  
  CONSTRAINT pk_facility PRIMARY KEY (facility_id)
);

-- NDT methods used during inspections

CREATE TABLE IF NOT EXISTS dim_method (
  method_key        BIGINT        GENERATED ALWAYS AS IDENTITY,
  method_id         STRING        NOT NULL,
  method_name       STRING        NOT NULL,  
  CONSTRAINT pk_method PRIMARY KEY (method_key)
);

-- Work orders that trigger NDT inspections

CREATE TABLE IF NOT EXISTS dim_workorder (
  workorder_id          STRING    NOT NULL,
  task_card_reference   STRING    NOT NULL,
  workorder_type        STRING    NOT NULL,  
  CONSTRAINT pk_workorder PRIMARY KEY (workorder_id)
);

-- Aircraft components subject to NDT inspection
-- Natural key used: component_id is stable from the source MRO system

CREATE TABLE IF NOT EXISTS dim_component (
  component_id            STRING    NOT NULL,
  component_description   STRING    NOT NULL,
  component_partnumber    STRING    NOT NULL,
  component_serialnumber  STRING    NOT NULL,
  component_material_type STRING    NOT NULL,
  component_ata_chapter   STRING    NOT NULL,
  CONSTRAINT pk_component PRIMARY KEY (component_id)
);

-- Date dimension for time-based analysis

CREATE TABLE IF NOT EXISTS dim_date (
  date_id       STRING    NOT NULL,
  full_date     DATE      NOT NULL,
  day           INT       NOT NULL,
  month         INT       NOT NULL,
  year          INT       NOT NULL,
  quarter       INT       NOT NULL,
  CONSTRAINT pk_date      PRIMARY KEY (date_id),
  CONSTRAINT chk_day      CHECK (day > 0 AND day <= 31),
  CONSTRAINT chk_month    CHECK (month > 0 AND month <= 12),
  CONSTRAINT chk_quarter  CHECK (quarter > 0 AND quarter <= 4)
);

-- NDT equipment used during inspections
-- SCD2: calibration status changes over time
-- Surrogate key used to version rows when calibration is renewed

CREATE TABLE IF NOT EXISTS dim_equipment (
  equipment_key           BIGINT    GENERATED ALWAYS AS IDENTITY,
  equipment_id            STRING    NOT NULL,
  equipment_description   STRING    NOT NULL,
  equipment_partnumber    STRING    NOT NULL,
  equipment_serialnumber  STRING    NOT NULL,
  calibrated_on           DATE      NOT NULL,
  calibration_due         DATE      NOT NULL,
  valid_from              DATE      NOT NULL,
  valid_to                DATE,
  is_current              BOOLEAN   NOT NULL,
  CONSTRAINT pk_equipment PRIMARY KEY (equipment_key)
);

-- NDT inspectors performing and certifying inspections
-- SCD2: authorization level and expiry change over time
-- Surrogate key used to version rows when certification is renewed or upgraded

CREATE TABLE IF NOT EXISTS dim_inspector (
  inspector_key               BIGINT    GENERATED ALWAYS AS IDENTITY,
  inspector_id                STRING    NOT NULL,
  inspector_name              STRING    NOT NULL,
  inspector_authorization_num STRING    NOT NULL,
  authorization_expiry        DATE      NOT NULL,
  inspector_max_EN4179_level  INT       NOT NULL,
  valid_from                  DATE      NOT NULL,
  valid_to                    DATE,
  is_current                  BOOLEAN   NOT NULL,
  CONSTRAINT pk_inspector     PRIMARY KEY (inspector_key),
  CONSTRAINT chk_level        CHECK (inspector_max_EN4179_level IN (2, 3))
);


-- -----------------------------------------------------------------------------
-- FACT TABLE
-- -----------------------------------------------------------------------------

-- One row per NDT inspection event
-- equipment_key is nullable: some methods (PT, VT) use consumables not equipment

CREATE TABLE IF NOT EXISTS fact_inspections (
  inspection_id             STRING    NOT NULL,
  date_id                   STRING    NOT NULL,
  component_id              STRING    NOT NULL,
  workorder_id              STRING    NOT NULL,
  method_key                BIGINT    NOT NULL,
  equipment_key             BIGINT,
  facility_id               STRING    NOT NULL,
  inspector_key             BIGINT    NOT NULL,

  -- Measurable outcomes
  inspection_duration_min   INT       NOT NULL,
  pass_fail                 BOOLEAN   NOT NULL,
  indication_count          INT       NOT NULL,
  max_indication_length_mm  FLOAT     NOT NULL,
  max_indication_width_mm   FLOAT     NOT NULL,
  next_inspection_due_hrs   INT       NOT NULL,

  -- Constraints
  CONSTRAINT pk_inspection      PRIMARY KEY (inspection_id),
  CONSTRAINT fk_date            FOREIGN KEY (date_id)       REFERENCES dim_date (date_id),
  CONSTRAINT fk_component       FOREIGN KEY (component_id)  REFERENCES dim_component (component_id),
  CONSTRAINT fk_workorder       FOREIGN KEY (workorder_id)  REFERENCES dim_workorder (workorder_id),
  CONSTRAINT fk_method          FOREIGN KEY (method_key)    REFERENCES dim_method (method_key),
  CONSTRAINT fk_equipment       FOREIGN KEY (equipment_key) REFERENCES dim_equipment (equipment_key),
  CONSTRAINT fk_facility        FOREIGN KEY (facility_id)   REFERENCES dim_facility (facility_id),
  CONSTRAINT fk_inspector       FOREIGN KEY (inspector_key) REFERENCES dim_inspector (inspector_key),
  CONSTRAINT chk_duration       CHECK (inspection_duration_min > 0),
  CONSTRAINT chk_indications    CHECK (indication_count >= 0),
  CONSTRAINT chk_length         CHECK (max_indication_length_mm >= 0),
  CONSTRAINT chk_width          CHECK (max_indication_width_mm >= 0),
  CONSTRAINT chk_next_insp      CHECK (next_inspection_due_hrs > 0)
);