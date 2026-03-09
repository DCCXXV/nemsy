ALTER TABLE users
    DROP COLUMN username,
    ADD COLUMN full_name TEXT,
    ADD COLUMN pfp TEXT;
