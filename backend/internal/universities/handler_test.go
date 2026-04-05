package universities

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/DCCXXV/Nemsy/backend/internal/app"
	db "github.com/DCCXXV/Nemsy/backend/internal/db/generated"
	"github.com/jackc/pgx/v5"
)

// mockQuerier implements app.QuerierWithTx with only the methods we need
// methods not used in these tests will just panic
type mockQuerier struct {
	db.Querier
	listUniversitiesFn   func(ctx context.Context) ([]db.ListUniversitiesRow, error)
	searchUniversitiesFn func(ctx context.Context, query string) ([]db.SearchUniversitiesRow, error)
}

func (m *mockQuerier) ListUniversities(ctx context.Context) ([]db.ListUniversitiesRow, error) {
	return m.listUniversitiesFn(ctx)
}

func (m *mockQuerier) SearchUniversities(ctx context.Context, query string) ([]db.SearchUniversitiesRow, error) {
	return m.searchUniversitiesFn(ctx, query)
}

func (m *mockQuerier) WithTx(tx pgx.Tx) *db.Queries {
	panic("WithTx not expected in universities tests")
}

func newTestHandler(mq *mockQuerier) *Handler {
	return NewHandler(&app.App{Queries: mq})
}

// Search

func TestSearch_EmptyQueryListsAll(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listUniversitiesFn: func(ctx context.Context) ([]db.ListUniversitiesRow, error) {
			return []db.ListUniversitiesRow{
				{ID: 1, Name: "Universidad Complutense de Madrid", Domain: "ucm.es"},
				{ID: 2, Name: "Universidad Politécnica de Madrid", Domain: "upm.es"},
			}, nil
		},
	})

	req := httptest.NewRequest("GET", "/api/universities", nil)
	rr := httptest.NewRecorder()

	h.Search(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp []UniversityResponse
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil {
		t.Fatal("failed to decode response:", err)
	}

	if len(resp) != 2 {
		t.Fatalf("expected 2 universities, got %d", len(resp))
	}
	if resp[0].Domain != "ucm.es" {
		t.Errorf("expected domain 'ucm.es', got %q", resp[0].Domain)
	}
}

func TestSearch_WithQueryUsesFullTextSearch(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		searchUniversitiesFn: func(ctx context.Context, query string) ([]db.SearchUniversitiesRow, error) {
			if query != "complutense:*" {
				t.Errorf("expected tsquery 'complutense:*', got %q", query)
			}
			return []db.SearchUniversitiesRow{
				{ID: 1, Name: "Universidad Complutense de Madrid", Domain: "ucm.es"},
			}, nil
		},
	})

	req := httptest.NewRequest("GET", "/api/universities?q=complutense", nil)
	rr := httptest.NewRecorder()

	h.Search(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp []UniversityResponse
	json.NewDecoder(rr.Body).Decode(&resp)

	if len(resp) != 1 {
		t.Fatalf("expected 1 university, got %d", len(resp))
	}
	if resp[0].Name != "Universidad Complutense de Madrid" {
		t.Errorf("expected 'Universidad Complutense de Madrid', got %q", resp[0].Name)
	}
}

func TestSearch_DBErrorReturns500(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listUniversitiesFn: func(ctx context.Context) ([]db.ListUniversitiesRow, error) {
			return nil, context.DeadlineExceeded
		},
	})

	req := httptest.NewRequest("GET", "/api/universities", nil)
	rr := httptest.NewRecorder()

	h.Search(rr, req)

	if rr.Code != http.StatusInternalServerError {
		t.Errorf("expected 500 on DB error, got %d", rr.Code)
	}
}

func TestSearch_SpecialCharsOnlyListsAll(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listUniversitiesFn: func(ctx context.Context) ([]db.ListUniversitiesRow, error) {
			return []db.ListUniversitiesRow{}, nil
		},
	})

	req := httptest.NewRequest("GET", "/api/universities?q=!!!%3F%3F%3F", nil)
	rr := httptest.NewRecorder()

	h.Search(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}
}
