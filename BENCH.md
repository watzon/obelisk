# Benchmark Suite: Obelisk vs Chroma

Benchmark suite comparing Obelisk (Crystal) against Chroma (Go) for syntax highlighting performance.

## Quick Start

```bash
# Download test data (21 files across 11 languages)
./scripts/fetch_benchmark_data.sh

# Run Obelisk benchmarks
crystal run benchmarks/crystal/benchemark.cr

# Run Chroma benchmarks (requires Go)
cd benchmarks/go && go test -bench=. -benchmem

# Compare results
crystal run benchmarks/compare.cr obelisk.csv chroma.csv
```

## Test Data

All test files are real source code from popular open-source repositories:

| Language   | Files                                                | Source                                       |
| ---------- | ---------------------------------------------------- | -------------------------------------------- |
| JavaScript | assert.js (23KB), lodash.js (544KB), vue.js (344KB)  | nodejs/node, lodash/lodash, vuejs/vue        |
| Python     | heapq.py (23KB), http.py (15KB), flask-app.py (86KB) | python/cpython, django/django, pallets/flask |
| JSON       | npm-package.json (7KB), vscode-package.json (10KB)   | npm/cli, microsoft/vscode                    |
| YAML       | github-action.yml (347B), rust-gitignore.yml (684B)  | actions/javascript-action, github/gitignore  |
| Ruby       | hash-keys.rb (5KB), base.rb (15KB)                   | rails/rails, rubocop/rubocop                 |
| Go         | context.go (25KB), http-server.go (131KB)            | golang/go                                    |
| Rust       | string.rs (91KB)                                     | rust-lang/rust                               |
| HTML       | github-markdown.html (63KB)                          | sindresorhus/github-markdown-css             |
| CSS        | bootstrap.css (280KB), github.css (2KB)              | twbs/bootstrap, highlightjs/highlight.js     |
| SQL        | pg_proc.dat (659KB)                                  | postgres/postgres                            |
| Shell      | nvm.sh (150KB), nvm-install.sh (15KB)                | creationix/nvm, nvm-sh/nvm                   |

## Initial Findings

Obelisk benchmark results reveal performance issues:

| Language    | File Size  | Time      | Notes              |
| ----------- | ---------- | --------- | ------------------ |
| YAML        | 0.3-0.7 KB | 0.5-3ms   | Good               |
| CSS (small) | 2 KB       | 5.6ms     | Good               |
| Ruby        | 4.6-15 KB  | 18-151ms  | Reasonable         |
| JSON        | 6.5-9.6 KB | 22-30ms   | OK                 |
| Shell       | 14.6 KB    | 151ms     | Acceptable         |
| Python      | 15-86 KB   | 88-4544ms | **Poor scaling**   |
| JavaScript  | 22.5 KB    | 773ms     | **Slow**           |
| Go          | 24.4 KB    | 455ms     | Slow               |
| HTML        | 61.9 KB    | 5850ms    | **Extremely slow** |

### Performance Issues Identified

1. **HTML Lexer** - Takes ~5.8 seconds for a 62KB file. This is ~100x slower than expected.
2. **Python Lexer** - Shows quadratic or worse scaling behavior.
3. **JavaScript Lexer** - Slower than expected for a 22KB file.

These are prime candidates for optimization work.

## Directory Structure

```
benchmarks/
├── crystal/
│   └── benchemark.cr       # Crystal benchmark implementation
├── go/
│   ├── benchmark_test.go   # Go benchmark for Chroma
│   └── go.mod              # Go module with Chroma dependency
├── compare.cr              # Comparison script
├── data/                   # Test files (gitignored)
└── README.md               # Full documentation

scripts/
└── fetch_benchmark_data.sh # Downloads test files from GitHub
```

## Metrics Measured

| Metric         | Description                                              |
| -------------- | -------------------------------------------------------- |
| **Time**       | Average milliseconds to highlight a file (10 iterations) |
| **Latency**    | Milliseconds until first token is emitted                |
| **Throughput** | Megabytes per second processed                           |

## Next Steps

1. Fix HTML lexer performance (critical)
2. Investigate Python lexer scaling
3. Profile JavaScript lexer for bottlenecks
4. Run full Chroma comparison once Obelisk is optimized
