-- TABLESPACE USAGE REPORT
-- Shows all tablespaces with size, used/free space, and percentage used
-- Compatible with Oracle 19c+
-- Last Updated: 2026-06-22

SELECT t.tablespace_name,
       ROUND(df.total_space / 1024 / 1024, 2) as size_mb,
       ROUND((df.total_space - fs.free_space) / 1024 / 1024, 2) as used_mb,
       ROUND(fs.free_space / 1024 / 1024, 2) as free_mb,
       ROUND(100 * (df.total_space - fs.free_space) / df.total_space, 2) as pct_used
FROM dba_tablespaces t
LEFT JOIN (SELECT tablespace_name, SUM(bytes) as total_space 
           FROM dba_data_files 
           GROUP BY tablespace_name) df 
  ON t.tablespace_name = df.tablespace_name
LEFT JOIN (SELECT tablespace_name, SUM(bytes) as free_space 
           FROM dba_free_space 
           GROUP BY tablespace_name) fs 
  ON t.tablespace_name = fs.tablespace_name
ORDER BY pct_used DESC;
