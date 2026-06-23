-- ACTIVE CONNECTIONS REPORT
-- Shows active database sessions by username and status
-- Compatible with Oracle 19c+
-- Last Updated: 2026-06-22

SELECT username, 
       status, 
       COUNT(*) as session_count, 
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM v$session), 2) as pct_of_total
FROM v$session
WHERE username IS NOT NULL
GROUP BY username, status
ORDER BY session_count DESC;
