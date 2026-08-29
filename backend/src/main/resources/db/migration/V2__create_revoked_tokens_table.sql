-- Revoked JWTs, for POST /api/auth/logout.
--
-- We don't store the whole token - just its unique id ("jti" claim) and
-- when it would have expired anyway. JwtAuthenticationFilter checks this
-- table on every request; once a token's own expiry has passed, this row
-- becomes dead weight (there's nothing left to protect against), so a
-- future cleanup job could safely delete rows where expires_at < now().
-- Not built yet - out of scope for the MVP, noted for later.

CREATE TABLE revoked_tokens (
    jti        UUID PRIMARY KEY,
    expires_at TIMESTAMPTZ NOT NULL
);
