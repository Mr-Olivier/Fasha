-- Categories are managed by an admin in the real product (Feature 9, not
-- built yet), so for now this table is seeded once (see V5) and only ever
-- read, never written to, by the application itself.

CREATE TABLE categories (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    description VARCHAR(500),

    CONSTRAINT uq_categories_name UNIQUE (name)
);
