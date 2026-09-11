USE outbreak_x_raw;


-- ============================================================
-- PROBLEM 04: INVALID / FUTURE BIRTH DATES
-- ============================================================
-- Objective:
-- Detect invalid birth dates that are later than the current date.
--
-- During the data quality analysis, we discovered that some
-- patients had a BirthDate in the future.
--
-- Total invalid records discovered: 599
-- Invalid date identified: 2099-01-01
-- ============================================================



-- ============================================================
-- STEP 1: DETECT FUTURE BIRTH DATES
-- ============================================================
-- This query retrieves all patient records where BirthDate
-- is greater than the current date.
--
-- CURDATE() returns the current date in MySQL.
--
-- Therefore:
--
-- BirthDate > CURDATE()
--
-- means that the recorded birth date is in the future,
-- which is logically invalid for a patient record.
--
-- This is our initial detection query.

SELECT *
FROM raw_patient
WHERE BirthDate > CURDATE();



-- ============================================================
-- STEP 2: IDENTIFY THE INVALID DATE AND ITS FREQUENCY
-- ============================================================
-- After detecting future dates, we need to know which specific
-- dates are causing the problem and how frequently they occur.
--
-- GROUP BY BirthDate:
-- Groups records according to their birth date.
--
-- COUNT(*):
-- Counts how many records contain each date.
--
-- ORDER BY total_count DESC:
-- Displays the most frequently occurring dates first.
--
-- Result:
-- 2099-01-01 → 599 records

SELECT
    BirthDate,
    COUNT(*) AS total_count
FROM raw_patient
WHERE BirthDate > CURDATE()
GROUP BY BirthDate
ORDER BY total_count DESC;



-- ============================================================
-- STEP 3: COUNT THE TOTAL NUMBER OF INVALID RECORDS
-- ============================================================
-- This query calculates the total number of patient records
-- containing a future BirthDate.
--
-- COUNT(*) is used to count all records that satisfy:
--
-- BirthDate > CURDATE()
--
-- Expected result:
-- 599 invalid birth dates.

SELECT
    COUNT(*) AS invalid_birthdates
FROM raw_patient
WHERE BirthDate > CURDATE();



-- ============================================================
-- STEP 4: ANALYZE THE AFFECTED RECORDS
-- ============================================================
-- Before modifying the invalid values, we analyze the affected
-- records using other available attributes.
--
-- We group the records by:
-- 1. Gender
-- 2. Occupation
--
-- The purpose is to determine whether there is a reliable
-- pattern that could help us infer the correct BirthDate.
--
-- Result:
-- The 599 affected records are distributed across different
-- genders and occupations.
--
-- Therefore, there is no reliable pattern that allows us
-- to determine the actual birth dates.

SELECT
    Gender,
    Occupation,
    COUNT(*) AS total_count
FROM raw_patient
WHERE BirthDate = '2099-01-01'
GROUP BY Gender, Occupation
ORDER BY total_count DESC;



-- ============================================================
-- STEP 5: VERIFY THE NUMBER OF RECORDS BEFORE UPDATE
-- ============================================================
-- Before performing the UPDATE, we perform an additional check
-- to confirm exactly how many records will be modified.
--
-- This is an important safety step before changing data.
--
-- Expected result:
-- records_to_update = 599

SELECT
    COUNT(*) AS records_to_update
FROM raw_patient
WHERE BirthDate = '2099-01-01';



-- ============================================================
-- STEP 6: CLEAN THE INVALID BIRTH DATES
-- ============================================================
-- The value 2099-01-01 was identified as an invalid future date.
--
-- We cannot determine the patients' actual birth dates from
-- the available data.
--
-- Therefore, instead of guessing or generating an artificial
-- date, we convert the invalid value to NULL.
--
-- NULL represents that the actual BirthDate is unknown or
-- unavailable.
--
-- The WHERE condition ensures that only the invalid
-- 2099-01-01 records are modified.
--
-- No patient records are deleted.

UPDATE raw_patient
SET BirthDate = NULL
WHERE BirthDate = '2099-01-01';



-- ============================================================
-- STEP 7: FINAL VALIDATION
-- ============================================================
-- After the UPDATE, we run the original detection query again.
--
-- The purpose is to verify that no future BirthDate values
-- remain in the dataset.
--
-- Expected result:
-- Empty result / 0 records.
--
-- This confirms that the invalid future birth dates were
-- successfully cleaned.

SELECT *
FROM raw_patient
WHERE BirthDate > CURDATE();



-- ============================================================
-- FINAL RESULT
-- ============================================================
-- Problem:
-- 599 patient records contained a future BirthDate.
--
-- Invalid value:
-- 2099-01-01
--
-- Cleaning action:
-- 2099-01-01 → NULL
--
-- Reason:
-- The correct birth dates could not be reliably determined,
-- so we avoided introducing fabricated data.
--
-- Records deleted:
-- 0
--
-- Remaining future BirthDates:
-- 0
--
-- Status:
-- PROBLEM 04 SUCCESSFULLY RESOLVED
-- ============================================================