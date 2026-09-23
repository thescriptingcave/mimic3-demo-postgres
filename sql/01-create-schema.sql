CREATE SCHEMA IF NOT EXISTS mimiciii;
SET search_path TO mimiciii, public;

CREATE TABLE admissions (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER NOT NULL,
    admittime           TIMESTAMP(0) NOT NULL,
    dischtime           TIMESTAMP(0) NOT NULL,
    deathtime           TIMESTAMP(0),
    admission_type      VARCHAR(50) NOT NULL,
    admission_location  VARCHAR(50) NOT NULL,
    discharge_location  VARCHAR(50) NOT NULL,
    insurance           VARCHAR(255) NOT NULL,
    language            VARCHAR(10),
    religion            VARCHAR(50),
    marital_status      VARCHAR(50),
    ethnicity           VARCHAR(200) NOT NULL,
    edregtime           TIMESTAMP(0),
    edouttime           TIMESTAMP(0),
    diagnosis           VARCHAR(300),
    hospital_expire_flag SMALLINT,
    has_chartevents_data SMALLINT NOT NULL
);

CREATE TABLE callout (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER NOT NULL,
    submit_wardid       INTEGER,
    submit_careunit     VARCHAR(15),
    curr_wardid         INTEGER,
    curr_careunit       VARCHAR(15),
    callout_wardid      INTEGER,
    callout_service     VARCHAR(10) NOT NULL,
    request_tele        SMALLINT,
    request_resp        SMALLINT,
    request_cdiff       SMALLINT,
    request_mrsa        SMALLINT,
    request_vre         SMALLINT,
    callout_status      VARCHAR(20) NOT NULL,
    callout_outcome     VARCHAR(20) NOT NULL,
    discharge_wardid    INTEGER,
    acknowledge_status  VARCHAR(20) NOT NULL,
    createtime          TIMESTAMP(0) NOT NULL,
    updatetime          TIMESTAMP(0) NOT NULL,
    acknowledgetime     TIMESTAMP(0),
    outcometime         TIMESTAMP(0),
    firstreservationtime TIMESTAMP(0),
    currentreservationtime TIMESTAMP(0)
);

CREATE TABLE caregivers (
    row_id              INTEGER,
    cgid                INTEGER NOT NULL,
    label               VARCHAR(15),
    description         VARCHAR(30)
);

CREATE TABLE chartevents (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER,
    icustay_id          INTEGER,
    itemid              INTEGER NOT NULL,
    charttime           TIMESTAMP(0),
    storetime           TIMESTAMP(0),
    cgid                INTEGER,
    value               VARCHAR(255),
    valuenum            NUMERIC,
    valueuom            VARCHAR(50),
    warning             SMALLINT,
    error               SMALLINT,
    resultstatus        VARCHAR(50),
    stopped             VARCHAR(50)
);

CREATE TABLE cptevents (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER NOT NULL,
    costcenter          VARCHAR(10) NOT NULL,
    chartdate           DATE,
    cpt_cd              VARCHAR(10) NOT NULL,
    cpt_number          INTEGER,
    cpt_suffix          VARCHAR(5),
    ticket_id_seq       INTEGER,
    sectionheader       VARCHAR(50),
    subsectionheader    VARCHAR(255),
    description         VARCHAR(100)
);

CREATE TABLE datetimeevents (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER,
    icustay_id          INTEGER,
    itemid              INTEGER NOT NULL,
    charttime           TIMESTAMP(0) NOT NULL,
    storetime           TIMESTAMP(0) NOT NULL,
    cgid                INTEGER,
    value               TIMESTAMP(0),
    valueuom            VARCHAR(50),
    warning             SMALLINT,
    error               SMALLINT,
    resultstatus        VARCHAR(50),
    stopped             VARCHAR(50)
);

CREATE TABLE diagnoses_icd (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER NOT NULL,
    seq_num             INTEGER,
    icd9_code           VARCHAR(10)
);

CREATE TABLE drgcodes (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER NOT NULL,
    drg_type            VARCHAR(20) NOT NULL,
    drg_code            VARCHAR(20) NOT NULL,
    description         VARCHAR(255),
    drg_severity        SMALLINT,
    drg_mortality       SMALLINT
);

CREATE TABLE d_cpt (
    row_id              INTEGER,
    category            SMALLINT NOT NULL,
    sectionrange        VARCHAR(100) NOT NULL,
    sectionheader       VARCHAR(50) NOT NULL,
    subsectionrange     VARCHAR(100) NOT NULL,
    subsectionheader    VARCHAR(255),
    codesuffix          VARCHAR(5),
    mincodeinsubsection INTEGER,
    maxcodeinsubsection INTEGER
);

CREATE TABLE d_icd_diagnoses (
    row_id              INTEGER,
    icd9_code           VARCHAR(10) NOT NULL,
    short_title         VARCHAR(50) NOT NULL,
    long_title          VARCHAR(255) NOT NULL
);

CREATE TABLE d_icd_procedures (
    row_id              INTEGER,
    icd9_code           VARCHAR(10) NOT NULL,
    short_title         VARCHAR(50) NOT NULL,
    long_title          VARCHAR(255) NOT NULL
);

CREATE TABLE d_items (
    row_id              INTEGER,
    itemid              INTEGER NOT NULL,
    label               VARCHAR(200),
    abbreviation        VARCHAR(100),
    dbsource            VARCHAR(20),
    linksto             VARCHAR(50),
    category            VARCHAR(100),
    unitname            VARCHAR(100),
    param_type          VARCHAR(30),
    conceptid           INTEGER
);

CREATE TABLE d_labitems (
    row_id              INTEGER,
    itemid              INTEGER NOT NULL,
    label               VARCHAR(100) NOT NULL,
    fluid               VARCHAR(100) NOT NULL,
    category            VARCHAR(100) NOT NULL,
    loinc_code          VARCHAR(100)
);

CREATE TABLE icustays (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER NOT NULL,
    icustay_id          INTEGER NOT NULL,
    dbsource            VARCHAR(20) NOT NULL,
    first_careunit      VARCHAR(20) NOT NULL,
    last_careunit       VARCHAR(20) NOT NULL,
    first_wardid        SMALLINT,
    last_wardid         SMALLINT,
    intime              TIMESTAMP(0) NOT NULL,
    outtime             TIMESTAMP(0),
    los                 NUMERIC
);

CREATE TABLE inputevents_cv (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER,
    icustay_id          INTEGER,
    charttime           TIMESTAMP(0),
    itemid              INTEGER,
    amount              NUMERIC,
    amountuom           VARCHAR(30),
    rate                NUMERIC,
    rateuom             VARCHAR(30),
    storetime           TIMESTAMP(0),
    cgid                INTEGER,
    orderid             INTEGER,
    linkorderid         INTEGER,
    stopped             VARCHAR(30),
    newbottle           SMALLINT,
    originalamount      NUMERIC,
    originalamountuom   VARCHAR(30),
    originalroute       VARCHAR(30),
    originalrate        NUMERIC,
    originalrateuom     VARCHAR(30),
    originalsite        VARCHAR(30)
);

CREATE TABLE inputevents_mv (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER,
    icustay_id          INTEGER,
    starttime           TIMESTAMP(0),
    endtime             TIMESTAMP(0),
    itemid              INTEGER,
    amount              NUMERIC,
    amountuom           VARCHAR(30),
    rate                NUMERIC,
    rateuom             VARCHAR(30),
    storetime           TIMESTAMP(0),
    cgid                INTEGER,
    orderid             INTEGER,
    linkorderid         INTEGER,
    ordercategoryname   VARCHAR(100),
    secondaryordercategoryname VARCHAR(100),
    ordercomponenttypedescription VARCHAR(200),
    ordercategorydescription VARCHAR(50),
    patientweight       NUMERIC,
    totalamount         NUMERIC,
    totalamountuom      VARCHAR(50),
    isopenbag           SMALLINT,
    continueinnextdept  SMALLINT,
    cancelreason        SMALLINT,
    statusdescription   VARCHAR(30),
    comments_editedby   VARCHAR(30),
    comments_canceledby VARCHAR(30),
    comments_date       TIMESTAMP(0),
    originalamount      NUMERIC,
    originalrate        NUMERIC
);

CREATE TABLE labevents (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER,
    itemid              INTEGER NOT NULL,
    charttime           TIMESTAMP(0),
    value               VARCHAR(200),
    valuenum            NUMERIC,
    valueuom            VARCHAR(30),
    flag                VARCHAR(30)
);

CREATE TABLE microbiologyevents (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER,
    chartdate           DATE,
    charttime           TIMESTAMP(0),
    spec_itemid         INTEGER,
    spec_type_desc      VARCHAR(100),
    org_itemid          INTEGER,
    org_name            VARCHAR(100),
    isolate_num         SMALLINT,
    ab_itemid           INTEGER,
    ab_name             VARCHAR(30),
    dilution_text       VARCHAR(10),
    dilution_comparison VARCHAR(20),
    dilution_value      NUMERIC,
    interpretation      VARCHAR(5)
);

CREATE TABLE noteevents (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER,
    chartdate           DATE,
    charttime           TIMESTAMP(0),
    storetime           TIMESTAMP(0),
    category            VARCHAR(50),
    description         VARCHAR(255),
    cgid                INTEGER,
    iserror             VARCHAR(10),
    text                TEXT
);

CREATE TABLE outputevents (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER,
    icustay_id          INTEGER,
    charttime           TIMESTAMP(0),
    itemid              INTEGER,
    value               NUMERIC,
    valueuom            VARCHAR(30),
    storetime           TIMESTAMP(0),
    cgid                INTEGER,
    stopped             VARCHAR(30),
    newbottle           SMALLINT,
    iserror             SMALLINT
);

CREATE TABLE patients (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    gender              VARCHAR(5) NOT NULL,
    dob                 TIMESTAMP(0) NOT NULL,
    dod                 TIMESTAMP(0),
    dod_hosp            TIMESTAMP(0),
    dod_ssn             TIMESTAMP(0),
    expire_flag         SMALLINT NOT NULL
);

CREATE TABLE prescriptions (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER NOT NULL,
    icustay_id          INTEGER,
    startdate           TIMESTAMP(0),
    enddate             TIMESTAMP(0),
    drug_type           VARCHAR(100) NOT NULL,
    drug                VARCHAR(100) NOT NULL,
    drug_name_poe       VARCHAR(100),
    drug_name_generic   VARCHAR(100),
    formulary_drug_cd   VARCHAR(120),
    gsn                 VARCHAR(200),
    ndc                 VARCHAR(120),
    prod_strength       VARCHAR(120),
    dose_val_rx         VARCHAR(120),
    dose_unit_rx        VARCHAR(120),
    form_val_disp       VARCHAR(120),
    form_unit_disp      VARCHAR(120),
    route               VARCHAR(120)
);

CREATE TABLE procedureevents_mv (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER,
    icustay_id          INTEGER,
    starttime           TIMESTAMP(0),
    endtime             TIMESTAMP(0),
    itemid              INTEGER,
    value               NUMERIC,
    valueuom            VARCHAR(30),
    location            VARCHAR(30),
    locationcategory    VARCHAR(30),
    storetime           TIMESTAMP(0),
    cgid                INTEGER,
    orderid             INTEGER,
    linkorderid         INTEGER,
    ordercategoryname   VARCHAR(100),
    secondaryordercategoryname VARCHAR(100),
    ordercategorydescription VARCHAR(50),
    isopenbag           SMALLINT,
    continueinnextdept  SMALLINT,
    cancelreason        SMALLINT,
    statusdescription   VARCHAR(30),
    comments_editedby   VARCHAR(30),
    comments_canceledby VARCHAR(30),
    comments_date       TIMESTAMP(0)
);

CREATE TABLE procedures_icd (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER NOT NULL,
    seq_num             INTEGER,
    icd9_code           VARCHAR(10)
);

CREATE TABLE services (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER NOT NULL,
    transfertime        TIMESTAMP(0) NOT NULL,
    prev_service        VARCHAR(20),
    curr_service        VARCHAR(20)
);

CREATE TABLE transfers (
    row_id              INTEGER,
    subject_id          INTEGER NOT NULL,
    hadm_id             INTEGER NOT NULL,
    icustay_id          INTEGER,
    dbsource            VARCHAR(20),
    eventtype           VARCHAR(20),
    prev_careunit       VARCHAR(20),
    curr_careunit       VARCHAR(20),
    prev_wardid         SMALLINT,
    curr_wardid         SMALLINT,
    intime              TIMESTAMP(0),
    outtime             TIMESTAMP(0),
    los                 NUMERIC
);