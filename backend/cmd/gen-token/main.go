// Generates a signed JWT for k6 load testing
// Usage: JWT_SECRET=... go run ./cmd/gen-token <user_id>
package main

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func main() {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		fmt.Fprintln(os.Stderr, "JWT_SECRET not set")
		os.Exit(1)
	}

	userID := 1
	if len(os.Args) > 1 {
		id, err := strconv.Atoi(os.Args[1])
		if err != nil {
			fmt.Fprintln(os.Stderr, "invalid user_id:", os.Args[1])
			os.Exit(1)
		}
		userID = id
	}

	claims := jwt.MapClaims{
		"sub":     "k6-test-subject",
		"email":   "k6test@ucm.es",
		"hd":      "ucm.es",
		"user_id": userID,
		"role":    "user",
		"exp":     time.Now().Add(24 * time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString([]byte(secret))
	if err != nil {
		fmt.Fprintln(os.Stderr, "sign error:", err)
		os.Exit(1)
	}
	fmt.Println(signed)
}
