-- Snapshots the service's price at the moment a booking is created,
-- instead of always looking it up live via service_listing_id. Without
-- this, a provider editing a service's price later would silently rewrite
-- the price shown on every past booking too - including ones already
-- COMPLETED, which is exactly the number the "completed jobs & earnings"
-- screen sums up. A snapshot keeps booking history honest.
ALTER TABLE bookings ADD COLUMN price NUMERIC(12, 2);

-- Backfill every existing booking from its linked service's CURRENT price -
-- the best information available, since no booking-level price existed
-- before this migration. Safe because there's no service-delete endpoint,
-- so no booking can point at a service_listing_id that no longer exists.
UPDATE bookings b
SET price = s.price
FROM services s
WHERE b.service_listing_id = s.id
  AND b.price IS NULL;

ALTER TABLE bookings ALTER COLUMN price SET NOT NULL;

-- A short note the provider leaves when finishing the job (e.g. "replaced
-- the tripped breaker") - shown to the customer. Nullable: most of a
-- booking's life it has no work note yet, and a provider can still mark a
-- job complete without writing one.
ALTER TABLE bookings ADD COLUMN work_note TEXT;
