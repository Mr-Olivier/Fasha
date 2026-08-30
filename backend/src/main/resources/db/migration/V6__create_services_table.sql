-- One row per service a provider offers. price is NUMERIC (exact decimal),
-- never FLOAT/DOUBLE - money must never use binary floating point, which
-- can't represent amounts like 0.10 exactly and accumulates rounding error.

CREATE TABLE services (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_profile_id UUID NOT NULL,
    category_id         UUID NOT NULL,
    name                VARCHAR(150) NOT NULL,
    description         TEXT,
    price               NUMERIC(12, 2) NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_services_provider_profile FOREIGN KEY (provider_profile_id) REFERENCES provider_profiles (id),
    CONSTRAINT fk_services_category FOREIGN KEY (category_id) REFERENCES categories (id),
    CONSTRAINT chk_services_price_non_negative CHECK (price >= 0)
);

-- Unlike users.email (unique, so already indexed), provider_profile_id here
-- is NOT unique - one provider has many services - so "list my services"
-- needs its own explicit index to avoid a full table scan.
CREATE INDEX idx_services_provider_profile_id ON services (provider_profile_id);
