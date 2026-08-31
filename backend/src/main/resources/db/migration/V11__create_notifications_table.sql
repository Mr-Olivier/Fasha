-- One row per in-app notification (booking status changes, provider
-- approval decisions, ...). booking_id is nullable because not every
-- notification is about a booking (e.g. a provider approval decision).
CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users (id),
    title       VARCHAR(200) NOT NULL,
    body        VARCHAR(500) NOT NULL,
    booking_id  UUID REFERENCES bookings (id),
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Powers "my notifications, newest first" (GET /api/notifications) - always
-- filtered to the caller's own user_id, so that's the natural index shape.
CREATE INDEX idx_notifications_user_id_created_at ON notifications (user_id, created_at DESC);
