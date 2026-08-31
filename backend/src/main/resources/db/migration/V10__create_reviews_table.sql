-- A customer's rating/comment for one COMPLETED booking. One review per
-- booking - see the unique constraint on booking_id - enforced again in
-- ReviewService before that constraint would even be hit, so a duplicate
-- attempt gets a clean error message instead of a raw SQL exception.
CREATE TABLE reviews (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id           UUID NOT NULL UNIQUE REFERENCES bookings (id),
    customer_id          UUID NOT NULL REFERENCES users (id),
    provider_profile_id  UUID NOT NULL REFERENCES provider_profiles (id),
    rating               INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment              TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Powers "show this provider's reviews" (GET /api/providers/{id}/reviews)
-- and the average-rating calculation shown in provider search/detail.
CREATE INDEX idx_reviews_provider_profile_id ON reviews (provider_profile_id);
