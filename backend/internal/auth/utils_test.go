package auth

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func TestJWTGenerationAndParsing(t *testing.T) {
	secret := []byte("mydevsupersecret")

	userInfo := UserInfo{
		GoogleSub: "123456789",
		Email:     "test@ucm.es",
		Hd:        "ucm.es",
	}

	tokenStr, err := GenerateJWT(userInfo, secret)
	if err != nil {
		t.Fatal("Error generating JWT:", err)
	}

	token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (any, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			t.Errorf("Unexpected signing method: %v", token.Header["alg"])
		}
		return secret, nil
	})

	if err != nil {
		t.Fatal("Parse failed:", err)
	}

	if !token.Valid {
		t.Fatal("Token not valid")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		t.Fatal("Could not cast claims to MapClaims")
	}

	if claims["email"] != userInfo.Email {
		t.Errorf("Expected email %s, got %v", userInfo.Email, claims["email"])
	}

	if claims["sub"] != userInfo.GoogleSub {
		t.Errorf("Expected sub %s, got %v", userInfo.GoogleSub, claims["sub"])
	}

	if claims["hd"] != userInfo.Hd {
		t.Errorf("Expected hd %s, got %v", userInfo.Hd, claims["hd"])
	}

	if _, ok := claims["exp"]; !ok {
		t.Error("Token missing exp claim")
	}

	if _, ok := claims["iat"]; !ok {
		t.Error("Token missing iat claim")
	}
}

func TestExtractUserInfo(t *testing.T) {
	claims := map[string]any{
		"sub":   "123456789",
		"email": "test@example.com",
		"hd":    "example.com",
	}

	userInfo := ExtractUserInfo(claims)

	if userInfo.GoogleSub != "123456789" {
		t.Errorf("Expected GoogleSub '123456789', got '%s'", userInfo.GoogleSub)
	}

	if userInfo.Email != "test@example.com" {
		t.Errorf("Expected Email 'test@example.com', got '%s'", userInfo.Email)
	}

	if userInfo.Hd != "example.com" {
		t.Errorf("Expected Hd 'example.com', got '%s'", userInfo.Hd)
	}
}

func TestExtractUserInfo_MissingFields(t *testing.T) {
	claims := map[string]any{
		"email": "test@example.com",
	}

	userInfo := ExtractUserInfo(claims)

	if userInfo.Email != "test@example.com" {
		t.Errorf("Expected Email 'test@example.com', got '%s'", userInfo.Email)
	}

	if userInfo.GoogleSub != "" {
		t.Errorf("Expected empty GoogleSub, got '%s'", userInfo.GoogleSub)
	}

	if userInfo.Hd != "" {
		t.Errorf("Expected empty Hd, got '%s'", userInfo.Hd)
	}
}

func TestExtractUserInfo_WrongTypes(t *testing.T) {
	claims := map[string]any{
		"sub":   123,
		"email": "test@example.com",
	}

	userInfo := ExtractUserInfo(claims)

	if userInfo.Email != "test@example.com" {
		t.Errorf("Expected Email 'test@example.com', got '%s'", userInfo.Email)
	}

	if userInfo.GoogleSub != "" {
		t.Errorf("Expected empty GoogleSub (wrong type), got '%s'", userInfo.GoogleSub)
	}
}

func TestGenerateStateUnique(t *testing.T) {
	s1 := generateState()
	s2 := generateState()

	if s1 == s2 {
		t.Error("Expected states to be different")
	}

	if s1 == "" || s2 == "" {
		t.Error("Expected non-empty states")
	}

	if len(s1) < 20 {
		t.Errorf("State too short: %d characters", len(s1))
	}
}

func TestAuthMiddleware_NoCookie(t *testing.T) {
	req := httptest.NewRequest("GET", "/protected", nil)
	rr := httptest.NewRecorder()

	mw := &AuthMiddleware{Secret: []byte("testsecret")}

	handler := mw.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("Expected 401 Unauthorized, got %d", rr.Code)
	}
}

func TestAuthMiddleware_ValidToken(t *testing.T) {
	secret := []byte("testsecret")

	userInfo := UserInfo{
		GoogleSub: "123456",
		Email:     "test@example.com",
	}

	tokenStr, err := GenerateJWTWithUserID(userInfo, 42, secret)
	if err != nil {
		t.Fatal("Error generating JWT:", err)
	}

	req := httptest.NewRequest("GET", "/protected", nil)
	req.AddCookie(&http.Cookie{
		Name:  "session_token",
		Value: tokenStr,
	})

	rr := httptest.NewRecorder()

	mw := &AuthMiddleware{Secret: secret}

	handlerCalled := false
	var contextUserInfo UserInfo

	handler := mw.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handlerCalled = true

		if info, ok := r.Context().Value(CtxUserInfo).(UserInfo); ok {
			contextUserInfo = info
		}

		w.WriteHeader(http.StatusOK)
	}))

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected 200 OK, got %d", rr.Code)
	}

	if !handlerCalled {
		t.Error("Protected handler was not called")
	}

	if contextUserInfo.Email != userInfo.Email {
		t.Errorf("Expected email '%s' in context, got '%s'", userInfo.Email, contextUserInfo.Email)
	}

	if contextUserInfo.GoogleSub != userInfo.GoogleSub {
		t.Errorf("Expected GoogleSub '%s' in context, got '%s'", userInfo.GoogleSub, contextUserInfo.GoogleSub)
	}
}

func TestAuthMiddleware_InvalidToken(t *testing.T) {
	req := httptest.NewRequest("GET", "/protected", nil)
	req.AddCookie(&http.Cookie{
		Name:  "session_token",
		Value: "invalid.token.here",
	})

	rr := httptest.NewRecorder()

	mw := &AuthMiddleware{Secret: []byte("testsecret")}

	handler := mw.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("Handler should not be called with invalid token")
		w.WriteHeader(http.StatusOK)
	}))

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("Expected 401 Unauthorized, got %d", rr.Code)
	}
}

func TestAuthMiddleware_WrongSecret(t *testing.T) {
	tokenStr, err := GenerateJWT(UserInfo{Email: "test@example.com"}, []byte("secret1"))
	if err != nil {
		t.Fatal("Error generating JWT:", err)
	}

	req := httptest.NewRequest("GET", "/protected", nil)
	req.AddCookie(&http.Cookie{
		Name:  "session_token",
		Value: tokenStr,
	})

	rr := httptest.NewRecorder()

	mw := &AuthMiddleware{Secret: []byte("secret2")}

	handler := mw.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("Handler should not be called with wrong secret")
		w.WriteHeader(http.StatusOK)
	}))

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("Expected 401 Unauthorized, got %d", rr.Code)
	}
}

func TestStateStore(t *testing.T) {
	store := NewStateStore(time.Second * 30)

	state := "test-state-123"
	store.Put(state)

	if !store.Check(state) {
		t.Error("State should be valid immediately after Put")
	}

	if store.Check(state) {
		t.Error("State should only be valid once")
	}
}

func TestStateStore_Invalid(t *testing.T) {
	store := NewStateStore(time.Second * 30)

	if store.Check("nonexistent-state") {
		t.Error("Nonexistent state should not be valid")
	}
}
