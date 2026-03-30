DROP INDEX IF EXISTS idx_resources_search;
ALTER TABLE resources DROP COLUMN IF EXISTS search_vector;
ALTER TABLE resources ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('spanish', coalesce(description, '')), 'B')
    ) STORED;
CREATE INDEX idx_resources_search ON resources USING GIN (search_vector);

DROP INDEX IF EXISTS idx_universities_search;
ALTER TABLE universities DROP COLUMN IF EXISTS search_vector;
ALTER TABLE universities ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
        to_tsvector('simple', coalesce(name, ''))
    ) STORED;
CREATE INDEX idx_universities_search ON universities USING GIN (search_vector);

DROP FUNCTION IF EXISTS immutable_unaccent(text);
DROP EXTENSION IF EXISTS unaccent;
