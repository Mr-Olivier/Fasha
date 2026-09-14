-- The Cancel Confirmation screen (customer side) offers an optional "why"
-- when backing out of a booking - previously the cancel endpoint took no
-- body at all, so there was nowhere to store it. Nullable: a customer can
-- still cancel without giving a reason.
ALTER TABLE bookings ADD COLUMN cancellation_reason TEXT;
