-- PakRastah Database Schema
-- PostgreSQL 16 | Raw SQL | No ORM

-- ---------------------------------------------------------------------------
-- USERS & IDENTITY
-- ---------------------------------------------------------------------------

CREATE TABLE users (
    user_id        SERIAL PRIMARY KEY,
    email          VARCHAR(255)  NOT NULL,
    password_hash  VARCHAR(255)  NOT NULL DEFAULT 'PLACEHOLDER',
    role           VARCHAR(30)   NOT NULL
                     CHECK (role IN ('admin','business','facility','auditor','developer',
                                     'charity','eatery','citizen')),
    full_name      VARCHAR(255)  NOT NULL,
    phone          VARCHAR(20),
    wallet_balance NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (wallet_balance >= 0),
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT users_email_unique UNIQUE (email)
);

-- ---------------------------------------------------------------------------
-- CORE BUSINESS ENTITIES
-- ---------------------------------------------------------------------------

CREATE TABLE businesses (
    business_id         SERIAL PRIMARY KEY,
    user_id             INTEGER      NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name                VARCHAR(255) NOT NULL,
    address             TEXT         NOT NULL,
    city                VARCHAR(100) NOT NULL,
    category            VARCHAR(50)  NOT NULL
                          CHECK (category IN ('manufacturing','food_processing','retail',
                                              'hospitality','textile','logistics','other')),
    registration_number VARCHAR(50)  NOT NULL,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT businesses_registration_unique UNIQUE (registration_number),
    CONSTRAINT businesses_user_unique         UNIQUE (user_id)
);

CREATE TABLE processing_facilities (
    facility_id             SERIAL PRIMARY KEY,
    user_id                 INTEGER      NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name                    VARCHAR(255) NOT NULL,
    address                 TEXT         NOT NULL,
    city                    VARCHAR(100) NOT NULL,
    capacity_tonnes_per_day NUMERIC(10,2) NOT NULL CHECK (capacity_tonnes_per_day > 0),
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT facilities_user_unique UNIQUE (user_id)
);

-- ---------------------------------------------------------------------------
-- WASTE EVENT LEDGER
-- ---------------------------------------------------------------------------

CREATE TABLE waste_events (
    event_id    SERIAL PRIMARY KEY,
    business_id INTEGER      NOT NULL REFERENCES businesses(business_id)          ON DELETE RESTRICT,
    facility_id INTEGER               REFERENCES processing_facilities(facility_id) ON DELETE RESTRICT,
    event_date  DATE         NOT NULL DEFAULT CURRENT_DATE,
    tonnage     NUMERIC(10,3) NOT NULL CHECK (tonnage > 0),
    waste_type  VARCHAR(30)  NOT NULL
                  CHECK (waste_type IN ('organic','recyclable','textile','hazardous','general','mixed')),
    status      VARCHAR(20)  NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','received','processed')),
    notes       TEXT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE processing_outputs (
    output_id         SERIAL PRIMARY KEY,
    event_id          INTEGER       NOT NULL REFERENCES waste_events(event_id)             ON DELETE RESTRICT,
    facility_id       INTEGER       NOT NULL REFERENCES processing_facilities(facility_id) ON DELETE RESTRICT,
    recovered_tonnage NUMERIC(10,3) NOT NULL CHECK (recovered_tonnage > 0),
    output_type       VARCHAR(30)   NOT NULL
                        CHECK (output_type IN ('recycled','composted','reused','energy_recovery')),
    processed_date    DATE          NOT NULL DEFAULT CURRENT_DATE,
    notes             TEXT,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT processing_outputs_event_unique UNIQUE (event_id)
);

-- ---------------------------------------------------------------------------
-- BUSINESS METRICS  (rolling 90-day aggregate, maintained by triggers)
-- ---------------------------------------------------------------------------

CREATE TABLE business_metrics (
    metric_id            SERIAL PRIMARY KEY,
    business_id          INTEGER       NOT NULL REFERENCES businesses(business_id) ON DELETE CASCADE,
    diversion_ratio      NUMERIC(6,5)  NOT NULL DEFAULT 0
                           CHECK (diversion_ratio BETWEEN 0 AND 1),
    total_tonnage_90d    NUMERIC(12,3) NOT NULL DEFAULT 0,
    diverted_tonnage_90d NUMERIC(12,3) NOT NULL DEFAULT 0,
    diverted_tonnage_30d NUMERIC(12,3) NOT NULL DEFAULT 0,
    last_updated         TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT business_metrics_business_unique UNIQUE (business_id)
);

-- ---------------------------------------------------------------------------
-- CERTIFICATION LIFECYCLE
-- ---------------------------------------------------------------------------

CREATE TABLE certification_queue (
    queue_id     SERIAL PRIMARY KEY,
    business_id  INTEGER     NOT NULL REFERENCES businesses(business_id) ON DELETE RESTRICT,
    status       VARCHAR(30) NOT NULL DEFAULT 'eligible_for_review'
                   CHECK (status IN ('eligible_for_review','under_review','approved','denied')),
    tier         VARCHAR(10)
                   CHECK (tier IN ('bronze','silver','gold')),
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at  TIMESTAMPTZ,
    reviewer_id  INTEGER     REFERENCES users(user_id) ON DELETE SET NULL,
    notes        TEXT
);

CREATE TABLE certifications (
    certification_id SERIAL PRIMARY KEY,
    business_id      INTEGER     NOT NULL REFERENCES businesses(business_id) ON DELETE RESTRICT,
    queue_id         INTEGER              REFERENCES certification_queue(queue_id) ON DELETE SET NULL,
    cert_number      VARCHAR(50) NOT NULL,
    tier             VARCHAR(10) NOT NULL CHECK (tier IN ('bronze','silver','gold')),
    issued_date      DATE        NOT NULL DEFAULT CURRENT_DATE,
    expiry_date      DATE        NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'active'
                       CHECK (status IN ('active','expired','revoked')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT certifications_cert_number_unique UNIQUE (cert_number)
);

-- ---------------------------------------------------------------------------
-- TAX CREDITS
-- ---------------------------------------------------------------------------

CREATE TABLE tax_credits (
    credit_id          SERIAL PRIMARY KEY,
    business_id        INTEGER       NOT NULL REFERENCES businesses(business_id)    ON DELETE RESTRICT,
    certification_id   INTEGER                REFERENCES certifications(certification_id) ON DELETE SET NULL,
    amount_pkr         NUMERIC(14,2) NOT NULL CHECK (amount_pkr > 0),
    diverted_tonnage   NUMERIC(12,3) NOT NULL,
    tier               VARCHAR(10)   NOT NULL,
    rate_per_tonne_pkr NUMERIC(10,2) NOT NULL,
    calculation_date   DATE          NOT NULL DEFAULT CURRENT_DATE,
    procedure_run_id   VARCHAR(60),
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- AUDIT LOG  (populated by delete triggers + procedure)
-- ---------------------------------------------------------------------------

CREATE TABLE audit_log (
    log_id       SERIAL PRIMARY KEY,
    table_name   VARCHAR(100) NOT NULL,
    operation    VARCHAR(10)  NOT NULL CHECK (operation IN ('DELETE','INSERT','UPDATE')),
    row_id       INTEGER,
    performed_by VARCHAR(255),
    performed_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    old_data     JSONB,
    context      TEXT
);

-- ---------------------------------------------------------------------------
-- STUB TABLES  (seeded read-only for food rescue + marketplace)
-- ---------------------------------------------------------------------------

CREATE TABLE food_donations (
    donation_id   SERIAL PRIMARY KEY,
    eatery_id     INTEGER       NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    charity_id    INTEGER       NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    food_type     VARCHAR(100)  NOT NULL,
    quantity_kg   NUMERIC(8,2)  NOT NULL CHECK (quantity_kg > 0),
    donation_date DATE          NOT NULL DEFAULT CURRENT_DATE,
    status        VARCHAR(20)   NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','collected','delivered','spoiled')),
    notes         TEXT,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE marketplace_listings (
    listing_id  SERIAL PRIMARY KEY,
    seller_id   INTEGER       NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    buyer_id    INTEGER                REFERENCES users(user_id) ON DELETE SET NULL,
    title       VARCHAR(255)  NOT NULL,
    description TEXT,
    category    VARCHAR(50)   NOT NULL
                  CHECK (category IN ('clothing','electronics','furniture','books',
                                      'appliances','materials','other')),
    price_pkr   NUMERIC(10,2) NOT NULL CHECK (price_pkr >= 0),
    quantity    INTEGER       NOT NULL DEFAULT 1 CHECK (quantity > 0),
    status      VARCHAR(20)   NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active','sold','removed')),
    city        VARCHAR(100),
    listed_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- WALLET TRANSACTIONS  (ledger of all balance movements per user)
-- ---------------------------------------------------------------------------

CREATE TABLE wallet_transactions (
    txn_id      SERIAL PRIMARY KEY,
    user_id     INTEGER       NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    amount      NUMERIC(12,2) NOT NULL,
    txn_type    VARCHAR(20)   NOT NULL
                  CHECK (txn_type IN ('topup','purchase','sale','refund')),
    listing_id  INTEGER                REFERENCES marketplace_listings(listing_id) ON DELETE SET NULL,
    description TEXT          NOT NULL,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
