package users

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/DCCXXV/Nemsy/backend/internal/app"
	"github.com/DCCXXV/Nemsy/backend/internal/auth"
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

type UserResponse struct {
	ID        int32   `json:"id"`
	Email     string  `json:"email"`
	Username  string  `json:"username"`
	Hd        *string `json:"hd,omitempty"`
	StudyID   *int32  `json:"studyId,omitempty"`
	StudyName *string `json:"studyName,omitempty"`
}

func (h *Handler) MeHandler(w http.ResponseWriter, r *http.Request) {
	userInfo, ok := r.Context().Value(auth.CtxUserInfo).(auth.UserInfo)
	if !ok || userInfo.Email == "" {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	user, err := h.app.Queries.GetUserWithStudyByEmail(r.Context(), userInfo.Email)
	if err != nil {
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	resp := UserResponse{
		ID:       user.ID,
		Email:    user.Email,
		Username: user.Username,
	}
	if user.Hd.Valid {
		resp.Hd = &user.Hd.String
	}
	if user.StudyIDFk.Valid {
		resp.StudyID = &user.StudyIDFk.Int32
		resp.StudyName = &user.StudyName.String
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (h *Handler) UpdateUserStudy(w http.ResponseWriter, r *http.Request) {
	userIDVal := r.Context().Value(auth.CtxUserID)
	if userIDVal == nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	userID, ok := userIDVal.(int32)
	if !ok {
		http.Error(w, "invalid user ID type", http.StatusInternalServerError)
		return
	}

	var req struct {
		StudyID int32 `json:"studyId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}
	if req.StudyID == 0 {
		http.Error(w, "studyId is required", http.StatusBadRequest)
		return
	}

	updatedUser, err := h.app.Queries.UpdateUserStudy(r.Context(), db.UpdateUserStudyParams{
		ID:      userID,
		StudyID: pgtype.Int4{Int32: req.StudyID, Valid: true},
	})
	if err != nil {
		log.Printf("Failed to update study for user %d: %v", userID, err)
		http.Error(w, "failed to update study", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updatedUser)
}

type SubjectResponse struct {
	ID     int32  `json:"id"`
	Name   string `json:"name"`
	Year   string `json:"year,omitempty"`
	Pinned bool   `json:"pinned"`
}

func (h *Handler) MySubjects(w http.ResponseWriter, r *http.Request) {
	userIDVal := r.Context().Value(auth.CtxUserID)
	if userIDVal == nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	userID, ok := userIDVal.(int32)
	if !ok {
		http.Error(w, "invalid user ID type", http.StatusInternalServerError)
		return
	}

	userInfo, ok := r.Context().Value(auth.CtxUserInfo).(auth.UserInfo)
	if !ok || userInfo.Email == "" {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	user, err := h.app.Queries.GetUserByEmail(r.Context(), userInfo.Email)
	if err != nil {
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	if !user.StudyID.Valid {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode([]SubjectResponse{})
		return
	}

	subjects, err := h.app.Queries.ListSubjectsByStudyWithPinned(r.Context(), db.ListSubjectsByStudyWithPinnedParams{
		StudyID: user.StudyID,
		UserID:  userID,
	})
	if err != nil {
		log.Printf("Error fetching subjects: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	resp := make([]SubjectResponse, len(subjects))
	for i, s := range subjects {
		resp[i] = SubjectResponse{
			ID:     s.ID,
			Name:   s.Name,
			Pinned: s.Pinned,
		}
		if s.Year.Valid {
			resp[i].Year = s.Year.String
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (h *Handler) PinSubject(w http.ResponseWriter, r *http.Request) {
	userIDVal := r.Context().Value(auth.CtxUserID)
	if userIDVal == nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	userID, ok := userIDVal.(int32)
	if !ok {
		http.Error(w, "invalid user ID type", http.StatusInternalServerError)
		return
	}

	idStr := chi.URLParam(r, "id")
	subjectID, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	if err := h.app.Queries.PinSubject(r.Context(), db.PinSubjectParams{
		UserID:    userID,
		SubjectID: int32(subjectID),
	}); err != nil {
		log.Printf("Error pinning subject: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) UnpinSubject(w http.ResponseWriter, r *http.Request) {
	userIDVal := r.Context().Value(auth.CtxUserID)
	if userIDVal == nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	userID, ok := userIDVal.(int32)
	if !ok {
		http.Error(w, "invalid user ID type", http.StatusInternalServerError)
		return
	}

	idStr := chi.URLParam(r, "id")
	subjectID, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	if err := h.app.Queries.UnpinSubject(r.Context(), db.UnpinSubjectParams{
		UserID:    userID,
		SubjectID: int32(subjectID),
	}); err != nil {
		log.Printf("Error unpinning subject: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) Get(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	user, err := h.app.Queries.GetUser(r.Context(), int32(id))
	if err != nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	resp := UserResponse{
		ID:       user.ID,
		Email:    user.Email,
		Username: user.Username,
	}
	if user.Hd.Valid {
		resp.Hd = &user.Hd.String
	}
	if user.StudyID.Valid {
		resp.StudyID = &user.StudyID.Int32
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (h *Handler) GetByUsername(w http.ResponseWriter, r *http.Request) {
	username := chi.URLParam(r, "username")
	if username == "" {
		http.Error(w, "invalid username", http.StatusBadRequest)
		return
	}

	user, err := h.app.Queries.GetUserWithStudyByUsername(r.Context(), username)
	if err != nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	resp := UserResponse{
		ID:       user.ID,
		Email:    user.Email,
		Username: user.Username,
	}
	if user.Hd.Valid {
		resp.Hd = &user.Hd.String
	}
	if user.StudyIDFk.Valid {
		resp.StudyID = &user.StudyIDFk.Int32
		resp.StudyName = &user.StudyName.String
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
