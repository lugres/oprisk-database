-- v0_7_simplified
-- added:
-- 1) a clear status (“Draft”, “Submitted”, “Validated”, “Closed”) + validated_by, validated_at. 
-- 2) gross_loss_amount, recovery_amount, net_loss_amount (calculated manually by risk team). 
-- plus some minor adjustments and enhancements

-- for testing environment only! Backup data if needed!
--DROP DATABASE IF EXISTS oprisk;
--CREATE DATABASE oprisk;
-- then use "\c oprisk" and "\i schema.sql" in psql 
-- to connect to the database and get schema created 

-- =========================
-- Reference Tables
-- =========================

CREATE TABLE role (
    role_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE risk_category (
    risk_category_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE loss_cause (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT
);

CREATE TABLE business_unit (
    business_unit_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    parent_id INT REFERENCES business_unit(business_unit_id) ON DELETE SET NULL
);

CREATE TABLE business_process (
    business_process_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    parent_id INT REFERENCES business_process(business_process_id) ON DELETE SET NULL,
    business_unit_id INT REFERENCES business_unit(business_unit_id) ON DELETE SET NULL
);

CREATE TABLE product (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    business_unit_id INT REFERENCES business_unit(business_unit_id) ON DELETE SET NULL
);

-- =========================
-- Core Tables
-- =========================

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    business_unit_id INT REFERENCES business_unit(business_unit_id) ON DELETE SET NULL,
    role_id INT REFERENCES role(role_id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- status reference tables to ensure correct workflow
CREATE TABLE incident_status_ref (
  status_id SERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,     -- e.g., 'DRAFT','SUBMITTED','VALIDATED','CLOSED'
  name VARCHAR(100) NOT NULL
);

CREATE TABLE measure_status_ref (
  status_id SERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,     -- e.g., 'OPEN','IN_PROGRESS','DONE','OVERDUE','CANCELLED'
  name VARCHAR(100) NOT NULL
);

CREATE TABLE risk (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    risk_category_id INT REFERENCES risk_category(risk_category_id),
    business_unit_id INT REFERENCES business_unit(business_unit_id),
    business_process_id INT REFERENCES business_process(business_process_id),
    product_id INT REFERENCES product(product_id),
    inherent_likelihood SMALLINT, -- e.g. 1–5
    inherent_impact SMALLINT,
    residual_likelihood SMALLINT,
    residual_impact SMALLINT,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT chk_risk_likelihood_values CHECK (inherent_likelihood BETWEEN 1 AND 5 AND residual_likelihood BETWEEN 1 AND 5),
    CONSTRAINT chk_risk_impact_values CHECK (inherent_impact BETWEEN 1 AND 5 AND residual_impact BETWEEN 1 AND 5)
);

-- indexes for possible typical queries
CREATE INDEX idx_risk_bu ON risk(business_unit_id);
CREATE INDEX idx_risk_process ON risk(business_process_id);
-- CREATE INDEX idx_risk_product ON risk(product_id);

CREATE TABLE incident (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    description TEXT NOT NULL,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    discovered_time TIMESTAMP,
    registered_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    --internal ownership
    business_unit_id INT REFERENCES business_unit(business_unit_id),
    business_process_id INT REFERENCES business_process(business_process_id),
    product_id INT REFERENCES product(product_id),

    -- Workflow (user → manager → risk team)
    status_id INT REFERENCES incident_status_ref(status_id),
    reported_by INT REFERENCES users(id), -- creator of the incident
    validated_by INT REFERENCES users(id),
    validated_at TIMESTAMP,
    closed_by INT REFERENCES users(id),
    closed_at TIMESTAMP,

    -- soft delete
    deleted_at TIMESTAMP,
    deleted_by INT REFERENCES users(id),
    
    -- Financial data
    gross_loss_amount NUMERIC(18,2) DEFAULT 0,
    recovery_amount NUMERIC(18,2) DEFAULT 0,
    net_loss_amount NUMERIC(18,2),  -- gros minus recovery, managed in app manually by risk officer
    currency_code VARCHAR(3), -- should be 3 ltters, ISO-4217 compliant
    near_miss BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT  -- including details on recovery (insurance, legal, third-party, etc.)
);

-- view for active incidents
CREATE OR REPLACE VIEW active_incident AS
SELECT * FROM incident WHERE deleted_at IS NULL;

-- indexes for possible typical queries
CREATE INDEX idx_incident_bu ON incident(business_unit_id);
CREATE INDEX idx_incident_status ON incident(status_id);

CREATE TABLE control (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    reference_doc VARCHAR(255),
    effectiveness SMALLINT CHECK (effectiveness BETWEEN 1 AND 5),
    business_process_id INT REFERENCES business_process(business_process_id),
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE measure (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    responsible_id INT REFERENCES users(id),
    deadline DATE,
    status_id INT REFERENCES measure_status_ref(status_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT REFERENCES users(id),
    updated_at TIMESTAMP,
    closed_at TIMESTAMP,
    closure_comment TEXT
);

CREATE TABLE key_risk_indicator (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    definition TEXT,
    unit VARCHAR(50),
    threshold_green NUMERIC,
    threshold_amber NUMERIC,
    threshold_red NUMERIC,
    frequency VARCHAR(20) CHECK (frequency IN ('Daily','Weekly','Monthly','Quarterly','Annually')),
    responsible_id INT REFERENCES users(id),
    risk_id INT REFERENCES risk(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Log of KRI measurements 
CREATE TABLE kri_measurement (
    id SERIAL PRIMARY KEY,
    kri_id INT REFERENCES key_risk_indicator(id) ON DELETE CASCADE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    value NUMERIC NOT NULL,
    -- threshold will be computed in the app
    threshold_status VARCHAR(10) CHECK (threshold_status IN ('Green', 'Amber', 'Red')),
    comment TEXT,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    recorded_by INT REFERENCES users(id),
    CONSTRAINT kri_period_order CHECK (period_start <= period_end)
);

CREATE INDEX idx_kri_period ON kri_measurement(kri_id, period_start, period_end);

-- this partial index will only work for big tables!
-- or use "SET enable_seqscan = OFF;" before querying for testing
CREATE INDEX idx_kri_breach_lookup ON kri_measurement(kri_id, period_start, period_end)
WHERE threshold_status <> 'Green';

-- more indexes for general reporting
CREATE INDEX idx_incident_dates ON incident(discovered_time, registered_time);
--CREATE INDEX idx_incident_owner ON incident(reported_by, validated_by, closed_by);
CREATE INDEX idx_control_process ON control(business_process_id);
CREATE INDEX idx_measure_assignee ON measure(responsible_id, status_id);

-- =========================
-- Link Tables (many-to-many)
-- =========================

-- Link incidents to known risks
CREATE TABLE incident_risk (
    incident_id INT REFERENCES incident(id) ON DELETE CASCADE,
    risk_id INT REFERENCES risk(id) ON DELETE CASCADE,
    PRIMARY KEY (incident_id, risk_id)
);

-- corrective
CREATE TABLE incident_measure (
    incident_id INT REFERENCES incident(id) ON DELETE CASCADE,
    measure_id INT REFERENCES measure(id) ON DELETE CASCADE,
    PRIMARY KEY (incident_id, measure_id)
);

-- multiple causes per incident
CREATE TABLE incident_cause (
    incident_id INT REFERENCES incident(id) ON DELETE CASCADE,
    loss_cause_id INT REFERENCES loss_cause(id) ON DELETE CASCADE,
    PRIMARY KEY (incident_id, loss_cause_id)
);

CREATE TABLE risk_control (
    risk_id INT REFERENCES risk(id) ON DELETE CASCADE,
    control_id INT REFERENCES control(id) ON DELETE CASCADE,
    PRIMARY KEY (risk_id, control_id)
);

-- preventive
CREATE TABLE risk_measure (
    risk_id INT REFERENCES risk(id) ON DELETE CASCADE,
    measure_id INT REFERENCES measure(id) ON DELETE CASCADE,
    PRIMARY KEY (risk_id, measure_id)
);

-- =========================
-- Soft deletion mechanisms (a unified trigger function attached to a table). 
-- This technique required extensive googling and exploring other's solutions,
-- although general logic was clear based on week's 4 ideas.
-- Initially applied for incident table as the most critical data, 
-- easily extended for other tables if needed.
-- =========================

CREATE OR REPLACE FUNCTION soft_delete_trigger()
RETURNS TRIGGER AS $$
BEGIN
  EXECUTE format( -- we need to run dynamic statement for a generic function
    'UPDATE %I SET deleted_at = now(), deleted_by = %s WHERE id = $1.id',
    TG_TABLE_NAME, -- replaces %I with the table the trigger fired on
    CASE -- select correct value for %s placeholder, NULL or content of audit.user_id
      WHEN current_setting('audit.user_id', true) IS NOT NULL
      THEN quote_literal(current_setting('audit.user_id', true)::INT)
      ELSE 'NULL'
    END
  )
  USING OLD; -- this goes into $1 placeholder above, meaning the row being deleted

  RETURN NULL; -- cancel the actual DELETE
END;
$$ LANGUAGE plpgsql;

-- can be applied for other tables as well
CREATE TRIGGER incident_soft_delete
BEFORE DELETE ON incident
FOR EACH ROW
EXECUTE FUNCTION soft_delete_trigger();


