-- Demo data so a fresh database isn't empty: providers (one per category,
-- covering all three verification_status values so the admin approval
-- screens have something to show), their services, a customer or two, an
-- admin login, and bookings/reviews spanning the whole status state machine
-- (see BookingStatus.java). Separate from V5's category seed for the same
-- reason V5 is separate from V4: schema vs. data.
--
-- Every user below shares the password "Demo1234!" - the value below is
-- its real BCrypt hash (generated with the same BCryptPasswordEncoder
-- SecurityConfig wires up), not a placeholder, so these accounts can
-- actually log in.
--
-- IDs are hardcoded UUID literals (instead of gen_random_uuid()) so later
-- INSERTs in this same file can reference them directly as foreign keys.

-- ── Users ────────────────────────────────────────────────────────────────
INSERT INTO users (id, name, email, phone, password_hash, role, status) VALUES
    ('a1111111-1111-1111-1111-111111111101', 'Jean Baptiste Uwimana', 'jean.uwimana@example.com', '+250788111101', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111111102', 'Alice Mukamana',       'alice.mukamana@example.com', '+250788111102', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111111103', 'Eric Nshimiyimana',    'eric.nshimiyimana@example.com', '+250788111103', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111111104', 'Claudine Uwase',       'claudine.uwase@example.com', '+250788111104', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111111105', 'Patrick Habimana',     'patrick.habimana@example.com', '+250788111105', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111111106', 'Diane Ingabire',       'diane.ingabire@example.com', '+250788111106', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111111107', 'Moses Karangwa',       'moses.karangwa@example.com', '+250788111107', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'PROVIDER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111111201', 'Samuel Niyonzima',     'sam.niyonzima@example.com', '+250788111201', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'CUSTOMER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111111202', 'Grace Umutoni',        'grace.umutoni@example.com', '+250788111202', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'CUSTOMER', 'ACTIVE'),
    ('a1111111-1111-1111-1111-111111111301', 'Fasha Admin',          'demo.admin@fasha.rw', '+250788111301', '$2a$10$VIk1lX8sk.8bncLtdp0GYes6qAEilEag9lCrQS8p0q8gWTM0ra0We', 'ADMIN', 'ACTIVE');

-- ── Provider profiles ───────────────────────────────────────────────────
-- Five APPROVED (so they show up in public browse/search), one PENDING and
-- one REJECTED (so the admin approval screens have real cases to act on).
INSERT INTO provider_profiles (id, user_id, business_name, description, location, verification_status) VALUES
    ('b2222222-2222-2222-2222-222222222101', 'a1111111-1111-1111-1111-111111111101', 'Uwimana Electrical Services', 'Licensed electrician handling home and office wiring, repairs, and installations across Kigali.', 'Kicukiro, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222222102', 'a1111111-1111-1111-1111-111111111102', 'Mukamana Plumbing Co.',       'Reliable plumbing repairs and installations, from leaky pipes to full bathroom fit-outs.', 'Gasabo, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222222103', 'a1111111-1111-1111-1111-111111111103', 'Nshimiyimana Auto Repair',    'General car servicing, brake repairs, and diagnostics for all vehicle makes.', 'Nyarugenge, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222222104', 'a1111111-1111-1111-1111-111111111104', 'Sparkle Home Cleaning',       'Home and office cleaning, from a standard tidy-up to a full deep clean.', 'Kicukiro, Kigali', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222222105', 'a1111111-1111-1111-1111-111111111105', 'Habimana Painting & Decor',   'Interior and exterior painting for homes and businesses.', 'Musanze', 'APPROVED'),
    ('b2222222-2222-2222-2222-222222222106', 'a1111111-1111-1111-1111-111111111106', 'Ingabire Tutoring',           'One-on-one and small-group academic tutoring, primary through high school.', 'Huye', 'PENDING'),
    ('b2222222-2222-2222-2222-222222222107', 'a1111111-1111-1111-1111-111111111107', 'Karangwa Tailoring',          'Custom tailoring and clothing repair.', 'Nyarugenge, Kigali', 'REJECTED');

-- ── Services ────────────────────────────────────────────────────────────
-- category_id is looked up by name since V5 seeded categories with
-- gen_random_uuid() rather than fixed IDs.
INSERT INTO services (id, provider_profile_id, category_id, name, description, price) VALUES
    ('c3333333-3333-3333-3333-333333333101', 'b2222222-2222-2222-2222-222222222101', (SELECT id FROM categories WHERE name = 'Electrician'), 'Home Rewiring', 'Full or partial rewiring of a home, including safety inspection.', 45000),
    ('c3333333-3333-3333-3333-333333333102', 'b2222222-2222-2222-2222-222222222101', (SELECT id FROM categories WHERE name = 'Electrician'), 'Circuit Breaker Installation', 'Supply and installation of a new circuit breaker panel.', 25000),
    ('c3333333-3333-3333-3333-333333333201', 'b2222222-2222-2222-2222-222222222102', (SELECT id FROM categories WHERE name = 'Plumber'),     'Pipe Leak Repair', 'Diagnosis and repair of leaking pipes.', 20000),
    ('c3333333-3333-3333-3333-333333333202', 'b2222222-2222-2222-2222-222222222102', (SELECT id FROM categories WHERE name = 'Plumber'),     'Bathroom Plumbing Installation', 'Full plumbing installation for a new or renovated bathroom.', 60000),
    ('c3333333-3333-3333-3333-333333333301', 'b2222222-2222-2222-2222-222222222103', (SELECT id FROM categories WHERE name = 'Mechanic'),    'General Car Service', 'Oil change, filter replacement, and full vehicle checkup.', 35000),
    ('c3333333-3333-3333-3333-333333333302', 'b2222222-2222-2222-2222-222222222103', (SELECT id FROM categories WHERE name = 'Mechanic'),    'Brake Repair', 'Brake pad and disc inspection and replacement.', 28000),
    ('c3333333-3333-3333-3333-333333333401', 'b2222222-2222-2222-2222-222222222104', (SELECT id FROM categories WHERE name = 'Cleaner'),     'Standard Home Cleaning', 'A full sweep, mop, and dust of a standard home.', 15000),
    ('c3333333-3333-3333-3333-333333333402', 'b2222222-2222-2222-2222-222222222104', (SELECT id FROM categories WHERE name = 'Cleaner'),     'Deep Cleaning', 'Deep clean including appliances, baseboards, and windows.', 30000),
    ('c3333333-3333-3333-3333-333333333501', 'b2222222-2222-2222-2222-222222222105', (SELECT id FROM categories WHERE name = 'Painter'),     'Interior Wall Painting', 'Interior wall painting, materials included.', 50000),
    ('c3333333-3333-3333-3333-333333333502', 'b2222222-2222-2222-2222-222222222105', (SELECT id FROM categories WHERE name = 'Painter'),     'Exterior House Painting', 'Full exterior house painting.', 90000),
    ('c3333333-3333-3333-3333-333333333601', 'b2222222-2222-2222-2222-222222222106', (SELECT id FROM categories WHERE name = 'Tutor'),       'Math Tutoring (High School)', 'One-on-one high school math tutoring.', 10000),
    ('c3333333-3333-3333-3333-333333333701', 'b2222222-2222-2222-2222-222222222107', (SELECT id FROM categories WHERE name = 'Tailor'),      'Custom Suit Tailoring', 'Made-to-measure suit tailoring.', 40000);

-- ── Bookings ────────────────────────────────────────────────────────────
-- Only against APPROVED providers - a PENDING/REJECTED provider never
-- shows up in public browse, so a real customer couldn't book them either.
-- Covers every status in the state machine at least once.
INSERT INTO bookings (id, customer_id, provider_profile_id, service_listing_id, note, requested_date, status) VALUES
    ('d4444444-4444-4444-4444-444444444101', 'a1111111-1111-1111-1111-111111111201', 'b2222222-2222-2222-2222-222222222101', 'c3333333-3333-3333-3333-333333333101', 'Kitchen outlet keeps tripping the breaker.', CURRENT_DATE + 3, 'REQUESTED'),
    ('d4444444-4444-4444-4444-444444444102', 'a1111111-1111-1111-1111-111111111201', 'b2222222-2222-2222-2222-222222222102', 'c3333333-3333-3333-3333-333333333201', 'Leak under the kitchen sink.', CURRENT_DATE + 2, 'ACCEPTED'),
    ('d4444444-4444-4444-4444-444444444103', 'a1111111-1111-1111-1111-111111111202', 'b2222222-2222-2222-2222-222222222103', 'c3333333-3333-3333-3333-333333333301', 'Due for a routine service.', CURRENT_DATE - 1, 'IN_PROGRESS'),
    ('d4444444-4444-4444-4444-444444444104', 'a1111111-1111-1111-1111-111111111202', 'b2222222-2222-2222-2222-222222222104', 'c3333333-3333-3333-3333-333333333401', 'Two-bedroom apartment, one-time clean.', CURRENT_DATE - 5, 'COMPLETED'),
    ('d4444444-4444-4444-4444-444444444105', 'a1111111-1111-1111-1111-111111111201', 'b2222222-2222-2222-2222-222222222105', 'c3333333-3333-3333-3333-333333333501', 'Living room and two bedrooms.', CURRENT_DATE - 10, 'REVIEWED'),
    ('d4444444-4444-4444-4444-444444444106', 'a1111111-1111-1111-1111-111111111202', 'b2222222-2222-2222-2222-222222222101', 'c3333333-3333-3333-3333-333333333102', 'Changed my mind, going with someone else.', CURRENT_DATE - 2, 'CANCELLED'),
    ('d4444444-4444-4444-4444-444444444107', 'a1111111-1111-1111-1111-111111111201', 'b2222222-2222-2222-2222-222222222104', 'c3333333-3333-3333-3333-333333333402', 'Same-day request.', CURRENT_DATE - 4, 'REJECTED'),
    ('d4444444-4444-4444-4444-444444444108', 'a1111111-1111-1111-1111-111111111202', 'b2222222-2222-2222-2222-222222222102', 'c3333333-3333-3333-3333-333333333202', 'New bathroom installation.', CURRENT_DATE - 15, 'REVIEWED');

-- ── Reviews ─────────────────────────────────────────────────────────────
-- One per REVIEWED booking (d...105 and d...108 above); the COMPLETED
-- booking (d...104) is deliberately left unreviewed to demo that flow too.
INSERT INTO reviews (id, booking_id, customer_id, provider_profile_id, rating, comment) VALUES
    ('e5555555-5555-5555-5555-555555555101', 'd4444444-4444-4444-4444-444444444105', 'a1111111-1111-1111-1111-111111111201', 'b2222222-2222-2222-2222-222222222105', 5, 'Excellent work, very neat finish and finished on time.'),
    ('e5555555-5555-5555-5555-555555555102', 'd4444444-4444-4444-4444-444444444108', 'a1111111-1111-1111-1111-111111111202', 'b2222222-2222-2222-2222-222222222102', 4, 'Good job, though arrived a bit later than agreed.');
