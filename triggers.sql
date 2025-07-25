CREATE TABLE evidence_chain_audit (
    audit_id SERIAL PRIMARY KEY,
    evidence_id INT NOT NULL REFERENCES evidence(evidence_id),
    changed_by VARCHAR(100),                        -- Could be officer ID, username or NULL if system
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- When change occurred
    old_chain JSONB,
    new_chain JSONB,
    comment TEXT
);

CREATE OR REPLACE FUNCTION log_chain_of_custody_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if the chain_of_custody JSONB actually changes
    IF NOT NEW.chain_of_custody IS DISTINCT FROM OLD.chain_of_custody THEN
        RETURN NEW;
    END IF;

    INSERT INTO evidence_chain_audit (
        evidence_id,
        changed_by,
        old_chain,
        new_chain,
        comment
    ) VALUES (
        NEW.evidence_id,
        NULL,                   -- or pass a user/username if your app provides it
        OLD.chain_of_custody,
        NEW.chain_of_custody,
        'Chain of custody updated'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS evidence_chain_update_trigger ON evidence;

CREATE TRIGGER evidence_chain_update_trigger
AFTER UPDATE OF chain_of_custody ON evidence
FOR EACH ROW
EXECUTE FUNCTION log_chain_of_custody_change();

UPDATE evidence
SET chain_of_custody = '[{"officer":"John Smith","timestamp":"2024-01-18T10:05:00"}]'
WHERE evidence_id = 1;

SELECT * 
FROM evidence_chain_audit 
WHERE evidence_id = 1
ORDER BY action_time DESC;

SELECT a.evidence_id, e.case_id, a.changed_by, a.action_time, a.old_chain, a.new_chain
FROM evidence_chain_audit a
JOIN evidence e ON a.evidence_id = e.evidence_id
WHERE e.case_id = 'CASE2024001'
ORDER BY a.action_time;


