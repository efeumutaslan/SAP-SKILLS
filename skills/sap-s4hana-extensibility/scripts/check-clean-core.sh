#!/usr/bin/env bash
# Clean Core Compliance Checker
# Scans ABAP/CDS code for Clean Core violations
# Usage: bash scripts/check-clean-core.sh [file_or_directory]

set -euo pipefail

TARGET="${1:-.}"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== Clean Core Compliance Check ==="
echo "Target: $TARGET"
echo ""

# --- Check 1: Direct DB access to SAP standard tables ---
echo "--- Check 1: Direct Standard Table Access ---"
STANDARD_TABLES=(
  "BSEG" "BKPF" "BSID" "BSAD" "BSIK" "BSAK" "BSIS" "BSAS"
  "COEP" "COBK" "KONV" "EKBE" "MBEW"
  "KNA1" "KNB1" "KNVV" "LFA1" "LFB1"
  "MARA" "MARC" "MARD" "MAKT"
  "VBAK" "VBAP" "VBFA" "LIKP" "LIPS"
  "EKKO" "EKPO" "EBAN" "EBKN"
  "USR02" "USR21" "AGR_USERS"
)

for table in "${STANDARD_TABLES[@]}"; do
  matches=$(grep -rn --include="*.abap" --include="*.cds" -iw "FROM\s\+$table\|INTO\s\+$table\|UPDATE\s\+$table\|DELETE\s\+FROM\s\+$table" "$TARGET" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo -e "${RED}[ERROR]${NC} Direct access to SAP table: $table → Use released CDS view or API"
    echo "$matches" | head -3
    ERRORS=$((ERRORS + 1))
  fi
done

# --- Check 2: Non-released function modules ---
echo ""
echo "--- Check 2: Potentially Non-Released Function Modules ---"
FM_PATTERNS=(
  "BAPI_MATERIAL_"
  "BAPI_SALESORDER_"
  "BAPI_PO_"
  "BAPI_ACC_"
  "SD_SALESDOCUMENT_"
  "ME_PROCESS_PO_"
  "REUSE_ALV_"
  "POPUP_TO_"
  "SO_NEW_DOCUMENT_"
  "GUI_DOWNLOAD"
  "GUI_UPLOAD"
)

for pattern in "${FM_PATTERNS[@]}"; do
  matches=$(grep -rn --include="*.abap" -i "CALL FUNCTION.*$pattern" "$TARGET" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo -e "${YELLOW}[WARN]${NC} Potentially non-released FM: $pattern → Check Cloudification Repository"
    echo "$matches" | head -2
    WARNINGS=$((WARNINGS + 1))
  fi
done

# --- Check 3: Classic extensibility patterns ---
echo ""
echo "--- Check 3: Classic Extensibility (Non-Clean-Core) ---"
CLASSIC_PATTERNS=(
  "APPEND.*TO.*EXIT"
  "CUSTOMER-FUNCTION"
  "ENHANCEMENT-POINT"
  "ENHANCEMENT-SECTION"
  "MODIFY.*SCREEN"
  "MODULE.*OUTPUT"
  "PROCESS BEFORE OUTPUT"
  "AT SELECTION-SCREEN"
  "START-OF-SELECTION"
)

for pattern in "${CLASSIC_PATTERNS[@]}"; do
  matches=$(grep -rn --include="*.abap" -i "$pattern" "$TARGET" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo -e "${YELLOW}[WARN]${NC} Classic pattern: $pattern → Consider BAdI or RAP extension"
    WARNINGS=$((WARNINGS + 1))
  fi
done

# --- Check 4: CDS view annotations ---
echo ""
echo "--- Check 4: CDS Best Practices ---"
CDS_FILES=$(find "$TARGET" -name "*.cds" -o -name "*.ddls" 2>/dev/null)
if [ -n "$CDS_FILES" ]; then
  # Missing @AccessControl
  for f in $CDS_FILES; do
    if grep -qi "define.*view\|define.*entity" "$f" 2>/dev/null; then
      if ! grep -qi "@AccessControl\|@AbapCatalog.viewEnhancementCategory" "$f" 2>/dev/null; then
        echo -e "${YELLOW}[WARN]${NC} $(basename $f): Missing @AccessControl annotation"
        WARNINGS=$((WARNINGS + 1))
      fi
    fi
  done
fi

# --- Summary ---
echo ""
echo "=== Summary ==="
TOTAL=$((ERRORS + WARNINGS))
if [ $TOTAL -eq 0 ]; then
  echo -e "${GREEN}✓ Clean Core compliant — no violations found${NC}"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠ $WARNINGS warning(s) — review recommended${NC}"
  exit 0
else
  echo -e "${RED}✗ $ERRORS error(s), $WARNINGS warning(s) — Clean Core violations found${NC}"
  exit 1
fi
