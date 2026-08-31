-- A customer's request to hire a provider for one of their services.
-- See BookingStatus.java for the full status state machine.
CREATE TABLE bookings (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id          UUID NOT NULL REFERENCES users (id),
    provider_profile_id  UUID NOT NULL REFERENCES provider_profiles (id),
    service_listing_id   UUID NOT NULL REFERENCES services (id),
    note                 TEXT,
    requested_date       DATE,
    status               VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Both "my bookings" (customer) and "incoming requests" (provider) list by
-- one of these two columns, always ordered by recency - see
-- BookingRepository.
CREATE INDEX idx_bookings_customer_id ON bookings (customer_id);
CREATE INDEX idx_bookings_provider_profile_id ON bookings (provider_profile_id);
