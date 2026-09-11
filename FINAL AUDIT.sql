USE outbreak_x_raw;


-- ============================================================
-- FINAL AUDIT - STEP 1
-- فحص العلاقات والتأكد من عدم وجود Foreign Key References
-- تشير إلى Records غير موجودة في الجداول المرجعية.
-- ============================================================

SELECT
    COUNT(*) AS invalid_patient_locations
FROM raw_patient p
LEFT JOIN raw_location l
    ON p.Location_ID = l.Location_ID
WHERE p.Location_ID IS NOT NULL
  AND l.Location_ID IS NULL;


-- ============================================================
-- FINAL AUDIT - STEP 2
-- فحص Recovery_Days بعد التنظيف.
-- نتأكد أنه لا توجد قيم سالبة أو قيم غير رقمية.
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN Recovery_Days IS NOT NULL
             AND Recovery_Days < 0
            THEN 1
            ELSE 0
        END
    ) AS negative_values,

    SUM(
        CASE
            WHEN Recovery_Days IS NOT NULL
             AND Recovery_Days < 0
            THEN 1
            ELSE 0
        END
    ) AS invalid_range_values
FROM raw_outcome;




-- ============================================================
-- FINAL AUDIT - STEP 3
-- فحص Adherence_Percentage.
-- النطاق المقبول من 0 إلى 100.
-- ============================================================

SELECT
    COUNT(*) AS invalid_adherence_values
FROM raw_adherence
WHERE Adherence_Percentage IS NOT NULL
  AND (
       Adherence_Percentage < 0
       OR Adherence_Percentage > 100
  );




-- ============================================================
-- FINAL AUDIT - STEP 4
-- التأكد من أن الأعمدة الرقمية أصبحت بالـData Types الصحيحة.
-- ============================================================

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND (
       (TABLE_NAME = 'raw_adherence'
        AND COLUMN_NAME IN (
            'Expected_Doses',
            'Taken_Doses',
            'Adherence_Percentage'
        ))

    OR (TABLE_NAME = 'raw_location'
        AND COLUMN_NAME IN (
            'Population',
            'Population_Density',
            'Crowding_Index'
        ))

    OR (TABLE_NAME = 'raw_outcome'
        AND COLUMN_NAME = 'Recovery_Days')
  )
ORDER BY TABLE_NAME, COLUMN_NAME;


-- ============================================================
-- FINAL AUDIT - STEP 5
-- التأكد من أن جميع أعمدة التاريخ أصبحت DATE.
-- ============================================================

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND (
       (TABLE_NAME = 'raw_case'
        AND COLUMN_NAME IN (
            'Diagnosis_Date',
            'Symptom_Onset_Date'
        ))

    OR (TABLE_NAME = 'raw_outcome'
        AND COLUMN_NAME = 'Recovery_Date')

    OR (TABLE_NAME = 'raw_patient'
        AND COLUMN_NAME = 'BirthDate')

    OR (TABLE_NAME = 'raw_patient_treatment'
        AND COLUMN_NAME IN (
            'Start_Date',
            'End_Date'
        ))
  )
ORDER BY TABLE_NAME, COLUMN_NAME;

















































