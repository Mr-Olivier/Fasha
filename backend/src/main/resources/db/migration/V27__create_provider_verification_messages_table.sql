-- A two-way conversation between a provider and admin about their
-- verification (D7 "Get verified") - e.g. admin telling a provider their
-- selfie is blurry, or a provider asking what's missing. Not tied to any
-- booking, unlike the existing "messages" table (per-booking chat), so it
-- can't just reuse that table - there's no booking involved here at all.
--
-- sender_role is denormalized (not looked up via a join every time) so the
-- mobile app can align a bubble left/right without an extra round trip -
-- same reasoning bookings.status is a plain column rather than derived.
CREATE TABLE provider_verification_messages (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_profile_id UUID         NOT NULL REFERENCES provider_profiles (id),
    sender_id           UUID         NOT NULL REFERENCES users (id),
    sender_role         VARCHAR(20)  NOT NULL,
    body                TEXT         NOT NULL,
    created_at          TIMESTAMP    NOT NULL
);

CREATE INDEX idx_provider_verification_messages_provider_profile_id ON provider_verification_messages (provider_profile_id);
