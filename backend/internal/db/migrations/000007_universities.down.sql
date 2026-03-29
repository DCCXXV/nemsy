ALTER TABLE users DROP COLUMN IF EXISTS university_id;
ALTER TABLE studies DROP COLUMN IF EXISTS university_id;
DROP INDEX IF EXISTS idx_universities_domain;
DROP INDEX IF EXISTS idx_universities_search;
DROP TABLE IF EXISTS universities;
