-- name: GetUser :one
SELECT * FROM users
WHERE id = $1 LIMIT 1;

-- name: GetUserWithStudy :one
SELECT
    u.*,
    s.id AS study_id_fk,
    s.name AS study_name
FROM users u
LEFT JOIN studies s ON u.study_id = s.id
WHERE u.id = $1 LIMIT 1;

-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = $1 LIMIT 1;

-- name: GetUserByUsername :one
SELECT * FROM users
WHERE username = $1 LIMIT 1;

-- name: GetUserWithStudyByEmail :one
SELECT
    u.*,
    s.id AS study_id_fk,
    s.name AS study_name
FROM users u
LEFT JOIN studies s ON u.study_id = s.id
WHERE u.email = $1 LIMIT 1;

-- name: CreateUser :one
INSERT INTO users (
    google_sub, study_id, email, username, hd) VALUES (
    $1, $2, $3, $4, $5
)
RETURNING *;

-- name: UpdateUserStudy :one
UPDATE users
SET study_id = $2
WHERE id = $1
RETURNING *;
