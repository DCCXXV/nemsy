package users

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/DCCXXV/Nemsy/backend/internal/app"
	"github.com/DCCXXV/Nemsy/backend/internal/auth"
	db "github.com/DCCXXV/Nemsy/backend/internal/db/generated"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

// mockQuerier implements app.QuerierWithTx with only the methods we need
// methods not used in these tests will just panic
type mockQuerier struct {
	db.Querier
	getUserWithStudyByEmailFn       func(ctx context.Context, email string) (db.GetUserWithStudyByEmailRow, error)
	getUserWithStudyByUsernameFn    func(ctx context.Context, username string) (db.GetUserWithStudyByUsernameRow, error)
	getUserFn                       func(ctx context.Context, id int32) (db.User, error)
	updateUserUniversityFn          func(ctx context.Context, arg db.UpdateUserUniversityParams) (db.User, error)
	updateUserStudyFn               func(ctx context.Context, arg db.UpdateUserStudyParams) (db.User, error)
	getUserByEmailFn                func(ctx context.Context, email string) (db.User, error)
	listSubjectsByStudyWithPinnedFn func(ctx context.Context, arg db.ListSubjectsByStudyWithPinnedParams) ([]db.ListSubjectsByStudyWithPinnedRow, error)
	pinSubjectFn                    func(ctx context.Context, arg db.PinSubjectParams) error
	unpinSubjectFn                  func(ctx context.Context, arg db.UnpinSubjectParams) error
}

func (m *mockQuerier) GetUserWithStudyByEmail(ctx context.Context, email string) (db.GetUserWithStudyByEmailRow, error) {
	return m.getUserWithStudyByEmailFn(ctx, email)
}

func (m *mockQuerier) GetUserWithStudyByUsername(ctx context.Context, username string) (db.GetUserWithStudyByUsernameRow, error) {
	return m.getUserWithStudyByUsernameFn(ctx, username)
}

func (m *mockQuerier) GetUser(ctx context.Context, id int32) (db.User, error) {
	return m.getUserFn(ctx, id)
}

func (m *mockQuerier) UpdateUserUniversity(ctx context.Context, arg db.UpdateUserUniversityParams) (db.User, error) {
	return m.updateUserUniversityFn(ctx, arg)
}

func (m *mockQuerier) UpdateUserStudy(ctx context.Context, arg db.UpdateUserStudyParams) (db.User, error) {
	return m.updateUserStudyFn(ctx, arg)
}

func (m *mockQuerier) GetUserByEmail(ctx context.Context, email string) (db.User, error) {
	return m.getUserByEmailFn(ctx, email)
}

func (m *mockQuerier) ListSubjectsByStudyWithPinned(ctx context.Context, arg db.ListSubjectsByStudyWithPinnedParams) ([]db.ListSubjectsByStudyWithPinnedRow, error) {
	return m.listSubjectsByStudyWithPinnedFn(ctx, arg)
}

func (m *mockQuerier) PinSubject(ctx context.Context, arg db.PinSubjectParams) error {
	return m.pinSubjectFn(ctx, arg)
}

func (m *mockQuerier) UnpinSubject(ctx context.Context, arg db.UnpinSubjectParams) error {
	return m.unpinSubjectFn(ctx, arg)
}

func (m *mockQuerier) WithTx(tx pgx.Tx) *db.Queries {
	panic("WithTx not expected in users tests")
}

func newTestHandler(mq *mockQuerier) *Handler {
	return NewHandler(&app.App{Queries: mq})
}

// withAuth injects CtxUserInfo and CtxUserID into the request context
func withAuth(req *http.Request, userID int32, email string) *http.Request {
	ctx := context.WithValue(req.Context(), auth.CtxUserInfo, auth.UserInfo{Email: email})
	ctx = context.WithValue(ctx, auth.CtxUserID, userID)
	return req.WithContext(ctx)
}

func chiCtx(req *http.Request, key, val string) *http.Request {
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add(key, val)
	return req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))
}

// MeHandler

func TestMeHandler_ReturnsUserWithStudyAndUniversity(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		getUserWithStudyByEmailFn: func(ctx context.Context, email string) (db.GetUserWithStudyByEmailRow, error) {
			if email != "ana@ucm.es" {
				t.Errorf("expected email 'ana@ucm.es', got %q", email)
			}
			return db.GetUserWithStudyByEmailRow{
				ID:               1,
				Email:            "ana@ucm.es",
				Username:         "ana",
				Role:             "user",
				Hd:               pgtype.Text{String: "ucm.es", Valid: true},
				StudyIDFk:        pgtype.Int4{Int32: 10, Valid: true},
				StudyName:        pgtype.Text{String: "Ingeniería de Software", Valid: true},
				UniversityIDFk:   pgtype.Int4{Int32: 1, Valid: true},
				UniversityName:   pgtype.Text{String: "UCM", Valid: true},
				UniversityDomain: pgtype.Text{String: "ucm.es", Valid: true},
			}, nil
		},
	})

	req := withAuth(httptest.NewRequest("GET", "/api/me", nil), 1, "ana@ucm.es")
	rr := httptest.NewRecorder()

	h.MeHandler(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp UserResponse
	json.NewDecoder(rr.Body).Decode(&resp)

	if resp.Username != "ana" {
		t.Errorf("expected username 'ana', got %q", resp.Username)
	}
	if resp.StudyName == nil || *resp.StudyName != "Ingeniería de Software" {
		t.Errorf("expected study 'Ingeniería de Software', got %v", resp.StudyName)
	}
	if resp.UniversityName == nil || *resp.UniversityName != "UCM" {
		t.Errorf("expected university 'UCM', got %v", resp.UniversityName)
	}
}

func TestMeHandler_NoAuthReturns401(t *testing.T) {
	h := newTestHandler(&mockQuerier{})

	req := httptest.NewRequest("GET", "/api/me", nil)
	rr := httptest.NewRecorder()

	h.MeHandler(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rr.Code)
	}
}

// GetByUsername

func TestGetByUsername_ReturnsUserProfile(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		getUserWithStudyByUsernameFn: func(ctx context.Context, username string) (db.GetUserWithStudyByUsernameRow, error) {
			if username != "carlos" {
				t.Errorf("expected username 'carlos', got %q", username)
			}
			return db.GetUserWithStudyByUsernameRow{
				ID:       2,
				Email:    "carlos@ucm.es",
				Username: "carlos",
				Role:     "user",
			}, nil
		},
	})

	req := chiCtx(httptest.NewRequest("GET", "/api/users/carlos", nil), "username", "carlos")
	rr := httptest.NewRecorder()

	h.GetByUsername(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp UserResponse
	json.NewDecoder(rr.Body).Decode(&resp)

	if resp.Username != "carlos" {
		t.Errorf("expected 'carlos', got %q", resp.Username)
	}
}

func TestGetByUsername_NotFoundReturns404(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		getUserWithStudyByUsernameFn: func(ctx context.Context, username string) (db.GetUserWithStudyByUsernameRow, error) {
			return db.GetUserWithStudyByUsernameRow{}, context.DeadlineExceeded
		},
	})

	req := chiCtx(httptest.NewRequest("GET", "/api/users/noexiste", nil), "username", "noexiste")
	rr := httptest.NewRecorder()

	h.GetByUsername(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", rr.Code)
	}
}

// UpdateUserUniversity

func TestUpdateUserUniversity_SuccessReturns204(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		updateUserUniversityFn: func(ctx context.Context, arg db.UpdateUserUniversityParams) (db.User, error) {
			if arg.ID != 1 {
				t.Errorf("expected user ID 1, got %d", arg.ID)
			}
			if arg.UniversityID.Int32 != 5 {
				t.Errorf("expected university ID 5, got %d", arg.UniversityID.Int32)
			}
			return db.User{}, nil
		},
	})

	body, _ := json.Marshal(map[string]int32{"universityId": 5})
	req := withAuth(httptest.NewRequest("PUT", "/api/me/university", bytes.NewReader(body)), 1, "ana@ucm.es")
	rr := httptest.NewRecorder()

	h.UpdateUserUniversity(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Errorf("expected 204, got %d", rr.Code)
	}
}

func TestUpdateUserUniversity_MissingIDReturns400(t *testing.T) {
	h := newTestHandler(&mockQuerier{})

	body, _ := json.Marshal(map[string]int32{"universityId": 0})
	req := withAuth(httptest.NewRequest("PUT", "/api/me/university", bytes.NewReader(body)), 1, "ana@ucm.es")
	rr := httptest.NewRecorder()

	h.UpdateUserUniversity(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rr.Code)
	}
}

func TestUpdateUserUniversity_NoAuthReturns401(t *testing.T) {
	h := newTestHandler(&mockQuerier{})

	req := httptest.NewRequest("PUT", "/api/me/university", nil)
	rr := httptest.NewRecorder()

	h.UpdateUserUniversity(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rr.Code)
	}
}

// PinSubject

func TestPinSubject_SuccessReturns204(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		pinSubjectFn: func(ctx context.Context, arg db.PinSubjectParams) error {
			if arg.UserID != 1 || arg.SubjectID != 42 {
				t.Errorf("expected user=1 subject=42, got user=%d subject=%d", arg.UserID, arg.SubjectID)
			}
			return nil
		},
	})

	req := chiCtx(
		withAuth(httptest.NewRequest("POST", "/api/me/subjects/42/pin", nil), 1, "ana@ucm.es"),
		"id", "42",
	)
	rr := httptest.NewRecorder()

	h.PinSubject(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Errorf("expected 204, got %d", rr.Code)
	}
}

func TestPinSubject_InvalidIDReturns400(t *testing.T) {
	h := newTestHandler(&mockQuerier{})

	req := chiCtx(
		withAuth(httptest.NewRequest("POST", "/api/me/subjects/abc/pin", nil), 1, "ana@ucm.es"),
		"id", "abc",
	)
	rr := httptest.NewRecorder()

	h.PinSubject(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rr.Code)
	}
}

// UnpinSubject

func TestUnpinSubject_SuccessReturns204(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		unpinSubjectFn: func(ctx context.Context, arg db.UnpinSubjectParams) error {
			if arg.UserID != 1 || arg.SubjectID != 42 {
				t.Errorf("expected user=1 subject=42, got user=%d subject=%d", arg.UserID, arg.SubjectID)
			}
			return nil
		},
	})

	req := chiCtx(
		withAuth(httptest.NewRequest("DELETE", "/api/me/subjects/42/pin", nil), 1, "ana@ucm.es"),
		"id", "42",
	)
	rr := httptest.NewRecorder()

	h.UnpinSubject(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Errorf("expected 204, got %d", rr.Code)
	}
}
