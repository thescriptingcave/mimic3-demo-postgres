-- ============================================================================
-- 01-beginner.sql
-- MIMIC-III Demo in PostgreSQL -- Beginner examples
--
-- Run with:
--   psql -h localhost -p 5432 -U mimic -d mimic -f sql/examples/01-beginner.sql
--   (or: docker exec -i mimic3-postgres psql -U mimic -d mimic < sql/examples/01-beginner.sql)
-- ============================================================================

SET search_path TO mimiciii;

-- [B1] SELECT all columns
-- Use case: take a first look at a table.
-- SELECT * returns every column; LIMIT keeps the result small while exploring.
SELECT *
FROM patients
LIMIT 5;

-- [B2] SELECT specific columns
-- Use case: pull only the fields you need (abc analysis, lighter queries).
SELECT subject_id, gender, dob
FROM patients
ORDER BY subject_id
LIMIT 10;

-- [B3] WHERE + equality
-- Use case: find ICU stays that started in the CCU (Coronary Care Unit).
SELECT subject_id, hadm_id, icustay_id, intime, los
FROM icustays
WHERE first_careunit = 'CCU'
ORDER BY intime
LIMIT 10;

-- [B4] WHERE + comparison operators
-- Use case: admissions from the year 2150 onwards.
SELECT subject_id, hadm_id, admittime, admission_type
FROM admissions
WHERE admittime >= '2150-01-01'
ORDER BY admittime
LIMIT 10;

-- [B5] WHERE + BETWEEN (inclusive range)
-- Use case: lab (potassium, itemid 50971) results collected in August 2102.
-- BETWEEN is shorthand for >= AND <=.
SELECT subject_id, hadm_id, charttime, value, valuenum
FROM labevents
WHERE itemid = 50971
  AND charttime BETWEEN '2102-08-01' AND '2102-08-31'
ORDER BY charttime
LIMIT 10;

-- [B6] WHERE + IN (list of values)
-- Use case: only non-emergency admissions.
SELECT subject_id, hadm_id, admittime, admission_type
FROM admissions
WHERE admission_type IN ('ELECTIVE', 'URGENT')
ORDER BY admittime;

-- [B7] WHERE + LIKE (pattern match, '%' = any chars)
-- Use case: find admissions for patients whose recorded ethnicity mentions ASIAN.
-- ILIKE ignores case; LIKE does not.
SELECT subject_id, hadm_id, ethnicity
FROM admissions
WHERE ethnicity LIKE '%ASIAN%'
ORDER BY subject_id;

-- [B8] WHERE + IS NULL
-- Use case: admissions with no emergency-department registration time
-- recorded (edregtime is a nullable column).
SELECT subject_id, hadm_id, admittime, edregtime
FROM admissions
WHERE edregtime IS NULL
ORDER BY subject_id
LIMIT 10;

-- [B9] DISTINCT -- list unique values
-- Use case: what admission types exist in the demo?
SELECT DISTINCT admission_type
FROM admissions;

-- [B10] ORDER BY multiple columns + LIMIT
-- Use case: the 10 longest ICU stays. NULLS LAST keeps unknown lengths at the end.
SELECT subject_id, icustay_id, first_careunit, los
FROM icustays
ORDER BY los DESC NULLS LAST, icustay_id
LIMIT 10;

-- [B11] COUNT and COUNT(DISTINCT)
-- Use case: how many admissions and how many distinct patients are there?
-- COUNT(*) counts rows; COUNT(DISTINCT x) counts unique values of x.
SELECT
    count(*)          AS total_admissions,
    count(DISTINCT subject_id) AS distinct_patients
FROM admissions;

-- [B12] Aggregate functions: SUM / AVG / MIN / MAX
-- Use case: summary statistics of ICU length of stay (days).
SELECT
    count(*)                 AS icu_stays,
    round(avg(los), 2)       AS avg_los_days,
    min(los)                 AS min_los_days,
    max(los)                 AS max_los_days
FROM icustays;

-- [B13] GROUP BY + aggregate: one row per group
-- Use case: how many patients died per gender (expire_flag 1 = deceased)?
SELECT gender, count(*) AS patients, sum(expire_flag) AS deceased
FROM patients
GROUP BY gender
ORDER BY patients DESC;

-- [B14] HAVING: filter GROUPS (after aggregation), WHERE filters rows
-- Use case: care units whose average ICU stay is longer than 4 days.
SELECT first_careunit, count(*) AS stays, round(avg(los), 2) AS avg_los_days
FROM icustays
GROUP BY first_careunit
HAVING avg(los) > 4
ORDER BY avg_los_days DESC;

-- [B15] Arithmetic in SELECT
-- Use case: express ICU length of stay in hours instead of days.
SELECT subject_id, icustay_id, los, round(los * 24, 1) AS los_hours
FROM icustays
ORDER BY los DESC NULLS LAST
LIMIT 10;

-- [B16] EXTRACT(): pull a part of a timestamp
-- Use case: how many admissions happened each year? (demo spans 2102-2202)
SELECT EXTRACT(YEAR FROM admittime)::int AS admission_year, count(*)
FROM admissions
GROUP BY admission_year
ORDER BY admission_year;