-- name: CreateResourceFile :one
INSERT INTO resource_files (resource_id, s3_key, file_name, file_size)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: ListFilesByResource :many
SELECT * FROM resource_files
WHERE resource_id = $1
ORDER BY created_at;

-- name: GetResourceFile :one
SELECT * FROM resource_files
WHERE id = $1 LIMIT 1;

-- name: DeleteResourceFile :exec
DELETE FROM resource_files
WHERE id = $1;

-- name: ListS3KeysByResource :many
SELECT s3_key FROM resource_files
WHERE resource_id = $1;
