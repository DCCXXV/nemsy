package universities

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/DCCXXV/Nemsy/backend/internal/app"
)

type Handler struct {
	app *app.App
}

func NewHandler(a *app.App) *Handler {
	return &Handler{app: a}
}

type UniversityResponse struct {
	ID     int32  `json:"id"`
	Name   string `json:"name"`
	Domain string `json:"domain"`
}

func (h *Handler) Search(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	if query == "" {
		unis, err := h.app.Queries.ListUniversities(r.Context())
		if err != nil {
			log.Printf("Error listing universities: %v", err)
			http.Error(w, "database error", http.StatusInternalServerError)
			return
		}
		resp := make([]UniversityResponse, len(unis))
		for i, u := range unis {
			resp[i] = UniversityResponse{ID: u.ID, Name: u.Name, Domain: u.Domain}
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
		return
	}

	unis, err := h.app.Queries.SearchUniversities(r.Context(), query)
	if err != nil {
		log.Printf("Error searching universities: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	resp := make([]UniversityResponse, len(unis))
	for i, u := range unis {
		resp[i] = UniversityResponse{ID: u.ID, Name: u.Name, Domain: u.Domain}
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
