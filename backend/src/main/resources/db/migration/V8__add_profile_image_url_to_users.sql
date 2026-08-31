-- Lets a user attach an avatar image to their account (see UserService's
-- avatar upload endpoint). Nullable because most existing users won't have
-- uploaded one - the app falls back to showing their initial instead.
ALTER TABLE users ADD COLUMN profile_image_url VARCHAR(500);
