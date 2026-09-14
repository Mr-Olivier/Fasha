-- A customer's saved/favorited providers (the heart icon on a provider's
-- profile) - lets them quickly get back to providers they liked without
-- re-searching. Composite primary key instead of a surrogate id: the only
-- thing this table is ever queried by is "did THIS customer favorite THIS
-- provider" or "list THIS customer's favorites", and the pair is naturally
-- unique (favoriting twice is a no-op, not a second row).
CREATE TABLE favorite_providers (
    customer_id          UUID NOT NULL REFERENCES users (id),
    provider_profile_id  UUID NOT NULL REFERENCES provider_profiles (id),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (customer_id, provider_profile_id)
);

-- Powers "list this provider's favoriters" if ever needed (e.g. a future
-- "N people saved this" count) - the PK above already covers customer-first
-- lookups (a customer's own favorites list, and the single-pair existence
-- check behind the heart icon's filled/outline state).
CREATE INDEX idx_favorite_providers_provider_profile_id ON favorite_providers (provider_profile_id);
