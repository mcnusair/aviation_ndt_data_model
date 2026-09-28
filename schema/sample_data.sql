
-- NDT Inspection Star Schema: Sample Data
-- Realistic aviation NDT inspection records for demonstration and testing




-- dim_facility


INSERT INTO dim_facility (facility_id, facility_name, facility_type) VALUES
('FAC-001', 'Hangar 4 — Line Maintenance',     'Line'),
('FAC-002', 'NDT Workshop — Base Maintenance',  'Shop'),
('FAC-003', 'Engine Overhaul Bay',              'Shop'),
('FAC-004', 'AOG Support Unit — Ramp',          'AOG');



-- dim_method
-- Explicit keys required for DuckDB, referenced by subqueries in fact_inspections


INSERT INTO dim_method (method_key, method_id, method_name) VALUES
(1, 'UT', 'Ultrasonic Testing'),
(2, 'ET', 'Eddy Current Testing'),
(3, 'PT', 'Liquid Penetrant Testing'),
(4, 'MT', 'Magnetic Particle Testing'),
(5, 'RT', 'Radiographic Testing'),
(6, 'VT', 'Visual Testing');



-- dim_workorder


INSERT INTO dim_workorder (workorder_id, task_card_reference, workorder_type) VALUES
('WO-2024-0891', 'TC-A320-57-10-001', 'Scheduled'),
('WO-2024-0892', 'TC-A320-32-41-003', 'Scheduled'),
('WO-2024-1143', 'TC-B737-53-10-007', 'Unscheduled'),
('WO-2024-1144', 'TC-B737-27-11-002', 'AOG'),
('WO-2024-1201', 'TC-A320-71-00-001', 'Scheduled');



-- dim_component


INSERT INTO dim_component (
  component_id, component_description, component_partnumber,
  component_serialnumber, component_material_type, component_ata_chapter
) VALUES
('COMP-001', 'Wing Front Spar Lower Cap',       'A320-57-1234-01', 'SN-78821A', 'Aluminium Alloy 7075-T6',  'ATA 57'),
('COMP-002', 'Main Landing Gear Drag Strut',     'A320-32-5521-02', 'SN-44302B', 'High Strength Steel 300M',  'ATA 32'),
('COMP-003', 'Fuselage Frame Station 663',       'B737-53-8812-01', 'SN-99011C', 'Aluminium Alloy 2024-T3',  'ATA 53'),
('COMP-004', 'Elevator Trailing Edge Skin',      'B737-27-3301-04', 'SN-22187D', 'Carbon Fibre Composite',    'ATA 27'),
('COMP-005', 'CFM56-5B Fan Blade',               'CFM-71-0012-00',  'SN-10045E', 'Titanium Alloy Ti-6Al-4V', 'ATA 71');



-- dim_date


INSERT INTO dim_date (date_id, full_date, day, month, year, quarter) VALUES
('2024-03-04', '2024-03-04', 4,  3, 2024, 1),
('2024-03-11', '2024-03-11', 11, 3, 2024, 1),
('2024-06-22', '2024-06-22', 22, 6, 2024, 2),
('2024-07-01', '2024-07-01', 1,  7, 2024, 3),
('2024-09-15', '2024-09-15', 15, 9, 2024, 3);



-- dim_equipment
-- Explicit keys required for DuckDB
-- equipment_key 1 appears twice: current and expired calibration (SCD2)


INSERT INTO dim_equipment (
  equipment_key, equipment_id, equipment_description, equipment_partnumber,
  equipment_serialnumber, calibrated_on, calibration_due,
  valid_from, valid_to, is_current
) VALUES
(1, 'EQ-001', 'Olympus EPOCH 650 UT Flaw Detector',          'EPOCH-650', 'SN-OLY-44821', '2024-01-10', '2024-07-10', '2024-01-10', NULL,         TRUE),
(2, 'EQ-001', 'Olympus EPOCH 650 UT Flaw Detector',          'EPOCH-650', 'SN-OLY-44821', '2023-07-10', '2024-01-10', '2023-07-10', '2024-01-10', FALSE),
(3, 'EQ-002', 'Zetec MIZ-21C Eddy Current Instrument',       'MIZ-21C',   'SN-ZTC-88120', '2024-02-01', '2024-08-01', '2024-02-01', NULL,         TRUE),
(4, 'EQ-003', 'Carestream HPX-1 Digital Radiography System', 'HPX-1',     'SN-CRS-30041', '2024-03-01', '2025-03-01', '2024-03-01', NULL,         TRUE);



-- dim_inspector
-- Explicit keys required for DuckDB
-- INS-002 Rashid Al-Farsi appears twice: upgraded from Level 2 to Level 3 (SCD2)


INSERT INTO dim_inspector (
  inspector_key, inspector_id, inspector_name, inspector_authorization_num,
  authorization_expiry, inspector_max_EN4179_level,
  valid_from, valid_to, is_current
) VALUES
(1, 'INS-001', 'James Whitfield',  'AUTH-EN4179-UK-00441', '2026-05-01', 3, '2022-05-01', NULL,         TRUE),
(2, 'INS-002', 'Rashid Al-Farsi', 'AUTH-EN4179-AE-00782', '2025-09-15', 2, '2021-09-15', '2024-06-01', FALSE),
(3, 'INS-002', 'Rashid Al-Farsi', 'AUTH-EN4179-AE-00782', '2027-06-01', 3, '2024-06-01', NULL,         TRUE),
(4, 'INS-003', 'Sofia Marchetti', 'AUTH-EN4179-IT-01123', '2025-11-30', 2, '2023-11-30', NULL,         TRUE);



-- fact_inspections


-- 1. UT inspection of wing spar: pass, minor indication
INSERT INTO fact_inspections (
  inspection_id, date_id, component_id, workorder_id,
  method_key, equipment_key, facility_id, inspector_key,
  inspection_duration_min, pass_fail, indication_count,
  max_indication_length_mm, max_indication_width_mm, next_inspection_due_hrs
) VALUES
('INSP-2024-0001', '2024-03-04', 'COMP-001', 'WO-2024-0891', 1, 1, 'FAC-002', 1, 95,  TRUE,  1, 3.2,  0.8, 3000);

-- 2. ET inspection of landing gear drag strut: pass, no indications
-- Uses Rashid at Level 2 (inspector_key=2, before his upgrade)
INSERT INTO fact_inspections (
  inspection_id, date_id, component_id, workorder_id,
  method_key, equipment_key, facility_id, inspector_key,
  inspection_duration_min, pass_fail, indication_count,
  max_indication_length_mm, max_indication_width_mm, next_inspection_due_hrs
) VALUES
('INSP-2024-0002', '2024-03-11', 'COMP-002', 'WO-2024-0892', 2, 3, 'FAC-001', 2, 60,  TRUE,  0, 0.0,  0.0, 4000);

-- 3. PT inspection of fuselage frame: FAIL, crack found
-- PT uses no calibrated equipment: equipment_key is NULL
INSERT INTO fact_inspections (
  inspection_id, date_id, component_id, workorder_id,
  method_key, equipment_key, facility_id, inspector_key,
  inspection_duration_min, pass_fail, indication_count,
  max_indication_length_mm, max_indication_width_mm, next_inspection_due_hrs
) VALUES
('INSP-2024-0003', '2024-06-22', 'COMP-003', 'WO-2024-1143', 3, NULL, 'FAC-002', 4, 45,  FALSE, 2, 12.5, 1.1, 500);

-- 4. VT inspection of elevator skin: pass, no indications
-- VT uses no calibrated equipment: equipment_key is NULL
INSERT INTO fact_inspections (
  inspection_id, date_id, component_id, workorder_id,
  method_key, equipment_key, facility_id, inspector_key,
  inspection_duration_min, pass_fail, indication_count,
  max_indication_length_mm, max_indication_width_mm, next_inspection_due_hrs
) VALUES
('INSP-2024-0004', '2024-07-01', 'COMP-004', 'WO-2024-1144', 6, NULL, 'FAC-004', 1, 30,  TRUE,  0, 0.0,  0.0, 2000);

-- 5. RT inspection of CFM56 fan blade: pass, no indications
INSERT INTO fact_inspections (
  inspection_id, date_id, component_id, workorder_id,
  method_key, equipment_key, facility_id, inspector_key,
  inspection_duration_min, pass_fail, indication_count,
  max_indication_length_mm, max_indication_width_mm, next_inspection_due_hrs
) VALUES
('INSP-2024-0005', '2024-09-15', 'COMP-005', 'WO-2024-1201', 5, 4, 'FAC-003', 3, 120, TRUE,  0, 0.0,  0.0, 6000);