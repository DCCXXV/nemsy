package admin

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
)

// mockQuerier implements app.QuerierWithTx with only the methods we need
// methods not used in these tests will just panic
type mockQuerier struct {
	db.Querier
	listReportsFn  func(ctx context.Context, arg db.ListReportsParams) ([]db.ListReportsRow, error)
	deleteReportFn func(ctx context.Context, id int32) error
}

func (m *mockQuerier) ListReports(ctx context.Context, arg db.ListReportsParams) ([]db.ListReportsRow, error) {
	return m.listReportsFn(ctx, arg)
}

func (m *mockQuerier) DeleteReport(ctx context.Context, id int32) error {
	return m.deleteReportFn(ctx, id)
}

func (m *mockQuerier) WithTx(tx pgx.Tx) *db.Queries {
	panic("WithTx not expected in admin tests")
}

func newTestHandler(mq *mockQuerier) *Handler {
	return NewHandler(&app.App{Queries: mq})
}

func chiCtx(req *http.Request, key, val string) *http.Request {
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add(key, val)
	return req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))
}

// ListReports

func TestListReports_ReturnsAllReports(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listReportsFn: func(ctx context.Context, arg db.ListReportsParams) ([]db.ListReportsRow, error) {
			if arg.Limit != 50 {
				t.Errorf("expected default limit 50, got %d", arg.Limit)
			}
			return []db.ListReportsRow{
				{ID: 1, Reason: "infracción de derechos de autor", ResourceID: 10, ResourceTitle: "Apuntes", ReporterID: 2, ReporterUsername: "ana", OwnerID: 3, OwnerUsername: "carlos"},
				{ID: 2, Reason: "contenido inapropiado", ResourceID: 11, ResourceTitle: "Resumen", ReporterID: 4, ReporterUsername: "luis", OwnerID: 5, OwnerUsername: "maria"},
			}, nil
		},
	})

	req := httptest.NewRequest("GET", "/api/admin/reports", nil)
	rr := httptest.NewRecorder()

	h.ListReports(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp []ReportResponse
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil {
		t.Fatal("failed to decode response:", err)
	}

	if len(resp) != 2 {
		t.Fatalf("expected 2 reports, got %d", len(resp))
	}
	if resp[0].Reason != "infracción de derechos de autor" {
		t.Errorf("expected reason 'infracción de derechos de autor', got %q", resp[0].Reason)
	}
}

func TestListReports_DBErrorReturns500(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listReportsFn: func(ctx context.Context, arg db.ListReportsParams) ([]db.ListReportsRow, error) {
			return nil, context.DeadlineExceeded
		},
	})

	req := httptest.NewRequest("GET", "/api/admin/reports", nil)
	rr := httptest.NewRecorder()

	h.ListReports(rr, req)

	if rr.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rr.Code)
	}
}

func TestListReports_CustomPagination(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		listReportsFn: func(ctx context.Context, arg db.ListReportsParams) ([]db.ListReportsRow, error) {
			if arg.Limit != 10 {
				t.Errorf("expected limit 10, got %d", arg.Limit)
			}
			if arg.Offset != 20 {
				t.Errorf("expected offset 20, got %d", arg.Offset)
			}
			return []db.ListReportsRow{}, nil
		},
	})

	req := httptest.NewRequest("GET", "/api/admin/reports?limit=10&offset=20", nil)
	rr := httptest.NewRecorder()

	h.ListReports(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}
}

// DismissReport

func TestDismissReport_SuccessReturns204(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		deleteReportFn: func(ctx context.Context, id int32) error {
			if id != 7 {
				t.Errorf("expected report ID 7, got %d", id)
			}
			return nil
		},
	})

	req := chiCtx(httptest.NewRequest("DELETE", "/api/admin/reports/7", nil), "id", "7")
	rr := httptest.NewRecorder()

	h.DismissReport(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Errorf("expected 204, got %d", rr.Code)
	}
}

func TestDismissReport_InvalidIDReturns400(t *testing.T) {
	h := newTestHandler(&mockQuerier{})

	req := chiCtx(httptest.NewRequest("DELETE", "/api/admin/reports/abc", nil), "id", "abc")
	rr := httptest.NewRecorder()

	h.DismissReport(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rr.Code)
	}
}

func TestDismissReport_DBErrorReturns500(t *testing.T) {
	h := newTestHandler(&mockQuerier{
		deleteReportFn: func(ctx context.Context, id int32) error {
			return context.DeadlineExceeded
		},
	})

	req := chiCtx(httptest.NewRequest("DELETE", "/api/admin/reports/1", nil), "id", "1")
	rr := httptest.NewRecorder()

	h.DismissReport(rr, req)

	if rr.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rr.Code)
	}
}
