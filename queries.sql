-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

-- !! Load test data first (in a separate file test_data.sql) !!
-- get connected to the database first and schema applied
-- then run "\i queries.sql" in psql

-- =========================
-- Example queries (using indexes, views)
-- use EXPLAIN ANALYZE to check whether indexes are used by a query
-- !!Apparently, postgresql can decide not to use indexes on small tables!!
-- (sequential scan can be cheaper than touching any index for small tables)
-- =========================

-- find all active incidents in IT unit (idx_incident_bu, view active_incident)
SELECT id, title, status_id, gross_loss_amount
FROM active_incident
WHERE business_unit_id = (
    SELECT business_unit_id FROM business_unit
    WHERE name = 'IT'
);

-- risks by business process with residual ratings (idx_risk_process)
SELECT r.id, r.description, bp.name AS process, r.residual_likelihood, r.residual_impact
FROM risk r
JOIN business_process bp ON r.business_process_id = bp.business_process_id
ORDER BY r.residual_impact DESC;

-- KRIs breaching thresholds (idx_kri_breach_lookup, for big tables only!)
SELECT k.name, m.value, m.threshold_status, m.period_start, m.period_end
FROM kri_measurement m
JOIN key_risk_indicator k ON m.kri_id = k.id
WHERE m.threshold_status <> 'Green';

-- KRI measurements in range (idx_kri_period)
SELECT kri_id, period_start, period_end, value, threshold_status
FROM kri_measurement
WHERE kri_id = 1
  AND period_start >= '2025-07-01'
  AND period_end <= '2025-07-31';

-- incidents by status (idx_incident_status)
SELECT id, title, reported_by, status_id
FROM incident
WHERE status_id = (
    SELECT status_id FROM incident_status_ref 
    WHERE code='VALIDATED'
);

-- incidents discovered in date range (idx_incident_dates) 
SELECT id, title, discovered_time, registered_time
FROM incident
WHERE discovered_time BETWEEN '2025-08-01' AND '2025-08-31';

-- risks by business unit (idx_risk_bu)
SELECT id, description, inherent_likelihood, inherent_impact
FROM risk
WHERE business_unit_id = (
    SELECT business_unit_id FROM business_unit
    WHERE name = 'Operations'
);

-- measures assigned to user and status (idx_measure_assignee)
SELECT id, description, status_id
FROM measure
WHERE responsible_id = (
    SELECT id FROM users
    WHERE username = 'cliu'
)
AND status_id = (
    SELECT status_id FROM measure_status_ref 
    WHERE code='OPEN'
);

-- =========================
-- Workflow updates
-- =========================

-- get details on incident #1
SELECT i.title, s.code 
FROM incident i
JOIN incident_status_ref s ON i.status_id = s.status_id
WHERE i.id = 1;

-- move incident #1 from SUBMITTED → VALIDATED
UPDATE incident
SET status_id = (SELECT status_id FROM incident_status_ref WHERE code='VALIDATED'),
    validated_by = 3,
    validated_at = NOW()
WHERE id = 1;

-- get details on measure #1
SELECT m.description, s.code, m.closed_at, m.closure_comment
FROM measure m
JOIN measure_status_ref s ON m.status_id = s.status_id
WHERE m.id = 1;

-- close measure #1 as done
UPDATE measure
SET status_id = (SELECT status_id FROM measure_status_ref WHERE code='DONE'),
    closed_at = NOW(),
    closure_comment = 'Completed successfully'
WHERE id = 1;

-- =========================
-- Soft delete
-- =========================

-- get details on incident #3, re-run after deletion
-- to get proper deleted_by you need to set "SET audit.user_id = ...;" in your session
SELECT i.title, s.code, i.deleted_at, i.deleted_by
FROM incident i
JOIN incident_status_ref s ON i.status_id = s.status_id
WHERE i.id = 3;

-- soft delete incident #3 (will set deleted_at & deleted_by via trigger)
-- you'll see DELETE 0 as the output in psql meaning no real deletion
DELETE FROM incident WHERE id = 3;

-- verify it's excluded from the view
SELECT * FROM active_incident;