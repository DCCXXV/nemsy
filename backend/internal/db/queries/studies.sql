-- name: ListStudies :many
SELECT * FROM studies
ORDER BY name;

-- name: ListStudiesByUniversity :many
SELECT * FROM studies
WHERE university_id = $1
ORDER BY name;

-- name: GetStudy :one
SELECT * FROM studies
WHERE id = $1 LIMIT 1;
