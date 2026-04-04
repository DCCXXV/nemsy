package app

import (
	db "github.com/DCCXXV/Nemsy/backend/internal/db/generated"
	"github.com/DCCXXV/Nemsy/backend/internal/storage"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// QuerierWithTx extends the sqlc generated querier with transaction support.
type QuerierWithTx interface {
	db.Querier
	WithTx(tx pgx.Tx) *db.Queries
}

type App struct {
	DB      *pgxpool.Pool
	Queries QuerierWithTx
	Storage *storage.S3Client
}
