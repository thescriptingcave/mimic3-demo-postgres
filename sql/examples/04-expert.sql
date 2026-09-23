-- ============================================================================
-- 04-expert.sql
-- MIMIC-III Demo in PostgreSQL -- Expert examples
--
-- Topics: recursive CTEs, ROLLUP / GROUPING SETS / CUBE, conditional
--         aggregation (FILTER), percentile + mode, correlated subqueries,
--         UNNEST / generate_series, EXPLAIN.
-- ============================================================================

SET search_path TO mimiciii;

-- [X1] Recursive CTE -- build a series and JOIN against it
-- Use case: complete monthly calendar of admissions, INCLUDING months with zero.
-- Fuel: date series generated row-by-row (month + 1) until the last admission.
-- LEFT JOIN keeps zero-count months visible.
WITH RECURSIVE months AS (
    SELECT date_trunc('month', min(admittime))::date AS month_start
    FROM admissions
    UNION ALL
    SELECT (month_start + INTERVAL '1 month')::date
    FROM months
    WHERE month_start < (SELECT date_trunc('month', max(admittime))::date FROM admissions)
)
SELECT m.month_start, count(a.hadm_id) AS admissions
FROM months m
LEFT JOIN admissions a
       ON date_trunc('month', a.admittime)::date = m.month_start
GROUP BY m.month_start
ORDER BY m.month_start
LIMIT 15;

-- [X2] ROLLUP -- subtotals and a grand total in one query
-- Use case: admissions per insurance and admission_type, plus subtotals.
-- The NULL rows are the subtotals ROLLUP inserts automatically.
SELECT insurance, admission_type, count(*) AS n
FROM admissions
GROUP BY ROLLUP (insurance, admission_type)
ORDER BY insurance NULLS LAST, admission_type NULLS LAST;

-- [X3] GROUPING SETS -- only the subtotal combinations you ask for
-- Use case: admissions grouped by insurance, by admission_type, and a total,
-- but NOT the insurance x admission_type cross.
SELECT insurance, admission_type, count(*) AS n,
       GROUPING(insurance) AS is_insurance_rollup
FROM admissions
GROUP BY GROUPING SETS ((insurance), (admission_type), ())
ORDER BY is_insurance_rollup, insurance NULLS LAST, admission_type NULLS LAST;

-- [X4] Conditional aggregation with FILTER (a.k.a. PIVOT)
-- Use case: side-by-side (pivoted) counts of admission types per year.
SELECT EXTRACT(YEAR FROM admittime)::int AS yr,
       count(*) FILTER (WHERE admission_type = 'EMERGENCY') AS emergency,
       count(*) FILTER (WHERE admission_type = 'ELECTIVE')  AS elective,
       count(*) FILTER (WHERE admission_type = 'URGENT')    AS urgent
FROM admissions
GROUP BY yr
ORDER BY yr;

-- [X5] Percentiles -- median and spread of ICU length of stay
-- Use case: unlike AVG, percentiles are robust to a few very long stays.
-- percentile_cont returns double precision here, so cast to numeric before round().
SELECT
    round(percentile_cont(0.50) WITHIN GROUP (ORDER BY los)::numeric, 2) AS median_los,
    round(percentile_cont(0.25) WITHIN GROUP (ORDER BY los)::numeric, 2) AS q1_los,
    round(percentile_cont(0.75) WITHIN GROUP (ORDER BY los)::numeric, 2) AS q3_los,
    round(percentile_cont(0.95) WITHIN GROUP (ORDER BY los)::numeric, 2) AS p95_los
FROM icustays
WHERE los IS NOT NULL;

-- [X6] mode() -- most frequent value in a set
-- Use case: most common admission_type in each 25-year window.
SELECT (EXTRACT(YEAR FROM admittime)::int / 25) * 25 AS year_window,
       mode() WITHIN GROUP (ORDER BY admission_type) AS most_common_type,
       count(*) AS n
FROM admissions
GROUP BY year_window
ORDER BY year_window;

-- [X7] generate_series -- build a table of values on the fly
-- Use case: hourly bins for one CCU ICU stay (demonstration of series JOIN).
WITH picks AS (
    SELECT icustay_id, intime, outtime
    FROM icustays
    WHERE first_careunit = 'CCU'
    ORDER BY los DESC
    LIMIT 1
)
SELECT p.icustay_id, h.hour_bucket
FROM picks p
JOIN LATERAL generate_series(
         date_trunc('hour', p.intime),
         date_trunc('hour', p.outtime),
         interval '1 hour'
     ) AS h(hour_bucket) ON true
ORDER BY h.hour_bucket;

-- [X8] Correlated subquery -- inner query re-evaluated per outer row
-- Use case: each patient's FIRST admission, written with a correlated subquery
-- (an alternative to DISTINCT ON in [A11]).
SELECT a.subject_id, a.hadm_id, a.admittime
FROM admissions a
WHERE a.admittime = (
    SELECT min(a2.admittime)
    FROM admissions a2
    WHERE a2.subject_id = a.subject_id
)
ORDER BY a.subject_id
LIMIT 10;

-- [X9] UNNEST + array agg -- explode grouped values into rows
-- Use case: flatten each patient's diagnosis ICD-9 codes into one list,
-- then show the first 5 codes as individual rows.
WITH per_patient AS (
    SELECT subject_id, array_agg(icd9_code ORDER BY seq_num) AS codes
    FROM diagnoses_icd
    GROUP BY subject_id
)
SELECT p.subject_id, u.ordinality AS position, u.code
FROM per_patient p
CROSS JOIN LATERAL UNNEST(p.codes) WITH ORDINALITY AS u(code, ordinality)
WHERE ordinality <= 5
ORDER BY p.subject_id, u.ordinality
LIMIT 15;

-- [X10] EXPLAIN ANALYZE -- inspect how PostgreSQL executes a query
-- Use case: verify an index is used / estimate cost before scaling up.
-- (Runs the query for real; keep it small during a demo!)
EXPLAIN ANALYZE
SELECT subject_id, count(*)
FROM labevents
WHERE itemid = 50971
GROUP BY subject_id;