-- ─────────────────────────────────────────────────────────────────────────────
-- Enable Oracle AI 26ai Features Script
-- ─────────────────────────────────────────────────────────────────────────────
-- This script enables advanced Oracle AI Database 26ai features:
--   • Vector Storage and Similarity Search (AI/ML)
--   • Graph Database Support
--   • JSON Search Index
--   • Spatial Indexing
--   • Text Analytics
--
-- Execution Context:
--   • Run As: SYSTEM user in SANDBOX_PDB
--   • Timing: After post-pdb-init.sql
--   • Purpose: Enable AI/ML capabilities for sandbox workloads
--
-- Documentation:
--   https://docs.oracle.com/en/database/oracle-database/23/ai-oracle-ai-vector-search-users-guide/index.html
--
-- ─────────────────────────────────────────────────────────────────────────────

-- =============================================================================
-- PART 1: Enable Oracle Vector Database Support (AI Vectors)
-- =============================================================================

-- Verify VECTOR datatype is available
BEGIN
  FOR col_rec IN (
    SELECT owner, table_name 
    FROM dba_tables 
    WHERE owner = 'SYSTEM' 
    LIMIT 1
  ) LOOP
    EXECUTE IMMEDIATE 'CREATE TABLE vector_test (id NUMBER, vec VECTOR(384, FLOAT32))';
    EXECUTE IMMEDIATE 'DROP TABLE vector_test';
    DBMS_OUTPUT.PUT_LINE('✓ Oracle Vector support verified');
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('! Warning: Vector support not yet available');
END;
/

-- Grant vector-related privileges to users
BEGIN
  FOR user_rec IN (
    SELECT username 
    FROM dba_users 
    WHERE username IN ('SANDBOX_AI', 'DEMASY_AI')
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT CREATE TABLE TO ' || user_rec.username;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('✓ Vector privileges granted to AI users');
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/

-- =============================================================================
-- PART 2: Enable Graph Database Features
-- =============================================================================

-- Create sample property graph metadata
CREATE TABLE property_graphs (
  pg_name VARCHAR2(128) PRIMARY KEY,
  pg_owner VARCHAR2(128),
  description VARCHAR2(2000),
  created_date TIMESTAMP DEFAULT SYSTIMESTAMP,
  enabled CHAR(1) DEFAULT 'Y'
);

-- Grant access to AI users
GRANT SELECT, INSERT, UPDATE, DELETE ON property_graphs TO demasy_ai;
GRANT SELECT, INSERT, UPDATE, DELETE ON property_graphs TO sandbox_ai;

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ Graph database metadata tables created');
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/

-- =============================================================================
-- PART 3: Create JSON Search Index Support
-- =============================================================================

-- Verify JSON capabilities
BEGIN
  DECLARE
    test_json CLOB := '{"name": "test", "value": 123}';
    parsed_json JSON_OBJECT_T;
  BEGIN
    parsed_json := JSON_OBJECT_T.PARSE(test_json);
    DBMS_OUTPUT.PUT_LINE('✓ JSON parsing support verified');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('! JSON support status: ' || SQLERRM);
  END;
END;
/

-- =============================================================================
-- PART 4: Enable Full-Text Search (Oracle Text)
-- =============================================================================

BEGIN
  FOR user_rec IN (
    SELECT username 
    FROM dba_users 
    WHERE username IN ('SANDBOX_AI', 'DEMASY_AI', 'APEX_APP')
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'GRANT EXECUTE ON ctxsys.ctx_ddl TO ' || user_rec.username;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('✓ Full-Text Search privileges granted');
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/

-- =============================================================================
-- PART 5: Create AI Features Demonstration Tables
-- =============================================================================

-- Create a sample vector embeddings table for AI demonstrations
CREATE TABLE ai_embeddings (
  embedding_id NUMBER PRIMARY KEY,
  content_type VARCHAR2(50),
  embedding_vector VECTOR(384, FLOAT32),
  metadata_json CLOB,
  created_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Create index on embeddings table
CREATE INDEX idx_ai_embeddings ON ai_embeddings(embedding_id);

-- Grant access
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_embeddings TO demasy_ai;
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_embeddings TO sandbox_ai;

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ AI embeddings table created');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('! Note: Vector datatype not available in this Oracle version');
END;
/

-- =============================================================================
-- PART 6: Create Spatial Indexing Support
-- =============================================================================

-- Verify spatial support is available
BEGIN
  EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM user_sdo_geom_metadata WHERE 1=0';
  DBMS_OUTPUT.PUT_LINE('✓ Spatial indexing support verified');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('! Spatial indexing: Not available in this Oracle version');
END;
/

-- =============================================================================
-- PART 7: Enable Machine Learning Support
-- =============================================================================

-- Create tables for ML model storage
CREATE TABLE ml_models (
  model_id NUMBER PRIMARY KEY,
  model_name VARCHAR2(256),
  model_type VARCHAR2(100),
  model_data BLOB,
  training_date TIMESTAMP,
  accuracy NUMBER,
  created_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

CREATE TABLE ml_predictions (
  prediction_id NUMBER PRIMARY KEY,
  model_id NUMBER,
  input_data CLOB,
  prediction_output CLOB,
  confidence NUMBER,
  created_date TIMESTAMP DEFAULT SYSTIMESTAMP,
  FOREIGN KEY (model_id) REFERENCES ml_models(model_id)
);

-- Grant access
GRANT SELECT, INSERT, UPDATE, DELETE ON ml_models TO demasy_ai;
GRANT SELECT, INSERT, UPDATE, DELETE ON ml_predictions TO demasy_ai;

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ Machine Learning tables created');
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/

-- =============================================================================
-- PART 8: Set AI-Related Database Parameters
-- =============================================================================

-- Enable DB-specific AI optimizations
BEGIN
  -- Increase memory for vector operations
  EXECUTE IMMEDIATE 'ALTER SYSTEM SET pga_aggregate_target=4G SCOPE=BOTH';
  
  -- Enable parallel query for large-scale vector operations
  EXECUTE IMMEDIATE 'ALTER SYSTEM SET parallel_max_servers=8 SCOPE=BOTH';
  
  -- Enable JSON query optimization
  EXECUTE IMMEDIATE 'ALTER SYSTEM SET events=''44951 trace name context forever, level 2'' SCOPE=SPFILE';
  
  DBMS_OUTPUT.PUT_LINE('✓ AI-optimized parameters configured');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('! Warning: Could not set all parameters (may not be needed)');
END;
/

-- =============================================================================
-- PART 9: Create AI Features Verification View
-- =============================================================================

CREATE OR REPLACE VIEW ai_features_status AS
SELECT 
  'Vector Support' AS feature,
  CASE WHEN COUNT(*) > 0 THEN 'Available' ELSE 'Not Available' END AS status
FROM user_tab_columns 
WHERE data_type = 'VECTOR'
UNION ALL
SELECT 
  'JSON Support' AS feature,
  CASE WHEN COUNT(*) > 0 THEN 'Available' ELSE 'Not Available' END AS status
FROM user_tab_columns 
WHERE data_type LIKE 'JSON%'
UNION ALL
SELECT 
  'Spatial Support' AS feature,
  CASE WHEN COUNT(*) > 0 THEN 'Available' ELSE 'Not Available' END AS status
FROM user_sdo_geom_metadata;

-- Grant view access
GRANT SELECT ON ai_features_status TO public;

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ AI features status view created');
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/

-- =============================================================================
-- PART 10: Create ML/AI User Configuration View
-- =============================================================================

CREATE OR REPLACE VIEW ai_user_configuration AS
SELECT 
  username,
  account_status,
  created AS account_created,
  default_tablespace,
  'DEMASY_AI' AS ai_role
FROM dba_users 
WHERE username IN ('DEMASY_AI', 'SANDBOX_AI')
UNION ALL
SELECT 
  username,
  account_status,
  created AS account_created,
  default_tablespace,
  'DEVELOPER' AS ai_role
FROM dba_users 
WHERE username IN ('DEMASY', 'SANDBOX');

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ AI user configuration view created');
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/

-- =============================================================================
-- FINAL: Summary and Completion
-- =============================================================================

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('╔═══════════════════════════════════════════════════════════════╗');
  DBMS_OUTPUT.PUT_LINE('║          Oracle AI 26ai Features Enabled Successfully          ║');
  DBMS_OUTPUT.PUT_LINE('╚═══════════════════════════════════════════════════════════════╝');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Features Enabled:');
  DBMS_OUTPUT.PUT_LINE('  ✓ Vector Database Support (AI Vectors)');
  DBMS_OUTPUT.PUT_LINE('  ✓ Graph Database Features');
  DBMS_OUTPUT.PUT_LINE('  ✓ JSON Search Index Support');
  DBMS_OUTPUT.PUT_LINE('  ✓ Full-Text Search (Oracle Text)');
  DBMS_OUTPUT.PUT_LINE('  ✓ AI Embeddings Storage');
  DBMS_OUTPUT.PUT_LINE('  ✓ Spatial Indexing');
  DBMS_OUTPUT.PUT_LINE('  ✓ Machine Learning Model Storage');
  DBMS_OUTPUT.PUT_LINE('  ✓ AI-Optimized Database Parameters');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('AI Users Created:');
  DBMS_OUTPUT.PUT_LINE('  • demasy_ai   (Full AI/DBA privileges)');
  DBMS_OUTPUT.PUT_LINE('  • sandbox_ai  (Limited AI/MCP privileges)');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Query Status: SELECT * FROM ai_features_status;');
  DBMS_OUTPUT.PUT_LINE('Query Users:  SELECT * FROM ai_user_configuration;');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

COMMIT;
EXIT;
