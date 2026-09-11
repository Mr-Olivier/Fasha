-- Lets an admin hide a category from customers (e.g. one with no real
-- provider coverage yet) without deleting it outright - deleting is already
-- blocked while any service still references the category (see
-- CategoryInUseException), so hiding is the only way to retire one early.
--
-- Defaults to TRUE so every existing category stays visible exactly as
-- before this migration ran.
ALTER TABLE categories ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;
