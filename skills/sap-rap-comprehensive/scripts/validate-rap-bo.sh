#!/usr/bin/env bash
# RAP Business Object Validator
# Checks RAP BO structure for completeness and best practices
# Usage: bash scripts/validate-rap-bo.sh [project_directory]

set -euo pipefail

TARGET="${1:-.}"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== RAP Business Object Validation ==="
echo "Target: $TARGET"
echo ""

# --- Check 1: BDEF existence ---
echo "--- Check 1: Behavior Definition ---"
BDEF_FILES=$(find "$TARGET" -name "*.bdef" -o -name "*behavior*definition*" 2>/dev/null)
if [ -z "$BDEF_FILES" ]; then
  echo -e "${YELLOW}[WARN]${NC} No .bdef files found"
  WARNINGS=$((WARNINGS + 1))
else
  BDEF_COUNT=$(echo "$BDEF_FILES" | wc -l)
  echo -e "${GREEN}[OK]${NC} Found $BDEF_COUNT behavior definition(s)"

  for bdef in $BDEF_FILES; do
    # Check for authorization
    if ! grep -qi "authorization master\|authorization dependent\|with privileged" "$bdef" 2>/dev/null; then
      echo -e "${YELLOW}[WARN]${NC} $(basename $bdef): No authorization control defined"
      WARNINGS=$((WARNINGS + 1))
    fi

    # Check for draft
    if grep -qi "with draft" "$bdef" 2>/dev/null; then
      echo -e "${GREEN}[INFO]${NC} $(basename $bdef): Draft enabled"
      # Check draft table
      if ! grep -qi "draft table" "$bdef" 2>/dev/null; then
        echo -e "${RED}[ERROR]${NC} $(basename $bdef): Draft enabled but no draft table defined"
        ERRORS=$((ERRORS + 1))
      fi
    fi

    # Check for etag
    if ! grep -qi "etag master\|etag dependent" "$bdef" 2>/dev/null; then
      echo -e "${YELLOW}[WARN]${NC} $(basename $bdef): No ETag defined — concurrency control missing"
      WARNINGS=$((WARNINGS + 1))
    fi
  done
fi

# --- Check 2: CDS view entity (not legacy view) ---
echo ""
echo "--- Check 2: CDS View Entity (Modern Syntax) ---"
CDS_FILES=$(find "$TARGET" -name "*.cds" -o -name "*.ddls" 2>/dev/null)
if [ -n "$CDS_FILES" ]; then
  LEGACY=$(grep -rl "define view " $CDS_FILES 2>/dev/null | grep -v "define view entity" || true)
  if [ -n "$LEGACY" ]; then
    echo -e "${YELLOW}[WARN]${NC} Legacy 'define view' syntax (should be 'define view entity'):"
    echo "$LEGACY" | head -5
    WARNINGS=$((WARNINGS + 1))
  fi

  ENTITY=$(grep -rl "define view entity\|define root view entity" $CDS_FILES 2>/dev/null || true)
  if [ -n "$ENTITY" ]; then
    ENTITY_COUNT=$(echo "$ENTITY" | wc -l)
    echo -e "${GREEN}[OK]${NC} Found $ENTITY_COUNT modern view entity definitions"
  fi
fi

# --- Check 3: Service binding ---
echo ""
echo "--- Check 3: Service Definition & Binding ---"
SRVD_FILES=$(find "$TARGET" -name "*.srvd" -o -name "*service*definition*" 2>/dev/null)
if [ -z "$SRVD_FILES" ]; then
  echo -e "${YELLOW}[WARN]${NC} No service definition (.srvd) found"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}[OK]${NC} Service definition(s) found"
fi

SRVB_FILES=$(find "$TARGET" -name "*.srvb" -o -name "*service*binding*" 2>/dev/null)
if [ -z "$SRVB_FILES" ]; then
  echo -e "${YELLOW}[WARN]${NC} No service binding (.srvb) found"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}[OK]${NC} Service binding(s) found"
fi

# --- Check 4: Test classes ---
echo ""
echo "--- Check 4: Unit Tests ---"
TEST_FILES=$(grep -rl "FOR TESTING\|for testing" "$TARGET" --include="*.abap" --include="*.clas" 2>/dev/null || true)
if [ -z "$TEST_FILES" ]; then
  echo -e "${YELLOW}[WARN]${NC} No ABAP Unit test classes found"
  WARNINGS=$((WARNINGS + 1))
else
  TEST_COUNT=$(echo "$TEST_FILES" | wc -l)
  echo -e "${GREEN}[OK]${NC} Found test classes in $TEST_COUNT files"
fi

# --- Summary ---
echo ""
echo "=== Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✓ RAP BO structure is complete${NC}"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠ $WARNINGS warning(s) — review recommended${NC}"
  exit 0
else
  echo -e "${RED}✗ $ERRORS error(s), $WARNINGS warning(s)${NC}"
  exit 1
fi
