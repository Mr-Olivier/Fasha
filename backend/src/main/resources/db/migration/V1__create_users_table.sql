-- Flyway migration V1: the users table.
--
-- Flyway runs this exactly once, in order, and records that it ran in its
-- own "flyway_schema_history" table. Never edit an already-applied
-- migration - add a new V2__..., V3__... file instead, the same way you'd
-- never rewrite git history that's already been pushed.

CREATE TABLE users (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name           VARCHAR(120) NOT NULL,
    email          VARCHAR(190) NOT NULL,
    phone          VARCHAR(30),
    password_hash  VARCHAR(100) NOT NULL,
    role           VARCHAR(20)  NOT NULL,
    status         VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT chk_users_role CHECK (role IN ('CUSTOMER', 'PROVIDER', 'ADMIN')),
    CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'SUSPENDED'))
);

-- No separate index on email: the UNIQUE constraint above already creates
-- one, and every login/registration query is an equality lookup on email.
