package resources

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
	getResourceWithOwnerFn                     func(ctx context.Context, id int32) (db.GetResourceWithOwnerRow, error)
	listFilesByResourceFn                      func(ctx context.Context, resourceID int32) ([]db.ResourceFile, error)
	listResourcesBySubjectWithOwnerPaginatedFn func(ctx context.Context, arg db.ListResourcesBySubjectWithOwnerPaginatedParams) ([]db.ListResourcesBySubjectWithOwnerPaginatedRow, error)
	searchResourcesFn                          func(ctx context.Context, arg db.SearchResourcesParams) ([]db.SearchResourcesRow, error)
}

func (m *mockQuerier) GetResourceWithOwner(ctx context.Context, id int32) (db.GetResourceWithOwnerRow, error) {
	return m.getResourceWithOwnerFn(ctx, id)
}

func (m *mockQuerier) ListFilesByResource(ctx context.Context, resourceID int32) ([]db.ResourceFile, error) {
	return m.listFilesByResourceFn(ctx, resourceID)
}

func (m *mockQuerier) ListResourcesBySubjectWithOwnerPaginated(ctx context.Context, arg db.ListResourcesBySubjectWithOwnerPaginatedParams) ([]db.ListResourcesBySubjectWithOwnerPaginatedRow, error) {
	return m.listResourcesBySubjectWithOwnerPaginatedFn(ctx, arg)
}

func (m *mockQuerier) SearchResources(ctx context.Context, arg db.SearchResourcesParams) ([]db.SearchResourcesRow, error) {
	return m.searchResourcesFn(ctx, arg)
}

func (m *mockQuerier) WithTx(tx pgx.Tx) *db.Queries {
	panic("WithTx not expected in these tests")
}

func newTestHandler(mq *mockQuerier) *Handler {
	return NewHandler(&app.App{Queries: mq})
}

func chiCtx(req *http.Request, key, val string) *http.Request {
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add(key, val)
	return req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))
}

// Get

func TestGet_ReturnsResourceWithOwnerAndFiles(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		getResourceWithOwnerFn: func(ctx context.Context, id int32) (db.GetResourceWithOwnerRow, error) {
			if id != 42 {
				t.Errorf("expected id 42, got %d", id)
			}
			return db.GetResourceWithOwnerRow{
				ID:            42,
				Title:         "Apuntes Álgebra",
				DownloadCount: 5,
				OwnerID:       1,
				OwnerUsername: "juan",
				OwnerEmail:    "juan@ucm.es",
			}, nil
		},
		listFilesByResourceFn: func(ctx context.Context, resourceID int32) ([]db.ResourceFile, error) {
			return []db.ResourceFile{
				{ID: 100, FileName: "tema1.pdf", FileSize: 1024},
				{ID: 101, FileName: "tema2.pdf", FileSize: 2048},
			}, nil
		},
	})

	req := chiCtx(httptest.NewRequest("GET", "/api/resources/42", nil), "id", "42")
	rr := httptest.NewRecorder()

	h.Get(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp ResourceResponse
	json.NewDecoder(rr.Body).Decode(&resp)

	if resp.Title != "Apuntes Álgebra" {
		t.Errorf("expected title 'Apuntes Álgebra', got %q", resp.Title)
	}
	if len(resp.Files) != 2 {
		t.Errorf("expected 2 files, got %d", len(resp.Files))
	}
	if resp.Owner == nil || resp.Owner.Username != "juan" {
		t.Errorf("expected owner 'juan', got %+v", resp.Owner)
	}
}

func TestGet_InvalidIDReturns400(t *testing.T) {
	h := newTestHandler(&mockQuerier{})

	req := chiCtx(httptest.NewRequest("GET", "/api/resources/abc", nil), "id", "abc")
	rr := httptest.NewRecorder()

	h.Get(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rr.Code)
	}
}

func TestGet_NotFoundReturns404(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		getResourceWithOwnerFn: func(ctx context.Context, id int32) (db.GetResourceWithOwnerRow, error) {
			return db.GetResourceWithOwnerRow{}, context.DeadlineExceeded
		},
	})

	req := chiCtx(httptest.NewRequest("GET", "/api/resources/999", nil), "id", "999")
	rr := httptest.NewRecorder()

	h.Get(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", rr.Code)
	}
}

// ListBySubject

func TestListBySubject_ReturnsPaginatedResources(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listResourcesBySubjectWithOwnerPaginatedFn: func(ctx context.Context, arg db.ListResourcesBySubjectWithOwnerPaginatedParams) ([]db.ListResourcesBySubjectWithOwnerPaginatedRow, error) {
			if arg.SubjectID != 3 {
				t.Errorf("expected subject ID 3, got %d", arg.SubjectID)
			}
			if arg.Limit != 5 {
				t.Errorf("expected limit 5, got %d", arg.Limit)
			}
			if arg.Offset != 10 {
				t.Errorf("expected offset 10, got %d", arg.Offset)
			}
			return []db.ListResourcesBySubjectWithOwnerPaginatedRow{
				{ID: 1, Title: "Apuntes Tema 1", OwnerID: 10, OwnerUsername: "ana", OwnerEmail: "ana@ucm.es"},
			}, nil
		},
		listFilesByResourceFn: func(ctx context.Context, resourceID int32) ([]db.ResourceFile, error) {
			return []db.ResourceFile{{ID: 50, FileName: "apuntes.pdf", FileSize: 512}}, nil
		},
	})

	req := chiCtx(httptest.NewRequest("GET", "/api/subjects/3/resources?limit=5&offset=10", nil), "id", "3")
	rr := httptest.NewRecorder()

	h.ListBySubject(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp []ResourceResponse
	json.NewDecoder(rr.Body).Decode(&resp)

	if len(resp) != 1 {
		t.Fatalf("expected 1 resource, got %d", len(resp))
	}
	if resp[0].Owner.Username != "ana" {
		t.Errorf("expected owner 'ana', got %q", resp[0].Owner.Username)
	}
}

func TestListBySubject_DefaultsPaginationParams(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listResourcesBySubjectWithOwnerPaginatedFn: func(ctx context.Context, arg db.ListResourcesBySubjectWithOwnerPaginatedParams) ([]db.ListResourcesBySubjectWithOwnerPaginatedRow, error) {
			if arg.Limit != 10 {
				t.Errorf("expected default limit 10, got %d", arg.Limit)
			}
			if arg.Offset != 0 {
				t.Errorf("expected default offset 0, got %d", arg.Offset)
			}
			return []db.ListResourcesBySubjectWithOwnerPaginatedRow{}, nil
		},
		listFilesByResourceFn: func(ctx context.Context, resourceID int32) ([]db.ResourceFile, error) {
			return nil, nil
		},
	})

	req := chiCtx(httptest.NewRequest("GET", "/api/subjects/1/resources", nil), "id", "1")
	rr := httptest.NewRecorder()

	h.ListBySubject(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}
}

func TestListBySubject_InvalidIDReturns400(t *testing.T) {
	h := newTestHandler(&mockQuerier{})

	req := chiCtx(httptest.NewRequest("GET", "/api/subjects/abc/resources", nil), "id", "abc")
	rr := httptest.NewRecorder()

	h.ListBySubject(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rr.Code)
	}
}

// Search

func TestSearch_EmptyQueryReturnsEmptyArray(t *testing.T) {
	h := newTestHandler(&mockQuerier{})

	req := httptest.NewRequest("GET", "/api/resources/search", nil)
	rr := httptest.NewRecorder()

	h.Search(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp []ResourceResponse
	json.NewDecoder(rr.Body).Decode(&resp)
	if len(resp) != 0 {
		t.Errorf("expected empty array, got %d items", len(resp))
	}
}

func TestSearch_WithQuerySearchesAndReturnsResults(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		searchResourcesFn: func(ctx context.Context, arg db.SearchResourcesParams) ([]db.SearchResourcesRow, error) {
			if arg.ToTsquery != "algebra:*" {
				t.Errorf("expected tsquery 'algebra:*', got %q", arg.ToTsquery)
			}
			if arg.Limit != 50 {
				t.Errorf("expected limit 50, got %d", arg.Limit)
			}
			return []db.SearchResourcesRow{
				{
					ID: 1, Title: "Apuntes Álgebra", OwnerID: 1,
					OwnerUsername: "carlos", OwnerEmail: "carlos@ucm.es",
					SubjectID: 5, SubjectName: "Álgebra Lineal",
					StudyID: 2, StudyName: "Ingeniería Informática",
					UniversityID:   pgtype.Int4{Int32: 1, Valid: true},
					UniversityName: pgtype.Text{String: "UCM", Valid: true},
				},
			}, nil
		},
		listFilesByResourceFn: func(ctx context.Context, resourceID int32) ([]db.ResourceFile, error) {
			return []db.ResourceFile{{ID: 10, FileName: "algebra.pdf", FileSize: 1024}}, nil
		},
	})

	req := httptest.NewRequest("GET", "/api/resources/search?q=algebra", nil)
	rr := httptest.NewRecorder()

	h.Search(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp []ResourceResponse
	json.NewDecoder(rr.Body).Decode(&resp)

	if len(resp) != 1 {
		t.Fatalf("expected 1 result, got %d", len(resp))
	}
	if resp[0].University == nil || resp[0].University.Name != "UCM" {
		t.Errorf("expected university 'UCM', got %+v", resp[0].University)
	}
	if resp[0].Subject == nil || resp[0].Subject.Name != "Álgebra Lineal" {
		t.Errorf("expected subject 'Álgebra Lineal', got %+v", resp[0].Subject)
	}
}

func TestSearch_DBErrorReturns500(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		searchResourcesFn: func(ctx context.Context, arg db.SearchResourcesParams) ([]db.SearchResourcesRow, error) {
			return nil, context.DeadlineExceeded
		},
	})

	req := httptest.NewRequest("GET", "/api/resources/search?q=test", nil)
	rr := httptest.NewRecorder()

	h.Search(rr, req)

	if rr.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rr.Code)
	}
}

// sanitizeFilename

func TestSanitizeFilename(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{"preserves normal filename", "apuntes.pdf", "apuntes.pdf"},
		{"replaces spaces with underscores", "mi archivo.pdf", "mi_archivo.pdf"},
		{"sanitizes special characters", "file<>name:.pdf", "file__name_.pdf"},
		{"handles path traversal", "../../../etc/passwd", "passwd"},
		{"keeps dashes and underscores", "my-file_v2.tar.gz", "my-file_v2.tar.gz"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := sanitizeFilename(tt.input)
			if got != tt.want {
				t.Errorf("sanitizeFilename(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}
