USE outbreak_x_raw;





-- ============================================================
-- PROBLEM 02: MISSING VALUES / NULLS
-- ============================================================
-- الهدف:
-- اكتشاف الـNULL values الموجودة في أعمدة جدول raw_patient،
-- تحديد حجم المشكلة، تحليل الـNULLs الموجودة في Occupation،
-- ثم معالجة القيم المفقودة والتحقق من نجاح عملية التنظيف.
--
-- النتيجة التي اكتشفناها:
-- Fname        = 0 NULLs
-- Lname        = 0 NULLs
-- BirthDate    = 0 NULLs
-- Gender       = 0 NULLs
-- Occupation   = 996 NULLs
-- Location_ID  = 0 NULLs
--
-- لذلك كانت المشكلة موجودة فقط في Occupation.
-- ============================================================



-- ============================================================
-- STEP 1: COUNT NULL VALUES IN EACH COLUMN
-- ============================================================
-- الهدف من الـQuery هو عمل Data Quality Check للـPatient table.
--
-- CASE WHEN:
-- يفحص كل record:
-- لو القيمة NULL يرجع 1.
--
-- COUNT:
-- يحسب عدد القيم التي رجعت 1.
--
-- بالتالي نعرف عدد الـNULL values في كل Column
-- في Query واحدة بدل ما نعمل SELECT منفصل لكل Column.

SELECT
    COUNT(
        CASE
            WHEN Fname IS NULL THEN 1
        END
    ) AS Fname,

    COUNT(
        CASE
            WHEN Lname IS NULL THEN 1
        END
    ) AS Lname,

    COUNT(
        CASE
            WHEN BirthDate IS NULL THEN 1
        END
    ) AS BirthDate,

    COUNT(
        CASE
            WHEN Gender IS NULL THEN 1
        END
    ) AS Gender,

    COUNT(
        CASE
            WHEN Occupation IS NULL THEN 1
        END
    ) AS Occupation,

    COUNT(
        CASE
            WHEN Location_ID IS NULL THEN 1
        END
    ) AS Location_ID

FROM raw_patient;


-- ============================================================
-- RESULT OF STEP 1
-- ============================================================
-- Fname        → 0
-- Lname        → 0
-- BirthDate    → 0
-- Gender       → 0
-- Occupation   → 996
-- Location_ID  → 0
--
-- إذن المشكلة الوحيدة التي تحتاج Cleaning في هذه المرحلة
-- هي Occupation، ويوجد بها 996 NULL values.



-- ============================================================
-- STEP 2: ANALYZE OCCUPATION VALUES
-- ============================================================
-- بعد اكتشاف وجود 996 NULLs في Occupation،
-- نريد معرفة توزيع جميع قيم Occupation.
--
-- COALESCE:
-- إذا كانت Occupation = NULL، يعرضها مؤقتًا باسم "null"
-- حتى تظهر لنا في الـresult بشكل واضح.
--
-- COUNT(*):
-- يحسب عدد records لكل Occupation value.
--
-- GROUP BY Occupation:
-- يجمع الـrecords حسب قيمة Occupation.

SELECT
    COUNT(*) AS total_count,
    COALESCE(Occupation, 'null') AS `null`
FROM raw_patient
GROUP BY Occupation;


-- ============================================================
-- RESULT OF STEP 2
-- ============================================================
-- اتضح أن قيمة Occupation نفسها NULL موجودة في 996 records.
--
-- هنا تأكدنا أن المشكلة Missing Values حقيقية،
-- وليست مجرد اختلاف في طريقة عرض البيانات.



-- ============================================================
-- STEP 3: ANALYZE NULL OCCUPATION BY GENDER
-- ============================================================
-- قبل تعويض الـNULL values، لا نريد وضع قيمة عشوائية.
--
-- لذلك قمنا بتحليل الـ996 records حسب Gender
-- لمعرفة هل يوجد Pattern واضح يمكن استخدامه
-- لاستنتاج Occupation أم لا.
--
-- WHERE Occupation IS NULL:
-- نحلل فقط المرضى الذين لديهم Occupation مفقودة.
--
-- GROUP BY Occupation, Gender:
-- يقسم الـNULL records حسب Gender.

SELECT
    Gender,
    Occupation,
    COUNT(*) AS total_count
FROM raw_patient
WHERE Occupation IS NULL
GROUP BY Occupation, Gender;


-- ============================================================
-- RESULT OF STEP 3
-- ============================================================
-- NULL Occupation records:
--
-- Male   → 517
-- Female → 468
-- M      → 11
--
-- Gender وحده لا يعطي قاعدة موثوقة لتحديد Occupation.
-- لذلك لن نقوم بتخمين Occupation بناءً على Gender.



-- ============================================================
-- STEP 4: ANALYZE NULL OCCUPATION BY AGE GROUP
-- ============================================================
-- بعد ذلك قمنا بتحليل الـAge للمرضى الذين لديهم
-- Occupation = NULL.
--
-- TIMESTAMPDIFF:
-- يحسب عمر المريض بالسنوات اعتمادًا على BirthDate.
--
-- CASE:
-- يحول العمر إلى Age Groups ليسهل تحليل البيانات.
--
-- تم تقسيم المرضى إلى:
-- 18-25
-- 26-35
-- 36-50
-- 50+
--
-- الهدف:
-- معرفة هل يوجد Pattern واضح بين Age Group
-- والـmissing Occupation.

SELECT
    age_group,
    COUNT(*) AS total_count
FROM (
    SELECT
        CASE
            WHEN age BETWEEN 18 AND 25 THEN '18-25'
            WHEN age BETWEEN 26 AND 35 THEN '26-35'
            WHEN age BETWEEN 36 AND 50 THEN '36-50'
            WHEN age > 50 THEN '50+'
        END AS age_group
    FROM (
        SELECT
            BirthDate,
            Occupation,
            TIMESTAMPDIFF(
                YEAR,
                BirthDate,
                CURDATE()
            ) AS age
        FROM raw_patient
        WHERE Occupation IS NULL
    ) AS ages
) AS group_data
GROUP BY age_group;


-- ============================================================
-- RESULT OF STEP 4
-- ============================================================
-- NULL Occupation records were distributed across
-- different age groups.
--
-- 36-50 → 286
-- 26-35 → 197
-- 50+   → 358
-- Other/under 26 → 155
--
-- Age Group also did not provide a sufficiently reliable
-- rule to determine the actual Occupation.
--
-- لذلك قررنا عدم عمل Imputation بتخمين Occupation.



-- ============================================================
-- STEP 5: HANDLE MISSING OCCUPATION VALUES
-- ============================================================
-- بما أننا لا نملك قاعدة موثوقة نستطيع من خلالها
-- استنتاج Occupation الحقيقي للـ996 records،
-- لن نقوم باختراع بيانات.
--
-- بدلًا من ذلك:
-- NULL → Unknown
--
-- Unknown تعني أن قيمة Occupation الأصلية غير متوفرة
-- ولا نملك معلومات كافية لاستنتاجها.
--
-- هذه الطريقة تحافظ على Data Integrity
-- بدلًا من إدخال قيم غير مؤكدة.

UPDATE raw_patient
SET Occupation = 'Unknown'
WHERE Occupation IS NULL;



-- ============================================================
-- STEP 6: VALIDATE THAT NO NULL OCCUPATION REMAINS
-- ============================================================
-- بعد الـUPDATE، نتحقق من عدد الـNULL values المتبقية
-- في Occupation.
--
-- Expected Result:
-- remaining_nulls = 0
--
-- إذا كانت النتيجة 0، فهذا يعني أن جميع الـ996
-- Missing Values تمت معالجتها.

SELECT
    COUNT(*) AS remaining_nulls
FROM raw_patient
WHERE Occupation IS NULL;



-- ============================================================
-- STEP 7: VALIDATE THE NEW OCCUPATION DISTRIBUTION
-- ============================================================
-- نعرض توزيع Occupation بعد عملية التنظيف.
--
-- الهدف:
-- التأكد من أن قيمة Unknown تمت إضافتها
-- وأن عددها يساوي عدد الـNULL values التي اكتشفناها.
--
-- Expected:
-- Unknown → 996

SELECT
    Occupation,
    COUNT(*) AS count
FROM raw_patient
GROUP BY Occupation
ORDER BY count DESC;



-- ============================================================
-- FINAL RESULT
-- ============================================================
-- Problem:
-- 996 NULL values in Occupation.
--
-- Analysis:
-- Gender and Age Group were investigated,
-- but neither provided a reliable rule for determining
-- the missing occupations.
--
-- Cleaning Decision:
-- NULL Occupation → 'Unknown'
--
-- Validation:
-- Remaining NULL Occupation values → 0
--
-- Data Integrity:
-- No occupation was guessed or artificially assigned.
-- ============================================================










