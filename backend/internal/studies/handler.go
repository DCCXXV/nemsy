package studies

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/DCCXXV/Nemsy/backend/internal/app"
	db "github.com/DCCXXV/Nemsy/backend/internal/db/generated"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type Handler struct {
	app *app.App
}

func NewHandler(a *app.App) *Handler {
	return &Handler{app: a}
}

type StudyResponse struct {
	ID   int32  `json:"id"`
	Name string `json:"name"`
}

func toStudyResponses(studies []db.Study) []StudyResponse {
	resp := make([]StudyResponse, len(studies))
	for i, s := range studies {
		resp[i] = StudyResponse{ID: s.ID, Name: s.Name}
	}
	return resp
}

func (h *Handler) ListStudies(w http.ResponseWriter, r *http.Request) {
	studies, err := h.app.Queries.ListStudies(r.Context())
	if err != nil {
		log.Printf("Error fetching studies: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(toStudyResponses(studies))
}

func (h *Handler) ListByUniversity(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "universityId")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "invalid university id", http.StatusBadRequest)
		return
	}

	studies, err := h.app.Queries.ListStudiesByUniversity(r.Context(), pgtype.Int4{Int32: int32(id), Valid: true})
	if err != nil {
		log.Printf("Error fetching studies by university: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(toStudyResponses(studies))
}
