CREATE OR REPLACE VIEW case_summary_export AS
SELECT 
    cr.case_id,
    cr.case_title,
    cr.case_type,
    cr.crime_category,
    TO_CHAR(cr.incident_date, 'YYYY-MM-DD HH24:MI') as incident_datetime,
    TO_CHAR(cr.reported_date, 'YYYY-MM-DD HH24:MI') as reported_datetime,
    cr.location_address,
    cr.case_status,
    cr.priority_level,
    
    -- Lead Officer Information
    o.first_name || ' ' || o.last_name as lead_officer_name,
    o.badge_number as lead_officer_badge,
    o.rank_position as lead_officer_rank,
    
    -- Case Duration
    CASE 
        WHEN cr.closed_date IS NOT NULL THEN
            EXTRACT(DAY FROM (cr.closed_date - cr.reported_date)) || ' days'
        ELSE
            EXTRACT(DAY FROM (CURRENT_TIMESTAMP - cr.reported_date)) || ' days (ongoing)'
    END as case_duration,
    
    -- Conviction Status
    COALESCE(cr.conviction_status, 'Pending') as conviction_outcome,
    
    -- Case Description
    COALESCE(cr.case_description, 'No description available') as case_summary,
    
    -- Statistics
    (SELECT COUNT(*) FROM suspects s 
     JOIN case_suspects cs ON s.suspect_id = cs.suspect_id 
     WHERE cs.case_id = cr.case_id) as total_suspects,
     
    (SELECT COUNT(*) FROM evidence e WHERE e.case_id = cr.case_id) as total_evidence_items,
    
    (SELECT COUNT(*) FROM witnesses w WHERE w.case_id = cr.case_id) as total_witnesses,
    
    -- Team Size
    (SELECT COUNT(*) FROM case_officers co WHERE co.case_id = cr.case_id) as officers_assigned
    
FROM cases_record cr
LEFT JOIN officers o ON cr.lead_officer_id = o.officer_id
ORDER BY cr.reported_date DESC;

--
CREATE OR REPLACE FUNCTION generate_case_investigation_report(p_case_id VARCHAR)
RETURNS TABLE (
    section_type VARCHAR,
    section_content TEXT
) AS $$
BEGIN
    -- Case Header
    RETURN QUERY
    SELECT 
        'CASE_HEADER'::VARCHAR,
        'INVESTIGATION REPORT - Case ID: ' || p_case_id || E'\n' ||
        'Title: ' || case_title || E'\n' ||
        'Type: ' || case_type || ' (' || crime_category || ')' || E'\n' ||
        'Status: ' || case_status || E'\n' ||
        'Priority: ' || priority_level || E'\n' ||
        'Incident Date: ' || TO_CHAR(incident_date, 'YYYY-MM-DD HH24:MI') || E'\n' ||
        'Location: ' || COALESCE(location_address, 'Not specified') || E'\n' ||
        'Lead Officer: ' || COALESCE(o.first_name || ' ' || o.last_name || ' (' || o.badge_number || ')', 'Not assigned')
    FROM cases_record cr
    LEFT JOIN officers o ON cr.lead_officer_id = o.officer_id
    WHERE cr.case_id = p_case_id;
    
    -- Suspects Section
    RETURN QUERY
    SELECT 
        'SUSPECTS'::VARCHAR,
        'SUSPECTS INVOLVED:' || E'\n' ||
        STRING_AGG(
            '- ' || COALESCE(s.first_name || ' ' || s.last_name, 'Unknown') || 
            CASE WHEN s.alias IS NOT NULL THEN ' (alias: ' || s.alias || ')' ELSE '' END ||
            ' - Role: ' || cs.relationship_type ||
            CASE WHEN cs.arrest_date IS NOT NULL THEN ' - Arrested: ' || TO_CHAR(cs.arrest_date, 'YYYY-MM-DD') ELSE ' - Not arrested' END ||
            CASE WHEN cs.charges IS NOT NULL THEN E'\n  Charges: ' || cs.charges ELSE '' END,
            E'\n'
        )
    FROM case_suspects cs
    JOIN suspects s ON cs.suspect_id = s.suspect_id
    WHERE cs.case_id = p_case_id;
    
    -- Evidence Section
    RETURN QUERY
    SELECT 
        'EVIDENCE'::VARCHAR,
        'EVIDENCE COLLECTED:' || E'\n' ||
        STRING_AGG(
            '- ' || evidence_type || ': ' || description ||
            E'\n  Collected: ' || TO_CHAR(collection_date, 'YYYY-MM-DD HH24:MI') ||
            E'\n  Status: ' || evidence_status ||
            CASE WHEN lab_analysis_result IS NOT NULL THEN E'\n  Analysis: ' || lab_analysis_result ELSE '' END,
            E'\n'
        )
    FROM evidence
    WHERE case_id = p_case_id;
    
    -- Witnesses Section
    RETURN QUERY
    SELECT 
        'WITNESSES'::VARCHAR,
        'WITNESS STATEMENTS:' || E'\n' ||
        STRING_AGG(
            '- ' || COALESCE(first_name || ' ' || last_name, 'Anonymous') || 
            ' (' || witness_type || ')' ||
            CASE WHEN reliability_score IS NOT NULL THEN ' - Reliability: ' || reliability_score || '/10' ELSE '' END ||
            CASE WHEN statement IS NOT NULL THEN E'\n  Statement: ' || statement ELSE E'\n  No statement recorded' END,
            E'\n'
        )
    FROM witnesses
    WHERE case_id = p_case_id;
    
    -- Timeline Section
    RETURN QUERY
    SELECT 
        'TIMELINE'::VARCHAR,
        'CASE TIMELINE:' || E'\n' ||
        STRING_AGG(
            TO_CHAR(event_date, 'YYYY-MM-DD HH24:MI') || ' - ' || event_type || ': ' || event_description,
            E'\n'
            ORDER BY event_date
        )
    FROM case_timeline
    WHERE case_id = p_case_id;
    
END;
$$ LANGUAGE plpgsql;
