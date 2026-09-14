-- The Request Service form (customer side) collects where the job is and a
-- rough time-of-day window, but bookings had nowhere to put either - only
-- a date, no address, no window. Both nullable: older/API-only bookings
-- created before this migration simply don't have them, and a customer can
-- still leave them blank (the provider coordinates specifics over chat).
--
-- time_window is a plain VARCHAR, not a Postgres enum - validated against
-- MORNING/AFTERNOON/EVENING in CreateBookingRequest instead, same approach
-- V22 already used for services.duration (a fixed set of app-level choices
-- that's cheaper to change in Java than in a DB enum type).
ALTER TABLE bookings ADD COLUMN address VARCHAR(255);
ALTER TABLE bookings ADD COLUMN time_window VARCHAR(20);
