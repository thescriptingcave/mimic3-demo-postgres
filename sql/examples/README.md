# SQL Examples for the MIMIC-III Demo Database

A progressive, clinically-flavoured SQL course that runs against the MIMIC-III demo
database loaded by this repository. Every query has been executed and verified against
the demo data (100 patients, 26 tables).

| File | Level | Techniques covered |
| ---- | ----- | ------------------ |
| [`01-beginner.sql`](01-beginner.sql) | Beginner | `SELECT`, `WHERE`, `ORDER BY`, `LIMIT`, `DISTINCT`, `IN`, `BETWEEN`, `LIKE`, `IS NULL`, aggregates, `GROUP BY`, `HAVING`, `EXTRACT` |
| [`02-intermediate.sql`](02-intermediate.sql) | Intermediate | `INNER`/`LEFT`/self/multi-table `JOIN`s, subqueries, `EXISTS`, `CASE`, `COALESCE`, string & date functions |
| [`03-advanced.sql`](03-advanced.sql) | Advanced | CTEs, window functions (`ROW_NUMBER`, `RANK`, `DENSE_RANK`, `NTILE`, `LAG`/`LEAD`, running totals, moving averages, `FIRST_VALUE`), `DISTINCT ON`, `LATERAL` |
| [`04-expert.sql`](04-expert.sql) | Expert | Recursive CTEs, `ROLLUP`, `GROUPING SETS`, `FILTER` pivots, `percentile_cont`, `mode()`, correlated subqueries, `generate_series`, `UNNEST`, `EXPLAIN ANALYZE` |

## How to run

```bash
# From a psql client on the host
psql -h localhost -p 5432 -U mimic -d mimic -f sql/examples/01-beginner.sql

# Or straight into the running container
docker exec -i mimic3-postgres psql -U mimic -d mimic \
  -v ON_ERROR_STOP=1 < sql/examples/04-expert.sql
```

Each file begins with `SET search_path TO mimiciii;` so the `mimiciii` tables are used.
Query labels below (e.g. `[B3]`) match comments inside the files — grep for them to
jump to a specific example.

The demo dataset is small, but several tables (`chartevents`, `labevents`) have
hundreds of thousands of rows, so every example is written with a `WHERE` filter or
`LIMIT` to keep runs fast.

---

## Beginner — 01-beginner.sql

Core reading/aggregation: writing a query, filtering rows, and summarizing groups.

| Query | Concept | Use case |
| ----- | ------- | -------- |
| `[B1]` | `SELECT *` with `LIMIT` | First look at a table |
| `[B2]` | Column list + `ORDER BY` | Pull only the columns you need |
| `[B3]` | `WHERE` + `=` | CCU ICU stays |
| `[B4]` | `WHERE` + comparison | Admissions since 2150 |
| `[B5]` | `BETWEEN` | Labs in a date range |
| `[B6]` | `IN` list | Only elective/urgent admissions |
| `[B7]` | `LIKE` pattern | Ethnicity containing "ASIAN" |
| `[B8]` | `IS NULL` | Admissions with no ED registration time |
| `[B9]` | `SELECT DISTINCT` | Distinct admission types |
| `[B10]` | Multi-column `ORDER BY` + `NULLS LAST` | 10 longest ICU stays |
| `[B11]` | `COUNT` / `COUNT(DISTINCT)` | Total admissions vs distinct patients |
| `[B12]` | `SUM` / `AVG` / `MIN` / `MAX` | ICU length-of-stay summary |
| `[B13]` | `GROUP BY` + aggregate | Deaths per gender |
| `[B14]` | `HAVING` | Care units averaging > 4 ICU days |
| `[B15]` | Arithmetic in `SELECT` | ICU stay length in hours |
| `[B16]` | `EXTRACT(YEAR ...)` + `GROUP BY` | Admissions per year |

**Key mental model:** `WHERE` filters *rows*; `GROUP BY` collapses rows into groups; `HAVING`
filters *groups* (it runs after aggregation). Aggregates like `count(*)/avg(...)` are
only allowed because of `GROUP BY`.

---

## Intermediate — 02-intermediate.sql

Relational thinking: how to combine tables and use subqueries.

| Query | Concept | Use case |
| ----- | ------- | -------- |
| `[I1]` | `INNER JOIN ... USING` | Attach ICU details to admissions |
| `[I2]` | 3-table JOIN | Patient + admission + ICU record |
| `[I3]` | `LEFT JOIN` | Keep admissions that lack an ICU stay |
| `[I4]` | Anti-join (`LEFT JOIN ... IS NULL`) | Admissions **without** any ICU stay |
| `[I5]` | Self join | Readmission pairs (days between) |
| `[I6]` | Scalar subquery in `WHERE` | ICU stays longer than average |
| `[I7]` | Derived table in `FROM` | Filter on a per-patient summary |
| `[I8]` | `EXISTS` | Patients who had any microbiology culture |
| `[I9]` | `CASE` expression | Bucket ICU stays into short/normal/long |
| `[I10]` | `COALESCE` | First known death date |
| `[I11]` | String functions | Normalize ethnicity for grouping |
| `[I12]` | `AGE()` + `EXTRACT` | Patient age at ICU admission |
| `[I13]` | JOIN + `GROUP BY` + `HAVING` | Top patients by potassium labs |
| `[I14]` | JOIN + value range | Abnormal high-potassium events |

**Key mental model:** `INNER JOIN` keeps matches only; `LEFT JOIN` keeps every row of
the left table and NULL-fills the right. A scalar subquery returns one value; a derived
table (`FROM (...) AS d`) is just a name for a subquery result you can filter on.

---

## Advanced — 03-advanced.sql

Composable queries (CTEs) and the workhorse of analytics: window functions.

| Query | Concept | Use case |
| ----- | ------- | -------- |
| `[A1]` | Single CTE (`WITH`) | Named annual admissions summary |
| `[A2]` | Multiple CTEs | Long-stay patients, step by step |
| `[A3]` | `ROW_NUMBER()` | Most recent ICU stay per patient |
| `[A4]` | `RANK()` vs `DENSE_RANK()` | Rank care units by stay count |
| `[A5]` | `NTILE(4)` | Assign LOS quartiles |
| `[A6]` | `LAG()` | Gap between consecutive unit transfers |
| `[A7]` | Window `sum()` (running total) | Cumulative ICU admissions over time |
| `[A8]` | Explicit `ROWS BETWEEN` frame | 7-day trailing average admissions |
| `[A9]` | `FIRST_VALUE` / `LAST_VALUE` | First vs last potassium per patient |
| `[A10]` | Window share of total | % of all labs a patient contributed |
| `[A11]` | `DISTINCT ON` | Earliest ICU admission per patient |
| `[A12]` | `LATERAL` subquery | Last heart-rate reading per patient |

**Key mental model:** a window function computes a value *per row* in a partition
(`PARTITION BY`), ordered by `ORDER BY`, without collapsing rows the way `GROUP BY`
does. The frame (`ROWS BETWEEN ... AND ...`) decides which peer rows the function sees.
`LATERAL` lets a subquery reference the outer query's columns and run once per outer row.

---

## Expert — 04-expert.sql

Advanced reporting machinery: recursive series, grouping sets, pivots, statistical
aggregates, and query plan inspection.

| Query | Concept | Use case |
| ----- | ------- | -------- |
| `[X1]` | Recursive CTE + `LEFT JOIN` | Monthly admissions calendar *including zero months* |
| `[X2]` | `ROLLUP` | Insurance/type breakdown with subtotals |
| `[X3]` | `GROUPING SETS` | Deliberate subtotal combinations |
| `[X4]` | `FILTER` (pivot) | Admission types side-by-side per year |
| `[X5]` | `percentile_cont` | Median / quartiles / p95 of ICU LOS |
| `[X6]` | `mode()` | Most common admission type per era |
| `[X7]` | `generate_series` | Expand one ICU stay into hourly rows |
| `[X8]` | Correlated subquery | First admission per patient |
| `[X9]` | `UNNEST` + `WITH ORDINALITY` | Flatten diagnosis lists into rows |
| `[X10]` | `EXPLAIN ANALYZE` | See how the planner executes a query |

**Key mental models**

- A *recursive CTE* builds a result row-by-row (seed row, then `UNION ALL` with an
  iteration step) — perfect for calendar/sequence generation.
- `ROLLUP(a, b)` produces `(a,b)`, `(a)`, `()` subtotals; `GROUPING SETS` lets you
  choose only the combinations you want; `GROUPING(...)` tells you which level a row is.
- `FILTER (WHERE ...)` turns aggregate counting/pivoting into a single pass per expression.
- `percentile_cont` has no `numeric` overload in PostgreSQL — it returns
  `double precision`, so cast before `round()`.
- `EXPLAIN ANALYZE` actually runs the query — keep its scope small.

---

## Reference: useful MIMIC-III table cheat-sheet

These tables are used throughout the examples (all under the `mimiciii` schema):

| Table | What's in one row | Key columns |
| ----- | ----------------- | ----------- |
| `patients` | one subject | `subject_id`, `gender`, `dob`, `expire_flag` |
| `admissions` | one hospital admission | `subject_id`, `hadm_id`, `admittime`, `dischtime`, `admission_type`, `ethnicity` |
| `icustays` | one ICU unit stay | `subject_id`, `hadm_id`, `icustay_id`, `first_careunit`, `intime`, `outtime`, `los` |
| `transfers` | one unit transfer | `subject_id`, `hadm_id`, `prev_careunit`, `curr_careunit`, `intime` |
| `diagnoses_icd` | one diagnosis code on an admission | `subject_id`, `hadm_id`, `seq_num`, `icd9_code` |
| `d_icd_diagnoses` | diagnosis code dictionary | `icd9_code`, `short_title` |
| `labevents` | one lab measurement | `subject_id`, `hadm_id`, `itemid`, `charttime`, `valuenum`, `valueuom` |
| `d_labitems` | lab item dictionary | `itemid`, `label`, `fluid` |
| `chartevents` | one charted vital event | `subject_id`, `icustay_id`, `itemid`, `charttime`, `value`, `valuenum` |
| `d_items` | item dictionary (vitals etc.) | `itemid`, `label`, `category` |
| `microbiologyevents` | one culture result | `subject_id`, `org_name`, `ab_name`, `interpretation` |

**Useful item IDs** used in the examples (from `d_items` / `d_labitems`):

- Heart Rate (chartevents, CV source): `211`
- Potassium (labevents): `50971`

For the full data dictionary, see the [MIMIC-III documentation](https://mimic.mit.edu/docs/iii/).