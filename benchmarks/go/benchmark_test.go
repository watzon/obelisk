package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"testing"

	"github.com/alecthomas/chroma/quick"
	"github.com/alecthomas/chroma/lexers"
)

// TestFile represents a source file to benchmark
type TestFile struct {
	Path     string
	Language string
	Name     string
	Source   string
	SizeKB   float64
}

// Load test files from the data directory
func loadTestFiles(dataDir string) []TestFile {
	var files []TestFile

	langMap := map[string]string{
		"javascript": "javascript",
		"python":     "python",
		"json":       "json",
		"yaml":       "yaml",
		"ruby":       "ruby",
		"go":         "go",
		"rust":       "rust",
		"html":       "html",
		"css":        "css",
		"sql":        "sql",
		"shell":      "shell",
	}

	for dir, lang := range langMap {
		pattern := filepath.Join(dataDir, dir, "*")
		matches, _ := filepath.Glob(pattern)
		for _, path := range matches {
			info, err := os.Stat(path)
			if err != nil || info.IsDir() {
				continue
			}

			source, err := os.ReadFile(path)
			if err != nil {
				continue
			}

			name := fmt.Sprintf("%s/%s", dir, filepath.Base(path))
			sizeKB := float64(len(source)) / 1024.0

			files = append(files, TestFile{
				Path:     path,
				Language: lang,
				Name:     name,
				Source:   string(source),
				SizeKB:   sizeKB,
			})
		}
	}

	return files
}

// BenchmarkHighlight benchmarks the highlighting performance
func BenchmarkHighlight(b *testing.B) {
	files := loadTestFiles("../data")
	if len(files) == 0 {
		b.Skip("No test files found. Run fetch_benchmark_data.sh first")
	}

	for _, file := range files {
		b.Run(file.Name, func(b *testing.B) {
			b.ReportMetric(float64(file.SizeKB), "size_kb")
			b.ResetTimer()

			for i := 0; i < b.N; i++ {
				quick.Highlight(io.Discard, file.Source, file.Language, "html", "github")
			}
		})
	}
}

// BenchmarkLatency benchmarks time to first token
func BenchmarkLatency(b *testing.B) {
	files := loadTestFiles("../data")
	if len(files) == 0 {
		b.Skip("No test files found. Run fetch_benchmark_data.sh first")
	}

	for _, file := range files {
		b.Run(file.Name, func(b *testing.B) {
			lexer := lexers.Get(file.Language)
			if lexer == nil {
				b.Skip("Lexer not found")
			}

			b.ResetTimer()

			for i := 0; i < b.N; i++ {
				iter, _ := lexer.Tokenise(nil, file.Source)
				iter()  // Iterator is a function type
			}
		})
	}
}
