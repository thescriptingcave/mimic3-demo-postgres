# MIMIC-III Clinical Database Demo (Docker + PostgreSQL)

Loads the [MIMIC-III Clinical Database Demo v1.4](https://physionet.org/content/mimiciii-demo/1.4/)
(100 patients, 26 tables) into PostgreSQL 16 using Docker Compose.

The CSV files are **not** committed to this repo — they are fetched from PhysioNet by
`scripts/download-data.sh`, which verifies every file against the official
`SHA256SUMS.txt`.

## Prerequisites

- Docker with Compose v2 (e.g. Docker Desktop)
- A free `POSTGRES_PORT` (default `5432`)

## Quickstart

```bash
# 1. Configure environment (password defaults are insecure — change it)
cp .env.example .env

# 2. Download and checksum-verify the MIMIC demo CSV files
./scripts/download-data.sh

# 3. Start PostgreSQL and import the CSVs (first run only)
docker compose up -d

# 4. Confirm the import finished
docker logs -f mimic3-loader
# Expected final line: "MIMIC-III CSV import completed successfully."

# 5. Verify data
docker exec mimic3-postgres psql -U mimic -d mimic \
  -c "SET search_path TO mimiciii; SELECT count(*) FROM chartevents;"
```

Connect from any PostgreSQL client using the values in `.env`:

| Setting   | Value (defaults)       |
| --------- | ---------------------- |
| Host      | `localhost`            |
| Port      | `5432`                 |
| Database  | `mimic`                |
| User      | `mimic`                |
| Password  | value of `POSTGRES_PASSWORD` |
| Schema    | `mimiciii`             |

## How it works

| Service  | Role                                                                 |
| -------- | -------------------------------------------------------------------- |
| `postgres` | PostgreSQL 16. On first volume creation runs `sql/01-create-schema.sql` |
| `loader`   | Waits for PostgreSQL to be healthy, then runs `sql/02-load-csvs.sh`, which `\copy`s every CSV from `./data` into the `mimiciii` schema |

Data is persisted in the named volume `postgres_data`.

## Re-importing from scratch

```bash
docker compose down -v     # destroys the volume and all loaded data
./scripts/download-data.sh # ensure data/ is populated (from step 2 above)
docker compose up -d       # re-runs schema + import
```

## Notes

- `NOTEEVENTS.csv` contains only a header row (the demo has no free-text notes), so the
  `noteevents` table is intentionally empty.
- Running `docker compose up` on an already-populated volume starts the loader again and
  will **duplicate rows**. Only re-import on an empty volume (see above).

## License and citation

Data provided by PhysioNet under the
[Open Data Commons Open Database License (ODbL) v1.0](https://physionet.org/content/mimiciii-demo/view-license/1.4/) —
see `LICENSE.txt`.

If you use this data, please cite:

> Johnson, A., Pollard, T., & Mark, R. (2019). MIMIC-III Clinical Database Demo
> (version 1.4). PhysioNet. https://doi.org/10.13026/C2HM2Q

And the original MIMIC-III publication:

> Johnson, A. E. W., Pollard, T. J., Shen, L., Lehman, L.-w. H., Feng, M.,
> Ghassemi, M., et al. (2016). MIMIC-III, a freely accessible critical care
> database. *Scientific Data*, 3, 160035. https://doi.org/10.1038/sdata.2016.35