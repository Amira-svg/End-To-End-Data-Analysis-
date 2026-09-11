USE outbreak_x_raw;


-- ============================================================
-- PROBLEM 05: INVALID FOREIGN KEYS / ORPHAN RECORDS
-- ============================================================
-- نتحقق من أن كل Location_ID موجود في raw_patient
-- له Location_ID مطابق في raw_location.
--
-- استخدمنا LEFT JOIN لأننا نريد الاحتفاظ بكل records
-- الموجودة في raw_patient.
--
-- إذا لم نجد قيمة مطابقة في raw_location،
-- فسيكون l.Location_ID = NULL.
--
-- هذه الحالة تسمى Orphan Record / Invalid Foreign Key.
--
-- مهم:
-- لا يوجد UPDATE أو DELETE في هذه المرحلة.
-- نحن فقط نكتشف المشكلة ونقيس حجمها.



SELECT
    p.Location_ID,
    COUNT(*) AS total_count
FROM raw_patient p
LEFT JOIN raw_location l
    ON p.Location_ID = l.Location_ID
WHERE l.Location_ID IS NULL
GROUP BY p.Location_ID
ORDER BY total_count DESC;



-- ============================================================
-- STEP 2: التأكد من وجود Location_ID = 999999 في جدول Locations
-- ============================================================
-- بنفحص الـParent Table مباشرة.
-- لو مفيش نتيجة، يبقى الـLocation_ID غير موجود فعلاً.

SELECT
    Location_ID
FROM raw_location
WHERE Location_ID = 999999;


-- ============================================================
-- STEP 3: معرفة تفاصيل الـ300 Patient المتأثرين
-- ============================================================
-- بنعرض الـPatient_ID والـLocation_ID للسجلات التي تشير
-- إلى Location غير موجودة في جدول raw_location.
--
-- الهدف هو فهم السجلات قبل اتخاذ قرار التنظيف.

SELECT
    p.Patient_ID,
    p.Location_ID
FROM raw_patient p
LEFT JOIN raw_location l
    ON p.Location_ID = l.Location_ID
WHERE l.Location_ID IS NULL
  AND p.Location_ID = 999999
LIMIT 20;




-- ============================================================
-- STEP 4: فحص استخدام 999999 في raw_patient
-- ============================================================
-- نعرف عدد مرات استخدام القيمة 999999 بالضبط
-- ونتأكد أن المشكلة محصورة في هذه القيمة.

SELECT
    Location_ID,
    COUNT(*) AS total_count
FROM raw_patient
WHERE Location_ID = 999999
GROUP BY Location_ID;



-- ============================================================
-- STEP 5: البحث عن Location تمثل Unknown / Missing
-- ============================================================
-- جدول raw_location لا يحتوي على Location_Name،
-- لذلك نفحص Governorate و City.
--
-- الهدف معرفة هل يوجد Location صحيحة يمكن ربط
-- الـ300 Patient بها بدل القيمة الوهمية 999999.

SELECT
    Location_ID,
    Governorate,
    City
FROM raw_location
WHERE LOWER(TRIM(Governorate)) LIKE '%unknown%'
   OR LOWER(TRIM(Governorate)) LIKE '%unspecified%'
   OR LOWER(TRIM(Governorate)) LIKE '%missing%'
   OR LOWER(TRIM(City)) LIKE '%unknown%'
   OR LOWER(TRIM(City)) LIKE '%unspecified%'
   OR LOWER(TRIM(City)) LIKE '%missing%';


-- ============================================================
-- STEP 6: معرفة أعمدة جدول raw_location
-- ============================================================

DESCRIBE raw_location;



-- ============================================================
-- STEP 6: التحقق هل Location_ID يسمح بـNULL
-- ============================================================
-- نحتاج معرفة هل نستطيع تحويل الـInvalid FK إلى NULL
-- بدل الاحتفاظ بالقيمة الوهمية 999999.

DESCRIBE raw_patient;



-- ============================================================
-- STEP 7: التحقق من طبيعة القيمة 999999
-- ============================================================
-- نبحث عن القيم الخاصة بـLocation_ID في raw_patient
-- ونقارنها بالقيم الموجودة في raw_location.
--
-- الهدف التأكد هل 999999 هي قيمة Placeholder
-- أم أن هناك مشكلة أخرى في البيانات.

SELECT
    p.Location_ID,
    COUNT(*) AS total_count,
    CASE
        WHEN l.Location_ID IS NULL THEN 'Invalid / Orphan'
        ELSE 'Valid'
    END AS location_status
FROM raw_patient p
LEFT JOIN raw_location l
    ON TRIM(p.Location_ID) = TRIM(l.Location_ID)
WHERE p.Location_ID = '999999'
GROUP BY
    p.Location_ID,
    l.Location_ID;



-- ============================================================
-- STEP 8: التأكد من عدم وجود Location_ID = 999999
-- في جدول raw_location
-- ============================================================

SELECT
    Location_ID,
    Governorate,
    City
FROM raw_location
WHERE TRIM(Location_ID) = '999999';


-- ============================================================
-- STEP 9: توثيق عدد الـRecords التي سيتم تنظيفها
-- ============================================================
-- نتأكد مرة أخيرة أن عدد السجلات التي تحتوي على
-- القيمة الوهمية 999999 هو 300 Record.

SELECT
    COUNT(*) AS invalid_location_records
FROM raw_patient
WHERE Location_ID = '999999';



-- ============================================================
-- STEP 10: تنظيف Invalid Foreign Key
-- ============================================================
-- القيمة 999999 غير موجودة في جدول raw_location،
-- وبالتالي فهي Invalid Foreign Key / Placeholder.
--
-- بما أن Location_ID يسمح بـNULL، سنحول القيمة إلى NULL
-- بدل الاحتفاظ بقيمة غير صحيحة أو اختراع Location_ID جديد.
--
-- هذا يحافظ على سلامة العلاقة بين الجداول.

UPDATE raw_patient
SET Location_ID = NULL
WHERE Location_ID = '999999';



-- ============================================================
-- STEP 11: Validation بعد تنظيف الـForeign Key
-- ============================================================
-- نتأكد أن 999999 لم تعد موجودة في raw_patient.

SELECT
    COUNT(*) AS remaining_invalid_location_ids
FROM raw_patient
WHERE Location_ID = '999999';


-- ============================================================
-- STEP 12: Final Validation للـOrphan Records
-- ============================================================
-- نعيد فحص العلاقة بالكامل بعد التنظيف.
--
-- المفروض ألا نجد أي Patient يشير إلى Location
-- غير موجودة في raw_location.

SELECT
    p.Location_ID,
    COUNT(*) AS total_count
FROM raw_patient p
LEFT JOIN raw_location l
    ON TRIM(p.Location_ID) = TRIM(l.Location_ID)
WHERE p.Location_ID IS NOT NULL
  AND l.Location_ID IS NULL
GROUP BY p.Location_ID
ORDER BY total_count DESC;
