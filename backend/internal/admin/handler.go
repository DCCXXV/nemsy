package admin

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/DCCXXV/Nemsy/backend/internal/app"
	db "github.com/DCCXXV/Nemsy/backend/internal/db/generated"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	app *app.App
}

func NewHandler(a *app.App) *Handler {
	return &Handler{app: a}
}

type ReportResponse struct {
	ID               int32  `json:"id"`
	Reason           string `json:"reason"`
	CreatedAt        string `json:"createdAt"`
	ResourceID       int32  `json:"resourceId"`
	ResourceTitle    string `json:"resourceTitle"`
	ReporterID       int32  `json:"reporterId"`
	ReporterUsername string `json:"reporterUsername"`
	OwnerID          int32  `json:"ownerId"`
	OwnerUsername    string `json:"ownerUsername"`
}

func (h *Handler) ListReports(w http.ResponseWriter, r *http.Request) {
	var limit int32 = 50
	var offset int32
	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 {
			limit = int32(v)
		}
	}
	if o := r.URL.Query().Get("offset"); o != "" {
		if v, err := strconv.Atoi(o); err == nil && v >= 0 {
			offset = int32(v)
		}
	}

	reports, err := h.app.Queries.ListReports(r.Context(), db.ListReportsParams{
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		log.Printf("Failed to list reports: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	resp := make([]ReportResponse, 0, len(reports))
	for _, rp := range reports {
		resp = append(resp, ReportResponse{
			ID:               rp.ID,
			Reason:           rp.Reason,
			CreatedAt:        rp.CreatedAt.Time.Format(time.RFC3339),
			ResourceID:       rp.ResourceID,
			ResourceTitle:    rp.ResourceTitle,
			ReporterID:       rp.ReporterID,
			ReporterUsername: rp.ReporterUsername,
			OwnerID:          rp.OwnerID,
			OwnerUsername:    rp.OwnerUsername,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (h *Handler) DismissReport(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	if err := h.app.Queries.DeleteReport(r.Context(), int32(id)); err != nil {
		log.Printf("Failed to dismiss report %d: %v", id, err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) DeleteResource(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	s3Keys, err := h.app.Queries.ListS3KeysByResource(r.Context(), int32(id))
	if err != nil {
		log.Printf("Failed to list S3 keys for resource %d: %v", id, err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	if err := h.app.Queries.AdminDeleteResource(r.Context(), int32(id)); err != nil {
		log.Printf("Failed to admin-delete resource %d: %v", id, err)
		http.Error(w, "failed to delete resource", http.StatusInternalServerError)
		return
	}

	if len(s3Keys) > 0 {
		if err := h.app.Storage.DeleteMultiple(r.Context(), s3Keys); err != nil {
			log.Printf("Failed to cleanup S3 objects for resource %d: %v", id, err)
		}
	}

	w.WriteHeader(http.StatusNoContent)
}
