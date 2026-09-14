-- The Booking Tracker screen (customer side) shows a real timeline -
-- "Request sent Tue 09:12 / Provider accepted Tue 09:31 / Job started Wed
-- 08:05" - with a timestamp per stage. bookings.updated_at can't do this:
-- it's overwritten on every transition, so by the time a job is IN_PROGRESS
-- the original "accepted at" moment is already gone.
--
-- A history table (one row per transition) rather than adding six more
-- nullable timestamp columns to bookings (accepted_at, started_at, ...) -
-- cheaper to extend if a future status gets added, and it doubles as a
-- general-purpose audit trail for a booking, not just tracker-screen fuel.
--
-- No foreign key ON DELETE behaviour needed beyond the default: bookings
-- are never hard-deleted (same reasoning as users - see
-- V3__create_provider_profiles_table.sql's comment).
CREATE TABLE booking_status_history (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID NOT NULL REFERENCES bookings (id),
    status      VARCHAR(20) NOT NULL,
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Booking Tracker reads this list once per booking, ordered oldest-first.
CREATE INDEX idx_booking_status_history_booking_id ON booking_status_history (booking_id);

-- Backfill one REQUESTED row for every booking that already exists, so the
-- tracker has at least a starting point for bookings created before this
-- migration ran - using each booking's own created_at as the timestamp
-- since that's genuinely when it was requested.
INSERT INTO booking_status_history (booking_id, status, changed_at)
SELECT id, 'REQUESTED', created_at FROM bookings;
