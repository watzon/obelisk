#!/usr/bin/env bash

# Runtime coverage generation logic based on https://hannes.kaeufler.net/posts/measuring-code-coverage-in-crystal-with-kcov
# and Athena framework's approach.

# Runs specs normally without coverage
function runSpecs() {
  set -e
  $CRYSTAL spec "${DEFAULT_BUILD_OPTIONS[@]}" "${DEFAULT_OPTIONS[@]}"
}

# Runs specs with kcov coverage generation
function runSpecsWithCoverage() {
  set -e
  rm -rf "coverage/"
  mkdir -p coverage/bin coverage/report

  echo "Building spec binary for coverage..."
  
  # Build spec binary that covers entire spec/ directory
  echo "require \"../../spec/**\"" > "./coverage/bin/obelisk_spec.cr"
  $CRYSTAL build "${DEFAULT_BUILD_OPTIONS[@]}" "./coverage/bin/obelisk_spec.cr" -o "./coverage/bin/obelisk_spec"

  echo "Running kcov coverage analysis..."
  
  # Run kcov on the spec binary
  kcov $(if [ "$IS_CI" != "true" ]; then echo "--cobertura-only"; fi) \
    --clean \
    --include-path="./src" \
    --exclude-pattern="/usr/,/lib/crystal/" \
    "./coverage/report" \
    "./coverage/bin/obelisk_spec" \
    "${DEFAULT_OPTIONS[@]}"

  echo "Generating macro coverage report..."
  # Generate macro coverage report for compile-time code
  $CRYSTAL tool macro_code_coverage --no-color "./coverage/bin/obelisk_spec.cr" > "./coverage/report/macro_coverage.codecov.json" 2>/dev/null || true

  echo "Generating unreachable code report..."
  # Generate unreachable code report
  $CRYSTAL tool unreachable --no-color --format=codecov "./coverage/bin/obelisk_spec.cr" > "./coverage/report/unreachable.codecov.json" 2>/dev/null || true

  # Copy and rename the coverage file for consistency
  if [ -f "./coverage/report/cov.xml" ]; then
    cp "./coverage/report/cov.xml" "./coverage/report/cobertura.xml"
  fi

  echo "Coverage reports generated in ./coverage/report/"
  
  # Show coverage summary if available
  if [ -f "./coverage/report/cobertura.xml" ]; then
    echo ""
    echo "Coverage Summary:"
    echo "=================="
    # Extract coverage percentage from cobertura.xml if available
    if command -v xmllint &>/dev/null; then
      COVERAGE=$(xmllint --xpath "string(//coverage/@line-rate)" "./coverage/report/cobertura.xml" 2>/dev/null || echo "N/A")
      if [ "$COVERAGE" != "N/A" ] && [ "$COVERAGE" != "" ]; then
        PERCENTAGE=$(echo "$COVERAGE * 100" | bc -l 2>/dev/null | cut -d. -f1 2>/dev/null || echo "N/A")
        echo "Line Coverage: ${PERCENTAGE}%"
      fi
    elif [ -f "./coverage/report/cobertura.xml" ]; then
      # Fallback: try to extract coverage using grep/sed
      COVERAGE=$(grep -o 'line-rate="[0-9.]*"' "./coverage/report/cobertura.xml" | head -1 | sed 's/line-rate="//;s/"//' 2>/dev/null || echo "")
      if [ "$COVERAGE" != "" ]; then
        PERCENTAGE=$(echo "$COVERAGE * 100" | bc -l 2>/dev/null | cut -d. -f1 2>/dev/null || echo "N/A")
        echo "Line Coverage: ${PERCENTAGE}%"
      fi
    fi
  fi
}

# Default Crystal build options
DEFAULT_BUILD_OPTIONS=(-Dstrict_multi_assign --error-on-warnings)
DEFAULT_OPTIONS=(--order=random)
CRYSTAL=${CRYSTAL:=crystal}
HAS_KCOV=$(if command -v "kcov" &>/dev/null; then echo "true"; else echo "false"; fi)
IS_CI=${CI:="false"}

# Parse command line arguments
COVERAGE=${1:-auto}

case "$COVERAGE" in
  "true"|"with-coverage")
    if [ "$HAS_KCOV" = "true" ]; then
      echo "Running specs with coverage..."
      runSpecsWithCoverage
    else
      echo "Error: kcov not found. Install kcov to generate coverage reports."
      echo "On Ubuntu/Debian: sudo apt-get install kcov"
      echo "On macOS: brew install kcov"
      exit 1
    fi
    ;;
  "false"|"no-coverage")
    echo "Running specs without coverage..."
    runSpecs
    ;;
  "auto")
    if [ "$HAS_KCOV" = "true" ]; then
      echo "kcov detected. Running specs with coverage..."
      runSpecsWithCoverage
    else
      echo "kcov not found. Running specs without coverage..."
      echo "(Install kcov to enable coverage: sudo apt-get install kcov)"
      runSpecs
    fi
    ;;
  *)
    echo "Usage: $0 [true|false|auto|with-coverage|no-coverage]"
    echo ""
    echo "  true/with-coverage  - Force coverage generation (requires kcov)"
    echo "  false/no-coverage   - Run specs without coverage"
    echo "  auto               - Use coverage if kcov is available (default)"
    echo ""
    exit 1
    ;;
esac