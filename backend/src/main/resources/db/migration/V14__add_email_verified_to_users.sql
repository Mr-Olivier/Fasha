-- DEFAULT TRUE so every existing row (dev/demo accounts already in the
-- database, or anyone an admin creates directly) stays usable immediately.
-- AuthService.register() explicitly sets this to false for every NEW
-- self-registered account instead - see its own doc comment.
ALTER TABLE users ADD COLUMN email_verified BOOLEAN NOT NULL DEFAULT TRUE;
