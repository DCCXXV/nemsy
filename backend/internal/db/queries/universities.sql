-- name: GetUniversityByDomain :one
SELECT * FROM universities
WHERE domain = $1 LIMIT 1;

-- name: GetUniversityByDomainSuffix :one
SELECT * FROM universities
WHERE $1 = domain OR $1 LIKE '%.' || domain
LIMIT 1;

-- name: GetUniversity :one
SELECT * FROM universities
WHERE id = $1 LIMIT 1;

-- name: SearchUniversities :many
SELECT id, name, domain
FROM universities
WHERE search_vector @@ to_tsquery('simple', $1)
ORDER BY ts_rank(search_vector, to_tsquery('simple', $1)) DESC
LIMIT 20;

-- name: ListUniversities :many
SELECT id, name, domain FROM universities
ORDER BY name
LIMIT 50;
