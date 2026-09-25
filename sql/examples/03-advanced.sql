-- ============================================================================
-- 03-advanced.sql
-- MIMIC-III Demo in PostgreSQL -- Advanced examples
--
-- Topics: Common Table Expressions (CTEs), window functions
--         (ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG/LEAD, running totals,
--         moving averages, FIRST_VALUE), DISTINCT ON, LATERAL.
-- ============================================================================

SET search_path TO mimiciii;

-- [A1] CTE (WITH clause) -- name a query and reuse it
-- Use case: count admissions per year as a named step, then query it.
WITH yearly_admissions AS (
    SELECT EXTRACT(YEAR FROM admittime)::int AS admission_year, count(*) AS n
    FROM admissions
    GROUP BY admission_year
)
SELECT *
FROM yearly_admissions
ORDER BY admission_year;

-- [A2] Multiple CTEs (separated by commas) -- build steps on top of steps
-- Use case: ICU summary per patient, then find patients with long stays.
WITH icu_per_patient AS (
    SELECT subject_id, count(*) AS n_icu_stays, round(sum(los), 2) AS total_icu_days
    FROM icustays
    GROUP BY subject_id
),
long_stay_patients AS (
    SELECT subject_id, total_icu_days
    FROM icu_per_patient
    WHERE total_icu_days > 20
)
SELECT p.subject_id, p.gender, c.total_icu_days
FROM long_stay_patients c
JOIN patients p USING (subject_id)
ORDER BY c.total_icu_days DESC;

-- [A3] ROW_NUMBER() -- rank rows, no ties
-- Use case: the most recent ICU stay per patient.
-- ROW_NUMBER breaks ties arbitrarily, so add a tiebreaker (icustay_id) to make
-- the result repeatable.
SELECT subject_id, icustay_id, intime, first_careunit
FROM (
    SELECT subject_id, icustay_id, intime, first_careunit,
           ROW_NUMBER() OVER (
               PARTITION BY subject_id
               ORDER BY intime DESC, icustay_id DESC
           ) AS rn
    FROM icustays
) sub
WHERE rn = 1
ORDER BY subject_id
LIMIT 10;

-- [A4] RANK() vs DENSE_RANK() -- rankings with ties
-- Use case: rank care units by number of ICU stays.
-- RANK skips numbers after a tie (1,2,2,4); DENSE_RANK does not (1,2,2,3).
SELECT first_careunit,
       count(*) AS n_stays,
       RANK()       OVER (ORDER BY count(*) DESC) AS rank_with_gaps,
       DENSE_RANK() OVER (ORDER BY count(*) DESC) AS dense_rank
FROM icustays
GROUP BY first_careunit
ORDER BY n_stays DESC;

-- [A5] NTILE(n) -- split rows into n buckets
-- Use case: assign each ICU stay a length-of-stay quartile.
SELECT subject_id, icustay_id, los,
       NTILE(4) OVER (ORDER BY los ASC) AS los_quartile
FROM icustays
WHERE los IS NOT NULL
ORDER BY los
LIMIT 12;

-- [A6] LAG() / LEAD() -- access previous / next row within a partition
-- Use case: time between consecutive unit transfers for the same admission.
-- LAG(intime) returns the intime of the *previous* row in the partition order;
-- LEAD(curr_careunit) returns the value from the *next* row.
-- A named WINDOW avoids repeating the same OVER (...) clause.
SELECT subject_id, hadm_id, curr_careunit, intime,
       LAG(intime)           OVER w AS prev_intime,
       intime - LAG(intime)  OVER w AS gap,
       LEAD(curr_careunit)   OVER w AS next_careunit
FROM transfers
WHERE intime IS NOT NULL
WINDOW w AS (PARTITION BY subject_id, hadm_id ORDER BY intime)
ORDER BY subject_id, hadm_id, intime
LIMIT 10;

-- [A7] Running total (cumulative sum) window, using the default frame
-- Use case: cumulative number of ICU admissions over time.
-- ORDER BY inside the window creates a cumulative (running) aggregate: the
-- default frame is RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW.
SELECT DATE(intime) AS day,
       count(*) AS admissions_today,
       sum(count(*)) OVER (ORDER BY DATE(intime)) AS cumulative_admissions
FROM icustays
GROUP BY day
ORDER BY day;

-- [A8] Moving average using an explicit WINDOW FRAME
-- Use case: 7-day trailing average of daily ICU admissions.
-- Days with zero admissions have no row, so ROWS BETWEEN 6 PRECEDING would
-- cover the last 7 *rows* (possibly weeks apart) and overstate the average.
-- RANGE with an interval covers the last 7 *calendar days* instead; dividing
-- the sum by 7 counts the missing days as zero.
SELECT DATE(intime) AS day,
       count(*) AS admissions_today,
       round(sum(count(*)) OVER (
           ORDER BY DATE(intime)
           RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW
       ) / 7.0, 2) AS trailing_7day_avg
FROM icustays
GROUP BY day
ORDER BY day;

-- [A9] FIRST_VALUE() / LAST_VALUE() with a frame
-- Use case: first and most recent potassium measurement per patient.
-- LAST_VALUE needs the full frame (ROWS ... UNBOUNDED FOLLOWING) to be useful.
-- Window functions keep every input row (one per lab result), so DISTINCT
-- collapses them to one row per patient.
SELECT DISTINCT subject_id,
       FIRST_VALUE(valuenum) OVER w AS first_potassium,
       LAST_VALUE(valuenum)  OVER w AS last_potassium,
       count(*)              OVER w AS n_results
FROM labevents
WHERE itemid = 50971
WINDOW w AS (
    PARTITION BY subject_id
    ORDER BY charttime, row_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
ORDER BY subject_id
LIMIT 10;

-- [A10] Window aggregate for "% of total"
-- Use case: share of labs contributed by each patient (potassium).
-- The windowed SUM keeps detail rows while also giving the total.
SELECT subject_id,
       count(*) AS n_results,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS pct_of_all_results
FROM labevents
WHERE itemid = 50971
GROUP BY subject_id
ORDER BY n_results DESC
LIMIT 10;

-- [A11] DISTINCT ON -- one row per group, chosen by ORDER BY
-- Use case: the earliest ICU admission for each patient (deduplicate).
-- The ORDER BY must start with the DISTINCT ON column(s).
SELECT DISTINCT ON (subject_id) subject_id, icustay_id, intime, first_careunit
FROM icustays
ORDER BY subject_id, intime ASC
LIMIT 10;

-- [A12] LATERAL -- run a subquery PER ROW of the outer query
-- Use case: most recent heart-rate reading for each patient.
-- Heart rate is itemid 211 in CareVue and 220045 in MetaVision; MIMIC-III
-- patients were charted in one system or the other, so check both.
-- The lateral subquery may reference the outer alias (p.subject_id).
-- Note: the schema has no indexes, so this scans chartevents once per patient.
SELECT p.subject_id, hr.charttime, hr.valuenum AS last_hr
FROM patients p
LEFT JOIN LATERAL (
    SELECT c.charttime, c.valuenum
    FROM chartevents c
    WHERE c.itemid IN (211, 220045)
      AND c.subject_id = p.subject_id
      AND c.valuenum IS NOT NULL
    ORDER BY c.charttime DESC
    LIMIT 1
) hr ON true
ORDER BY p.subject_id
LIMIT 10;