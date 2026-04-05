package studies

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/DCCXXV/Nemsy/backend/internal/app"
	db "github.com/DCCXXV/Nemsy/backend/internal/db/generated"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

// mockQuerier implements app.QuerierWithTx with only the methods we need
// methods not used in these tests will just panic
type mockQuerier struct {
	db.Querier
	listStudiesFn             func(ctx context.Context) ([]db.Study, error)
	listStudiesByUniversityFn func(ctx context.Context, uid pgtype.Int4) ([]db.Study, error)
}

func (m *mockQuerier) ListStudies(ctx context.Context) ([]db.Study, error) {
	return m.listStudiesFn(ctx)
}

func (m *mockQuerier) ListStudiesByUniversity(ctx context.Context, uid pgtype.Int4) ([]db.Study, error) {
	return m.listStudiesByUniversityFn(ctx, uid)
}

func (m *mockQuerier) WithTx(tx pgx.Tx) *db.Queries {
	panic("WithTx not expected in studies tests")
}

func newTestHandler(mq *mockQuerier) *Handler {
	return NewHandler(&app.App{Queries: mq})
}

// ListStudies

func TestListStudies_ReturnsAllStudies(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listStudiesFn: func(ctx context.Context) ([]db.Study, error) {
			return []db.Study{
				{ID: 1, Name: "Ingeniería de Software"},
				{ID: 2, Name: "Matemáticas"},
			}, nil
		},
	})

	req := httptest.NewRequest("GET", "/api/studies", nil)
	rr := httptest.NewRecorder()

	h.ListStudies(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp []StudyResponse
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil {
		t.Fatal("failed to decode response:", err)
	}

	if len(resp) != 2 {
		t.Fatalf("expected 2 studies, got %d", len(resp))
	}
	if resp[0].Name != "Ingeniería de Software" {
		t.Errorf("expected first study 'Ingeniería de Software', got %q", resp[0].Name)
	}
}

func TestListStudies_EmptyReturnsEmptyArray(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listStudiesFn: func(ctx context.Context) ([]db.Study, error) {
			return []db.Study{}, nil
		},
	})

	req := httptest.NewRequest("GET", "/api/studies", nil)
	rr := httptest.NewRecorder()

	h.ListStudies(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp []StudyResponse
	json.NewDecoder(rr.Body).Decode(&resp)
	if len(resp) != 0 {
		t.Errorf("expected 0 studies, got %d", len(resp))
	}
}

func TestListStudies_DBErrorReturns500(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listStudiesFn: func(ctx context.Context) ([]db.Study, error) {
			return nil, context.DeadlineExceeded
		},
	})

	req := httptest.NewRequest("GET", "/api/studies", nil)
	rr := httptest.NewRecorder()

	h.ListStudies(rr, req)

	if rr.Code != http.StatusInternalServerError {
		t.Errorf("expected 500 on DB error, got %d", rr.Code)
	}
}

// ListByUniversity

func TestListByUniversity_ReturnsStudiesForUniversity(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listStudiesByUniversityFn: func(ctx context.Context, uid pgtype.Int4) ([]db.Study, error) {
			if uid.Int32 != 5 || !uid.Valid {
				t.Errorf("expected university ID 5, got %d (valid=%v)", uid.Int32, uid.Valid)
			}
			return []db.Study{
				{ID: 10, Name: "Derecho"},
			}, nil
		},
	})

	req := httptest.NewRequest("GET", "/api/universities/5/studies", nil)
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("universityId", "5")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	rr := httptest.NewRecorder()
	h.ListByUniversity(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp []StudyResponse
	json.NewDecoder(rr.Body).Decode(&resp)
	if len(resp) != 1 || resp[0].Name != "Derecho" {
		t.Errorf("unexpected response: %+v", resp)
	}
}

func TestListByUniversity_InvalidIDReturns400(t *testing.T) {
	h := newTestHandler(&mockQuerier{})

	req := httptest.NewRequest("GET", "/api/universities/abc/studies", nil)
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("universityId", "abc")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	rr := httptest.NewRecorder()
	h.ListByUniversity(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid ID, got %d", rr.Code)
	}
}

func TestListByUniversity_DBErrorReturns500(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listStudiesByUniversityFn: func(ctx context.Context, uid pgtype.Int4) ([]db.Study, error) {
			return nil, context.DeadlineExceeded
		},
	})

	req := httptest.NewRequest("GET", "/api/universities/1/studies", nil)
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("universityId", "1")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	rr := httptest.NewRecorder()
	h.ListByUniversity(rr, req)

	if rr.Code != http.StatusInternalServerError {
		t.Errorf("expected 500 on DB error, got %d", rr.Code)
	}
}
