-- One provider profile per provider user. We don't declare a foreign-key
-- ON DELETE behaviour beyond the default (RESTRICT) since users are never
-- hard-deleted in this app (see README.md's User.status: ACTIVE/SUSPENDED).

CREATE TABLE provider_profiles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL,
    business_name       VARCHAR(150) NOT NULL,
    description         TEXT,
    location            VARCHAR(150),
    profile_image_url   VARCHAR(500),
    verification_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_provider_profiles_user_id UNIQUE (user_id),
    CONSTRAINT fk_provider_profiles_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_provider_profiles_verification_status
        CHECK (verification_status IN ('PENDING', 'APPROVED', 'REJECTED'))
);
