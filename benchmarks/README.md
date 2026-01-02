# Obelisk vs Chroma Benchmarks

Benchmark suite comparing [Obelisk](https://github.com/watzon/obelisk) (Crystal) against [Chroma](https://github.com/alecthomas/chroma) (Go) for syntax highlighting performance.

## Setup

### Prerequisites

- Crystal 1.0+
- Go 1.21+

### 1. Fetch Test Data

Download real-world source code files from popular open-source repositories:

```bash
./scripts/fetch_benchmark_data.sh
```

This downloads sample files to `benchmarks/data/` (which is gitignored).

### 2. Install Go Dependencies

```bash
cd benchmarks/go
go mod download
cd ../..
```

## Running Benchmarks

### Obelisk (Crystal)

```bash
crystal run benchmarks/crystal/benchemark.cr
```

To save results for comparison:
```bash
crystal run benchmarks/crystal/benchemark.cr > obelisk_results.csv
```

### Chroma (Go)

```bash
cd benchmarks/go
go test -bench=. -benchmem
```

The Go benchmarks use the standard `testing.B` framework and output:
- `ns/op` - nanoseconds per operation
- `B/s` - bytes per second (throughput)
- `allocs/op` - allocations per operation
- `B/op` - bytes allocated per operation

## Comparing Results

After running both benchmark suites, compare the results:

```bash
crystal run benchmarks/compare.cr obelisk_results.csv chroma_results.csv
```

This outputs a side-by-side comparison showing:
- Execution time for each test file
- Latency (time to first token)
- Throughput (MB/s)
- Winner and speedup/slowdown ratio
- Overall averages

## Metrics

| Metric | Description |
|--------|-------------|
| **Time** | Average milliseconds to highlight a file |
| **Latency** | Milliseconds until first token is emitted |
| **Throughput** | Megabytes per second processed |

## Languages Benchmarked

- JavaScript
- Python
- JSON
- YAML
- Ruby
- Go
- Rust
- HTML
- CSS
- SQL
- Shell

## Test Data

Test files are sourced from real-world projects:
- **Small**: 1-5 KB (simple modules, configs)
- **Medium**: 10-50 KB (typical source files)
- **Large**: 100+ KB (complex modules, generated code)

See `scripts/fetch_benchmark_data.sh` for specific sources.

## Notes

- Both libraries use similar highlighting strategies (lexer → formatter)
- Chroma has a larger lexer ecosystem (hundreds of languages)
- Obelisk focuses on core languages with Crystal performance
- Results may vary based on:
  - Compilation settings (release vs debug)
  - System load during benchmarking
  - CPU throttling/power management
  - Compiler optimizations applied

For accurate comparisons:
- Run benchmarks multiple times
- Ensure system is idle
- Use release builds for Crystal
