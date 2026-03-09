ALTER TABLE users
    DROP COLUMN full_name,
    DROP COLUMN pfp,
    ADD COLUMN username TEXT UNIQUE;

UPDATE users SET username = split_part(email, '@', 1) WHERE username IS NULL;

ALTER TABLE users ALTER COLUMN username SET NOT NULL;
