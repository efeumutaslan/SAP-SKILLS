---
name: sap-check-clean-core
description: Check ABAP code for Clean Core compliance. Scans for non-released APIs, deprecated patterns, and S/4HANA Cloud readiness issues.
allowed-tools: Read Glob Grep Bash
---

# /sap-check-clean-core

Scan the current project or specified files for SAP Clean Core compliance violations.

## What to Check

Scan all `.abap`, `.cds`, `.asddls`, and `.acinf` files for these violations:

### CRITICAL — Non-Released API Usage
Search for patterns that indicate non-released API usage:

```
CALL FUNCTION '[^']*'     → Check if FM is released (warn on all CALL FUNCTION)
SELECT FROM [A-Z]{3,5}    → Check if table is SAP standard (non-Z/Y prefix = likely non-released)
cl_gui_*, cl_salv_*        → Check UI classes (many not released for cloud)
```

### HIGH — Deprecated Patterns
```
FORM ... ENDFORM          → Replace with class methods
INCLUDE [type] ...        → Replace with class includes
TABLES ...                → Replace with typed parameters
WRITE / FORMAT            → Replace with RAP / HTTP service
SUBMIT ... AND RETURN     → Replace with API call
CALL TRANSACTION          → Replace with API call / RAP action
COMMUNICATION             → Replace with HTTP destination
```

### MEDIUM — Modernization Opportunities
```
MOVE ... TO ...           → Use = assignment
TRANSLATE ... USING       → Use string functions
DESCRIBE TABLE LINES      → Use lines( )
READ TABLE ... SY-SUBRC   → Use VALUE #( ... OPTIONAL )
IF ... IS INITIAL / NOT   → Use xsdbool( ) or COND
CALL METHOD obj->method   → Use obj->method( ) functional
```

## Output Format

```
╔══════════════════════════════════════════════╗
║  SAP Clean Core Compliance Report            ║
╠══════════════════════════════════════════════╣
║  Files scanned:  {{COUNT}}                   ║
║  Critical:       {{COUNT}} 🔴                ║
║  High:           {{COUNT}} 🟠                ║
║  Medium:         {{COUNT}} 🟡                ║
║  Clean:          {{COUNT}} 🟢                ║
╚══════════════════════════════════════════════╝

CRITICAL FINDINGS:
  📍 file.abap:42 — CALL FUNCTION 'NON_RELEASED_FM'
     → Replace with released class/method or create Tier 2 wrapper

HIGH FINDINGS:
  📍 file.abap:15 — FORM my_form
     → Convert to class method in ZCL_*

MEDIUM FINDINGS:
  📍 file.abap:88 — MOVE lv_a TO lv_b
     → Simplify to: lv_b = lv_a
```

## Execution Steps

1. Find all ABAP/CDS files: `**/*.abap`, `**/*.cds`, `**/*.asddls`
2. Grep for each violation pattern
3. Classify findings by severity
4. Generate report with file:line references
5. Provide summary statistics
