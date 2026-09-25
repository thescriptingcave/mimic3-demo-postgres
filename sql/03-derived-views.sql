-- ============================================================================
-- 03-derived-views.sql
-- Cleaned views that correct known MIMIC-III data quirks.
--
-- The raw tables in the mimiciii schema are left exactly as PhysioNet ships
-- them; these views live in a separate mimiciii_derived schema and read from
-- them, so they always reflect the loaded data.
--
-- Runs automatically on first start (docker-entrypoint-initdb.d). To add the
-- views to an existing database without re-importing:
--   docker exec -i mimic3-postgres psql -U mimic -d mimic < sql/03-derived-views.sql
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS mimiciii_derived;

-- ----------------------------------------------------------------------------
-- icustay_detail: ICU stays with a usable patient age.
-- Quirk: for privacy, patients older than 89 have their dob shifted ~300 years
-- back, so a raw age calculation gives ~300. age_group reports them as '90+'
-- and age uses 91.4, the true median age of that group (MIMIC-III docs).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW mimiciii_derived.icustay_detail AS
WITH ages AS (
    SELECT i.subject_id, i.hadm_id, i.icustay_id, i.dbsource,
           i.first_careunit, i.last_careunit, i.intime, i.outtime, i.los,
           p.gender,
           EXTRACT(YEAR FROM AGE(i.intime, p.dob))::int AS raw_age
    FROM mimiciii.icustays i
    JOIN mimiciii.patients p USING (subject_id)
)
SELECT subject_id, hadm_id, icustay_id, dbsource,
       first_careunit, last_careunit, intime, outtime, los, gender,
       raw_age,
       raw_age > 89                                      AS age_is_shifted,
       CASE WHEN raw_age > 89 THEN 91.4 ELSE raw_age END AS age,
       CASE WHEN raw_age > 89 THEN '90+'
            ELSE raw_age::text END                       AS age_group
FROM ages;

-- ----------------------------------------------------------------------------
-- admissions_ordered: admissions numbered in date order per patient.
-- Quirk: hadm_id values are random, not chronological, so "lower hadm_id =
-- earlier admission" is wrong. admission_seq and the prev_* columns are based
-- on admittime instead.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW mimiciii_derived.admissions_ordered AS
SELECT a.*,
       ROW_NUMBER()     OVER w AS admission_seq,
       LAG(a.hadm_id)   OVER w AS prev_hadm_id,
       LAG(a.dischtime) OVER w AS prev_dischtime,
       round(EXTRACT(EPOCH FROM (a.admittime - LAG(a.dischtime) OVER w)) / 86400, 1)
                               AS days_since_prev_discharge
FROM mimiciii.admissions a
WINDOW w AS (PARTITION BY a.subject_id ORDER BY a.admittime, a.hadm_id);

-- ----------------------------------------------------------------------------
-- heart_rate: one row per heart-rate measurement from either charting system.
-- Quirk: MIMIC-III merges two ICU systems with different item IDs:
-- 211 (CareVue) and 220045 (MetaVision). Querying one ID misses about half the
-- patients. Rows flagged as errors (error = 1) and physiologically impossible
-- values are excluded.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW mimiciii_derived.heart_rate AS
SELECT c.subject_id, c.hadm_id, c.icustay_id, c.charttime,
       c.valuenum AS heart_rate,
       c.itemid,
       CASE c.itemid WHEN 211 THEN 'carevue' ELSE 'metavision' END AS source_system
FROM mimiciii.chartevents c
WHERE c.itemid IN (211, 220045)
  AND c.valuenum > 0
  AND c.valuenum < 300
  AND c.error IS DISTINCT FROM 1;

-- ----------------------------------------------------------------------------
-- labevents_labeled: lab results with their label, fluid and category.
-- Quirk: lab labels are not unique ('Potassium' is both a blood test (50971)
-- and a body-fluid test (50833)), so filtering on label alone mixes specimens.
-- Filter on itemid, or on label AND fluid.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW mimiciii_derived.labevents_labeled AS
SELECT l.subject_id, l.hadm_id, l.itemid, l.charttime,
       d.label, d.fluid, d.category,
       l.value, l.valuenum, l.valueuom, l.flag
FROM mimiciii.labevents l
JOIN mimiciii.d_labitems d USING (itemid);
