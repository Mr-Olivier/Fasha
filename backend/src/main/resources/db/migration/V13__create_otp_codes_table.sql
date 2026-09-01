-- Replaces password_reset_tokens with a general-purpose OTP mechanism -
-- the same 6-digit-code idea now also verifies a new account's email at
-- registration (see OtpPurpose), not just password resets, so this table
-- is keyed by (user, purpose) rather than being reset-specific.
DROP TABLE password_reset_tokens;

CREATE TABLE otp_codes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users (id),
    purpose     VARCHAR(30) NOT NULL,
    code        VARCHAR(6) NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    used_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- OtpService always looks a code up by exactly these three columns - see
-- OtpCodeRepository.findTopByUserIdAndPurposeAndCodeOrderByCreatedAtDesc.
CREATE INDEX idx_otp_codes_user_id_purpose ON otp_codes (user_id, purpose);
