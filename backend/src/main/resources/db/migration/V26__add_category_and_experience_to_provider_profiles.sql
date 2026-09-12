-- Two profile fields the "Edit provider profile" screen collects but that
-- provider_profiles had no column for yet: which category the business
-- mainly belongs to, and how many years they've been doing this work.
-- Both nullable/optional - existing providers haven't set either yet, and
-- a provider isn't required to fill them in to keep using the app.
--
-- Plain UUID column for category_id, no foreign-key ManyToOne relation on
-- the entity side - same reasoning as services.category_id (see
-- ServiceListing's doc comment): we only ever need the id itself here.
ALTER TABLE provider_profiles ADD COLUMN category_id UUID;
ALTER TABLE provider_profiles ADD COLUMN years_experience INTEGER;
