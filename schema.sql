-- 1. CASES TABLE
CREATE TABLE cases_record (
    case_id VARCHAR(20) PRIMARY KEY,
    case_title VARCHAR(200) NOT NULL,
    case_type VARCHAR(50) NOT NULL,
    crime_category VARCHAR(50) NOT NULL,
    incident_date TIMESTAMP NOT NULL,
    reported_date TIMESTAMP NOT NULL,
    location_address TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    case_status VARCHAR(30) DEFAULT 'OPEN',
    priority_level VARCHAR(10) DEFAULT 'MEDIUM',
    lead_officer_id INT,
    case_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_date TIMESTAMP,
    conviction_status VARCHAR(30)
);
select * from cases_record ; 

ALTER TABLE cases_record ADD FOREIGN KEY (lead_officer_id) REFERENCES officers(officer_id);
-- 2. OFFICERS TABLE
CREATE TABLE officers (
    officer_id SERIAL PRIMARY KEY,
    badge_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    rank_position VARCHAR(30) NOT NULL,
    department VARCHAR(50) NOT NULL,
    specialization VARCHAR(50),
    phone VARCHAR(15),
    email VARCHAR(100),
    hire_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    total_cases_solved INT DEFAULT 0,
    performance_rating DECIMAL(3,2)
);
select officer_id from officers;
-- 3. SUSPECTS TABLE
CREATE TABLE suspects (
    suspect_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    alias VARCHAR(100),
    date_of_birth DATE,
    gender CHAR(1),
    height_cm INT,
    weight_kg INT,
    eye_color VARCHAR(20),
    hair_color VARCHAR(20),
    identifying_marks TEXT,
    address TEXT,
    phone VARCHAR(15),
    criminal_history TEXT,
    modus_operandi TEXT,
    risk_level VARCHAR(10) DEFAULT 'LOW',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. EVIDENCE TABLE
CREATE TABLE evidence (
    evidence_id SERIAL PRIMARY KEY,
    case_id VARCHAR(20) NOT NULL,
    evidence_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    collection_date TIMESTAMP NOT NULL,
    collection_location TEXT,
    collected_by INT NOT NULL,
    chain_of_custody JSONB,
    storage_location VARCHAR(100),
    evidence_status VARCHAR(30) DEFAULT 'COLLECTED',
    lab_analysis_result TEXT,
    admissible_in_court BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. WITNESSES TABLE
CREATE TABLE witnesses (
    witness_id SERIAL PRIMARY KEY,
    case_id VARCHAR(20) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    contact_phone VARCHAR(15),
    contact_email VARCHAR(100),
    address TEXT,
    witness_type VARCHAR(30), -- 'EYEWITNESS', 'EXPERT', 'CHARACTER'
    statement TEXT,
    reliability_score INT CHECK (reliability_score BETWEEN 1 AND 10),
    statement_date TIMESTAMP,
    interviewed_by INT
);

ALTER TABLE evidence ADD FOREIGN KEY (case_id) REFERENCES cases_record(case_id);
ALTER TABLE evidence ADD FOREIGN KEY (collected_by) REFERENCES officers(officer_id);
ALTER TABLE witnesses ADD FOREIGN KEY (case_id) REFERENCES cases_record(case_id);
ALTER TABLE witnesses ADD FOREIGN KEY (interviewed_by) REFERENCES officers(officer_id);

-- 6. CASE_SUSPECT_RELATIONSHIP TABLE
CREATE TABLE case_suspects (
    case_id VARCHAR(20),
    suspect_id INT,
    relationship_type VARCHAR(30), -- 'PRIMARY', 'ACCOMPLICE', 'PERSON OF INTEREST'
    arrest_date TIMESTAMP,
    charges TEXT,
    bail_amount DECIMAL(10,2),
    court_date DATE,
    PRIMARY KEY (case_id, suspect_id)
);

-- 7. CASE_OFFICERS TABLE (Many-to-Many)
CREATE TABLE case_officers (
    case_id VARCHAR(20),
    officer_id INT,
    role VARCHAR(30), -- 'LEAD', 'ASSISTING', 'CONSULTANT'
    assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (case_id, officer_id)
);

-- 8. FORENSIC_ANALYSIS TABLE
CREATE TABLE forensic_analysis (
    analysis_id SERIAL PRIMARY KEY,
    evidence_id INT NOT NULL,
    analysis_type VARCHAR(50) NOT NULL,
    lab_technician VARCHAR(100),
    analysis_date TIMESTAMP NOT NULL,
    results TEXT,
    conclusion TEXT,
    confidence_level VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. CASE_TIMELINE TABLE
CREATE TABLE case_timeline (
    timeline_id SERIAL PRIMARY KEY,
    case_id VARCHAR(20) NOT NULL,
    event_date TIMESTAMP NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_description TEXT NOT NULL,
    officer_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. CRIME_STATISTICS TABLE
CREATE TABLE crime_statistics (
    stat_id SERIAL PRIMARY KEY,
    date_recorded DATE NOT NULL,
    crime_type VARCHAR(50) NOT NULL,
    location_district VARCHAR(50),
    case_count INT NOT NULL,
    solved_count INT DEFAULT 0,
    conviction_count INT DEFAULT 0
);

Select * from crime_statistics;


ALTER TABLE case_suspects ADD FOREIGN KEY (case_id) REFERENCES cases_record(case_id);
ALTER TABLE case_suspects ADD FOREIGN KEY (suspect_id) REFERENCES suspects(suspect_id);
ALTER TABLE case_officers ADD FOREIGN KEY (case_id) REFERENCES cases_record(case_id);
ALTER TABLE case_officers ADD FOREIGN KEY (officer_id) REFERENCES officers(officer_id);
ALTER TABLE forensic_analysis ADD FOREIGN KEY (evidence_id) REFERENCES evidence(evidence_id);
ALTER TABLE case_timeline ADD FOREIGN KEY (case_id) REFERENCES cases_record(case_id);
ALTER TABLE case_timeline ADD FOREIGN KEY (officer_id) REFERENCES officers(officer_id);

-- Inserting values

-- INSERT OFFICERS (Some with NULL specialization, performance_rating)
INSERT INTO officers (badge_number, first_name, last_name, rank_position, department, specialization, phone, email, hire_date, status, total_cases_solved, performance_rating) VALUES
('BD001', 'John', 'Smith', 'Detective', 'Criminal Investigation', 'Homicide', '555-0101', 'j.smith@police.gov', '2020-01-15', 'ACTIVE', 15, 4.5),
('BD002', 'Sarah', 'Johnson', 'Lieutenant', 'Criminal Investigation', 'Cybercrime', '555-0102', 's.johnson@police.gov', '2018-03-20', 'ACTIVE', 22, 4.8),
('BD003', 'Mike', 'Brown', 'Sergeant', 'Forensics', NULL, '555-0103', 'm.brown@police.gov', '2019-07-10', 'ACTIVE', 8, NULL),
('BD004', 'Emily', 'Davis', 'Officer', 'Patrol', NULL, NULL, 'e.davis@police.gov', '2021-05-12', 'ACTIVE', 3, 3.9),
('BD005', 'Robert', 'Wilson', 'Captain', 'Administration', 'Management', '555-0105', NULL, '2015-02-28', 'INACTIVE', 45, 4.7),
('BD006', 'Lisa', 'Garcia', 'Detective', 'Criminal Investigation', 'Financial Crimes', '555-0106', 'l.garcia@police.gov', '2022-01-10', 'ACTIVE', 7, NULL);

-- INSERT SUSPECTS (Some with NULL aliases, addresses, criminal_history)
INSERT INTO suspects (first_name, last_name, alias, date_of_birth, gender, height_cm, weight_kg, eye_color, hair_color, identifying_marks, address, phone, criminal_history, modus_operandi, risk_level) VALUES
('James', 'Thompson', 'Jimmy T', '1985-05-12', 'M', 180, 75, 'Brown', 'Black', 'Scar on left cheek', '123 Elm Street', '555-1001', 'Previous robbery convictions in 2018, 2020', 'Uses distraction techniques', 'HIGH'),
('Maria', 'Rodriguez', NULL, '1990-08-25', 'F', 165, 60, 'Green', 'Brown', NULL, NULL, NULL, 'First time offender', 'Unknown', 'LOW'),
('David', 'Lee', 'Dave the Snake', '1978-12-03', 'M', 175, 80, 'Blue', 'Blonde', 'Dragon tattoo on right arm', '456 Oak Avenue', '555-1002', NULL, 'Targets high-end electronics', 'MEDIUM'),
('Jennifer', 'White', NULL, '1995-03-18', 'F', 170, 65, 'Hazel', 'Red', NULL, '789 Pine Road', '555-1003', 'Minor theft charges', NULL, 'LOW'),
('Michael', 'Johnson', 'Big Mike', '1982-07-22', 'M', 190, 95, 'Brown', 'Black', 'Multiple scars on hands', NULL, NULL, 'Armed robbery, assault charges', 'Uses intimidation tactics', 'HIGH');

-- INSERT CASES (Some with NULL latitude/longitude, closed_date, conviction_status)
INSERT INTO cases_record (case_id, case_title, case_type, crime_category, incident_date, reported_date, location_address, latitude, longitude, case_status, priority_level, lead_officer_id, case_description, closed_date, conviction_status) VALUES
('CASE2024001', 'Downtown Bank Robbery', 'FELONY', 'ROBBERY', '2024-01-15 14:30:00', '2024-01-15 14:45:00', '123 Main St, Downtown', 40.7128, -74.0060, 'CLOSED', 'HIGH', 1, 'Armed robbery at First National Bank with 3 suspects', '2024-02-20 16:00:00', 'CONVICTED'),
('CASE2024002', 'Residential Burglary', 'FELONY', 'BURGLARY', '2024-01-20 22:00:00', '2024-01-21 08:00:00', '456 Oak Avenue', NULL, NULL, 'OPEN', 'MEDIUM', 2, 'Break-in at residential property, electronics stolen', NULL, NULL),
('CASE2024003', 'Credit Card Fraud', 'FELONY', 'FRAUD', '2024-02-05 10:15:00', '2024-02-05 11:30:00', 'Online Transaction', NULL, NULL, 'UNDER_INVESTIGATION', 'MEDIUM', 6, 'Multiple unauthorized credit card transactions', NULL, NULL),
('CASE2024004', 'Assault Case', 'MISDEMEANOR', 'ASSAULT', '2024-02-10 21:45:00', '2024-02-10 22:00:00', '789 Pine Road', 40.7589, -73.9851, 'CLOSED', 'LOW', 4, NULL, '2024-02-15 14:30:00', 'DISMISSED'),
('CASE2024005', 'Vehicle Theft', 'FELONY', 'THEFT', '2024-02-12 07:30:00', '2024-02-12 18:00:00', 'Shopping Mall Parking Lot', 40.7505, -73.9934, 'OPEN', 'HIGH', 1, 'Luxury vehicle stolen from mall parking', NULL, NULL);

-- INSERT EVIDENCE (Some with NULL chain_of_custody, lab_analysis_result)
INSERT INTO evidence (case_id, evidence_type, description, collection_date, collection_location, collected_by, chain_of_custody, storage_location, evidence_status, lab_analysis_result, admissible_in_court) VALUES
('CASE2024001', 'FINGERPRINT', 'Fingerprints found on bank counter', '2024-01-15 16:00:00', '123 Main St, Downtown', 3, '[]', 'Evidence Room A-15', 'ANALYZED', 'Match found in database - James Thompson', TRUE),
('CASE2024001', 'WEAPON', '9mm handgun recovered at scene', '2024-01-15 16:30:00', '123 Main St, Downtown', 1, NULL, 'Evidence Room B-08', 'COLLECTED', NULL, TRUE),
('CASE2024002', 'DNA', 'Blood sample from broken window', '2024-01-21 09:00:00', '456 Oak Avenue', 3, '[]', 'Evidence Room A-12', 'PENDING_ANALYSIS', NULL, TRUE),
('CASE2024003', 'DIGITAL', 'Transaction logs and IP addresses', '2024-02-05 14:00:00', 'Cyber Crime Unit', 2, NULL, 'Digital Evidence Storage', 'ANALYZED', 'Traced to suspect location', TRUE),
('CASE2024005', 'VIDEO', 'Security camera footage', '2024-02-12 20:00:00', 'Shopping Mall Security Office', 4, '[]', 'Digital Evidence Storage', 'COLLECTED', NULL, TRUE);

-- INSERT WITNESSES (Some with NULL contact info, reliability_score)
INSERT INTO witnesses (case_id, first_name, last_name, contact_phone, contact_email, address, witness_type, statement, reliability_score, statement_date, interviewed_by) VALUES
('CASE2024001', 'Alice', 'Brown', '555-2001', 'alice.brown@email.com', '789 First Ave', 'EYEWITNESS', 'Saw three men enter the bank with weapons', 8, '2024-01-15 18:00:00', 1),
('CASE2024001', 'Peter', 'Davis', NULL, NULL, NULL, 'EYEWITNESS', 'Witnessed suspects fleeing in blue sedan', NULL, '2024-01-16 10:00:00', 1),
('CASE2024002', 'Nancy', 'Wilson', '555-2002', 'nancy.w@email.com', '460 Oak Avenue', 'EYEWITNESS', 'Heard breaking glass around 10 PM', 6, '2024-01-21 12:00:00', 2),
('CASE2024004', 'Mark', 'Taylor', '555-2003', NULL, '790 Pine Road', 'EYEWITNESS', NULL, 7, '2024-02-11 09:00:00', 4),
('CASE2024005', 'Sandra', 'Martinez', NULL, 'sandra.m@email.com', NULL, 'EYEWITNESS', 'Saw suspicious person near parking area', NULL, '2024-02-13 11:00:00', 1);

-- INSERT CASE_SUSPECTS (Some with NULL arrest_date, bail_amount, court_date)
INSERT INTO case_suspects (case_id, suspect_id, relationship_type, arrest_date, charges, bail_amount, court_date) VALUES
('CASE2024001', 1, 'PRIMARY', '2024-01-20 10:00:00', 'Armed Robbery, Aggravated Assault', 50000.00, '2024-03-15'),
('CASE2024001', 5, 'ACCOMPLICE', '2024-01-22 14:00:00', 'Armed Robbery', 25000.00, '2024-03-15'),
('CASE2024002', 3, 'PERSON OF INTEREST', NULL, NULL, NULL, NULL),
('CASE2024003', 2, 'PRIMARY', NULL, 'Credit Card Fraud', NULL, NULL),
('CASE2024004', 4, 'PRIMARY', '2024-02-11 08:00:00', 'Simple Assault', 1000.00, '2024-02-25'),
('CASE2024005', 1, 'PERSON OF INTEREST', NULL, NULL, NULL, NULL);

-- INSERT CASE_OFFICERS
INSERT INTO case_officers (case_id, officer_id, role, assigned_date) VALUES
('CASE2024001', 1, 'LEAD', '2024-01-15 15:00:00'),
('CASE2024001', 3, 'ASSISTING', '2024-01-15 16:00:00'),
('CASE2024002', 2, 'LEAD', '2024-01-21 09:00:00'),
('CASE2024003', 6, 'LEAD', '2024-02-05 12:00:00'),
('CASE2024003', 2, 'CONSULTANT', '2024-02-05 13:00:00'),
('CASE2024004', 4, 'LEAD', '2024-02-10 22:30:00'),
('CASE2024005', 1, 'LEAD', '2024-02-12 19:00:00');

-- INSERT FORENSIC_ANALYSIS (Some with NULL results, conclusion)
INSERT INTO forensic_analysis (evidence_id, analysis_type, lab_technician, analysis_date, results, conclusion, confidence_level) VALUES
(1, 'FINGERPRINT_ANALYSIS', 'Dr. Smith', '2024-01-16 10:00:00', 'Clear match with suspect database', 'Positive identification of James Thompson', 'HIGH'),
(3, 'DNA_ANALYSIS', 'Dr. Johnson', '2024-01-23 14:00:00', NULL, NULL, 'PENDING'),
(4, 'DIGITAL_FORENSICS', 'Tech Analyst Brown', '2024-02-06 16:00:00', 'IP trace successful, location identified', 'Strong evidence linking to suspect', 'HIGH'),
(2, 'BALLISTICS', NULL, '2024-01-17 11:00:00', 'Weapon fired recently, no database match', NULL, 'MEDIUM');

-- INSERT CASE_TIMELINE
INSERT INTO case_timeline (case_id, event_date, event_type, event_description, officer_id) VALUES
('CASE2024001', '2024-01-15 14:45:00', 'CASE_OPENED', 'Bank robbery reported', 1),
('CASE2024001', '2024-01-15 16:00:00', 'EVIDENCE_COLLECTED', 'Fingerprints and weapon collected', 3),
('CASE2024001', '2024-01-20 10:00:00', 'ARREST_MADE', 'Primary suspect James Thompson arrested', 1),
('CASE2024001', '2024-02-20 16:00:00', 'CASE_CLOSED', 'Case closed with conviction', 1),
('CASE2024002', '2024-01-21 08:30:00', 'CASE_OPENED', 'Residential burglary reported', 2),
('CASE2024003', '2024-02-05 11:45:00', 'CASE_OPENED', 'Credit card fraud investigation started', 6);

-- INSERT CRIME_STATISTICS
INSERT INTO crime_statistics (date_recorded, crime_type, location_district, case_count, solved_count, conviction_count) VALUES
('2024-01-31', 'ROBBERY', 'Downtown', 3, 2, 1),
('2024-01-31', 'BURGLARY', 'Residential Area', 5, 2, 1),
('2024-02-29', 'FRAUD', 'Online', 8, 3, 2),
('2024-02-29', 'ASSAULT', 'Various', 12, 10, 8),
('2024-02-29', 'THEFT', 'Commercial Areas', 15, 6, 4);

-- UPDATE Operations with NULL handling
-- Update missing specializations
UPDATE officers 
SET specialization = 'General Investigation' 
WHERE specialization IS NULL;

-- Update NULL performance ratings with average
UPDATE officers 
SET performance_rating = (
    SELECT AVG(performance_rating) 
    FROM officers 
    WHERE performance_rating IS NOT NULL
)
WHERE performance_rating IS NULL;

-- Update case descriptions using COALESCE
UPDATE cases_record 
SET case_description = COALESCE(case_description, 'No description provided')
WHERE case_description IS NULL;

-- Using COALESCE to handle NULL values
SELECT 
    officer_id,
    first_name || ' ' || last_name as full_name,
    COALESCE(specialization, 'Not Specified') as specialization,
    COALESCE(phone, 'No Phone') as contact_phone,
    COALESCE(email, 'No Email') as contact_email,
    COALESCE(performance_rating::text, 'Not Rated') as rating
FROM officers;
















