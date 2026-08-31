-- Supports POST /api/auth/forgot-password and /reset-password.
--
-- The token itself IS the primary key (like revoked_tokens' jti) - all we
-- ever do is "does this token exist, and is it still valid?" and "insert
-- a new one". used_at is nullable rather than just deleting the row on
-- use, so there's an audit trail of past resets instead of them vanishing.

CREATE TABLE password_reset_tokens (
    token      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_password_reset_tokens_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_password_reset_tokens_user_id ON password_reset_tokens (user_id);
