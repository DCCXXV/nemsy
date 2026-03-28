DROP INDEX IF EXISTS idx_resources_search;
ALTER TABLE resources DROP COLUMN IF EXISTS search_vector;
