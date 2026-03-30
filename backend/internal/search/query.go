package search

import (
	"strings"
	"unicode"

	"golang.org/x/text/runes"
	"golang.org/x/text/transform"
	"golang.org/x/text/unicode/norm"
)

var remover = transform.Chain(norm.NFD, runes.Remove(runes.In(unicode.Mn)), norm.NFC)

// PrefixQuery converts user input into a tsquery with prefix matching
func PrefixQuery(input string) string {
	stripped, _, _ := transform.String(remover, input)
	words := strings.Fields(stripped)
	parts := make([]string, 0, len(words))
	for _, w := range words {
		sanitized := sanitizeWord(w)
		if sanitized != "" {
			parts = append(parts, sanitized+":*")
		}
	}
	if len(parts) == 0 {
		return ""
	}
	return strings.Join(parts, " & ")
}

// sanitizeWord removes characters that are not letters, digits, or underscores
// to prevent tsquery syntax errors.
func sanitizeWord(w string) string {
	var b strings.Builder
	for _, r := range w {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			b.WriteRune(r)
		}
	}
	return b.String()
}
