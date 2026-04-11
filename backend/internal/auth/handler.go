package auth

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strings"

	db "github.com/DCCXXV/Nemsy/backend/internal/db/generated"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"golang.org/x/oauth2"
	"google.golang.org/api/idtoken"
)

type Handler struct {
	OAuthConfig    *oauth2.Config
	JWTSecret      []byte
	StateStore     *StateStore
	Queries        db.Querier
	FrontendOrigin string
}

func NewHandler(cfg *oauth2.Config, secret []byte, store *StateStore, queries db.Querier, frontendOrigin string) *Handler {
	return &Handler{
		OAuthConfig:    cfg,
		JWTSecret:      secret,
		StateStore:     store,
		Queries:        queries,
		FrontendOrigin: frontendOrigin,
	}
}

type UserInfo struct {
	GoogleSub string
	Email     string
	Hd        string
}

func (h *Handler) LoginHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	w.Header().Set("Pragma", "no-cache")
	w.Header().Set("Expires", "0")

	state := generateState()
	h.StateStore.Put(state)

	url := h.OAuthConfig.AuthCodeURL(
		state,
		oauth2.AccessTypeOffline,
		oauth2.SetAuthURLParam("prompt", "select_account"),
	)
	http.Redirect(w, r, url, http.StatusTemporaryRedirect)
}

func (h *Handler) CallbackHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	w.Header().Set("Pragma", "no-cache")
	w.Header().Set("Expires", "0")

	returnedState := r.URL.Query().Get("state")
	if !h.StateStore.Check(returnedState) {
		http.Error(w, "Invalid OAuth state", http.StatusUnauthorized)
		return
	}

	code := r.URL.Query().Get("code")
	token, err := h.OAuthConfig.Exchange(context.Background(), code)
	if err != nil {
		log.Println("OAuth exchange failed")
		http.Error(w, "Failed exchange", http.StatusUnauthorized)
		return
	}

	rawIDToken, ok := token.Extra("id_token").(string)
	if !ok {
		http.Error(w, "ID Token missing in OAuth2 response", http.StatusInternalServerError)
		return
	}

	payload, err := idtoken.Validate(context.Background(), rawIDToken, h.OAuthConfig.ClientID)
	if err != nil {
		http.Error(w, "Invalid ID Token: "+err.Error(), http.StatusUnauthorized)
		return
	}

	userInfo := ExtractUserInfo(payload.Claims)
	var user db.User
	newUser := false

	user, err = h.Queries.GetUserByEmail(r.Context(), userInfo.Email)
	if err == pgx.ErrNoRows {
		log.Println("Creating new user")

		var universityID pgtype.Int4
		domain := userInfo.Hd
		if domain == "" {
			parts := strings.Split(userInfo.Email, "@")
			if len(parts) == 2 {
				domain = parts[1]
			}
		}
		if domain != "" {
			uni, uniErr := h.Queries.GetUniversityByDomainSuffix(r.Context(), domain)
			if uniErr == nil {
				universityID = pgtype.Int4{Int32: uni.ID, Valid: true}
			}
		}

		base := strings.Split(userInfo.Email, "@")[0]
		for i := 0; i <= 100; i++ {
			username := base
			if i > 0 {
				username = fmt.Sprintf("%s%d", base, i)
			}
			user, err = h.Queries.CreateUser(r.Context(), db.CreateUserParams{
				GoogleSub:    userInfo.GoogleSub,
				StudyID:      pgtype.Int4{Valid: false},
				Email:        userInfo.Email,
				Username:     username,
				Hd:           stringToPgText(userInfo.Hd),
				UniversityID: universityID,
			})
			if err == nil {
				break
			}
			var pgErr *pgconn.PgError
			if errors.As(err, &pgErr) && pgErr.Code == "23505" && strings.Contains(pgErr.ConstraintName, "username") {
				continue
			}
			break
		}
		newUser = true
	}
	if err != nil {
		log.Println("Database error:", err)
		http.Error(w, "Could not save user", http.StatusInternalServerError)
		return
	}

	jwtToken, err := GenerateJWTWithUserID(userInfo, int(user.ID), user.Role, h.JWTSecret)
	if err != nil {
		http.Error(w, "Could not create session token", http.StatusInternalServerError)
		return
	}

	http.SetCookie(w, &http.Cookie{
		Name:     "session_token",
		Value:    jwtToken,
		Path:     "/",
		Domain:   ".nemsy.org",
		HttpOnly: true,
		Secure:   true,
		SameSite: http.SameSiteLaxMode,
	})

	if newUser {
		http.Redirect(w, r, h.FrontendOrigin+"/auth", http.StatusSeeOther)
	} else {
		http.Redirect(w, r, h.FrontendOrigin+"/", http.StatusSeeOther)
	}
}

func (h *Handler) LogoutHandler(w http.ResponseWriter, r *http.Request) {
	http.SetCookie(w, &http.Cookie{
		Name:     "session_token",
		Value:    "",
		Path:     "/",
		Domain:   ".nemsy.org",
		HttpOnly: true,
		Secure:   true,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   -1,
	})
	w.WriteHeader(http.StatusOK)
}
