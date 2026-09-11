-- ============================================================
-- PROBLEM 04: CATEGORY STANDARDIZATION + CONDITIONAL MISSING VALUES
-- ============================================================

USE outbreak_x_raw;


-- ============================================================
-- STEP 1: فحص قيم Occupation
-- ============================================================
-- في البداية قمنا بفحص قيم Occupation وعدد مرات ظهور كل قيمة.
-- الهدف هو التأكد من عدم وجود Categories مكررة أو مختلفة
-- في الكتابة وتمثل نفس الفئة.
--
-- بعد الفحص وجدنا أن قيم Occupation كانت Standardized
-- ولا توجد Category إضافية تحتاج إلى تعديل.
--
-- قيمة Unknown = 996 تمثل القيم التي كانت NULL في Problem 02
-- وتم تحويلها إلى Unknown بشكل مقصود.

SELECT
    Occupation,
    COUNT(*) AS total_count
FROM raw_patient
GROUP BY Occupation
ORDER BY total_count DESC;


-- ============================================================
-- STEP 2: عرض جميع الجداول الموجودة في قاعدة البيانات
-- ============================================================
-- استخدمنا SHOW TABLES لمعرفة جميع الجداول الموجودة في
-- قاعدة البيانات حتى لا نحصر فحص Category Standardization
-- في جدول raw_patient فقط.

SHOW TABLES;


-- ============================================================
-- STEP 3: تحديد الأعمدة النصية التي يمكن أن تحتوي على Categories
-- ============================================================
-- استخدمنا INFORMATION_SCHEMA.COLUMNS لمعرفة الأعمدة التي
-- نوع بياناتها CHAR أو VARCHAR أو TEXT أو ENUM.
--
-- الهدف هو تحديد الأعمدة النصية التي يمكن أن تحتوي على
-- Categorical Values وتحتاج إلى Data Quality Analysis.
--
-- ليس كل TEXT column يعتبر Category.
-- بعض الأعمدة النصية هي IDs أو Dates أو Numeric Values
-- مخزنة كنص، ولذلك سنحدد منها فقط الأعمدة المناسبة للتحليل.

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'outbreak_x_raw'
  AND DATA_TYPE IN ('char', 'varchar', 'text', 'enum')
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- ============================================================
-- PROBLEM 04-A: CATEGORY STANDARDIZATION
-- ============================================================
-- بعد فحص الأعمدة الـCategorical، بدأنا بتحليل
-- Stopped_Treatment في جدول raw_adherence.
--
-- الهدف هو اكتشاف القيم المختلفة التي تمثل نفس المعنى.


-- ============================================================
-- STEP 4: فحص قيم Stopped_Treatment
-- ============================================================
-- قمنا بتجميع القيم الموجودة في Stopped_Treatment
-- وحساب عدد الـRecords لكل قيمة.
--
-- اكتشفنا وجود:
--
-- False → 492,135
-- True  → 108,854
-- Yes   → 2,011
--
-- وجود Yes وTrue في نفس العمود يمثل مشكلة
-- في Category Standardization لأنهما يمثلان نفس المعنى:
-- العلاج تم إيقافه.

SELECT
    Stopped_Treatment,
    COUNT(*) AS total_count
FROM raw_adherence
GROUP BY Stopped_Treatment
ORDER BY total_count DESC;


-- ============================================================
-- STEP 5: فحص قيم Stop_Reason
-- ============================================================
-- قمنا بفحص Stop_Reason لمعرفة جميع الأسباب الموجودة
-- وعدد مرات ظهور كل سبب.
--
-- ظهر لدينا NULL بالإضافة إلى عدة أسباب معروفة.
--
-- في هذه المرحلة لم نقم بتعديل NULL لأننا نحتاج أولًا
-- إلى معرفة العلاقة بين Stop_Reason و Stopped_Treatment.

SELECT
    Stop_Reason,
    COUNT(*) AS total_count
FROM raw_adherence
GROUP BY Stop_Reason
ORDER BY total_count DESC;


-- ============================================================
-- STEP 6: تحليل العلاقة بين Stopped_Treatment و Stop_Reason
-- ============================================================
-- قمنا بربط العمودين معًا لمعرفة هل NULL في Stop_Reason
-- له علاقة بحالة إيقاف العلاج أم لا.
--
-- النتيجة أظهرت أن:
--
-- Stopped_Treatment = False
-- Stop_Reason = NULL
--
-- وهذا منطقي لأن العلاج لم يتم إيقافه، وبالتالي
-- لا يوجد سبب للإيقاف.
--
-- كما اكتشفنا حالات أخرى كان فيها العلاج متوقفًا
-- ولكن Stop_Reason كان NULL، وهذه أصبحت مشكلة منفصلة.

SELECT
    Stopped_Treatment,
    Stop_Reason,
    COUNT(*) AS total_count
FROM raw_adherence
GROUP BY Stopped_Treatment, Stop_Reason
ORDER BY Stopped_Treatment, total_count DESC;


-- ============================================================
-- STEP 7: التحقق من قيم Stopped_Treatment غير الـNULL
-- ============================================================
-- استخدمنا هذا الفحص للتأكد من القيم الفعلية الموجودة
-- في Stopped_Treatment بدون احتساب NULL.
--
-- الهدف هو تأكيد وجود True وFalse وYes قبل تنفيذ
-- عملية الـStandardization.

SELECT
    Stopped_Treatment,
    COUNT(*) AS total_count
FROM raw_adherence
WHERE Stopped_Treatment IS NOT NULL
GROUP BY Stopped_Treatment;


-- ============================================================
-- STEP 8: حل مشكلة Category Standardization
-- ============================================================
-- اكتشفنا أن:
--
-- Yes = True
--
-- والقيمتان تمثلان نفس المعنى المنطقي:
-- العلاج تم إيقافه.
--
-- لذلك قمنا بتوحيد الـCategory واستخدمنا True كقيمة
-- قياسية بدلًا من وجود Yes وTrue لنفس المعنى.
--
-- لم نستخدم NULL أو أي قيمة جديدة، لأن True موجودة
-- بالفعل كـStandard Category في العمود.

UPDATE raw_adherence
SET Stopped_Treatment = 'True'
WHERE Stopped_Treatment = 'Yes';


-- ============================================================
-- STEP 9: Validation بعد Category Standardization
-- ============================================================
-- بعد تنفيذ الـUPDATE قمنا بإعادة فحص القيم للتأكد
-- من اختفاء Yes وأن جميع الحالات أصبحت تستخدم
-- نفس الـStandardized Category.
--
-- النتيجة المتوقعة:
--
-- False → 492,135
-- True  → 110,865
--
-- ولا توجد Yes بعد الآن.

SELECT
    Stopped_Treatment,
    COUNT(*) AS total_count
FROM raw_adherence
GROUP BY Stopped_Treatment
ORDER BY total_count DESC;


-- ============================================================
-- PROBLEM 04-B: CONDITIONAL MISSING VALUES
-- ============================================================
-- أثناء تحليل Category Standardization اكتشفنا مشكلة أخرى.
--
-- بعض الـRecords لديها:
--
-- Stopped_Treatment = True
-- Stop_Reason = NULL
--
-- عندما يكون العلاج متوقفًا، فمن المنطقي أن يكون هناك
-- سبب للإيقاف.
--
-- لذلك اعتبرنا هذه الحالة Conditional Missing Value.
--
-- هذه مشكلة مختلفة عن Category Standardization.


-- ============================================================
-- STEP 10: حساب عدد الحالات التي أوقفت العلاج بدون سبب
-- ============================================================
-- نحسب عدد الـRecords التي يكون فيها العلاج متوقفًا
-- ولكن سبب التوقف مفقود.
--
-- النتيجة:
-- 1,645 Records.

SELECT
    COUNT(*) AS true_without_reason
FROM raw_adherence
WHERE Stopped_Treatment = 'True'
  AND Stop_Reason IS NULL;


-- ============================================================
-- STEP 11: حساب نسبة الحالات المتأثرة
-- ============================================================
-- قمنا بحساب نسبة الـRecords التي أوقفت العلاج
-- ولكن ليس لديها Stop_Reason.
--
-- النتيجة:
-- 1,645 Records
-- ≈ 1.48% من جميع حالات Stopped_Treatment = True
--
-- استخدمنا النسبة لمعرفة حجم المشكلة وليس فقط عددها.

SELECT
    COUNT(*) AS true_without_reason,
    (
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM raw_adherence
            WHERE Stopped_Treatment = 'True'
        )
    ) AS percentage
FROM raw_adherence
WHERE Stopped_Treatment = 'True'
  AND Stop_Reason IS NULL;


-- ============================================================
-- STEP 12: حل Conditional Missing Values
-- ============================================================
-- اكتشفنا أن الـStop_Reason مفقود في 1,645 حالة
-- رغم أن Stopped_Treatment = True.
--
-- لا نعرف السبب الحقيقي لإيقاف العلاج، لذلك لا يمكننا
-- تخمين السبب أو وضع قيمة غير مؤكدة.
--
-- لذلك استخدمنا:
--
-- Unknown
--
-- بدلًا من NULL.
--
-- اخترنا Unknown وليس Other لأن:
--
-- Other = السبب معروف لكنه لا ينتمي للفئات المحددة.
--
-- Unknown = السبب غير معروف أو غير مسجل.
--
-- وهذا الفرق مهم جدًا في Data Cleaning.

UPDATE raw_adherence
SET Stop_Reason = 'Unknown'
WHERE Stopped_Treatment = 'True'
  AND Stop_Reason IS NULL;


-- ============================================================
-- STEP 13: Final Validation
-- ============================================================
-- بعد تنفيذ الـUPDATE نقوم بالتأكد من عدم وجود أي
-- Stopped_Treatment = True بدون Stop_Reason.
--
-- النتيجة المتوقعة:
--
-- remaining_missing_reasons = 0
--
-- وهذا يؤكد أن الـConditional Missing Values تم التعامل معها.

SELECT
    COUNT(*) AS remaining_missing_reasons
FROM raw_adherence
WHERE Stopped_Treatment = 'True'
  AND Stop_Reason IS NULL;


-- ============================================================
-- FINAL RESULTS
-- ============================================================
--
-- Problem 1:
-- Category Standardization
--
-- Before:
-- Yes = 2,011
-- True = 108,854
-- False = 492,135
--
-- Cleaning:
-- Yes → True
--
-- After:
-- True = 110,865
-- False = 492,135
-- Yes = 0
--
--
-- Problem 2:
-- Conditional Missing Values
--
-- Detected:
-- Stopped_Treatment = True
-- Stop_Reason = NULL
--
-- Affected Records:
-- 1,645
--
-- Percentage:
-- Approximately 1.48%
--
-- Cleaning:
-- NULL → Unknown
--
-- Validation:
-- Remaining True + NULL Stop_Reason = 0
--
-- ============================================================
-- STATUS:
-- CATEGORY STANDARDIZATION        → RESOLVED
-- CONDITIONAL MISSING VALUES      → RESOLVED
-- ============================================================