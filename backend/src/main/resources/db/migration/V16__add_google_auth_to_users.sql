-- Google Sign-In support. Every existing account keeps auth_provider =
-- 'LOCAL' (the column default) and its password untouched - this migration
-- only adds room for a NEW kind of account that authenticates via Google
-- instead of a password.
--
-- password_hash can no longer be NOT NULL at the column level, since a
-- Google-only account never has a password to store - the CHECK constraint
-- below is what actually enforces "every LOCAL account still has a
-- password", now that the column itself can't.
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

ALTER TABLE users ADD COLUMN auth_provider VARCHAR(20) NOT NULL DEFAULT 'LOCAL';
ALTER TABLE users ADD COLUMN google_sub VARCHAR(255);

ALTER TABLE users ADD CONSTRAINT chk_users_auth_provider CHECK (auth_provider IN ('LOCAL', 'GOOGLE'));
ALTER TABLE users ADD CONSTRAINT chk_users_local_has_password CHECK (auth_provider <> 'LOCAL' OR password_hash IS NOT NULL);
ALTER TABLE users ADD CONSTRAINT uq_users_google_sub UNIQUE (google_sub);
