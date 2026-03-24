---
name: sap-migration-check
description: Check ABAP code for S/4HANA migration readiness. Identifies deprecated tables, removed function modules, simplification items, and provides migration effort estimate.
allowed-tools: Read Glob Grep Bash
---

# /sap-migration-check

Scan ABAP code for S/4HANA migration blockers and generate readiness report.

## Scan Rules

### BLOCKER — Removed/Replaced Objects
Tables and function modules removed in S/4HANA:

```
Tables:
  BSEG (direct access)  → ACDOCA / I_JournalEntry CDS
  KNA1                   → BUT000 / I_Customer CDS
  LFA1                   → BUT000 / I_Supplier CDS
  KONV                   → PRCD_ELEMENTS
  VBRK/VBRP (some fields) → Check simplification list
  COEP                   → ACDOCA
  BSID/BSIK/BSAD/BSAK   → ACDOCA + clearing info

Function Modules:
  POPUP_TO_CONFIRM_*     → Use CL_ABAP_POPUP or RAP messages
  REUSE_ALV_*            → CL_SALV_TABLE / RAP Fiori Elements
  CONVERT_TO_LOCAL_CURRENCY → CL_ABAP_CONV_CODEPAGE
  BDC_INSERT/OPEN/CLOSE  → Direct API calls
  READ_TEXT / SAVE_TEXT   → Check if still available, use wrappers
```

### ADAPTATION — Simplification Items
```
Material Ledger:
  ML active check (T_001K-MLACTIVE) → Always active, remove checks

New GL:
  Classic GL tables (GLT0, SKC1C) → New GL tables (FAGLFLEXT, ACDOCA)
  Ledger checks              → Universal Journal always active

Credit Management:
  FD32 / KNKK tables         → UKM_* FSCM classes/tables
  BAPI_CREDITCHECK_*         → UKM_API_*

Output Management:
  NAST / TNAPR               → BRF+ / Adobe Forms / RAP actions
  SAPscript (SE71)           → Adobe Forms / Output Management

Business Partner:
  KNA1 + LFA1 separate       → Unified BP (BUT000)
  Customer/vendor creates     → BP_CREATE / I_BusinessPartnerTP
```

### WARNING — Deprecated Patterns
```
WRITE / SKIP / ULINE / FORMAT    → No classic list output in S/4HANA Cloud
SUBMIT ... AND RETURN            → Call API directly
CALL TRANSACTION ... USING       → Call API directly
SELECT ... INTO CORRESPONDING    → Use @DATA or explicit field list
MOVE-CORRESPONDING ... EXPANDING → Check field mapping
FIELD-SYMBOLS without TYPE       → Always type field symbols
```

## Output Format

```
╔══════════════════════════════════════════════╗
║  S/4HANA Migration Readiness Report          ║
║  Generated: {{DATE}}                         ║
╠══════════════════════════════════════════════╣
║  Readiness Score:  {{X}}/10                  ║
║  Files scanned:    {{COUNT}}                 ║
║  Blockers:         {{COUNT}} 🔴              ║
║  Adaptations:      {{COUNT}} 🟠              ║
║  Warnings:         {{COUNT}} 🟡              ║
║  Estimated effort: {{X}} person-days         ║
╚══════════════════════════════════════════════╝

🔴 BLOCKERS (Must fix before migration):

  📍 src/z_report.abap:25 — SELECT * FROM BSEG
     → Replace with: SELECT FROM I_JournalEntry or ACDOCA
     → Effort: 2-4 hours
     → Simplification Item: SIMPLIFICATION_S4_FIN_BSEG

  📍 src/z_customer.abap:42 — SELECT FROM KNA1
     → Replace with: I_Customer CDS view or Business Partner API
     → Effort: 4-8 hours
     → Simplification Item: SIMPLIFICATION_BP

🟠 ADAPTATIONS (Should fix during migration):

  📍 src/z_output.abap:15 — CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
     → Replace with: CL_SALV_TABLE or RAP Fiori Elements
     → Effort: 1-2 days

🟡 WARNINGS:

  📍 src/z_utils.abap:88 — WRITE: / lv_text
     → Replace with HTTP/RAP service output
     → Effort: 0.5-1 day

EFFORT SUMMARY:
  Blockers:    {{X}} person-days
  Adaptations: {{X}} person-days
  Warnings:    {{X}} person-days
  Testing:     {{X}} person-days (40% of dev effort)
  ─────────────────────────
  TOTAL:       {{X}} person-days
```

## Effort Estimation Rules

| Finding Type | Per-Instance Estimate |
|-------------|----------------------|
| Table replacement (BSEG, KNA1) | 0.5-1 day |
| FM replacement (REUSE_ALV) | 1-2 days |
| Output replacement (WRITE→RAP) | 0.5-1 day |
| BDC replacement | 1-3 days |
| BP migration (customer/vendor) | 2-5 days |
| Credit mgmt migration | 3-5 days |
| Testing | 40% of development effort |

## Execution Steps

1. Glob all ABAP files: `**/*.abap`, `**/*.asddls`, `**/*.fugr`
2. Run blocker patterns (removed tables, FMs)
3. Run adaptation patterns (simplification items)
4. Run warning patterns (deprecated syntax)
5. Calculate effort estimate per finding
6. Generate readiness score: `10 - (blockers * 2) - (adaptations * 0.5)`
7. Output formatted report
