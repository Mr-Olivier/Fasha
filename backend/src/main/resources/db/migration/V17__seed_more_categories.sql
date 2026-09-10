-- Expands V5's 8 categories to a more realistic set for a Rwandan services
-- marketplace, so Home's category rail actually looks like a full app
-- instead of 8 sparse tiles. Separate migration from V5 for the same reason
-- V15 is separate from V4: this is a data change, not a schema change.
--
-- These names are matched by the Flutter app's CategoryStyle map (see
-- mobile/lib/features/services/presentation/category_style.dart) to pick an
-- icon and accent colour for each category's home-screen tile - keep that
-- map in sync if a name here is ever renamed.

INSERT INTO categories (name, description) VALUES
    ('Carpenter', 'Furniture making, repair, and custom woodwork'),
    ('Hair & Beauty', 'Hairdressing, braiding, and beauty services'),
    ('Photographer', 'Event and portrait photography'),
    ('Event Planner', 'Weddings, parties, and event coordination'),
    ('Mover', 'Home and office moving, delivery, and logistics'),
    ('Gardener', 'Landscaping, lawn care, and garden maintenance'),
    ('Mason', 'Construction, tiling, and masonry work'),
    ('Laundry', 'Washing, ironing, and dry cleaning'),
    ('Caterer', 'Event catering and food services'),
    ('Security Guard', 'Residential and event security services');
