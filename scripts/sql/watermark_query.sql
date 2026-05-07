-- =============================================
-- Watermark Queries for Incremental Load
-- Pipeline: pipeline3_Sql_Data_migration_to_ADLS
-- =============================================

-- Step 1: Get the latest watermark from source table
-- Used by Lookup1_latest_load activity
SELECT MAX(booking_date) AS latestload
FROM dbo.FactBookings;

-- Step 2: Full incremental query used in Copy Activity source
-- (ADF replaces @{...} expressions at runtime)
/*
SELECT * FROM dbo.FactBookings
WHERE booking_date > '@{activity('Lookup1_last_load').output.firstRow.lastload}'
  AND booking_date <= '@{activity('Lookup1_latest_load').output.firstRow.latestload}'
*/

-- Step 3: Verify row counts before and after a run
SELECT
    COUNT(*)                        AS total_rows,
    MAX(booking_date)               AS latest_booking,
    MIN(booking_date)               AS earliest_booking
FROM dbo.FactBookings;
