-- One row per (installed app on one device) that's ever registered for
-- push notifications - see PushNotificationService. `token` alone is
-- UNIQUE (not per-user): if the same device's token later shows up under a
-- different logged-in user (someone logs out and a different person logs
-- in on the same phone), re-registering should move the token to the new
-- owner, not create a stale second row still pointing at the old user.
--
-- No FK-cascade delete needed beyond the default: users are never
-- hard-deleted in this app (same reasoning as every other table
-- referencing users.id - see V3__create_provider_profiles_table.sql).
CREATE TABLE device_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users (id),
    token       TEXT NOT NULL,
    platform    VARCHAR(20) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_device_tokens_token UNIQUE (token),
    CONSTRAINT chk_device_tokens_platform CHECK (platform IN ('ANDROID', 'WEB'))
);

-- Powers PushNotificationService.sendToUser() - every device to push to
-- for one recipient.
CREATE INDEX idx_device_tokens_user_id ON device_tokens (user_id);
