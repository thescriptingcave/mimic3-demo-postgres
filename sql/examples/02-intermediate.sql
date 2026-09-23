-- ============================================================================
-- 02-intermediate.sql
-- MIMIC-III Demo in PostgreSQL -- Intermediate examples
--
-- Topics: JOINs (INNER / LEFT / self / multi-table), subqueries, CASE,
--         COALESCE, string functions, date arithmetic, HAVING on joins.
-- ============================================================================

SET search_path TO mimiciii;

-- [I1] INNER JOIN -- combine two tables on a common column
-- Use case: attach ICU stay details to each admission.
-- Only rows that match on both sides are returned.
SELECT a.subject_id, a.hadm_id, a.admittime, i.icustay_id, i.first_careunit
FROM admissions  a
JOIN icustays    i USING (subject_id, hadm_id)
WHERE a.admittime >= '2150-01-01'
ORDER BY a.admittime
LIMIT 10;

-- [I2] Multi-table INNER JOIN (3 tables)
-- Use case: patient demography + admission + ICU records in one row.
SELECT p.subject_id, p.gender, a.admission_type, i.intime, i.los
FROM patients   p
JOIN admissions a USING (subject_id)
JOIN icustays   i USING (subject_id, hadm_id)
ORDER BY i.intime
LIMIT 10;

-- [I3] LEFT JOIN -- keep every row of the left table
-- Use case: list all admissions, and the ICU stay if one exists.
-- Rows with no match get NULL on the right side.
SELECT a.subject_id, a.hadm_id, i.icustay_id, i.first_careunit
FROM admissions a
LEFT JOIN icustays i USING (subject_id, hadm_id)
ORDER BY a.hadm_id
LIMIT 10;

-- [I4] LEFT JOIN + WHERE ... IS NULL  (anti-join)
-- Use case: which admissions had NO ICU stay?
SELECT a.subject_id, a.hadm_id, a.admittime, a.dischtime
FROM admissions a
LEFT JOIN icustays i USING (subject_id, hadm_id)
WHERE i.icustay_id IS NULL
ORDER BY a.hadm_id;

-- [I5] Self join -- a table joined to itself
-- Use case: pairs of admissions for the same patient (readmissions).
-- Aliasing the same table twice lets us compare a patient with themselves.
SELECT a1.subject_id,
       a1.hadm_id  AS first_admission,
       a2.hadm_id  AS readmission,
       a1.admittime AS first_admittime,
       a2.admittime AS readmittime,
       round(EXTRACT(EPOCH FROM (a2.admittime - a1.admittime)) / 86400) AS days_between
FROM admissions a1
JOIN admissions a2 USING (subject_id)
WHERE a1.hadm_id < a2.hadm_id
ORDER BY a1.subject_id, a1.hadm_id;

-- [I6] Subquery in WHERE (scalar subquery)
-- Use case: ICU stays longer than the average. The inner query returns ONE value.
SELECT subject_id, icustay_id, first_careunit, los
FROM icustays
WHERE los > (SELECT avg(los) FROM icustays)
ORDER BY los DESC;

-- [I7] Subquery in FROM (derived table)
-- Use case: summarize diagnoses per patient, then filter on the summary.
-- Queries in FROM must have an alias (here: d).
SELECT subject_id, n_diagnoses
FROM (
    SELECT subject_id, count(*) AS n_diagnoses
    FROM diagnoses_icd
    GROUP BY subject_id
) AS d
WHERE n_diagnoses > 10
ORDER BY n_diagnoses DESC;

-- [I8] EXISTS -- "there exists at least one matching row"
-- Use case: which patients with an ICU stay also have any microbiology culture?
-- EXISTS stops at the first match, so it is often faster than count(*) > 0.
SELECT DISTINCT p.subject_id, p.gender
FROM patients p
WHERE EXISTS (
    SELECT 1
    FROM microbiologyevents m
    WHERE m.subject_id = p.subject_id
)
ORDER BY p.subject_id;

-- [I9] CASE -- conditional value in SELECT
-- Use case: bucket ICU stays into short / normal / long categories.
SELECT subject_id, icustay_id, los,
       CASE
           WHEN los <  2        THEN 'short'
           WHEN los BETWEEN 2 AND 7 THEN 'normal'
           ELSE                      'long'
       END AS los_category
FROM icustays
ORDER BY los DESC NULLS LAST
LIMIT 15;

-- [I10] COALESCE -- first non-NULL value
-- Use case: for deceased patients show the first known death date.
SELECT subject_id, expire_flag, dod_hosp, dod_ssn,
       COALESCE(dod_hosp, dod_ssn) AS first_known_death
FROM patients
WHERE expire_flag = 1
ORDER BY subject_id
LIMIT 10;

-- [I11] String functions
-- Use case: normalize the ethnicity field for grouping.
-- UPPER(), LOWER(), REPLACE(), and LENGTH() are common text helpers.
SELECT UPPER(ethnicity) AS ethnicity_upper, count(*)
FROM admissions
GROUP BY ethnicity_upper
ORDER BY count(*) DESC
LIMIT 8;

-- [I12] Date arithmetic + EXTRACT
-- Use case: patient age (years) at ICU admission, from date of birth.
SELECT p.subject_id, i.hadm_id, i.intime,
       EXTRACT(YEAR FROM AGE(i.intime, p.dob))::int AS age_at_icu
FROM patients p
JOIN icustays i USING (subject_id)
ORDER BY i.intime
LIMIT 10;

-- [I13] JOIN + GROUP BY + HAVING
-- Use case: count potassium (itemid 50971) labs per patient, keep the top 5.
SELECT l.subject_id, dl.label, count(*) AS n_results
FROM labevents l
JOIN d_labitems dl USING (itemid)
WHERE l.itemid = 50971
GROUP BY l.subject_id, dl.label
HAVING count(*) >= 3
ORDER BY n_results DESC
LIMIT 5;

-- [I14] JOIN + WHERE on joined values (range filter)
-- Use case: abnormal high potassium (> 5.2 mmol/L) events.
SELECT l.subject_id, l.hadm_id, l.charttime, dl.label, l.valuenum, l.valueuom
FROM labevents l
JOIN d_labitems dl USING (itemid)
WHERE dl.label = 'Potassium'
  AND l.valuenum > 5.2
ORDER BY l.charttime
LIMIT 10;