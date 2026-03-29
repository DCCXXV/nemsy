CREATE TABLE universities (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    domain TEXT NOT NULL UNIQUE,
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('simple', coalesce(name, ''))
    ) STORED
);

CREATE INDEX idx_universities_search ON universities USING GIN (search_vector);
CREATE INDEX idx_universities_domain ON universities (domain);

ALTER TABLE studies ADD COLUMN university_id INTEGER REFERENCES universities(id);
ALTER TABLE users ADD COLUMN university_id INTEGER REFERENCES universities(id);
