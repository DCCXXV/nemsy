ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'user';

CREATE TABLE reports (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    resource_id INT NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    reporter_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(resource_id, reporter_id)
);
