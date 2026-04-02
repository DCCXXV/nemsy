package auth

import (
	"context"
	"log"
	"net/http"

	"github.com/golang-jwt/jwt/v5"
)

type ctxKey string

const CtxUserInfo ctxKey = "user_info"
const CtxUserID ctxKey = "userID"
const CtxUserRole ctxKey = "userRole"

type AuthMiddleware struct {
	Secret []byte
}

func (a *AuthMiddleware) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cookie, err := r.Cookie("session_token")
		if err != nil {
			log.Println("AuthMiddleware: no session cookie")
			http.Error(w, "Unauthorized: no session cookie", http.StatusUnauthorized)
			return
		}

		tokenStr := cookie.Value
		log.Println("AuthMiddleware: got cookie", tokenStr)
		log.Printf("Middleware using secret: %q", a.Secret)

		token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (any, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				log.Println("AuthMiddleware: wrong signing method")
				return nil, jwt.ErrSignatureInvalid
			}
			return a.Secret, nil
		})
		if err != nil {
			log.Println("AuthMiddleware: jwt.Parse error:", err)
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}
		if token == nil || !token.Valid {
			log.Println("AuthMiddleware: token invalid or nil")
			http.Error(w, "Invalid or expired token", http.StatusUnauthorized)
			return
		}

		log.Println("AuthMiddleware: token is valid")

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			log.Println("AuthMiddleware: could not cast claims to MapClaims")
			http.Error(w, "Invalid token claims", http.StatusUnauthorized)
			return
		}

		log.Printf("AuthMiddleware: claims = %#v\n", claims)
		userInfo := ExtractUserInfo(claims)

		userIDClaim, ok := claims["user_id"].(float64)
		if !ok {
			log.Println("AuthMiddleware: missing or invalid user_id claim")
			http.Error(w, "Invalid session token", http.StatusUnauthorized)
			return
		}
		userID := int32(userIDClaim)

		log.Printf("AuthMiddleware: user_id = %d", userID)

		role, _ := claims["role"].(string)
		if role == "" {
			role = "user"
		}

		ctx := context.WithValue(r.Context(), CtxUserInfo, userInfo)
		ctx = context.WithValue(ctx, CtxUserID, userID)
		ctx = context.WithValue(ctx, CtxUserRole, role)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}
