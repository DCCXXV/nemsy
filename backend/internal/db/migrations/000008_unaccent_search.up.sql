CREATE EXTENSION IF NOT EXISTS unaccent;

-- Immutable wrapper needed for GENERATED columns
CREATE OR REPLACE FUNCTION immutable_unaccent(text)
RETURNS text AS $$
    SELECT public.unaccent('public.unaccent', $1)
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;

-- Rebuild resources search_vector with unaccent
DROP INDEX IF EXISTS idx_resources_search;
ALTER TABLE resources DROP COLUMN search_vector;
ALTER TABLE resources ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
        setweight(to_tsvector('spanish', immutable_unaccent(coalesce(title, ''))), 'A') ||
        setweight(to_tsvector('spanish', immutable_unaccent(coalesce(description, ''))), 'B')
    ) STORED;
CREATE INDEX idx_resources_search ON resources USING GIN (search_vector);

-- Rebuild universities search_vector with unaccent
DROP INDEX IF EXISTS idx_universities_search;
ALTER TABLE universities DROP COLUMN search_vector;
ALTER TABLE universities ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
        to_tsvector('simple', immutable_unaccent(coalesce(name, '')))
    ) STORED;
CREATE INDEX idx_universities_search ON universities USING GIN (search_vector);
