-- get connected to the database first and schema applied
-- then run "\i test_data.sql" in psql

-- =========================
-- Test data:
-- 5 users across 5 BUs.
-- 4 risks.
-- 4 incidents at different stages.
-- 5 measures.
-- 3 KRIs + measurements.
-- Causes, controls, links all present.
-- =========================

-- roles
INSERT INTO role (name) VALUES
 ('Business Manager'), ('Ops Officer'), ('Risk Analyst'), ('HR Manager'), ('IT Admin');

-- risk categories
INSERT INTO risk_category (name) VALUES
 ('Credit Risk'), ('Operational Risk'), ('IT/System Risk'), ('Compliance Risk');

-- loss causes
INSERT INTO loss_cause (name, description) VALUES
 ('System Outage','Unplanned IT system downtime'),
 ('Human Error','Staff mistakes in processes'),
 ('External Fraud','Fraud by third parties'),
 ('Regulatory Breach','Failure to comply with regulation');

-- business units
INSERT INTO business_unit (name) VALUES
 ('Wholesale'), ('Retail'), ('Operations'), ('Risk Management'), ('IT');

-- business processes
INSERT INTO business_process (name, business_unit_id) VALUES
 ('Wholesale Lending',1),
 ('Credit Card Sales',2),
 ('Account Reconciliation',3),
 ('Incident Validation',4),
 ('Core Banking System Support',5);

-- products
INSERT INTO product (name, business_unit_id) VALUES
 ('Corporate Loans',1),
 ('Credit Cards',2),
 ('Payments',3);

-- users
INSERT INTO users (username, email, full_name, business_unit_id, role_id) VALUES
 ('jdoe','jdoe@bank.com','John Doe',1,1),      -- Business Manager, Wholesale
 ('asmith','asmith@bank.com','Alice Smith',3,2),-- Ops Officer, Operations
 ('bchan','bchan@bank.com','Brian Chan',4,3),   -- Risk Analyst, Risk Mgmt
 ('cliu','cliu@bank.com','Carol Liu',5,5),      -- IT Admin, IT
 ('dmartin','dmartin@bank.com','David Martin',2,4); -- HR Manager, Retail

-- status references for incidents and measures
INSERT INTO incident_status_ref (code,name) VALUES
 ('DRAFT','Draft'),
 ('SUBMITTED','Submitted'),
 ('VALIDATED','Validated'),
 ('CLOSED','Closed');

INSERT INTO measure_status_ref (code,name) VALUES
 ('OPEN','Open'),
 ('IN_PROGRESS','In Progress'),
 ('DONE','Done'),
 ('OVERDUE','Overdue');

-- risks
INSERT INTO risk (description, risk_category_id, business_unit_id, business_process_id, product_id,
                  inherent_likelihood, inherent_impact, residual_likelihood, residual_impact, created_by)
VALUES
 ('System downtime of core banking app',3,5,5,NULL,5,5,3,3,4),
 ('Fraudulent use of stolen credit cards',1,2,2,2,4,4,2,3,1),
 ('Incorrect reconciliations in Ops',2,3,3,3,3,3,4,2,2),
 ('Regulatory fine for missing documents',4,1,1,1,1,4,5,2,3);

-- incidents
INSERT INTO incident (title, description, start_time, discovered_time, business_unit_id, business_process_id,
                      product_id, status_id, reported_by, gross_loss_amount, currency_code, near_miss)
VALUES
 ('Core Banking Downtime','System unavailable for 2 hours', NOW() - interval '2 day', NOW() - interval '2 day',
   5,5,NULL,2,4, 50000,'USD',false),
 ('Credit Card Fraud','Stolen cards used in transactions', NOW() - interval '5 day', NOW() - interval '4 day',
   2,2,2,2,1, 20000,'USD',false),
 ('Ops Reconciliation Error','Accounts mismatched for 1 day', NOW() - interval '1 day', NOW() - interval '1 day',
   3,3,3,1,2, 0,'USD',true),
 ('Regulatory Fine','Fine due to late reporting', NOW() - interval '20 day', NOW() - interval '18 day',
   1,1,1,3,3, 100000,'EUR',false);

-- controls (just examples)
INSERT INTO control (name, description, business_process_id, created_by, effectiveness) VALUES
 ('IT Monitoring','Monitoring of core systems',5,4,3),
 ('Fraud Rules','Fraud detection rules in card system',2,1,4);

-- measures
INSERT INTO measure (description, responsible_id, deadline, status_id, created_by)
VALUES
 ('Upgrade IT monitoring tools',4, NOW() + interval '30 day',1,3),
 ('Enhance fraud detection rules',1, NOW() + interval '60 day',2,3),
 ('Ops staff training on reconciliation',2, NOW() + interval '15 day',1,3),
 ('Implement document checklist',1, NOW() + interval '20 day',1,3),
 ('Set up backup server',4, NOW() + interval '45 day',1,3);

-- KRIs
INSERT INTO key_risk_indicator (name, definition, unit, threshold_green, threshold_amber, threshold_red,
                                frequency, responsible_id, risk_id)
VALUES
 ('System Downtime (hours/month)','Cumulative downtime of core banking system','hours',2,5,10,'Monthly',4,1),
 ('Staff Turnover Rate','Monthly % turnover of Ops staff','%',5,10,20,'Monthly',5,3),
 ('Unreconciled Accounts %','Daily % of unreconciled accounts','%',1,3,5,'Daily',2,3);

-- KRI measurements
INSERT INTO kri_measurement (kri_id, period_start, period_end, value, threshold_status, comment, recorded_by)
VALUES
 (1,'2025-07-01','2025-07-31',6,'Amber','Downtime exceeded 5h due to outage',4),
 (2,'2025-07-01','2025-07-31',12,'Red','Ops attrition spike',5),
 (3,'2025-08-25','2025-08-25',2,'Amber','Daily recon delay',2);

-- link tables
INSERT INTO incident_risk VALUES
 (1,1), (2,2), (3,3), (4,4);

INSERT INTO incident_measure VALUES
 (1,1), (1,5), (2,2), (3,3), (4,4);

INSERT INTO incident_cause VALUES
 (1,1), (2,3), (3,2), (4,4);

INSERT INTO risk_control VALUES
 (1,1), (2,2);

INSERT INTO risk_measure VALUES
 (1,5), (2,2), (3,3), (4,4);
