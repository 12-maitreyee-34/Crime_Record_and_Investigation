--  COMPREHENSIVE OFFICER WORKLOAD VIEW
CREATE VIEW officer_workload_summary AS
SELECT 
    o.officer_id,
    o.badge_number,
    o.first_name || ' ' || o.last_name AS full_name,
    o.rank_position,
    o.department,
    o.specialization,
    o.status,
    
    -- Current Active Cases
    COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) AS active_cases,
    
    -- Total Cases (All Time)
    COUNT(co.case_id) AS total_assigned_cases,
    
    -- Closed Cases
    COUNT(CASE WHEN cr.case_status = 'CLOSED' THEN 1 END) AS closed_cases,
    
    -- Cases by Role
    COUNT(CASE WHEN co.role = 'LEAD' THEN 1 END) AS lead_cases,
    COUNT(CASE WHEN co.role = 'ASSISTING' THEN 1 END) AS assisting_cases,
    COUNT(CASE WHEN co.role = 'CONSULTANT' THEN 1 END) AS consultant_cases,
    
    -- Cases by Priority
    COUNT(CASE WHEN cr.priority_level = 'HIGH' AND cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) AS high_priority_active,
    COUNT(CASE WHEN cr.priority_level = 'MEDIUM' AND cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) AS medium_priority_active,
    COUNT(CASE WHEN cr.priority_level = 'LOW' AND cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) AS low_priority_active,
    
    -- Performance Metrics
    o.total_cases_solved,
    o.performance_rating,
    
    -- Case Success Rate
    CASE 
        WHEN COUNT(co.case_id) > 0 THEN 
            ROUND((COUNT(CASE WHEN cr.case_status = 'CLOSED' THEN 1 END)::DECIMAL / COUNT(co.case_id)) * 100, 2)
        ELSE 0 
    END AS case_closure_rate,
    
    -- Workload Status
    CASE 
        WHEN COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) >= 10 THEN 'OVERLOADED'
        WHEN COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) >= 5 THEN 'BUSY'
        WHEN COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) >= 1 THEN 'MODERATE'
        ELSE 'AVAILABLE'
    END AS workload_status

FROM officers o
LEFT JOIN case_officers co ON o.officer_id = co.officer_id
LEFT JOIN cases_record cr ON co.case_id = cr.case_id
WHERE o.status = 'ACTIVE'
GROUP BY o.officer_id, o.badge_number, o.first_name, o.last_name, o.rank_position, 
         o.department, o.specialization, o.status, o.total_cases_solved, o.performance_rating
ORDER BY active_cases DESC, o.rank_position;


--  ACTIVE CASES DETAIL VIEW
CREATE VIEW officer_active_cases AS
SELECT 
    o.officer_id,
    o.badge_number,
    o.first_name || ' ' || o.last_name AS officer_name,
    o.rank_position,
    o.department,
    co.role AS case_role,
    cr.case_id,
    cr.case_title,
    cr.case_type,
    cr.crime_category,
    cr.priority_level,
    cr.case_status,
    cr.incident_date,
    cr.reported_date,
    EXTRACT(DAYS FROM CURRENT_TIMESTAMP - cr.reported_date) AS days_since_reported,
    cr.location_address,
    co.assigned_date,
    EXTRACT(DAYS FROM CURRENT_TIMESTAMP - co.assigned_date) AS days_assigned
FROM officers o
JOIN case_officers co ON o.officer_id = co.officer_id
JOIN cases_record cr ON co.case_id = cr.case_id
WHERE cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION')
    AND o.status = 'ACTIVE'
ORDER BY cr.priority_level DESC, cr.reported_date ASC;


--  DEPARTMENT WORKLOAD VIEW
CREATE VIEW department_workload AS
SELECT 
    o.department,
    COUNT(DISTINCT o.officer_id) AS total_officers,
    COUNT(DISTINCT CASE WHEN o.status = 'ACTIVE' THEN o.officer_id END) AS active_officers,
    
    -- Case Distribution
    COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) AS active_cases,
    COUNT(CASE WHEN cr.case_status = 'CLOSED' THEN 1 END) AS closed_cases,
    COUNT(co.case_id) AS total_cases_assigned,
    
    -- Priority Distribution
    COUNT(CASE WHEN cr.priority_level = 'HIGH' AND cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) AS high_priority_cases,
    COUNT(CASE WHEN cr.priority_level = 'MEDIUM' AND cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) AS medium_priority_cases,
    COUNT(CASE WHEN cr.priority_level = 'LOW' AND cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) AS low_priority_cases,
    
    -- Average Workload per Officer
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN o.status = 'ACTIVE' THEN o.officer_id END) > 0 THEN
            ROUND(COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END)::DECIMAL / 
                  COUNT(DISTINCT CASE WHEN o.status = 'ACTIVE' THEN o.officer_id END), 2)
        ELSE 0
    END AS avg_active_cases_per_officer,
    
    -- Department Performance
    AVG(o.performance_rating) AS avg_department_rating,
    SUM(o.total_cases_solved) AS total_department_solved_cases

FROM officers o
LEFT JOIN case_officers co ON o.officer_id = co.officer_id
LEFT JOIN cases_record cr ON co.case_id = cr.case_id
GROUP BY o.department
ORDER BY active_cases DESC;

-- OVERLOADED OFFICERS ALERT VIEW
CREATE VIEW overloaded_officers_alert AS
SELECT 
    o.officer_id,
    o.badge_number,
    o.first_name || ' ' || o.last_name AS officer_name,
    o.rank_position,
    o.department,
    COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) AS active_cases,
    COUNT(CASE WHEN cr.priority_level = 'HIGH' AND cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) AS high_priority_cases,
    
    -- Oldest Case
    MIN(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN cr.reported_date END) AS oldest_active_case_date,
    
    -- Days since oldest case
    EXTRACT(DAYS FROM CURRENT_TIMESTAMP - 
            MIN(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN cr.reported_date END)) AS days_oldest_case,
    
    -- Alert Level
    CASE 
        WHEN COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) >= 15 THEN 'CRITICAL'
        WHEN COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) >= 10 THEN 'HIGH'
        WHEN COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) >= 7 THEN 'MODERATE'
        ELSE 'NORMAL'
    END AS alert_level

FROM officers o
JOIN case_officers co ON o.officer_id = co.officer_id
JOIN cases_record cr ON co.case_id = cr.case_id
WHERE o.status = 'ACTIVE'
    AND cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION')
GROUP BY o.officer_id, o.badge_number, o.first_name, o.last_name, o.rank_position, o.department
HAVING COUNT(CASE WHEN cr.case_status IN ('OPEN', 'UNDER_INVESTIGATION') THEN 1 END) >= 5
ORDER BY active_cases DESC, high_priority_cases DESC;