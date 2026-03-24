#!/usr/bin/env bash
# CAP Project Validator
# Validates CAP project structure, CDS models, and configuration
# Usage: bash scripts/validate-cap-project.sh [project_root]

set -euo pipefail

ROOT="${1:-.}"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== CAP Project Validation ==="
echo "Root: $ROOT"
echo ""

# --- Check 1: Required files ---
echo "--- Check 1: Required Files ---"
REQUIRED_FILES=("package.json" "db" "srv")
for f in "${REQUIRED_FILES[@]}"; do
  if [ ! -e "$ROOT/$f" ]; then
    echo -e "${RED}[ERROR]${NC} Missing: $f"
    ERRORS=$((ERRORS + 1))
  else
    echo -e "${GREEN}[OK]${NC} Found: $f"
  fi
done

# --- Check 2: package.json CDS config ---
echo ""
echo "--- Check 2: CDS Configuration ---"
if [ -f "$ROOT/package.json" ]; then
  if grep -q '"cds"' "$ROOT/package.json"; then
    echo -e "${GREEN}[OK]${NC} CDS config found in package.json"

    # Check for HANA binding
    if grep -q '"hana"' "$ROOT/package.json"; then
      echo -e "${GREEN}[OK]${NC} HANA database binding configured"
    else
      echo -e "${YELLOW}[WARN]${NC} No HANA binding — using SQLite only?"
    fi

    # Check for auth
    if grep -q '"xsuaa"\|"ias"' "$ROOT/package.json"; then
      echo -e "${GREEN}[OK]${NC} Authentication configured"
    else
      echo -e "${YELLOW}[WARN]${NC} No XSUAA/IAS auth binding"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo -e "${YELLOW}[WARN]${NC} No CDS config in package.json"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# --- Check 3: CDS model validation ---
echo ""
echo "--- Check 3: CDS Models ---"
CDS_FILES=$(find "$ROOT/db" "$ROOT/srv" -name "*.cds" 2>/dev/null | head -20)
if [ -z "$CDS_FILES" ]; then
  echo -e "${RED}[ERROR]${NC} No .cds files found"
  ERRORS=$((ERRORS + 1))
else
  CDS_COUNT=$(echo "$CDS_FILES" | wc -l)
  echo -e "${GREEN}[OK]${NC} Found $CDS_COUNT .cds files"

  # Check for @requires annotations (authorization)
  AUTH_COUNT=$(grep -rl "@requires\|@restrict" $CDS_FILES 2>/dev/null | wc -l || echo 0)
  if [ "$AUTH_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} No @requires/@restrict annotations — services may be unprotected"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "${GREEN}[OK]${NC} Authorization annotations found in $AUTH_COUNT files"
  fi
fi

# --- Check 4: MTA / deployment config ---
echo ""
echo "--- Check 4: Deployment Config ---"
if [ -f "$ROOT/mta.yaml" ]; then
  echo -e "${GREEN}[OK]${NC} mta.yaml found (Cloud Foundry deploy)"
elif [ -f "$ROOT/chart/Chart.yaml" ]; then
  echo -e "${GREEN}[OK]${NC} Helm chart found (Kyma deploy)"
else
  echo -e "${YELLOW}[WARN]${NC} No mta.yaml or Helm chart — local dev only?"
  WARNINGS=$((WARNINGS + 1))
fi

# --- Check 5: Test files ---
echo ""
echo "--- Check 5: Tests ---"
TEST_FILES=$(find "$ROOT" -name "*.test.js" -o -name "*.spec.js" -o -name "*.test.ts" 2>/dev/null | head -10)
if [ -z "$TEST_FILES" ]; then
  echo -e "${YELLOW}[WARN]${NC} No test files found"
  WARNINGS=$((WARNINGS + 1))
else
  TEST_COUNT=$(echo "$TEST_FILES" | wc -l)
  echo -e "${GREEN}[OK]${NC} Found $TEST_COUNT test files"
fi

# --- Summary ---
echo ""
echo "=== Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✓ All checks passed${NC}"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠ $WARNINGS warning(s), 0 errors${NC}"
  exit 0
else
  echo -e "${RED}✗ $ERRORS error(s), $WARNINGS warning(s)${NC}"
  exit 1
fi
