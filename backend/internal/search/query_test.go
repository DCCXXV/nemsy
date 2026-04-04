package search

import "testing"

func TestPrefixQuery(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{
			name:  "single word",
			input: "matematicas",
			want:  "matematicas:*",
		},
		{
			name:  "multiple words joined with AND",
			input: "algebra lineal",
			want:  "algebra:* & lineal:*",
		},
		{
			name:  "strips accents",
			input: "programación",
			want:  "programacion:*",
		},
		{
			name:  "removes special characters",
			input: "hello! world?",
			want:  "hello:* & world:*",
		},
		{
			name:  "empty input returns empty",
			input: "",
			want:  "",
		},
		{
			name:  "only special characters returns empty",
			input: "!!! ???",
			want:  "",
		},
		{
			name:  "extra whitespace is trimmed",
			input: "  fisica   cuantica  ",
			want:  "fisica:* & cuantica:*",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := PrefixQuery(tt.input)
			if got != tt.want {
				t.Errorf("PrefixQuery(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestSanitizeWord(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"hello", "hello"},
		{"hello!", "hello"},
		{"c++", "c"}, //!
		{"año2024", "año2024"},
		{"", ""},
		{"!!!!", ""},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := sanitizeWord(tt.input)
			if got != tt.want {
				t.Errorf("sanitizeWord(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}
