-- Lets a provider pause bookings on one of their own services without
-- deleting it (same "hide, don't delete" idea as categories.is_active -
-- see V19__add_is_active_to_categories.sql). A hidden service is excluded
-- from customer-facing browse/search but still shows up in the provider's
-- own "My services" list, greyed out.
--
-- Defaults to TRUE so every existing service stays visible exactly as
-- before this migration ran.
ALTER TABLE services ADD COLUMN is_visible BOOLEAN NOT NULL DEFAULT TRUE;

-- How long the job typically takes - shown to the customer before they
-- book. A plain VARCHAR enum name (not a lookup table) because the set of
-- durations is small and fixed, same reasoning as bookings.status.
--
-- Defaults every existing service to the shortest option since we have no
-- real data to backfill from.
ALTER TABLE services ADD COLUMN duration VARCHAR(20) NOT NULL DEFAULT 'ONE_TO_TWO_HOURS';
