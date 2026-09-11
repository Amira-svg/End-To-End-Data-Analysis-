USE outbreak_x_raw;


-- ============================================================
-- PROBLEM 07: INVALID NUMERIC VALUES
-- STEP 1: تحديد الأعمدة التي يفترض أن تحتوي على أرقام
-- ============================================================
-- أولاً نبدأ بالأعمدة الرقمية المعروفة في الداتا.
-- الهدف هو اكتشاف القيم غير الرقمية قبل أي تعديل.
--
-- لا يوجد UPDATE هنا، هذه مرحلة Detection فقط.

SELECT
    'raw_location.Population' AS column_name,
    COUNT(*) AS total_rows,
    SUM(
        CASE
            WHEN Population IS NOT NULL
             AND TRIM(Population) <> ''
             AND TRIM(Population) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'
            THEN 1
            ELSE 0
        END
    ) AS invalid_numeric_rows
FROM raw_location

UNION ALL

SELECT
    'raw_location.Population_Density',
    COUNT(*),
    SUM(
        CASE
            WHEN Population_Density IS NOT NULL
             AND TRIM(Population_Density) <> ''
             AND TRIM(Population_Density) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'
            THEN 1
            ELSE 0
        END
    )
FROM raw_location

UNION ALL

SELECT
    'raw_location.Crowding_Index',
    COUNT(*),
    SUM(
        CASE
            WHEN Crowding_Index IS NOT NULL
             AND TRIM(Crowding_Index) <> ''
             AND TRIM(Crowding_Index) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'
            THEN 1
            ELSE 0
        END
    )
FROM raw_location;





-- ============================================================
-- STEP 2: عرض أعمدة الجداول التي قد تحتوي على قيم رقمية
-- ============================================================
-- الهدف معرفة الـcolumns الفعلية قبل كتابة أي Detection Query.
-- لن نفترض أسماء أعمدة غير موجودة.

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND (
       DATA_TYPE IN ('int', 'bigint', 'decimal', 'float', 'double')
       OR COLUMN_NAME LIKE '%Dose%'
       OR COLUMN_NAME LIKE '%Days%'
       OR COLUMN_NAME LIKE '%Count%'
       OR COLUMN_NAME LIKE '%Population%'
       OR COLUMN_NAME LIKE '%Density%'
       OR COLUMN_NAME LIKE '%Index%'
  )
ORDER BY TABLE_NAME, ORDINAL_POSITION;



-- ============================================================
-- STEP 2: فحص القيم الرقمية في raw_adherence
-- ============================================================
-- Expected_Doses و Taken_Doses المفروض يكونوا أرقام صحيحة.
-- نبحث عن أي قيمة غير رقمية.

SELECT
    'Expected_Doses' AS column_name,
    COUNT(*) AS total_rows,
    SUM(
        CASE
            WHEN Expected_Doses IS NOT NULL
             AND TRIM(Expected_Doses) <> ''
             AND TRIM(Expected_Doses) NOT REGEXP '^[0-9]+$'
            THEN 1
            ELSE 0
        END
    ) AS invalid_numeric_rows
FROM raw_adherence

UNION ALL

SELECT
    'Taken_Doses',
    COUNT(*),
    SUM(
        CASE
            WHEN Taken_Doses IS NOT NULL
             AND TRIM(Taken_Doses) <> ''
             AND TRIM(Taken_Doses) NOT REGEXP '^[0-9]+$'
            THEN 1
            ELSE 0
        END
    )
FROM raw_adherence;



-- ============================================================
-- STEP 3: فحص القيم الرقمية في raw_outcome
-- ============================================================
-- Recovery_Days المفروض يكون رقمًا صحيحًا.
-- نبحث عن أي قيمة غير رقمية.

SELECT
    COUNT(*) AS total_rows,
    SUM(
        CASE
            WHEN Recovery_Days IS NOT NULL
             AND TRIM(Recovery_Days) <> ''
             AND TRIM(Recovery_Days) NOT REGEXP '^[0-9]+$'
            THEN 1
            ELSE 0
        END
    ) AS invalid_numeric_rows
FROM raw_outcome;


-- ============================================================
-- STEP 4: معرفة القيم غير الرقمية في Recovery_Days
-- ============================================================
-- نعرض كل قيمة غير رقمية وعدد مرات ظهورها.
-- الهدف معرفة هل هي NULL/Unknown أو نصوص أو قيم أخرى
-- قبل اتخاذ قرار التنظيف.

SELECT
    Recovery_Days,
    COUNT(*) AS total_count
FROM raw_outcome
WHERE Recovery_Days IS NOT NULL
  AND TRIM(Recovery_Days) <> ''
  AND TRIM(Recovery_Days) NOT REGEXP '^[0-9]+$'
GROUP BY Recovery_Days
ORDER BY total_count DESC;


-- ============================================================
-- STEP 5: التحقق من القيم السالبة في Recovery_Days
-- ============================================================
-- نتحقق أن كل القيم غير الصالحة هي أرقام سالبة،
-- ونرى أقل وأعلى قيمة سالبة وعدد السجلات المتأثرة.
--
-- لا يوجد UPDATE هنا.

SELECT
    COUNT(*) AS negative_records,
    MIN(CAST(TRIM(Recovery_Days) AS SIGNED)) AS minimum_value,
    MAX(CAST(TRIM(Recovery_Days) AS SIGNED)) AS maximum_negative_value
FROM raw_outcome
WHERE Recovery_Days IS NOT NULL
  AND TRIM(Recovery_Days) REGEXP '^-[0-9]+$';


-- ============================================================
-- STEP 6: فحص نطاق Recovery_Days الصحيح
-- ============================================================
-- نعرف أقل وأعلى قيمة غير سالبة في العمود.
-- الهدف التأكد من النطاق قبل تنظيف القيم السالبة.

SELECT
    MIN(CAST(TRIM(Recovery_Days) AS UNSIGNED)) AS minimum_valid_days,
    MAX(CAST(TRIM(Recovery_Days) AS UNSIGNED)) AS maximum_valid_days
FROM raw_outcome
WHERE Recovery_Days IS NOT NULL
  AND TRIM(Recovery_Days) REGEXP '^[0-9]+$';



-- ============================================================
-- STEP 7: تنظيف القيم السالبة في Recovery_Days
-- ============================================================
-- القيم من -1 إلى -39 غير منطقية لعدد أيام التعافي.
-- لا نستطيع معرفة القيمة الصحيحة الأصلية لها،
-- لذلك نحولها إلى NULL بدل تخمين قيمة.
--
-- سيتم تعديل القيم السالبة فقط.

UPDATE raw_outcome
SET Recovery_Days = NULL
WHERE Recovery_Days REGEXP '^-[0-9]+$';



-- ============================================================
-- STEP 8: التحقق من عدم وجود قيم سالبة بعد التنظيف
-- ============================================================
-- المفروض أن تكون النتيجة 0،
-- أي لا توجد أي Recovery_Days سالبة.

SELECT
    COUNT(*) AS remaining_negative_values
FROM raw_outcome
WHERE Recovery_Days REGEXP '^-[0-9]+$';



-- ============================================================
-- STEP 9: Final Validation لـ Recovery_Days
-- ============================================================
-- نتحقق من القيم غير الرقمية والقيم السالبة معًا.
-- الهدف التأكد أن العمود لا يحتوي على Invalid Numeric Values.

SELECT
    SUM(
        CASE
            WHEN Recovery_Days IS NOT NULL
             AND TRIM(Recovery_Days) <> ''
             AND TRIM(Recovery_Days) NOT REGEXP '^[0-9]+$'
            THEN 1
            ELSE 0
        END
    ) AS remaining_invalid_numeric
FROM raw_outcome;





