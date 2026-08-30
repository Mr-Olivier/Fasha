-- Real seed data (README.md section 18: the app must not look empty).
-- Separate migration from V4 on purpose - schema changes and data changes
-- are different kinds of change, and keeping them apart makes it obvious
-- which is which when reading the migration history later.

INSERT INTO categories (name, description) VALUES
    ('Electrician', 'Electrical wiring, repairs, and installations'),
    ('Plumber', 'Pipe repairs, installations, and water systems'),
    ('Mechanic', 'Vehicle repair and maintenance'),
    ('Cleaner', 'Home and office cleaning services'),
    ('Painter', 'Interior and exterior painting'),
    ('Tutor', 'Academic tutoring and lessons'),
    ('Tailor', 'Clothing repair and custom tailoring'),
    ('Phone & Computer Repair', 'Device diagnostics and repair');
