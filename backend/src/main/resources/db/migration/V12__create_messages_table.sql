-- One in-app chat message between a booking's customer and provider. See
-- MessageService for who's allowed to read/send (only the two parties on
-- the booking, and only once BookingStatus.allowsContact() is true).
CREATE TABLE messages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID NOT NULL REFERENCES bookings (id),
    sender_id   UUID NOT NULL REFERENCES users (id),
    body        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- The chat screen always lists one booking's whole conversation, oldest
-- first - see MessageRepository.findByBookingIdOrderByCreatedAtAsc.
CREATE INDEX idx_messages_booking_id ON messages (booking_id);
