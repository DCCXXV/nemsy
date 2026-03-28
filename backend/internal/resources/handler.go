package resources

import (
	"archive/zip"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

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

type FileResponse struct {
	ID       int32  `json:"id"`
	FileName string `json:"fileName"`
	FileSize int64  `json:"fileSize"`
}

type ResourceResponse struct {
	ID            int32          `json:"id"`
	Title         string         `json:"title"`
	Description   *string        `json:"description,omitempty"`
	Files         []FileResponse `json:"files"`
	CreatedAt     string         `json:"createdAt"`
	DownloadCount int32          `json:"downloadCount"`
	Owner         *Owner         `json:"owner,omitempty"`
	Subject       *SubjectInfo   `json:"subject,omitempty"`
	Study         *StudyInfo     `json:"study,omitempty"`
}

type Owner struct {
	ID       int32  `json:"id"`
	Username string `json:"username"`
	Email    string `json:"email"`
}

type StudyInfo struct {
	ID   int32  `json:"id"`
	Name string `json:"name"`
}

type SubjectInfo struct {
	ID   int32  `json:"id"`
	Name string `json:"name"`
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value(auth.CtxUserID).(int32)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	if err := r.ParseMultipartForm(100 << 20); err != nil {
		http.Error(w, "file too large or invalid form", http.StatusBadRequest)
		return
	}

	subjectIDStr := r.FormValue("subjectId")
	title := r.FormValue("title")
	description := r.FormValue("description")

	if subjectIDStr == "" || title == "" {
		http.Error(w, "subjectId and title are required", http.StatusBadRequest)
		return
	}

	if len(description) > 500 {
		http.Error(w, "description must be 500 characters or less", http.StatusBadRequest)
		return
	}

	subjectID, err := strconv.Atoi(subjectIDStr)
	if err != nil {
		http.Error(w, "invalid subjectId", http.StatusBadRequest)
		return
	}

	files := r.MultipartForm.File["files"]
	if len(files) == 0 {
		http.Error(w, "at least one file is required", http.StatusBadRequest)
		return
	}

	var desc pgtype.Text
	if description != "" {
		desc = pgtype.Text{String: description, Valid: true}
	}

	tx, err := h.app.DB.Begin(r.Context())
	if err != nil {
		log.Printf("Failed to begin transaction: %v", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	qtx := h.app.Queries.WithTx(tx)

	resource, err := qtx.CreateResource(r.Context(), db.CreateResourceParams{
		OwnerID:     userID,
		SubjectID:   int32(subjectID),
		Title:       title,
		Description: desc,
	})
	if err != nil {
		log.Printf("Failed to create resource: %v", err)
		http.Error(w, "failed to create resource", http.StatusInternalServerError)
		return
	}

	var uploadedKeys []string
	var fileResponses []FileResponse

	for _, fh := range files {
		f, err := fh.Open()
		if err != nil {
			log.Printf("Failed to open uploaded file: %v", err)
			h.cleanupS3(r, uploadedKeys)
			http.Error(w, "failed to read uploaded file", http.StatusInternalServerError)
			return
		}

		sanitized := sanitizeFilename(fh.Filename)
		s3Key := fmt.Sprintf("resources/%d/%s", resource.ID, sanitized)
		contentType := fh.Header.Get("Content-Type")
		if contentType == "" {
			contentType = "application/octet-stream"
		}

		if err := h.app.Storage.Upload(r.Context(), s3Key, f, fh.Size, contentType); err != nil {
			f.Close()
			log.Printf("Failed to upload to S3: %v", err)
			h.cleanupS3(r, uploadedKeys)
			http.Error(w, "failed to upload file", http.StatusInternalServerError)
			return
		}
		f.Close()

		uploadedKeys = append(uploadedKeys, s3Key)

		rf, err := qtx.CreateResourceFile(r.Context(), db.CreateResourceFileParams{
			ResourceID: resource.ID,
			S3Key:      s3Key,
			FileName:   fh.Filename,
			FileSize:   fh.Size,
		})
		if err != nil {
			log.Printf("Failed to create resource file record: %v", err)
			h.cleanupS3(r, uploadedKeys)
			http.Error(w, "failed to save file record", http.StatusInternalServerError)
			return
		}

		fileResponses = append(fileResponses, FileResponse{
			ID:       rf.ID,
			FileName: rf.FileName,
			FileSize: rf.FileSize,
		})
	}

	if err := tx.Commit(r.Context()); err != nil {
		log.Printf("Failed to commit transaction: %v", err)
		h.cleanupS3(r, uploadedKeys)
		http.Error(w, "failed to save resource", http.StatusInternalServerError)
		return
	}

	resp := ResourceResponse{
		ID:        resource.ID,
		Title:     resource.Title,
		Files:     fileResponses,
		CreatedAt: resource.CreatedAt.Time.Format(time.RFC3339),
	}
	if resource.Description.Valid {
		resp.Description = &resource.Description.String
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(resp)
}

func (h *Handler) Get(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	resource, err := h.app.Queries.GetResourceWithOwner(r.Context(), int32(id))
	if err != nil {
		http.Error(w, "resource not found", http.StatusNotFound)
		return
	}

	files, err := h.app.Queries.ListFilesByResource(r.Context(), int32(id))
	if err != nil {
		log.Printf("Failed to list files: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	resp := buildResourceResponse(resource, files)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (h *Handler) ListBySubject(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	limit := 10
	offset := 0
	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 {
			limit = v
		}
	}
	if o := r.URL.Query().Get("offset"); o != "" {
		if v, err := strconv.Atoi(o); err == nil && v >= 0 {
			offset = v
		}
	}

	resources, err := h.app.Queries.ListResourcesBySubjectWithOwnerPaginated(r.Context(), db.ListResourcesBySubjectWithOwnerPaginatedParams{
		SubjectID: int32(id),
		Limit:     int32(limit),
		Offset:    int32(offset),
	})
	if err != nil {
		log.Printf("Failed to list resources: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	resp := make([]ResourceResponse, 0, len(resources))
	for _, res := range resources {
		files, err := h.app.Queries.ListFilesByResource(r.Context(), res.ID)
		if err != nil {
			log.Printf("Failed to list files for resource %d: %v", res.ID, err)
			http.Error(w, "database error", http.StatusInternalServerError)
			return
		}

		fileResponses := make([]FileResponse, 0, len(files))
		for _, f := range files {
			fileResponses = append(fileResponses, FileResponse{
				ID:       f.ID,
				FileName: f.FileName,
				FileSize: f.FileSize,
			})
		}

		rr := ResourceResponse{
			ID:            res.ID,
			Title:         res.Title,
			Files:         fileResponses,
			CreatedAt:     res.CreatedAt.Time.Format(time.RFC3339),
			DownloadCount: res.DownloadCount,
			Owner: &Owner{
				ID:       res.OwnerID,
				Username: res.OwnerUsername,
				Email:    res.OwnerEmail,
			},
		}
		if res.Description.Valid {
			rr.Description = &res.Description.String
		}

		resp = append(resp, rr)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (h *Handler) ListByUser(w http.ResponseWriter, r *http.Request) {
	username := chi.URLParam(r, "username")

	user, err := h.app.Queries.GetUserByUsername(r.Context(), username)
	if err != nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	resources, err := h.app.Queries.ListResourcesByOwnerWithSubject(r.Context(), user.ID)
	if err != nil {
		log.Printf("Failed to list resources for user %s: %v", username, err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	resp := make([]ResourceResponse, 0, len(resources))
	for _, res := range resources {
		files, err := h.app.Queries.ListFilesByResource(r.Context(), res.ID)
		if err != nil {
			log.Printf("Failed to list files for resource %d: %v", res.ID, err)
			http.Error(w, "database error", http.StatusInternalServerError)
			return
		}

		fileResponses := make([]FileResponse, 0, len(files))
		for _, f := range files {
			fileResponses = append(fileResponses, FileResponse{
				ID:       f.ID,
				FileName: f.FileName,
				FileSize: f.FileSize,
			})
		}

		rr := ResourceResponse{
			ID:            res.ID,
			Title:         res.Title,
			Files:         fileResponses,
			CreatedAt:     res.CreatedAt.Time.Format(time.RFC3339),
			DownloadCount: res.DownloadCount,
			Owner: &Owner{
				ID:       res.OwnerID,
				Username: res.OwnerUsername,
				Email:    res.OwnerEmail,
			},
			Subject: &SubjectInfo{
				ID:   res.SubjectID,
				Name: res.SubjectName,
			},
		}
		if res.Description.Valid {
			rr.Description = &res.Description.String
		}
		resp = append(resp, rr)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (h *Handler) Download(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	resource, err := h.app.Queries.GetResource(r.Context(), int32(id))
	if err != nil {
		http.Error(w, "resource not found", http.StatusNotFound)
		return
	}

	files, err := h.app.Queries.ListFilesByResource(r.Context(), int32(id))
	if err != nil || len(files) == 0 {
		http.Error(w, "no files found", http.StatusNotFound)
		return
	}

	if err := h.app.Queries.IncrementDownloadCount(r.Context(), int32(id)); err != nil {
		log.Printf("Failed to increment download count for resource %d: %v", id, err)
	}

	// Single file: redirect to presigned URL
	if len(files) == 1 {
		presigned, err := h.app.Storage.GetPresignedURL(r.Context(), files[0].S3Key, 15*time.Minute, files[0].FileName)
		if err != nil {
			log.Printf("Failed to generate presigned URL: %v", err)
			http.Error(w, "download error", http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, presigned, http.StatusTemporaryRedirect)
		return
	}

	// Multiple files: stream zip
	filename := strings.ReplaceAll(resource.Title, " ", "_") + ".zip"
	w.Header().Set("Content-Type", "application/zip")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, filename))

	zw := zip.NewWriter(w)
	defer zw.Close()

	for _, file := range files {
		obj, _, err := h.app.Storage.GetObject(r.Context(), file.S3Key)
		if err != nil {
			log.Printf("Failed to get S3 object %s: %v", file.S3Key, err)
			return
		}

		header := &zip.FileHeader{
			Name:   file.FileName,
			Method: zip.Store,
		}
		header.Modified = file.CreatedAt.Time

		writer, err := zw.CreateHeader(header)
		if err != nil {
			obj.Close()
			log.Printf("Failed to create zip entry: %v", err)
			return
		}

		buf := make([]byte, 32*1024)
		for {
			n, readErr := obj.Read(buf)
			if n > 0 {
				if _, writeErr := writer.Write(buf[:n]); writeErr != nil {
					obj.Close()
					log.Printf("Failed to write to zip: %v", writeErr)
					return
				}
			}
			if readErr != nil {
				break
			}
		}
		obj.Close()
	}
}

func (h *Handler) DownloadFile(w http.ResponseWriter, r *http.Request) {
	fileIDStr := chi.URLParam(r, "fileId")
	fileID, err := strconv.Atoi(fileIDStr)
	if err != nil {
		http.Error(w, "invalid file id", http.StatusBadRequest)
		return
	}

	file, err := h.app.Queries.GetResourceFile(r.Context(), int32(fileID))
	if err != nil {
		http.Error(w, "file not found", http.StatusNotFound)
		return
	}

	obj, size, err := h.app.Storage.GetObject(r.Context(), file.S3Key)
	if err != nil {
		log.Printf("Failed to get object: %v", err)
		http.Error(w, "download error", http.StatusInternalServerError)
		return
	}
	defer obj.Close()

	contentType := mime.TypeByExtension(filepath.Ext(file.FileName))
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Content-Length", strconv.FormatInt(size, 10))
	w.Header().Set("Content-Disposition", fmt.Sprintf(`inline; filename="%s"`, file.FileName))
	io.Copy(w, obj)
}

func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value(auth.CtxUserID).(int32)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

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

	err = h.app.Queries.DeleteResource(r.Context(), db.DeleteResourceParams{
		ID:      int32(id),
		OwnerID: userID,
	})
	if err != nil {
		log.Printf("Failed to delete resource %d: %v", id, err)
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

func (h *Handler) cleanupS3(r *http.Request, keys []string) {
	if len(keys) == 0 {
		return
	}
	if err := h.app.Storage.DeleteMultiple(r.Context(), keys); err != nil {
		log.Printf("Failed to cleanup S3 objects: %v", err)
	}
}

func buildResourceResponse(res db.GetResourceWithOwnerRow, files []db.ResourceFile) ResourceResponse {
	fileResponses := make([]FileResponse, 0, len(files))
	for _, f := range files {
		fileResponses = append(fileResponses, FileResponse{
			ID:       f.ID,
			FileName: f.FileName,
			FileSize: f.FileSize,
		})
	}

	rr := ResourceResponse{
		ID:            res.ID,
		Title:         res.Title,
		Files:         fileResponses,
		CreatedAt:     res.CreatedAt.Time.Format(time.RFC3339),
		DownloadCount: res.DownloadCount,
		Owner: &Owner{
			ID:       res.OwnerID,
			Username: res.OwnerUsername,
			Email:    res.OwnerEmail,
		},
	}
	if res.Description.Valid {
		rr.Description = &res.Description.String
	}
	return rr
}

func (h *Handler) Search(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	if query == "" {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode([]ResourceResponse{})
		return
	}

	results, err := h.app.Queries.SearchResources(r.Context(), query)
	if err != nil {
		log.Printf("Failed to search resources: %v", err)
		http.Error(w, "database error", http.StatusInternalServerError)
		return
	}

	resp := make([]ResourceResponse, 0, len(results))
	for _, res := range results {
		files, err := h.app.Queries.ListFilesByResource(r.Context(), res.ID)
		if err != nil {
			log.Printf("Failed to list files for resource %d: %v", res.ID, err)
			continue
		}

		fileResponses := make([]FileResponse, 0, len(files))
		for _, f := range files {
			fileResponses = append(fileResponses, FileResponse{
				ID:       f.ID,
				FileName: f.FileName,
				FileSize: f.FileSize,
			})
		}

		rr := ResourceResponse{
			ID:            res.ID,
			Title:         res.Title,
			Files:         fileResponses,
			CreatedAt:     res.CreatedAt.Time.Format(time.RFC3339),
			DownloadCount: res.DownloadCount,
			Owner: &Owner{
				ID:       res.OwnerID,
				Username: res.OwnerUsername,
				Email:    res.OwnerEmail,
			},
			Subject: &SubjectInfo{
				ID:   res.SubjectID,
				Name: res.SubjectName,
			},
			Study: &StudyInfo{
				ID:   res.StudyID,
				Name: res.StudyName,
			},
		}
		if res.Description.Valid {
			rr.Description = &res.Description.String
		}
		resp = append(resp, rr)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func sanitizeFilename(name string) string {
	name = filepath.Base(name)
	name = strings.ReplaceAll(name, " ", "_")
	name = strings.Map(func(r rune) rune {
		if r == '.' || r == '-' || r == '_' || (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') {
			return r
		}
		return '_'
	}, name)
	return name
}
