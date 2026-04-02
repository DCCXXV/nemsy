-- name: CreateReport :one
INSERT INTO reports (resource_id, reporter_id, reason)
VALUES ($1, $2, $3)
RETURNING *;

-- name: ListReports :many
SELECT
    rp.id, rp.reason, rp.created_at,
    r.id AS resource_id, r.title AS resource_title,
    reporter.id AS reporter_id, reporter.username AS reporter_username,
    owner.id AS owner_id, owner.username AS owner_username
FROM reports rp
JOIN resources r ON rp.resource_id = r.id
JOIN users reporter ON rp.reporter_id = reporter.id
JOIN users owner ON r.owner_id = owner.id
ORDER BY rp.created_at DESC
LIMIT $1 OFFSET $2;

-- name: DeleteReport :exec
DELETE FROM reports WHERE id = $1;

-- name: DeleteReportsByResource :exec
DELETE FROM reports WHERE resource_id = $1;
