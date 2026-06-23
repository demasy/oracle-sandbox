-- ─────────────────────────────────────────────────────────────────────────────
-- Post-PDB Initialization Script
-- ─────────────────────────────────────────────────────────────────────────────
-- This script runs AFTER the PDB is created and all users/roles are set up
-- It creates additional database objects like indexes, synonyms, views, etc.
--
-- Execution Context:
--   • Run As: SYSTEM user in SANDBOX_PDB
--   • Timing: After user creation and privilege grants
--   • Purpose: Setup application-level database objects
--
-- ─────────────────────────────────────────────────────────────────────────────

-- =============================================================================
-- PART 1: Create public synonyms for commonly used packages
-- =============================================================================

CREATE OR REPLACE PUBLIC SYNONYM dbms_output FOR sys.dbms_output;
CREATE OR REPLACE PUBLIC SYNONYM dbms_sql FOR sys.dbms_sql;
CREATE OR REPLACE PUBLIC SYNONYM dbms_lock FOR sys.dbms_lock;
CREATE OR REPLACE PUBLIC SYNONYM dbms_session FOR sys.dbms_session;
CREATE OR REPLACE PUBLIC SYNONYM dbms_utility FOR sys.dbms_utility;
CREATE OR REPLACE PUBLIC SYNONYM dbms_describe FOR sys.dbms_describe;
CREATE OR REPLACE PUBLIC SYNONYM dbms_alert FOR sys.dbms_alert;
CREATE OR REPLACE PUBLIC SYNONYM dbms_application_info FOR sys.dbms_application_info;

-- =============================================================================
-- PART 2: Grant execute rights on commonly used packages
-- =============================================================================

BEGIN
  FOR user_rec IN (
    SELECT username 
    FROM dba_users 
    WHERE username IN ('SANDBOX', 'SANDBOX_AI', 'DEMASY', 'DEMASY_AI', 'APEX_APP')
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON sys.dbms_output TO ' || user_rec.username;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON sys.dbms_sql TO ' || user_rec.username;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON sys.dbms_lock TO ' || user_rec.username;
  END LOOP;
END;
/

-- =============================================================================
-- PART 3: Create default application schemas if needed
-- =============================================================================

-- Create default schema for application data (if not already created by user setup)
-- This can be expanded with specific application-level objects

-- =============================================================================
-- PART 4: Create monitoring views for sandbox operations
-- =============================================================================

CREATE OR REPLACE VIEW demasy_database_info AS
SELECT 
  database_name,
  open_cursors,
  db_unique_name,
  platform_name,
  instance_name
FROM v$database, v$instance;

-- =============================================================================
-- PART 5: Enable audit logging for sensitive operations
-- =============================================================================

-- Audit user connects and disconnects
AUDIT CREATE SESSION BY demasy_ai BY ACCESS;
AUDIT ALTER SYSTEM BY demasy_ai BY ACCESS;

-- =============================================================================
-- PART 6: Set common initialization parameters
-- =============================================================================

ALTER SYSTEM SET processes=300 SCOPE=BOTH;
ALTER SYSTEM SET open_cursors=3000 SCOPE=BOTH;
ALTER SYSTEM SET db_recovery_file_dest_size=50G SCOPE=BOTH;

COMMIT;

-- =============================================================================
-- Completion Message
-- =============================================================================

BEGIN
  DBMS_OUTPUT.PUT_LINE('Post-PDB initialization completed successfully');
  DBMS_OUTPUT.PUT_LINE('Synonym creation: OK');
  DBMS_OUTPUT.PUT_LINE('Package grants: OK');
  DBMS_OUTPUT.PUT_LINE('Monitoring views: OK');
  DBMS_OUTPUT.PUT_LINE('Audit logging: OK');
  DBMS_OUTPUT.PUT_LINE('Parameter settings: OK');
END;
/

EXIT;
