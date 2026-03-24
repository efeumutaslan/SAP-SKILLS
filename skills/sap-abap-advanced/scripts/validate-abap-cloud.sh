#!/usr/bin/env bash
# ABAP Cloud Compliance Validator
# Checks ABAP source files for non-released API usage and classic patterns
# Usage: bash scripts/validate-abap-cloud.sh [file_or_directory]

set -euo pipefail

TARGET="${1:-.}"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== ABAP Cloud Compliance Check ==="
echo "Target: $TARGET"
echo ""

# --- Check 1: Forbidden statements in ABAP Cloud (Tier 1) ---
echo "--- Check 1: Forbidden Classic ABAP Statements ---"
FORBIDDEN_PATTERNS=(
  "CALL FUNCTION"
  "CALL SCREEN"
  "CALL TRANSACTION"
  "CALL DIALOG"
  "WRITE:"
  "WRITE /"
  "SELECT.*FROM.*INTO.*ENDSELECT"
  "EXEC SQL"
  "GENERATE SUBROUTINE"
  "FORM .*USING"
  "PERFORM "
  "FIELD-SYMBOLS.*ASSIGNING.*<"
)

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  matches=$(grep -rn --include="*.abap" --include="*.clas" -i "$pattern" "$TARGET" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo -e "${RED}[ERROR]${NC} Found forbidden pattern: $pattern"
    echo "$matches" | head -5
    ERRORS=$((ERRORS + 1))
  fi
done

# --- Check 2: Non-released API patterns ---
echo ""
echo "--- Check 2: Non-Released API Usage ---"
UNRELEASED_PATTERNS=(
  "cl_gui_"
  "cl_salv_"
  "cl_bcs"
  "cl_abap_typedescr"
  "cl_http_client"
  "if_http_client"
  "cl_gui_alv_grid"
  "cl_gui_frontend_services"
)

for pattern in "${UNRELEASED_PATTERNS[@]}"; do
  matches=$(grep -rn --include="*.abap" --include="*.clas" -i "$pattern" "$TARGET" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo -e "${YELLOW}[WARN]${NC} Potentially non-released API: $pattern"
    echo "$matches" | head -3
    WARNINGS=$((WARNINGS + 1))
  fi
done

# --- Check 3: Naming conventions ---
echo ""
echo "--- Check 3: Naming Conventions ---"
# Z/Y namespace check
z_files=$(find "$TARGET" -name "*.abap" -o -name "*.clas" 2>/dev/null | grep -iv "[/\\]z\|[/\\]y" | head -5 || true)
if [ -n "$z_files" ]; then
  echo -e "${YELLOW}[WARN]${NC} Files without Z/Y namespace prefix found (may be OK for BTP)"
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
