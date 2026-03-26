-- name: GetResource :one
SELECT * FROM resources
WHERE id = $1 LIMIT 1;

-- name: GetResourceWithOwner :one
SELECT
    r.id, r.title, r.description, r.created_at, r.download_count,
    u.id AS owner_id, u.username AS owner_username, u.email AS owner_email
FROM resources r
JOIN users u ON r.owner_id = u.id
WHERE r.id = $1 LIMIT 1;

-- name: ListResourcesBySubject :many
SELECT * FROM resources
WHERE subject_id = $1
ORDER BY created_at DESC;

-- name: ListResourcesBySubjectWithOwner :many
SELECT
    r.id, r.title, r.description, r.created_at, r.download_count,
    u.id AS owner_id, u.username AS owner_username, u.email AS owner_email
FROM resources r
JOIN users u ON r.owner_id = u.id
WHERE r.subject_id = $1
ORDER BY r.created_at DESC;

-- name: ListResourcesBySubjectWithOwnerPaginated :many
SELECT
    r.id, r.title, r.description, r.created_at, r.download_count,
    u.id AS owner_id, u.username AS owner_username, u.email AS owner_email
FROM resources r
JOIN users u ON r.owner_id = u.id
WHERE r.subject_id = $1
ORDER BY r.created_at DESC
LIMIT $2 OFFSET $3;

-- name: ListResourcesByOwner :many
SELECT * FROM resources
WHERE owner_id = $1
ORDER BY created_at DESC;

-- name: ListResourcesByOwnerWithSubject :many
SELECT
    r.id, r.title, r.description, r.created_at, r.download_count,
    u.id AS owner_id, u.username AS owner_username, u.email AS owner_email,
    s.id AS subject_id, s.name AS subject_name
FROM resources r
JOIN users u ON r.owner_id = u.id
JOIN subjects s ON r.subject_id = s.id
WHERE r.owner_id = $1
ORDER BY r.created_at DESC;

-- name: CreateResource :one
INSERT INTO resources (
    owner_id, subject_id, title, description
) VALUES (
    $1, $2, $3, $4
)
RETURNING *;

-- name: IncrementDownloadCount :exec
UPDATE resources SET download_count = download_count + 1 WHERE id = $1;

-- name: DeleteResource :exec
DELETE FROM resources WHERE id = $1 AND owner_id = $2;
