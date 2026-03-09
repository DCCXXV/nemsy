-- name: GetResource :one
SELECT * FROM resources
WHERE id = $1 LIMIT 1;

-- name: GetResourceWithOwner :one
SELECT
    r.id, r.title, r.description, r.created_at,
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
    r.id, r.title, r.description, r.created_at,
    u.id AS owner_id, u.username AS owner_username, u.email AS owner_email
FROM resources r
JOIN users u ON r.owner_id = u.id
WHERE r.subject_id = $1
ORDER BY r.created_at DESC;

-- name: ListResourcesBySubjectWithOwnerPaginated :many
SELECT
    r.id, r.title, r.description, r.created_at,
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

-- name: CreateResource :one
INSERT INTO resources (
    owner_id, subject_id, title, description
) VALUES (
    $1, $2, $3, $4
)
RETURNING *;
