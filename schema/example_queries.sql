--- Pass rate by NDT method ---
SELECT
    method_name,
    COUNT(*) as total_inspections,
    SUM(pass_fail) as passed,
    ROUND(SUM(pass_fail) * 100.0 / COUNT(*), 1) as pass_rate_pct
FROM fact_inspections f
JOIN dim_method m ON f.method_key = m.method_key
GROUP BY method_name
ORDER BY pass_rate_pct DESC;

--- Inspector workload and pass rate ---
SELECT
    i.inspector_name,
    i.inspector_max_EN4179_level AS certification_level,
    COUNT(f.inspection_id) as total_inspections_performed,
    ROUND(SUM(f.pass_fail) * 100.0 / COUNT(*), 1) as pass_rate_pct
FROM fact_inspections f
JOIN dim_inspector i ON f.inspector_key = i.inspector_key
WHERE i.is_current = TRUE
GROUP BY i.inspector_name, i.inspector_max_EN4179_level
ORDER BY pass_rate_pct DESC;

--- Components with highest average indication length ---
SELECT
    f.component_id,
    c.component_description,
    c.component_partnumber,
    AVG(f.max_indication_length_mm) AS avg_max_indication_length
FROM fact_inspections f
JOIN dim_component c ON f.component_id = c.component_id
GROUP BY f.component_id, c.component_description, c.component_partnumber
ORDER BY avg_max_indication_length DESC;

--- Equipment due for calibration in the next 90 days ---
SELECT
    e.equipment_description,
    e.equipment_serialnumber,
    e.calibration_due,
    DATE_DIFF('day', CURRENT_DATE, e.calibration_due) AS days_until_calib_expiry
FROM dim_equipment e
WHERE e.is_current = TRUE 
AND e.calibration_due BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '90' DAY;

--- Inspections per facility per quarter ---
SELECT
    y.facility_name,
    d.year AS inspection_year,
    d.quarter AS inspection_quarter,
    COUNT(f.inspection_id) AS total_inspections
FROM fact_inspections f
JOIN dim_facility y ON f.facility_id = y.facility_id
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY y.facility_name, inspection_year, inspection_quarter
ORDER BY inspection_year, inspection_quarter, total_inspections DESC
