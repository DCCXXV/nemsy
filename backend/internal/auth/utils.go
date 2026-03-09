package auth

import (
	"crypto/rand"
	"encoding/base64"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

func GoogleOAuthConfig() *oauth2.Config {
	return &oauth2.Config{
		ClientID:     os.Getenv("GOOGLE_CLIENT_ID"),
		ClientSecret: os.Getenv("GOOGLE_CLIENT_SECRET"),
		RedirectURL:  os.Getenv("GOOGLE_REDIRECT_URL"),
		Scopes: []string{
			"openid",
			"email",
			"profile",
		},
		Endpoint: google.Endpoint,
	}
}

func generateState() string {
	b := make([]byte, 16)
	_, err := rand.Read(b)
	if err != nil {
		return "defaultstate"
	}

	return base64.URLEncoding.EncodeToString(b)
}

func GenerateJWT(userInfo UserInfo, secret []byte) (string, error) {
	claims := jwt.MapClaims{
		"sub":   userInfo.GoogleSub,
		"email": userInfo.Email,
		"hd":    userInfo.Hd,
		"exp":   time.Now().Add(7 * 24 * time.Hour).Unix(),
		"iat":   time.Now().Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secret)
}

func GenerateJWTWithUserID(info UserInfo, userID int, secret []byte) (string, error) {
	claims := jwt.MapClaims{
		"sub":     info.GoogleSub,
		"email":   info.Email,
		"hd":      info.Hd,
		"user_id": userID,
		"exp":     time.Now().Add(7 * 24 * time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secret)
}

func ExtractUserInfo(claims map[string]any) UserInfo {
	info := UserInfo{}

	if sub, ok := claims["sub"].(string); ok {
		info.GoogleSub = sub
	}

	if email, ok := claims["email"].(string); ok {
		info.Email = email
	}

	if hd, ok := claims["hd"].(string); ok {
		info.Hd = hd
	}

	return info
}

func stringToPgText(s string) pgtype.Text {
	if s == "" {
		return pgtype.Text{Valid: false}
	}
	return pgtype.Text{
		String: s,
		Valid:  true,
	}
}
