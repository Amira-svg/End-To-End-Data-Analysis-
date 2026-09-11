-- ============================================================
-- TEXT STANDARDIZATION / CATEGORY PROFILING
-- ============================================================

USE outbreak_x_raw;


-- ============================================================
-- STEP 1: فحص Fname بحثًا عن Leading / Trailing Spaces
-- ============================================================
-- بنقارن القيمة الأصلية في Fname مع القيمة بعد استخدام TRIM().
-- لو القيمتان مختلفتان، فهذا يعني وجود مسافات زائدة في بداية
-- أو نهاية الاسم.
--
-- الهدف:
-- اكتشاف أي أسماء تحتوي على Extra Spaces قبل إجراء أي تعديل.

SELECT
    Patient_ID,
    Fname
FROM raw_patient
WHERE Fname <> TRIM(Fname);


-- ============================================================
-- STEP 2: فحص Lname بحثًا عن Leading / Trailing Spaces
-- ============================================================
-- نفس الفكرة السابقة ولكن على Last Name.
-- لو القيمة الأصلية مختلفة عن القيمة بعد TRIM()
-- فهذا يدل على وجود مسافات زائدة في بداية أو نهاية الاسم.

SELECT
    Patient_ID,
    Lname
FROM raw_patient
WHERE Lname <> TRIM(Lname);


-- ============================================================
-- STEP 3: حساب عدد Fname التي تحتوي على Extra Spaces
-- ============================================================
-- بدل عرض الـrecords، هنا نحسب العدد فقط.
--
-- استخدمنا IS NOT NULL حتى لا تدخل القيم المفقودة في المقارنة.
--
-- النتيجة كانت 0، وبالتالي لا توجد Extra Spaces في Fname.

SELECT
    COUNT(*) AS names_with_extra_spaces
FROM raw_patient
WHERE fname IS NOT NULL
  AND fname <> TRIM(fname);


-- ============================================================
-- STEP 4: حساب عدد Lname التي تحتوي على Extra Spaces
-- ============================================================
-- نفس الفكرة على Last Name.
--
-- النتيجة كانت 0، وبالتالي لا توجد Leading / Trailing
-- Spaces في Lname.

SELECT
    COUNT(*) AS names_with_extra_spaces
FROM raw_patient
WHERE lname IS NOT NULL
  AND lname <> TRIM(lname);


-- ============================================================
-- STEP 5: فحص أسماء Fname بعد توحيد الـCase
-- ============================================================
-- استخدمنا LOWER() لتحويل الأسماء إلى lowercase أثناء التحليل.
--
-- الهدف:
-- معرفة شكل الأسماء بعد توحيد الـcase وعدد مرات ظهور كل اسم.
--
-- هذه الخطوة استكشافية، ولا تقوم بتعديل البيانات.

SELECT
    LOWER(Fname) AS standardized_name,
    COUNT(*) AS total_count
FROM raw_patient
GROUP BY LOWER(Fname)
ORDER BY total_count DESC;


-- ============================================================
-- STEP 6: التأكد من وجود أكثر من Representation لنفس Fname
-- ============================================================
-- هنا نقارن عدد القيم الأصلية المختلفة لنفس الاسم بعد
-- توحيد الـcase باستخدام LOWER().
--
-- مثال:
-- Ahmed
-- ahmed
-- AHMED
--
-- كلهم سيظهرون تحت standardized_name = ahmed،
-- لكن COUNT(DISTINCT Fname) سيكون أكبر من 1.
--
-- HAVING > 1:
-- يعرض فقط الحالات التي يوجد فيها أكثر من كتابة أصلية
-- لنفس الاسم.
--
-- النتيجة كانت 0، لذلك لا توجد Case Inconsistency في Fname.

SELECT
    LOWER(Fname) AS standardized_name,
    COUNT(DISTINCT Fname) AS different_original_values
FROM raw_patient
WHERE Fname IS NOT NULL
GROUP BY LOWER(Fname)
HAVING COUNT(DISTINCT Fname) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 7: فحص Case Inconsistency في Lname
-- ============================================================
-- نفس فكرة Fname، ولكن على Last Name.
--
-- نبحث عن نفس الاسم مكتوب بأكثر من شكل من حيث Capitalization.
--
-- النتيجة كانت 0.

SELECT
    LOWER(Lname) AS standardized_name,
    COUNT(DISTINCT Lname) AS different_original_values
FROM raw_patient
WHERE Lname IS NOT NULL
GROUP BY LOWER(Lname)
HAVING COUNT(DISTINCT Lname) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 8: فحص Occupation بعد توحيد الـCase
-- ============================================================
-- نستخدم LOWER() أثناء التحليل حتى نكتشف إذا كانت نفس
-- الوظيفة مكتوبة بأشكال مختلفة من ناحية الـcase.

SELECT
    LOWER(Occupation) AS standardized_occupation,
    COUNT(*) AS total_count
FROM raw_patient
WHERE Occupation IS NOT NULL
GROUP BY LOWER(Occupation)
ORDER BY total_count DESC;


-- ============================================================
-- STEP 9: التأكد من اختلاف الـRepresentations في Occupation
-- ============================================================
-- نبحث عن نفس الـOccupation مكتوبة بأكثر من شكل أصلي.
--
-- مثال:
-- Office Worker
-- office worker
--
-- النتيجة كانت 0، لذلك لم نجد Case Inconsistency.

SELECT
    LOWER(Occupation) AS standardized_occupation,
    COUNT(DISTINCT Occupation) AS different_original_values
FROM raw_patient
WHERE Occupation IS NOT NULL
GROUP BY LOWER(Occupation)
HAVING COUNT(DISTINCT Occupation) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 10: البحث عن Multiple Consecutive Spaces في Occupation
-- ============================================================
-- LIKE '%  %' يبحث عن وجود مسافتين متتاليتين داخل النص.
--
-- الهدف:
-- اكتشاف مشاكل مثل:
-- Office  Worker
--
-- النتيجة كانت 0.

SELECT
    Occupation
FROM raw_patient
WHERE Occupation LIKE '%  %';


-- ============================================================
-- STEP 11: فحص Leading / Trailing Spaces في Stop_Reason
-- ============================================================
-- نستخدم TRIM() لمعرفة هل يوجد Spaces زائدة في بداية
-- أو نهاية Stop_Reason.
--
-- النتيجة كانت 0.

SELECT
    Stop_Reason
FROM raw_adherence
WHERE Stop_Reason IS NOT NULL
  AND Stop_Reason <> TRIM(Stop_Reason);


-- ============================================================
-- STEP 12: فحص Case Inconsistency في Stop_Reason
-- ============================================================
-- نحول القيم إلى lowercase ثم نبحث عن أكثر من
-- Representation أصلية لنفس القيمة.
--
-- النتيجة كانت 0.

SELECT
    LOWER(Stop_Reason) AS standardized_reason,
    COUNT(DISTINCT Stop_Reason) AS different_original_values
FROM raw_adherence
WHERE Stop_Reason IS NOT NULL
GROUP BY LOWER(Stop_Reason)
HAVING COUNT(DISTINCT Stop_Reason) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 13: فحص Multiple Spaces في Stop_Reason
-- ============================================================
-- نبحث عن وجود مسافتين متتاليتين داخل النص.
--
-- النتيجة كانت 0.

SELECT
    Stop_Reason
FROM raw_adherence
WHERE Stop_Reason IS NOT NULL
  AND Stop_Reason LIKE '%  %';


-- ============================================================
-- STEP 14: Profiling لقيم Severity
-- ============================================================
-- نعرض جميع قيم Severity وعدد مرات ظهور كل Category.
--
-- الهدف:
-- معرفة الـCategories الموجودة قبل عمل أي Standardization.

SELECT
    Severity,
    COUNT(*) AS total_count
FROM raw_case
GROUP BY Severity
ORDER BY total_count DESC;


-- ============================================================
-- STEP 15: فحص Case Inconsistency في Severity
-- ============================================================
-- نبحث عن أكثر من كتابة أصلية لنفس الـSeverity
-- بعد تحويلها إلى lowercase.
--
-- النتيجة كانت 0.

SELECT
    LOWER(Severity) AS standardized_severity,
    COUNT(DISTINCT Severity) AS different_original_values
FROM raw_case
WHERE Severity IS NOT NULL
GROUP BY LOWER(Severity)
HAVING COUNT(DISTINCT Severity) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 16: إعادة عرض Severity بشكل مرتب
-- ============================================================
-- استخدمنا هذه الـQuery لعرض القيم الفعلية الموجودة
-- وترتيبها أبجديًا بعد انتهاء التحليل.

SELECT
    Severity,
    COUNT(*) AS total_count
FROM raw_case
GROUP BY Severity
ORDER BY Severity;


-- ============================================================
-- STEP 17: فحص Leading / Trailing Spaces في Severity
-- ============================================================
-- نستخدم TRIM() للكشف عن المسافات الزائدة.
--
-- النتيجة كانت 0.

SELECT
    Severity
FROM raw_case
WHERE Severity IS NOT NULL
  AND Severity <> TRIM(Severity);


-- ============================================================
-- STEP 18: فحص Multiple Spaces في Severity
-- ============================================================
-- نبحث عن مسافتين متتاليتين داخل النص.
--
-- النتيجة كانت 0.

SELECT
    Severity
FROM raw_case
WHERE Severity IS NOT NULL
  AND Severity LIKE '%  %';


-- ============================================================
-- STEP 19: Profiling لقيم Symptom_Severity
-- ============================================================
-- نعرض جميع قيم Symptom_Severity وعدد مرات ظهورها.
--
-- اكتشفنا وجود:
-- Mild
-- Moderate
-- Severe
-- NULL
--
-- الـNULL هنا لا يعني تلقائيًا وجود خطأ في Standardization،
-- لذلك قمنا بتحليله بشكل منفصل.

SELECT
    Symptom_Severity,
    COUNT(*) AS total_count
FROM raw_case_symptom
GROUP BY Symptom_Severity
ORDER BY total_count DESC;


-- ============================================================
-- STEP 20: حساب عدد NULL في Symptom_Severity
-- ============================================================
-- نحسب عدد السجلات التي لا تحتوي على Symptom_Severity.
--
-- النتيجة كانت 12,059.
--
-- لم نقم بتحويلها إلى Unknown لأننا لا نعرف القيمة الحقيقية.

SELECT
    COUNT(*) AS null_symptom_severity
FROM raw_case_symptom
WHERE Symptom_Severity IS NULL;


-- ============================================================
-- STEP 21: فحص عينة من سجلات Symptom_Severity المفقودة
-- ============================================================
-- نعرض أول 20 Record تحتوي على NULL لمعرفة طبيعة
-- السجلات المتأثرة والتأكد من عدم وجود Pattern واضح
-- يسمح باستنتاج الـSeverity.
--
-- بعد الفحص لم نجد أساسًا موثوقًا لتعويض القيمة.

SELECT
    Case_ID,
    Symptom_ID,
    Symptom_Severity
FROM raw_case_symptom
WHERE Symptom_Severity IS NULL
LIMIT 20;


-- ============================================================
-- STEP 22: Profiling لقيم Treatment_Status
-- ============================================================
-- نعرض Categories الموجودة في Treatment_Status
-- وعدد كل Category.
--
-- القيم كانت:
-- Completed
-- Stopped
-- Changed
-- Ongoing

SELECT
    Treatment_Status,
    COUNT(*) AS total_count
FROM raw_patient_treatment
GROUP BY Treatment_Status
ORDER BY total_count DESC;


-- ============================================================
-- STEP 23: فحص Case Inconsistency في Treatment_Status
-- ============================================================
-- نبحث عن نفس Category مكتوبة بأكثر من Case.
--
-- النتيجة كانت 0.

SELECT
    LOWER(Treatment_Status) AS standardized_status,
    COUNT(DISTINCT Treatment_Status) AS different_original_values
FROM raw_patient_treatment
WHERE Treatment_Status IS NOT NULL
GROUP BY LOWER(Treatment_Status)
HAVING COUNT(DISTINCT Treatment_Status) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 24: فحص Leading / Trailing Spaces في Treatment_Status
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Treatment_Status
FROM raw_patient_treatment
WHERE Treatment_Status IS NOT NULL
  AND Treatment_Status <> TRIM(Treatment_Status);


-- ============================================================
-- STEP 25: فحص Multiple Spaces في Treatment_Status
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Treatment_Status
FROM raw_patient_treatment
WHERE Treatment_Status IS NOT NULL
  AND Treatment_Status LIKE '%  %';


-- ============================================================
-- STEP 26: Profiling لقيم Dosage_Group
-- ============================================================
-- نعرض جميع Categories الموجودة في Dosage_Group.
--
-- أثناء الفحص اكتشفنا:
-- High
-- High
--
-- والقيمة الثانية كانت تحتوي على Trailing Space.

SELECT
    Dosage_Group,
    COUNT(*) AS total_count
FROM raw_patient_treatment
GROUP BY Dosage_Group
ORDER BY total_count DESC;


-- ============================================================
-- STEP 27: إثبات مشكلة الـTrailing Space في Dosage_Group
-- ============================================================
-- نقارن القيمة الأصلية مع القيمة بعد TRIM().
--
-- إذا كانتا مختلفتين فهذا يعني وجود Extra Spaces.
--
-- النتيجة:
-- High  → 2,009 Records
--
-- أي أن 2,009 Record كانت تحتوي على Trailing Space.

SELECT
    Dosage_Group,
    COUNT(*) AS total_count
FROM raw_patient_treatment
WHERE Dosage_Group <> TRIM(Dosage_Group)
GROUP BY Dosage_Group
ORDER BY total_count DESC;


-- ============================================================
-- STEP 28: تنظيف Dosage_Group
-- ============================================================
-- استخدمنا TRIM() لإزالة المسافات الزائدة من بداية
-- ونهاية Dosage_Group.
--
-- استخدمنا WHERE حتى يتم تعديل السجلات التي تحتاج
-- إلى تنظيف فقط، وليس كل السجلات.

UPDATE raw_patient_treatment
SET Dosage_Group = TRIM(Dosage_Group)
WHERE Dosage_Group <> TRIM(Dosage_Group);


-- ============================================================
-- STEP 29: Validation بعد تنظيف Dosage_Group
-- ============================================================
-- نعيد عرض القيم وعدد كل Category للتأكد من دمج:
--
-- High
-- High
--
-- في Category واحدة:
-- High

SELECT
    Dosage_Group,
    COUNT(*) AS total_count
FROM raw_patient_treatment
GROUP BY Dosage_Group
ORDER BY total_count DESC;


-- ============================================================
-- STEP 30: Final Validation لعدم وجود Extra Spaces
-- ============================================================
-- نتأكد أن عدد السجلات التي ما زالت تحتوي على
-- Extra Spaces أصبح صفر.

SELECT COUNT(*) AS remaining_extra_spaces
FROM raw_patient_treatment
WHERE Dosage_Group <> TRIM(Dosage_Group);


-- ============================================================
-- STEP 31: Profiling لقيم Medication_Type
-- ============================================================
-- نعرض Categories الموجودة في Medication_Type.
--
-- القيم:
-- Antiviral
-- Supportive
-- Adjunct
--
-- لم نجد مشكلة Standardization.

SELECT
    Medication_Type,
    COUNT(*) AS total_count
FROM raw_medication
GROUP BY Medication_Type
ORDER BY total_count DESC;


-- ============================================================
-- STEP 32: فحص Case Inconsistency في Medication_Type
-- ============================================================
-- النتيجة كانت 0.

SELECT
    LOWER(Medication_Type) AS standardized_type,
    COUNT(DISTINCT Medication_Type) AS different_original_values
FROM raw_medication
WHERE Medication_Type IS NOT NULL
GROUP BY LOWER(Medication_Type)
HAVING COUNT(DISTINCT Medication_Type) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 33: فحص Leading / Trailing Spaces في Medication_Type
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Medication_Type
FROM raw_medication
WHERE Medication_Type IS NOT NULL
  AND Medication_Type <> TRIM(Medication_Type);


-- ============================================================
-- STEP 34: فحص Multiple Spaces في Medication_Type
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Medication_Type
FROM raw_medication
WHERE Medication_Type IS NOT NULL
  AND Medication_Type LIKE '%  %';


-- ============================================================
-- STEP 35: Profiling لقيم Protocol_Type
-- ============================================================
-- نعرض Categories الموجودة في Protocol_Type.
--
-- لم نجد مشكلة في القيم.

SELECT
    Protocol_Type,
    COUNT(*) AS total_count
FROM raw_treatment
GROUP BY Protocol_Type
ORDER BY total_count DESC;


-- ============================================================
-- STEP 36: فحص Case Inconsistency في Protocol_Type
-- ============================================================
-- النتيجة كانت 0.

SELECT
    LOWER(Protocol_Type) AS standardized_type,
    COUNT(DISTINCT Protocol_Type) AS different_original_values
FROM raw_treatment
WHERE Protocol_Type IS NOT NULL
GROUP BY LOWER(Protocol_Type)
HAVING COUNT(DISTINCT Protocol_Type) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 37: فحص Leading / Trailing Spaces في Protocol_Type
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Protocol_Type
FROM raw_treatment
WHERE Protocol_Type IS NOT NULL
  AND Protocol_Type <> TRIM(Protocol_Type);


-- ============================================================
-- STEP 38: فحص Multiple Spaces في Protocol_Type
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Protocol_Type
FROM raw_treatment
WHERE Protocol_Type IS NOT NULL
  AND Protocol_Type LIKE '%  %';


-- ============================================================
-- STEP 39: Profiling لقيم Outcome_Status
-- ============================================================
-- نعرض Categories الموجودة في Outcome_Status.
--
-- القيم ظهرت كالتالي:
-- Recovered
-- Hospitalized
-- ICU
-- unknown
--
-- لم نفترض أن unknown خطأ، لأن وجود lowercase وحده
-- لا يثبت أن القيمة غير صحيحة.

SELECT
    Outcome_Status,
    COUNT(*) AS total_count
FROM raw_outcome
GROUP BY Outcome_Status
ORDER BY total_count DESC;


-- ============================================================
-- STEP 40: فحص Case Inconsistency في Outcome_Status
-- ============================================================
-- نبحث عن أكثر من Representation لنفس Category.
--
-- النتيجة كانت 0.

SELECT
    LOWER(Outcome_Status) AS standardized_status,
    COUNT(DISTINCT Outcome_Status) AS different_original_values
FROM raw_outcome
WHERE Outcome_Status IS NOT NULL
GROUP BY LOWER(Outcome_Status)
HAVING COUNT(DISTINCT Outcome_Status) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 41: فحص Leading / Trailing Spaces في Outcome_Status
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Outcome_Status
FROM raw_outcome
WHERE Outcome_Status IS NOT NULL
  AND Outcome_Status <> TRIM(Outcome_Status);


-- ============================================================
-- STEP 42: فحص Multiple Spaces في Outcome_Status
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Outcome_Status
FROM raw_outcome
WHERE Outcome_Status IS NOT NULL
  AND Outcome_Status LIKE '%  %';


-- ============================================================
-- STEP 43: Profiling لقيم Side_Effects
-- ============================================================
-- نعرض جميع القيم الموجودة وعدد مرات ظهورها.
--
-- اكتشفنا عددًا كبيرًا من NULL.
-- لم نقم بتغيير NULL لأننا لا نملك دليلًا يحدد
-- هل تعني "No Side Effects" أم "Unknown".

SELECT
    Side_Effects,
    COUNT(*) AS total_count
FROM raw_outcome
GROUP BY Side_Effects
ORDER BY total_count DESC;


-- ============================================================
-- STEP 44: تحليل Side_Effects في سياق Hospitalized و ICU
-- ============================================================
-- الهدف من هذه الخطوة هو فهم معنى NULL في Side_Effects
-- بدلًا من افتراض أنه Missing Value دائمًا.
--
-- قمنا بتحليل Side_Effects مع Hospitalized و ICU_Admission
-- لاكتشاف أي Pattern منطقي.
--
-- بعد التحليل، وجدنا أن NULL يظهر مع حالات مختلفة،
-- لذلك لا يمكننا استنتاج قيمة صحيحة له بأمان.

SELECT
    Side_Effects,
    Hospitalized,
    ICU_Admission,
    COUNT(*) AS total_count
FROM raw_outcome
GROUP BY Side_Effects, Hospitalized, ICU_Admission
ORDER BY total_count DESC;


-- ============================================================
-- STEP 45: Profiling لقيم Hospitalized
-- ============================================================
-- اكتشفنا أن Hospitalized يحتوي على:
--
-- False
-- True
-- Yes
--
-- وجود Yes وTrue يمثل Category Standardization issue.

SELECT
    Hospitalized,
    COUNT(*) AS total_count
FROM raw_outcome
GROUP BY Hospitalized
ORDER BY total_count DESC;


-- ============================================================
-- STEP 46: فحص Case Inconsistency في Hospitalized
-- ============================================================
-- الهدف هو التأكد هل المشكلة بسبب اختلاف الـCase
-- مثل true / True أو بسبب وجود Category مختلفة مثل Yes.
--
-- النتيجة:
-- لا توجد Case inconsistency،
-- لكن يوجد Yes كتمثيل مختلف لنفس المعنى.

SELECT
    LOWER(Hospitalized) AS standardized_value,
    COUNT(DISTINCT Hospitalized) AS different_original_values
FROM raw_outcome
WHERE Hospitalized IS NOT NULL
GROUP BY LOWER(Hospitalized)
HAVING COUNT(DISTINCT Hospitalized) > 1;


-- ============================================================
-- STEP 47: حساب عدد Yes في Hospitalized
-- ============================================================
-- قبل الـUPDATE نتأكد من عدد السجلات التي سيتم تعديلها.
--
-- النتيجة:
-- 2,510 Records.

SELECT COUNT(*) AS yes_records
FROM raw_outcome
WHERE Hospitalized = 'Yes';


-- ============================================================
-- STEP 48: توحيد Hospitalized
-- ============================================================
-- Yes وTrue يمثلان نفس الحالة:
-- المريض تم إدخاله/تصنيفه على أنه Hospitalized.
--
-- لذلك قمنا بتوحيد Yes إلى True.
--
-- نستخدم WHERE حتى يتم تعديل Yes فقط.

UPDATE raw_outcome
SET Hospitalized = 'True'
WHERE Hospitalized = 'Yes';


-- ============================================================
-- STEP 49: Validation بعد توحيد Hospitalized
-- ============================================================
-- نعيد توزيع القيم للتأكد من أن Yes تم دمجها داخل True.
--
-- المتوقع:
-- False = 479,942
-- True = 123,058

SELECT
    Hospitalized,
    COUNT(*) AS total_count
FROM raw_outcome
GROUP BY Hospitalized
ORDER BY total_count DESC;


-- ============================================================
-- STEP 50: Final Validation لعدم وجود Yes
-- ============================================================
-- نتأكد بشكل مباشر أن Category Yes لم تعد موجودة.

SELECT COUNT(*) AS remaining_yes
FROM raw_outcome
WHERE Hospitalized = 'Yes';


-- ============================================================
-- STEP 51: Profiling لقيم ICU_Admission
-- ============================================================
-- نعرض القيم الموجودة في ICU_Admission.
--
-- وجدنا:
-- False
-- True
-- NULL
--
-- لا توجد Category Standardization problem،
-- ولكن يوجد Missing Value يجب تحليله منفصلًا.

SELECT
    ICU_Admission,
    COUNT(*) AS total_count
FROM raw_outcome
GROUP BY ICU_Admission
ORDER BY total_count DESC;


-- ============================================================
-- STEP 52: تحليل NULL في ICU_Admission مع Hospitalized
-- ============================================================
-- نريد معرفة هل يمكن استنتاج قيمة ICU_Admission
-- من Hospitalized.
--
-- وجدنا أن NULL موجود مع:
-- Hospitalized = False
-- Hospitalized = True
--
-- لذلك لا يمكن استخدام Hospitalized لاستنتاج القيمة الصحيحة.
--
-- لم يتم إجراء UPDATE.

SELECT
    ICU_Admission,
    Hospitalized,
    COUNT(*) AS total_count
FROM raw_outcome
GROUP BY ICU_Admission, Hospitalized
ORDER BY total_count DESC;


-- ============================================================
-- STEP 53: Profiling لقيم Chronic_Disease
-- ============================================================
-- نعرض Categories الموجودة في Chronic_Disease.
--
-- وجدنا أربع Categories بالإضافة إلى NULL.
--
-- لم نفترض أن NULL يمكن تعويضه بدون معرفة المرض الحقيقي.

SELECT
    Chronic_Disease,
    COUNT(*) AS total_count
FROM raw_medical_history
GROUP BY Chronic_Disease
ORDER BY total_count DESC;


-- ============================================================
-- STEP 54: فحص Case Inconsistency في Chronic_Disease
-- ============================================================
-- النتيجة كانت 0.

SELECT
    LOWER(Chronic_Disease) AS standardized_disease,
    COUNT(DISTINCT Chronic_Disease) AS different_original_values
FROM raw_medical_history
WHERE Chronic_Disease IS NOT NULL
GROUP BY LOWER(Chronic_Disease)
HAVING COUNT(DISTINCT Chronic_Disease) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 55: فحص Leading / Trailing Spaces في Chronic_Disease
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Chronic_Disease
FROM raw_medical_history
WHERE Chronic_Disease IS NOT NULL
  AND Chronic_Disease <> TRIM(Chronic_Disease);


-- ============================================================
-- STEP 56: فحص Multiple Spaces في Chronic_Disease
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Chronic_Disease
FROM raw_medical_history
WHERE Chronic_Disease IS NOT NULL
  AND Chronic_Disease LIKE '%  %';


-- ============================================================
-- STEP 57: Profiling لقيم Disease_Severity
-- ============================================================
-- نعرض Categories الموجودة في Disease_Severity.
--
-- القيم:
-- Mild
-- Moderate
-- Severe
--
-- لا توجد NULL values.

SELECT
    Disease_Severity,
    COUNT(*) AS total_count
FROM raw_medical_history
GROUP BY Disease_Severity
ORDER BY total_count DESC;


-- ============================================================
-- STEP 58: فحص Case Inconsistency في Disease_Severity
-- ============================================================
-- النتيجة كانت 0.

SELECT
    LOWER(Disease_Severity) AS standardized_severity,
    COUNT(DISTINCT Disease_Severity) AS different_original_values
FROM raw_medical_history
WHERE Disease_Severity IS NOT NULL
GROUP BY LOWER(Disease_Severity)
HAVING COUNT(DISTINCT Disease_Severity) > 1;


-- ============================================================
-- STEP 59: فحص Leading / Trailing Spaces في Disease_Severity
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Disease_Severity
FROM raw_medical_history
WHERE Disease_Severity IS NOT NULL
  AND Disease_Severity <> TRIM(Disease_Severity);


-- ============================================================
-- STEP 60: فحص Multiple Spaces في Disease_Severity
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Disease_Severity
FROM raw_medical_history
WHERE Disease_Severity IS NOT NULL
  AND Disease_Severity LIKE '%  %';


-- ============================================================
-- STEP 61: Profiling لقيم Previous_Conditions
-- ============================================================
-- نعرض Categories الموجودة في Previous_Conditions.
--
-- لا توجد NULL values أو Categories واضحة غير قياسية.

SELECT
    Previous_Conditions,
    COUNT(*) AS total_count
FROM raw_medical_history
GROUP BY Previous_Conditions
ORDER BY total_count DESC;


-- ============================================================
-- STEP 62: فحص Case Inconsistency في Previous_Conditions
-- ============================================================
-- النتيجة كانت 0.

SELECT
    LOWER(Previous_Conditions) AS standardized_condition,
    COUNT(DISTINCT Previous_Conditions) AS different_original_values
FROM raw_medical_history
WHERE Previous_Conditions IS NOT NULL
GROUP BY LOWER(Previous_Conditions)
HAVING COUNT(DISTINCT Previous_Conditions) > 1;


-- ============================================================
-- STEP 63: فحص Leading / Trailing Spaces في Previous_Conditions
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Previous_Conditions
FROM raw_medical_history
WHERE Previous_Conditions IS NOT NULL
  AND Previous_Conditions <> TRIM(Previous_Conditions);


-- ============================================================
-- STEP 64: فحص Multiple Spaces في Previous_Conditions
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Previous_Conditions
FROM raw_medical_history
WHERE Previous_Conditions IS NOT NULL
  AND Previous_Conditions LIKE '%  %';


-- ============================================================
-- STEP 65: Profiling لقيم Medication_Name
-- ============================================================
-- نعرض أسماء الأدوية الموجودة.
--
-- كل قيمة ظهرت مرة واحدة، ولم تظهر Duplicated Representations.

SELECT
    Medication_Name,
    COUNT(*) AS total_count
FROM raw_medication
GROUP BY Medication_Name
ORDER BY total_count DESC;


-- ============================================================
-- STEP 66: فحص Case Inconsistency في Medication_Name
-- ============================================================
-- النتيجة كانت 0.

SELECT
    LOWER(Medication_Name) AS standardized_name,
    COUNT(DISTINCT Medication_Name) AS different_original_values
FROM raw_medication
WHERE Medication_Name IS NOT NULL
GROUP BY LOWER(Medication_Name)
HAVING COUNT(DISTINCT Medication_Name) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 67: فحص Leading / Trailing Spaces في Medication_Name
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Medication_Name
FROM raw_medication
WHERE Medication_Name IS NOT NULL
  AND Medication_Name <> TRIM(Medication_Name);


-- ============================================================
-- STEP 68: فحص Multiple Spaces في Medication_Name
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Medication_Name
FROM raw_medication
WHERE Medication_Name IS NOT NULL
  AND Medication_Name LIKE '%  %';


-- ============================================================
-- STEP 69: Profiling لقيم Symptom_Name
-- ============================================================
-- نعرض أسماء الأعراض الموجودة في الـMaster Table.
--
-- القيم كانت موحدة ولا توجد Duplicates ظاهرة.

SELECT
    Symptom_Name,
    COUNT(*) AS total_count
FROM raw_symptom
GROUP BY Symptom_Name
ORDER BY total_count DESC;


-- ============================================================
-- STEP 70: فحص Case Inconsistency في Symptom_Name
-- ============================================================
-- النتيجة كانت 0.

SELECT
    LOWER(Symptom_Name) AS standardized_name,
    COUNT(DISTINCT Symptom_Name) AS different_original_values
FROM raw_symptom
WHERE Symptom_Name IS NOT NULL
GROUP BY LOWER(Symptom_Name)
HAVING COUNT(DISTINCT Symptom_Name) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 71: فحص Leading / Trailing Spaces في Symptom_Name
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Symptom_Name
FROM raw_symptom
WHERE Symptom_Name IS NOT NULL
  AND Symptom_Name <> TRIM(Symptom_Name);


-- ============================================================
-- STEP 72: فحص Multiple Spaces في Symptom_Name
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Symptom_Name
FROM raw_symptom
WHERE Symptom_Name IS NOT NULL
  AND Symptom_Name LIKE '%  %';


-- ============================================================
-- STEP 73: Profiling لقيم Treatment_Name
-- ============================================================
-- نعرض أسماء الـTreatments الموجودة.
--
-- كل قيمة ظهرت مرة واحدة ولا يوجد Representation مكررة.

SELECT
    Treatment_Name,
    COUNT(*) AS total_count
FROM raw_treatment
GROUP BY Treatment_Name
ORDER BY total_count DESC;


-- ============================================================
-- STEP 74: فحص Case Inconsistency في Treatment_Name
-- ============================================================
-- نبحث عن أكثر من Representation أصلية لنفس الاسم
-- بعد توحيد الـcase.
--
-- النتيجة كانت 0.

SELECT
    LOWER(Treatment_Name) AS standardized_name,
    COUNT(DISTINCT Treatment_Name) AS different_original_values
FROM raw_treatment
WHERE Treatment_Name IS NOT NULL
GROUP BY LOWER(Treatment_Name)
HAVING COUNT(DISTINCT Treatment_Name) > 1
ORDER BY different_original_values DESC;


-- ============================================================
-- STEP 75: فحص Leading / Trailing Spaces في Treatment_Name
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Treatment_Name
FROM raw_treatment
WHERE Treatment_Name IS NOT NULL
  AND Treatment_Name <> TRIM(Treatment_Name);


-- ============================================================
-- STEP 76: فحص Multiple Spaces في Treatment_Name
-- ============================================================
-- النتيجة كانت 0.

SELECT
    Treatment_Name
FROM raw_treatment
WHERE Treatment_Name IS NOT NULL
  AND Treatment_Name LIKE '%  %';


-- ============================================================
-- FINAL SUMMARY
-- ============================================================
-- خلال مرحلة Text / Category Standardization:
--
-- 1. Dosage_Group:
--    تم اكتشاف 2,009 Records بقيمة "High " مع Trailing Space.
--    تم تنظيفها باستخدام TRIM().
--
-- 2. Hospitalized:
--    تم اكتشاف 2,510 Records بقيمة "Yes".
--    تم توحيدها إلى "True".
--
-- 3. Stopped_Treatment:
--    تم اكتشاف "Yes" كـRepresentation مختلفة عن "True"
--    وتم توحيدها إلى "True".
--
-- 4. Stop_Reason:
--    تم اكتشاف حالات Stopped_Treatment = True
--    بدون Stop_Reason، وتم التعامل معها في مشكلة
--    Conditional Missing Values باستخدام Unknown.
--
-- باقي الأعمدة التي تم فحصها لم تظهر فيها
-- Case/Space Standardization issues تحتاج إلى تعديل.
-- ============================================================