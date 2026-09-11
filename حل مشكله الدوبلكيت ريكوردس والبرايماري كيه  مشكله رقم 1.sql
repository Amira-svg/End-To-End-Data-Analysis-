USE outbreak_x_raw;

-- ============================================================
-- PROBLEM 01: DUPLICATE PATIENT RECORDS
-- ============================================================
-- الهدف:
-- اكتشاف الـ Duplicate Records الموجودة في raw_patient،
-- تحليل حجم المشكلة، تحديد الـ Exact Duplicates،
-- حذف النسخ الزائدة، ثم التأكد من نجاح عملية التنظيف.
--
-- النتيجة التي اكتشفناها:
-- 201,999 records قبل التنظيف
-- 2,500 Patient_ID ظهروا مرتين
-- 2,500 duplicate rows سيتم حذفهم
-- 199,499 records بعد التنظيف
-- ============================================================



-- ============================================================
-- STEP 1: DETECT DUPLICATE PATIENT_IDs
-- ============================================================
-- GROUP BY Patient_ID:
-- يجمع كل الـ records التي لها نفس Patient_ID.
--
-- COUNT(*):
-- يحسب عدد مرات ظهور كل Patient_ID.
--
-- HAVING COUNT(*) > 1:
-- يعرض فقط الـ Patient_IDs التي ظهرت أكثر من مرة.
--
-- ORDER BY:
-- يرتب النتائج من الأكثر تكرارًا إلى الأقل.

SELECT
    Patient_ID,
    COUNT(*) AS occurrence_count
FROM raw_patient
GROUP BY Patient_ID
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;



-- ============================================================
-- STEP 2: INSPECT A SPECIFIC DUPLICATE
-- ============================================================
-- اخترنا Patient_ID = 16 كمثال على Duplicate.
--
-- الهدف هنا ليس فقط معرفة أن الـID متكرر،
-- ولكن معرفة هل الـrecords متطابقة تمامًا
-- أم أن هناك اختلافًا في بيانات المريض.
--
-- لو كل الأعمدة متطابقة، فهذا يسمى Exact Duplicate.

SELECT *
FROM raw_patient
WHERE Patient_ID = '16';



-- ============================================================
-- STEP 3: COMPARE TOTAL ROWS WITH UNIQUE PATIENT IDs
-- ============================================================
-- COUNT(*):
-- يحسب إجمالي عدد الـrecords في الجدول.
--
-- COUNT(DISTINCT Patient_ID):
-- يحسب عدد الـPatient_IDs المختلفة فقط.
--
-- الفرق بين الرقمين يساعدنا في معرفة حجم التكرار.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Patient_ID) AS unique_patient_ids
FROM raw_patient;



-- ============================================================
-- STEP 4: ANALYZE THE DUPLICATION PATTERN
-- ============================================================
-- الـSubquery الداخلي يحسب عدد مرات ظهور كل Patient_ID.
--
-- الـQuery الخارجي يجمع النتائج حسب عدد مرات التكرار.
--
-- هذا يسمح لنا بمعرفة:
-- كم Patient ظهر مرة واحدة؟
-- كم Patient ظهر مرتين؟
-- كم Patient ظهر 3 مرات؟
-- وهكذا.
--
-- النتيجة التي اكتشفناها:
-- 196,999 Patient_ID ظهر مرة واحدة.
-- 2,500 Patient_ID ظهر مرتين.
-- لا يوجد Patient_ID ظهر 3 مرات أو أكثر.

SELECT
    occurrence_count,
    COUNT(*) AS number_of_patient_ids
FROM (
    SELECT
        Patient_ID,
        COUNT(*) AS occurrence_count
    FROM raw_patient
    GROUP BY Patient_ID
) AS x
GROUP BY occurrence_count
ORDER BY occurrence_count;



-- ============================================================
-- STEP 5: EXPERIMENT WITH ROW_NUMBER()
-- ============================================================
-- ROW_NUMBER() يعطي رقمًا تسلسليًا لكل record.
--
-- PARTITION BY Patient_ID:
-- يبدأ العد من جديد لكل Patient_ID.
--
-- مثال:
--
-- Patient_ID = 16
-- Record 1 → rn = 1
-- Record 2 → rn = 2
--
-- وبالتالي:
-- rn = 1  → أول occurrence
-- rn > 1  → Duplicate occurrence
--
-- هنا نحن فقط نعرض النتيجة ولا نحذف أي شيء.

SELECT
    Patient_ID,
    Fname,
    Lname,
    BirthDate,
    Gender,
    Occupation,
    Location_ID,
    ROW_NUMBER() OVER (
        PARTITION BY Patient_ID
        ORDER BY Patient_ID
    ) AS rn
FROM raw_patient;



-- ============================================================
-- STEP 6: PREVIEW DUPLICATE RECORDS
-- ============================================================
-- هنا نضع نتيجة ROW_NUMBER() داخل Subquery
-- ثم نطلب فقط records التي لديها rn > 1.
--
-- هذه هي records التي سيتم اعتبارها
-- redundant duplicate records.
--
-- ما زلنا لا نحذف أي شيء.

SELECT *
FROM (
    SELECT
        Patient_ID,
        Fname,
        Lname,
        BirthDate,
        Gender,
        Occupation,
        Location_ID,
        ROW_NUMBER() OVER (
            PARTITION BY Patient_ID
            ORDER BY Patient_ID
        ) AS rn
    FROM raw_patient
) AS ranked
WHERE rn > 1;



-- ============================================================
-- STEP 7: CHECK THE NUMBER OF RECORDS BEFORE CLEANING
-- ============================================================
-- نحفظ عدد الـrecords قبل عملية الحذف
-- حتى نستطيع مقارنة Before vs After.

SELECT COUNT(*) AS before_count
FROM raw_patient;



-- ============================================================
-- STEP 8: ADD A UNIQUE ROW IDENTIFIER
-- ============================================================
-- المشكلة:
-- Patient_ID متكرر في الـDirty Dataset،
-- لذلك لا يمكننا استخدامه وحده لتحديد صف معين للحذف.
--
-- الحل:
-- نضيف row_id ليكون Unique لكل record.
--
-- AUTO_INCREMENT:
-- يعطي كل record رقمًا مختلفًا تلقائيًا.
--
-- PRIMARY KEY:
-- يجعل row_id فريدًا لكل record.

ALTER TABLE raw_patient
ADD COLUMN row_id BIGINT AUTO_INCREMENT PRIMARY KEY FIRST;



-- ============================================================
-- STEP 9: VERIFY DUPLICATES AFTER ADDING row_id
-- ============================================================
-- إضافة row_id لا تنظف البيانات.
-- لذلك نعيد فحص الـduplicates للتأكد أن المشكلة
-- ما زالت موجودة قبل الحذف.

SELECT
    Patient_ID,
    COUNT(*) AS occurrence_count
FROM raw_patient
GROUP BY Patient_ID
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;



-- ============================================================
-- STEP 10: IDENTIFY THE EXACT ROWS TO DELETE
-- ============================================================
-- الآن نستخدم row_id في ORDER BY.
--
-- لكل Patient_ID:
--
-- rn = 1 → أول record → نحتفظ به
-- rn = 2 → ثاني record → Duplicate
--
-- row_id يجعل كل record قابلًا للتحديد بشكل منفصل.

SELECT *
FROM (
    SELECT
        row_id,
        Patient_ID,
        Fname,
        Lname,
        BirthDate,
        Gender,
        Occupation,
        Location_ID,
        ROW_NUMBER() OVER (
            PARTITION BY Patient_ID
            ORDER BY row_id
        ) AS rn
    FROM raw_patient
) AS ranked
WHERE rn > 1;



-- ============================================================
-- STEP 11: DELETE DUPLICATE RECORDS
-- ============================================================
-- نحذف فقط الـrow_id التي حصلت على rn > 1.
--
-- وبالتالي:
-- أول occurrence لكل Patient_ID يتم الاحتفاظ به.
-- النسخة الثانية الزائدة يتم حذفها.
--
-- هذه الطريقة أكثر أمانًا من:
--
-- DELETE WHERE Patient_ID = ...
--
-- لأن Patient_ID المتكرر موجود في أكثر من record.

DELETE FROM raw_patient
WHERE row_id IN (
    SELECT row_id
    FROM (
        SELECT
            row_id,
            ROW_NUMBER() OVER (
                PARTITION BY Patient_ID
                ORDER BY row_id
            ) AS rn
        FROM raw_patient
    ) AS ranked
    WHERE rn > 1
);



-- ============================================================
-- STEP 12: CHECK THE NUMBER OF RECORDS AFTER CLEANING
-- ============================================================
-- نتحقق من عدد الـrecords بعد عملية الحذف.
--
-- Expected:
--
-- Before = 201,999
-- Duplicate rows removed = 2,500
-- After = 199,499

SELECT COUNT(*) AS after_count
FROM raw_patient;



-- ============================================================
-- STEP 13: FINAL DUPLICATE VALIDATION
-- ============================================================
-- نعيد فحص الـPatient_IDs مرة أخرى.
--
-- لو الـQuery لم ترجع أي rows:
-- فهذا يعني أنه لم يعد هناك Patient_ID مكرر.

SELECT
    Patient_ID,
    COUNT(*) AS occurrence_count
FROM raw_patient
GROUP BY Patient_ID
HAVING COUNT(*) > 1;



-- ============================================================
-- STEP 14: VALIDATE PATIENT_ID VALUES
-- ============================================================
-- قبل تحويل Patient_ID من TEXT إلى INT،
-- نتأكد أن كل القيم:
--
-- 1. ليست NULL
-- 2. تحتوي على أرقام فقط.
--
-- REGEXP:
-- يتحقق من أن القيمة تتكون من digits فقط.
--
-- Expected:
-- 0 rows.

SELECT Patient_ID
FROM raw_patient
WHERE Patient_ID IS NULL
   OR Patient_ID NOT REGEXP '^[0-9]+$';



-- ============================================================
-- STEP 15: REMOVE THE TEMPORARY row_id
-- ============================================================
-- بعد انتهاء عملية Duplicate Cleaning،
-- لم نعد بحاجة إلى row_id.
--
-- لذلك نحذفه من الـraw_patient table.

ALTER TABLE raw_patient
DROP COLUMN row_id;



-- ============================================================
-- STEP 16: CONVERT Patient_ID FROM TEXT TO INT
-- ============================================================
-- Patient_ID يمثل رقمًا وليس نصًا.
--
-- تحويله إلى INT يجعل نوع البيانات مناسبًا لطبيعة الـID
-- ويسمح باستخدامه كـPrimary Key.
--
-- NOT NULL:
-- يمنع وجود Patient_ID بدون قيمة.

ALTER TABLE raw_patient
MODIFY COLUMN Patient_ID INT NOT NULL;



-- ============================================================
-- STEP 17: ADD Patient_ID AS PRIMARY KEY
-- ============================================================
-- بعد التأكد من:
--
-- 1. عدم وجود Duplicates
-- 2. عدم وجود NULL values
-- 3. أن Patient_ID أصبح INT
--
-- نستطيع استخدام Patient_ID كـPrimary Key.

ALTER TABLE raw_patient
ADD PRIMARY KEY (Patient_ID);



-- ============================================================
-- STEP 18: VERIFY THE FINAL COLUMN DEFINITION
-- ============================================================
-- نتحقق من نوع Patient_ID بعد التعديل.

SHOW COLUMNS FROM raw_patient LIKE 'Patient_ID';



-- ============================================================
-- STEP 19: VERIFY THE FINAL TABLE STRUCTURE
-- ============================================================
-- SHOW CREATE TABLE يعرض الـCREATE statement الكامل
-- للجدول، وبالتالي نستطيع التأكد من:
--
-- Patient_ID datatype
-- NOT NULL
-- PRIMARY KEY
-- وباقي Structure الجدول.

SHOW CREATE TABLE raw_patient;