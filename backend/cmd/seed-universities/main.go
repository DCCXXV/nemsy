package main

import (
	"archive/tar"
	"bufio"
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

const swotURL = "https://github.com/JetBrains/swot/archive/refs/heads/master.tar.gz"
const domainsPrefix = "swot-master/lib/domains/"

type university struct {
	name   string
	domain string
}

func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL is required")
	}

	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer pool.Close()

	log.Println("Downloading Swot data...")
	universities, err := downloadAndParse()
	if err != nil {
		log.Fatalf("Failed to download Swot data: %v", err)
	}
	log.Printf("Parsed %d universities from Swot", len(universities))

	log.Println("Seeding database...")
	inserted := 0
	skipped := 0
	for _, u := range universities {
		_, err := pool.Exec(ctx,
			`INSERT INTO universities (name, domain) VALUES ($1, $2) ON CONFLICT (domain) DO NOTHING`,
			u.name, u.domain,
		)
		if err != nil {
			log.Printf("Failed to insert %s (%s): %v", u.name, u.domain, err)
			continue
		}
		inserted++
	}
	skipped = len(universities) - inserted
	log.Printf("Done: %d inserted, %d skipped (duplicates)", inserted, skipped)
}

func downloadAndParse() ([]university, error) {
	resp, err := http.Get(swotURL)
	if err != nil {
		return nil, fmt.Errorf("download failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	gz, err := gzip.NewReader(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("gzip error: %w", err)
	}
	defer gz.Close()

	tr := tar.NewReader(gz)
	var universities []university

	for {
		header, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("tar error: %w", err)
		}

		if header.Typeflag != tar.TypeReg {
			continue
		}
		if !strings.HasPrefix(header.Name, domainsPrefix) {
			continue
		}
		if filepath.Ext(header.Name) != ".txt" {
			continue
		}

		/**
		 * extract domain from path
		 *
		 * e.g.:
		 * swot-master/lib/domains/es/ucm.txt -> ucm.es
		 */
		relPath := strings.TrimPrefix(header.Name, domainsPrefix)
		domain := pathToDomain(relPath)
		if domain == "" {
			continue
		}

		// get university name
		scanner := bufio.NewScanner(tr)
		name := ""
		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if line != "" {
				name = line
				break
			}
		}
		if name == "" {
			continue
		}

		universities = append(universities, university{name: name, domain: domain})
	}

	return universities, nil
}

// pathToDomain converts a Swot path like "es/ucm.txt" to "ucm.es"
// or "uk/ac/cam.txt" to "cam.ac.uk"
func pathToDomain(relPath string) string {
	relPath = strings.TrimSuffix(relPath, ".txt")
	parts := strings.Split(relPath, "/")
	if len(parts) == 0 {
		return ""
	}

	// [es, ucm] -> ucm.es
	reversed := make([]string, len(parts))
	for i, p := range parts {
		reversed[len(parts)-1-i] = p
	}
	return strings.Join(reversed, ".")
}
