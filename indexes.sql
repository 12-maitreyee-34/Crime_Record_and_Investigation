-- cases_record table
CREATE INDEX idx_cases_status ON cases_record(case_status);
CREATE INDEX idx_cases_crime_category ON cases_record(crime_category);
CREATE INDEX idx_cases_incident_date ON cases_record(incident_date);
CREATE INDEX idx_cases_priority_level ON cases_record(priority_level);
CREATE INDEX idx_cases_lead_officer ON cases_record(lead_officer_id);

-- SUSPECTS TABLE - Name Search Optimization

CREATE INDEX idx_suspects_last_name ON suspects(last_name);
CREATE INDEX idx_suspects_first_name ON suspects(first_name);
CREATE INDEX idx_suspects_full_name ON suspects(last_name, first_name);

-- OFFICERS TABLE - Administrative Queries

CREATE INDEX idx_officers_department ON officers(department);
CREATE INDEX idx_officers_status ON officers(status);
CREATE INDEX idx_officers_badge_number ON officers(badge_number);

CREATE INDEX idx_cases_open_high_priority 
ON cases_record(incident_date, case_id) 
WHERE case_status = 'OPEN' AND priority_level = 'HIGH';

SELECT indexname, tablename, indexdef 
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename = 'officers';

-- Get count of cases by status
SELECT 
    case_status,
    COUNT(*) as case_count,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cases_record)), 2) as percentage
FROM cases_record
GROUP BY case_status
ORDER BY case_count DESC;

-- solved vs unsolved cases summary
SELECT 
    CASE 
        WHEN case_status = 'CLOSED' THEN 'SOLVED'
        ELSE 'UNSOLVED'
    END as case_category,
    COUNT(*) as total_cases,
    ROUND(AVG(EXTRACT(DAYS FROM (COALESCE(closed_date, CURRENT_TIMESTAMP) - incident_date))), 2) as avg_days_to_resolve
FROM cases_record
GROUP BY 
    CASE 
        WHEN case_status = 'CLOSED' THEN 'SOLVED'
        ELSE 'UNSOLVED'
    END;

-- LONG-RUNNING UNSOLVED CASES (Over 90 days)
SELECT 
    cr.case_id,
    cr.case_title,
    cr.crime_category,
    cr.priority_level,
    cr.incident_date,
    EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - cr.incident_date)) as days_open,
    o.first_name || ' ' || o.last_name as lead_officer,
    cr.case_description
FROM cases_record cr
LEFT JOIN officers o ON cr.lead_officer_id = o.officer_id
WHERE cr.case_status != 'CLOSED' 
    AND EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - cr.incident_date)) > 90
ORDER BY days_open DESC;

