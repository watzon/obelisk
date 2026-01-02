#!/usr/bin/env bash
# Fetch real-world source code files for benchmarking
# Downloads individual files from popular open-source repositories

set -e

BENCH_DIR="$(dirname "$0")/../benchmarks"
DATA_DIR="$BENCH_DIR/data"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Fetching benchmark data...${NC}"

# Ensure data directory exists
mkdir -p "$DATA_DIR"

# Function to download a file with validation
download_file() {
    local url="$1"
    local dest="$2"
    local name="$3"
    local min_size="${4:-100}"  # Minimum size in bytes (default 100)

    # Check if file exists and is large enough
    if [ -f "$dest" ]; then
        size=$(wc -c < "$dest" 2>/dev/null || echo 0)
        if [ "$size" -gt $min_size ]; then
            echo -e "${YELLOW}Skipping $name (already exists)${NC}"
            return
        fi
    fi

    echo "Downloading: $name"
    # Create parent directory
    mkdir -p "$(dirname "$dest")"
    temp_dest="${dest}.tmp"
    if curl -sL "$url" -o "$temp_dest"; then
        # Check file size
        size=$(wc -c < "$temp_dest" 2>/dev/null || echo 0)
        if [ "$size" -lt $min_size ]; then
            echo -e "${RED}  Failed: file too small ($size bytes)${NC}"
            rm -f "$temp_dest"
        else
            mv "$temp_dest" "$dest"
            echo -e "  ${GREEN}OK${NC} ($size bytes)"
        fi
    else
        echo -e "${RED}  Failed to download $name${NC}"
        rm -f "$temp_dest"
    fi
}

# JavaScript files
download_file \
    "https://raw.githubusercontent.com/nodejs/node/v20.x/lib/assert.js" \
    "$DATA_DIR/javascript/assert.js" \
    "javascript/assert.js (small)"

download_file \
    "https://raw.githubusercontent.com/lodash/lodash/4.17.21/lodash.js" \
    "$DATA_DIR/javascript/lodash.js" \
    "javascript/lodash.js (medium)" 10000

download_file \
    "https://raw.githubusercontent.com/vuejs/vue/v2.6.14/dist/vue.js" \
    "$DATA_DIR/javascript/vue.js" \
    "javascript/vue.js (large)" 50000

# Python files
download_file \
    "https://raw.githubusercontent.com/python/cpython/3.11/Lib/heapq.py" \
    "$DATA_DIR/python/heapq.py" \
    "python/heapq.py (small)"

download_file \
    "https://raw.githubusercontent.com/django/django/4.2/django/utils/http.py" \
    "$DATA_DIR/python/http.py" \
    "python/http.py (medium)" 5000

download_file \
    "https://raw.githubusercontent.com/pallets/flask/2.3.0/src/flask/app.py" \
    "$DATA_DIR/python/flask-app.py" \
    "python/flask-app.py (large)" 10000

# JSON files
download_file \
    "https://raw.githubusercontent.com/npm/cli/latest/package.json" \
    "$DATA_DIR/json/npm-package.json" \
    "json/npm-package.json (small)"

download_file \
    "https://raw.githubusercontent.com/microsoft/vscode/main/package.json" \
    "$DATA_DIR/json/vscode-package.json" \
    "json/vscode-package.json (large)" 5000

# YAML files
download_file \
    "https://raw.githubusercontent.com/actions/javascript-action/v1/action.yml" \
    "$DATA_DIR/yaml/github-action.yml" \
    "yaml/github-action.yml (small)"

download_file \
    "https://raw.githubusercontent.com/github/gitignore/main/Rust.gitignore" \
    "$DATA_DIR/yaml/rust-gitignore.yml" \
    "yaml/rust-gitignore.yml (medium)" 200

# Ruby files
download_file \
    "https://raw.githubusercontent.com/rails/rails/v7.0.0/activesupport/lib/active_support/core_ext/hash/keys.rb" \
    "$DATA_DIR/ruby/hash-keys.rb" \
    "ruby/hash-keys.rb (small)"

download_file \
    "https://raw.githubusercontent.com/rubocop/rubocop/v1.50.0/lib/rubocop/cop/base.rb" \
    "$DATA_DIR/rubocop/base.rb" \
    "ruby/base.rb (medium)" 5000

# Go files
download_file \
    "https://raw.githubusercontent.com/golang/go/master/src/context/context.go" \
    "$DATA_DIR/go/context.go" \
    "go/context.go (small)"

download_file \
    "https://raw.githubusercontent.com/golang/go/master/src/net/http/server.go" \
    "$DATA_DIR/go/http-server.go" \
    "go/http-server.go (large)" 50000

# Rust files
download_file \
    "https://raw.githubusercontent.com/rust-lang/rust/1.70.0/library/alloc/src/string.rs" \
    "$DATA_DIR/rust/string.rs" \
    "rust/string.rs (large)" 10000

# HTML files
download_file \
    "https://raw.githubusercontent.com/sindresorhus/github-markdown-css/main/index.html" \
    "$DATA_DIR/html/github-markdown.html" \
    "html/github-markdown.html (small)"

# CSS files
download_file \
    "https://raw.githubusercontent.com/twbs/bootstrap/main/dist/css/bootstrap.css" \
    "$DATA_DIR/css/bootstrap.css" \
    "css/bootstrap.css (large)" 50000

download_file \
    "https://raw.githubusercontent.com/highlightjs/highlight.js/main/src/styles/github.css" \
    "$DATA_DIR/css/github.css" \
    "css/github.css (small)"

# SQL files
download_file \
    "https://raw.githubusercontent.com/postgres/postgres/master/src/include/catalog/pg_proc.dat" \
    "$DATA_DIR/sql/pg_proc.dat" \
    "sql/pg_proc.dat (large)" 10000

# Shell scripts
download_file \
    "https://raw.githubusercontent.com/creationix/nvm/master/nvm.sh" \
    "$DATA_DIR/shell/nvm.sh" \
    "shell/nvm.sh (large)" 10000

download_file \
    "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh" \
    "$DATA_DIR/shell/nvm-install.sh" \
    "shell/nvm-install.sh (medium)" 5000

echo -e "${GREEN}Done! Benchmark data ready in $DATA_DIR${NC}"
