-- ARCHIVE LOG STATUS REPORT
-- Shows recovery destination space usage (if configured)
-- Compatible with Oracle 19c+
-- Last Updated: 2026-06-22

SELECT name, 
       ROUND(space_limit / 1024 / 1024 / 1024, 2) as limit_gb,
       ROUND(space_used / 1024 / 1024 / 1024, 2) as used_gb,
       ROUND(100 * space_used / space_limit, 2) as pct_used
FROM v$recovery_file_dest;
