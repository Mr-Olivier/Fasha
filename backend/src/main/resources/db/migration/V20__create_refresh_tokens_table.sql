-- Refresh-token rotation: access tokens (see app.jwt.expiration-ms) are now
-- short-lived, so a stolen one is only useful for a narrow window. This
-- table backs the longer-lived credential that gets a user a NEW access
-- token without logging in again.
--
-- We store only a SHA-256 hash of the actual refresh token, never the
-- token itself - same reasoning as password_hash on users: this table
-- being read (a backup, a compromised replica) shouldn't hand out usable
-- credentials.
--
-- Rotation means every refresh token is single-use: using it to get a new
-- access token also issues a brand new refresh token and marks this one
-- revoked, chaining to its replacement via replaced_by_token_id. If a
-- revoked token is ever presented again, that's a signal it was stolen and
-- used out of order - see RefreshTokenService for how that's handled.
CREATE TABLE refresh_tokens (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash            VARCHAR(64) NOT NULL UNIQUE,
    expires_at            TIMESTAMPTZ NOT NULL,
    revoked               BOOLEAN NOT NULL DEFAULT FALSE,
    replaced_by_token_id  UUID REFERENCES refresh_tokens(id),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
