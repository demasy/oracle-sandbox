-- TOP QUERIES BY CPU TIME
-- Shows the 10 most CPU-intensive queries in the database
-- Compatible with Oracle 19c+
-- Last Updated: 2026-06-22

SELECT sql_id, 
       SUBSTR(sql_text, 1, 80) as sql_snippet,
       executions,
       ROUND(cpu_time / 1000000, 2) as cpu_secs,
       ROUND(cpu_time / executions / 1000, 2) as avg_cpu_ms
FROM v$sql
WHERE executions > 0
  AND sql_text NOT LIKE '%v$%'
  AND sql_text NOT LIKE '%dba_%'
ORDER BY cpu_time DESC
FETCH FIRST 10 ROWS ONLY;
