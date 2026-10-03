-- QuantoraDiyet initial schema
-- All timestamps are UTC. Use parameterised queries only.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    display_name    TEXT NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    failed_logins   INTEGER NOT NULL DEFAULT 0,
    locked_until    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Case-insensitive unique email lookups.
CREATE UNIQUE INDEX IF NOT EXISTS users_email_lower_idx ON users (lower(email));

-- Refresh tokens are stored as SHA-256 hashes (never the raw token), support
-- rotation, and can be revoked individually or per-user (logout everywhere).
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash      TEXT NOT NULL UNIQUE,
    expires_at      TIMESTAMPTZ NOT NULL,
    revoked_at      TIMESTAMPTZ,
    replaced_by     UUID REFERENCES refresh_tokens(id),
    user_agent      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS refresh_tokens_user_idx ON refresh_tokens (user_id);

-- One profile per user: physical data + preferences used by the AI engine.
CREATE TABLE IF NOT EXISTS user_profiles (
    user_id         UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    sex             TEXT CHECK (sex IN ('male', 'female', 'other')),
    birth_year      INTEGER CHECK (birth_year BETWEEN 1900 AND 2100),
    height_cm       NUMERIC(5,1) CHECK (height_cm BETWEEN 50 AND 260),
    weight_kg       NUMERIC(5,1) CHECK (weight_kg BETWEEN 20 AND 400),
    activity_level  TEXT CHECK (activity_level IN ('sedentary','light','moderate','active','very_active')),
    goal            TEXT CHECK (goal IN ('lose','maintain','gain')),
    diet_type       TEXT CHECK (diet_type IN ('omnivore','vegetarian','vegan','pescatarian','keto','mediterranean','halal','glutenfree')),
    allergies       TEXT[] NOT NULL DEFAULT '{}',
    disliked_foods  TEXT[] NOT NULL DEFAULT '{}',
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Pantry: what the user currently has at home. Drives ingredient-aware plans.
CREATE TABLE IF NOT EXISTS pantry_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    quantity        TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS pantry_user_idx ON pantry_items (user_id);

-- Generated meal plans (daily/weekly/monthly). `plan` holds the structured JSON.
CREATE TABLE IF NOT EXISTS meal_plans (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mode            TEXT NOT NULL CHECK (mode IN ('diet','daily')),
    period          TEXT NOT NULL CHECK (period IN ('daily','weekly','monthly')),
    source          TEXT NOT NULL CHECK (source IN ('ai','fallback')),
    target_calories INTEGER,
    plan            JSONB NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS meal_plans_user_idx ON meal_plans (user_id, created_at DESC);
