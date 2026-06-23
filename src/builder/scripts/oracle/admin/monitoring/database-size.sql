-- DATABASE SIZE REPORT
-- Shows total database size across all data files
-- Compatible with Oracle 19c+
-- Last Updated: 2026-06-22

SELECT ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2) as db_size_gb
FROM dba_data_files;
