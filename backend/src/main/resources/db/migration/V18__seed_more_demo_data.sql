-- Extends V15's demo data now that V17 added 10 more categories - without
-- this, every one of those new categories would show an empty provider
-- list the moment a customer tapped it, which looks broken rather than
-- "not built yet". Adds a provider for each new category, a second
-- Electrician (so at least one category demonstrates multiple providers to
-- choose between), two more customers, and bookings/reviews spanning the
-- new providers.
--
-- ID scheme: continues V15's UUID literals but with an 8-three prefix +
-- 4-digit suffix (e.g. ...111111110108) instead of V15's 9-three prefix +
-- 3-digit suffix (e.g. ...111111111101) - deliberately different lengths
-- so a new literal here can never collide with an existing V15 one.
--
-- Every new user shares the same demo password as V15 ("Demo1234!").

-- ── Users ────────────────────────────────────────────────────────────────
INSERT INTO users (id, name, email, phone, password_hash, role, status) VALUES
    ('a1111111-1111-1111-1111-111111110108', 'Bosco Ntawukuriryayo', 'bosco.ntawukuriryayo@example.com', '+250788112108', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110109', 'Emmanuel Rugamba',     'emmanuel.rugamba@example.com', '+250788112109', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110110', 'Bella Uwimana',        'bella.uwimana@example.com', '+250788112110', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110111', 'Yves Munyaneza',       'yves.munyaneza@example.com', '+250788112111', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110112', 'Solange Mutesi',       'solange.mutesi@example.com', '+250788112112', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110113', 'Innocent Byiringiro',  'innocent.byiringiro@example.com', '+250788112113', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110114', 'Fiacre Hakizimana',    'fiacre.hakizimana@example.com', '+250788112114', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110115', 'Vestine Nyirahabimana','vestine.nyirahabimana@example.com', '+250788112115', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110116', 'Aline Umulisa',        'aline.umulisa@example.com', '+250788112116', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110117', 'Christian Sibomana',   'christian.sibomana@example.com', '+250788112117', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110118', 'Olivier Ndagijimana',  'olivier.ndagijimana@example.com', '+250788112118', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110119', 'Theogene Habiyambere', 'theogene.habiyambere@example.com', '+250788112119', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110203', 'Emmanuel Bizimana',    'emmanuel.bizimana@example.com', '+250788112203', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'CUSTOMER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111110204', 'Olive Uwamahoro',      'olive.uwamahoro@example.com', '+250788112204', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'CUSTOMER', 'ACTIVE');

-- ── Provider profiles ───────────────────────────────────────────────────
-- One per new category (V17), plus a second Electrician so that category
-- demonstrates a multi-provider list. 11 APPROVED, 1 PENDING (Security
-- Guard) so the admin approval queue still has a live case to act on.
INSERT INTO provider_profiles (id, user_id, business_name, description, location, verification_status) VALUES
    ('b2222222-2222-2222-2222-222222220108', 'a1111111-1111-1111-1111-111111110108', 'TechFix Kigali',              'Laptop and phone diagnostics, screen and battery replacement, and data recovery.', 'Nyarugenge, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222220109', 'a1111111-1111-1111-1111-111111110109', 'Rugamba Carpentry Works',     'Custom furniture, built-in cabinets, and furniture repair.', 'Gasabo, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222220110', 'a1111111-1111-1111-1111-111111110110', 'Bella Hair & Beauty Salon',   'Hairdressing, braiding, and bridal beauty services.', 'Kicukiro, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222220111', 'a1111111-1111-1111-1111-111111110111', 'Kigali Moments Photography',  'Event, portrait, and graduation photography.', 'Nyarugenge, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222220112', 'a1111111-1111-1111-1111-111111110112', 'Perfect Day Events',          'Full event planning, decoration, and coordination for weddings and parties.', 'Gasabo, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222220113', 'a1111111-1111-1111-1111-111111110113', 'Swift Movers Rwanda',         'Home and office moving, furniture delivery, and logistics.', 'Kicukiro, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222220114', 'a1111111-1111-1111-1111-111111110114', 'Green Thumb Landscaping',     'Garden clearing, lawn care, and landscaping.', 'Musanze', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222220115', 'a1111111-1111-1111-1111-111111110115', 'Solid Build Masonry',         'Tiling, brickwork, and general construction.', 'Huye', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222220116', 'a1111111-1111-1111-1111-111111110116', 'CleanPress Laundry Services', 'Laundry pickup, washing, ironing, and dry cleaning.', 'Kicukiro, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222220117', 'a1111111-1111-1111-1111-111111110117', 'Taste of Rwanda Catering',    'Wedding and corporate event catering.', 'Gasabo, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222220118', 'a1111111-1111-1111-1111-111111110118', 'SafeGuard Security Services', 'Residential and event security staffing.', 'Nyarugenge, Kigali', 'PENDING'),
    ('b2222222-2222-2222-2222-222222220119', 'a1111111-1111-1111-1111-111111110119', 'Bright Spark Electricals',    'Outdoor lighting, rewiring, and electrical safety inspections.', 'Gasabo, Kigali', 'APPROVED');

-- ── Services ────────────────────────────────────────────────────────────
INSERT INTO services (id, provider_profile_id, category_id, name, description, price) VALUES
    ('c3333333-3333-3333-3333-333333330801', 'b2222222-2222-2222-2222-222222220108', (SELECT id FROM categories WHERE name = 'Phone & Computer Repair'), 'Laptop Screen Replacement', 'Diagnosis and replacement of a cracked or faulty laptop screen.', 35000),
    ('c3333333-3333-3333-3333-333333330802', 'b2222222-2222-2222-2222-222222220108', (SELECT id FROM categories WHERE name = 'Phone & Computer Repair'), 'Phone Battery Replacement', 'Battery diagnostics and replacement for most phone models.', 12000),
    ('c3333333-3333-3333-3333-333333330901', 'b2222222-2222-2222-2222-222222220109', (SELECT id FROM categories WHERE name = 'Carpenter'),                'Custom Furniture Making', 'Made-to-order furniture built to your space and design.', 80000),
    ('c3333333-3333-3333-3333-333333330902', 'b2222222-2222-2222-2222-222222220109', (SELECT id FROM categories WHERE name = 'Carpenter'),                'Furniture Repair', 'Repair of chairs, tables, cabinets, and other wooden furniture.', 15000),
    ('c3333333-3333-3333-3333-333333331001', 'b2222222-2222-2222-2222-222222220110', (SELECT id FROM categories WHERE name = 'Hair & Beauty'),            'Bridal Hair & Makeup', 'Full bridal hairstyling and makeup for the big day.', 45000),
    ('c3333333-3333-3333-3333-333333331002', 'b2222222-2222-2222-2222-222222220110', (SELECT id FROM categories WHERE name = 'Hair & Beauty'),            'Braiding & Styling', 'Braiding and everyday hairstyling.', 15000),
    ('c3333333-3333-3333-3333-333333331101', 'b2222222-2222-2222-2222-222222220111', (SELECT id FROM categories WHERE name = 'Photographer'),             'Event Photography (Half Day)', 'Half-day event coverage with edited digital photos.', 60000),
    ('c3333333-3333-3333-3333-333333331102', 'b2222222-2222-2222-2222-222222220111', (SELECT id FROM categories WHERE name = 'Photographer'),             'Portrait Photoshoot', 'Individual or family portrait session with edited photos.', 25000),
    ('c3333333-3333-3333-3333-333333331201', 'b2222222-2222-2222-2222-222222220112', (SELECT id FROM categories WHERE name = 'Event Planner'),            'Full Event Planning & Coordination', 'End-to-end planning and on-the-day coordination.', 150000),
    ('c3333333-3333-3333-3333-333333331202', 'b2222222-2222-2222-2222-222222220112', (SELECT id FROM categories WHERE name = 'Event Planner'),            'Decoration & Setup', 'Venue decoration and setup for parties and weddings.', 70000),
    ('c3333333-3333-3333-3333-333333331301', 'b2222222-2222-2222-2222-222222220113', (SELECT id FROM categories WHERE name = 'Mover'),                    'Apartment Moving (2-3 rooms)', 'Full-service move for a 2-3 room apartment, including loading.', 50000),
    ('c3333333-3333-3333-3333-333333331302', 'b2222222-2222-2222-2222-222222220113', (SELECT id FROM categories WHERE name = 'Mover'),                    'Furniture Delivery', 'Delivery of individual furniture items across Kigali.', 20000),
    ('c3333333-3333-3333-3333-333333331401', 'b2222222-2222-2222-2222-222222220114', (SELECT id FROM categories WHERE name = 'Gardener'),                 'Garden Clearing & Maintenance', 'Overgrowth clearing and general garden upkeep.', 25000),
    ('c3333333-3333-3333-3333-333333331402', 'b2222222-2222-2222-2222-222222220114', (SELECT id FROM categories WHERE name = 'Gardener'),                 'Lawn Mowing', 'Regular lawn mowing and edging.', 10000),
    ('c3333333-3333-3333-3333-333333331501', 'b2222222-2222-2222-2222-222222220115', (SELECT id FROM categories WHERE name = 'Mason'),                    'Floor & Wall Tiling', 'Tiling for kitchens, bathrooms, and floors.', 55000),
    ('c3333333-3333-3333-3333-333333331502', 'b2222222-2222-2222-2222-222222220115', (SELECT id FROM categories WHERE name = 'Mason'),                    'Brick Wall Construction', 'Boundary and structural brick wall construction.', 90000),
    ('c3333333-3333-3333-3333-333333331601', 'b2222222-2222-2222-2222-222222220116', (SELECT id FROM categories WHERE name = 'Laundry'),                  'Weekly Laundry Pickup', 'Scheduled weekly laundry pickup, wash, and delivery.', 8000),
    ('c3333333-3333-3333-3333-333333331602', 'b2222222-2222-2222-2222-222222220116', (SELECT id FROM categories WHERE name = 'Laundry'),                  'Dry Cleaning (per item)', 'Professional dry cleaning, priced per garment.', 3000),
    ('c3333333-3333-3333-3333-333333331701', 'b2222222-2222-2222-2222-222222220117', (SELECT id FROM categories WHERE name = 'Caterer'),                  'Wedding Catering (per 100 guests)', 'Full wedding catering, including service staff.', 500000),
    ('c3333333-3333-3333-3333-333333331702', 'b2222222-2222-2222-2222-222222220117', (SELECT id FROM categories WHERE name = 'Caterer'),                  'Corporate Event Catering', 'Catering for office and corporate events.', 200000),
    ('c3333333-3333-3333-3333-333333331801', 'b2222222-2222-2222-2222-222222220118', (SELECT id FROM categories WHERE name = 'Security Guard'),           'Event Security Staffing', 'Trained security staff for private and public events.', 30000),
    ('c3333333-3333-3333-3333-333333330103', 'b2222222-2222-2222-2222-222222220119', (SELECT id FROM categories WHERE name = 'Electrician'),              'Outdoor & Garden Lighting Installation', 'Design and installation of outdoor and garden lighting.', 30000),
    ('c3333333-3333-3333-3333-333333330104', 'b2222222-2222-2222-2222-222222220119', (SELECT id FROM categories WHERE name = 'Electrician'),              'Electrical Safety Inspection', 'Full-home electrical safety inspection with a written report.', 15000);

-- ── Bookings ────────────────────────────────────────────────────────────
-- Only against APPROVED providers, same rule as V15 (SafeGuard/118 is
-- PENDING so it's deliberately not booked here).
INSERT INTO bookings (id, customer_id, provider_profile_id, service_listing_id, note, requested_date, status) VALUES
    ('d4444444-4444-4444-4444-444444440109', 'a1111111-1111-1111-1111-111111111201', 'b2222222-2222-2222-2222-222222220108', 'c3333333-3333-3333-3333-333333330801', 'My laptop won''t turn on at all.', CURRENT_DATE + 1, 'REQUESTED'),
    ('d4444444-4444-4444-4444-444444440110', 'a1111111-1111-1111-1111-111111111202', 'b2222222-2222-2222-2222-222222220109', 'c3333333-3333-3333-3333-333333330901', 'Need a custom bookshelf for the living room.', CURRENT_DATE + 4, 'ACCEPTED'),
    ('d4444444-4444-4444-4444-444444440111', 'a1111111-1111-1111-1111-111111110203', 'b2222222-2222-2222-2222-222222220110', 'c3333333-3333-3333-3333-333333331001', 'Bridal hair and makeup needed for Saturday morning.', CURRENT_DATE - 1, 'IN_PROGRESS'),
    ('d4444444-4444-4444-4444-444444440112', 'a1111111-1111-1111-1111-111111110204', 'b2222222-2222-2222-2222-222222220111', 'c3333333-3333-3333-3333-333333331101', 'Graduation ceremony coverage.', CURRENT_DATE - 3, 'REVIEWED'),
    ('d4444444-4444-4444-4444-444444440113', 'a1111111-1111-1111-1111-111111111201', 'b2222222-2222-2222-2222-222222220112', 'c3333333-3333-3333-3333-333333331201', 'Birthday party for 50 guests, need full coordination.', CURRENT_DATE - 8, 'REVIEWED'),
    ('d4444444-4444-4444-4444-444444440114', 'a1111111-1111-1111-1111-111111111202', 'b2222222-2222-2222-2222-222222220113', 'c3333333-3333-3333-3333-333333331301', 'Moving a 2-bedroom apartment across town.', CURRENT_DATE - 12, 'REVIEWED'),
    ('d4444444-4444-4444-4444-444444440115', 'a1111111-1111-1111-1111-111111110203', 'b2222222-2222-2222-2222-222222220114', 'c3333333-3333-3333-3333-333333331401', 'Backyard is very overgrown, needs clearing.', CURRENT_DATE + 5, 'REQUESTED'),
    ('d4444444-4444-4444-4444-444444440116', 'a1111111-1111-1111-1111-111111110204', 'b2222222-2222-2222-2222-222222220115', 'c3333333-3333-3333-3333-333333331501', 'Tiling for a new kitchen floor.', CURRENT_DATE - 2, 'CANCELLED'),
    ('d4444444-4444-4444-4444-444444440117', 'a1111111-1111-1111-1111-111111111201', 'b2222222-2222-2222-2222-222222220116', 'c3333333-3333-3333-3333-333333331601', 'Weekly laundry pickup, starting this week.', CURRENT_DATE + 2, 'ACCEPTED'),
    ('d4444444-4444-4444-4444-444444440118', 'a1111111-1111-1111-1111-111111111202', 'b2222222-2222-2222-2222-222222220117', 'c3333333-3333-3333-3333-333333331701', 'Catering for a 100-guest wedding in December.', CURRENT_DATE - 6, 'REVIEWED'),
    ('d4444444-4444-4444-4444-444444440119', 'a1111111-1111-1111-1111-111111110203', 'b2222222-2222-2222-2222-222222220119', 'c3333333-3333-3333-3333-333333330103', 'Installing new outdoor lighting around the house.', CURRENT_DATE + 3, 'REQUESTED'),
    ('d4444444-4444-4444-4444-444444440120', 'a1111111-1111-1111-1111-111111110204', 'b2222222-2222-2222-2222-222222220109', 'c3333333-3333-3333-3333-333333330902', 'Repairing a broken dining chair.', CURRENT_DATE - 4, 'COMPLETED');

-- ── Reviews ─────────────────────────────────────────────────────────────
-- One per REVIEWED booking above (d...440112, 440113, 440114, 440118). The
-- COMPLETED booking (d...440120) is deliberately left unreviewed, same as
-- V15's pattern.
INSERT INTO reviews (id, booking_id, customer_id, provider_profile_id, rating, comment) VALUES
    ('e5555555-5555-5555-5555-555555550103', 'd4444444-4444-4444-4444-444444440112', 'a1111111-1111-1111-1111-111111110204', 'b2222222-2222-2222-2222-222222220111', 5, 'Beautiful photos, delivered quickly. Highly recommend!'),
    ('e5555555-5555-5555-5555-555555550104', 'd4444444-4444-4444-4444-444444440113', 'a1111111-1111-1111-1111-111111111201', 'b2222222-2222-2222-2222-222222220112', 5, 'Made the whole party stress-free. Everything was on time.'),
    ('e5555555-5555-5555-5555-555555550105', 'd4444444-4444-4444-4444-444444440114', 'a1111111-1111-1111-1111-111111111202', 'b2222222-2222-2222-2222-222222220113', 4, 'Careful with our furniture, just arrived a little late.'),
    ('e5555555-5555-5555-5555-555555550106', 'd4444444-4444-4444-4444-444444440118', 'a1111111-1111-1111-1111-111111111202', 'b2222222-2222-2222-2222-222222220117', 5, 'Food was excellent and guests loved it. Will book again.');
