#!/usr/bin/env bash
set -Eeuo pipefail

: "${MIMIC_DATA_DIR:=/data}"

psql \
  --set=ON_ERROR_STOP=1 \
  --dbname="$PGDATABASE" \
  <<SQL
SET search_path TO mimiciii, public;

\copy admissions             FROM '${MIMIC_DATA_DIR}/ADMISSIONS.csv'             WITH (FORMAT csv, HEADER true, NULL '');
\copy callout                FROM '${MIMIC_DATA_DIR}/CALLOUT.csv'                WITH (FORMAT csv, HEADER true, NULL '');
\copy caregivers             FROM '${MIMIC_DATA_DIR}/CAREGIVERS.csv'             WITH (FORMAT csv, HEADER true, NULL '');
\copy chartevents            FROM '${MIMIC_DATA_DIR}/CHARTEVENTS.csv'            WITH (FORMAT csv, HEADER true, NULL '');
\copy cptevents              FROM '${MIMIC_DATA_DIR}/CPTEVENTS.csv'              WITH (FORMAT csv, HEADER true, NULL '');
\copy datetimeevents         FROM '${MIMIC_DATA_DIR}/DATETIMEEVENTS.csv'         WITH (FORMAT csv, HEADER true, NULL '');
\copy diagnoses_icd          FROM '${MIMIC_DATA_DIR}/DIAGNOSES_ICD.csv'          WITH (FORMAT csv, HEADER true, NULL '');
\copy drgcodes               FROM '${MIMIC_DATA_DIR}/DRGCODES.csv'               WITH (FORMAT csv, HEADER true, NULL '');
\copy d_cpt                  FROM '${MIMIC_DATA_DIR}/D_CPT.csv'                  WITH (FORMAT csv, HEADER true, NULL '');
\copy d_icd_diagnoses        FROM '${MIMIC_DATA_DIR}/D_ICD_DIAGNOSES.csv'        WITH (FORMAT csv, HEADER true, NULL '');
\copy d_icd_procedures       FROM '${MIMIC_DATA_DIR}/D_ICD_PROCEDURES.csv'       WITH (FORMAT csv, HEADER true, NULL '');
\copy d_items                FROM '${MIMIC_DATA_DIR}/D_ITEMS.csv'                WITH (FORMAT csv, HEADER true, NULL '');
\copy d_labitems             FROM '${MIMIC_DATA_DIR}/D_LABITEMS.csv'             WITH (FORMAT csv, HEADER true, NULL '');
\copy icustays               FROM '${MIMIC_DATA_DIR}/ICUSTAYS.csv'               WITH (FORMAT csv, HEADER true, NULL '');
\copy inputevents_cv         FROM '${MIMIC_DATA_DIR}/INPUTEVENTS_CV.csv'         WITH (FORMAT csv, HEADER true, NULL '');
\copy inputevents_mv         FROM '${MIMIC_DATA_DIR}/INPUTEVENTS_MV.csv'         WITH (FORMAT csv, HEADER true, NULL '');
\copy labevents              FROM '${MIMIC_DATA_DIR}/LABEVENTS.csv'              WITH (FORMAT csv, HEADER true, NULL '');
\copy microbiologyevents     FROM '${MIMIC_DATA_DIR}/MICROBIOLOGYEVENTS.csv'     WITH (FORMAT csv, HEADER true, NULL '');
\copy noteevents             FROM '${MIMIC_DATA_DIR}/NOTEEVENTS.csv'             WITH (FORMAT csv, HEADER true, NULL '');
\copy outputevents           FROM '${MIMIC_DATA_DIR}/OUTPUTEVENTS.csv'           WITH (FORMAT csv, HEADER true, NULL '');
\copy patients               FROM '${MIMIC_DATA_DIR}/PATIENTS.csv'               WITH (FORMAT csv, HEADER true, NULL '');
\copy prescriptions          FROM '${MIMIC_DATA_DIR}/PRESCRIPTIONS.csv'          WITH (FORMAT csv, HEADER true, NULL '');
\copy procedureevents_mv     FROM '${MIMIC_DATA_DIR}/PROCEDUREEVENTS_MV.csv'     WITH (FORMAT csv, HEADER true, NULL '');
\copy procedures_icd         FROM '${MIMIC_DATA_DIR}/PROCEDURES_ICD.csv'         WITH (FORMAT csv, HEADER true, NULL '');
\copy services               FROM '${MIMIC_DATA_DIR}/SERVICES.csv'               WITH (FORMAT csv, HEADER true, NULL '');
\copy transfers              FROM '${MIMIC_DATA_DIR}/TRANSFERS.csv'              WITH (FORMAT csv, HEADER true, NULL '');

ANALYZE;
SQL

echo "MIMIC-III CSV import completed successfully."