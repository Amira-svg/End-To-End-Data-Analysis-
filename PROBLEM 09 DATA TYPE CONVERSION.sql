USE outbreak_x_raw;



-- ============================================================
-- PROBLEM 08: DATA TYPE CONVERSION & CLEAN TABLES
-- STEP 1: مراجعة الـTEXT columns الموجودة في قاعدة البيانات
-- ============================================================
-- الهدف معرفة كل الأعمدة المخزنة كـTEXT قبل تحديد
-- الأعمدة التي تحتاج Data Type Conversion.
--
-- لا يوجد UPDATE أو ALTER هنا.

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND DATA_TYPE = 'text'
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- ============================================================
-- STEP 2: فحص Adherence_Percentage قبل تحويل Data Type
-- ============================================================
-- نتحقق هل القيم رقمية فعلًا، وهل يوجد أي قيم غير رقمية.
-- لا يوجد أي UPDATE أو ALTER في هذه المرحلة.

SELECT
    COUNT(*) AS total_rows,
    SUM(
        CASE
            WHEN Adherence_Percentage IS NOT NULL
             AND TRIM(Adherence_Percentage) <> ''
             AND TRIM(Adherence_Percentage) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'
            THEN 1
            ELSE 0
        END
    ) AS invalid_numeric_rows,
    MIN(CAST(TRIM(Adherence_Percentage) AS DECIMAL(10,2))) AS minimum_value,
    MAX(CAST(TRIM(Adherence_Percentage) AS DECIMAL(10,2))) AS maximum_value
FROM raw_adherence;


-- ============================================================
-- STEP 3: تحديد القيم غير المنطقية في Adherence_Percentage
-- ============================================================
-- النطاق المقبول للـAdherence_Percentage هو من 0 إلى 100.
-- نعرض كل قيمة خارج هذا النطاق وعدد مرات ظهورها.
--
-- لا يوجد UPDATE هنا.

SELECT
    Adherence_Percentage,
    COUNT(*) AS total_count
FROM raw_adherence
WHERE Adherence_Percentage IS NOT NULL
  AND (
       CAST(TRIM(Adherence_Percentage) AS DECIMAL(10,2)) < 0
       OR CAST(TRIM(Adherence_Percentage) AS DECIMAL(10,2)) > 100
  )
GROUP BY Adherence_Percentage
ORDER BY total_count DESC;



-- ============================================================
-- STEP 4: تنظيف القيم خارج النطاق في Adherence_Percentage
-- ============================================================
-- النطاق المنطقي للـAdherence_Percentage هو 0 إلى 100.
--
-- القيم:
-- 150.0
-- 101.0
-- -25.0
-- كلها خارج النطاق المنطقي.
--
-- لا نستطيع معرفة القيمة الصحيحة الأصلية،
-- لذلك نحولها إلى NULL بدل تخمين قيمة.
--
-- سيتم تعديل القيم خارج النطاق فقط.

UPDATE raw_adherence
SET Adherence_Percentage = NULL
WHERE CAST(TRIM(Adherence_Percentage) AS DECIMAL(10,2)) < 0
   OR CAST(TRIM(Adherence_Percentage) AS DECIMAL(10,2)) > 100;


-- ============================================================
-- STEP 5: Validation بعد تنظيف Adherence_Percentage
-- ============================================================
-- نتأكد أنه لم يعد هناك أي قيمة خارج النطاق 0-100.

SELECT
    COUNT(*) AS remaining_invalid_range
FROM raw_adherence
WHERE Adherence_Percentage IS NOT NULL
  AND (
       CAST(TRIM(Adherence_Percentage) AS DECIMAL(10,2)) < 0
       OR CAST(TRIM(Adherence_Percentage) AS DECIMAL(10,2)) > 100
  );


-- ============================================================
-- STEP 6: تحويل Adherence_Percentage من TEXT إلى DECIMAL
-- ============================================================
-- بعد تنظيف القيم خارج النطاق والتأكد من عدم وجود
-- قيم غير صالحة، نحول العمود إلى DECIMAL.
--
-- DECIMAL مناسب لأنه يمثل النسب المئوية بدقة.

ALTER TABLE raw_adherence
MODIFY COLUMN Adherence_Percentage DECIMAL(5,2) NULL;


-- ============================================================
-- STEP 7: Validation للـData Type
-- ============================================================
-- نتأكد أن Adherence_Percentage أصبح DECIMAL.

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'raw_adherence'
  AND COLUMN_NAME = 'Adherence_Percentage';


-- ============================================================
-- STEP 8: تحويل الأعمدة الرقمية في raw_adherence
-- ============================================================
-- Expected_Doses و Taken_Doses يمثلان أعداد جرعات صحيحة،
-- لذلك نحولهما إلى INT.
--
-- تم فحص القيم مسبقًا ولم نجد قيمًا غير رقمية.

ALTER TABLE raw_adherence
MODIFY COLUMN Expected_Doses INT NULL,
MODIFY COLUMN Taken_Doses INT NULL;


-- ============================================================
-- STEP 9: التحقق من Data Types في raw_adherence
-- ============================================================

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'raw_adherence'
  AND COLUMN_NAME IN (
      'Expected_Doses',
      'Taken_Doses',
      'Adherence_Percentage'
  )
ORDER BY ORDINAL_POSITION;




-- ============================================================
-- STEP 10: تحويل الأعمدة الرقمية في raw_location
-- ============================================================
-- الأعمدة الثلاثة تحتوي على قيم رقمية،
-- وتم فحصها مسبقًا ولم نجد قيمًا غير رقمية.
--
-- نستخدم DECIMAL لأن Population_Density و Crowding_Index
-- يمكن أن يحتويان على كسور عشرية.

ALTER TABLE raw_location
MODIFY COLUMN Population INT NULL,
MODIFY COLUMN Population_Density DECIMAL(12,2) NULL,
MODIFY COLUMN Crowding_Index DECIMAL(12,2) NULL;




-- ============================================================
-- STEP 11: التحقق من Data Types في raw_location
-- ============================================================

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'raw_location'
  AND COLUMN_NAME IN (
      'Population',
      'Population_Density',
      'Crowding_Index'
  )
ORDER BY ORDINAL_POSITION;



-- ============================================================
-- STEP 12: تحويل Recovery_Days من TEXT إلى INT
-- ============================================================
-- Recovery_Days يمثل عدد أيام التعافي، لذلك النوع المناسب
-- هو INT.
--
-- القيم السالبة غير المنطقية تم تنظيفها مسبقًا وتحويلها
-- إلى NULL.
--
-- القيم الصحيحة المتبقية أعداد صحيحة.

ALTER TABLE raw_outcome
MODIFY COLUMN Recovery_Days INT NULL;



-- ============================================================
-- STEP 13: التحقق من Data Type في raw_outcome
-- ============================================================

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'raw_outcome'
  AND COLUMN_NAME = 'Recovery_Days';


-- ============================================================
-- STEP 14: فحص أعمدة التاريخ في raw_case
-- ============================================================
-- نتأكد أن القيم الموجودة تتبع صيغة YYYY-MM-DD
-- قبل تحويلها من TEXT إلى DATE.
--
-- لا يوجد ALTER أو UPDATE هنا.

SELECT
    'Diagnosis_Date' AS column_name,
    COUNT(*) AS total_rows,
    SUM(
        CASE
            WHEN Diagnosis_Date IS NOT NULL
             AND TRIM(Diagnosis_Date) <> ''
             AND TRIM(Diagnosis_Date) NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN 1
            ELSE 0
        END
    ) AS invalid_format
FROM raw_case

UNION ALL

SELECT
    'Symptom_Onset_Date',
    COUNT(*),
    SUM(
        CASE
            WHEN Symptom_Onset_Date IS NOT NULL
             AND TRIM(Symptom_Onset_Date) <> ''
             AND TRIM(Symptom_Onset_Date) NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN 1
            ELSE 0
        END
    )
FROM raw_case;



-- ============================================================
-- STEP 15: فحص Recovery_Date و BirthDate
-- ============================================================
-- نتأكد أن القيم تتبع صيغة YYYY-MM-DD قبل تحويلها
-- من TEXT إلى DATE.

SELECT
    'Recovery_Date' AS column_name,
    COUNT(*) AS total_rows,
    SUM(
        CASE
            WHEN Recovery_Date IS NOT NULL
             AND TRIM(Recovery_Date) <> ''
             AND TRIM(Recovery_Date) NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN 1
            ELSE 0
        END
    ) AS invalid_format
FROM raw_outcome

UNION ALL

SELECT
    'BirthDate',
    COUNT(*),
    SUM(
        CASE
            WHEN BirthDate IS NOT NULL
             AND TRIM(BirthDate) <> ''
             AND TRIM(BirthDate) NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN 1
            ELSE 0
        END
    )
FROM raw_patient;


-- ============================================================
-- STEP 16: فحص Start_Date و End_Date
-- ============================================================
-- نتأكد أن القيم تتبع صيغة YYYY-MM-DD
-- قبل تحويلها من TEXT إلى DATE.

SELECT
    'Start_Date' AS column_name,
    COUNT(*) AS total_rows,
    SUM(
        CASE
            WHEN Start_Date IS NOT NULL
             AND TRIM(Start_Date) <> ''
             AND TRIM(Start_Date) NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN 1
            ELSE 0
        END
    ) AS invalid_format
FROM raw_patient_treatment

UNION ALL

SELECT
    'End_Date',
    COUNT(*),
    SUM(
        CASE
            WHEN End_Date IS NOT NULL
             AND TRIM(End_Date) <> ''
             AND TRIM(End_Date) NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN 1
            ELSE 0
        END
    )
FROM raw_patient_treatment;



-- ============================================================
-- STEP 17: تحويل أعمدة التاريخ من TEXT إلى DATE
-- ============================================================
-- تم فحص جميع الأعمدة والتأكد أن صيغة التواريخ صحيحة.
-- لذلك نحولها إلى DATE لتحسين جودة البيانات والتعامل معها
-- بشكل صحيح في MySQL.
--
-- الأعمدة:
-- raw_case:
--   Diagnosis_Date
--   Symptom_Onset_Date
--
-- raw_outcome:
--   Recovery_Date
--
-- raw_patient:
--   BirthDate
--
-- raw_patient_treatment:
--   Start_Date
--   End_Date

ALTER TABLE raw_case
MODIFY COLUMN Diagnosis_Date DATE NULL,
MODIFY COLUMN Symptom_Onset_Date DATE NULL;

ALTER TABLE raw_outcome
MODIFY COLUMN Recovery_Date DATE NULL;

ALTER TABLE raw_patient
MODIFY COLUMN BirthDate DATE NULL;

ALTER TABLE raw_patient_treatment
MODIFY COLUMN Start_Date DATE NULL,
MODIFY COLUMN End_Date DATE NULL;



-- ============================================================
-- STEP 18: التحقق من Data Types لجميع أعمدة التاريخ
-- ============================================================
-- نتأكد أن كل أعمدة التاريخ أصبحت DATE بالفعل.

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND DATA_TYPE = 'date'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- ============================================================
-- STEP 19: التحقق النهائي من جميع أعمدة التاريخ
-- ============================================================
-- نتأكد أن الأعمدة الستة أصبحت DATE بالفعل.

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND (
       (TABLE_NAME = 'raw_case'
        AND COLUMN_NAME IN ('Diagnosis_Date', 'Symptom_Onset_Date'))
    OR (TABLE_NAME = 'raw_outcome'
        AND COLUMN_NAME = 'Recovery_Date')
    OR (TABLE_NAME = 'raw_patient'
        AND COLUMN_NAME = 'BirthDate')
    OR (TABLE_NAME = 'raw_patient_treatment'
        AND COLUMN_NAME IN ('Start_Date', 'End_Date'))
  )
ORDER BY TABLE_NAME, COLUMN_NAME;



-- ============================================================
-- STEP 21: Final Validation لأعمدة التاريخ
-- ============================================================
-- التأكد أن الأعمدة الستة أصبحت DATE.

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND (
       (TABLE_NAME = 'raw_case'
        AND COLUMN_NAME IN ('Diagnosis_Date', 'Symptom_Onset_Date'))
    OR (TABLE_NAME = 'raw_outcome'
        AND COLUMN_NAME = 'Recovery_Date')
    OR (TABLE_NAME = 'raw_patient'
        AND COLUMN_NAME = 'BirthDate')
    OR (TABLE_NAME = 'raw_patient_treatment'
        AND COLUMN_NAME IN ('Start_Date', 'End_Date'))
  )
ORDER BY TABLE_NAME, COLUMN_NAME;

















































































